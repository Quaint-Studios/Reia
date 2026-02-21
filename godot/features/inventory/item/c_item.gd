class_name C_Item
extends Component

@export var unique_id: int = -1 # DB primary key
@export var name: String = ""
@export var description: String = ""

@export var category: Enums.ItemCategory = Enums.ItemCategory.MATERIAL
@export var grade: Enums.ItemGrade = Enums.ItemGrade.COMMON
