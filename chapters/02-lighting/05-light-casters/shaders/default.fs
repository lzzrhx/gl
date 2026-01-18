#version 330 core

struct Material {
    sampler2D diffuse;
    sampler2D specular;
    float     shininess;
};

struct Light {
    vec3 pos;
    vec3 diffuse;
    vec3 specular;
};

struct LightDirectional {
    vec3 dir;
    vec3 diffuse;
    vec3 specular;
};

struct LightPoint {
    vec3  pos;
    vec3  diffuse;
    vec3  specular;
    float constant;
    float linear;
    float quadratic;
};

struct LightSpot {
    vec3  pos;
    vec3  dir;
    vec3  diffuse;
    vec3  specular;
    float cutOff;
    float cutOffOuter;
    float constant;
    float linear;
    float quadratic;
};

// Uniforms
uniform vec3 ambientLight;
uniform vec3 viewPos;
uniform Material material;
//uniform Light light;
//uniform LightDirectional lightDirectional;
//uniform LightPoint lightPoint;
uniform LightSpot lightSpot;

// Ins
in vec3 FragPos;
in vec3 Normal;
in vec2 TexCoords;

// Outs
out vec4 FragColor;

void main()
{
    /* LIGHT:
    // Calculate vectors
    vec3 norm = normalize(Normal);
    vec3 lightDir = normalize(light.pos - FragPos);
    vec3 viewDir = normalize(viewPos - FragPos);
    vec3 reflectDir = reflect(-lightDir, norm);
    // Calculate light color values
    vec3 ambient = ambientLight * texture(material.diffuse, TexCoords).rgb;
    vec3 diffuse = light.diffuse * max(dot(norm, lightDir), 0.0) * texture(material.diffuse, TexCoords).rgb;
    vec3 specular = light.specular * pow(max(dot(viewDir, reflectDir), 0.0), material.shininess) * texture(material.specular, TexCoords).rgb;
    // Set final color value
    FragColor = vec4(ambient + diffuse + specular, 1.0);
    */

    /* DIRECTIONAL LIGHT:
    // Calculate vectors
    vec3 norm = normalize(Normal);
    vec3 lightDir = normalize(-lightDirectional.dir);
    vec3 viewDir = normalize(viewPos - FragPos);
    vec3 reflectDir = reflect(-lightDir, norm);
    // Calculate light color values
    vec3 ambient = ambientLight * texture(material.diffuse, TexCoords).rgb;
    vec3 diffuse = lightDirectional.diffuse * max(dot(norm, lightDir), 0.0) * texture(material.diffuse, TexCoords).rgb;
    vec3 specular = lightDirectional.specular * pow(max(dot(viewDir, reflectDir), 0.0), material.shininess) * texture(material.specular, TexCoords).rgb;
    // Set final color value
    FragColor = vec4(ambient + diffuse + specular, 1.0);
    */

    /* POINT LIGHT:
    // Calculate vectors
    vec3 norm = normalize(Normal);
    vec3 lightDir = normalize(lightPoint.pos - FragPos);
    vec3 viewDir = normalize(viewPos - FragPos);
    vec3 reflectDir = reflect(-lightDir, norm);
    // Calculate light color values
    float distance = length(lightPoint.pos - FragPos);
    float attenuation = 1.0 / (lightPoint.constant + lightPoint.linear * distance + lightPoint.quadratic * (distance * distance));
    vec3 ambient = ambientLight * texture(material.diffuse, TexCoords).rgb;
    vec3 diffuse = attenuation * (lightPoint.diffuse * max(dot(norm, lightDir), 0.0) * texture(material.diffuse, TexCoords).rgb);
    vec3 specular = attenuation * (lightPoint.specular * pow(max(dot(viewDir, reflectDir), 0.0), material.shininess) * texture(material.specular, TexCoords).rgb);
    // Set final color value
    FragColor = vec4(ambient + diffuse + specular, 1.0);
    */

    vec3 ambient = ambientLight * texture(material.diffuse, TexCoords).rgb;
    vec3 lightDir = normalize(lightSpot.pos - FragPos);
    float theta = dot(lightDir, normalize(-lightSpot.dir));
    if(theta > lightSpot.cutOffOuter) {

        // Calculate vectors
        vec3 norm = normalize(Normal);
        vec3 viewDir = normalize(viewPos - FragPos);
        vec3 reflectDir = reflect(-lightDir, norm);
        // Calculate light color values
        float distance = length(lightSpot.pos - FragPos);
        float attenuation = 1.0 / (lightSpot.constant + lightSpot.linear * distance + lightSpot.quadratic * (distance * distance));
        float epsilon = lightSpot.cutOff - lightSpot.cutOffOuter;
        float intensity = clamp((theta - lightSpot.cutOffOuter) / epsilon, 0.0, 1.0);
        vec3 diffuse = intensity * attenuation * (lightSpot.diffuse * max(dot(norm, lightDir), 0.0) * texture(material.diffuse, TexCoords).rgb);
        vec3 specular = intensity * attenuation * (lightSpot.specular * pow(max(dot(viewDir, reflectDir), 0.0), material.shininess) * texture(material.specular, TexCoords).rgb);
        // Set final color value
        FragColor = vec4(ambient + diffuse + specular, 1.0);
    }
    else {
        FragColor = vec4(ambient, 1.0);
    }
}