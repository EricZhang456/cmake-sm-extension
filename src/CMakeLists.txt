add_library(example-ext SHARED
    ${CMAKE_CURRENT_LIST_DIR}/extension.cpp
)

target_include_directories(example-ext PUBLIC ./)

message("${HL2SDK_LIBRARY_NAME}")
target_link_libraries(example-ext PUBLIC smsdk_ext ${HL2SDK_LIBRARY_NAME})

set_target_properties(example-ext PROPERTIES PREFIX "")

if(WIN32)
    set_target_properties(example-ext PROPERTIES SUFFIX ".ext.${HL2SDK_EXTENSION}.dll")
elseif(APPLE)
    set_target_properties(example-ext PROPERTIES SUFFIX ".ext.${HL2SDK_EXTENSION}.dylib")
else()
    set_target_properties(example-ext PROPERTIES SUFFIX ".ext.${HL2SDK_EXTENSION}.so")
endif()
