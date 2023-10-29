extends GutTest

var category;
var item1;
var item2;
var item3;
var item4;

func before_all():
	category = CategoryData.new()
	category.name = "TestCategory"

	item1 = ItemData.new()
	item1.name = "Item1"
	item2 = StackableItemData.new()
	item2.name = "Item2"
	item3 = StackableItemData.new()
	item3.name = "Item3"
	item4 = ItemData.new()
	item4.name = "Item4"
	category.add_item(item1).add_item(item2)
	category.add_item(item3).add_item(item4)

func test_assert_is():
	assert_is(category.get_item("Item1"), ItemData)
	assert_is(category.get_item("Item2"), StackableItemData)
	assert_is(category.get_item("Item3"), StackableItemData)
	assert_is(category.get_item("Item4"), ItemData)

func test_assert_null():
	assert_null(category.get_item("Item5"), null)
