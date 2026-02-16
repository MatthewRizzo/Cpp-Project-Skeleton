include(FetchContent)

# Prefer a system-installed UnitTest++ via find_package. This avoids rebuilding
# UnitTest++ on every configure/build. If not found, fall back to fetching the
# source (FetchContent) and building it.
find_package(UnitTest++ CONFIG QUIET)
set(UNITTEST_TARGET "")

if(TARGET "UnitTest++::UnitTest++")
    set(UNITTEST_TARGET "UnitTest++::UnitTest++")
else()
    message(info " Installing & building UnitTest++ from source")

    # Not found; fetch and build (with upstream tests/warnings disabled)
    FetchContent_Declare(
        unittest_cpp
        GIT_REPOSITORY https://github.com/unittest-cpp/unittest-cpp.git
        GIT_TAG master
    )
    set(UTPP_INCLUDE_TESTS_IN_BUILD OFF CACHE BOOL "Don't build UnitTest++ internal tests" FORCE)
    set(UTPP_AMPLIFY_WARNINGS OFF CACHE BOOL "Don't amplify warnings in UnitTest++" FORCE)

    # Fetch and make available UnitTest++ (prefer FetchContent_MakeAvailable).
    # We set upstream CMake variables prior to calling MakeAvailable so the
    # fetched project picks them up from the cache and avoids building its
    # internal tests or amplifying warnings.
    FetchContent_MakeAvailable(unittest_cpp)

    if(TARGET "UnitTest++::UnitTest++")
        set(UNITTEST_TARGET "UnitTest++::UnitTest++")
    elseif(TARGET UnitTest++)
        set(UNITTEST_TARGET "UnitTest++")
    elseif(TARGET unittest-cpp)
        set(UNITTEST_TARGET "unittest-cpp")
    elseif(TARGET unittest++)
        set(UNITTEST_TARGET "unittest++")
    endif()
endif()

# Gather test sources (each test source must provide its own `main`)
file(GLOB TEST_SOURCES RELATIVE ${CMAKE_SOURCE_DIR}/tests ${CMAKE_SOURCE_DIR}/tests/*test*.cpp)

foreach(test_src IN LISTS TEST_SOURCES)
    get_filename_component(test_name ${test_src} NAME_WE)
    add_executable(${test_name} ${CMAKE_SOURCE_DIR}/tests/${test_src})
    target_include_directories(${test_name} PRIVATE ${CMAKE_SOURCE_DIR}/src/include)

    if(UNITTEST_TARGET)
        target_link_libraries(${test_name} PRIVATE ${UNITTEST_TARGET} example_lib)
    else()
        target_link_libraries(${test_name} PRIVATE example_lib)
        message(WARNING "Could not detect a UnitTest++ CMake target automatically. If linking fails, you may need to adjust this file to match the upstream target name.")
    endif()

    add_test(NAME ${test_name} COMMAND ${test_name})
endforeach()
