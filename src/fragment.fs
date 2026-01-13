#version 330 core
out vec4 FragColor;
in vec3 vertexColor;
//uniform vec4 customColor;

void main()
{
    //FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
    FragColor = vec4(vertexColor, 1.0);
    //FragColor = customColor;
}