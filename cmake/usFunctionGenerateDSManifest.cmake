# Generate manifest for declarative service bundles into the build tree (opt-in).
#
# Usage:
#   usFunctionGenerateDSManifest(TARGET_NAME
#       [ANNOTATED_SOURCES src/ServiceComponents.hpp ...]
#       [EXISTING_MANIFEST path/to/existing_manifest.json]  # optional, passed with -i
#       [OUTPUT_DIR path/to/build/output/directory]         # optional, defaults to build tree
#   )
#
function(usFunctionGenerateDSManifest TARGET_NAME)
  set(options "")
  set(oneValueArgs EXISTING_MANIFEST OUTPUT_DIR)
  set(multiValueArgs ANNOTATED_SOURCES)
  cmake_parse_arguments(DS_GEN "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(NOT TARGET_NAME)
    message(FATAL_ERROR "usFunctionGenerateDSManifest: TARGET_NAME is required")
  endif()

  # Default annotated source if none provided
  if(NOT DS_GEN_ANNOTATED_SOURCES)
    set(DS_GEN_ANNOTATED_SOURCES "src/ServiceComponents.hpp")
  endif()

  # Build-tree default output directory
  if(NOT DS_GEN_OUTPUT_DIR)
    set(DS_GEN_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/ds_manifest")
  endif()
 # Compute the intended output path early
  set(GENERATED_MANIFEST "${DS_GEN_OUTPUT_DIR}/manifest.json")

  # Idempotency guard: If we already registered a manifest OUTPUT for this target, reuse it.
  # Note: variable name is cache-internal, scoped per target
  if(DEFINED US_DSMANIFEST_${TARGET_NAME})
    # If a different path is requested on a subsequent call, warn and keep the first one
    if(NOT "${US_DSMANIFEST_${TARGET_NAME}}" STREQUAL "${GENERATED_MANIFEST}")
      message(WARNING
        "usFunctionGenerateDSManifest(${TARGET_NAME}) was already defined to output:\n"
        "  ${US_DSMANIFEST_${TARGET_NAME}}\n"
        "Ignoring new OUTPUT_DIR:\n"
        "  ${GENERATED_MANIFEST}\n")
      set(GENERATED_MANIFEST "${US_DSMANIFEST_${TARGET_NAME}}")
      # Also adjust DS_GEN_OUTPUT_DIR to match the first registration, for consistency
      get_filename_component(DS_GEN_OUTPUT_DIR "${GENERATED_MANIFEST}" DIRECTORY)
    endif()

    # Export variables and return without adding another add_custom_command
    set(${TARGET_NAME}_GENERATED_MANIFEST "${GENERATED_MANIFEST}" PARENT_SCOPE)
    set(${TARGET_NAME}_MANIFEST "${GENERATED_MANIFEST}" PARENT_SCOPE)
    return()
  endif()

  # Resolve parser executable
  if(WIN32)
    set(PARSER_EXECUTABLE "parser.exe")
  else()
    set(PARSER_EXECUTABLE "parser")
  endif()
  find_program(MANIFEST_PARSER_TOOL ${PARSER_EXECUTABLE}
    HINTS ${CMAKE_SOURCE_DIR}/compendium/tools/bin
    REQUIRED)

  # Normalize annotated sources to absolute paths
  set(ABS_ANN_SOURCES "")
  foreach(src ${DS_GEN_ANNOTATED_SOURCES})
    if(IS_ABSOLUTE "${src}")
      list(APPEND ABS_ANN_SOURCES "${src}")
    else()
      list(APPEND ABS_ANN_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/${src}")
    endif()
  endforeach()

  set(GENERATED_MANIFEST "${DS_GEN_OUTPUT_DIR}/manifest.json")

  # Build the parser command
  set(_parser_cmd
    ${MANIFEST_PARSER_TOOL}
      -extra-arg=-Wno-error=unknown-warning-option
      -extra-arg=-Wno-error=unused-command-line-argument
      ${ABS_ANN_SOURCES}
      -o ${DS_GEN_OUTPUT_DIR}/
      -p ${CMAKE_BINARY_DIR}
  )
  if(DS_GEN_EXISTING_MANIFEST)
    list(APPEND _parser_cmd -i ${DS_GEN_EXISTING_MANIFEST})
  endif()

  # Generate the manifest into the build tree
  add_custom_command(
    OUTPUT ${GENERATED_MANIFEST}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${DS_GEN_OUTPUT_DIR}
    COMMAND ${_parser_cmd}
    DEPENDS ${ABS_ANN_SOURCES} ${DS_GEN_EXISTING_MANIFEST}
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    COMMENT "Generating DS manifest for ${TARGET_NAME} -> ${GENERATED_MANIFEST}"
    VERBATIM
  )

  # Mark as generated so it can be listed before it exists
  set_source_files_properties(${GENERATED_MANIFEST} PROPERTIES GENERATED TRUE)

  # Convenience target if someone wants to build just the manifest
  add_custom_target(${TARGET_NAME}_generate_manifest
    DEPENDS ${GENERATED_MANIFEST})

  # Remember this output path globally to prevent duplicate OUTPUT rules
  set(US_DSMANIFEST_${TARGET_NAME} "${GENERATED_MANIFEST}" CACHE INTERNAL "Build-tree DS manifest for ${TARGET_NAME}")

  # Export absolute path for downstream macros
  set(${TARGET_NAME}_GENERATED_MANIFEST ${GENERATED_MANIFEST} PARENT_SCOPE)
  set(${TARGET_NAME}_MANIFEST ${GENERATED_MANIFEST} PARENT_SCOPE)
endfunction()