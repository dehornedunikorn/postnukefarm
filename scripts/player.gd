extends CharacterBody3D

@export var speed := 5.2
var gravity := 22.0
var camera_pivot: Node3D

func _ready() -> void:
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.42
    capsule.height = 1.7
    var body := MeshInstance3D.new()
    body.mesh = capsule
    body.position.y = 0.85
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.78, 0.63, 0.40)
    body.material_override = material
    add_child(body)

    var head := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.34
    head.mesh = sphere
    head.position.y = 1.82
    var skin := StandardMaterial3D.new()
    skin.albedo_color = Color(0.91, 0.72, 0.53)
    head.material_override = skin
    add_child(head)

    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.42
    shape.height = 1.7
    collision.shape = shape
    collision.position.y = 0.85
    add_child(collision)

    camera_pivot = Node3D.new()
    camera_pivot.position = Vector3(0, 4.2, 7.5)
    add_child(camera_pivot)
    var camera := Camera3D.new()
    camera.position = Vector3(0, 1.8, 8.2)
    camera.rotation_degrees.x = -17
    camera.current = true
    camera_pivot.add_child(camera)

func _physics_process(delta: float) -> void:
    var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var dir := Vector3(input.x, 0, input.y)
    if dir.length() > 1: dir = dir.normalized()
    velocity.x = dir.x * speed
    velocity.z = dir.z * speed
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0
    move_and_slide()
