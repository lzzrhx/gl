#version 330 core

// Uniforms
uniform vec3 objectColor;
uniform vec3 lightColor;
uniform vec3 lightPos;
uniform vec3 viewPos;
uniform float ambientStrength;
uniform float specularStrength;

// Ins
in vec3 FragPos;
in vec3 Normal;

// Outs
out vec4 FragColor;

void main()
{
    // Calculate vectors
    vec3 norm = normalize(Normal);
    vec3 lightDir = normalize(lightPos - FragPos);
    vec3 viewDir = normalize(viewPos - FragPos);
    vec3 reflectDir = reflect(-lightDir, norm);
    // Calculate light strengths
    vec3 ambient = ambientStrength * lightColor;
    vec3 diffuse = max(dot(norm, lightDir), 0.0) * lightColor;
    vec3 specular = pow(max(dot(viewDir, reflectDir), 0.0), 16) * specularStrength * lightColor;
    // Set final color value
    vec3 result = (ambient + diffuse + specular) * objectColor;
    FragColor = vec4(result, 1.0);
}