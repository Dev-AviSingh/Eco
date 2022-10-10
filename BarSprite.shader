shader_type canvas_item;
uniform float width;
uniform float height;
uniform float healthPercentageGone;

void fragment(){
	float UVTOFILL = healthPercentageGone;
	
	if(UV.x <= UVTOFILL){
		COLOR.r = 1.0;
		COLOR.g = 1.0;
		COLOR.b = 1.0;
		COLOR.a = 1.0;
	}else{
		COLOR.r = 0.0;
		COLOR.a = 0.0;
	}
	
}