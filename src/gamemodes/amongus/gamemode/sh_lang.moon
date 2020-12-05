--- Shared module using for localizing strings.
-- @module sh_lang

entryMeta = {
	__call: (...) => @.__entry ...
	__tostring: =>
		result = @.__entry and @__entry!
		return "Unknown" if result == nil

		str = tostring result
		return if "string" == type str
			str
		else
			type str

	__concat: (a, b) -> tostring(a) .. tostring(b)
}

NIL = { __entry: -> }
setmetatable NIL, entryMeta

GMOD_LANGUAGE = GetConVar "gmod_language"

GM.Lang or= {
	--- Returns the database specific to the language in question.
	-- This is used for defining i18n entries.
	--
	-- @param lang Language.
	Get: (lang) =>
		@__database[lang] or= {}
		return @__database[lang]

	--- Fetches a translation entry.
	-- An entry is a metatable wrapper around the actual entry in the database.
	--
	-- A returned entry is callable. However, you can also just pass it to `tostring`.
	-- This is useful for quick localizations if the entry doesn't expect any inputs.
	--
	-- If the internal entry is a string, this function creates a wrapper around it,
	-- automatically calling `string.format` so you don't have to.
	--
	-- If the input is nil or an empty string, the wrapped entry will return "Unknown".
	--
	-- The result of this function is lazily cached.
	--
	-- @param entry Database entry.
	-- @param lang Optional language. Defaults to `gmod_language` on the client realm, and to "en" on the server realm.
	GetEntry: (entry, lang) ->
		@ = GAMEMODE.Lang

		if lang == nil
			if SERVER
				lang = "en"
			else
				lang = GMOD_LANGUAGE\GetString!

		return NIL if entry == nil or entry == ""

		if @__entryCache[lang] and @__entryCache[lang][entry]
			return @__entryCache[lang][entry]

		entry = entry and ((@__database[lang] and @__database[lang][entry]) or
			(lang ~= "en" and @__database["en"] and @__database["en"][entry])) or entry

		result = switch type entry
			when "function"
				entry
			else
				(...) ->
					string.format tostring(entry), ...

		result = { __entry: result }
		setmetatable result, entryMeta

		@__entryCache[lang] or= {}
		@__entryCache[lang][entry] = result

		return result

	Initialize: (gamemode) =>
		@__database = {}
		@__entryCache = {}

		pathsToCheck = {
			{ "amongus/gamemode/lang", "LUA" }
			if gamemode.FolderName ~= "amongus"
				{ "#{gamemode.FolderName}/gamemode/lang", "LUA" }

			{ "amongus/lang", "LUA" }
		}

		for pathToCheck in *pathsToCheck
			-- This can, and most likely will be null because the second element
			-- is nullable. See `pathsToCheck = { ... }` above.
			continue unless pathToCheck

			filePath, location = unpack pathToCheck
			files = file.Find "#{filePath}/*.lua", location

			-- Sort files alphabetically.
			table.sort files

			gamemode.Logger.Info "Checking #{filePath} for language files..."

			-- Scan the provided directory for language files.
			-- Include everything.
			for fileName in *files
				path = "#{filePath}/#{fileName}"

				if "lua" == string.sub fileName, -3, -1
					if SERVER
						AddCSLuaFile path

					include path

					gamemode.Logger.Info "* Included #{path}"
}

GM.Lang\Initialize GM or GAMEMODE
