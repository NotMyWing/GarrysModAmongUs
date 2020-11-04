--- All things render.
-- Handles the rendering of default Source UI elements.
-- Draws halos and nicknames.
-- Exposes helpful functions.
-- @module cl_render

GM.Render = {}

fitImage = (material, w, h) ->
	if texture = material\GetTexture "$basetexture"
		width = texture\GetMappingWidth!
		height = texture\GetMappingHeight!

		imgAspect = width / height
		containerAspect = w / h

		if imgAspect > containerAspect
			h = w / imgAspect
		elseif imgAspect < containerAspect
			w = h * imgAspect

	return w, h

--- Helper function that attemps to fit the specified material into given bounds.
--
-- Makes it possible not to hard-code aspect ratios everywhere.
-- @param material The material to fit.
-- @param width Container width.
-- @param height Container height.
GM.Render.FitMaterial = fitImage

GM.Render.DermaFitImage = (w, h) =>
	with @
		if .Image
			newWidth, newHeight = fitImage .Image, w, h

			surface.SetMaterial .Image
			surface.SetDrawColor .Color or Color 255, 255, 255

			render.PushFilterMag TEXFILTER.ANISOTROPIC
			render.PushFilterMin TEXFILTER.ANISOTROPIC
			surface.DrawTexturedRect w/2 - newWidth/2, h/2 - newHeight/2, newWidth, newHeight
			render.PopFilterMag!
			render.PopFilterMin!

--- Creates a circle for drawing with `surface.DrawPoly`.
-- @param x Origin X.
-- @param y Origin Y.
-- @param radius Radius.
-- @param seg Segments.
GM.Render.CreateCircle = ( x, y, radius, seg ) ->
	cir = {}

	table.insert( cir, { :x, :y, u: 0.5, u: 0.5 } )
	for i = 0, seg
		a = math.rad( ( i / seg ) * -360 )
		table.insert( cir, { x: x + math.sin( a ) * radius, y: y + math.cos( a ) * radius, u: math.sin( a ) / 2 + 0.5, v: math.cos( a ) / 2 + 0.5 } )

	a = math.rad( 0 )
	table.insert( cir, { x: x + math.sin( a ) * radius, y: y + math.cos( a ) * radius, u: math.sin( a ) / 2 + 0.5, v: math.cos( a ) / 2 + 0.5 } )

	return cir

hide = {
	"CHudCrosshair": true
	"CHudHealth": true
	"CHudBattery": true
	"CHudWeaponSelection": true
}

hook.Add "HUDShouldDraw", "NMW AU HideHud", (element) ->
	if hide[element]
		false

hook.Add "CalcView", "NMW AU CalcView", ( ply, pos, angles, fov ) ->
	if GAMEMODE.GameData.Vented
		return {
			origin: ply\GetPos! + Vector 0, 0, 10
			:angles
			:fov
		}

color_sabotage = Color 32, 255, 32
color_sabotageb = Color 255, 32, 32

color_kill = Color 255, 0, 0
color_task   = Color 255, 230, 0
color_white = Color 255, 255, 255

GM.GetHighlightColor = (entity) => if IsValid entity
	className = entity\GetClass!

	return switch className
		when "prop_vent", "func_vent"
			color_kill
		when "prop_meeting_button", "func_meeting_button"
			color_white
		when "prop_task_button", "func_task_button", "prop_sabotage_button", "func_sabotage_button"
			color_task

hook.Add "PreDrawHalos", "NMW AU Highlight", ->
	-- Highlight our current tasks.
	if not GAMEMODE.GameData.Imposters[GAMEMODE.GameData.Lookup_PlayerByEntity[LocalPlayer!]]
		for _, task in pairs GAMEMODE.GameData.MyTasks
			btn = task\GetActivationButton!
			if not IsValid btn
				continue

			color = GAMEMODE\GetHighlightColor task\GetActivationButton!
			-- Obligatory wall of checks.
			if color and not task\GetCompleted! and
				IsValid(btn) and btn ~= GAMEMODE.UseHighlight and
				200 > btn\GetPos!\Distance LocalPlayer!\GetPos!

					with util.TraceLine {
						start: LocalPlayer!\EyePos!
						endpos: btn\WorldSpaceCenter!
						filter: (trEnt) -> trEnt == ent or not trEnt\IsPlayer!
					}
						if .Entity == btn
							halo.Add { btn }, color, 3, 3, 2, true, true

	-- Highlight sabotage buttons.
	for btn in pairs GAMEMODE.GameData.SabotageButtons
		halo.Add { btn }, math.floor((SysTime! * 4) % 2) ~= 0 and color_sabotage or color_sabotageb, 1, 1, 10, true, true

	if IsValid GAMEMODE.KillHighlight
		halo.Add { GAMEMODE.KillHighlight }, color_kill, 4, 4, 8, true, true

	if IsValid GAMEMODE.UseHighlight
		if color = GAMEMODE\GetHighlightColor GAMEMODE.UseHighlight
			halo.Add { GAMEMODE.UseHighlight }, color, 4, 4, 8, true, true

color_crew = Color(255, 255, 255)
color_imposter = Color(255, 0, 0)

hook.Add "PostDrawTranslucentRenderables", "NMW AU Nicknames", (depth, skybox) ->
	if skybox
		return

	players = GAMEMODE.Util.SortByDistance player.GetAll!, LocalPlayer!\GetPos!

	aply = GAMEMODE.GameData.Lookup_PlayerByEntity and GAMEMODE.GameData.Lookup_PlayerByEntity[LocalPlayer!]
	for _, ply in ipairs players
		lply = aply and GAMEMODE.GameData.Lookup_PlayerByEntity[ply]
		if ply\IsDormant! or ply == LocalPlayer!
			continue

		pos = ply\GetPos!
		pos = pos + Vector 0, 0, 70

		angle = (pos - LocalPlayer!\GetPos!)\Angle!
		angle = Angle( 0, angle.y, 0 )
		angle.y = angle.y + math.sin( CurTime() ) * 10

		angle\RotateAroundAxis( angle\Up(), -90 )
		angle\RotateAroundAxis( angle\Forward(), 90 )

		cam.Start3D2D( pos, angle, 0.075 )
		do
			tW, tH = surface.GetTextSize ply\Nick!

			color = if lply and GAMEMODE.GameData.Imposters[lply]
				color_imposter
			else
				color_crew

			draw.SimpleText ply\Nick!, "NMW AU Meeting Button", -tW / 2, -tH/2, color
		cam.End3D2D()
