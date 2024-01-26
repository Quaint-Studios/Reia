class_name StackableItem extends Item

@export var quantity := 0

func increment_item(_quantity:= 1):
	quantity += quantity
	return self

func decrement_item(_quantity:= -1):
	increment_item(_quantity) # Hehe lazy
	return self
