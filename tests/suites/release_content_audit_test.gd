extends RefCounted

const ARCHIVED_ASSETS := [
	"assets/backgrounds/flooded_wilderness_atlas_source.png",
	"assets/backgrounds/highway_atlas_source.png",
	"assets/sprites/architect_calder_edit_source.png",
	"assets/sprites/architect_calder_source.png",
	"assets/sprites/cinder_matriarch_source.png",
	"assets/sprites/desert_interceptor_source.png",
	"assets/sprites/dinosaur_ecosystem_source.png",
	"assets/sprites/enemy_roster_source.png",
	"assets/sprites/enemy_sheet.png",
	"assets/sprites/forge_regent_source.png",
	"assets/sprites/iron_vulture_source.png",
	"assets/sprites/jungle_mine_cart_edit_source.png",
	"assets/sprites/jungle_mine_cart_source.png",
	"assets/sprites/mirewarden_source.png",
	"assets/sprites/ranger_sheet.png",
	"assets/sprites/raptor_sheet.png",
	"assets/sprites/titan_warden_edit_source.png",
	"assets/sprites/titan_warden_source.png",
	"assets/sprites/vault_sentinels_source.png",
]
const PROTECTED_RUNTIME_TOKENS := [
	"cadillacs and dinosaurs",
	"mustapha cairo",
	"jack tenrec",
	"hannah dundee",
	"mess o'bradovich",
	"capcom",
]
const FORBIDDEN_ARCHIVE_EXTENSIONS := [".zip", ".7z", ".rar", ".rom", ".chd", ".iso", ".nes", ".sfc", ".gba"]


func run(test) -> void:
	var license_text := FileAccess.get_file_as_string("res://LICENSE")
	var notices := FileAccess.get_file_as_string("res://THIRD_PARTY_NOTICES.md")
	var provenance := FileAccess.get_file_as_string("res://ASSET_PROVENANCE.md")
	var exports := FileAccess.get_file_as_string("res://export_presets.cfg")
	var release_notes := FileAccess.get_file_as_string("res://RELEASE_NOTES_v1.0.0.md")
	var issues := FileAccess.get_file_as_string("res://KNOWN_ISSUES.md")

	test.check(license_text.contains("MIT License") and license_text.contains("Creative Commons Attribution 4.0"), "project code/asset license grant is incomplete")
	test.check(notices.contains("Godot Engine") and notices.contains("Copyright (c) 2014-present Godot Engine contributors"), "Godot binary redistribution notice is incomplete")
	test.check(notices.contains("Noto Sans SC") and FileAccess.file_exists("res://assets/fonts/OFL.txt"), "font notice or complete OFL text is missing")
	test.check(release_notes.contains("Wildland Strike v1.0.0") and release_notes.contains("Release qualification"), "v1.0.0 release notes are incomplete")
	test.check(issues.contains("Critical | 0") and issues.contains("High | 0") and issues.contains("Medium | 0"), "release defect gate does not explicitly clear critical/high/medium defects")

	var png_assets := _collect_files("res://assets", [".png"])
	test.check(png_assets.size() >= 60, "asset inventory unexpectedly lost production PNGs")
	for path in png_assets:
		test.check(provenance.contains(path.get_file()), "asset provenance is missing %s" % path)

	test.check(ARCHIVED_ASSETS.size() == 19, "archived source inventory count drifted")
	for path in ARCHIVED_ASSETS:
		test.check(FileAccess.file_exists("res://" + path), "archived source disappeared without an inventory update: %s" % path)
		test.check(exports.count(path) == 2, "archived source is not excluded from both Web and iOS: %s" % path)

	var runtime_text := ""
	for root in ["res://core", "res://data", "res://scripts"]:
		for path in _collect_files(root, [".gd", ".tres"]):
			runtime_text += FileAccess.get_file_as_string(path).to_lower()
	for path in ["res://main.tscn", "res://project.godot"]:
		runtime_text += FileAccess.get_file_as_string(path).to_lower()
	for token in PROTECTED_RUNTIME_TOKENS:
		test.check(not runtime_text.contains(token), "protected franchise token entered runtime content: %s" % token)

	for path in _collect_files("res://assets", []):
		for extension in FORBIDDEN_ARCHIVE_EXTENSIONS:
			test.check(not path.to_lower().ends_with(extension), "forbidden archive/ROM asset entered the repository: %s" % path)

	var audio_files := _collect_files("res://assets", [".wav", ".mp3", ".ogg", ".flac", ".m4a"])
	test.check(audio_files.is_empty(), "unexpected external audio bypassed the procedural-audio provenance contract")
	test.check(provenance.contains("every tracked PNG is named") and provenance.contains("no third-party audio file"), "final provenance closure statement is missing")


func _collect_files(root: String, extensions: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for filename in DirAccess.get_files_at(root):
		var path := root.path_join(filename)
		if extensions.is_empty() or extensions.has("." + filename.get_extension().to_lower()):
			result.append(path)
	for directory in DirAccess.get_directories_at(root):
		result.append_array(_collect_files(root.path_join(directory), extensions))
	result.sort()
	return result
