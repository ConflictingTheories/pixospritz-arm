#include <SDL2/SDL.h>
#include <GLES3/gl3.h>
#include <iostream>
#include <cmath>

// RG353V specifications
const int SCREEN_WIDTH = 640;
const int SCREEN_HEIGHT = 480;

class GameEngine {
private:
    SDL_Window* window;
    SDL_GLContext glContext;
    SDL_GameController* controller;
    bool running;
    
    // Example: rotating triangle
    GLuint shaderProgram;
    GLuint vao, vbo;
    float rotation;
    
public:
    GameEngine() : window(nullptr), glContext(nullptr), controller(nullptr), 
                   running(true), rotation(0.0f) {}
    
    bool initialize() {
        // Initialize SDL
        if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMECONTROLLER | SDL_INIT_AUDIO) < 0) {
            std::cerr << "SDL initialization failed: " << SDL_GetError() << std::endl;
            return false;
        }
        
        // Force KMSDRM backend (direct rendering without X11/Wayland)
        SDL_SetHint(SDL_HINT_VIDEO_DRIVER, "kmsdrm");
        
        // Set OpenGL ES 3.2 attributes
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);
        SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
        SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
        
        // Create fullscreen window at native resolution
        window = SDL_CreateWindow(
            "RG353V Game Engine",
            0, 0,
            SCREEN_WIDTH, SCREEN_HEIGHT,
            SDL_WINDOW_OPENGL | SDL_WINDOW_FULLSCREEN
        );
        
        if (!window) {
            std::cerr << "Window creation failed: " << SDL_GetError() << std::endl;
            return false;
        }
        
        // Create OpenGL context
        glContext = SDL_GL_CreateContext(window);
        if (!glContext) {
            std::cerr << "OpenGL context creation failed: " << SDL_GetError() << std::endl;
            return false;
        }
        
        // Enable vsync
        SDL_GL_SetSwapInterval(1);
        
        // Initialize game controller
        if (SDL_NumJoysticks() > 0) {
            controller = SDL_GameControllerOpen(0);
            if (controller) {
                std::cout << "Controller connected: " 
                          << SDL_GameControllerName(controller) << std::endl;
            }
        }
        
        // Print OpenGL info
        std::cout << "OpenGL Vendor: " << glGetString(GL_VENDOR) << std::endl;
        std::cout << "OpenGL Renderer: " << glGetString(GL_RENDERER) << std::endl;
        std::cout << "OpenGL Version: " << glGetString(GL_VERSION) << std::endl;
        std::cout << "GLSL Version: " << glGetString(GL_SHADING_LANGUAGE_VERSION) << std::endl;
        
        // Initialize OpenGL
        if (!initializeGL()) {
            return false;
        }
        
        return true;
    }
    
    bool initializeGL() {
        // Vertex shader (GLSL ES 3.20)
        const char* vertexShaderSource = R"(
            #version 320 es
            precision highp float;
            
            layout(location = 0) in vec2 position;
            layout(location = 1) in vec3 color;
            
            uniform float rotation;
            out vec3 fragColor;
            
            void main() {
                float c = cos(rotation);
                float s = sin(rotation);
                mat2 rot = mat2(c, -s, s, c);
                vec2 rotated = rot * position;
                
                gl_Position = vec4(rotated, 0.0, 1.0);
                fragColor = color;
            }
        )";
        
        // Fragment shader (GLSL ES 3.20)
        const char* fragmentShaderSource = R"(
            #version 320 es
            precision highp float;
            
            in vec3 fragColor;
            out vec4 outColor;
            
            void main() {
                outColor = vec4(fragColor, 1.0);
            }
        )";
        
        // Compile vertex shader
        GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
        glShaderSource(vertexShader, 1, &vertexShaderSource, nullptr);
        glCompileShader(vertexShader);
        
        GLint success;
        glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &success);
        if (!success) {
            char infoLog[512];
            glGetShaderInfoLog(vertexShader, 512, nullptr, infoLog);
            std::cerr << "Vertex shader compilation failed: " << infoLog << std::endl;
            return false;
        }
        
        // Compile fragment shader
        GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
        glShaderSource(fragmentShader, 1, &fragmentShaderSource, nullptr);
        glCompileShader(fragmentShader);
        
        glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, &success);
        if (!success) {
            char infoLog[512];
            glGetShaderInfoLog(fragmentShader, 512, nullptr, infoLog);
            std::cerr << "Fragment shader compilation failed: " << infoLog << std::endl;
            return false;
        }
        
        // Link shader program
        shaderProgram = glCreateProgram();
        glAttachShader(shaderProgram, vertexShader);
        glAttachShader(shaderProgram, fragmentShader);
        glLinkProgram(shaderProgram);
        
        glGetProgramiv(shaderProgram, GL_LINK_STATUS, &success);
        if (!success) {
            char infoLog[512];
            glGetProgramInfoLog(shaderProgram, 512, nullptr, infoLog);
            std::cerr << "Shader program linking failed: " << infoLog << std::endl;
            return false;
        }
        
        glDeleteShader(vertexShader);
        glDeleteShader(fragmentShader);
        
        // Create triangle vertices (position + color)
        float vertices[] = {
            // positions        // colors
             0.0f,  0.5f,      1.0f, 0.0f, 0.0f,  // top (red)
            -0.5f, -0.5f,      0.0f, 1.0f, 0.0f,  // bottom left (green)
             0.5f, -0.5f,      0.0f, 0.0f, 1.0f   // bottom right (blue)
        };
        
        // Create VAO and VBO
        glGenVertexArrays(1, &vao);
        glGenBuffers(1, &vbo);
        
        glBindVertexArray(vao);
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
        
        // Position attribute
        glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)0);
        glEnableVertexAttribArray(0);
        
        // Color attribute
        glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(float), 
                            (void*)(2 * sizeof(float)));
        glEnableVertexAttribArray(1);
        
        glBindVertexArray(0);
        
        // Set clear color
        glClearColor(0.1f, 0.1f, 0.1f, 1.0f);
        
        return true;
    }
    
    void handleInput() {
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            switch (event.type) {
                case SDL_QUIT:
                    running = false;
                    break;
                    
                case SDL_CONTROLLERBUTTONDOWN:
                    handleControllerButton(event.cbutton);
                    break;
                    
                case SDL_KEYDOWN:
                    if (event.key.keysym.sym == SDLK_ESCAPE) {
                        running = false;
                    }
                    break;
            }
        }
    }
    
    void handleControllerButton(const SDL_ControllerButtonEvent& button) {
        switch (button.button) {
            case SDL_CONTROLLER_BUTTON_A:
                std::cout << "A button pressed" << std::endl;
                break;
            case SDL_CONTROLLER_BUTTON_B:
                std::cout << "B button pressed" << std::endl;
                break;
            case SDL_CONTROLLER_BUTTON_X:
                std::cout << "X button pressed" << std::endl;
                break;
            case SDL_CONTROLLER_BUTTON_Y:
                std::cout << "Y button pressed" << std::endl;
                break;
            case SDL_CONTROLLER_BUTTON_START:
                std::cout << "Start button pressed" << std::endl;
                running = false;  // Exit on Start button
                break;
            case SDL_CONTROLLER_BUTTON_BACK:
                std::cout << "Select button pressed" << std::endl;
                break;
        }
    }
    
    void update(float deltaTime) {
        // Update game logic
        rotation += 1.0f * deltaTime;  // Rotate 1 radian per second
    }
    
    void render() {
        // Clear screen
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        // Use shader program
        glUseProgram(shaderProgram);
        
        // Set rotation uniform
        GLint rotationLoc = glGetUniformLocation(shaderProgram, "rotation");
        glUniform1f(rotationLoc, rotation);
        
        // Draw triangle
        glBindVertexArray(vao);
        glDrawArrays(GL_TRIANGLES, 0, 3);
        glBindVertexArray(0);
        
        // Swap buffers
        SDL_GL_SwapWindow(window);
    }
    
    void run() {
        Uint64 lastTime = SDL_GetPerformanceCounter();
        
        while (running) {
            // Calculate delta time
            Uint64 currentTime = SDL_GetPerformanceCounter();
            float deltaTime = (currentTime - lastTime) / (float)SDL_GetPerformanceFrequency();
            lastTime = currentTime;
            
            handleInput();
            update(deltaTime);
            render();
        }
    }
    
    void cleanup() {
        if (vao) glDeleteVertexArrays(1, &vao);
        if (vbo) glDeleteBuffers(1, &vbo);
        if (shaderProgram) glDeleteProgram(shaderProgram);
        
        if (controller) {
            SDL_GameControllerClose(controller);
        }
        
        if (glContext) {
            SDL_GL_DeleteContext(glContext);
        }
        
        if (window) {
            SDL_DestroyWindow(window);
        }
        
        SDL_Quit();
    }
};

int main(int argc, char* argv[]) {
    std::cout << "RG353V Game Engine Starting..." << std::endl;
    
    GameEngine engine;
    
    if (!engine.initialize()) {
        std::cerr << "Engine initialization failed!" << std::endl;
        return 1;
    }
    
    std::cout << "Engine initialized successfully. Starting main loop..." << std::endl;
    engine.run();
    
    std::cout << "Shutting down..." << std::endl;
    engine.cleanup();
    
    return 0;
}