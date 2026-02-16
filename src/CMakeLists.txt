option(EXAMPLE_LIBRARY_BUILD_SHARED "Build example_lib as a shared library" OFF)

if(EXAMPLE_LIBRARY_BUILD_SHARED)
    set(LIB_TYPE SHARED)
else()
    set(LIB_TYPE STATIC)
endif()

add_library(example_lib ${LIB_TYPE}
    ${CMAKE_CURRENT_SOURCE_DIR}/include/example_lib/lib.hpp
)

set_target_properties(example_lib PROPERTIES LINKER_LANGUAGE CXX)

target_include_directories(example_lib
    PUBLIC
    $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/src/include>
    $<INSTALL_INTERFACE:include>
    PRIVATE
    $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/src/include_private>
)

install(TARGETS example_lib
    EXPORT example_libTargets
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
)
