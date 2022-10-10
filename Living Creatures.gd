extends Node2D


var livingBeingTemplate
var livingBeings = []
var timer
var ageTimer
var screenSize
var allowSpawn = true
var viewPort
var isFemale = false
var mainWorld
var currentSpawnType = "prey" # Prey, Predator, Scavenger, Vegetation

var currentSpawnVariant = "chicken" # The name of the variant being spawned
var currentGeneSet = null # The pure gene set for that particular variant

var displayingCreatureDetails = false
var controllingCreature = false

var canvasModulate

var creatureAgeTimeStep = 1
var dayNightCycleModulateFactor = creatureAgeTimeStep / 24.0
var currentModulate = 1
var isDay = true

var livingBeingVariants 

# Called when the node enters the scene tree for the first time.
func _ready():
	livingBeingTemplate = preload("res://LivingBeing.tscn")
	livingBeingVariants = preload("res://SpeciesVariants/LivingBeingVariants.tscn").instance()
	setSpawnVariant(currentSpawnVariant)
	screenSize = get_viewport_rect().size
	viewPort = get_viewport()
	mainWorld = get_parent()
	canvasModulate = mainWorld.get_node("CanvasModulate")
	
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = creatureAgeTimeStep
	timer.connect("timeout", self, "enableSpawn")
	timer.start()
	
	ageTimer = Timer.new()
	add_child(ageTimer)
	ageTimer.wait_time = creatureAgeTimeStep
	ageTimer.connect("timeout", self, "incrementAges")
	ageTimer.start() 
	
	#print(timer)

func setSpawnVariant(livingBeingVariant):
	currentSpawnVariant = livingBeingVariant
	currentGeneSet = livingBeingVariants.variants[currentSpawnVariant]

func enableSpawn():
	allowSpawn = true

func spawn(pos = null, geneSet1 = null, geneSet2 = null):
	livingBeings.append(livingBeingTemplate.instance())
	livingBeings[-1].isFemale = isFemale
	
	# if the spawn function is called by a creature for giving birth
	if geneSet1 != null:
		livingBeings[-1].setGeneSet(livingBeingVariants.mutateGeneSets(geneSet1, geneSet2))
	else:
		livingBeings[-1].setGeneSet(currentGeneSet)
	
	isFemale = not isFemale
	add_child(livingBeings[-1])
	
	# Add data to for the gene chart.
	for gene in livingBeings[-1].geneSet.keys():
		if gene in mainWorld.dataPoints:
			mainWorld.dataPoints[gene].append(livingBeings[-1].geneSet[gene])
	
	mainWorld.numberOfLivingBeings += 1
	# print("Spawning", livingBeings[-1])
	if pos == null:
		livingBeings[-1].position.x = rand_range(screenSize.x + 50, screenSize.x - 50)
		livingBeings[-1].position.y = rand_range(screenSize.y + 50, screenSize.y - 50)
	else:
		#print(pos, livingBeings[-1].position)
		livingBeings[-1].position = pos
	allowSpawn = false


func _process(_delta):
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		if allowSpawn:
			spawn(get_viewport().get_mouse_position())
	

func incrementAges():
	# Age clock for all of the livingbeings
	dayNightCycleStep()
	for livingBeing in livingBeings:
		livingBeing.lifeStep()

func killCreature(creature):
	livingBeings.remove(livingBeings.find(creature))
	mainWorld.numberOfLivingBeings += 1

func dayNightCycleStep():
	# If at the ends, then simply reverse the change direction of the colour.
	if currentModulate <= 0.3 or currentModulate >= 1:
		isDay = not isDay
		dayNightCycleModulateFactor *= -1
#	print(canvasModulate.color, " ", currentModulate)
	currentModulate += dayNightCycleModulateFactor
	
	canvasModulate.color = Color(currentModulate, currentModulate, currentModulate, 1)
	
