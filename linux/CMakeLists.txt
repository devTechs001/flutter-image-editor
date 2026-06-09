cmake_minimum_required(VERSION 3.13)
project(ai_image_editor LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_subdirectory(${FLUTTER_MANAGED_DIRECTORY})

find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED gtk+-3.0)
pkg_check_modules(FLUTTER_LINUX REQUIRED flutter_linux)

add_executable(ai_image_editor
  my_application.cc
  fl_window.cc
)

target_include_directories(ai_image_editor PRIVATE
  ${GTK_INCLUDE_DIRS}
  ${FLUTTER_LINUX_INCLUDE_DIRS}
)

target_link_libraries(ai_image_editor PRIVATE
  ${GTK_LIBRARIES}
  ${FLUTTER_LINUX_LIBRARIES}
  PkgConfig::FLUTTER_LINUX
)

add_dependencies(ai_image_editor flutter_assemble)
