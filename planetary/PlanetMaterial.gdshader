shader_type spatial;

uniform float min_height;
uniform float max_height;
varying float height;
uniform sampler2D height_color;


void vertex() {
	// Called for every vertex the material is visible on.
	height = length(VERTEX);

}

void fragment() {
	float t = height / (max_height-min_height) - (min_height / (max_height-min_height));
	vec3 color = texture(height_color, vec2(t, 0.0)).rgb;
	ALBEDO = color;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
