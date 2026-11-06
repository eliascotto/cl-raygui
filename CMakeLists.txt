cmake_minimum_required(VERSION 3.16)
project(cl_raygui VERSION 0.1.0 LANGUAGES C)

find_package(raylib REQUIRED)
add_library(raygui SHARED src/raygui.c)
target_include_directories(raygui PRIVATE vendor)
target_link_libraries(raygui PRIVATE raylib)
target_compile_features(raygui PRIVATE c_std_99)
target_compile_definitions(raygui PRIVATE BUILD_LIBTYPE_SHARED)
set_target_properties(raygui PROPERTIES
    C_VISIBILITY_PRESET hidden
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")
if(UNIX AND NOT APPLE)
    target_link_libraries(raygui PRIVATE m)
endif()
include(GNUInstallDirs)
install(TARGETS raygui
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})

option(CL_RAYGUI_BUILD_TESTS "Build the ABI probe and deterministic interaction backend" OFF)
if(CL_RAYGUI_BUILD_TESTS)
    add_library(raygui_abi_probe SHARED tests/abi-probe.c)
    target_include_directories(raygui_abi_probe PRIVATE vendor)
    target_link_libraries(raygui_abi_probe PRIVATE raylib)
    set_target_properties(raygui_abi_probe PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")
    # Compile the same vendored implementation with scripted input and a draw
    # sink. Load this instead of the production library in a separate process.
    add_library(raygui_interaction SHARED tests/interaction-backend.c)
    target_include_directories(raygui_interaction PRIVATE vendor)
    target_link_libraries(raygui_interaction PRIVATE raylib)
    target_compile_features(raygui_interaction PRIVATE c_std_99)
    target_compile_definitions(raygui_interaction PRIVATE BUILD_LIBTYPE_SHARED)
    set_target_properties(raygui_interaction PROPERTIES
        C_VISIBILITY_PRESET hidden
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")
    if(UNIX AND NOT APPLE)
        target_link_libraries(raygui_interaction PRIVATE m)
    endif()
endif()
