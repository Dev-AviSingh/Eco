extends KinematicBody2D

# Free assets used:
# 1.Chicken - https://heamomo.itch.io/pet
# 2.Background - https://guttykreum.itch.io/field-of-green/download/eyJleHBpcmVzIjoxNjE0NTIwNDUyLCJpZCI6NDM5MjIzfQ%3d%3d%2e2%2b0ebfVUoIpOy6me0eN4tH7%2bD5g%3d
# 3.Top Down Earth TileSet - https://beeler.itch.io/top-down-earth-tileset

# Game Targets:
# Basic value assignment to the character including genes 
# Basic movement
# Random Movement
# Food chain hierarchy in characters 
# Basic environment generation with water, food, 

# Characters to add:
# 1. Creatures
# 2. Basic animals following the food chain and providing them with predefined life values.
# 3. Plants
# 4. Evironment objects: Water sources, hiding spots
# 5. Terrain generation
# 6. Script to spawn the creatures maually
# 7. Automatic generation of all the creatures, terrain, and environment.

var velocity = Vector2(0, 0)
var maxVelocity = 100
var acceleration = Vector2.ZERO
var maxAcceleration = 20
var autoPilot = true
var type = "Prey" # Several types like prey, predator, scavenger
var roaming = false
var mating = false

var geneSet = {
	geneType = "prey",
	maxHealth = 10,
	maxAge = 12,
	speed = 10,
	attractiveness = 1,
	visionSphereRadius = 100,
	memory = 5,
	maxAcceleration = 20,
	altruismFactor = 0,
	intimidationFactor = 10,
	gestationPeriod = 10,
	numberOfChildren = 2,
	anger = 0,
	attackStrength = 10,
	animationNode = null # This is the complete animation Sprite node saved into a separate animations folder. 
}


# Basic life values
var maxHealth = 10
var health = geneSet["maxHealth"]

var maxHunger = maxHealth * 2
var hunger = maxHunger / 2

var maxThirst = maxHealth * 5
var thirst = maxThirst / 2

var reproductiveUrge = 0
var maxReproductiveUrge = 100


var isFemale = false # Male or Female
var biologicalFamily = "Animal" # Can be a plant, animal or an attack helicopter, also it can be water.
var species = "Chicken" # Used to identify possible mates.
var defenceTactic = "Run" # This is the behaviour that a creature chooses while facing an enemy. Defence Tactics are Hide, Run, counterattack.
var eatables = ["Vegetation"]

var age = 0 # The age in seconds, as the age progresses over 75% of the creatures lifetime, the attack decreases.
var maturityAge = geneSet["maxAge"] / 24
var ageTimer

var maxRejectedMates = geneSet["memory"]

# Values that need constant calculation.
# All of these values will be straight up reference to the referred object, and the velocity will be determined as per their global global_position.
var closestFood = null # This will be determined when the hunger drops below 25%
var closestWater = null # Same as food
var closestMate = null # Same as food
var rejectedMates = [] # This is the list of the 10 creatures that rejected or were rejected to mate.
var possibleHidingSpots = [] # Any hiding spot encountered to be added to this list.
var waterSources = [] # Rememer any number of watersources.

var apparentVelocity = Vector2.ZERO
var genderModulation = null
var target = null # The decideTargetAndCalculateVelocity function decides the target and selects it from the closest food, water or mate
var targetedAction = "doNothing"
# 1. Use the hunger, thirst and reproductiveUrge to determine the action in each cycle.
# 2. If under attack then decide the defence tactic on the basis of health, attack and intimidation factor
# 3. When hungry, if any creature found below the creature in the food chain then hunt, otherwise search for the closest food.
# 4. When thirsty, directly go for the closest water source. 
# 5. When hunger, thirst and reproductiveUrge, all are above 75%, or no plants or water sources are visible, then go to a random direction, which changes to another random direction when you collide to a wall.
# Remember that each step, attack or defense has a cost of hunger and thirst which must be fulfilled

# Complex behaviours to implement:
# 1.Altruism, asically sharing food, and if possible add helping in defense.
# 2.Hiding, running, counterattacking in defense
# 3.Resting when all the life values are fulfilled significantly and the health is low.
# 4.When mating, choose and reject mates on the basis of the attractiveness factor.
# 5.Madness, which decides the tendency to randomly attack people, it defines a random chance to attack others with no regard for the intimidation factor. It has a max limit, starts with 0, and can get increased by the reproductive urge when that is full.
# 6.Day night cycles. If possible add sleeping features.
# One more idea, if the creature dies then spawn a dead body that can be eaten by scavengers.


# Game changing feature:
# 1. Add a player controlled character that has the same features: has thirst, hunger, reproductiveUrge, sleep cycle and the other liufe values.
# 2. The purpose of the player is to stay alive using the environment which he can manually create.
# 3. The player can be given building capabilities.
# 4. There can be a map

# Game target
#	There can be a main quest line which aims to repopulate the lands, and for that the player is given targets.
# The player can plant trees, spawn animals with experience, the experience is gained by sacrificing animals to something.


var creatureName = "Insignificant"
var sprites = []
var state = "Idle" # 3 states = Idle, Active, Preying, Active, Searching.
var screenSize
var statusBar
var displayDetails
var mainWorld
var livingCreaturesNode
#export (int) var wallProximityLimit = 10

var matingAction = "mate"

# Called when the node enters the scene tree for the first time.
func _ready():
	screenSize = get_viewport_rect().size
	livingCreaturesNode = get_parent()
	mainWorld = get_parent().get_parent() # self --> Living Creatures --> Main World
	displayDetails = $"Detail Display"
	
	# Change the colour modulation for testing if female for recognition
	# Later this colour modulation will be dependent on the attractiveness factor and gender.
	if isFemale:
		genderModulation = Color("#FFC0CB")
		matingAction = "doNothing"
	else:
		genderModulation = Color(1, 1, 1, 1)
		
	$AnimatedSprite.modulate = genderModulation
	$VisionSphere/VisionShereCollisionShape.shape.radius = geneSet["visionSphereRadius"]
	

func setGeneSet(newGeneSet):
	for value in newGeneSet.keys():
		geneSet[value] = newGeneSet[value]


func printLifeValues():
	print("Health = ", health)
	print("Thirst = ", thirst)
	print("Hunger = ", hunger)
	print("Reurge = ", reproductiveUrge)


func lifeStep():
	# Basically increase each one of the basic life values every time step depending on the speed.
	age += 1
	
	# Using 2 and 2.5 as the equation results in a value above 1.
	hunger = min(maxHunger, hunger + 2 * geneSet["speed"] / 100)
	thirst = min(maxThirst, thirst + 2.25 * geneSet["speed"] / 100)
	reproductiveUrge = min(maxReproductiveUrge, reproductiveUrge + 1)

	# Old people are weak at fighting.
	if age/geneSet["maxAge"] > 0.75:
		geneSet["attackStrength"] -= 5
	
	# If hunger and thirst reach their limits, just reduce health each life step.
	# For reproductive urge, madness will be a factor that will be increased of complex behaviours are added.
	if hunger >= maxHunger:
		health -= 0.2
		print(self, "Hurt by hunger.")
	if thirst >= maxThirst:
		print(self, "Hurt by thirst.")
		health -= 0.5
	
	# Updating all the status bars.
	# all of the values increase only within a timestep except for health.
	
	$"Detail Display".maxValues["thirst"] = maxThirst
	$"Detail Display".maxValues["hunger"] = maxHunger
	$"Detail Display".maxValues["health"] = maxHealth
	$"Detail Display".maxValues["reproductiveUrge"] = maxReproductiveUrge


func _physics_process(delta):
	# Creature Death.
	if health <= 0 or age >= geneSet["maxAge"]:
		print(health, age)
		die()

	# Check for bodies colliding with the creature's main collision box
	for collisionIndex in range(get_slide_count()):
		var collision = get_slide_collision(collisionIndex)
		#print(collision.collider.biologicalFamily, " ", target)

		# According to the target we check whether the colliding object was our target or not.
		if collision.collider == target:
			call(targetedAction)
		elif collision.collider is StaticBody2D and target == null:
			velocity = velocity.bounce(collision.normal)

	# Input movement block
	if not autoPilot:
		# Movement Input control
		if Input.is_action_pressed("ui_up"):
			velocity.y -= geneSet["speed"]
			$AnimatedSprite.flip_v = false
		elif Input.is_action_pressed("ui_down"):
			velocity.y = geneSet["speed"]
			$AnimatedSprite.flip_v = true
		else:
			velocity.y = 0
		
		if Input.is_action_pressed("ui_left"):
			velocity.x = -geneSet["speed"]
		elif Input.is_action_pressed("ui_right"):
			velocity.x = geneSet["speed"]
		else:
			velocity.x = 0

	# Limit the velocity
	velocity.x = clamp(velocity.x, -maxVelocity, maxVelocity)
	velocity.y = clamp(velocity.y, -maxVelocity, maxVelocity)
	
	
	if velocity.x < 0:
		$AnimatedSprite.play("left")
	elif velocity.y > 0:
		$AnimatedSprite.play("right")
	
	elif velocity.y < 0:
		$AnimatedSprite.play("up")
	elif velocity.y > 0:
		$AnimatedSprite.play("down")
	
	if velocity.x == 0 and velocity.y == 0:
		$AnimatedSprite.play("Idle")
	
	if autoPilot:
		getEnvironmentData()
		velocity = decideTargetAndCalculateVelocity(delta)
	# Move the creature when in manucal control.
	else:
		velocity  = velocity.normalized() * geneSet["speed"]
		
	$Line2D.rotation = velocity.angle()
	
	if mating:
		$AnimatedSprite.modulate = Color(0, 0.7, 0, 1)
	elif target == null:
		$AnimatedSprite.modulate = genderModulation
	elif targetedAction == "eat":
		$AnimatedSprite.modulate = Color(1, 0, 0, 1)
	elif targetedAction == "drink":
		$AnimatedSprite.modulate = Color(0, 0, 1, 1)
#	print(targetedAction, " ", target)
	apparentVelocity = move_and_slide(velocity)


func getEnvironmentData():
	# Get the nearest objects within the influence sphere
	# Add all the hiding spots and the watersources.
	for collidingBody in $VisionSphere.get_overlapping_bodies():
		if collidingBody == self:
			continue
		if "biologicalFamily" in collidingBody:
			if collidingBody.biologicalFamily == "Animal":
				# If the creature is of the opposite gender, then add it to the closestMate
				# True and false, basically one has to female one does not
				if not "isFemale" in collidingBody:
					print("Something went horribly wrong.")
					 
				# If the creature is of the same species, and is of the opposite gender, then it is the closest possible mate. If the mate is in the rejection list then ignore it.

				if collidingBody.isFemale == (not isFemale) and collidingBody.species == species and not collidingBody in rejectedMates:
					if closestMate == null:
						closestMate = collidingBody
					else:
						if (global_position - collidingBody.global_position).length() > (global_position - closestMate.global_position).length():
							closestMate = collidingBody
					if targetedAction == matingAction:
						call(matingAction)
						
			elif collidingBody.biologicalFamily == "Vegetation":
				# If the body is a plant and if hunger is the target. then approach it and then eat it.
				if closestFood == null:
					closestFood = collidingBody
				else:
					var closePositionFactor = 50 # To prevent useless assignment, we want the new item to be super close
					if (global_position - collidingBody.global_position).length() + closePositionFactor > (global_position - closestFood.global_position).length():
						# If this food source is the nearest, then follow this one instead
						closestFood = collidingBody
			elif collidingBody.biologicalFamily == "Water":
				# If the memory of the ocreature has not exceeded then add the new water source, when thristy, the creature checks for the closes water source.
				closestWater = collidingBody
				if len(waterSources) < geneSet["memory"]:
					waterSources.append(collidingBody)
				# There never should be more water sources recorded than the memory limit
				else:
					waterSources[-1] = collidingBody
			else:
				print("Unknown Body found", " ", collidingBody, " ", collidingBody.biologicalFamily)
		else:
			continue


func getSteer():
	# Using abrupt movement.
	if target == null:
		return velocity
	var desired = (target.global_position - global_position).normalized() * geneSet["speed"]
	return desired


func decideTargetAndCalculateVelocity(_delta):
	# If a target is already found then no need to find a new velocity, the target becomes null after eating or drinking.
	
	# If the creature is mating, do not disturb it.
	if mating:
		target = closestMate
		return getSteer()
	
	var newVelocity = velocity
	
	if target != null:
		if targetedAction == "eat":
			target = closestFood
		elif targetedAction == "drink":
			target = closestWater
		elif targetedAction == "mate":
			target = closestMate
		
		newVelocity = getSteer()
		
		# The following block is for obstable avoidance.
		# The 1.57078 is the 90 degree spot 
		var ang = global_position.angle_to_point(target.global_position)
		if is_on_wall() and ((ang > 1.4 and ang < 1.6) or (ang > 3.0 and ang < 3.2) or (ang > 4.6 and ang < 4.8) or (ang > 6.2 and ang < 0.1)):# The angle checks are for 90, 180, 270 and 360degrees. 
			# This is weird, use context based steering please.
			
			if apparentVelocity.x == 0:
				global_position.y += 22 * sign(global_position.x -target.global_position.x)
			elif apparentVelocity.y == 0:
				global_position.x += 22 * sign(global_position.y - target.global_position.y)
		
		return newVelocity
	# Calculate the target direction.
	# If there is no immediate target or there are no targets found then the creature roams randomly.
	# Targets to add:
	# 1. Attacking another creature if they are below in the food chain.
	# 2. Hiding targets if attacked.
	
	if reproductiveUrge > hunger and reproductiveUrge > thirst and not isFemale and age > geneSet["maxAge"] / 4 and reproductiveUrge > maxReproductiveUrge / 2: # Taking 21 because accoring to me the age of consent shuld be 21
		state = "Searching"
		target = closestMate
		targetedAction = "mate"
	
	elif hunger < maxHunger * 0.25 and thirst < maxThirst * 0.25:
		state = "Searching"
		target = null
		targetedAction = "doNothing"
	
	elif hunger > thirst:
		state = "Searching"
		target = closestFood
		targetedAction = "eat"
	
	elif thirst > hunger:
		state = "Searching"
		target = closestWater
		targetedAction = "drink"
	
	else:
		state = "Idle"
		target = null
		targetedAction = "doNothing"
		roaming = true
	
	#print(target, " ", targetedAction)
	#print(velocity)
	if target == null:
		if roaming:
			pass
		else:
			newVelocity = Vector2(geneSet["speed"], geneSet["speed"]).rotated(rand_range(0, 6.28)) # Choose a random radian to go towards.
			roaming = true
	else:
		# Find the vector suitable to go towards the target.
		newVelocity = getSteer()
		roaming = false
	
	return newVelocity


func createHighlight():
	# Create a highlight around the creature's sprite
	pass

func toggleAutopilot():
	if autoPilot:
		# Disable autopilot and return to automatic control
		autoPilot = false
		livingCreaturesNode.controllingCreature = false
		mainWorld.currentlyControlledCreature = null
		roaming = false
	elif not livingCreaturesNode.controllingCreature:
		# Enable autopilot only if there is no other creature under autopilot.
		autoPilot = true
		livingCreaturesNode.controllingCreature = true
		mainWorld.currentlyControlledCreature = self
	else:
		pass
	print(autoPilot)
func attack():
	# Attack with all the attack strength, if the health drops below 90%, run. 
	pass


func doNothing():
	pass


func hide():
	pass


func run(global_positionToRunAwayFrom):
	pass


func eat():
	velocity = Vector2.ZERO
	if target != null:
		if target.has_method("getEaten"):
			hunger -= target.getEaten()
			hunger = max(hunger, 0)
		else:
			print(target.biologicalFamily, " is not eatable.")
		target = null


func drink():
	velocity = Vector2.ZERO
	if target != null and target.has_method("getWater"):
		thirst -= target.getWater(thirst)# The water level never goes below zero
	target = null


func giveBirth(targetGeneSet):
	# Spawn x number of creatures where x is the maximumNumber of children, the gene values of the children will be mutated by a mutation factor. Reduce the reproductive urge such that, it will be more than 0 only after the resting period.
	mating = false
	target = null
	
	# Spawn children using the parent living creatures node's spaw3n function.
	for _x in range(geneSet["numberOfChildren"]):
		get_parent().spawn(position, geneSet, targetGeneSet)


func mate():
	# Nullify the reproductive urge, start a timer for the give birth function.
	# The main problem with the mate function is that it is two way, current hope is that the target creature will automatically call the mate function as well. If that does not happen, need to keep flags for that. 
	# Remember kids consent is important, and also because of natural selection.
	if target != null and target.getConsent(self):
		reproductiveUrge = 0
		target.reproductiveUrge = 0
		target.mating = true
		mating = true
		
		var birthTimer = Timer.new()
		birthTimer.wait_time = geneSet["gestationPeriod"]
	
		#print(name, " ", "reproduced with ", " ", target.name)
		
		# Invoke the giveBirth command after the gestation period, until then, the female shall stand still.
		target.add_child(birthTimer)
		birthTimer.connect("timeout", target, "giveBirth", [target.geneSet])
		mating = false
		target = null
		birthTimer.start()
	else:
		if len(rejectedMates) >= maxRejectedMates:
			rejectedMates.pop_front()
		rejectedMates.append(target)
		target = null


func getConsent(wooer): 
	# If the wooer creature is attractive enough and the current target is reproduction, then give consent. Otherwise, add it to the rejected targets.
	if wooer.geneSet["attractiveness"] >= geneSet["attractiveness"] and not wooer in rejectedMates:
		velocity = Vector2.ZERO
		target = wooer
		return true
	else:
		# Add the creature to the rejection list it is unattractive.
		if len(rejectedMates) >= maxRejectedMates:
			rejectedMates.pop_front()
		rejectedMates.append(wooer)
		return false


func turnIntoCorpse():
	# When the health gets 0 and the creature is an animal, the biological family gets turned into a corpse which can then be eaten.
	# The food value becomes half of the alive food value. 
	pass


func getEaten():
	# Get's called as a plant, corpse or when defeated in battle.
	# Just return the foodValue of the creature to the creature that is eating this creature.
	var foodValue = maxHunger - hunger
	die()
	return foodValue


func die():
	velocity.x = 0
	velocity.y = 0
	
	mainWorld.lastDiedCreature = self
	
	get_parent().killCreature(self)
	set_physics_process(false)
	
	# Make sure that the detail display is closed and the next display can be opened.
	displayDetails.visible = false
	get_parent().displayingCreatureDetails = false
	
	$AnimatedSprite.hide()
#	$"Status Bars".hide()
	
	$Particles2D.emitting = true
	
	var tim = Timer.new()
	tim.wait_time = 1
	tim.connect("timeout", self, "queue_free")
	add_child(tim)
	tim.start()


func _on_Living_Being_input_event(_viewport, event, _shape_idx):
	if Input.is_mouse_button_pressed(BUTTON_RIGHT):
		if Input.is_action_pressed("ui_accept"):
			toggleAutopilot()
		else:
			die()
	
