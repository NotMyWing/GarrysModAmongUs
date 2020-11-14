export GAMEMODE = GAMEMODE or GM

include "shared.lua"
include "sh_gamedata.lua"
include "sh_lang.lua"
include "meta/sh_player.lua"
include "cl_hud.lua"
include "cl_net.lua"
include "cl_render.lua"
include "sh_hooks.lua"
include "sh_tasks.lua"
include "sh_sabotages.lua"
include "sh_convarsnapshots.lua"
include "sh_manifest.lua"

cv = GM.ConVars

GM.ConVarsDisplay = {
	{
		Name: "General"
		ConVars: {
			{ "Int"  , "ImposterCount"   }
			{ "Time" , "KillCooldown"    }
			{ "Time" , "TimeLimit"       }
			{ "Mod"  , "KillDistanceMod" }
			{ "Bool" , "DeadChat"        }
		}
	}
	{
		Name: "Meeting"
		ConVars: {
			{ "Int"  , "MeetingsPerPlayer" }
			{ "Time" , "MeetingCooldown"   }
			{ "Time" , "VoteTime"          }
			{ "Time" , "VotePreTime"       }
			{ "Time" , "VotePostTime"      }
			{ "Bool" , "ConfirmEjects"     }
		}
	}
	{
		Name: "Tasks"
		ConVars: {
			{ "Int"  , "TasksShort"  }
			{ "Int"  , "TasksLong"   }
			{ "Int"  , "TasksCommon" }
			{ "Bool" , "TasksVisual" }
		}
	}
}

hook.Add "InitPostEntity", "NMW AU Flash", ->
	if not system.HasFocus!
		system.FlashWindow!

key_num = (key) ->
	if GAMEMODE.GameData.Vented
		GAMEMODE\Net_VentRequest key - 1

GAMEMODE.KeyBinds = {
	-- Z (gmod_undo).
	[input.GetKeyCode(input.LookupBinding("gmod_undo") or "")]: ->
		GAMEMODE\HUD_ToggleTaskList!

	[KEY_1]: key_num
	[KEY_2]: key_num
	[KEY_3]: key_num
	[KEY_4]: key_num
	[KEY_5]: key_num
	[KEY_6]: key_num
	[KEY_7]: key_num
	[KEY_8]: key_num
	[KEY_9]: key_num
}

keyMemo = {}

hook.Add "Tick", "NMW AU KeyBinds", ->
	for key, fn in pairs GAMEMODE.KeyBinds
		old = keyMemo[key]
		new = input.IsKeyDown key
		if new and not old
			fn key

		keyMemo[key] = new

	-- screw implicit returns man
	return

hook.Add "Tick", "NMW AU Highlight", ->
	oldHighlight = GAMEMODE.UseHighlight

	if IsValid(LocalPlayer!) and GAMEMODE\IsGameInProgress! and GAMEMODE.GameData.Lookup_PlayerByEntity[LocalPlayer!]
		killable, usable = GAMEMODE\TracePlayer LocalPlayer!
		GAMEMODE.KillHighlight = killable
		GAMEMODE.UseHighlight = usable
	else
		GAMEMODE.KillHighlight = nil
		GAMEMODE.UseHighlight = nil

	if GAMEMODE.Hud
		if GAMEMODE.UseHighlight ~= oldHighlight
			material = if IsValid GAMEMODE.UseHighlight
				hook.Call "GMAU UseButtonOverride", nil, GAMEMODE.UseHighlight

			if GAMEMODE.Hud.UseButtonOverride ~= material
				GAMEMODE.Hud.UseButtonOverride = material

		oldHighlight = GAMEMODE.UseHighlight

	-- screw implicit returns man
	return

GM.HUDDrawTargetID = ->
hook.Add "EntityEmitSound", "TimeWarpSounds", (t) ->
	if t.Entity\IsRagdoll!
		return false

hook.Add "CreateClientsideRagdoll", "test", (owner, rag) ->
	rag\GetPhysicsObject!\SetMaterial "gmod_silent"

GM.CreateVentAnim = (ply, pos, appearing) =>
	with ventAnim = ents.CreateClientside "vent_jump"
		\SetPos pos
		\SetModel ply\GetModel!
		\SetColor ply\GetColor!
		.Appearing = appearing
		\Spawn!
		\Activate!

hook.Add "InitPostEntity", "NWM AU RequestUpdate", ->
	net.Start "NMW AU Flow"
	net.WriteUInt GAMEMODE.FlowTypes.RequestUpdate, GAMEMODE.FlowSize
	net.SendToServer!

hook.Add "CreateMove", "NMW AU KillScreenMove", (cmd) ->
	if IsValid(GAMEMODE.Hud) and IsValid(GAMEMODE.Hud.Kill)
		cmd\ClearButtons!
		cmd\ClearMovement!
		cmd\SetMouseX 0
		cmd\SetMouseY 0
		return true

hook.Add "OnPlayerChat", "NMW AU DeadSay", (ply, text) ->
	if GAMEMODE.ConVarSnapshots.DeadChat\GetBool! or not GAMEMODE\IsGameInProgress!
		return

	playerTable = GAMEMODE.GameData.Lookup_PlayerByEntity[ply]


	chat.AddText (if GAMEMODE.GameData.DeadPlayers[playerTable]
		Color(255, 0, 0), "(GHOST CHAT) "
	), ply\GetColor!, ply\Nick!, Color(255, 255, 255), ": ", Color(220, 220, 220), text

	return true

hook.Add "OnSpawnMenuOpen", "NMW AU RequestKill", ->
	with GAMEMODE
		playerTable = .GameData.Lookup_PlayerByEntity[LocalPlayer!]

		if .GameData.Imposters[playerTable] and IsValid(GAMEMODE.KillHighlight) and GAMEMODE.KillHighlight\IsPlayer!
			\Net_KillRequest .KillHighlight

	return
