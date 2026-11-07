extends StaticBody3D

var state := 0 # 0 empty, 1 growing, 2 ready
var growth := 0.0
var last_visual_stage := -1
const GROWTH_SECONDS := 12.0
var crop_visual: Node3D
var label: Label3D

func _ready() -> void:
    # Rich tilled soil with a warm timber frame and clear walkable boundaries.
    var base := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(2.12, 0.22, 2.12)
    base.mesh = mesh
    base.position.y = 0.04
    base.material_override = _mat(Color("#79543a"))
    add_child(base)
    for x in [-1.04, 1.04]:
        _add_rail(Vector3(x, 0.19, 0), Vector3(0.12, 0.24, 2.24))
    for z in [-1.04, 1.04]:
        _add_rail(Vector3(0, 0.19, z), Vector3(2.24, 0.24, 0.12))
    for row in range(3):
        var ridge := MeshInstance3D.new()
        var ridge_mesh := BoxMesh.new()
        ridge_mesh.size = Vector3(1.68, 0.035, 0.08)
        ridge.mesh = ridge_mesh
        ridge.position = Vector3(0, 0.18, -0.58 + row * 0.58)
        ridge.material_override = _mat(Color("#9a704c"))
        add_child(ridge)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(2.12, 0.5, 2.12)
    collision.shape = shape
    collision.position.y = 0.1
    add_child(collision)
    label = Label3D.new()
    label.position.y = 1.35
    label.font_size = 30
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.text = "E  •  PLANT"
    label.modulate = Color("#fff0d3")
    add_child(label)

func _process(delta: float) -> void:
    if state != 1: return
    growth += delta
    var visual_stage := int(floor(growth / GROWTH_SECONDS * 4.0))
    if visual_stage != last_visual_stage:
        last_visual_stage = visual_stage
        _show_crop(clampf(growth / GROWTH_SECONDS, 0.0, 1.0))
    if growth >= GROWTH_SECONDS:
        state = 2
        label.text = "READY TO PICK!"
        _show_crop(1.0)
        var world = get_meta("world")
        world.update_hud()

func _mat(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 1.0
    return mat

func _add_rail(pos: Vector3, size: Vector3) -> void:
    var rail := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    rail.mesh = mesh
    rail.position = pos
    rail.material_override = _mat(Color("#a8794b"))
    add_child(rail)

func interact() -> void:
    var world = get_meta("world")
    if state == 0:
        if world.seed_count <= 0:
            label.text = "NO SEEDS"
            return
        world.seed_count -= 1
        state = 1
        growth = 0.0
        last_visual_stage = -1
        label.text = "GROWING... WATER TO HELP"
        _show_crop(0.35)
    elif state == 1:
        growth += 4.0
        if growth >= GROWTH_SECONDS:
            state = 2
            label.text = "READY TO PICK!"
            _show_crop(1.0)
        else:
            label.text = "WATERED · %d%%" % int(growth / GROWTH_SECONDS * 100.0)
            _show_crop(0.35 + growth / GROWTH_SECONDS * 0.65)
    else:
        world.harvest_count += 1
        world.seed_count += 1
        state = 0
        label.text = "E  •  PLANT"
        if crop_visual:
            crop_visual.queue_free()
            crop_visual = null
    world.update_hud()

func _show_crop(height_factor: float) -> void:
    if crop_visual:
        crop_visual.queue_free()
    crop_visual = Node3D.new()
    crop_visual.name = "QuaterniusCropVisual"
    add_child(crop_visual)

    var world = get_meta("world")
    var crop_scene: PackedScene = world.get_crop_scene(int(get_instance_id()), height_factor)
    if crop_scene != null:
        # Five individual plants create a readable row inside the timber bed.
        for i in range(5):
            var plant := crop_scene.instantiate() as Node3D
            if plant == null: continue
            if world.has_method("sanitize_model"):
                world.call("sanitize_model", plant)
            plant.position = Vector3(-0.66 + i * 0.33, 0.16, 0)
            plant.scale = Vector3.ONE * 0.42
            plant.rotation.y = float(i) * 0.73
            crop_visual.add_child(plant)
        return

    # Safe visual fallback for local editor runs before the optional crop pack is downloaded.
    var leaf_color := Color("#5c9a4b") if state == 1 else Color("#e6b94e")
    for i in range(5):
        var stem := MeshInstance3D.new()
        var mesh := CylinderMesh.new()
        mesh.top_radius = 0.035
        mesh.bottom_radius = 0.055
        mesh.height = 0.75 * maxf(height_factor, 0.15)
        stem.mesh = mesh
        stem.position = Vector3(-0.55 + i * 0.27, 0.28 + mesh.height * 0.5, 0)
        stem.material_override = _mat(Color("#47783d"))
        crop_visual.add_child(stem)
        for side in [-1, 1]:
            var leaf := MeshInstance3D.new()
            var leaf_mesh := SphereMesh.new()
            leaf_mesh.radius = 0.19 * maxf(height_factor, 0.15)
            leaf_mesh.height = 0.13 * maxf(height_factor, 0.15)
            leaf.mesh = leaf_mesh
            leaf.position = stem.position + Vector3(0.11 * side, 0.17 * height_factor, 0.08 * side)
            leaf.scale = Vector3(1.35, 0.5, 0.65)
            leaf.material_override = _mat(leaf_color)
            crop_visual.add_child(leaf)
        if state == 2:
            var fruit := MeshInstance3D.new()
            var fruit_mesh := SphereMesh.new()
            fruit_mesh.radius = 0.13
            fruit.mesh = fruit_mesh
            fruit.position = stem.position + Vector3(0, 0.42, 0.06)
            fruit.material_override = _mat(Color("#e9b84f"))
            crop_visual.add_child(fruit)
