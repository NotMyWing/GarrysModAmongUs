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

hook.Add "Tick", "NMW AU Light", ->
	if not IsValid LocalPlayer!
		return

	with dlight = DynamicLight LocalPlayer!\EntIndex!
		.pos = LocalPlayer!\GetShootPos!
		.r = 127
		.g = 127
		.b = 127
		.brightness = 2
		.Decay = 0
		.Size = 200
		.DieTime = CurTime! + 0.25

	-- screw implicit returns man
	return

hook.Add "CalcView", "NMW AU CalcView", ( ply, pos, angles, fov ) ->
	newOrigin = if GAMEMODE.GameData.Vented
		ply\GetPos! + Vector 0, 0, 10
	else
		pos - Vector 0, 0, 15

	return {
		origin: newOrigin
		:angles
		:fov
	}

color_sabotage = Color 32, 255, 32
color_sabotageb = Color 255, 32, 32

color_kill = Color 255, 0, 0
color_use   = Color 255, 230, 0
color_task  = Color 255, 230, 0, 32

hook.Add "PreDrawHalos", "NMW AU Highlight", ->
	-- Highlight our current tasks.
	for _, task in pairs GAMEMODE.GameData.MyTasks
		if not task.completed and IsValid(task.entity) and task.entity ~= GAMEMODE.UseHighlight and task.entity\GetPos!\Distance(LocalPlayer!\GetPos!) < 200
			halo.Add { task.entity }, color_task, 6, 6, 2, true, true

	-- Highlight sabotage buttons.
	for btn in pairs GAMEMODE.GameData.SabotageButtons
		halo.Add { btn }, math.floor((SysTime! * 4) % 2) ~= 0 and color_sabotage or color_sabotageb, 1, 1, 10, true, true

	if IsValid GAMEMODE.KillHighlight
		halo.Add { GAMEMODE.KillHighlight }, color_kill, 4, 4, 5, true, true

	if IsValid GAMEMODE.UseHighlight
		entClass = GAMEMODE.UseHighlight\GetClass!
		color = if entClass == "prop_vent" or entClass == "func_vent"
			color_kill
		else
			color_use

		halo.Add { GAMEMODE.UseHighlight }, color, 4, 4, 5, true, true

color_crew = Color(255, 255, 255)
color_imposter = Color(255, 0, 0)

hook.Add "PostDrawTranslucentRenderables", "NMW AU Nicknames", (depth, skybox) ->
	if skybox
		return

	players = GAMEMODE.Util.SortByDistance player.GetAll!, LocalPlayer!

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
