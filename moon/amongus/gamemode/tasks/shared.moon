AddCSLuaFile!

tasks = {
	"inspectSample"
	"fixWiring"
	"fuelEngines"
	"emptyGarbage"
	"emptyChute"
	"chartCourse"
	"calibrateDistributor"
	"alignEngineOutput"
	"clearAsteroids"
	"cleanO2Filter"
	"divertPower"
	"stabilizeSteering"
	"primeShields"
	"submitScan"
	"startReactor"
	"unlockManifolds"
	"swipeCard"
	"uploadData"
}

for _, task in ipairs tasks
	if SERVER
		AddCSLuaFile "#{task}.lua"

	taskTable = include "#{task}.lua"
	taskTable.Name or= "#{task}"

	gm = GAMEMODE or GM
	gm\Task_Register taskTable