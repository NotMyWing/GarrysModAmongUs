AddCSLuaFile!

ENT.Type = "point"
ENT.Base = "base_point"

ENT.KeyValue = (key, value) =>
	if key == "angles"
		@SetAngles Angle value