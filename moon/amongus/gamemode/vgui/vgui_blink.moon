blink = {}

blink.Init = => with @
	\SetSize ScrW!, ScrH!
	\SetAlpha 0
	\SetZPos 30001
	.Paint = (w, h) =>
		surface.SetDrawColor 0, 0, 0
		surface.DrawRect 0, 0, w, h

blink.Blink = (duration, delay = 0.25, pre = 0.1) => with @
	\AlphaTo 255, pre, nil, ->
		\AlphaTo 0, math.max(0, duration - delay), delay, ->
			\Remove!

return vgui.RegisterTable blink, "DPanel"