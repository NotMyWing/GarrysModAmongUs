with GM.Lang\Get "cn"
	["tasks.totalCompleted"] = "已完成的任务数"
	["tasks.totalCompleted.sabotaged"] = "通信系统遭到破坏"

	["tasks.commsSabotaged"] = "通信系统遭到破坏"
	["tasks.lightsSabotaged"] = "修理灯光 (%d%%)"
	["tasks.reactorSabotaged"] = "反应堆将在%d秒后熔毁。 (%d/%d)"
	["tasks.oxygenSabotaged"] = "氧气将在%d秒后耗尽。 (%d/%d)"

	areas = {
		["cafeteria"]:      "餐厅"
		["upperEngine"]:    "上层发动机"
		["reactor"]:        "反应堆"
		["lowerEngine"]:    "下层发动机"
		["security"]:       "安保室"
		["electrical"]:     "电力室"
		["medbay"]:         "医疗室"
		["storage"]:        "仓库"
		["shields"]:        "护盾控制室"
		["communications"]: "通讯室"
		["navigation"]:     "领航室"
		["o2"]:             "氧气室"
		["admin"]:          "管理室"
		["weapons"]:        "武器室"
	}

	for area, areaName in pairs areas
		["area.#{area}"] = areaName
		["task.divertPower.area.#{area}"] = "将功率转移到 #{areaName}"
		["vent.#{area}"] = "潜入到 #{areaName}"

	taskNames = {
		"divertPower":          "转移电力"
		"alignEngineOutput":    "校准发动机输出"
		"calibrateDistributor": "校准分配器"
		"chartCourse":          "绘制航线"
		"cleanO2Filter":        "清洁氧气过滤器"
		"clearAsteroids":       "清除小行星"
		"emptyGarbage":         "清空垃圾"
		"emptyChute":           "清空水槽"
		"fixWiring":            "修理线路"
		"inspectSample":        "检验样本"
		"primeShields":         "重启护盾"
		"stabilizeSteering":    "稳定舵机"
		"startReactor":         "启动反应堆"
		"submitScan":           "提交扫描"
		"swipeCard":            "刷卡"
		"unlockManifolds":      "解锁歧管"
		"uploadData":           "下载数据"
		"uploadData.2":         "上传数据"
		"fuelEngines":          "给发动机加油"
	}

	for task, taskName in pairs taskNames
		["task.#{task}"] = taskName

	["meetingButton.cooldown"] = (time) -> {
		{
			text: "船员们还需要等待"
		}, {
			text: string.format "%d秒", time
			color: Color 255, 0, 0
		}, {
			text: "才能开启 召开紧急会议"
		}
	}

	["meetingButton.default"] = (nickname, uses) -> {
		{
			text: string.format "船员%s还能再召开", nickname
		}, {
			text: string.format "%d次", uses
			color: Color 255, 0, 0
		}, {
			text: "紧急会议"
		}
	}

	["meetingButton.crisis"] = -> {
		{
			text: "紧急会议无法在"
		}, {
			text: "危险情况中召开"
		}
	}

	["task.clearAsteroids.destroyed"] = "已破坏: %d"

	["eject.remaining"] = (remaining) ->
		if remaining == 1
			string.format "还剩下一个内鬼"
		else
			string.format "还剩下%d个内鬼", remaining

	["eject.reason.tie"]     = "没有人被票出。 (平局)"
	["eject.reason.skipped"] = "没有人被票出。 (大多数人弃权)"
	["eject.reason.generic"] = "没有人被票出。"

	["eject.text"] = (nickname, confirm, isImposter, total) ->
		string.format (if confirm
			if isImposter
				"%s是内鬼"
			else
				"%s不是内鬼"
		else
			"%s被票出了。"), nickname

	["meeting.timer.begins"]     = (time) -> string.format "投票还有%d秒开始", time
	["meeting.timer.ends"]       = (time) -> string.format "投票还有%ds秒结束", time
	["meeting.timer.proceeding"] = (time) -> string.format "计票中：%ds", time
	["meeting.header"] = "谁是内鬼？"

	["splash.victory"] = "胜利"
	["splash.defeat"]  = "失败"
	["splash.imposter"]  = "内鬼"
	["splash.spectator"] = "旁观者"
	["splash.crewmate"]  = "船员"
	["splash.text"] = (isPlaying, imposterCount) ->	"有%s个内鬼在" ..
		(isPlaying and "我们之中" or "团队中")

	["hud.sabotageAndKill"] = "破坏设备并杀死所有人"
	["hud.countdown"] = "游戏将在%d秒后开始"
	["hud.tasks"] = "任务："
	["hud.fakeTasks"] = "假任务："
	["hud.taskComplete"] = "任务完成！"
	["hud.cvar.disabled"] = "禁用"
	["hud.cvar.enabled"] = "启用"
	["hud.cvar.time"] = "%d秒"

	["hud.cvar.au_taskbar_updates.0"] = "总是"
	["hud.cvar.au_taskbar_updates.1"] = "会议"
	["hud.cvar.au_taskbar_updates.2"] = "永不"

	cvars = {
		au_max_imposters:    "最大内鬼数"
		au_kill_cooldown:    "击杀冷却时间"
		au_time_limit:       "时间限制"
		au_killdistance_mod: "击杀距离"
		sv_alltalk:          "全体麦"
		au_taskbar_updates:  "任务栏更新"

		au_meeting_available: "每个玩家的会议"
		au_meeting_cooldown:  "会议按钮冷却时间"
		au_meeting_vote_time: "投票时间"
		au_meeting_vote_pre_time:  "投票前时间"
		au_meeting_vote_post_time: "计票时间"
		au_confirm_ejects:         "确认弹射 被票身份"
		au_meeting_anonymous: "匿名投票"

		au_tasks_short:  "短任务"
		au_tasks_long:   "长任务"
		au_tasks_common: "通用任务"
		au_tasks_enable_visual: "可视化任务"
	}

	for name, value in pairs cvars
		["cvar.#{name}"] = value

	["vote.voted"] = "%s已投票，还剩%s人"

	["prepare.admin"] = "你是管理员！"
	["prepare.spectator"] = "你是观众。"
	["prepare.pressToStart"] = "按下[%s]开始这局游戏！"

	["prepare.invalidMap"] = "无效的地图!"
	["prepare.invalidMap.subText"] = "未找到地图清单文件。"

	["prepare.warmup"] = "热身时间！"
	["prepare.waitingForPlayers"] = "等待玩家中。。。"
	["prepare.waitingForAdmin"] = "等待管理员开始游戏。"
	["prepare.commencing"] = "本局游戏将在%d秒后开始。"
	["prepare.imposterCount"] = (count) -> string.format "%d个内鬼", count

	["connected.spectating"] = "%s已通过旁观者的身份加入。"
	["connected.spawned"] = "%s准备就绪。"
	["connected.disconnected"] = "%s离开了房间。"

	["chat.noTalkingDuringGame"] = "你不能在游戏中说话！"

	inspectSample = {
		eta:           "ETA %d."
		addingReagent: "添加试剂。"
		oneMore:       "再来一次。"
		testComplete:  "测试完成。"
		pressToStart:  "按下开始  -->"
		selectAnomaly: "选择异常试剂。"
		hello:         "欢迎使用_(:з」∠)_"
		badResult:     "输出值错误。"
		thankYou:      "感谢使用！"
		randomText: () -> table.Random {
			"你不需要等待。"
			"去做别的事情吧。"
			"休息一下。"
			"老大哥在看着你。"
			"去喝杯咖啡吧。"
		}
	}

	for key, value in pairs inspectSample
		["tasks.inspectSample.#{key}"] = value

	controls = {
		"map": "打开地图 / 破坏"
		"kill": "杀人"
		"use": "使用"
		"report": "报告尸体"
		"hideTasks": "隐藏任务列表"
		"toggleNoClip": "启用幽灵飞行"
		"showHelp": "打开菜单"
	}

	for key, value in pairs controls
		["help.controls.#{key}"] = value

	tabs = {
		"color": "颜色"
		"settings": "设置"
		"game":  "游戏"
		"controls": "控制项"
		"about": "关于"
	}

	for key, value in pairs tabs
		["help.tab.#{key}"] = value

	settingsCvars = {
		"au_spectator_mode": "观众模式"
		"au_debug_drawversion": "显示当前版本"
	}

	for key, value in pairs settingsCvars
		["help.settings.#{key}"] = value
