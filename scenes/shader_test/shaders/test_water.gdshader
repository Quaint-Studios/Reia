shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform vec4 ShallowColor : source_color = vec4(0.000000, 0.564869, 0.920949, 1.000000);
uniform vec4 DeepColor : source_color = vec4(0.000000, 0.196078, 0.337255, 0.000000);
uniform float DepthPower : hint_range(0, 1) = 1;
uniform float DepthScale : hint_range(0, 1) = 0.75;
uniform float DepthFoam : hint_range(0, 1) = 0;
uniform float FoamWidth : hint_range(0, 1) = 0.5;
uniform float FoamNoise : hint_range(-5, 5) = 2;
uniform sampler2D NormalMap : hint_normal;
uniform float BumpStrength : hint_range(0, 1) = 0.5;
uniform float DetailStrength : hint_range(0, 1) = 0.20000000298023;

// Varyings
varying vec2 v_normalized_screen_position;

uniform sampler2D depth_tex_frg_46 : hint_depth_texture;


// GlobalExpression:0
	float saturate(float input, float minVal, float maxVal) {
		return clamp(input, minVal, maxVal);
	}

void vertex() {
	v_normalized_screen_position = vec2(0.0);
}

void fragment() {
// ParameterRef:104
	vec3 n_out104p0 = ShallowColor.rgb;
	float n_out104p1 = ShallowColor.a;


// VectorDecompose:105
	float n_out105p0 = n_out104p0.x;
	float n_out105p1 = n_out104p0.y;
	float n_out105p2 = n_out104p0.z;


// VectorCompose:106
	vec4 n_out106p0 = vec4(n_out105p0, n_out105p1, n_out105p2, n_out104p1);


// ParameterRef:25
	vec3 n_out25p0 = DeepColor.rgb;
	float n_out25p1 = DeepColor.a;


// VectorDecompose:107
	float n_out107p0 = n_out25p0.x;
	float n_out107p1 = n_out25p0.y;
	float n_out107p2 = n_out25p0.z;


// VectorCompose:108
	float n_in108p3 = 0.00000;
	vec4 n_out108p0 = vec4(n_out107p0, n_out107p1, n_out107p2, n_in108p3);


	float n_out46p0;
// LinearSceneDepth:46
	{
		float __log_depth = textureLod(depth_tex_frg_46, SCREEN_UV, 0.0).x;
	vec4 __depth_view = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, __log_depth, 1.0);
		__depth_view.xyz /= __depth_view.w;
		n_out46p0 = -__depth_view.z;
	}


// VaryingGetter:140
	vec2 n_out140p0 = v_normalized_screen_position;


// VectorDecompose:48
	float n_out48p0 = vec4(n_out140p0, 0.0, 0.0).x;
	float n_out48p1 = vec4(n_out140p0, 0.0, 0.0).y;
	float n_out48p2 = vec4(n_out140p0, 0.0, 0.0).z;
	float n_out48p3 = vec4(n_out140p0, 0.0, 0.0).w;


// FloatOp:49
	float n_out49p0 = n_out46p0 - n_out48p3;


// Input:43
	vec3 n_out43p0 = NORMAL;


// VectorDecompose:44
	float n_out44p0 = n_out43p0.x;
	float n_out44p1 = n_out43p0.y;
	float n_out44p2 = n_out43p0.z;


// FloatFunc:42
	float n_out42p0 = min(max(n_out44p1, 0.0), 1.0);


// FloatOp:40
	float n_in40p0 = 1.00000;
	float n_out40p0 = n_in40p0 - n_out42p0;


// FloatOp:39
	float n_in39p1 = 0.85000;
	float n_out39p0 = n_out40p0 * n_in39p1;


// FloatFunc:38
	float n_out38p0 = min(max(n_out39p0, 0.0), 1.0);


// FloatOp:37
	float n_in37p0 = 1.00000;
	float n_out37p0 = n_in37p0 - n_out38p0;


// FloatOp:36
	float n_out36p0 = n_out49p0 * n_out37p0;


// FloatOp:41
	float n_in41p1 = 1.00000;
	float n_out41p0 = n_out40p0 * n_in41p1;


// FloatOp:23
	float n_out23p0 = n_out36p0 + n_out41p0;


// ParameterRef:35
	float n_out35p0 = DepthScale;


// FloatOp:22
	float n_out22p0 = n_out23p0 * n_out35p0;


// ParameterRef:34
	float n_out34p0 = DepthPower;


// FloatOp:20
	float n_out20p0 = pow(n_out22p0, n_out34p0);


// FloatOp:8
	float n_in8p1 = 0.65000;
	float n_out8p0 = n_out20p0 * n_in8p1;


// FloatFunc:7
	float n_out7p0 = min(max(n_out8p0, 0.0), 1.0);


// Mix:4
	vec4 n_out4p0 = mix(n_out106p0, n_out108p0, vec4(n_out7p0));


// Mix:13
	vec4 n_in13p1 = vec4(1.00000, 1.00000, 1.00000, 1.00000);
	vec4 n_in13p2 = vec4(0.50000, 0.50000, 0.50000, 0.50000);
	vec4 n_out13p0 = mix(n_out4p0, n_in13p1, n_in13p2);


// ParameterRef:33
	vec3 n_out33p0 = ShallowColor.rgb;
	float n_out33p1 = ShallowColor.a;


// VectorDecompose:100
	float n_out100p0 = n_out33p0.x;
	float n_out100p1 = n_out33p0.y;
	float n_out100p2 = n_out33p0.z;


// VectorCompose:101
	float n_in101p3 = 0.00000;
	vec4 n_out101p0 = vec4(n_out100p0, n_out100p1, n_out100p2, n_in101p3);


// ParameterRef:28
	vec3 n_out28p0 = DeepColor.rgb;
	float n_out28p1 = DeepColor.a;


// VectorDecompose:102
	float n_out102p0 = n_out28p0.x;
	float n_out102p1 = n_out28p0.y;
	float n_out102p2 = n_out28p0.z;


// VectorCompose:103
	float n_in103p3 = 0.00000;
	vec4 n_out103p0 = vec4(n_out102p0, n_out102p1, n_out102p2, n_in103p3);


// FloatFunc:19
	float n_out19p0 = min(max(n_out20p0, 0.0), 1.0);


// Mix:16
	vec4 n_out16p0 = mix(n_out101p0, n_out103p0, vec4(n_out19p0));


// ParameterRef:64
	float n_out64p0 = FoamWidth;


// FloatOp:62
	float n_in62p0 = 1.00000;
	float n_out62p0 = n_in62p0 - n_out64p0;


// FloatOp:65
	float n_in65p1 = 10.00000;
	float n_out65p0 = n_out62p0 * n_in65p1;


// ParameterRef:59
	float n_out59p0 = DepthFoam;


// FloatOp:57
	float n_in57p0 = 1.00000;
	float n_out57p0 = n_in57p0 / n_out59p0;


// FloatOp:56
	float n_out56p0 = n_out49p0 * n_out57p0;


// FloatOp:55
	float n_in55p0 = 1.00000;
	float n_out55p0 = n_in55p0 - n_out56p0;


// FloatFunc:54
	float n_out54p0 = min(max(n_out55p0, 0.0), 1.0);


// Input:53
	vec4 n_out53p0 = COLOR;


// VectorDecompose:52
	float n_out52p0 = n_out53p0.x;
	float n_out52p1 = n_out53p0.y;
	float n_out52p2 = n_out53p0.z;
	float n_out52p3 = n_out53p0.w;


// FloatOp:50
	float n_out50p0 = max(n_out54p0, n_out52p0);


// FloatOp:61
	float n_in61p1 = 2.00000;
	float n_out61p0 = n_out50p0 * n_in61p1;


// FloatOp:66
	float n_in66p1 = 2.00000;
	float n_out66p0 = pow(n_out61p0, n_in66p1);


// FloatOp:67
	float n_in67p1 = 1.50000;
	float n_out67p0 = n_out66p0 * n_in67p1;


// FloatOp:68
	float n_out68p0 = n_out65p0 - n_out67p0;


// VectorOp:113
	vec2 n_in113p0 = vec2(0.00000, 0.00000);
	vec2 n_in113p1 = vec2(1.00000, 1.00000);
	vec2 n_out113p0 = n_in113p0 + n_in113p1;


	vec4 n_out133p0;
// Texture2D:133
	n_out133p0 = texture(NormalMap, n_out113p0);


// VectorDecompose:114
	float n_out114p0 = n_out133p0.x;
	float n_out114p1 = n_out133p0.y;
	float n_out114p2 = n_out133p0.z;
	float n_out114p3 = n_out133p0.w;


// VectorOp:131
	vec2 n_in131p0 = vec2(0.00000, 0.00000);
	vec2 n_in131p1 = vec2(1.00000, 0.00000);
	vec2 n_out131p0 = n_in131p0 + n_in131p1;


	vec4 n_out132p0;
// Texture2D:132
	n_out132p0 = texture(NormalMap, n_out131p0);


// VectorDecompose:98
	float n_out98p0 = n_out132p0.x;
	float n_out98p1 = n_out132p0.y;
	float n_out98p2 = n_out132p0.z;
	float n_out98p3 = n_out132p0.w;


// FloatOp:74
	float n_out74p0 = n_out114p0 * n_out98p1;


// FloatOp:75
	float n_out75p0 = n_out114p1 * n_out98p0;


// FloatOp:73
	float n_out73p0 = n_out74p0 + n_out75p0;


// ParameterRef:72
	float n_out72p0 = FoamNoise;


// FloatOp:70
	float n_out70p0 = n_out73p0 * n_out72p0;


// FloatOp:69
	float n_out69p0 = step(n_out68p0, n_out70p0);


// Mix:31
	vec4 n_in31p1 = vec4(1.00000, 1.00000, 1.00000, 1.00000);
	vec4 n_out31p0 = mix(n_out16p0, n_in31p1, vec4(n_out69p0));


// VectorDecompose:15
	float n_out15p0 = n_out31p0.x;
	float n_out15p1 = n_out31p0.y;
	float n_out15p2 = n_out31p0.z;
	float n_out15p3 = n_out31p0.w;


// FloatOp:14
	float n_in14p0 = 1.00000;
	float n_out14p0 = n_in14p0 - n_out15p3;


// FloatFunc:12
	float n_out12p0 = min(max(n_out14p0, 0.0), 1.0);


// IntOp:3
	int n_in3p0 = 1;
	int n_out3p0 = n_in3p0 - int(n_out12p0);


// VectorOp:2
	vec4 n_out2p0 = n_out13p0 * vec4(float(n_out3p0));


// Output:0
	ALBEDO = vec3(n_out2p0.xyz);


}
