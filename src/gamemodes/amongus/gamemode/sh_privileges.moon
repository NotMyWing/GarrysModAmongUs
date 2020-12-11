include "lib/sh_cami.lua"
AddCSLuaFile "lib/sh_cami.lua"

GAMEMODE.PRIV_START_ROUND = "GMAU_StartRound"
GAMEMODE.PRIV_RESTART_ROUND = "GMAU_RestartRound"
GAMEMODE.PRIV_CHANGE_SETTINGS = "GMAU_ChangeSettings"

CAMI.RegisterPrivilege {
	Name: GM.PRIV_START_ROUND
	MinAccess: "admin"
}

CAMI.RegisterPrivilege {
	Name: GM.PRIV_RESTART_ROUND
	MinAccess: "admin"
}

CAMI.RegisterPrivilege {
	Name: GM.PRIV_CHANGE_SETTINGS
	MinAccess: "admin"
}
