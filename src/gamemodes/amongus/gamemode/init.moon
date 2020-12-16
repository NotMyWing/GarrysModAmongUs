export GAMEMODE = GAMEMODE or GM

-- Obligatory includes
include "shared.lua"
include "sh_gamedata.lua"
include "sh_lang.lua"
include "meta/sh_player.lua"

-- Only include resources manually if the workshop ID is unset.
if GAMEMODE.WorkshopID
	resource.AddWorkshop tostring GAMEMODE.WorkshopID
	GAMEMODE.Logger.Info "Adding addon ##{GAMEMODE.WorkshopID} as a workshop dependency"
else
	include "sv_resources.lua"
	GAMEMODE.Logger.Info "Adding the resources manually since the workshop ID is not set"

include "sv_net.lua"
include "sv_spectate.lua"
include "sv_player.lua"
include "sv_meeting.lua"
include "sv_game.lua"

include "sh_hooks.lua"
include "sh_tasks.lua"
include "sh_sabotages.lua"
include "sh_convarsnapshots.lua"
include "sh_manifest.lua"
include "sh_footsteps.lua"
include "sh_privileges.lua"

-- Obligatory client stuff
AddCSLuaFile "sh_lang.lua"
AddCSLuaFile "sh_gamedata.lua"
AddCSLuaFile "sh_tasks.lua"
AddCSLuaFile "sh_sabotages.lua"
AddCSLuaFile "sh_hooks.lua"
AddCSLuaFile "meta/sh_player.lua"
AddCSLuaFile "vgui/vgui_splash.lua"
AddCSLuaFile "vgui/vgui_hud.lua"
AddCSLuaFile "vgui/vgui_meeting.lua"
AddCSLuaFile "vgui/vgui_doutlinedlabel.lua"
AddCSLuaFile "vgui/vgui_eject.lua"
AddCSLuaFile "vgui/vgui_blink.lua"
AddCSLuaFile "vgui/vgui_vent.lua"
AddCSLuaFile "vgui/vgui_ui_bases.lua"
AddCSLuaFile "vgui/vgui_map_base.lua"
AddCSLuaFile "vgui/vgui_crewmate.lua"
AddCSLuaFile "vgui/vgui_task_placeholder.lua"
AddCSLuaFile "vgui/vgui_kill.lua"
AddCSLuaFile "vgui/vgui_map.lua"
AddCSLuaFile "vgui/vgui_showhelp.lua"
AddCSLuaFile "vgui/kills/remover.lua"
AddCSLuaFile "cl_hud.lua"
AddCSLuaFile "cl_net.lua"
AddCSLuaFile "cl_render.lua"
AddCSLuaFile "sh_convarsnapshots.lua"
AddCSLuaFile "sh_manifest.lua"
AddCSLuaFile "sh_footsteps.lua"
AddCSLuaFile "sh_privileges.lua"

concommand.Add "au_debug_restart", (ply) ->
	if CAMI.PlayerHasAccess ply, GAMEMODE.PRIV_RESTART_ROUND
		GAMEMODE\Game_Restart!

GM.Initialize = =>
	MsgN!
	GAMEMODE.Logger.Info "Thanks for installing Among Us for Garry's Mod!"
	GAMEMODE.Logger.Info "Brought to you by NotMyWing and contributors"
	GAMEMODE.Logger.Info "Visit https://github.com/NotMyWing/GarrysModAmongUs for more info"
	MsgN!
	GAMEMODE\Game_Restart!
	GAMEMODE\SetOnAutoPilot true

	-- screw implicit returns man
	return

cvars.AddChangeCallback GAMEMODE.ConVars.PlayerSpeedMod\GetName!, ((_, _, new) ->
	return if GAMEMODE\IsGameInProgress! or GAMEMODE\IsGameCommencing!

	new = tonumber new
	return if not new

	for ply in *player.GetAll!
		with movementSpeed = 190 * new
			ply\SetSlowWalkSpeed movementSpeed
			ply\SetWalkSpeed movementSpeed
			ply\SetRunSpeed  movementSpeed
			ply\SetMaxSpeed  movementSpeed

), "speedmod"
