surface.CreateFont "NMW AU Countdown", {
	font: "Arial"
	size: ScreenScale 20
	weight: 500
	outline: true
}

surface.CreateFont "NMW AU Cooldown", {
	font: "Arial"
	size: ScrH! * 0.125
	weight: 500
	outline: true
}

hud = {}

MAT_BUTTONS = {
	kill: Material "au/gui/kill.png"
	use: Material "au/gui/use.png"
	report: Material "au/gui/report.png"
}

COLOR_BTN_DISABLED = Color 255, 255, 255, 32
COLOR_BTN = Color 255, 255, 255

hud.Init = =>
	@SetSize ScrW!, ScrH!

	hook.Add "OnScreenSizeChanged", "NMW AU Hud Size", ->
		@SetSize ScrW!, ScrH!

	with @buttons = vgui.Create "DPanel", @
		\SetTall ScrH! * 0.20

		margin = ScreenScale 5
		\DockMargin margin, margin, margin, margin
		\Dock BOTTOM
		\SetZPos -1

		.Paint = ->

hud.SetupButtons = (state, impostor) =>
	for _, v in ipairs @buttons\GetChildren!
		v\Remove!

	@buttons\SetAlpha 0
	@buttons\AlphaTo 255, 2

	if state == GAMEMODE.GameState.Preparing
		return

	-- Kill button for imposerts. Content-aware.
	if impostor
		with @kill = vgui.Create "DPanel", @buttons
			\SetWide @buttons\GetTall!
			\DockMargin 0, 0, ScreenScale(5), 0
			\Dock RIGHT
			.Paint = (_, w, h) ->
				color = if GAMEMODE.KillCooldown >= CurTime!
					COLOR_BTN_DISABLED
				elseif IsValid(GAMEMODE.KillHighlight) and not GAMEMODE.GameData.Imposters[GAMEMODE.KillHighlight]
					COLOR_BTN
				else
					COLOR_BTN_DISABLED

				-- Honestly I wish I had a wrapper for this kind of monstrosities.
				surface.SetDrawColor color
				surface.SetMaterial MAT_BUTTONS.kill

				render.PushFilterMag TEXFILTER.ANISOTROPIC
				render.PushFilterMin TEXFILTER.ANISOTROPIC
				surface.DrawTexturedRect 0, 0, w, h
				render.PopFilterMag!
				render.PopFilterMin!

				if GAMEMODE.KillCooldown and GAMEMODE.KillCooldown >= CurTime!
					draw.DrawText string.format("%d", math.ceil(math.max(0, GAMEMODE.KillCooldown - CurTime!))),
						"NMW AU Cooldown", w * 0.5, h * 0.15, Color(255,255,255,255), TEXT_ALIGN_CENTER

	-- Use/report button. Content-aware.
	with @use = vgui.Create "DPanel", @buttons
		\SetWide @buttons\GetTall!
		\DockMargin 0, 0, ScreenScale(5), 0
		\Dock RIGHT
		.Paint = (_, w, h) ->
			color = if IsValid GAMEMODE.UseHighlight
				COLOR_BTN
			else
				COLOR_BTN_DISABLED

			mat = if IsValid(GAMEMODE.UseHighlight) and 0 ~= GAMEMODE.UseHighlight\GetNW2Int "NMW AU PlayerID"
				MAT_BUTTONS.report
			else
				MAT_BUTTONS.use

			-- Like, jesus christ man.
			surface.SetDrawColor color
			surface.SetMaterial mat

			render.PushFilterMag TEXFILTER.ANISOTROPIC
			render.PushFilterMin TEXFILTER.ANISOTROPIC
			surface.DrawTexturedRect 0, 0, w, h
			render.PopFilterMag!
			render.PopFilterMin!

--- Displays a countdown.
-- @param time Target time.
hud.Countdown = (time) =>
	@countdownTime = time

	if IsValid @countdown
		@countdown\Remove!

	with @countdown = vgui.Create "DPanel", @
		\SetSize @GetWide!, @GetTall! * 0.1
		\SetPos 0, @GetTall! * 0.7

		color = Color 255, 255, 255
		.Paint = (_, w, h) ->
			draw.DrawText string.format("Starting in %d", math.floor math.max(0, @countdownTime - CurTime!)),
				"NMW AU Countdown",
				w * 0.5, h * 0.25, color, TEXT_ALIGN_CENTER

			if @countdownTime - CurTime! <= 0
				_\Remove!

hud.Paint = ->

return vgui.RegisterTable hud, "DPanel"