extends Area2D

var vp # View port
func _ready():
	vp = get_viewport()

func _process(_delta):
	position = vp.get_mouse_position()
	if Input.is_mouse_button_pressed(BUTTON_RIGHT):
		for overlappingBody in get_overlapping_bodies():
			if "biologicalFamily" in overlappingBody:
				if overlappingBody.biologicalFamily == "Animal":
					overlappingBody.die()
	

