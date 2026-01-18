package main

import "core:os"
import "core:log"
import "core:math"
import "vendor:glfw"
import "core:math/linalg/glsl"
import gl "vendor:OpenGL"

Game :: struct {
    window:                glfw.WindowHandle,
    shader_program:        u32,
    light_shader_program:  u32,
    light:                 ^Entity,
    camera:                ^Camera,
    entities:              [dynamic]Entity,
    models:                [dynamic]Model,
}


game_init :: proc(game: ^Game) {
    // GLFW and OpenGL initialization
    glfw.Init()
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_VERSION_MAJOR)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_VERSION_MINOR)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
    game.window = glfw.CreateWindow(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE, nil, nil)
    if game.window == nil {
        log.errorf("GLFW window creation failed.")
        glfw.Terminate()
        os.exit(1)
    }
    glfw.MakeContextCurrent(game.window)
    gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, glfw.gl_set_proc_address)
    gl.Viewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
    // Load shaders from file
    ok : bool
    game.shader_program, ok = gl.load_shaders_file(VERTEX_SHADER, FRAGMENT_SHADER)
    if !ok {
        log.errorf("Shader loading failed.")
        os.exit(1)
    }
    game.light_shader_program, ok = gl.load_shaders_file(VERTEX_SHADER_LIGHT, FRAGMENT_SHADER_LIGHT)
    if !ok {
        log.errorf("Shader loading failed.")
        os.exit(1)
    }
    // Enable depth testing
    gl.Enable(gl.DEPTH_TEST)
    // Shader setup
    gl.UseProgram(game.shader_program)
    shader_set_float(game.shader_program, "ambientStrength", AMBIENT_STRENGTH)
    shader_set_float(game.shader_program, "specularStrength", SPECULAR_STRENGTH)
}


game_input :: proc(game: ^Game, dt: f64) {
    if glfw.GetKey(game.window, glfw.KEY_ESCAPE) == glfw.PRESS { glfw.SetWindowShouldClose(game.window, true) }
    if glfw.GetKey(game.window, glfw.KEY_W) == glfw.PRESS { game.camera.pos += game.camera.speed * f32(dt) * game.camera.front }
    else if glfw.GetKey(game.window, glfw.KEY_S) == glfw.PRESS { game.camera.pos -= game.camera.speed * f32(dt) * game.camera.front }
    if glfw.GetKey(game.window, glfw.KEY_A) == glfw.PRESS { game.camera.pos -= game.camera.speed * f32(dt) * glsl.normalize_vec3(glsl.cross_vec3(game.camera.front, game.camera.up)) }
    else if glfw.GetKey(game.window, glfw.KEY_D) == glfw.PRESS { game.camera.pos += game.camera.speed * f32(dt) * glsl.normalize_vec3(glsl.cross_vec3(game.camera.front, game.camera.up)) }
    if glfw.GetKey(game.window, glfw.KEY_E) == glfw.PRESS { game.camera.pos += game.camera.speed * f32(dt) * glsl.normalize_vec3(game.camera.up) }
    else if glfw.GetKey(game.window, glfw.KEY_Q) == glfw.PRESS { game.camera.pos -= game.camera.speed * f32(dt) * glsl.normalize_vec3(game.camera.up) }
    if glfw.GetKey(game.window, glfw.KEY_UP) == glfw.PRESS { game.camera.pitch += 75.0 * f32(dt) }
    else if glfw.GetKey(game.window, glfw.KEY_DOWN) == glfw.PRESS { game.camera.pitch -= 75.0 * f32(dt) }
    if glfw.GetKey(game.window, glfw.KEY_LEFT) == glfw.PRESS { game.camera.yaw -= 75.0 * f32(dt) }
    else if glfw.GetKey(game.window, glfw.KEY_RIGHT) == glfw.PRESS { game.camera.yaw += 75.0 * f32(dt) }
    if game.camera.pitch > 89.0 { game.camera.pitch = 89.0}
    else if game.camera.pitch < -89.0 { game.camera.pitch = -89.0}
    game.camera.front = glsl.normalize_vec3({
        math.cos_f32(glsl.radians_f32(game.camera.yaw)) * math.cos_f32(glsl.radians_f32(game.camera.pitch)),
        math.sin_f32(glsl.radians_f32(game.camera.pitch)),
        math.sin_f32(glsl.radians_f32(game.camera.yaw)) * math.cos_f32(glsl.radians_f32(game.camera.pitch))
    })
}


game_update :: proc(game: ^Game, dt: f64) {
    game.light.pos.x = math.sin_f32(f32(glfw.GetTime())) * 2;
    game.light.pos.y = math.cos_f32(f32(glfw.GetTime())) * 2;
}


game_render :: proc(game: ^Game) {
        // Clear screen
        gl.ClearColor(0.2, 0.3, 0.3, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
        // Set projection matrix
        projection := glsl.mat4Perspective(glsl.radians_f32(game.camera.fov), f32(f32(WINDOW_WIDTH) / f32(WINDOW_HEIGHT)), 0.1, 100.0)
        // Set view matrix
        view := glsl.mat4LookAt(game.camera.pos, game.camera.pos + game.camera.front, game.camera.up)
        // Render entities
        gl.UseProgram(game.shader_program)
        shader_set_mat4(game.shader_program, "projection", projection)
        shader_set_mat4(game.shader_program, "view", view)
        shader_set_vec3(game.shader_program, "viewPos", game.camera.pos)
        shader_set_vec3(game.shader_program, "lightPos", game.light.pos)
        shader_set_vec3(game.shader_program, "lightColor", game.light.color)
        for &entity in game.entities {
            entity_render(&entity, game.shader_program)
        }
        // Render light
        gl.UseProgram(game.light_shader_program)
        shader_set_mat4(game.light_shader_program, "projection", projection)
        shader_set_mat4(game.light_shader_program, "view", view)
        shader_set_vec3(game.light_shader_program, "lightColor", game.light.color)
        entity_render(game.light, game.light_shader_program)
        // Swap buffers
        glfw.SwapBuffers(game.window)
}


game_exit :: proc(game: ^Game) {
    defer glfw.Terminate()
    defer delete(game.models)
    defer delete(game.entities)
    gl.DeleteProgram(game.shader_program)
    models_destroy(&game.models)
}