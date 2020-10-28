VGUI_HUD = include "vgui/vgui_hud.lua"
VGUI_MEETING = include "vgui/vgui_meeting.lua"
VGUI_EJECT = include "vgui/vgui_eject.lua"
VGUI_SPLASH = include "vgui/vgui_splash.lua"
VGUI_BLINK = include "vgui/vgui_blink.lua"
VGUI_VENT = include "vgui/vgui_vent.lua"
VGUI_KILL = include "vgui/vgui_kill.lua"
VGUI_MAP = include "vgui/vgui_map.lua"

include "vgui/vgui_task_base.lua"
include "vgui/vgui_task_placeholder.lua"

surface.CreateFont "NMW AU Button Tooltip", {
	font: "Arial"
	size: ScreenScale 22
	weight: 500
	outline: true
}

GM.Blink = (duration = 1, delay, pre) =>
	vgui.CreateFromTable(VGUI_BLINK)\Blink duration, delay, pre

GM.HUDShowVents = (vents) =>
	if IsValid @Hud
		if IsValid @Hud.Vents
			@Hud.Vents\Remove!

		@Hud.Vents = with vgui.CreateFromTable(VGUI_VENT)
			\ShowVents vents

GM.HUDReset = =>
	if IsValid(@Hud) and IsValid(@Hud.TaskScreen)
		@Hud.TaskScreen\Close!

	if IsValid @Hud
		@Hud\Remove!

	@Hud = vgui.CreateFromTable VGUI_HUD
	@Hud\SetPaintedManually true

	if @MapManifest
		@HUD_InitializeMap!

GM.HUD_UpdateTaskAmount = =>
	if IsValid @Hud
		@Hud\SetTaskbarValue GAMEMODE.GameData.CompletedTasks / GAMEMODE.GameData.TotalTasks

GM.HUD_HideTaskScreen = =>
	if IsValid(@Hud) and IsValid(@Hud.TaskScreen)
		@Hud.TaskScreen\Close!

GM.HUD_DisplayMeeting = (caller, bodyColor) =>
	if IsValid @Hud
		if IsValid @Hud.Meeting
			@Hud.Meeting\Remove!

		@HUD_CloseMap!

		@Hud.Meeting = with vgui.CreateFromTable VGUI_MEETING, @Hud
			\StartEmergency caller, bodyColor

GM.HUD_DisplayEject = (reason, ply, confirm, imposter, remaining, total) =>
	if IsValid @Hud
		if IsValid @Hud.Eject
			@Hud.Meeting\Remove!

		@HUD_CloseMap!

		@Hud.Eject = with vgui.CreateFromTable VGUI_EJECT, @Hud
			\Eject reason, ply, confirm, imposter, remaining, total

GM.HUD_DisplayGameOver = (reason) =>
	if IsValid @Hud
		@HUD_CloseMap!

		@Hud.Splash = with vgui.CreateFromTable VGUI_SPLASH, @Hud
			\DisplayGameOver reason

GM.HUD_DisplayShush = (reason) =>
	if IsValid @Hud
		@HUD_CloseMap!

		@Hud.Splash = with vgui.CreateFromTable VGUI_SPLASH, @Hud
			\DisplayShush!

GM.HUD_PlayKill = (killer, victim) =>
	if IsValid @Hud
		if IsValid @Hud.Kill
			@Hud.Kill\Remove!

		@HUD_CloseMap!

		@Hud.Kill = with vgui.CreateFromTable VGUI_KILL, @Hud
			\Kill killer, victim

GM.HUD_OpenMap = =>
	if IsValid @Hud.Meeting
		return

	if IsValid @Hud.TaskScreen
		return

	if IsValid @Hud.Eject
		return

	if IsValid @Hud.Splash
		return

	if GAMEMODE\IsGameInProgress! and IsValid(GAMEMODE.Hud) and IsValid(GAMEMODE.Hud.Map)
		GAMEMODE.Hud.Map\Popup!

		return true

GM.HUD_CloseMap = =>
	if IsValid(GAMEMODE.Hud) and IsValid(GAMEMODE.Hud.Map)
		GAMEMODE.Hud.Map\Close!

MAT_TASK = Material "au/gui/maps/task.png", "smooth"

GM.HUD_TrackTaskOnMap = (entity, track = true) =>
	if IsValid(@Hud) and IsValid(@Hud.Map)
		with @Hud.Map
			if track
				size = \GetInnerSize!

				\Track entity, with vgui.Create "DPanel"
					\SetSize size * 0.1, size * 0.1
					.Paint = (_, w, h) ->
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

surface.CreateFont "NMW AU Task Complete", {
	font: "Roboto"
	size: ScrH! * 0.06
	weight: 400
	outline: true
}

GM.HUD_CreateTaskCompletePopup = =>
	with @Hud\Add "DLabel"
		\SetSize ScrW!, ScrH! * 0.08
		\SetZPos 32000

		\SetContentAlignment 5
		\SetText tostring @Lang.GetEntryFunc "hud.taskComplete"
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

CREW_LAYERS = {
	Material "au/gui/meeting/crewmate1.png", "smooth"
	Material "au/gui/meeting/crewmate2.png", "smooth"
}

GM.HUD_InitializeMap = =>
	@Hud.Map = with @Hud\Add VGUI_MAP
		if @MapManifest and @MapManifest.Map and @MapManifest.Map.UI
			\SetupFromManifestEntry @MapManifest.Map.UI

		\SetColor Color 32, 32, 220
		\SetPos 0, ScrH!

		localPlayerTable = GAMEMODE.GameData.Lookup_PlayerByEntity[LocalPlayer!]
		if localPlayerTable
			size = 0.05 * \GetInnerSize!
			player = with \Add "DPanel"
				\SetSize size, size
				.Paint = ->

				-- A slightly unreadable chunk of garbage code
				-- responsible for layering the crewmate sprite.
				layers = {}
				for i = 1, 2
					with layers[i] = \Add "DPanel"
						\SetSize size, size
						.Image = CREW_LAYERS[i]
						.Paint = GAMEMODE.Render.DermaFitImage
				layers[1].Color = localPlayerTable.color

			\Track LocalPlayer!, player

hook.Add "Initialize", "Init Hud", ->
	GAMEMODE\HUDReset!

ASSETS = {
	btn: Material "au/gui/button.png", "smooth"
}

hook.Add "HUDPaintBackground", "NMW AU Hud", ->
	-- Iterate through the two possible entity types we can interact with.
	for highlight in *{
		{
			button: input.LookupBinding "use"
			entity: GAMEMODE.UseHighlight
		}
		-- TO-DO: Make this keybind not hardcoded.
		{
			button: "Q"
			entity: GAMEMODE.KillHighlight
		}
	}
		if IsValid highlight.entity
			pos = highlight.entity\WorldSpaceCenter!\ToScreen!

			nearestPoint = highlight.entity\NearestPoint LocalPlayer!\WorldSpaceCenter!
			value = 1 * (1 - math.max 0, math.min 1, 1/90 * nearestPoint\Distance LocalPlayer!\WorldSpaceCenter!)
			size = 0.125 * math.min ScrH!, ScrW!

			-- Since Garry's Mod doesn't allow scaling fonts on the go,
			-- we'll have to scale the ENTIRE rendering sequence.
			m = with Matrix!
				\Translate Vector pos.x, pos.y, 0
				\Scale math.Clamp(value, 0.25, 1) * Vector 1, 1, 1
				\Translate -Vector pos.x, pos.y, 0

			cam.PushModelMatrix m, true
			do
				color = Color 255, 255, 255, math.Clamp 255 * value * 2, 0, 255
				shadowColor = Color 0, 0, 0, math.Clamp 64 * value * 2, 0, 255

				-- The button sprite.
				surface.SetMaterial ASSETS.btn
				surface.SetDrawColor color

				render.PushFilterMag TEXFILTER.ANISOTROPIC
				render.PushFilterMin TEXFILTER.ANISOTROPIC
				surface.DrawTexturedRect pos.x - size/2, pos.y - size/2, size, size
				render.PopFilterMag!
				render.PopFilterMin!

				-- The tooltip.
				draw.SimpleTextOutlined string.upper(highlight.button or "?"), "NMW AU Button Tooltip",
					pos.x, pos.y - size * 0.15, color,
					TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, shadowColor
			cam.PopModelMatrix!

	if IsValid GAMEMODE.Hud
		GAMEMODE.Hud\PaintManual!

hook.Add "ScoreboardShow", "NMW AU Map", ->
	if GAMEMODE\HUD_OpenMap!
		return true

hook.Add "ScoreboardHide", "NMW AU Map", ->
	GAMEMODE\HUD_CloseMap!

concommand.Add "au_debug_eject_test", ->
	if IsValid GAMEMODE.Hud.Eject
		GAMEMODE.Hud.Eject\Remove!

	ply = table.Random GAMEMODE.GameData.PlayerTables
	GAMEMODE\HUD_DisplayEject GAMEMODE.EjectReason.Vote, ply, true, true, 2, 2

concommand.Add "au_debug_kill_test", ->
	killer = table.Random GAMEMODE.GameData.PlayerTables
	victim = table.Random GAMEMODE.GameData.PlayerTables
	GAMEMODE\HUD_PlayKill killer, victim
