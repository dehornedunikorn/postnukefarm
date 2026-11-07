extends CharacterBody3D

@export var speed := 5.2
var gravity := 22.0
var character_visual: Node3D
var walk_phase := 0.0

func _ready() -> void:
    var world := get_parent()
    var avatar_scene: PackedScene = null
    if world != null and world.has_method("get_character_scene"):
        avatar_scene = world.call("get_character_scene") as PackedScene
    var avatar_valid := false
    if avatar_scene != null:
        var avatar := avatar_scene.instantiate() as Node3D
        if avatar != null:
            avatar.name = "QuaterniusFarmer"
            avatar_valid = true
            if world != null and world.has_method("sanitize_model"):
                avatar_valid = bool(world.call("sanitize_model", avatar))
            if avatar_valid:
                avatar.scale = Vector3.ONE * 0.9
                avatar.position.y = 0.0
                add_child(avatar)
                character_visual = avatar
            else:
                avatar.free()
    if not avatar_valid:
        _build_procedural_avatar()

    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.36
    shape.height = 1.85
    collision.shape = shape
    collision.position.y = 0.94
    add_child(collision)

    var camera_pivot := Node3D.new()
    camera_pivot.position = Vector3(0, 4.2, 7.5)
    add_child(camera_pivot)
    var camera := Camera3D.new()
    camera.position = Vector3(0, 1.8, 8.2)
    camera.rotation_degrees.x = -17
    camera.current = true
    camera_pivot.add_child(camera)

func _build_procedural_avatar() -> void:
    # Last-resort fallback if an imported Quaternius character has no valid mesh.
    _part(CapsuleMesh.new(), Vector3(0, 1.0, 0), Vector3(0.72, 1.0, 0.42), Color("#6b8060"))
    _part(SphereMesh.new(), Vector3(0, 1.92, 0), Vector3(0.48, 0.48, 0.46), Color("#e8bd91"))
    _part(CylinderMesh.new(), Vector3(0, 2.18, 0), Vector3(0.72, 0.12, 0.72), Color("#a66e3e"))
    _part(CylinderMesh.new(), Vector3(0, 2.28, 0), Vector3(0.42, 0.24, 0.42), Color("#b77c43"))
    _part(BoxMesh.new(), Vector3(-0.43, 1.0, -0.03), Vector3(0.42, 0.72, 0.35), Color("#8b5438"))
    _part(CapsuleMesh.new(), Vector3(-0.25, 0.42, 0), Vector3(0.26, 0.68, 0.28), Color("#584637"))
    _part(CapsuleMesh.new(), Vector3(0.25, 0.42, 0), Vector3(0.26, 0.68, 0.28), Color("#584637"))
    _part(CapsuleMesh.new(), Vector3(-0.49, 1.12, 0), Vector3(0.22, 0.68, 0.22), Color("#e8bd91"))
    _part(CapsuleMesh.new(), Vector3(0.49, 1.12, 0), Vector3(0.22, 0.68, 0.22), Color("#e8bd91"))

func _part(mesh: Mesh, pos: Vector3, dimensions: Vector3, color: Color) -> void:
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.position = pos
    node.scale = dimensions
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.92
    node.material_override = mat
    add_child(node)

func _physics_process(delta: float) -> void:
    var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var dir := Vector3(input.x, 0, input.y)
    if dir.length() > 1.0:
        dir = dir.normalized()
    velocity.x = dir.x * speed
    velocity.z = dir.z * speed
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0.0
    if dir.length() > 0.05:
        rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 9.0)
        walk_phase += delta * 10.5
    if character_visual != null:
        var target_bob := sin(walk_phase) * 0.045 if dir.length() > 0.05 else 0.0
        character_visual.position.y = lerpf(character_visual.position.y, target_bob, delta * 9.0)
    move_and_slide()
