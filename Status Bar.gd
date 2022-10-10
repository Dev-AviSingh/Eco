extends Node2D

var shader
var health = 0.0
var maxHealth = 100.0
var healthPercentageGone = 0.0
var backTexture
var values = {
	"health" : 100.0,
	"hunger":0.0,
	"thirst": 0.0,
	"reproductiveUrge":0.0
}
var maxValues = {
	"health" : 100.0,
	"hunger" : 100.0,
	"thirst": 100.0,
	"reproductiveUrge": 100.0
}
var bars = {
	"health" : null,
	"hunger": null,
	"thirst": null,
	"reproductiveUrge":null
}

func _ready():
	backTexture = preload("res://BarSprite.tscn")
	shader = preload("res://BarSprite.shader")
	updateBars()

func changeValue(valueName, newValue):
	values[valueName] = newValue
	#print(values[valueName] / maxValues[valueName])
	bars[valueName].material.set_shader_param("healthPercentageGone", values[valueName] / maxValues[valueName])
	#print(valueName, newValue)

func setValue(valueName, newValue, maxValue, modulation):
	values[valueName] = newValue
	maxValues[valueName] = maxValue
	bars[valueName].material.set_shader_param("healthPercentageGone", values[valueName] / maxValues[valueName])
	bars[valueName].modulate = modulation
	
	updateBars()

func addNewBar(valueName, maxValue, initialValue):
	values[valueName] = initialValue
	maxValues[valueName] = maxValue

func updateBars():
	for child in get_children():
		child.queue_free()
	
	var index = 1
	for key in values:
		var newBar = backTexture.instance()
		newBar.position.y = index * -15 -30 # Using position and not global position because the bar position is relative to the parent's center.
		var newMaterial = ShaderMaterial.new()
		newMaterial.shader = shader
		newMaterial.set_shader_param("healthPercentageGone", values[key] / maxValues[key])
		newBar.set_material(newMaterial)
		bars[key] = newBar
		add_child(newBar)
		index += 1

func _process(delta):
	updateBars()
