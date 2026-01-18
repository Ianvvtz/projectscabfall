shader_type canvas_item;

uniform vec4 hit_flash_color : source_color = vec4(1.0);
uniform float flash_pct : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 sprite_color = texture(TEXTURE, UV);
	vec4 mixed = mix(sprite_color, hit_flash_color, flash_pct);
	COLOR = vec4(mixed.rgb, sprite_color.a);
}