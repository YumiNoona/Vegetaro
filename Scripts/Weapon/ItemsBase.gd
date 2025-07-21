extends Resource
class_name ItemBase

enum ItemType{
	WEAPON,
	UPGRADE,
	PASSIVE
}


@export var item_name : String
@export var item_icon : Texture2D
@export var item_tier : Global.UpgradeTier
@export var item_type : ItemType
@export var item_cost : int

func get_description() -> String:
	return ""
