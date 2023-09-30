class_name CategoryData extends Resource
# Weapon, Soulstones, Consumables (Food, Potions, etc), Quest, Equipment, Materials

@export var name: String = ""
@export var slots: Array[SlotData]

func add_item(item: ItemData):
	var new_slot = SlotData.new()
	new_slot.item = item
	new_slot.quantity = 1

	slots.append(new_slot)
	return self
