class_name Player
extends CharacterBody2D
## The survivor: WASD movement, stats, experience and owned upgrades.

signal hp_changed(hp: float, max_hp: float)
signal xp_changed(xp: float, xp_next: float, level: int)
signal leveled_up
signal loadout_changed
signal died

const BASE_SPEED := 90.0
const BASE_HP := 100.0
const BASE_MAGNET := 40.0
const HIT_INVULNERABILITY := 0.4

const WEAPON_SCRIPTS := {
	"wand": preload("res://scripts/weapons/wand.gd"),
	"knife": preload("res://scripts/weapons/knife.gd"),
	"aura": preload("res://scripts/weapons/aura.gd"),
}

# Stats derived from passive upgrades (see _recompute_stats).
var max_hp := BASE_HP
var hp := BASE_HP
var speed := BASE_SPEED
var regen := 0.0
var armor := 0.0
var magnet := BASE_MAGNET
var might := 1.0
var cooldown := 1.0
var area := 1.0
var amount := 0
var growth := 1.0

var level := 1
var xp := 0.0
var xp_next := DB.xp_for_level(1)
var facing := Vector2.RIGHT
var weapons := {}   # id -> Weapon
var passives := {}  # id -> level
var dead := false

var _invulnerable := 0.0

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var shadow: Sprite2D = $Shadow
@onready var body_shape: CollisionShape2D = $BodyShape
@onready var hurtbox: Area2D = $Hurtbox
@onready var hurt_shape: CollisionShape2D = $Hurtbox/Shape
@onready var magnet_area: Area2D = $Magnet
@onready var magnet_shape: CollisionShape2D = $Magnet/Shape
@onready var weapons_node: Node2D = $Weapons
@onready var hp_bar: UiBar = $HpBar
@onready var camera: Camera2D = $Camera


func _ready() -> void:
	sprite.sprite_frames = Assets.sprite_frames("player")
	sprite.play("idle")
	_fit_to_sprite()
	magnet_area.area_entered.connect(_on_magnet_area_entered)
	_recompute_stats()
	add_weapon("wand")
	_emit_all()


func _fit_to_sprite() -> void:
	# Origin sits at the feet so y-sorting works with any sprite size.
	var size := Assets.frame_size("player")
	sprite.position = Vector2(0, -size.y / 2.0)
	shadow.texture = Assets.texture("shadow")
	shadow.scale = Vector2.ONE * (size.x / 16.0)
	var circle := CircleShape2D.new()
	circle.radius = maxf(3.0, size.x * 0.22)
	body_shape.shape = circle
	body_shape.position = Vector2(0, -circle.radius)
	var hurt := CircleShape2D.new()
	hurt.radius = size.x * 0.3
	hurt_shape.shape = hurt
	hurt_shape.position = Vector2(0, -size.y * 0.4)
	weapons_node.position = Vector2(0, -size.y * 0.45)
	hp_bar.position = Vector2(-hp_bar.size.x / 2.0, 3)


func _physics_process(delta: float) -> void:
	if dead:
		return
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input * speed
	move_and_slide()
	if input != Vector2.ZERO:
		facing = input.normalized()
		if absf(input.x) > 0.1:
			sprite.flip_h = input.x < 0.0
		sprite.play("walk")
	else:
		sprite.play("idle")

	if regen > 0.0 and hp < max_hp:
		heal(regen * delta)

	_invulnerable -= delta
	if _invulnerable <= 0.0:
		var damage := 0.0
		for body in hurtbox.get_overlapping_bodies():
			if body is Enemy:
				damage = maxf(damage, body.damage)
		if damage > 0.0:
			take_damage(damage)


func take_damage(amount_in: float) -> void:
	if dead:
		return
	hp -= maxf(1.0, amount_in - armor)
	_invulnerable = HIT_INVULNERABILITY
	var tween := create_tween()
	sprite.modulate = Color(1.0, 0.25, 0.25)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.25)
	camera.shake(2.5)
	hp_changed.emit(hp, max_hp)
	_update_hp_bar()
	if hp <= 0.0:
		hp = 0.0
		dead = true
		sprite.play("idle")
		sprite.modulate = Color(1, 0.3, 0.3)
		died.emit()


func heal(value: float) -> void:
	hp = minf(max_hp, hp + value)
	hp_changed.emit(hp, max_hp)
	_update_hp_bar()


func add_xp(value: float) -> void:
	xp += value * growth
	while xp >= xp_next:
		xp -= xp_next
		level += 1
		xp_next = DB.xp_for_level(level)
		leveled_up.emit()
	xp_changed.emit(xp, xp_next, level)


# --- upgrades ---------------------------------------------------------------

func upgrade_level(id: String) -> int:
	if DB.is_weapon(id):
		return weapons[id].level if weapons.has(id) else 0
	return passives.get(id, 0)


func can_upgrade(id: String) -> bool:
	if DB.is_weapon(id):
		return upgrade_level(id) < DB.MAX_WEAPON_LEVEL
	return upgrade_level(id) < DB.PASSIVES[id]["max"]


func apply_upgrade(id: String) -> void:
	if id == "heal":
		heal(30.0)
	elif DB.is_weapon(id):
		if weapons.has(id):
			weapons[id].level_up()
		else:
			add_weapon(id)
	else:
		passives[id] = passives.get(id, 0) + 1
		_recompute_stats()
	loadout_changed.emit()


func add_weapon(id: String) -> void:
	var weapon: Weapon = WEAPON_SCRIPTS[id].new()
	weapon.id = id
	weapon.player = self
	weapon.name = id.capitalize()
	weapons[id] = weapon
	weapons_node.add_child(weapon)
	loadout_changed.emit()


func _recompute_stats() -> void:
	var old_max := max_hp
	might = 1.0 + 0.2 * passives.get("might", 0)
	speed = BASE_SPEED * (1.0 + 0.1 * passives.get("speed", 0))
	max_hp = BASE_HP + 20.0 * passives.get("vitality", 0)
	regen = 0.4 * passives.get("recovery", 0)
	armor = 1.0 * passives.get("armor", 0)
	magnet = BASE_MAGNET * (1.0 + 0.4 * passives.get("magnet", 0))
	cooldown = pow(0.92, passives.get("cooldown", 0))
	amount = passives.get("amount", 0)
	area = 1.0 + 0.15 * passives.get("area", 0)
	growth = 1.0 + 0.15 * passives.get("growth", 0)
	if max_hp > old_max:
		hp += max_hp - old_max
	(magnet_shape.shape as CircleShape2D).radius = magnet
	_emit_all()


func _emit_all() -> void:
	hp_changed.emit(hp, max_hp)
	xp_changed.emit(xp, xp_next, level)
	_update_hp_bar()


func _update_hp_bar() -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	hp_bar.visible = hp < max_hp


func _on_magnet_area_entered(area_node: Area2D) -> void:
	if area_node is Pickup:
		area_node.attract(self)
