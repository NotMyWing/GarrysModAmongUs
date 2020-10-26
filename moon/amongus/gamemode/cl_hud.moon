VGUI_HUD = include "vgui/vgui_hud.lua"
VGUI_MEETING = include "vgui/vgui_meeting.lua"
VGUI_EJECT = include "vgui/vgui_eject.lua"
VGUI_SPLASH = include "vgui/vgui_splash.lua"
VGUI_BLINK = include "vgui/vgui_blink.lua"
VGUI_VENT = include "vgui/vgui_vent.lua"
VGUI_KILL = include "vgui/vgui_kill.lua"

include "vgui/vgui_task_base.lua"
include "vgui/vgui_task_placeholder.lua"

surface.CreateFont "NMW AU Button Tooltip", {
	font: "Arial"
	size: ScreenScale 35
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

		@Hud.Meeting = with vgui.CreateFromTable VGUI_MEETING, @Hud
			\StartEmergency caller, bodyColor

GM.HUD_DisplayEject = (reason, ply, confirm, imposter, remaining, total) =>
	if IsValid @Hud
		if IsValid @Hud.Eject
			@Hud.Meeting\Remove!

		@Hud.Eject = with vgui.CreateFromTable VGUI_EJECT, @Hud
			\Eject reason, ply, confirm, imposter, remaining, total

GM.HUD_DisplayGameOver = (reason) =>
	if IsValid @Hud
		@Hud.Splash = with vgui.CreateFromTable VGUI_SPLASH, @Hud
			\DisplayGameOver reason

GM.HUD_DisplayShush = (reason) =>
	if IsValid @Hud
		@Hud.Splash = with vgui.CreateFromTable VGUI_SPLASH, @Hud
			\DisplayShush!

GM.HUD_PlayKill = (killer, victim) =>
	if IsValid @Hud
		if IsValid @Hud.Kill
			@Hud.Kill\Remove!

		@Hud.Kill = with vgui.CreateFromTable VGUI_KILL, @Hud
			\Kill killer, victim

hook.Add "Initialize", "Init Hud", ->
	GAMEMODE\HUDReset!

ASSETS = {
	btn: Material "au/gui/button.png", "smooth"
	map: Material "au/gui/mapa.png", "smooth"
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
			pos = highlight.entity\GetPos!\ToScreen!

			value = 1.25 * (1 - math.max 0, math.min 1, 1/90 * highlight.entity\GetPos!\Distance LocalPlayer!\GetPos!)
			size = 0.2 * math.min ScrH!, ScrW!

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

concommand.Add "au_debug_eject_test", ->
	if IsValid GAMEMODE.Hud.Eject
		GAMEMODE.Hud.Eject\Remove!

	ply = table.Random GAMEMODE.GameData.PlayerTables
	GAMEMODE\HUD_DisplayEject GAMEMODE.EjectReason.Vote, ply, true, true, 2, 2

concommand.Add "au_debug_kill_test", ->
	killer = table.Random GAMEMODE.GameData.PlayerTables
	victim = table.Random GAMEMODE.GameData.PlayerTables
	GAMEMODE\HUD_PlayKill killer, victim
