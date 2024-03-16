class_name PlayerInventory extends Inventory

func _init(fake_data := false):
	if fake_data:
		create_inventory()

func create_inventory():
	var keys = Tab.keys()
	(self
		.add_category(keys[Tab.WEAPONS])
		.add_category(keys[Tab.SOULSTONES])
		.add_category(keys[Tab.CONSUMABLES])
		.add_category(keys[Tab.EQUIPMENT])
		.add_category(keys[Tab.MATERIALS])
		.add_category(keys[Tab.QUEST_ITEMS]))

	populate_test_data()

func populate_test_data():
	var keys := Tab.keys()

	var weapons_tab := keys[Tab.WEAPONS] as String

	(self.add_item(weapons_tab, load(WeaponIndex.WOODEN_SWORD))
	.add_item(weapons_tab, load(WeaponIndex.WOODEN_SWORD))
	.add_item(weapons_tab, load(WeaponIndex.WOODEN_SWORD))
	.add_item(weapons_tab, load(WeaponIndex.WOODEN_SWORD))
	.add_item(weapons_tab, load(WeaponIndex.WOODEN_SWORD))

	.add_item(weapons_tab, load(WeaponIndex.SAPPHIRITE_WHIP))
	.add_item(weapons_tab, load(WeaponIndex.SAPPHIRITE_WHIP))
	.add_item(weapons_tab, load(WeaponIndex.SAPPHIRITE_WHIP))
	.add_item(weapons_tab, load(WeaponIndex.SAPPHIRITE_WHIP))

	.add_item(weapons_tab, load(WeaponIndex.PYROMANCERS_WAND))
	.add_item(weapons_tab, load(WeaponIndex.PYROMANCERS_WAND))
	.add_item(weapons_tab, load(WeaponIndex.PYROMANCERS_WAND))

	.add_item(weapons_tab, load(WeaponIndex.ROBINS_BOW))
	.add_item(weapons_tab, load(WeaponIndex.ROBINS_BOW))

	.add_item(weapons_tab, load(WeaponIndex.ETHEREAL_BOW))
	.add_item(weapons_tab, load(WeaponIndex.ETHEREAL_BOW))

	.add_item(weapons_tab, load(WeaponIndex.STARLIT_SWORD)))

func save_data():
	# MongoDB and ResourceSaver + JSON
	pass

func load_data():
	pass
