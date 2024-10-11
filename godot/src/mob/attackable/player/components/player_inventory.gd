class_name PlayerInventory extends Inventory

func _init(fake_data := false) -> void:
	if fake_data:
		create_inventory()

func create_inventory() -> void:
	var keys: Array[String] = Tab.keys()
	(self
		.add_category(keys[Tab.WEAPONS])
		.add_category(keys[Tab.SOULSTONES])
		.add_category(keys[Tab.CONSUMABLES])
		.add_category(keys[Tab.EQUIPMENT])
		.add_category(keys[Tab.MATERIALS])
		.add_category(keys[Tab.QUEST_ITEMS])
		.end())

	populate_test_data()

func populate_test_data() -> void:
	var keys := Tab.keys()

	var weapons_tab: String = keys[Tab.WEAPONS]

	(self.add_item(weapons_tab, load(WeaponIndex.WOODEN_SWORD) as Weapon)
	.add_item(weapons_tab, load(WeaponIndex.WOODEN_SWORD) as Weapon)
	.add_item(weapons_tab, load(WeaponIndex.WOODEN_SWORD) as Weapon)
	.add_item(weapons_tab, load(WeaponIndex.WOODEN_SWORD) as Weapon)
	.add_item(weapons_tab, load(WeaponIndex.WOODEN_SWORD) as Weapon)

	.add_item(weapons_tab, load(WeaponIndex.SAPPHIRITE_WHIP) as Weapon)
	.add_item(weapons_tab, load(WeaponIndex.SAPPHIRITE_WHIP) as Weapon)
	.add_item(weapons_tab, load(WeaponIndex.SAPPHIRITE_WHIP) as Weapon)
	.add_item(weapons_tab, load(WeaponIndex.SAPPHIRITE_WHIP) as Weapon)

	.add_item(weapons_tab, load(WeaponIndex.PYROMANCERS_WAND) as Weapon)
	.add_item(weapons_tab, load(WeaponIndex.PYROMANCERS_WAND) as Weapon)
	.add_item(weapons_tab, load(WeaponIndex.PYROMANCERS_WAND) as Weapon)

	.add_item(weapons_tab, load(WeaponIndex.ROBINS_BOW) as Weapon)
	.add_item(weapons_tab, load(WeaponIndex.ROBINS_BOW) as Weapon)

	.add_item(weapons_tab, load(WeaponIndex.ETHEREAL_BOW) as Weapon)
	.add_item(weapons_tab, load(WeaponIndex.ETHEREAL_BOW) as Weapon)

	.add_item(weapons_tab, load(WeaponIndex.STARLIT_SWORD) as Weapon)
	
	.end())

func save_data() -> void:
	# MongoDB and ResourceSaver + JSON
	pass

func load_data() -> void:
	pass
