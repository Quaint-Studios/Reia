class_name StackableItem extends Item

@export var quantity := 0

## Increases the quantity by the given amount (default is 1).
func increment(_quantity:= 1) -> StackableItem:
	quantity += _quantity
	return self

## Decreases the quantity by the given amount (default is 1).
func decrement(_quantity:= 1) -> StackableItem:
	quantity -= _quantity
	return self

func end() -> void:
	pass
