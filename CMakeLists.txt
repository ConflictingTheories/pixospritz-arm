cmake_minimum_required(VERSION 3.10)
project(GameEngine)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find SDL2
find_package(SDL2 REQUIRED)
find_package(OpenGL REQUIRED)

# Create executable
add_executable(game_engine
    src/main.cpp
)

# Include directories
target_include_directories(game_engine PRIVATE
    ${SDL2_INCLUDE_DIRS}
    ${OPENGL_INCLUDE_DIR}
)

# Link libraries
target_link_libraries(game_engine
    ${SDL2_LIBRARIES}
    GLESv2
    EGL
    pthread
    dl
    m
)

# Strip binary for smaller size
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    add_custom_command(TARGET game_engine POST_BUILD
        COMMAND ${CMAKE_STRIP} game_engine
    )
endif()