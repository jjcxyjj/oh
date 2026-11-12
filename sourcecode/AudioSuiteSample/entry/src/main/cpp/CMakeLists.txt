# the minimum version of CMake.
cmake_minimum_required(VERSION 3.5.0)
project(AudioSuiteSample)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

if(DEFINED PACKAGE_FIND_FILE)
    include(${PACKAGE_FIND_FILE})
endif()

include_directories(${NATIVERENDER_ROOT_PATH}
                    ${NATIVERENDER_ROOT_PATH}/include
                    ${NATIVERENDER_ROOT_PATH}/audio_effect)

add_library(entry SHARED manual_rendering.cpp real_time_rendering.cpp audio_suite.cpp pcm_file_utils.cpp audio_format_converter.cpp print_info_to_file.cpp space_render_rotation.cpp audio_effect/audio_effect.cpp)
target_link_libraries(entry PUBLIC libace_napi.z.so)
target_link_libraries(entry PUBLIC libhilog_ndk.z.so)
# [Start CMake_lib_suite]
# [Start CMake_lib_suite_libohaudio]
target_link_libraries(entry PUBLIC libohaudio.so)
# [End CMake_lib_suite_libohaudio]
# [Start CMake_lib_suite_libohaudiosuite]
target_link_libraries(entry PUBLIC libohaudiosuite.so)
# [End CMake_lib_suite_libohaudiosuite]
# [End CMake_lib_suite]