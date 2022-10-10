extends KinematicBody2D



# This script will generate the collision body of the water and generate the shaders accordingly.
var biologicalFamily = "Water"
var waterAmount = 50 # Water amount of single water block
var positionData_
var tileMap
func _ready():
	pass # Replace with function body.

func generateBody(positionData):
	 # 32 is the size of a single cell. Position data z is the cell span of the water source
	var newShape = RectangleShape2D.new()
	newShape.extents = Vector2(int(positionData.z * 32 / 2), int(positionData.z * 32 / 2))
	$CollisionShape2D.set_shape(newShape)
	
	waterAmount = waterAmount * positionData.z * positionData.z # side x side = total number of blocks
	
	# The xpos and ypos from the grid translated to global positions
	position.x = positionData.x  * 32 + (int(positionData.z * 32 / 2))
	position.y = positionData.y  * 32 + (int(positionData.z * 32 / 2))
	
	positionData_ = positionData
	set_process(false)
	set_physics_process(false)

func killSelf():
	for y in range(positionData_.y, positionData_.y + positionData_.z):
		for x in range(positionData_.x, positionData_.x + positionData_.z):
			tileMap.set_cell(x, y, randi() % 20 + 11) # replace all the waterblocks with a random variation of grass
	queue_free()

func getWater(amount):
	# Reduce the water level, if water lesser than 0, delete self.
	waterAmount -= amount
	
	if waterAmount < 0:
		killSelf()
		return amount + waterAmount
	return amount
