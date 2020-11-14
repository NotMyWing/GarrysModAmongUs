with FindMetaTable "Player"
	.GetAUPlayerTable = => GAMEMODE.GameData and GAMEMODE.GameData.Lookup_PlayerByEntity[@]
	.IsImposter       = => not not GAMEMODE.GameData.Imposters[@GetAUPlayerTable!]
	.IsPlaying        = => not not GAMEMODE.GameData.Lookup_PlayerByEntity[@]

return
