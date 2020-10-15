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

BUTTONS = {
	kill: Material "au/gui/kill.png"
	use: Material "au/gui/use.png"
	report: Material "au/gui/report.png"
}

hud.Init = =>
	@SetSize ScrW!, ScrH!

	hook.Add "OnScreenSizeChanged", "NMW AU Hud Size", ->
		@SetSize ScrW!, ScrH!

	with @buttons = vgui.Create "DPanel", @
		\SetTall ScrH! * 0.20

		margin = ScreenScale 5
		\DockMargin margin, margin, margin, margin
		\Dock BOTTOM
		.Paint = ->
		\SetZPos -1

hud.SetupButtons = (state, impostor) =>
	for _, v in ipairs @buttons\GetChildren!
		v\Remove!

	@buttons\SetAlpha 0
	@buttons\AlphaTo 255, 2

	if state == GAMEMODE.GameState.Preparing
		return

	if impostor
		with @kill = vgui.Create "DPanel", @buttons
			\SetWide @buttons\GetTall!
			\DockMargin 0, 0, ScreenScale(5), 0
			\Dock RIGHT
			.Paint = (_, w, h) ->
				color = if GAMEMODE.KillCooldown >= CurTime!
					Color 255, 255, 255, 32
				elseif IsValid(GAMEMODE.KillHighlight) and not GAMEMODE.GameData.Imposters[GAMEMODE.KillHighlight]
					Color 255, 255, 255
				else
					Color 255, 255, 255, 32

				surface.SetDrawColor color				
				surface.SetMaterial BUTTONS.kill
				render.PushFilterMag TEXFILTER.ANISOTROPIC
				render.PushFilterMin TEXFILTER.ANISOTROPIC
				surface.DrawTexturedRect 0, 0, w, h
				render.PopFilterMag!
				render.PopFilterMin!

				if GAMEMODE.KillCooldown and GAMEMODE.KillCooldown >= CurTime!
					draw.DrawText string.format("%d", math.ceil(math.max(0, GAMEMODE.KillCooldown - CurTime!))), "NMW AU Cooldown", w * 0.5, h * 0.15, Color(255,255,255,255), TEXT_ALIGN_CENTER

	with @use = vgui.Create "DPanel", @buttons
		\SetWide @buttons\GetTall!
		\DockMargin 0, 0, ScreenScale(5), 0
		\Dock RIGHT
		.Paint = (_, w, h) ->
			color = if IsValid GAMEMODE.UseHighlight
				Color 255, 255, 255
			else
				Color 255, 255, 255, 32

			mat = if IsValid(GAMEMODE.UseHighlight) and 0 ~= GAMEMODE.UseHighlight\GetNW2Int "NMW AU PlayerID" 
				BUTTONS.report
			else
				BUTTONS.use

			surface.SetDrawColor color		
			surface.SetMaterial mat
			render.PushFilterMag TEXFILTER.ANISOTROPIC
			render.PushFilterMin TEXFILTER.ANISOTROPIC
			surface.DrawTexturedRect 0, 0, w, h
			render.PopFilterMag!
			render.PopFilterMin!

hud.Countdown = (target) =>
	@__countdownTarget = target

	if IsValid @__countdown
		@__countdown\Remove!

	with @__countdown = vgui.Create "DPanel", @
		\SetSize @GetWide!, @GetTall! * 0.1
		\SetPos 0, @GetTall! * 0.7
		.Paint = (_, w, h) ->
			draw.DrawText string.format("Starting in %d", math.floor math.max(0, @__countdownTarget - CurTime!)), "NMW AU Countdown", w * 0.5, h * 0.25, Color(255,255,255,255), TEXT_ALIGN_CENTER
			if @__countdownTarget - CurTime! <= 0
				_\Remove!

hud.Paint = ->

return vgui.RegisterTable hud, "DPanel"