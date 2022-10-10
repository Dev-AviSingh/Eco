extends Node2D


# Now the problem with the tilemaps is that those are inefficient, thus to counter that issue
# we wile use the tilemaps only as the visual element of the emvironment and add on the environment
# over the tilemap as separate entities.

var tileMap
var tileMapSize = Vector2.ZERO
var maxNumberOfWaterSoures = 10
var maxNumberOfTrees = 30
var waterAreas = [] # Three dimensional vectors denoting xpos, ypos, sidesize
var bushes = [] # 2D Vector positions of the bushes

var vegetations = [] # All the vegetation items, for updating their age

var waterBlockTemplate
var vegetationTemplate
var vegetationVariants

var vegetationAgeTimer

var maleNames = ["Jeff", "Avi", "Ravi", "Rahul", "Raju", "Rakesh", "Ashu"]
var femaleNames = ["Yumi", "Ashi", "Nimi"]

var tileHashMap = {
	"Plain Grass": 0,
	"Grass Variation 1": 1,
	"Grass Variation 2": 2,
	"Grass Variation 3": 3,
	"Water Left Border": 4,
	"Water Bottom Border": 5,
	"Plain Water": 6,
	"Bush Type 1": 7,
	"Water Bottom Left Border": 8,
	"Single Cell Water": 9,
	"Big Tree": 10
}



# Total number of significant objects.
var numberOfCreatures = 0
var numberOfLivingBeings = 0
var numberOfWaterSources = 0
var numberOfVegetation = 0

var currentlyControlledCreature = null
var currentlyDetailDisplayingCreature = null
var lastDiedCreature = null

# Graph data for the generation representation
var dataPoints = {
	maxHealth = [],
	speed = [],
	attractiveness = [],
	visionSphereRadius = [],
	memory = [],
	maxAcceleration = [],
	altruismFactor = [],
	intimidationFactor = [],
	gestationPeriod = [],
	numberOfChildren = [],
	anger = [],
	attackStrength = [],
	maxAge = []
}

var dayNightCycle

func _ready():
	waterBlockTemplate = preload("res://WorldEnvironmentObjects/Water.tscn")
	vegetationTemplate = preload("res://WorldEnvironmentObjects/Tree.tscn")
	vegetationVariants = preload("res://SpeciesVariants/VegetationVariants.tscn").instance()
	
	vegetationAgeTimer = Timer.new()
	vegetationAgeTimer.wait_time = 1
	vegetationAgeTimer.connect("timeout", self, "incrementAge")
	add_child(vegetationAgeTimer)
	vegetationAgeTimer.start()
	#randomize()
	generateVisualMap()
	generateEnvironmentObjects()

func generateEnvironmentObjects():
	# Creating collision bodies for the objects
	for data in waterAreas:
		var waterBlock = waterBlockTemplate.instance()
		waterBlock.generateBody(data)
		numberOfWaterSources += 1
		waterBlock.tileMap = $TileMap
		numberOfWaterSources += 1
		$"Living Creatures".add_child(waterBlock)
		
	for treePos in bushes:
		var newVegetation = vegetationTemplate.instance()
		$"Living Creatures".add_child(newVegetation)
		numberOfVegetation += 1
		if randi() % 2 == 0:
			$TileMap.set_cell(treePos.x, treePos.y, tileHashMap["Big Tree"])
			newVegetation.setGeneSet(vegetationVariants.variants.bigTree)
		else:
			$TileMap.set_cell(treePos.x, treePos.y, tileHashMap["Bush Type 1"])
			newVegetation.setGeneSet(vegetationVariants.variants.bush)
	
		
		vegetations.append(newVegetation)
		newVegetation.worldGenerator = self
		newVegetation.position.x = treePos.x * 32 + 16
		newVegetation.position.y = treePos.y * 32 + 16
		newVegetation.tilePosition = treePos
		newVegetation.tileMap = $TileMap
	

func generateVisualMap():
	# Creating tiles of the objects and their positions
	tileMapSize.x = int(get_viewport_rect().size.x / $TileMap.cell_size.x)
	tileMapSize.y = int(get_viewport_rect().size.y / $TileMap.cell_size.y)
	
	# Generate water blocks:
	for _index in range(maxNumberOfWaterSoures):
		# Going for only square water sources for the sake of simplicity.
		var side = randi() % 5 + 1 # Size of each water source square
		var initialX = randi() % int(tileMapSize.x - side)
		var initialY = randi() % int(tileMapSize.x - side)
		
		
		for waterArea in waterAreas:
			if initialX >= waterArea.x and initialX <= waterArea.x + waterArea.z:
				initialX += waterArea.z # Shift the water source by the intersecting water source's side size.
				
				# Shift the water source to the left of the screen if it extends beyond the right border.
				if initialX + side > tileMapSize.x:
					initialX = initialX + side - tileMapSize.x
			
			if initialY >= waterArea.y and initialY <= waterArea.y + waterArea.z:
				initialY += waterArea.z # Shift the water source by the intersecting water source's side size.
				
				# Shift the water source to the left of the screen if it extends beyond the right border.
				if initialY + side > tileMapSize.y:
					initialY = initialY + side - tileMapSize.y
			
		waterAreas.append(Vector3(initialX, initialY, side))
		
		# If the water source is a single block
		if side == 1:
			$TileMap.set_cell(initialX, initialY, tileHashMap["Single Cell Water"])
			continue
		for y in range(side):
			for x in range(side):
				var xpos = initialX + x
				var ypos = initialY + y
				
				# Corners
				# If the block is the top left corner
				if (xpos == initialX and ypos == initialY):
					$TileMap.set_cell(xpos, ypos, tileHashMap["Water Bottom Left Border"], false, true) # Y flipped
				# If the block is the bottom right corner
				elif (xpos == initialX + side - 1 and ypos == initialY + side - 1):
					$TileMap.set_cell(xpos, ypos, tileHashMap["Water Bottom Left Border"], true, false) # X flipped
				# If the block is the top right corner
				elif (xpos == initialX + side - 1 and ypos == initialY):
					$TileMap.set_cell(xpos, ypos, tileHashMap["Water Bottom Left Border"], true, true) # X and Y flipped
				# If the block is the bottom left corner
				elif (xpos == initialX and ypos == initialY + side - 1):
					$TileMap.set_cell(xpos, ypos, tileHashMap["Water Bottom Left Border"], false, false) # not flipped
				
				# Borders
				# If the block is a upper boundary
				elif (ypos == initialY and xpos != initialX and xpos != initialX + side - 1):
					$TileMap.set_cell(xpos, ypos, tileHashMap["Water Bottom Border"], false, true) # Y flipped
				# If the block is a lower boundary
				elif (ypos == initialY + side - 1 and xpos != initialX and xpos != initialX + side - 1):
					$TileMap.set_cell(xpos, ypos, tileHashMap["Water Bottom Border"]) # not flipped					
				# If the block is a left border
				elif (xpos == initialX and ypos != initialY and ypos != initialY + side - 1):
					$TileMap.set_cell(xpos, ypos, tileHashMap["Water Left Border"]) # not flipped
				# If the border is a right border
				elif (xpos == initialX + side - 1 and ypos != initialY and ypos != initialY + side - 1):
					$TileMap.set_cell(xpos, ypos, tileHashMap["Water Left Border"], true, false) # X flipped
				# If it's in the center
				else:
					$TileMap.set_cell(xpos, ypos, tileHashMap["Plain Water"])

	# Generate trees
	for _index in range(maxNumberOfTrees):
		# Place the tree randomly on any spot and make sure there are no water blocks there.
		while true:
			var xpos = randi() % int(tileMapSize.x)
			var ypos = randi() % int(tileMapSize.y)
			
			# If the cell is empty.
			if $TileMap.get_cell(xpos, ypos) == -1:
				bushes.append(Vector2(xpos, ypos))
				break
	
	
	for ypos in range(tileMapSize.y + 1):
		for xpos in range(tileMapSize.x):
			if $TileMap.get_cell(xpos, ypos) == -1:
				var randomTile = randi() % 20 + 11 #The tile number for the grass types
				$TileMap.set_cell(xpos, ypos, randomTile, false, false) # Random grass tiles


func incrementAge():
	for vegetation in vegetations:
		vegetation.incrementAge()


func _process(_delta):
	pass
