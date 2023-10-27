shader_type spatial;

uniform sampler2D screen_tex : hint_screen_texture;
uniform sampler2D depth_tex : hint_depth_texture;

uniform float metallic : hint_range(0, 1) = 0;
uniform float roughness : hint_range(0, 1) = 0.00999999977648;
uniform float specular : hint_range(0, 5) = 2;

// Water
uniform vec4 deep_water : source_color = vec4(0.556863, 0.819608, 0.890196, 0.333333);
uniform vec4 shallow_water : source_color = vec4(0.811765, 0.956863, 0.996078, 0.333333);

uniform float murkiness = 0.3;
uniform float refraction = 0.1;
uniform vec4 color_factor = vec4(0.5, 0.5, 0.5, 0.5);

// Caustics
uniform sampler2D caustic_a;
uniform sampler2D caustic_b;
uniform float caustic_speed_a : hint_range(-4, 4) = 0.00499999988824;
uniform float caustic_speed_b : hint_range(-4, 4) = 0.02500000037253;
uniform float caustic_strength_a : hint_range(-4, 4) = 1;
uniform float caustic_strength_b : hint_range(-4, 4) = 1.5;
uniform float caustic_power = 3;
uniform float caustic_type : hint_range(0, 1) = 1;

// Simulations
uniform sampler2D simulation;
uniform vec2 viewport_size = vec2(1024, 1024);

// Vertex Waves
uniform float wave_speed : hint_range(-50, 50) = 1;
uniform float wave_frequency : hint_range(-10, 10) = 0.80000001192093;
uniform float wave_scale : hint_range(-1, 1) = 0.20000000298023;
uniform float sim_amplitude = 0.5;

void fragment() {
	//*** Declarations ***//
	// Linear Scene Depth
	float LINEAR_SCENE_DEPTH;
	{
		float log_depth = textureLod(depth_tex, SCREEN_UV, 0.0).x;
		vec4 depth_view = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, log_depth, 1.0);
		depth_view.xyz /= depth_view.w;
		LINEAR_SCENE_DEPTH = -depth_view.z;
	}
	//*** End Declarations ***//

	// Delta UV Normal
	vec3 duv_normal;
	{
		vec3 duv = vec3(4.0 / viewport_size.x, 4.0 / viewport_size.x, 0);
		float v1 = texture(simulation, UV - duv.xz).y;
		float v2 = texture(simulation, UV + duv.xz).y;
		float v3 = texture(simulation, UV - duv.zy).y;
		float v4 = texture(simulation, UV + duv.zy).y;

		duv_normal = normalize(vec3(v1 - v2, v3 - v4, 0.3));
	}

	// Get Water Color
	vec4 water_color;
	{
		float d = LINEAR_SCENE_DEPTH;
		d = d + VERTEX.z;
		float depth = exp(-d * murkiness);
		water_color = mix(deep_water, shallow_water, depth);
	}

	ALPHA = water_color.a;

	// Add Refraction to Water Color
	{
		vec4 refraction_color = texture(screen_tex, (refraction * duv_normal).xy + SCREEN_UV);
		water_color = mix(refraction_color, water_color, color_factor);
	}

	// Add Surface Caustics to Water Color
	{
		// UV Panning
		vec2 scale = vec2(1.0, 1.0);
		vec2 uv_a = vec2(sin(TIME * caustic_speed_a)) * scale + UV;
		vec2 uv_b = vec2(cos(TIME * caustic_speed_b)) * scale + UV;

		vec4 amped_caustic_a = vec4(texture(caustic_a, uv_a)) * vec4(caustic_strength_a);
		vec4 amped_caustic_b = vec4(texture(caustic_b, uv_b)) * vec4(caustic_strength_b);

		vec4 add_caustics = pow(vec4(amped_caustic_a + amped_caustic_b), vec4(caustic_power));
		vec4 mul_caustics = pow(vec4(amped_caustic_a * amped_caustic_b), vec4(caustic_power));

		water_color = mix(add_caustics, mul_caustics, caustic_type) + water_color;
	}

	/*
	float n_out108p0;
	// ProximityFade:108
	float n_in108p0 = 1.00000;
	{
		float __depth_tex = texture(depth_tex_frg_108, SCREEN_UV).r;
		vec4 __depth_world_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, __depth_tex, 1.0);
		__depth_world_pos.xyz /= __depth_world_pos.w;
		n_out108p0 = clamp(1.0 - smoothstep(__depth_world_pos.z + n_in108p0, __depth_world_pos.z, VERTEX.z), 0.0, 1.0);
	}

	// Add Foam to Water Color
	//{
		float foam_strength = texture(depth_tex, SCREEN_UV).x;
		vec4 foam_color = vec4(1.0, 1.0, 1.0, 1.0);

		float foam_strength = 0.0;

		distance_to_nearest_surface()

		float distance_to_object = texture(DISTANCE_FIELD_TEXTURE, SCREEN_UV).x;

		water_color = mix(water_color, foam_color, foam_strength);

	}
	*/

	ALBEDO = water_color.rgb;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;
}

void vertex() {
	// Wave Generation
	vec3 wavePos;
	{
		vec3 modelVertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		float waveTime = wave_speed * TIME;

		float frequency = sin(waveTime + (wave_frequency * modelVertex.x)) + cos(waveTime + (modelVertex.z * wave_frequency));

		wavePos = vec3(
			modelVertex.x,
			modelVertex.y + (step(0.5, modelVertex.y) * (frequency * wave_scale)),
			modelVertex.z
		);
	}

	// Ripple Simulation
	{
		wavePos = (VERTEX + (NORMAL * (texture(simulation, UV).r * sim_amplitude))) + wavePos;
		wavePos /= vec3(2.0, 4.0, 2.0);
	}

	VERTEX = wavePos;
}
