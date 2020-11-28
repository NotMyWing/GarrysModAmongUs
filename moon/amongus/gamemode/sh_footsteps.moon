-- Footstep sound replacement

GAMEMODE.Logger.Info("Replacing footstep sounds...")

basedir = "au/footsteps"

soundScriptReplacements = {
	Default: "dirt"
	SolidMetal: "metal"
	Dirt: "dirt"
	Mud: "snow"
	-- Source doesn't have a Carpet.StepLeft/Carpet.StepRight soundscript
	-- because apparently grass sounds are perfect for carpet too. Oh well,
	-- just hope nobody wants to use grass in their custom maps! Or, at
	-- least, hope they're okay with it sounding like office carpet.
	Grass: "carpet"
	MetalGrate: "metal"
	MetalVent: "metal"
	Tile: "tile"
	Glass: "glass"
	Computer: "plastic"
	Concrete: "tile"
	Gravel: "dirt"
	Sand: "snow"
	Wood: "wood"
}

--- Helper function to add a list of footstep sounds
-- @string name The name of the soundscript to override
-- @string sound The base name (minus %d.ogg) of the file to add
addFootstepSound = (name, snd) ->
	soundTable = {
		name: "#{name}.StepLeft"
		channel: CHAN_BODY
		volume: 1
		level: 75
		pitch: { 90, 110 }
		sound: {}
	}

	files = file.Find "sound/#{basedir}/#{snd}*.ogg", 'GAME'

	for i, file in ipairs(files)
		file = "#{basedir}/#{file}"
		util.PrecacheSound file
		soundTable.sound[i] = file

	sound.Add soundTable
	soundTable.name = "#{name}.StepRight"
	sound.Add soundTable

for name, file in pairs(soundScriptReplacements)
	addFootstepSound name, file
