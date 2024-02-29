shader_type canvas_item;

// scrolling starfield background

uniform float scroll_speed : hint_range(0.0, 1.0) = 0.08;
uniform vec4 bg_color : source_color = vec4(0.02, 0.02, 0.06, 1.0);

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float star_layer(vec2 uv, float density, float thresh) {
	vec2 grid = uv * density;
	vec2 id = floor(grid);
	vec2 f = fract(grid) - 0.5;
	float h = hash(id);
	float brightness = step(thresh, h);
	float d = length(f);
	float point = smoothstep(0.08, 0.0, d) * brightness;
	float twinkle = 0.6 + 0.4 * sin(TIME * 2.0 + h * 100.0);
	return point * twinkle;
}

void fragment() {
	vec2 uv = UV;
	float s = 0.0;
	s += star_layer(uv + vec2(0.0, TIME * scroll_speed), 40.0, 0.97);
	s += star_layer(uv + vec2(0.0, TIME * scroll_speed * 0.5), 20.0, 0.93) * 0.6;
	COLOR = vec4(bg_color.rgb + vec3(s), 1.0);
}
