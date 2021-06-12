with GM.Lang\Get "ru"
	["tasks.totalCompleted"] = "ВСЕГО ЗАДАНИЙ ВЫПОЛНЕНО"
	["tasks.totalCompleted.sabotaged"] = "САБОТАЖ КОММУНИКАЦИОННОГО МОДУЛЯ"

	["tasks.commsSabotaged"] = "Саботаж коммуникационного модуля"
	["tasks.lightsSabotaged"] = "Почините свет (%d%%)"
	["tasks.reactorSabotaged"] = "Взрыв реактора через %d с. (%d/%d)"
	["tasks.oxygenSabotaged"] = "Утечка кислорода через %d с. (%d/%d)"

	areas = {
		["cafeteria"]:      "Столовая"
		["upperEngine"]:    "Верхний двигатель"
		["reactor"]:        "Реактор"
		["lowerEngine"]:    "Нижний двигатель"
		["security"]:       "Охрана"
		["electrical"]:     "Электричество"
		["medbay"]:         "Медпункт"
		["storage"]:        "Хранилище"
		["shields"]:        "Щиты"
		["communications"]: "Связь"
		["navigation"]:     "Навигация"
		["o2"]:             "O2"
		["admin"]:          "Управление"
		["weapons"]:        "Оружейная"
	}

	for area, areaName in pairs areas
		["area.#{area}"] = areaName
		["task.divertPower.area.#{area}"] = "Проведите энергию в #{areaName}"
		["vent.#{area}"] = "Телепортироваться в #{areaName}"

	taskNames = {
		"divertPower": "Проведите энергию"
		"alignEngineOutput": "Выровняйте мощность"
		"calibrateDistributor": "Откалибруйте передатчик"
		"chartCourse": "Организуйте маршрут"
		"cleanO2Filter": "Очистите фильтр"
		"clearAsteroids": "Раскромсайте астероиды"
		"emptyGarbage": "Выбросите мусор"
		"emptyChute": "Очистите отсек"
		"fixWiring": "Почините проводку"
		"inspectSample": "Исследуйте образец"
		"primeShields": "Почините щиты"
		"stabilizeSteering": "Стабилизируйте управление"
		"startReactor": "Запустите реактор"
		"submitScan": "Проведите сканирование"
		"swipeCard": "Проведите картой"
		"unlockManifolds": "Разблокируйте трубопроводку"
		"uploadData": "Скачайте данные"
		"uploadData.2": "Загрузите данные"
		"fuelEngines": "Заправьте двигатели"
	}

	for task, taskName in pairs taskNames
		["task.#{task}"] = taskName

	["meetingButton.cooldown"] = (time) -> {
		{
			text: "ЭКИПАЖ ДОЛЖЕН ПОДОЖДАТЬ"
		}, {
			text: string.format "%d СЕК.", time
			color: Color 255, 0, 0
		}, {
			text: "ДО СЛЕДУЮЩЕГО СОБРАНИЯ"
		}
	}

	["meetingButton.default"] = (nickname, uses) -> {
		{
			text: string.format "ЧЛЕН ЭКИПАЖА %s МОЖЕТ", nickname
		}, {
			text: string.format "%d", uses
			color: Color 255, 0, 0
		}, {
			text: "РАЗ(А) ОРГАНИЗОВАТЬ СОБРАНИЕ"
		}
	}

	["meetingButton.crisis"] = -> {
		{
			text: "ЭКСТРЕННЫЕ СОБРАНИЕ ОТКЛЮЧЕНЫ"
		}, {
			text: "ВО ВРЕМЯ ПРОИСШЕСТВИЙ"
		}
	}

	["task.clearAsteroids.destroyed"] = "Уничтожено: %d"

	["eject.remaining"] = (remaining) ->
		string.format (switch remaining % 10
			when 1
				"Остался %s Предатель."
			when 2, 3, 4
				"Осталось %s Предателя."
			else
				"Осталось %s Предателей."
		), remaining

	["eject.reason.tie"]     = "Не было принято единого решения."
	["eject.reason.skipped"] = "Было решено пропустить голосование."
	["eject.reason.generic"] = "Было решено пропустить голосование."

	["eject.text"] = (nickname, confirm, isImposter, total) ->
		string.format (if confirm
			if isImposter
				"%s был Предателем."
			else
				"%s не был Предателем."
		else
			"%s был вышвырнут."), nickname

	["meeting.timer.begins"]     = (time) -> string.format "Голосование через: %d с.", time
	["meeting.timer.ends"]       = (time) -> string.format "До конца голосования: %d с.", time
	["meeting.timer.proceeding"] = (time) -> string.format "Итоги через: %d с.", time
	["meeting.header"] = "Кто же Предатель?"

	["splash.victory"] = "Победа"
	["splash.defeat"]  = "Поражение"
	["splash.imposter"]  = "Предатель"
	["splash.spectator"] = "Наблюдатель"
	["splash.crewmate"]  = "Член экипажа"
	["splash.text"] = (isPlaying, imposterCount) ->
		amongSubtext = isPlaying and "нас" or "них"

		return string.format (switch remaining % 10
			when 1
				"%s Предатель среди #{amongSubtext}"
			when 2, 3, 4
				"%s Предателя среди #{amongSubtext}"
			else
				"%s Предателей среди #{amongSubtext}"
		), imposterCount

	["hud.sabotageAndKill"] = "Устраивай саботажи и убивай всех."
	["hud.countdown"] = "Начало через %d"
	["hud.tasks"] = "Задания:"
	["hud.fakeTasks"] = "Фальшивые задания:"
	["hud.taskComplete"] = "Задание выполнено!"
	["hud.cvar.disabled"] = "Отключено"
	["hud.cvar.enabled"] = "Включено"
	["hud.cvar.time"] = "%d сек."

	["hud.cvar.au_taskbar_updates.0"] = "Всегда"
	["hud.cvar.au_taskbar_updates.1"] = "Во время голосования"
	["hud.cvar.au_taskbar_updates.2"] = "Никогда"

	cvars = {
		au_max_imposters:    "Макс. Предателей"
		au_kill_cooldown:    "Перезарядка убийства"
		au_time_limit:       "Лимит времени"
		au_killdistance_mod: "Дистанция убийства"
		sv_alltalk:          "Разговор без ограничений"
		au_taskbar_updates:  "Обновления шкалы заданий"
		au_player_speed_mod: "Скорость передвижения"

		au_meeting_available: "Экстренных собраний"
		au_meeting_cooldown:  "Перезарядка собраний"
		au_meeting_vote_time: "Время на голосование"
		au_meeting_vote_pre_time:  "Время до голосования"
		au_meeting_vote_post_time: "Время после голосования"
		au_confirm_ejects:         "Роли выброшенных"
		au_meeting_anonymous:      "Анонимное голосование"

		au_tasks_short:  "Коротких задания"
		au_tasks_long:   "Длинных заданий"
		au_tasks_common: "Общих заданий"
		au_tasks_enable_visual: "Визуальные задания"
	}

	for name, value in pairs cvars
		["cvar.#{name}"] = value

	["vote.voted"] = "%s проголосовал(а). Осталось %s."

	["prepare.admin"] = "Ты Админ!"
	["prepare.spectator"] = "Ты Наблюдатель."
	["prepare.pressToStart"] = "Нажми [%s] чтобы начать игру."

	["prepare.invalidMap"] = "Неправильная карта!"
	["prepare.invalidMap.subText"] = "Карта не подходит для режима."

	["prepare.warmup"] = "Время подготовки!"
	["prepare.waitingForPlayers"] = "Ожидание других игроков..."
	["prepare.waitingForAdmin"] = "Ожидание начала матча Админом."
	["prepare.commencing"] = "Игра начнётся через %d с."
	["prepare.imposterCount"] = (count) ->
		string.format (if count == 1
			"%d Предатель"
		else
			"%d Предателей"), count

	["connected.spectating"] = "%s зашёл(ла) в игру наблюдателем."
	["connected.spawned"] = "%s готов(а) играть."
	["connected.disconnected"] = "%s покинул(а) игру!"

	["chat.noTalkingDuringGame"] = "Ты не можешь говорить во время игры!"

	inspectSample = {
		eta:           "%d СЕК."
		addingReagent: "РЕАГЕНТ ДОБАВЛЯЕТСЯ."
		oneMore:       "ЕЩЁ РАЗ."
		testComplete:  "ТЕСТИРОВАНИЕ ЗАВЕРШЕНО."
		pressToStart:  "НАЖМИТЕ ДЛЯ СТАРТА -->"
		selectAnomaly: "ВЫБЕРИТЕ АНОМАЛИЮ."
		hello:         "ПРИВЕТ."
		badResult:     "ПЛОХОЙ РЕЗУЛЬТАТ."
		thankYou:      "СПАСИБО!"
		randomText: table.Random {
			"ВАМ НЕ НУЖНО ЖДАТЬ."
			"ИДИТЕ ЗАЙМИТЕСЬ ДЕЛАМИ."
			"ОТДОХНИТЕ."
			"НАЛЕЙТЕ ЧАШКУ КОФЕ."
		}
	}

	for key, value in pairs inspectSample
		["tasks.inspectSample.#{key}"] = value

	controls = {
		"map": "Открыть карту или саботаж"
		"kill": "Убить"
		"use": "Использовать"
		"report": "Доложить о теле"
		"hideTasks": "Скрыть список заданий"
		"toggleNoClip": "Включить полёт призрака"
		"showHelp": "Текущее меню"
	}

	for key, value in pairs controls
		["help.controls.#{key}"] = value

	tabs = {
		"color": "Цвет"
		"settings": "Настройки"
		"game":  "Игра"
		"controls": "Управление"
		"about": "О режиме"
	}

	for key, value in pairs tabs
		["help.tab.#{key}"] = value

	settingsCvars = {
		"au_spectator_mode": "Режим наблюдателя"
		"au_debug_drawversion": "Отображать версию в правом углу"
		"au_vgui_lookaround": "Разрешить оглядывание по сторонам в тасках"
	}

	for key, value in pairs settingsCvars
		["help.settings.#{key}"] = value

	["sabotage.reactor.hold"] = "Удерживайте для остановки расплавления"
	["sabotage.reactor.waiting"] = "Ожидание второго пользователя"
	["sabotage.reactor.nominal"] = "Реактор в норме"
