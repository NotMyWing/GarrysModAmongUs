VGUI_HUD = include "vgui/vgui_hud.lua"
VGUI_MEETING = include "vgui/vgui_meeting.lua"
VGUI_EJECT = include "vgui/vgui_eject.lua"
VGUI_SPLASH = include "vgui/vgui_splash.lua"
VGUI_BLINK = include "vgui/vgui_blink.lua"
VGUI_VENT = include "vgui/vgui_vent.lua"

GM.Blink = (duration = 1, delay, pre) =>
	vgui.CreateFromTable(VGUI_BLINK)\Blink duration, delay, pre

GM.HUDShowVents = (vents) =>
	if IsValid @Hud
		if IsValid @Hud.Vents
			@Hud.Vents\Remove!

		@Hud.Vents = with vgui.CreateFromTable(VGUI_VENT)
			\ShowVents vents

GM.HUDReset = =>
	if IsValid @Hud
		@Hud\Remove!

	@Hud = vgui.CreateFromTable VGUI_HUD
	@Hud\SetPaintedManually true

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

if GAMEMODE and IsValid GAMEMODE.Hud
	GAMEMODE\HUDReset!

hook.Add "Initialize", "Init Hud", ->
	GAMEMODE\HUDReset!

hook.Add "HUDPaintBackground", "NMW AU Hud", ->
	if IsValid GAMEMODE.Hud
		cam.Start2D!
		GAMEMODE.Hud\PaintManual!
		cam.End2D!
	
concommand.Add "au_debug_eject_test", ->
	if IsValid GAMEMODE.Hud.Eject
		GAMEMODE.Hud.Eject\Remove!

	ply = table.Random GAMEMODE.GameData.PlayerTables
	GAMEMODE\HUD_DisplayEject GAMEMODE.EjectReason.Vote, ply, true, true, 2, 2