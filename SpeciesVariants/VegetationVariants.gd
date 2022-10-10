extends Node

var default = {
	seedSpreadingRadius = 2,
	foodValueFactor = 10,
	maxAge = 200,
	numerOfSeeds = 2
}

var bigTree = {
	seedSpreadingRadius = 2,
	foodValueFactor = 10,
	maxAge = 69,
	numberOfSeeds = 2
}

var bush = {
	seedSpreadingRadius = 4,
	foodValueFactor = 5,
	maxAge = 20,
	numberOfSeeds = 3
}

var variants = {bigTree = self.bigTree, bush = self.bush}
var mutationRange = 1

