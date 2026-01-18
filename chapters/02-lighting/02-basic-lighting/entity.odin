package main

import "core:math/linalg/glsl"
import gl "vendor:OpenGL"
import "vendor:glfw"

Entity :: struct {
    pos:   glsl.vec3,
    scale: glsl.vec3,
    color:  glsl.vec3,
    model: ^Model,
}

entity_new :: proc(entities: ^[dynamic]Entity, model: ^Model, pos: glsl.vec3) {
    append(entities, Entity{ pos = pos, model = model })
}

entity_render :: proc(entity: ^Entity, shader_program: u32) {
    // Bind vertex array object
    gl.BindVertexArray(entity.model.vao)
    // Model matrix
    model: glsl.mat4 = 1
    model *= glsl.mat4Translate(entity.pos)
    model *= glsl.mat4Scale(entity.scale)
    shader_set_mat4(shader_program, "model", model)
    shader_set_mat3(shader_program, "normal", glsl.mat3(glsl.inverse_transpose(model)));
    shader_set_vec3(shader_program, "objectColor", entity.color)
    // Draw primitves
    gl.DrawArrays(gl.TRIANGLES, 0, 36)
}