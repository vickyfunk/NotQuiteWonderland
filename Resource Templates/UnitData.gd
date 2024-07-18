extends Resource

class_name UnitData

@export var max_health: float = 100.0
@export var health: float = 100.0

@export var max_armor_durability: float = 25.0
@export var armor_durability: float = 25.0
@export var armor_rating: float = 1.0

@export var max_luck: float = 0.0
@export var luck: float = 0.0

func ready():
	health = max_health
	armor_durability = max_armor_durability
	luck = max_luck

func take_damage(damage: float, impact: float, pen_rating: float):
	var net_pen = pen_rating - armor_rating
	var net_health_damage = 0.0
	var net_armor_damage = 0.0
	if net_pen < -1.5: #over 1.5 below
		net_health_damage += impact * .01
	elif net_pen < -1.0: #i.e 1.5 below
		net_health_damage += impact * .25
	elif net_pen < -0.5: #i.e. 1.0 below
		net_health_damage += impact * .50
	elif net_pen < 0.0: #i.e. 0.5 below
		net_health_damage += impact 
		net_armor_damage += damage * .25
	elif net_pen < 0.5: #i.e. matching
		net_health_damage += damage
		net_armor_damage += damage * .5
	else: #i.e. overpen
		net_health_damage += damage
		net_armor_damage += damage
		
	luck -= net_health_damage
	if luck < 0.0:
		health += luck
		luck = 0.0
	armor_durability -= net_armor_damage
	if armor_durability <= 0.0:
		armor_rating = 0.0
