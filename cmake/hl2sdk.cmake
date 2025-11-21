include(FetchContent)

function(json_get_nullable out json key)
    string(JSON data ERROR_VARIABLE err GET "${json}" "${key}")
    if(NOT err STREQUAL "NOTFOUND")
        set(data "")
    endif()
    set(${out} "${data}" PARENT_SCOPE)
endfunction()

function(parse_json_list out json_list)
    if(NOT json_list)
        set(${out} "" PARENT_SCOPE)
        return()
    endif()

    string(JSON json_list_length LENGTH "${json_list}")
    math(EXPR last_index "${json_list_length} - 1")
    set(data "")
    foreach(i RANGE ${last_index})
        string(JSON e GET "${json_list}" ${i})
        list(APPEND data "${e}")
    endforeach()
    set(${out} "${data}" PARENT_SCOPE)
endfunction()

set(HL2SDK_ALL_MANIFEST_PATH ${CMAKE_SOURCE_DIR}/lib/hl2sdk-manifests/manifests)

if(WIN32)
    set(HL2SDK_PLATFORM_NAME "windows")
elseif(LINUX)
    set(HL2SDK_PLATFORM_NAME "linux")
elseif(APPLE)
    set(HL2SDK_PLATFORM_NAME "mac")
else()
    message(FATAL_ERROR "Unsupported platform. Stop.")
endif()

if("${HL2SDK_TARGET}" STREQUAL "")
    message(FATAL_ERROR "No Source SDK target specified. Stop.")
endif()

set(HL2SDK_MANIFEST_PATH ${HL2SDK_ALL_MANIFEST_PATH}/${HL2SDK_TARGET}.json)

if(NOT EXISTS ${HL2SDK_MANIFEST_PATH})
    message(FATAL_ERROR "Source SDK target is invalid. Stop.")
endif()


file(READ "${HL2SDK_MANIFEST_PATH}" HL2SDK_MANIFEST)

string(JSON HL2SDK_PATH_ENV_VAR GET "${HL2SDK_MANIFEST}" env_var)
string(JSON HL2SDK_NAME GET "${HL2SDK_MANIFEST}" name)

set(HL2SDK_LIBRARY_NAME "hl2sdk-${HL2SDK_NAME}")
add_library(${HL2SDK_LIBRARY_NAME} INTERFACE)

set(HL2SDK_PATH $ENV{${HL2SDK_PATH_ENV_VAR}})
if(NOT(HL2SDK_PATH AND EXISTS "${HL2SDK_PATH}"))
    message(STATUS "Fetching Source SDK for ${HL2SDK_NAME}")
    FetchContent_Declare(
        HL2SDK_${HL2SDK_NAME}
        GIT_REPOSITORY https://github.com/alliedmodders/hl2sdk.git
        GIT_TAG ${HL2SDK_NAME}
    )
    FetchContent_MakeAvailable(HL2SDK_${HL2SDK_NAME})
    string(TOLOWER "HL2SDK_${HL2SDK_NAME}" HL2SDK_SOURCE_DIR_ID)
    set(HL2SDK_PATH ${${HL2SDK_SOURCE_DIR_ID}_SOURCE_DIR})
endif()

message(STATUS "Using Source SDK at ${HL2SDK_PATH}")

string(JSON HL2SDK_CODE GET "${HL2SDK_MANIFEST}" code)
string(JSON HL2SDK_DEFINE GET "${HL2SDK_MANIFEST}" define)
string(JSON HL2SDK_EXTENSION GET "${HL2SDK_MANIFEST}" extension)

add_compile_definitions(
    SOURCE_ENGINE=${HL2SDK_CODE}
    ${HL2SDK_DEFINE}
)

if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    set(TARGET_SDKS_REMOVE_DEFS "sdk2013" "bms" "pvkii" "tf2" "css" "dods" "hl2dm")
    if("${HL2SDK_NAME}" IN_LIST TARGET_SDKS_REMOVE_DEFS)
        remove_definitions(
            -Dstricmp=strcasecmp
            -D_stricmp=strcasecmp
            -D_snprintf=snprintf
            -D_vsnprintf=vsnprintf
        )
    endif()
endif()

if(MSVC)
    add_compile_definitions(
        COMPILER_MSVC
        WIN32
        _CRT_SECURE_NO_DEPRECATE
        _CRT_SECURE_NO_WARNINGS
        _CRT_NONSTDC_NO_DEPRECATE
        _ITERATOR_DEBUG_LEVEL=0
    )
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded")

    # if 64-bit
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        add_compile_definitions(
            COMPILER_MSVC64
            WIN64
        )
    else()
        add_compile_definitions(COMPILER_MSVC32)
    endif()

    if(MSVC_VERSION GREATER_EQUAL 1900)
        target_link_libraries(${HL2SDK_LIBRARY_NAME} INTERFACE legacy_stdio_definitions)
    endif()
else()
    add_compile_definitions(
        COMPILER_GCC
        _LINUX
        LINUX
        POSIX
        GNUC
    )
endif()

if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    add_compile_definitions(
        X64BITS
        PLATFORM_64BITS
    )
endif()

if(LINUX)
    target_link_libraries(${HL2SDK_LIBRARY_NAME} m)
endif()

if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(HL2SDK_ARCH_NAME "x86_64")
else()
    set(HL2SDK_ARCH_NAME "x86")
endif()

string(JSON HL2SDK_INCLUDE_PATHS_PRE GET "${HL2SDK_MANIFEST}" include_paths)
parse_json_list(HL2SDK_INCLUDE_PATHS "${HL2SDK_INCLUDE_PATHS_PRE}")
foreach(path IN LISTS HL2SDK_INCLUDE_PATHS)
    target_include_directories(${HL2SDK_LIBRARY_NAME} INTERFACE "${HL2SDK_PATH}/${path}")
endforeach()

string(JSON HL2SDK_PLATFORM_SECTION GET "${HL2SDK_MANIFEST}" "${HL2SDK_PLATFORM_NAME}")
json_get_nullable(HL2SDK_PLATFORM_DEFINES_PRE "${HL2SDK_PLATFORM_SECTION}" defines)
parse_json_list(HL2SDK_PLATFORM_DEFINES "${HL2SDK_PLATFORM_DEFINES_PRE}")
json_get_nullable(HL2SDK_PLATFORM_CFLAGS_PRE "${HL2SDK_PLATFORM_SECTION}" cflags)
parse_json_list(HL2SDK_PLATFORM_CFLAGS "${HL2SDK_PLATFORM_CFLAGS_PRE}")

add_compile_definitions(${HL2SDK_PLATFORM_DEFINES})
add_compile_options(${HL2SDK_PLATFORM_CFLAGS})

json_get_nullable(HL2SDK_ARCH_SECTION "${HL2SDK_PLATFORM_SECTION}" "${HL2SDK_ARCH_NAME}")

if(NOT HL2SDK_ARCH_SECTION)
    message(FATAL_ERROR "Unsupported architecture ${HL2SDK_ARCH_NAME}. Stop.")
endif()

json_get_nullable(HL2SDK_ARCH_CFLAGS_PRE "${HL2SDK_ARCH_SECTION}" cflags)
parse_json_list(HL2SDK_ARCH_CFLAGS "${HL2SDK_ARCH_CFLAGS_PRE}")
json_get_nullable(HL2SDK_ARCH_DEFINES_PRE "${HL2SDK_ARCH_SECTION}" defines)
parse_json_list(HL2SDK_ARCH_DEFINES "${HL2SDK_ARCH_DEFINES_PRE}")

add_compile_definitions(${HL2SDK_ARCH_DEFINES})
add_compile_options(${HL2SDK_ARCH_CFLAGS})

set(TARGET_TIER1_SDKS "tf2" "dods" "css" "hl2dm")
if(UNIX)
    json_get_nullable(HL2SDK_ARCH_POSTLINK_LIBS_PRE "${HL2SDK_ARCH_SECTION}" postlink_libs)
    parse_json_list(HL2SDK_ARCH_POSTLINK_LIBS "${HL2SDK_ARCH_POSTLINK_LIBS_PRE}")
    json_get_nullable(HL2SDK_ARCH_DYNAMIC_LIBS_PRE "${HL2SDK_ARCH_SECTION}" dynamic_libs)
    parse_json_list(HL2SDK_ARCH_DYNAMIC_LIBS "${HL2SDK_ARCH_DYNAMIC_LIBS_PRE}")
    foreach(lib IN LISTS HL2SDK_ARCH_POSTLINK_LIBS)
        target_link_libraries(${HL2SDK_LIBRARY_NAME} INTERFACE "${HL2SDK_PATH}/${lib}")
    endforeach()
    foreach(lib IN LISTS HL2SDK_ARCH_DYNAMIC_LIBS)
        target_link_libraries(${HL2SDK_LIBRARY_NAME} INTERFACE "${HL2SDK_PATH}/${lib}")
    endforeach()

    if(LINUX)
        json_get_nullable(HL2SDK_LINUX_USES_SYSTEM_CXX_LIBS "${HL2SDK_PLATFORM_SECTION}" uses_system_cxxlib)
        if(HL2SDK_LINUX_USES_SYSTEM_CXX_LIBS)
            get_target_property(HL2SDK_LINK_OPTIONS hl2sdk LINK_OPTIONS)
            list(REMOVE_ITEM HL2SDK_LINK_OPTIONS "-static-libstdc++")
            list(FIND HL2SDK_LINK_OPTIONS "-lstdc++" _system_cxx_linkflag_idx)
            if(_system_cxx_linkflag_idx EQUAL -1)
                list(APPEND HL2SDK_LINK_OPTIONS "-lstdc++")
            endif()
            set_target_properties(${HL2SDK_LIBRARY_NAME} PROPERTIES LINK_OPTIONS "${HL2SDK_LINK_OPTIONS}")
        endif()

        if("${HL2SDK_NAME}" IN_LIST TARGET_TIER1_SDKS)
            if(CMAKE_SIZEOF_VOID_P EQUAL 8)
                target_link_libraries(${HL2SDK_LIBRARY_NAME} INTERFACE
                    ${HL2SDK_PATH}/lib/public/linux64/tier1.a
                    ${HL2SDK_PATH}/lib/public/linux64/mathlib.a
                )
            else()
                target_link_libraries(${HL2SDK_LIBRARY_NAME} INTERFACE
                    ${HL2SDK_PATH}/lib/public/linux/tier1_i486.a
                    ${HL2SDK_PATH}/lib/public/linux/mathlib_i486.a
                )
            endif()
        endif()
    endif()
elseif(WIN32)
    json_get_nullable(HL2SDK_ARCH_LIBS_PRE "${HL2SDK_ARCH_SECTION}" libs)
    parse_json_list(HL2SDK_ARCH_LIBS "${HL2SDK_ARCH_LIBS_PRE}")
    foreach(lib IN LISTS HL2SDK_ARCH_LIBS)
        target_link_libraries(${HL2SDK_LIBRARY_NAME} INTERFACE "${HL2SDK_PATH}/${lib}")
    endforeach()
    if("${HL2SDK_NAME}" IN_LIST TARGET_TIER1_SDKS)
        if(CMAKE_SIZEOF_VOID_P EQUAL 8)
            target_link_libraries(${HL2SDK_LIBRARY_NAME} INTERFACE
                ${HL2SDK_PATH}/lib/public/x64/tier1.lib
                ${HL2SDK_PATH}/lib/public/x64/mathlib.lib
            )
        else()
            target_link_libraries(${HL2SDK_LIBRARY_NAME} INTERFACE
                ${HL2SDK_PATH}/lib/public/x86/tier1.lib
                ${HL2SDK_PATH}/lib/public/x86/mathlib.lib
            )
        endif()
    endif()
endif()
