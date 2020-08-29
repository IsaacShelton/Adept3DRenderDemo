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
in vec2 pass_uvs;
in vec3 tangent_light_pos[N_POINT_LIGHTS];
in vec3 tangent_view_pos;
in vec3 tangent_frag_pos;
in float dist[N_POINT_LIGHTS];

// Output Variables
out vec4 out_color;

// Uniform Variables
uniform sampler2D diffuse_map;
uniform sampler2D normal_map;
uniform Material material;
uniform PointLight point_lights[N_POINT_LIGHTS];

// Helper Functions
vec3 lighting_for_point_light(int i, vec3 normal, vec3 view_dir);

void main(void){
    // Determine final normal (in tangent space)
    vec3 final_normal;

    if(material.has_normal_map){
        final_normal = normalize(2.0f * texture(normal_map, pass_uvs).xyz - 1.0f);
    } else {
        final_normal = vec3(0.0f, 0.0f, 1.0f);
    }

    // Determine view direction
    vec3 view_dir = normalize(-tangent_view_pos - tangent_frag_pos);

    // Do lighting for each point light
    vec3 result = vec3(0.0f);
    
    for(int i = 0; i != N_POINT_LIGHTS; i++){
        if(!point_lights[i].enabled) continue;
        result += lighting_for_point_light(i, final_normal, view_dir);
    }

    // Gamma Correction
    result = pow(result, vec3(1.0/2.2));
    
    // Set output color
    out_color = vec4(result, 1.0f);
}

vec3 lighting_for_point_light(int i, vec3 normal, vec3 view_dir){
    PointLight light = point_lights[i];

    vec3 diffuse_color = material.has_diffuse_map ? texture(diffuse_map, pass_uvs).xyz : material.diffuse;
    vec3 light_dir = normalize(tangent_light_pos[i] - tangent_frag_pos);
    float diff = max(dot(light_dir, normal), 0.0);
    vec3 halfway_dir = normalize(light_dir + view_dir);
    float spec = pow(max(dot(normal, halfway_dir), 0.0f), material.shininess);

    vec3 ambient  = light.color * material.ambient;
    vec3 diffuse  = light.color * diff * diffuse_color;
    vec3 specular = light.color * spec * material.specular;

    const float light_constant = 1.0f;
    const float light_linear = 0.027f;    
    const float light_quadratic = 0.0028f;

    // simple attenuation
    //float max_distance = 1.5;
    float light_distance = dist[i];
    float attenuation = 1.0 / (light_constant + light_linear * light_distance + 
                light_quadratic * (light_distance * light_distance));

    return (diffuse + specular) * attenuation;
}
