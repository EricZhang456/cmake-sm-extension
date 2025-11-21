set(SOURCEMOD_PATH ${CMAKE_SOURCE_DIR}/lib/sourcemod)

add_library(amtl INTERFACE)
target_include_directories(amtl INTERFACE
    ${SOURCEMOD_PATH}/public/amtl
    ${SOURCEMOD_PATH}/public/amtl/amtl
)

add_library(smsdk INTERFACE)
target_include_directories(smsdk INTERFACE
    ${SOURCEMOD_PATH}/core
    ${SOURCEMOD_PATH}/public
    ${SOURCEMOD_PATH}/sourcepawn/include
)
target_link_libraries(smsdk INTERFACE amtl)

add_subdirectory(${SOURCEMOD_PATH}/public/safetyhook)

add_library(jit INTERFACE
    ${SOURCEMOD_PATH}/public/jit/jit_helpers.h
    ${SOURCEMOD_PATH}/public/jit/x86/x86_macros.h
)

add_library(CDetour INTERFACE)
target_sources(CDetour INTERFACE
    ${SOURCEMOD_PATH}/public/CDetour/detourhelpers.h
    ${SOURCEMOD_PATH}/public/CDetour/detours.cpp
    ${SOURCEMOD_PATH}/public/CDetour/detours.h
)

option(ENABLE_CDETOUR "Enable CDetour" OFF)

target_link_libraries(CDetour INTERFACE safetyhook jit smsdk)

add_library(Zydis SHARED
    ${SOURCEMOD_PATH}/public/safetyhook/zydis/Zydis.c
)
target_include_directories(Zydis PUBLIC ${SOURCEMOD_PATH}/public/safetyhook/zydis/)
target_include_directories(safetyhook PRIVATE ${SOURCEMOD_PATH}/public/safetyhook/zydis/)

add_library(smsdk_ext INTERFACE)
target_sources(smsdk_ext INTERFACE ${SOURCEMOD_PATH}/public/smsdk_ext.cpp)
target_link_libraries(smsdk_ext INTERFACE smsdk)

if(ENABLE_CDETOUR)
    add_compile_definitions(SMEXT_ENABLE_GAMECONF)
    target_link_libraries(smsdk_ext INTERFACE CDetour)
endif()
