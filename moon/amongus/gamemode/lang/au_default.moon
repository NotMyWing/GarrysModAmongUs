with GM.Lang\Get "en"
	["tasks.totalCompleted"] = "TOTAL TASKS COMPLETED"
	["tasks.totalCompleted.sabotaged"] = "COMMS SABOTAGED"

	["tasks.commsSabotaged"] = "Comms Sabotaged"
	["tasks.lightsSabotaged"] = "Fix Lights (%d%%)"
	["tasks.reactorSabotaged"] = "Reactor Meltdown in %d s. (%d/%d)"
	["tasks.oxygenSabotaged"] = "Oxygen Depleted in %d s. (%d/%d)"

	areas = {
		["cafeteria"]:      "Cafeteria"
		["upperEngine"]:   "Upper Engine"
		["reactor"]:        "Reactor"
		["lowerEngine"]:   "Lower Engine"
		["security"]:       "Security"
		["electrical"]:     "Electrical"
		["medbay"]:         "Medbay"
		["storage"]:        "Storage"
		["shields"]:        "Shields"
		["communications"]: "Communications"
		["navigation"]:     "Navigation"
		["o2"]:             "O2"
		["admin"]:          "Admin"
		["weapons"]:        "Weapons"
	}

	for area, areaName in pairs areas
		["area.#{area}"] = areaName
		["task.divertPower.area.#{area}"] = "Divert Power to #{areaName}"
		["vent.#{area}"] = "Vent to #{areaName}"

	taskNames = {
		"divertPower": "Divert Power"
		"alignEngineOutput": "Align Engine Output"
		"calibrateDistributor": "Calibrate Distributor"
		"chartCourse": "Chart Course"
		"cleanO2Filter": "Clean O2 Filter"
		"clearAsteroids": "Clear Asteroids"
		"emptyGarbage": "Empty Garbage"
		"emptyChute": "Empty Chute"
		"fixWiring": "Fix Wiring"
		"inspectSample": "Inspect Sample"
		"primeShields": "Prime Shields"
		"stabilizeSteering": "Stabilize Steering"
		"startReactor": "Start Reactor"
		"submitScan": "Submit Scan"
		"swipeCard": "Swipe Card"
		"unlockManifolds": "Unlock Manifolds"
		"uploadData": "Download Data"
		"uploadData.2": "Upload Data"
		"fuelEngines": "Fuel Engines"
	}

	for task, taskName in pairs taskNames
		["task.#{task}"] = taskName

	["meetingButton.cooldown"] = (time) -> {
		{
			text: "Crewmates Must Wait"
		}, {
			text: string.format "%ds", time
			color: Color 255, 0, 0
		}, {
			text: "Before The Emergency"
		}
	}

	["meetingButton.default"] = (nickname, uses) -> {
		{
			text: string.format "Crewmember %s Has", nickname
		}, {
			text: string.format "%d", uses
			color: Color 255, 0, 0
		}, {
			text: "Emergency Meetings Left"
		}
	}

	["meetingButton.crisis"] = -> {
		{
			text: "EMERGENCY MEETINGS CANNOT"
		}, {
			text: "BE CALLED DURING CRISES"
		}
	}

	["task.clearAsteroids.destroyed"] = "Destroyed: %d"

	["eject.remaining"] = (remaining) ->
		if remaining == 1
			string.format "1 Imposter remains."
		else
			string.format "%d Imposters remain.", remaining

	["eject.reason.tie"]     = "Nobody was ejected. (Tie)"
	["eject.reason.skipped"] = "Nobody was ejected. (Skipped)"
	["eject.reason.generic"] = "Nobody was ejected."

	["eject.text"] = (nickname, confirm, isImposter, total) ->
		string.format (if confirm
			if isImposter
				if total == 1
					"%s was The Imposter."
				else
					"%s was An Imposter."
			else
				if total == 1
					"%s was not The Imposter."
				else
					"%s was not An Imposter."
		else
			"%s was ejected."), nickname

	["meeting.timer.begins"]     = (time) -> string.format "Voting Begins In: %ds", time
	["meeting.timer.ends"]       = (time) -> string.format "Voting Ends In: %ds", time
	["meeting.timer.proceeding"] = (time) -> string.format "Proceeding In: %ds", time
	["meeting.header"] = "Who Is The Imposter?"

	["splash.victory"] = "Victory"
	["splash.defeat"]  = "Defeat"
	["splash.imposter"]  = "Imposter"
	["splash.spectator"] = "Spectator"
	["splash.crewmate"]  = "Crewmate"
	["splash.text"] = (isPlaying, imposterCount) ->
		amongSubtext = isPlaying and "us" or "them"

		return if imposterCount == 1
			"There is %s Imposter among " .. amongSubtext
		else
			"There are %s Imposters among " .. amongSubtext

	["hud.countdown"] = "Starting in %d"
	["hud.tasks"] = "Tasks:"
	["hud.fakeTasks"] = "Fake Tasks:"
	["hud.taskComplete"] = "Task Complete!"
	["hud.cvar.disabled"] = "Disabled"
	["hud.cvar.enabled"] = "Enabled"
	["hud.cvar.time"] = "%d s."

	cvars = {
		au_max_imposters:    "Max. Imposters"
		au_kill_cooldown:    "Kill Cooldown"
		au_time_limit:       "Time Limit"
		au_killdistance_mod: "Kill Distance"
		au_dead_chat:        "Dead Chat"

		au_meeting_available: "Meetings per Player"
		au_meeting_cooldown:  "Meeting Button Cooldown"
		au_meeting_vote_time: "Voting Time"
		au_meeting_vote_pre_time:  "Pre-Voting Time"
		au_meeting_vote_post_time: "Post-Voting Time"
		au_confirm_ejects:         "Confirm Ejects"

		au_tasks_short:  "Short Tasks"
		au_tasks_long:   "Long Tasks"
		au_tasks_common: "Common Tasks"
		au_tasks_enable_visual: "Visual Tasks"
	}

	for name, value in pairs cvars
		["cvar.#{name}"] = value

	["vote.voted"] = "%s has voted. %s remaining."

	["prepare.admin"] = "You're an Admin!"
	["prepare.pressToStart"] = "Press [%s] to start the game."

	["prepare.invalidMap"] = "Invalid Map!"
	["prepare.invalidMap.subText"] = "No map manifest file found."

	["prepare.warmup"] = "Warm-Up Time!"
	["prepare.waitingForPlayers"] = "Waiting for players..."
	["prepare.waitingForAdmin"] = "Waiting for an Admin to start the game."
	["prepare.commencing"] = "The game will start in %d s."
	["prepare.imposterCount"] = (count) ->
		string.format (if count == 1
			"%d Imposter"
		else
			"%d Imposters"), count

	["connected.spectating"] = "%s has joined as a spectator."
	["connected.spawned"] = "%s is ready to play."
	["connected.disconnected"] = "%s has left the game!"
