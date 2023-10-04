extends Node

const fs = preload("res://scripts/utils/fs.gd")
const changelog_prefab = preload("res://changelogs/changelog.tscn")
const h_divider_prefab = preload("res://changelogs/h_divider.tscn")

@onready var changelog_holder = $Margin/Panel/Margin/Scroll/List

func _ready() -> void:
	get_changelogs()

# Get all changelog files.
func get_changelogs():
	var path = "res://changelogs/"

	var files = fs.get_all_files(path, "json")

	files.reverse()

	for file in files:
		var content = fs.read_file(path + file)
		var json = JSON.new()
		var error = json.parse(content)
		if error == OK:
			var data = json.data
			if typeof(data) == TYPE_DICTIONARY:
				read_changelog(data)
			else:
				print("Unexpected data")
		else:
			print("JSON Parse Error: ", json.get_error_message(), " in ", content, " at line ", json.get_error_line())

# Read each individual changelog.
func read_changelog(data: Dictionary):
	var version: String = data.version
	var description: String = data.description
	var added: Array = data.changes.add
	var removed: Array = data.changes.remove
	var changed: Array = data.changes.change
	var fixed: Array = data.changes.fix
	var extra: String = data.extra

	var changelog = changelog_prefab.instantiate()

	var path = "MainMargin/List/DescMargin/TextMargin/List/"
	changelog.get_node(path + "Version").text = version
	changelog.get_node(path + "Description").text = description

	path = "MainMargin/List/ChangesMargin/TextMargin/List/"
	changelog.get_node(path + "Added").text = array_to_listtext(added)
	changelog.get_node(path + "Removed").text = array_to_listtext(removed)
	changelog.get_node(path + "Changed").text = array_to_listtext(changed)
	changelog.get_node(path + "Fixed").text = array_to_listtext(fixed)

	path = "MainMargin/List/ExtraMargin/TextMargin/"
	changelog.get_node(path + "Extra").text = extra
	if changelog_holder.get_child_count() > 0:
		changelog_holder.add_child(h_divider_prefab.instantiate())
	changelog_holder.add_child(changelog)

# Format the array from changes into new lines and bullets.
func array_to_listtext(arr: Array):
	var final_string = ""

	for item in arr:
		final_string += "• " + item + "\n"

	return final_string
