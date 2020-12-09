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
	return false if GAMEMODE\IsGameInProgress! and
		GAMEMODE\IsMeetingInProgress! and "CHudChat" == element

	return false if hide[element]

hook.Add "CalcView", "NMW AU CalcView", ( ply, pos, angles, fov ) -> {
	origin: ply\GetPos! + Vector 0, 0, 10
	:angles
	:fov
} if GAMEMODE.GameData.Vented

color_sabotage = Color 32, 255, 32
color_sabotageb = Color 255, 32, 32

color_kill  = Color 255, 0, 0
color_task  = Color 255, 230, 0
color_white = Color 255, 255, 255

GM.GetHighlightColor = (entity) => if IsValid entity
	return (entity\GetNWVector "NMW AU HighlightColor")\ToColor! if entity\GetNWBool "NMW AU UseHighlight"

	hookResult = hook.Call "GMAU ShouldHighlight"
	return color_white if hookResult == true
	return hookResult if IsColor hookResult

	return switch entity\GetClass!
		when "prop_vent", "func_vent"
			color_kill
		when "prop_task_button", "func_task_button"
			color_task
		when "prop_meeting_button", "func_meeting_button"
			color_white

hook.Add "PreDrawHalos", "NMW AU Highlight", ->
	return unless GAMEMODE\IsGameInProgress!

	-- Highlight sabotage buttons.
	for btn in pairs GAMEMODE.GameData.SabotageButtons
		halo.Add { btn }, math.floor((SysTime! * 4) % 2) ~= 0 and color_sabotage or color_sabotageb, 1, 1, 10, true, true

	if IsValid GAMEMODE.KillHighlight
		halo.Add { GAMEMODE.KillHighlight }, color_kill, 4, 4, 8, true, true

	highlighted = {}
	if IsValid GAMEMODE.UseHighlight
		if color = GAMEMODE\GetHighlightColor GAMEMODE.UseHighlight
			highlighted[GAMEMODE.UseHighlight] = true
			halo.Add { GAMEMODE.UseHighlight }, color, 4, 4, 8, true, true

	-- Highlight all highlightables, except tasks.
	for ent in *ents.FindInSphere LocalPlayer!\GetPos!, 160
		continue if ent.GetTaskName
		continue if highlighted[ent]

		-- Only highlight vents for the imposters.
		continue if not LocalPlayer!\IsImposter! and
			(ent\GetClass! == "func_vent" or ent\GetClass! == "prop_vent")

		color = GAMEMODE\GetHighlightColor ent
		if color
			halo.Add { ent }, color, 3, 3, 2, true, true

	-- Highlight tasks. The reason why they're handled separately is that
	-- it's impossible to do in the upper block without re-iterating the entire task list every time.
	if not LocalPlayer!\IsImposter!
		for taskName, taskInstance in pairs GAMEMODE.GameData.MyTasks
			continue if taskInstance\GetCompleted!

			button = taskInstance\GetActivationButton!
			continue unless IsValid button
			continue if highlighted[button]

			color = GAMEMODE\GetHighlightColor button

			continue if not taskInstance\GetPositionImportant! and
				160 < button\GetPos!\Distance LocalPlayer!\GetPos!

			if button
				halo.Add { button }, color, 3, 3, 2, true, true

color_crew = Color 255, 255, 255
color_imposter = Color 255, 0, 0
color_black = Color 0, 0, 0, 128

hook.Add "PostPlayerDraw", "NMW AU Nicknames", (ply) ->
	-- Don't draw our nickname.
	-- Don't draw ghost nicknames.
	-- Don't draw invalid players' nicknames... what?
	return if not ply\IsValid! or ply\IsDormant! or ply == LocalPlayer!

	-- No drawing if something doesn't want us to draw.
	return if true == hook.Call "GMAU PreDrawNicknames"

	-- Position the text directly above the player's head.
	pos = ply\OBBMaxs!
	pos += ply\GetPos! + Vector -pos.x, -pos.y, 2

	-- Calculate the text angle.
	angle = (pos - EyePos!)\Angle!
	angle = Angle angle.p, angle.y, 0
	angle.y += 10 * math.sin CurTime!

	calculated = {
		player: ply
		playerPos: pos
		textAngle: angle
	}

	-- Pass the table to hooks.
	-- If something returned `true`, pass.
	return if true == hook.Call "GMAU CalcNicknames", nil, calculated

	-- Rotation shenanigans.
	calculated.textAngle\RotateAroundAxis calculated.textAngle\Up!, -90
	calculated.textAngle\RotateAroundAxis calculated.textAngle\Forward!, 90

	-- Draw the actual 3D2D text above the player in question.
	cam.Start3D2D calculated.playerPos, calculated.textAngle, 0.075
	do
		-- Draw a "better" outline.
		passes = 4
		for i = -passes/2, passes/2
			for j = -passes/2, passes/2
				continue if i == 0 or j == 0

				offsetX = 2 * i
				offsetY = 2 * j
				draw.SimpleText ply\Nick!, "NMW AU Meeting Button",
					offsetX, offsetY, color_black, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER

		color = if ply\IsImposter!
			color_imposter
		else
			color_crew

		draw.SimpleText ply\Nick!, "NMW AU Meeting Button", 0, 0, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER
	cam.End3D2D!
