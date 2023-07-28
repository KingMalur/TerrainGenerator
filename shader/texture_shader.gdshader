shader_type spatial;

uniform sampler2D terrain_grass;
uniform sampler2D terrain_rock;

uniform float min_grass_height = -0.30;
uniform float max_rock_height = 1.6;

varying float vertex_y;
uniform vec2 uv_scale = vec2(1);


void fragment() {
	float vert_weight = vertex_y;
	
	vec3 grass = texture(terrain_grass, UV * uv_scale).rgb;
	vec3 rock = texture(terrain_rock, UV * uv_scale).rgb;
	
	float weight = smoothstep(min_grass_height, max_rock_height, vert_weight);
	vec3 final_color = mix(grass, rock, weight);
	
	ALBEDO = final_color.rgb;
}


void vertex() {
	vertex_y = VERTEX.y;
}
