add_library(example-ext SHARED
    ${CMAKE_CURRENT_LIST_DIR}/extension.cpp
)

target_include_directories(example-ext PUBLIC ./)

target_link_libraries(example-ext PUBLIC smsdk_ext)

set_target_properties(example-ext PROPERTIES PREFIX "")

if(WIN32)
    set_target_properties(example-ext PROPERTIES SUFFIX ".ext.dll")
else()
    set_target_properties(example-ext PROPERTIES SUFFIX ".ext.so")
endif()
