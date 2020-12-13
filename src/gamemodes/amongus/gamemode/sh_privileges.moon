include "lib/sh_cami.lua"
AddCSLuaFile "lib/sh_cami.lua"

GM.PRIV_START_ROUND = "GMAU_StartRound"
GM.PRIV_RESTART_ROUND = "GMAU_RestartRound"
GM.PRIV_CHANGE_SETTINGS = "GMAU_ChangeSettings"

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
