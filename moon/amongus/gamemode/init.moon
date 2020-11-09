export GAMEMODE = GAMEMODE or GM

-- Obligatory includes
include "shared.lua"
include "sh_gamedata.lua"
include "sh_lang.lua"

include "sv_net.lua"
include "sv_spectate.lua"
include "sv_resources.lua"
include "sv_player.lua"
include "sv_meeting.lua"
include "sv_game.lua"

include "sh_hooks.lua"
include "sh_tasks.lua"
include "sh_sabotages.lua"
include "sh_convarsnapshots.lua"
include "sh_manifest.lua"

-- Obligatory client stuff
AddCSLuaFile "sh_lang.lua"
AddCSLuaFile "sh_gamedata.lua"
AddCSLuaFile "sh_tasks.lua"
AddCSLuaFile "sh_sabotages.lua"
AddCSLuaFile "sh_hooks.lua"
AddCSLuaFile "vgui/vgui_splash.lua"
AddCSLuaFile "vgui/vgui_hud.lua"
AddCSLuaFile "vgui/vgui_meeting.lua"
AddCSLuaFile "vgui/vgui_eject.lua"
AddCSLuaFile "vgui/vgui_blink.lua"
AddCSLuaFile "vgui/vgui_vent.lua"
AddCSLuaFile "vgui/vgui_task_base.lua"
AddCSLuaFile "vgui/vgui_gui_base.lua"
AddCSLuaFile "vgui/vgui_map_base.lua"
AddCSLuaFile "vgui/vgui_sabotage_base.lua"
AddCSLuaFile "vgui/vgui_task_placeholder.lua"
AddCSLuaFile "vgui/vgui_kill.lua"
AddCSLuaFile "vgui/vgui_map.lua"
AddCSLuaFile "vgui/kills/remover.lua"
AddCSLuaFile "cl_hud.lua"
AddCSLuaFile "cl_net.lua"
AddCSLuaFile "cl_render.lua"
AddCSLuaFile "sh_convarsnapshots.lua"
AddCSLuaFile "sh_manifest.lua"

concommand.Add "au_debug_restart", ->
	GAMEMODE\Game_Restart!

hook.Add "Initialize", "NMW AU Initialize", ->
	MsgN!
	GAMEMODE.Logger.Info "Thanks for installing Among Us for Garry's Mod!"
	GAMEMODE.Logger.Info "Brought to you by NotMyWing and contributors"
	GAMEMODE.Logger.Info "Visit https://github.com/NotMyWing/GarrysModAmongUs for more info"
	MsgN!
	GAMEMODE\Game_Restart!
	GAMEMODE\SetOnAutoPilot true

	-- screw implicit returns man
	return
