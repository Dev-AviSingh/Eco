extends KinematicBody2D

# This script can be universally used for all types of vegetation.
# The trees will also have an age, reproductive factor and etc. This will be implemented after the testing for basic getting eaten abilities are implemented and the living being creature is tested.
# Add death particle effects
var biologicalFamily = "Vegetation"
var foodValue = 10
var deathTimer
var age = 0
var tilePosition = Vector2.ZERO
var tileMap = null
var worldGenerator

var geneSet = {
	seedSpreadingRadius = 2,
	foodValueFactor = 10,
	maxAge = 200,
	numerOfSeeds = 2
}
# Gene Values
#var seedSpreadingRadius = 2 # The radius of blocks around the vegetation for the newborn to plant itself
#var foodValueFactor = 10 # The factor by which the food value of the vegetation increases each lifeStep
#var maxAge = 200
#var numberOfSeeds = 2

var maturityAge = geneSet["maxAge"] / 4

# Called when the node enters the scene tree for the first time.
func _ready():
	deathTimer = Timer.new()
	deathTimer.wait_time = 1
	deathTimer.connect('timeout', self, "death")
	add_child(deathTimer)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func incrementAge():
	foodValue += geneSet["foodValueFactor"]
	age += 1
	if age > geneSet["maxAge"]:
		death()

func createChild(vegetationTile):
	# Random position in a square region with self in the center and the side is the seedSpreadingRadius * 2
	var xpos = randi() % int(max(tilePosition.x + geneSet["seedSpreadingRadius"], 1)) + (tilePosition.x - geneSet["seedSpreadingRadius"])
	var ypos = randi() % int(max(tilePosition.y + geneSet["seedSpreadingRadius"], 1)) + (tilePosition.y - geneSet["seedSpreadingRadius"])
	
	# limit the position withing the map
	xpos = max(0, xpos)
	xpos= min(xpos, int(get_viewport_rect().size.x / tileMap.cell_size.x) - 1)
	ypos = max(0, ypos)
	ypos= min(ypos, int(get_viewport_rect().size.y / tileMap.cell_size.y) - 1)
	
	while true:
		if tileMap.get_cell(xpos, ypos) in [4, 5, 6, 8, 9]: # If the tile is water
			xpos += 1
			ypos += 1
		else:
			break
	
	# Continue to make a new tree, same process as in the world gen.
	tileMap.set_cell(xpos, ypos, vegetationTile)
	
	var vegetationTemplate = load("res://WorldEnvironmentObjects/Tree.tscn")
	var newVegetation = vegetationTemplate.instance()
	
	newVegetation.setGeneSet(mutateGeneSet(geneSet))
	
	get_parent().add_child(newVegetation)
	worldGenerator.vegetations.append(newVegetation)
	
	newVegetation.worldGenerator = worldGenerator
	newVegetation.position.x = xpos * 32 + 16
	newVegetation.position.y = ypos * 32 + 16
	newVegetation.tilePosition = Vector2(xpos, ypos)
	newVegetation.tileMap = tileMap
	

	print(newVegetation.position, " ", newVegetation.tilePosition)

func setGeneSet(newGeneSet):
	for value in newGeneSet.keys():
		self.geneSet[value] = newGeneSet[value]
	maturityAge = geneSet["maxAge"] / 4

func mutateGeneSet(oldGeneSet):
	var mutationFactor = 2
	for value in oldGeneSet.keys():
		oldGeneSet[value] += (randi() % mutationFactor - mutationFactor)
	return oldGeneSet

func death():
	worldGenerator.vegetations.remove(worldGenerator.vegetations.find(self))
	for _x in range(geneSet["numberOfSeeds"]):
		createChild(tileMap.get_cell(tilePosition.x, tilePosition.y))
	tileMap.set_cell(tilePosition.x, tilePosition.y, randi() % 20 + 11)# 11 to 20 are the grass variation types
	queue_free()

func getEaten():
	deathTimer.start()
	return foodValue
