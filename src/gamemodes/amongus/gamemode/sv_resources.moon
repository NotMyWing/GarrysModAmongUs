resource.AddWorkshop "2227901495"

add = (cur) ->
	files, folders = file.Find(cur .. "/*", "GAME")
	return unless files or folders

	for _, f in ipairs files or {}
		f = cur .. "/" .. f
		resource.AddSingleFile f

	for _, folder in ipairs folders or {}
		folder = (cur or "") .. "/" .. folder
		add folder

add "materials/au"
add "sound/au"
