class_name GameManager__Character extends Resource

@export var id: int
@export var name: String = ""
@export_multiline var description: String = ""
@export var picture: AtlasTexture
@export var type: CharacterType

enum CharacterType {NPC, ENEMY, BOSS, PLAYER, UNKNOWN}
