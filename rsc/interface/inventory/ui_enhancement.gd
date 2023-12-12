@tool class_name UI_Enhancement
###
###  ui_configure.gd
### 	This content type is opened by selecting any sort of enhancable or craftable item.
### 	Weapons and Equipment can be enhanced and given soulstones.
### 	Soulstones can be upgraded and can have their set effects evolve by mixing two soulstones
### 	 several times. This will cause the primary soulstone to have its name changed to the new
### 	 soulstone that is coming up with a prefix of "Unawakened"
### 	Consumables can be used to craft better consumables. Herbs and such can be eaten raw or
### 	 mixed together.
### 	Quest Items can be inspected to give clues to the quest.

# Loads basic information for all items.
func load_all_items(category: CategoryData):
	for item in category.items:
		pass

# Loads detailed information about a specific item.
func load_item(item: Item):
	pass
