shader_type canvas_item;

uniform float size = 1;
uniform float r = 0;
uniform vec2 offset = vec2(0,0);
//uniform float x = 0;
//uniform mat2 deform = mat2(vec2(1,0),vec2(0,1));

void vertex()
{
	//mat2 deform = mat2(vec2(cos(r),sin(r)),vec2(-1.0*sin(r), cos(r)));
	//mat2 deform = mat2(vec2(1.0-x,0),vec2(0, 1.0+x));
	float rr = r+PI/2.0;
	vec2 arx = vec2(0,size);
	vec2 ary = vec2(size,0);
	arx *= mat2(vec2(cos(rr),sin(rr)),vec2(-1.0*sin(rr), cos(rr))); // rotate both arrows
	ary *= mat2(vec2(cos(rr),sin(rr)),vec2(-1.0*sin(rr), cos(rr))); //
	mat2 deform = mat2(vec2(1,0)+arx,vec2(0,1)+ary);
	//deform *= mat2(vec2(cos(r),sin(r)),vec2(-1.0*sin(r), cos(r)));
	VERTEX *= deform;
	VERTEX.y += ary.y * offset.y * -2.0;
	VERTEX.x += arx.x * offset.x * -2.0;
	
}


void fragment()
{

}
