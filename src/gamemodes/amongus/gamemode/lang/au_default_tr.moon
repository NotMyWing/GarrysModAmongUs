with GM.Lang\Get "tr"
	["tasks.totalCompleted"] = "TAMAMLANAN TOPLAM GÖREV"
	["tasks.totalCompleted.sabotaged"] = "İLETİŞİM SABOTE EDİLDİ"

	["tasks.commsSabotaged"] = "İletişim Sabote Edildi"
    ["tasks.lightsSabotaged"] = "Işıkları Düzelt (%d%%)"
	["tasks.reactorSabotaged"] = "%d saniye içinde reaktör eriyecek. (%d/%d)"
	["tasks.oxygenSabotaged"] = "%d saniye içinde oksijen tükenecek. (%d/%d)"

	areas = {
		["cafeteria"]:     "Kafeterya"
		["upperEngine"]:   "Üst Motor"
		["reactor"]:       "Reaktör"
		["lowerEngine"]:   "Alt Motor"
		["security"]:      "Güvenlik"
		["electrical"]:    "Elektrik"
		["medbay"]:        "Revir"
		["storage"]:       "Depo"
		["shields"]:       "Kalkanlar"
		["communications"]: "İletişimler"
		["navigation"]:     "Navigasyon"
		["o2"]:             "O2"
		["admin"]:          "Yönetici"
		["weapons"]:        "Silahlar"
	}

	for area, areaName in pairs areas
		["area.#{area}"] = areaName
		["task.divertPower.area.#{area}"] = "Gücü #{areaName} alanına yönlendir"
		["vent.#{area}"] = "#{areaName} adlı yere sız"

	taskNames = {
		"divertPower": "Gücü Yönlendir"
		"alignEngineOutput": "Motor Çıkış Gücünü Hizala"
		"calibrateDistributor": "Distribütörü Kalibre Et"
		"chartCourse": "Rota Planı"
		"cleanO2Filter": "O2 Filtresini Temizle"
		"clearAsteroids": "Asteroitleri Temizle"
		"emptyGarbage": "Çöpü Boşalt"
		"emptyChute": "Kanalı Temizle"
		"fixWiring": "Kablolamayı Düzelt"
		"inspectSample": "Numuneyi İncele"
		"primeShields": "Asal Kalkanlar"
		"stabilizeSteering": "Direksiyonu Stabilize Edin"
		"startReactor": "Reaktörü Başlat"
		"submitScan": "Taramayı Gönder"
		"swipeCard": "Kartı Kaydır"
		"unlockManifolds": "Manifoldların Kilidini Aç"
		"uploadData": "Veri İndir"
		"uploadData.2": "Veri Yükle"
		"fuelEngines": "Motorlara Yakıt Doldur"
	}

	for task, taskName in pairs taskNames
		["task.#{task}"] = taskName

	["meetingButton.cooldown"] = (time) -> {
		{
			text: "Mürettebat Beklemeli"
		}, {
			text: string.format "%ds", time
			color: Color 255, 0, 0
		}, {
			text: "Acil Durum Öncesi"
		}
	}

	["meetingButton.default"] = (nickname, uses) -> {
		{
			text: string.format "Mürettebat %s Var", nickname
		}, {
			text: string.format "%d", uses
			color: Color 255, 0, 0
		}, {
			text: "Kalan Acil Durum Toplantısı"
		}
	}

	["meetingButton.crisis"] = -> {
		{
			text: "ACİL DURUM TOPLANTILARI"
		}, {
			text: "KRİZLERDE YAPILAMAZ"
		}
	}

	["task.clearAsteroids.destroyed"] = "Yok edilen: %d"

	["eject.remaining"] = (remaining) ->
		if remaining == 1
			string.format "1 Sahtekar kaldı."
		else
			string.format "%d Sahtekar kaldı.", remaining

	["eject.reason.tie"]     = "Kimse atılmadı. (Berabere)"
	["eject.reason.skipped"] = "Kimse atılmadı. (Atlandı)"
	["eject.reason.tie"]     = "Kimse atılmadı."

	["eject.text"] = (nickname, confirm, isImposter, total) ->
		string.format (if confirm
			if isImposter
				if total == 1
					"%s Sahtekardı."
				else
					"%s bir Sahtekardı."
		else
				if total == 1
					"%s Sahtekar değildi."
				else
					"%s bir Sahtekar değildi."
		else
			"%s atıldı."), nickname

	["meeting.timer.begins"]     = (time) -> string.format "Oylama %ds içinde başlayacak", time
	["meeting.timer.ends"] 	     = (time) -> string.format "Oylama %ds içinde bitecek", time
	["meeting.timer.proceeding"] = (time) -> string.format "%ds içinde devam edilecek", time
	["meeting.header"] = "Sahtekar Kim?"

	["splash.victory"] = "Zafer"
	["splash.defeat"]  = "Yenilgi"
	["splash.imposter"]  = "Sahtekar"
	["splash.spectator"] = "İzleyici"
	["splash.crewmate"]  = "Mürettebat arkadaşı"
	["splash.text"] = (isPlaying, imposterCount) ->
		amongSubtext = isPlaying and " " or " "

		return if imposterCount == 1
			"Aramızda %s Sahtekar var" .. amongSubtext
		else
			"Aramızda %s Sahtekar var" .. amongSubtext

	["hud.sabotageAndKill"] = "Sabote et ve herkesi öldür."
	["hud.countdown"] = "%d içinde başlıyor"
	["hud.tasks"] = "Görevler:"
	["hud.fakeTasks"] = "Sahte Görevler:"
	["hud.taskComplete"] = "Görev Tamamlandı!"
	["hud.cvar.disabled"] = "Devre Dışı"
	["hud.cvar.enabled"] = "Etkin"
	["hud.cvar.time"] = "%d s."

	["hud.cvar.au_taskbar_updates.0"] = "Her zaman"
	["hud.cvar.au_taskbar_updates.1"] = "Toplantılar"
	["hud.cvar.au_taskbar_updates.2"] = "Asla"

	cvars = {
		au_max_imposters:    "Maks. Sahtekar"
		au_kill_cooldown:    "Öldürme Bekleme Süresi"
		au_time_limit:       "Zaman Sınırı"
		au_killdistance_mod: "Öldürme Mesafesi"
		sv_alltalk:          "Herkes Konuşabilir"
		au_taskbar_updates:  "Görev Çubuğu Güncellemeleri"
		au_player_speed_mod: "Oyuncu Hızı"

		au_meeting_available: "Oyuncu başına toplantı"
		au_meeting_cooldown:  "Toplantı Düğmesi Bekleme Süresi"
		au_meeting_vote_time: "Oy Verme Süresi"
		au_meeting_vote_pre_time:  "Ön Oylama Süresi"
		au_meeting_vote_post_time: "Oylama Sonrası Süre"
		au_confirm_ejects:          "Atılmaları Onayla"
		au_meeting_ononymous: "Anonim oylama"

		au_tasks_short:  "Kısa Görevler"
		au_tasks_long:   "Uzun Görevler"
		au_tasks_common: "Ortak Görevler"
		au_tasks_enable_visual: "Görsel Görevler"
	}

	 for name, value in pairs cvars
		["cvar.#{name}"] = value

	["vot.voted"] = "%s oy verdi. %s kaldı."

	["prepare.admin"] = "Sen bir Yöneticisin!"
	["prepare.spectator"] = "İzleyicisin."
	["prepare.pressToStart"] = "Oyunu başlatmak için [%s] bas."

	["prepare.invalidMap"] = "Geçersiz Harita!"
	["prepare.invalidMap.subText"] = "Harita bildirim dosyası bulunamadı."

	["prepare.warmup"] = "Isınma Zamanı!"
	["prepare.waitingForPlayers"] = "Oyuncular bekleniyor..."
	["prepare.waitingForAdmin"] = "Bir Yöneticinin oyunu başlatması bekleniyor."
	["prepare.commencing"] = "Oyun %d saniye içinde başlayacak."
	["prepare.imposterCount"] = (count) ->
		string.format (if count == 1
			"%d Sahtekar"
		else
			"%d Sahtekar"), count

	["connected.spectating"] = "%s izleyici olarak katıldı."
	["connected.spawned"] = "%s oynamaya hazır."
	["connected.disconnected"] = "%s oyundan ayrıldı!"

	["chat.noTalkingDuringGame"] = "Oyun sırasında konuşamazsın!"

	inspectSample = {
		eta:           "ETA %d."
		addingReagent: "AYIRAÇ EKLENİYOR."
		oneMore:       "1 TANE DAHA."
		testComplete:  "TEST TAMAMLANDI."
		pressToStart:  "BAŞLATMAK için BASIN -->"
		selectAnomaly: "ANOMALİYİ SEÇ."
		hello:         "MERHABA."
		badResult:     "KÖTÜ SONUÇ."
		thankYou:      "TEŞEKKÜR EDERİM!"
		randomText: table.Random {
			"BEKLEMENE GEREK YOK."
			"GİT BAŞKA BİR ŞEY YAP."
			"MOLA VER."
			"GİT BİR KAHVE KAP."
		}
	}

	for key, value in pairs inspectSample
		["tasks.inspectSample.#{key}"] = value

	controls = {
		"map": "Haritayı aç / sabotaj et"
		"kill": "Öldür"
		"use": "Kullan"
		"report": "Cesedi bildir"
		"hideTasks": "Görev listesini gizle"
		"toggleNoClip": "Hayaletlerin duvardan geçebilmesini aç/kapat"
		"showHelp": "Bu menü"
	}

	for key, value in pairs controls
		["help.controls.#{key}"] = value

	tabs = {
		"color": "Renk"
		"settings": "Ayarlar"
		"game": "Oyun"
		"controls": "Kontroller",
		"about": "Hakkında"
	}

	for key, value in pairs tabs
		["help.tab.#{key}"] = value

	settingsCvars = {
		"au_spectator_mode": "İzleyici modu"
		"au_debug_drawversion": "Geçerli sürümü göster"
		"au_vgui_lookaround": "Görev kullanıcı arayüzlerinde bakınmayı etkinleştir"
	}

	for key, value in pairs settingsCvars
		["help.settings.#{key}"] = value

	["sabotage.reactor.hold"] = "Erimeyi durdurmak için basılı tutun"
	["sabotage.reactor.waiting"] = "İkinci kullanıcı bekleniyor"
	["sabotage.reactor.nominal"] = "Reaktör nominal"
