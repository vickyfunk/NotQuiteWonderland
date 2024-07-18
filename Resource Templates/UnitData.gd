extends Resource

class_name UnitData

@export var max_health: float = 100.0
@export var health: float = 100.0

@export var armor_level: float = 1.0
@export var armor_durability: float = 25.0

@export var max_luck: float = 0.0
@export var luck: float = 0.0


func take_damage(Damage: float):
	health -= Damage
		
