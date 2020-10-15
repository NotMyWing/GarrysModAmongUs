hook.Add "Think", "Think_Lights!", ->
	if false 
		return

	with dlight = DynamicLight LocalPlayer!\EntIndex!
		.pos = LocalPlayer!\GetShootPos!
		.r = 127
		.g = 127
		.b = 127
		.brightness = 2
		.Decay = 1000
		.Size = 200
		.DieTime = CurTime! + 0.2

hook.Add "CalcView", "MyCalcView", ( ply, pos, angles, fov ) ->
	newOrigin = if GAMEMODE.Vented
		ply\GetPos! + Vector 0, 0, 10
	else
		pos - Vector 0, 0, 15
 
	return {
		origin: newOrigin
		:angles
		:fov
	}

hide = {
	"CHudCrosshair": true
	"CHudHealth": true
	"CHudBattery": true
	"CHudWeaponSelection": true
}

hook.Add "HUDShouldDraw", "HideHUD", (element) ->
	if hide[element]
		false

color_kill = Color 255, 0, 0
color_use = Color 255, 255, 255
hook.Add "PreDrawHalos", "NMW AU Highlight", ->
	if IsValid GAMEMODE.KillHighlight
		halo.Add { GAMEMODE.KillHighlight }, color_kill, 6, 6, 2, true, true

	if IsValid GAMEMODE.UseHighlight
		halo.Add { GAMEMODE.UseHighlight }, color_use, 6, 6, 2, true, true

GM.Render = {}
--
-- Sigmoid curve. [0 .. 1]
--
pow = math.pow
GM.Render.SigmoidCurve = (x, p = 0.5, s = 0.75) ->
    c = (2 / (1 - s)) - 1

	if (x <= p)
		pow(x, c) / pow(p, c - 1)
    else
		1 - (pow(1 - x, c) / pow(1 - p, c - 1))

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
