extends Node2D

var maxValues = {
	"health":100,
	"thirst":100,
	"hunger":100,
	"reproductiveUrge":100
}

var individualValueTexts = {
	"health":null,
	"thirst":null,
	"hunger":null,
	"reproductiveUrge":null,
	"target":null,
	"targetedAction":null
}

var parent
var creaturesNode
# Called when the node enters the scene tree for the first time.
func _ready():
	parent = get_parent()
	creaturesNode = parent.get_parent()
	if not "livingBeingTemplate" in creaturesNode:
		print("Not under the suitable node.")
		queue_free()
	
	individualValueTexts["health"] = $"Texts/Health"
	individualValueTexts["hunger"] = $"Texts/Hunger"
	individualValueTexts["thirst"] = $"Texts/Thirst"
	individualValueTexts["reproductiveUrge"] = $"Texts/Reproductive Urge"
	individualValueTexts["target"] = $"Texts/Target"
	individualValueTexts["targetedAction"] = $"Texts/Targeted Action"

	# Max values need not be accessed again and again as they are constants.
	maxValues["health"] = parent.maxHealth
	maxValues["hunger"] = parent.maxHunger
	maxValues["thirst"] = parent.maxThirst
	maxValues["reproductiveUrge"] = parent.maxReproductiveUrge
	
	set_process(false)
	set_physics_process(false)
	
# Not using function overriding and defining constant functions because did not use static typing anywahere else.
func updateIntegerValue(valueName, newValue):
	individualValueTexts[valueName].text = "%f/%s" % [newValue, maxValues[valueName]]

func updateStringValue(valueName, newValue):
	individualValueTexts[valueName].text = "%s" % str(newValue)
		

func _process(_delta):
	updateIntegerValue("health", parent.health)
	updateIntegerValue("hunger", parent.hunger)
	updateIntegerValue("thirst", parent.thirst)
	updateIntegerValue("reproductiveUrge", parent.reproductiveUrge)

	updateStringValue("target", str(parent.target))
	updateStringValue("targetedAction", parent.targetedAction)

func _on_Living_Being_mouse_entered():
	if creaturesNode.displayingCreatureDetails:
		return
	parent.mainWorld.currentlyDetailDisplayingCreature = parent
	self.visible = true
	set_process(true)
	creaturesNode.displayingCreatureDetails = true
	
func _on_Area2D_mouse_exited():
	parent.mainWorld.currentlyDetailDisplayingCreature = null
	self.visible = false
	set_process(false)
	creaturesNode.displayingCreatureDetails = false


