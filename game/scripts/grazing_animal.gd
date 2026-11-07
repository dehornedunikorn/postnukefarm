extends Node3D

@export var wander_radius := 0.8
@export var movement_rate := 0.00018

var home_position := Vector3.ZERO
var phase := 0.0
var facing := 0.0

func _ready() -> void:
    home_position = position
    phase = randf_range(0.0, TAU)
    facing = rotation.y

func _process(delta: float) -> void:
    var t := float(Time.get_ticks_msec()) * movement_rate + phase
    var next_position := home_position
    next_position.x += sin(t) * wander_radius
    next_position.z += sin(t * 0.73) * wander_radius * 0.65
    position = position.lerp(next_position, delta * 1.2)

    var direction := Vector3(cos(t), 0.0, cos(t * 0.73) * 0.7)
    if direction.length_squared() > 0.01:
        facing = lerp_angle(facing, atan2(direction.x, direction.z), delta * 1.8)
        rotation.y = facing
