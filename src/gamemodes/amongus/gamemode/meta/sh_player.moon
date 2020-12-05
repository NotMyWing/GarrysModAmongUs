with FindMetaTable "Player"
	.GetAUPlayerTable = => GAMEMODE.GameData and GAMEMODE.GameData.Lookup_PlayerByEntity[@]
	.IsImposter       = => not not GAMEMODE.GameData.Imposters[@GetAUPlayerTable!]
	.IsPlaying        = => not not GAMEMODE.GameData.Lookup_PlayerByEntity[@]
	.IsDead           = => not not GAMEMODE.GameData.DeadPlayers[@GetAUPlayerTable!]
	.IsInVent         = =>
		if CLIENT and @ == LocalPlayer!
			GAMEMODE.GameData.Vented
		else
			GAMEMODE.GameData.Vented[@GetAUPlayerTable!]

	.GetCurrentVGUI = =>
		if CLIENT and @ == LocalPlayer!
			GAMEMODE.Hud.CurrentVGUI
		else
			GAMEMODE.GameData.CurrentVGUI[@GetAUPlayerTable!]

	.GetTaskList = =>
		if CLIENT and @ == LocalPlayer!
			GAMEMODE.GameData.MyTasks
		elseif SERVER
			GAMEMODE.GameData.Tasks[@GetAUPlayerTable!]

return
