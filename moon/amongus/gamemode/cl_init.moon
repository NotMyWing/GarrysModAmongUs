include "shared.lua"
include "cl_hud.lua"
include "cl_net.lua"
include "cl_render.lua"

hook.Add "InitPostEntity", "NMW AU Flash", ->
	if not system.HasFocus!
		system.FlashWindow!

key_num = (key) ->
	if GAMEMODE.GameData.Vented
		GAMEMODE\VentRequest key - 1

keyBinds = {
	[KEY_Q]: ->
		with GAMEMODE
			if .GameData.ActivePlayersMap
				lply = .GameData.ActivePlayersMap[LocalPlayer!]

				if .GameData.Imposters[lply] and IsValid(GAMEMODE.KillHighlight) and GAMEMODE.KillHighlight\IsPlayer!
					\KillRequest .KillHighlight

	[KEY_1]: key_num
	[KEY_2]: key_num
	[KEY_3]: key_num
	[KEY_4]: key_num
	[KEY_5]: key_num
	[KEY_6]: key_num
	[KEY_7]: key_num
	[KEY_8]: key_num
	[KEY_9]: key_num
}

keyMemo = {}

hook.Add "Tick", "NMW AU KeyBinds", ->
	for key, fn in pairs keyBinds
		old = keyMemo[key]
		new = input.IsKeyDown key
		if new and not old
			fn key

		keyMemo[key] = new

hook.Add "Tick", "NMW AU Highlight", ->
	if IsValid LocalPlayer!
		killable, usable = GAMEMODE\TracePlayer LocalPlayer!
		GAMEMODE.KillHighlight = killable
		GAMEMODE.UseHighlight = usable

GM.HUDDrawTargetID = ->
hook.Add "EntityEmitSound", "TimeWarpSounds", (t) ->
	if t.Entity\IsRagdoll!
		return false

hook.Add "CreateClientsideRagdoll", "test", (owner, rag) ->
	rag\GetPhysicsObject!\SetMaterial "gmod_silent"

color_crew = Color(255, 255, 255)
color_imposter = Color(255, 0, 0)

hook.Add "PostDrawOpaqueRenderables", "NMW AU Nicknames", ->
	players = player.GetAll!

	export distSort_memo = {}
	export distSort_player = LocalPlayer!
	table.sort players, distSort

	aply = GAMEMODE.GameData.ActivePlayersMap and GAMEMODE.GameData.ActivePlayersMap[LocalPlayer!]
	for _, ply in ipairs players
		lply = aply and GAMEMODE.GameData.ActivePlayersMap[ply]				
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

GM.CreateVentAnim = (ply, pos, appearing) =>
	with ventAnim = ents.CreateClientside "vent_jump"
		\SetPos pos
		\SetModel ply\GetModel!
		\SetColor ply\GetColor!
		.Appearing = appearing
		\Spawn!
		\Activate!

hook.Add "InitPostEntity", "NWM AU RequestUpdate", ->
	net.Start "NMW AU Flow"
	net.WriteUInt GAMEMODE.FlowTypes.RequestUpdate, GAMEMODE.FlowSize
	net.SendToServer!