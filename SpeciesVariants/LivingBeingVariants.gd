extends Node

# The names of the dfferent creatures categorised.
var preyVariantsList = []
var predatorVariantsList = []
var scavengerVariantsList = []

var default = {
	maxHealth = 10,
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
	maxAge = 100,
	animationNode = null # This is the complete animation Sprite node saved into a separate animations folder. 
}

var chicken = {
	geneType = "prey",
	maxHealth = 20,
	speed = 50,
	attractiveness = 1,
	visionSphereRadius = 80,
	memory = 5,
	maxAcceleration = 15,
	altruismFactor = 1,
	intimidationFactor = 2,
	gestationPeriod = 6,
	numberOfChildren = 4,
	anger = 0,
	attackStrength = 5,
	maxAge = 60,
	animationNode = null
}

# All the living being variants linked to their genesets
var variants = {chicken = self.chicken}
var mutationRange = 1

func mutateGeneSets(geneSet1, geneSet2):
	var newGeneSet = geneSet1
	for gene in geneSet1:
		if gene in geneSet2:
			if gene is int:
				newGeneSet[gene] = randi() % (geneSet1[gene] + (randi() % mutationRange + 1)) + (geneSet2[gene]  + (randi() % mutationRange + 1))
			else:
				newGeneSet[gene] = geneSet1[gene]
	return newGeneSet
