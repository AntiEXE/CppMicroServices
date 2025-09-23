function(usFunctionCreateDSTestBundle name)
  # Optional argument parsing (keeps backward compatibility)
  cmake_parse_arguments(US_DST "" "MANIFEST" "" ${ARGN})

  # Resolve manifest path priority:
  # 1) Explicit MANIFEST argument to this function
  # 2) Variable <name>_MANIFEST (exported by usFunctionGenerateDSManifest)
  # 3) Legacy source-tree manifest
  set(_manifest_src "${CMAKE_CURRENT_SOURCE_DIR}/resources/manifest.json")
  if(US_DST_MANIFEST)
    set(_manifest_src "${US_DST_MANIFEST}")
  else()
    set(_hint_var "${name}_MANIFEST")
    if(DEFINED ${_hint_var} AND NOT "${${_hint_var}}" STREQUAL "")
      set(_manifest_src "${${_hint_var}}")
    endif()
  endif()

  # Expose glue file to caller
  set(_glue_file ${CMAKE_CURRENT_BINARY_DIR}/autogen_${name}_Glue.cpp)
  set(_glue_file ${_glue_file} PARENT_SCOPE)

  # Generate glue from the chosen manifest and depend on it for correct ordering
  add_custom_command(
    OUTPUT ${_glue_file}
    COMMAND $<TARGET_FILE:SCRCodeGen>
            --manifest "${_manifest_src}"
            --out-file "${_glue_file}"
            --include-headers ServiceComponents.hpp
    DEPENDS SCRCodeGen usServiceComponent "${_manifest_src}"
    COMMENT "Generate bundle activator based on manifest: ${_manifest_src}"
    VERBATIM
  )
endfunction()