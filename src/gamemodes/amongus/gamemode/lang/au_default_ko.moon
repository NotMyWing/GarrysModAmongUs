-- Koren translation by Ice_Dolphin_Sign

with GM.Lang\Get "en"
	["tasks.totalCompleted"] = "TOTAL TASKS COMPLETED"
	["tasks.totalCompleted.sabotaged"] = "통신 기기 파손으로 고치기"

	["tasks.commsSabotaged"] = "통신 기기 파손"
	["tasks.lightsSabotaged"] = "전등 고치기 (%d%%)"
	["tasks.reactorSabotaged"] = "원자로 용해까지 %d (%d/%d)"
	["tasks.oxygenSabotaged"] = "산소 고갈까지 %d (%d/%d)"

	areas = {
		["cafeteria"]:      "식당"
		["upperEngine"]:    "상부 엔진"
		["reactor"]:        "원자로"
		["lowerEngine"]:    "하부 엔진"
		["security"]:       "보안실"
		["electrical"]:     "전기실"
		["medbay"]:         "의무실"
		["storage"]:        "창고"
		["shields"]:        "보호막 제어실"
		["communications"]: "통신실"
		["navigation"]:     "항해실"
		["o2"]:             "산소 공급실"
		["admin"]:          "관리실 지도"
		["weapons"]:        "무기고"
	}

	for area, areaName in pairs areas
		["area.#{area}"] = areaName
		["task.divertPower.area.#{area}"] = "#{areaName} 으로 에너지 전환하기"
		["vent.#{area}"] = "Vent to #{areaName}"

	taskNames = {
		"divertPower": "에너지 전환하기"
		"alignEngineOutput": "엔진 출력 정렬 시키기"
		"calibrateDistributor": "배전기 조정하기"
		"chartCourse": "항로 계획하기"
		"cleanO2Filter": "산소 필터 청소하기"
		"clearAsteroids": "소행성 파괴하기"
		"emptyGarbage": "쓰레기 비우기"
		"emptyChute": "쓰레기 비우기"
		"fixWiring": "배선 수리하기"
		"inspectSample": "샘플 분석하기"
		"primeShields": "실드 준비하기"
		"stabilizeSteering": "항로 조정하기"
		"startReactor": "원자로 가동하기"
		"submitScan": "스캔 제출하기"
		"swipeCard": "카드 긋기"
		"unlockManifolds": "매니폴드 열기"
		"uploadData": "데이터 다운로드 하기"
		"uploadData.2": "데이터 업로드하기"
		"fuelEngines": "엔진 연료 공급하기"
	}

	for task, taskName in pairs taskNames
		["task.#{task}"] = taskName

	["meetingButton.cooldown"] = (time) -> {
		{
			text: "크루원은 긴급 회의 소집까지"
		}, {
			text: string.format "%ds", time
			color: Color 255, 0, 0
		}, {
			text: "동안 기다려야합니다"
		}
	}

	["meetingButton.default"] = (nickname, uses) -> {
		{
			text: string.format "크루원 %s 은(는)", nickname
		}, {
			text: string.format "%d", uses
			color: Color 255, 0, 0
		}, {
			text: "번의 긴급 회의 소집 기회가 남아있습니다"
		}
	}

	["meetingButton.crisis"] = -> {
		{
			text: "긴급 회의는 위급 상황시"
		}, {
			text: "소집될 수 없습니다"
		}
	}

	["task.clearAsteroids.destroyed"] = "Destroyed: %d"

	["eject.remaining"] = (remaining) ->
		if remaining == 1
			string.format "임포스터가 한명 남았습니다."
		else
			string.format "임포스터가 %d명 남았습니다.", remaining

	["eject.reason.tie"]     = "아무도 퇴출되지 않았습니다 (투표수 동점)"
	["eject.reason.skipped"] = "아무도 퇴출되지 않았습니다 (투표 건너 뜀)"
	["eject.reason.generic"] = "아무도 퇴출되지 않았습니다"

	["eject.text"] = (nickname, confirm, isImposter, total) ->
		string.format (if confirm
			if isImposter
				"%s 는 임포스터였습니다."
			else
				"%s 는 임포스터가 아니었습니다."
		else
			"%s 는 배출되었습니다."), nickname

	["meeting.timer.begins"]     = (time) -> string.format "투표 시작까지: %ds", time
	["meeting.timer.ends"]       = (time) -> string.format "투표 종료까지: %ds", time
	["meeting.timer.proceeding"] = (time) -> string.format "확인까지: %ds", time
	["meeting.header"] = "임포스터는 누구인가?"

	["splash.victory"] = "승리"
	["splash.defeat"]  = "패배"
	["splash.imposter"]  = "임포스터"
	["splash.spectator"] = "관전자"
	["splash.crewmate"]  = "크루원"
	["splash.text"] = (isPlaying, imposterCount) ->
		return if imposterCount == 1
			"임포스터가 한명 남았습니다."
		else
			"임포스터가 %s명 남았습니다."

	["hud.sabotageAndKill"] = "방해 공작을 펼치면서 모두를 처치하세요."
	["hud.countdown"] = "%d 초 후에 게임이 시작됩니다."
	["hud.tasks"] = "임무:"
	["hud.fakeTasks"] = "가짜 임무:"
	["hud.taskComplete"] = "임무 완료!"
	["hud.cvar.disabled"] = "비활성화"
	["hud.cvar.enabled"] = "활성화"
	["hud.cvar.time"] = "%d"

	["hud.cvar.au_taskbar_updates.0"] = "Always"
	["hud.cvar.au_taskbar_updates.1"] = "Meetings"
	["hud.cvar.au_taskbar_updates.2"] = "Never"

	cvars = {
		au_max_imposters:    "임포스터"
		au_kill_cooldown:    "킬 쿨타임"
		au_time_limit:       "시간 제한"
		au_killdistance_mod: "킬 범위"
		sv_alltalk:          "채팅"
		au_taskbar_updates:  "Task Bar Updates"
		au_player_speed_mod: "이동 속도"

		au_meeting_available: "긴급 회의"
		au_meeting_cooldown:  "긴급 회의 쿨타임"
		au_meeting_vote_time: "투표 제한 시간"
		au_meeting_vote_pre_time:  "사전 투표 제한 시간"
		au_meeting_vote_post_time: "사후 투표 제한 시간"
		au_confirm_ejects:         "Confirm Ejects"
		au_meeting_anonymous: "Anonymous Votes"

		au_tasks_short:  "간단한 임무"
		au_tasks_long:   "복잡한 임무"
		au_tasks_common: "공통 임무"
		au_tasks_enable_visual: "Visual Tasks"
	}

	for name, value in pairs cvars
		["cvar.#{name}"] = value

	["vote.voted"] = "%s 이(가) 투표했습니다.%s 명 남음."

	["prepare.admin"] = "당신은 관리자입니다!"
	["prepare.spectator"] = "당신은 관전자입니다."
	["prepare.pressToStart"] = "[%s]를 눌러 게임을 시작하세요."

	["prepare.invalidMap"] = "잘못된 맵!"
	["prepare.invalidMap.subText"] = "맵 매니페스트 파일을 찾을 수 없습니다."

	["prepare.warmup"] = "워밍업 타임!"
	["prepare.waitingForPlayers"] = "플레이어 기다리는중..."
	["prepare.waitingForAdmin"] = "관리자가 게임을 시작할 때까지 기다리세요."
	["prepare.commencing"] = "%d초 후 게임이 시작됩니다."
	["prepare.imposterCount"] = (count) ->
		string.format (if count == 1
			"한명 임포스터가"
		else
			"%d명 임포스터들"), count

	["connected.spectating"] = "%s님이 관전자에 참가했습니다."
	["connected.spawned"] = "%s님은 플레이할 준비가 되었습니다."
	["connected.disconnected"] = "%s님이 게임에서 나갔습니다!"

	["chat.noTalkingDuringGame"] = "게임 중에는 대화할 수 없습니다!"

	inspectSample = {
		eta:           "ETA %d."
		addingReagent: "시약 추가"
		oneMore:       "한번 더"
		testComplete:  "시험 완료!"
		pressToStart:  "START를 누르세요!  -->"
		selectAnomaly: "이상시약 선택"
		hello:         "안녕"
		badResult:     "나쁜 결과"
		thankYou:      "고마워요!"
		randomText: table.Random {
			"기다릴 필요 없습니다."
			"가서 다른 일을 하세요."
			"휴식을 취하세요."
			"커피를 잡으세요."
		}
	}

	for key, value in pairs inspectSample
		["tasks.inspectSample.#{key}"] = value

	controls = {
		"map": "맵 열기 / 사보타지"
		"kill": "죽이기"
		"use": "사용하기"
		"report": "신고하기"
		"hideTasks": "일과 숨기기"
		"toggleNoClip": "노클립 활성화"
		"showHelp": "메뉴"
	}

	for key, value in pairs controls
		["help.controls.#{key}"] = value

	tabs = {
		"color": "색"
		"settings": "설정"
		"game":  "게임"
		"controls": "컨트롤"
		"about": "게임에 대해"
	}

	for key, value in pairs tabs
		["help.tab.#{key}"] = value

	settingsCvars = {
		"au_spectator_mode": "관전자 모드"
		"au_debug_drawversion": "현재 버전 표시"
	}

	for key, value in pairs settingsCvars
		["help.settings.#{key}"] = value
