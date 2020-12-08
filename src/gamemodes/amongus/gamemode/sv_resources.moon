add = (cur) ->
	files, folders = file.Find(cur .. "/*", "GAME")
	return unless files or folders

	for f in *(files or {})
		f = cur .. "/" .. f
		resource.AddSingleFile f

	for folder in *(folders or {})
		folder = (cur or "") .. "/" .. folder
		add folder

add "materials/au"
add "sound/au"
