# AFTER: generate DS manifest into the build tree (opt-in)
usFunctionGenerateDSManifest(DSGraph02
    ANNOTATED_SOURCES src/ServiceComponents.hpp
    OUTPUT_DIR ${CMAKE_CURRENT_BINARY_DIR}/ds_manifest
    EXISTING_MANIFEST ${CMAKE_CURRENT_SOURCE_DIR}/resources/manifest.json 
)

usFunctionCreateDSTestBundle(DSGraph02)

usFunctionCreateTestBundleWithResources(DSGraph02
  SOURCES src/ServiceImpl.cpp ${_glue_file}
  MANIFESTS ${DSGraph02_MANIFEST}
  BUNDLE_SYMBOLIC_NAME DSGraph02
  OTHER_LIBRARIES usTestInterfaces usServiceComponent)
