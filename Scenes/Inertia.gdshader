shader_type canvas_item;

uniform float amplitude = 20.f;
uniform float speed = 2.f;
uniform vec2 dir = vec2(10,-10);

uniform vec2 line_point = vec2(0,0); // Un point sur la ligne
uniform vec2 line_dir = vec2(1,1);  // Direction de la ligne

void vertex() {
	//VERTEX =  mix(VERTEX,VERTEX+dir,pow(distance(VERTEX.y,16)/32.0,2));
	vec2 line_dir_norm = normalize(line_dir);
	vec2 pts = VERTEX - line_point;
	float proj_len = dot(pts,line_dir_norm);
	vec2 proj_pts = line_point + proj_len * line_dir_norm;
	VERTEX = mix(VERTEX,proj_pts,0.5);
}

void fragment() {

}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
