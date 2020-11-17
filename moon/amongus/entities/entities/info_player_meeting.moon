AddCSLuaFile!

ENT.Type = "point"
ENT.Base = "base_point"

ENT.Initialize = =>
	if @__angles then @SetAngles @__angles

ENT.KeyValue = (key, value) =>
	if key == "angles"
		@__angles = value
