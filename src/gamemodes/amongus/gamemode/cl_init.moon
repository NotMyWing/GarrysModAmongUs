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
include "sh_footsteps.lua"
include "sh_privileges.lua"

cv = GM.ConVars

GM.ConVarsDisplay = {
	{
		Name: "General"
		ConVars: {
			{ "Int"    , "ImposterCount"   }
			{ "Time"   , "KillCooldown"    }
			{ "Time"   , "TimeLimit"       }
			{ "Mod"    , "KillDistanceMod" }
			{ "Bool"   , "AllTalk"         }
			{ "Select" , "TaskbarUpdates"  }
			{ "Mod"    , "PlayerSpeedMod"  }
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
			{ "Bool" , "VoteAnonymous"     }
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

flags      = bit.bor FCVAR_ARCHIVE
flagsUInfo = bit.bor FCVAR_ARCHIVE, FCVAR_USERINFO

GM.ClientSideConVars = {
	PreferredColor:  CreateConVar "au_preferred_color"     , 0  , flagsUInfo, "", 0, 128
	DrawVersion:     CreateConVar "au_debug_drawversion"   , 0  , flags     , "", 0, 1
	MaxChatMessages: CreateConVar "au_meeting_max_messages", 100, flags     , "", 0, 200
	SpectatorMode:   CreateConVar "au_spectator_mode"      , 0  , flagsUInfo, "", 0, 1
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

local nextTickCheck
hook.Add "Tick", "NMW AU Highlight", ->
	-- Operate at ~20 op/s. We don't need this to be any faster
	-- since TracePlayer can potentially be terribly inefficient.
	-- Realistically this shouldn't ever be a problem.
	-- Ha-ha.
	-- Unless...?
	return unless SysTime! >= (nextTickCheck or 0)

	-- Don't trace while the meeting is in progress.
	if GAMEMODE\IsMeetingInProgress!
		GAMEMODE.UseHighlight = nil
		GAMEMODE.ReportHighlight = nil
		GAMEMODE.KillHighlight = nil

		nextTickCheck = SysTime! + 1
		return

	localPlayer = LocalPlayer!
	playerTable = IsValid(localPlayer) and localPlayer\GetAUPlayerTable!

	-- Wait, it's all invalid?
	if not playerTable
		GAMEMODE.UseHighlight = nil
		GAMEMODE.ReportHighlight = nil
		GAMEMODE.KillHighlight = nil

		nextTickCheck = SysTime! + 1
		-- Always has been.
		return

	nextTickCheck = SysTime! + (1/20)

	usable, reportable = GAMEMODE\TracePlayer playerTable

	oldHighlight = GAMEMODE.UseHighlight
	GAMEMODE.UseHighlight = GAMEMODE\ShouldHighlightEntity(usable) and usable
	GAMEMODE.ReportHighlight = reportable

	-- Determine the closest player if imposter.
	if playerTable and playerTable.entity\IsImposter! and not playerTable.entity\IsDead!
		local closest, min
		for target in *player.GetAll!
			targetTable = target\GetAUPlayerTable!

			-- Bail if no table.
			continue if not targetTable or not targetTable.entity

			-- Bail if imposter.
			continue if target\IsImposter!

			-- Bail if dead or dormant.
			-- Both are basically the same thing, but it's better to be on the safe side.
			continue if target\IsDormant! or target\IsDead!

			currentDist = target\GetPos!\DistToSqr localPlayer\EyePos! + localPlayer\GetAimVector! * 32

			if not closest or currentDist < min
				closest = target
				min = currentDist

		if closest
			-- Do the expensive math to see if the closest target is actually within the kill radius.
			-- Please note that spoofing this check will not actually grant you the ability
			-- to kill anyone on the map regardless of the distance.
			-- This is purely visual stuff.
			radius = GAMEMODE.BaseUseRadius * GAMEMODE.ConVarSnapshots.KillDistanceMod\GetFloat!
			closest = nil if radius * radius <
				(closest\NearestPoint localPlayer\GetPos!)\DistToSqr(
					localPlayer\NearestPoint closest\GetPos!)

		GAMEMODE.KillHighlight = closest
	else
		-- Should probably not do that.
		GAMEMODE.KillHighlight = nil

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
hook.Add "EntityEmitSound", "TimeWarpSounds", (t) -> false if t.Entity\IsRagdoll!

hook.Add "CreateClientsideRagdoll", "test", (owner, rag) ->
	rag\GetPhysicsObject!\SetMaterial "gmod_silent"

GM.CreateVentAnim = (ply, pos, ang, appearing) =>
	if not IsValid ply
		@Logger.Error "CreateVentAnim received an invalid player! This should never happen!"
		return

	with ventAnim = ents.CreateClientside "vent_jump"
		playerColor = ply\GetPlayerColor!
		.GetPlayerColor = -> playerColor
		.Appearing = appearing

		angles = with ang
			.p = 0
			.r = 0

		\SetAngles angles

		\SetPos pos
		\SetModel ply\GetModel!

		\Spawn!
		\Activate!

hook.Add "InitPostEntity", "NWM AU RequestUpdate", ->
	net.Start "NMW AU Flow"
	net.WriteUInt GAMEMODE.FlowTypes.RequestUpdate, GAMEMODE.FlowSize
	net.SendToServer!

	return

hook.Add "CreateMove", "NMW AU KillScreenMove", (cmd) ->
	if IsValid(GAMEMODE.Hud) and IsValid(GAMEMODE.Hud.Kill)
		cmd\ClearButtons!
		cmd\ClearMovement!
		cmd\SetMouseX 0
		cmd\SetMouseY 0
		return true

hook.Add "OnPlayerChat", "NMW AU DeadSay", (ply, text) ->
	return unless ply\IsValid!

	prefixColor, prefixText = if ply.IsDead and ply\IsDead!
		Color(255, 0, 0), "(GHOST CHAT) "
	elseif not ply\GetAUPlayerTable! and IsValid(ply) and ply\GetObserverMode! > 0
		Color(64, 220, 64), "(SPECTATOR) "

	chat.AddText prefixColor, prefixText, ply\GetPlayerColor!\ToColor! or ply\GetColor!, ply\Nick!,
		Color(255, 255, 255), ": ", ply\IsDead! and Color(220, 220, 220), text

	return true

hook.Add "OnSpawnMenuOpen", "NMW AU RequestKill", ->
	with GAMEMODE
		playerTable = .GameData.Lookup_PlayerByEntity[LocalPlayer!]

		if .GameData.Imposters[playerTable] and IsValid(GAMEMODE.KillHighlight) and GAMEMODE.KillHighlight\IsPlayer!
			\Net_KillRequest .KillHighlight

	return

hook.Add "OnEntityCreated", "NMW AU PaintRagdolls", (ent) ->
	if IsValid(ent) and ent\IsRagdoll!
		playerTable = GAMEMODE\GetPlayerTableFromCorpse ent

		if playerTable
			playerColor = playerTable.color\ToVector!
			ent.GetPlayerColor = -> playerColor

hook.Add "NotifyShouldTransmit", "NMW AU TransmitWorkaround", (ent, shouldTransmit) ->
	pac.ToggleIgnoreEntity ent, not shouldTransmit, "GMAU" if pac and ent\IsPlayer!

class LimitedLinkedList
	new: (@__max = 1, @__count = 0) =>
	getFirst: => @__first
	getLast: => @__last
	getCount: => math.min @__max, @__count

	push: (value) =>
		@__count += 1 if @__count <= @__max

		node = { :value }

		-- If the first element already exists...
		if @__first
			-- link the new node to it and vice versa.
			node.next = @__first
			@__first.prev = node

		-- otherwise make the new node the last element.
		else
			@__last = node

		@__first = node

		-- If we've reached the max amount of elements,
		-- unlink the last one and tell the GC to get rid of it.
		if @__count > @__max
			@__last = @__last.prev
			@__last.next = nil

-- Not doing this kills Garry's Mod for god unknown reason.
GM.Util.LimitedLinkedList = (...) -> LimitedLinkedList ...
