resource.AddWorkshop "2227901495"

add = (cur) ->
	files, folders = file.Find(cur .. "/*", "GAME")
	if not files and not folders
		return

	for _, f in ipairs files or {}
		f = cur .. "/" .. f
		resource.AddSingleFile f

	for _, folder in ipairs folders or {}
		folder = (cur or "") .. "/" .. folder
		add folder

add "materials/au"
add "sound/au"
