#version 400 core

// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
struct Material {
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    float shininess;
    bool has_diffuse_map;
    bool has_normal_map;
};

struct PointLight {
    vec3 position;
    vec3 color;
    bool enabled;
};
#define N_POINT_LIGHTS 4
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

// Input Variables
layout (location = 0) in vec3 position;
layout (location = 1) in vec2 uvs;
layout (location = 2) in vec3 normal;
layout (location = 3) in vec3 tangent;

// Output Variables
out vec2 pass_uvs;
out vec3 tangent_light_pos[N_POINT_LIGHTS];
out vec3 tangent_view_pos;
out vec3 tangent_frag_pos;
out float dist[N_POINT_LIGHTS];

// Uniform Variables
uniform mat4 projection;
uniform mat4 view;
uniform mat4 transformation;
uniform mat4 inverse_transformation;
uniform vec3 view_pos;
uniform PointLight point_lights[N_POINT_LIGHTS];

void main(void){
    // UVs
    pass_uvs = uvs;

    // Create Normal Matrix and TBN Matrix
    mat3 normal_matrix = mat3(transpose(inverse_transformation));
    vec3 adjusted_normal = normalize(normal_matrix * normal);
    vec3 adjusted_tangent = normalize(normal_matrix * tangent);
    adjusted_tangent = normalize(adjusted_tangent - dot(adjusted_tangent, adjusted_normal) * adjusted_normal);
    vec3 adjusted_bitangent = cross(adjusted_normal, adjusted_tangent);

    mat3 TBN = transpose(mat3(adjusted_tangent, adjusted_bitangent, adjusted_normal));
    vec3 frag_pos = vec3(transformation * vec4(position, 1.0f));

    for(int i = 0; i != N_POINT_LIGHTS; i++){
        if(!point_lights[i].enabled) continue;
        tangent_light_pos[i] = TBN * point_lights[i].position;
        dist[i] = length(point_lights[i].position - frag_pos);
    }

    tangent_view_pos = TBN * view_pos;
    tangent_frag_pos = TBN * frag_pos;
    
    gl_Position = projection * view * transformation * vec4(position.xyz, 1.0);
}
