cmake_minimum_required(VERSION 3.13)
project(example-ext VERSION 0.1.0 LANGUAGES C CXX)

include(${CMAKE_CURRENT_LIST_DIR}/cmake/sourcemod.cmake)

add_subdirectory(src)
