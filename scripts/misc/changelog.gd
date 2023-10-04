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
	var version: String = data.version if data.has("version") else ""
	var stage: String = data.stage if data.has("stage") else ""
	var date: Dictionary = data.date if data.has("date") else null
	var description: String = data.description if data.has("description") else ""

	var has_changes = data.has("changes")
	var added: Array = data.changes.add if has_changes && "add" in data.changes else []
	var removed: Array = data.changes.remove if has_changes && "remove" in data.changes else []
	var changed: Array = data.changes.change if has_changes && "change" in data.changes else []
	var fixed: Array = data.changes.fix if has_changes && "fix" in data.changes else []

	var extra: String = data.extra if data.has("extra") else ""

	var changelog = changelog_prefab.instantiate()

	var path = "MainMargin/List/DescMargin/TextMargin/List/"
	changelog.get_node(path + "Version").text = version
	changelog.get_node(path + "Version/Stage").text = stage
	changelog.get_node(path + "Date").text = date_format(date) if date != null else ""
	changelog.get_node(path + "Description").text = description

	path = "MainMargin/List/ChangesMargin/TextMargin/List/"

	var set_section = func(arr: Array, section_name: String, hide: bool = false):
		changelog.get_node(path + section_name).text = array_to_listtext(arr)

		if hide:
			changelog.get_node(path + section_name).visible = false
			changelog.get_node(path + section_name + "Header").visible = false

	set_section.call(added, "Added", added.is_empty())
	set_section.call(removed, "Removed", removed.is_empty())
	set_section.call(changed, "Changed", changed.is_empty())
	set_section.call(fixed, "Fixed", fixed.is_empty())

	path = "MainMargin/List/ExtraMargin/TextMargin/"
	changelog.get_node(path + "Extra").text = extra
	if changelog_holder.get_child_count() > 0:
		changelog_holder.add_child(h_divider_prefab.instantiate())
	changelog_holder.add_child(changelog)

func date_format(date: Dictionary):
	const months := [
		"Jan_uary",
		"Feb_ruary",
		"Mar_ch",
		"Apr_il",
		"May",
		"Jun_e",
		"Jul_y",
		"Aug_ust",
		"Sep_tember",
		"Oct_ober",
		"Nov_ember",
		"Dec_ember"
	]

	# month day, year hour:min<am/pm>
	var month = months[int(date.month)-1].replace("_", "")
	var day = date.day
	var year = date.year

	var hour = date.hour
	var minute = date.minute

	var ampm = "pm" if hour >= 12 && hour <= 23 else "am"

	if ampm == "pm":
		hour -= 12

	if hour == 0:
		hour = 12

	return month + " " + day + ", " + year + " " + str(hour) + ":" + str(minute) + ampm

# Format the array from changes into new lines and bullets.
func array_to_listtext(arr: Array):
	var final_string = ""

	for item in arr:
		final_string += "• " + item + "\n"

	return final_string
