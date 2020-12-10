--- Player HUD module.
-- Interfaces the HUD things. Responsible for everything Derma-related.
-- @module cl_hud

include "vgui/vgui_ui_bases.lua"
include "vgui/vgui_map_base.lua"
include "vgui/vgui_task_placeholder.lua"
include "vgui/vgui_crewmate.lua"
include "vgui/vgui_doutlinedlabel.lua"

VGUI_HUD = include "vgui/vgui_hud.lua"
VGUI_MEETING = include "vgui/vgui_meeting.lua"
VGUI_EJECT = include "vgui/vgui_eject.lua"
VGUI_SPLASH = include "vgui/vgui_splash.lua"
VGUI_BLINK = include "vgui/vgui_blink.lua"
VGUI_VENT = include "vgui/vgui_vent.lua"
VGUI_KILL = include "vgui/vgui_kill.lua"
VGUI_MAP = include "vgui/vgui_map.lua"
VGUI_SHOWHELP = include "vgui/vgui_showhelp.lua"

surface.CreateFont "NMW AU Button Tooltip", {
	font: "Roboto"
	size: ScreenScale 22
	weight: 550
}

surface.CreateFont "NMW AU Version", {
	font: "Roboto"
	size: ScreenScale 10
	weight: 550
}

--- Makes the player's screen fade in and out.
-- In-built screenfades are impractical to use.
-- @param duration Duration. One second by default.
GM.HUD_Blink = (duration = 1, delay, pre) =>
	vgui.CreateFromTable(VGUI_BLINK)\Blink duration, delay, pre

--- Displays a small vent UI for the vented player.
-- @param vents A table of vents.
GM.HUD_ShowVents = (vents) =>
	if IsValid @Hud
		if IsValid @Hud.Vents
			@Hud.Vents\Remove!

		@Hud.Vents = with @Hud\Add VGUI_VENT
			\ShowVents vents

--- Resets and re-creates the HUD.
-- You should NOT call this, this WILL break everything horribly.
-- This is used by the game mode for resetting the HUD between the rounds.
GM.HUD_Reset = =>
	if IsValid @__splash
		@__splash\Remove!

	if IsValid @Hud
		@Hud\Remove!

	@Hud = vgui.CreateFromTable VGUI_HUD
	@Hud\SetPaintedManually true

	if @MapManifest
		@HUD_InitializeMap!

--- Updates the task bar value.
-- @param value Value. [0..1]
GM.HUD_UpdateTaskAmount = (value) =>
	if IsValid @Hud
		@Hud\SetTaskbarValue value

--- Opens the meeting screen.
-- Plays the emergency meeting/body report animation.
-- @param caller The vote caller.
-- @param bodyColor Optional body color.
GM.HUD_DisplayMeeting = (caller, bodyColor) =>
	if IsValid @Hud
		if IsValid @Hud.Meeting
			@Hud.Meeting\Remove!

		@HUD_CloseMap!

		@Hud.Meeting = with @Hud\Add VGUI_MEETING
			\StartEmergency caller, bodyColor

--- Ejects the person.
-- damn that's a lot of inputs
-- @see shared.EjectReason
-- @param reason Eject reason.
-- @param playerTable Ejected player. PlayerTable.
-- @param confirm Are confirms enabled?
-- @param imposter If confirms are enabled, was this person an imposter?
-- @param remaining If confirms are enabled, how many imposters left?
-- @param total If confirms are enabled, how many imposters there are total?
GM.HUD_DisplayEject = (reason, ply, confirm, imposter, remaining, total) =>
	if "Player" == type ply
		ply = ply\GetAUPlayerTable!

	if IsValid @Hud
		if IsValid @Hud.Eject
			@Hud.Meeting\Remove!

		@HUD_CloseMap!

		@Hud.Eject = with @Hud\Add VGUI_EJECT
			\Eject reason, ply, confirm, imposter, remaining, total

--- Displays the game over screen.
-- @see shared.GameOverReason
-- @param reason Game over reason.
GM.HUD_DisplayGameOver = (reason) =>
	if IsValid @Hud
		@HUD_CloseMap!

		if IsValid @__splash
			@__splash\Remove!

		@__splash = with vgui.CreateFromTable VGUI_SPLASH
			\DisplayGameOver reason

--- Displays the shush screen.
GM.HUD_DisplayShush = =>
	if IsValid @Hud
		@HUD_CloseMap!

		if IsValid @__splash
			@__splash\Remove!

		@__splash = with vgui.CreateFromTable VGUI_SPLASH
			\DisplayShush!

--- Displays the death animation.
-- @param killer The killer.
-- @param victim The killed.
GM.HUD_PlayKill = (killer, victim) =>
	if "Player" == type killer
		killer = killer\GetAUPlayerTable!
	return unless killer

	if "Player" == type victim
		victim = victim\GetAUPlayerTable!
	return unless victim

	if IsValid @Hud
		if IsValid @Hud.Kill
			@Hud.Kill\Remove!

		@HUD_CloseMap!

		@Hud.Kill = with @Hud\Add VGUI_KILL
			\Kill killer, victim

--- Opens the map. Simple as that.
-- Doesn't open anything if something else is on the screen.
-- @return Has the map been opened?
GM.HUD_OpenMap = =>
	if GAMEMODE\IsGameInProgress! and IsValid(GAMEMODE.Hud) and IsValid(GAMEMODE.Hud.Map)
		GAMEMODE.Hud.Map\Popup!

		return true

--- Shows the F1 menu.
GM.HUD_ShowHelp = =>
	if not IsValid @ShowHelpMenu
		@ShowHelpMenu = vgui.CreateFromTable VGUI_SHOWHELP

	with @ShowHelpMenu
		\ParentToHUD!
		\Show!
		\MakePopup!

--- Closes the map. Simple as that.
GM.HUD_CloseMap = =>
	if IsValid(GAMEMODE.Hud) and IsValid(GAMEMODE.Hud.Map)
		return GAMEMODE.Hud.Map\Close!

MAT_TASK = Material "au/gui/map/task.png", "smooth"

--- Starts or stops tracking a task button on the map.
-- @param entity Task button to track.
-- @param track Optional. Pass `false` to stop tracking.
GM.HUD_TrackTaskOnMap = (entity, track = true) =>
	if IsValid(@Hud) and IsValid(@Hud.Map)
		with @Hud.Map
			if track
				size = 0.06 * math.min ScrW!, ScrH!

				\Track entity, with vgui.Create "Panel"
					\SetSize size, size
					.Paint = (_, w, h) ->
						return if GAMEMODE\GetCommunicationsDisabled! and
							not LocalPlayer!\IsImposter!

						surface.DisableClipping true
						surface.SetDrawColor 255, 230, 0
						surface.SetMaterial MAT_TASK

						render.PushFilterMag TEXFILTER.ANISOTROPIC
						render.PushFilterMin TEXFILTER.ANISOTROPIC
						surface.DrawTexturedRect 0, 0, w, h
						render.PopFilterMag!
						render.PopFilterMin!

						surface.DisableClipping false
			else
				\UnTrack entity

GM.HUD_AddTaskEntry = => @Hud\AddTaskEntry!

GM.HUD_Countdown = (time) =>
	if time > CurTime! and IsValid @__splash
		@__splash\Remove!

	if IsValid @Hud
		@Hud\Countdown time

surface.CreateFont "NMW AU Task Complete", {
	font: "Roboto"
	size: ScrH! * 0.06
	weight: 550
}

--- Creates a "Task Complete!" popup.
-- Animates it going from the bottom of the screen all the way to the top.
GM.HUD_CreateTaskCompletePopup = =>
	with @Hud\Add "DOutlinedLabel"
		\SetSize ScrW!, ScrH! * 0.08
		\SetZPos 32000

		\SetContentAlignment 5
		\SetText tostring @Lang.GetEntry "hud.taskComplete"
		\SetFont "NMW AU Task Complete"
		\SetColor Color 255, 255, 255

		-- This is mandatory.
		-- Otherwise the panel will get buried behind everything.
		\MakePopup!
		\SetMouseInputEnabled false
		\SetKeyboardInputEnabled false

		-- Animayshuns baby.
		\SetPos 0, ScrH!
		\MoveTo 0, ScrH! / 2 - \GetTall! / 2, 0.25, nil, nil, ->
			\MoveTo 0, -\GetTall!, 0.25, 0.75, nil, ->
				\Remove!

GM.HUD_CloseVGUI = =>
	if IsValid @Hud.CurrentVGUI
		if @Hud.CurrentVGUI.Close
			@Hud.CurrentVGUI\Close true
		else
			@Hud.CurrentVGUI\Remove!

		@Net_SendCloseVGUI!

GM.HUD_OpenVGUI = (panel) =>
	if IsValid panel
		@HUD_CloseVGUI!

		panel\SetParent @Hud
		@Hud.CurrentVGUI = panel

GM.HUD_HideTaskList = (state) =>
	if IsValid @Hud
		@Hud\HideTaskList state

GM.HUD_ToggleTaskList = =>
	if IsValid @Hud
		@Hud\ToggleTaskList!

GM.HUD_InitializeMap = =>
	@Hud.Map = with @Hud\Add VGUI_MAP
		\SetupFromManifest @MapManifest
		\SetColor Color 32, 32, 220
		\SetPos 0, ScrH!

		localPlayerTable = GAMEMODE.GameData.Lookup_PlayerByEntity[LocalPlayer!]
		if localPlayerTable
			size = 0.04 * math.min ScrW!, ScrH!
			player = with \Add "AmongUsCrewmate"
				\SetSize size, size
				\SetColor localPlayerTable.color

			\Track LocalPlayer!, player

GM.HUD_InitializeImposterMap = =>
	if IsValid @Hud.Map
		@Hud.Map\SetColor Color 200, 20, 20
		@Hud.Map\EnableSabotageOverlay!

ASSETS = {
	btn: Material "au/gui/floatingbutton.png", "smooth"
}

HIGHLIGHT_MATRIX = Matrix!
COLOR_WHITE_VERSION = Color 255, 255, 255, 32
COLOR_WHITE = Color 255, 255, 255
COLOR_BLACK = Color 0, 0, 0, 160

hook.Add "HUDPaintBackground", "NMW AU Hud", ->
	if GAMEMODE.ClientSideConVars.DrawVersion\GetBool!
		draw.SimpleText "EARLY ALPHA BUILD. EXPECT BUGS.", "NMW AU Version",
			ScrW! * 0.99, ScrH! * 0.01, COLOR_WHITE_VERSION,
			TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP

		if GAMEMODE.Version
			draw.SimpleText "VERSION: #{string.upper GAMEMODE.Version}.", "NMW AU Version",
				ScrW! * 0.99, ScrH! * 0.01 + ScreenScale(12), COLOR_WHITE_VERSION,
				TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP

	if GAMEMODE\IsGameInProgress!
		if IsValid GAMEMODE.UseHighlight
			color = GAMEMODE\GetHighlightColor GAMEMODE.UseHighlight
			if color
				cam.Start3D!
				with render
					.ClearStencil!

					.SetStencilEnable true
					.SetStencilTestMask 0xFF
					.SetStencilWriteMask 0xFF
					.SetStencilReferenceValue 0x01

					.SetStencilCompareFunction STENCIL_NEVER
					.SetStencilFailOperation STENCIL_REPLACE
					.SetStencilZFailOperation STENCIL_REPLACE

					GAMEMODE.UseHighlight\DrawModel!

					.SetStencilCompareFunction STENCIL_LESSEQUAL
					.SetStencilFailOperation STENCIL_KEEP
					.SetStencilZFailOperation STENCIL_KEEP

				cam.End3D!

				entClass = GAMEMODE.UseHighlight\GetClass!

				surface.SetDrawColor color.r, color.g, color.b, 32 + 8 * math.sin SysTime! * 5
				surface.DrawRect 0, 0, ScrW!, ScrH!

				render.ClearStencil!
				render.SetStencilEnable false

		-- Iterate through the three possible entity types we can interact with.
		for highlight in *{
			{
				button: input.LookupBinding "use"
				entity: GAMEMODE.UseHighlight
			}
			{
				button: input.LookupBinding "menu"
				entity: GAMEMODE.KillHighlight
			}
			{
				button: input.LookupBinding "reload"
				entity: GAMEMODE.ReportHighlight
			}
		}
			if IsValid highlight.entity
				pos = highlight.entity\WorldSpaceCenter!\ToScreen!

				nearestPoint = highlight.entity\NearestPoint LocalPlayer!\EyePos!
				value = (1 - math.max 0, math.min 1, (1/GAMEMODE.BaseUseRadius) * nearestPoint\Distance LocalPlayer!\EyePos!)
				size = 0.125 * math.min ScrH!, ScrW!

				-- Since Garry's Mod doesn't allow scaling fonts on the go,
				-- we'll have to scale the ENTIRE rendering sequence.
				m = with HIGHLIGHT_MATRIX
					\Identity!
					\Translate Vector pos.x, pos.y, 0
					\Scale math.Clamp(value, 0.25, 1) * Vector 1, 1, 1
					\Translate -Vector pos.x, pos.y, 0

				surface.SetAlphaMultiplier value

				render.PushFilterMag TEXFILTER.ANISOTROPIC
				render.PushFilterMin TEXFILTER.ANISOTROPIC

				cam.PushModelMatrix HIGHLIGHT_MATRIX, true
				do
					-- The button sprite.
					surface.SetMaterial ASSETS.btn
					surface.SetDrawColor COLOR_WHITE

					surface.DrawTexturedRect pos.x - size/2, pos.y - size/2, size, size

					-- The tooltip.
					draw.SimpleTextOutlined string.upper(highlight.button or "?"), "NMW AU Button Tooltip",
						pos.x, pos.y - size * 0.15, COLOR_WHITE,
						TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 3, COLOR_BLACK

				cam.PopModelMatrix!

				render.PopFilterMag!
				render.PopFilterMin!

				surface.SetAlphaMultiplier 1

	if IsValid GAMEMODE.Hud
		GAMEMODE.Hud\PaintManual!

hook.Add "ScoreboardShow", "NMW AU Map", ->
	return if IsValid GAMEMODE.Hud.Meeting
	return if IsValid GAMEMODE.__splash
	return unless LocalPlayer!\GetAUPlayerTable!

	return true if IsValid GAMEMODE.Hud.Eject
	return true if IsValid GAMEMODE.Hud.CurrentVGUI

	return true if GAMEMODE\HUD_OpenMap!

hook.Add "ScoreboardHide", "NMW AU Map", ->
	GAMEMODE\HUD_CloseMap!

	return nil

concommand.Add "au_debug_eject_test", ->
	if IsValid GAMEMODE.Hud.Eject
		GAMEMODE.Hud.Eject\Remove!

	ply = table.Random GAMEMODE.GameData.PlayerTables
	GAMEMODE\HUD_DisplayEject GAMEMODE.EjectReason.Vote, ply, true, true, 2, 2

concommand.Add "au_debug_kill_test", ->
	killer = table.Random GAMEMODE.GameData.PlayerTables
	victim = table.Random GAMEMODE.GameData.PlayerTables
	GAMEMODE\HUD_PlayKill killer, victim
