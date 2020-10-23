taskTable = {
	Type: GM.TaskType.Common
}

if CLIENT
	surface.CreateFont "NMW AU Swipe", {
		font: "Courier New"
		size: 0.05 * math.min ScrH! * 0.8, ScrW! * 0.8
	}

	ASSETS = {
		bg: Material "au/gui/tasks/swipeCard/base.png", "smooth"
		card: Material "au/gui/tasks/swipeCard/card.png", "smooth"
		sliderTop: Material "au/gui/tasks/swipeCard/sliderTop.png", "smooth"
		sliderTopGreen: Material "au/gui/tasks/swipeCard/sliderTopGreen.png", "smooth"
		sliderTopRed: Material "au/gui/tasks/swipeCard/sliderTopRed.png", "smooth"
		wallet: Material "au/gui/tasks/swipeCard/wallet.png", "smooth"
	}

	SOUNDS = {
		out: "au/panel_admin_walletout.wav"
		accept: "au/panel_admin_cardaccept.wav"
		deny: "au/panel_admin_carddeny_f2.wav"
		swipe: ["au/panel_admin_cardmove#{i}.wav" for i = 1, 3]
	}

	taskTable.CreateVGUI = =>
		base = vgui.Create "AmongUsTaskBase"

		with base
			\Setup with container = vgui.Create "DPanel"
				local ledGreen
				local ledRed
				local label

				max_size = math.min ScrH! * 0.8, ScrW! * 0.8

				\SetSize max_size + max_size * (190 * 2 / 900), max_size
				.Paint = ->

				with background = \Add "DImage"
					\SetSize max_size, max_size
					\Center!
					\SetMaterial ASSETS.bg

				with \Add "DImageButton"
					cardSize = max_size * (410/900)
					finalSizeW, finalSizeH = GAMEMODE.Render.FitMaterial ASSETS.card, cardSize, cardSize

					smallCardSize = max_size * (300/900)
					\SetSize GAMEMODE.Render.FitMaterial ASSETS.card, smallCardSize, smallCardSize
					\SetMaterial ASSETS.card
					\SetPos max_size * (190 / 900) + max_size * (100/900), max_size * (700/900)

					moved = false
					moving = false
					depressed = false
					swiped = false
					clickOffset = 0
					swipeStart = 0

					.OnReleased = ->
						if not moving and moved and depressed
							swiped = false
							depressed = false

							destX, destY = 0, max_size * (200 / 900)
							curX = \GetPos!

							time = SysTime! - swipeStart
							if time < 0.5 or time > 0.8 or curX ~= math.floor container\GetWide! - finalSizeW
								ledRed\AlphaTo 255, 0.1
								surface.PlaySound SOUNDS.deny

								label\SetText if curX ~= math.floor container\GetWide! - finalSizeW
									"BAD READ. TRY AGAIN."
								elseif time > 0.8
									"TOO SLOW. TRY AGAIN."
								else
									"TOO FAST. TRY AGAIN."

								if destX ~= curX
									moving = true
									\MoveTo 0, max_size * (200 / 900), 0.3, 0, nil, ->
										moving = false
							else
								label\SetText "ACCEPTED. THANK YOU."
								ledRed\AlphaTo 0, 0.1
								ledGreen\AlphaTo 255, 0.1
								surface.PlaySound SOUNDS.accept
								base\Submit!

					.OnDepressed = ->
						if not moving and moved and not depressed
							swipeStart = SysTime!
							ledGreen\AlphaTo 0, 0.1
							ledRed\AlphaTo 0, 0.1

							clickOffset = \LocalCursorPos!
							depressed = true

					.Think = ->
						if depressed
							cX, _ = container\LocalCursorPos!
							oldX, oldY = \GetPos!

							cX = math.Clamp cX - clickOffset, 0, container\GetWide! - finalSizeW

							if oldX ~= cX and not swiped
								swiped = true
								surface.PlaySound table.Random SOUNDS.swipe

							\SetPos cX, oldY

					.DoClick = ->
						if not moving and not moved
							surface.PlaySound SOUNDS.out

							moving = true
							\SizeTo finalSizeW, finalSizeH, 0.75

							\MoveTo 0, max_size * (200 / 900), 0.75, 0, nil, ->
								moving = false
								moved = true

								ledGreen\AlphaTo 255, 0.1
								label\SetText "PLEASE SWIPE CARD"

				with \Add "DImage"
					\SetSize GAMEMODE.Render.FitMaterial ASSETS.sliderTop, max_size, max_size
					\SetZPos 1
					\CenterHorizontal!
					\SetMaterial ASSETS.sliderTop

					label = with \Add "DLabel"
						\SetColor Color 255, 255, 255
						\SetFont "NMW AU Swipe"
						\SetText "PLEASE INSERT CARD"
						\SetSize max_size * (738/900), max_size * (51/900)
						\SetPos max_size * (80/900), max_size * (35/900)
						\SetContentAlignment 4

						cb = ->
							\NewAnimation 0, 1, 0, ->
								text = \GetText!
								if text[1] == " "
									text = string.sub text, 2, -1
								else
									text = " " .. text

								\SetText text

								cb!

						cb!

				ledGreen = with \Add "DImage"
					\SetSize GAMEMODE.Render.FitMaterial ASSETS.sliderTop, max_size, max_size
					\SetZPos 2
					\CenterHorizontal!
					\SetMaterial ASSETS.sliderTopGreen
					\SetAlpha 0

				ledRed = with \Add "DImage"
					\SetSize GAMEMODE.Render.FitMaterial ASSETS.sliderTop, max_size, max_size
					\SetZPos 2
					\CenterHorizontal!
					\SetMaterial ASSETS.sliderTopRed
					\SetAlpha 0

				with \Add "DImage"
					\SetSize GAMEMODE.Render.FitMaterial ASSETS.wallet, max_size, max_size
					\SetZPos 2
					\AlignBottom 0
					\CenterHorizontal!
					\SetMaterial ASSETS.wallet
			\Popup!

return taskTable
