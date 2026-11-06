extends StaticBody3D

var state := 0 # 0 empty, 1 growing, 2 ready
var growth := 0.0
var crop_visual: Node3D
var label: Label3D

func _ready() -> void:
    var base := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(2.05, 0.18, 2.05)
    base.mesh = mesh
    base.position.y = 0.02
    var soil := StandardMaterial3D.new()
    soil.albedo_color = Color(0.31, 0.19, 0.12)
    base.material_override = soil
    add_child(base)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(2.05, 0.5, 2.05)
    collision.shape = shape
    collision.position.y = 0.1
    add_child(collision)
    label = Label3D.new()
    label.position.y = 1.3
    label.font_size = 32
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.text = "E  •  Plant"
    add_child(label)

func interact() -> void:
    var world = get_meta("world")
    if state == 0:
        if world.seed_count <= 0:
            label.text = "No seeds!"
            return
        world.seed_count -= 1
        state = 1
        growth = 0.0
        label.text = "Growing..."
        _show_crop(0.45)
    elif state == 1:
        growth = 1.0
        state = 2
        label.text = "Ready!"
        _show_crop(1.0)
    else:
        world.harvest_count += 1
        world.seed_count += 1
        state = 0
        label.text = "E  •  Plant"
        if crop_visual:
            crop_visual.queue_free()
            crop_visual = null
    world.update_hud()

func _show_crop(height_factor: float) -> void:
    if crop_visual:
        crop_visual.queue_free()
    crop_visual = Node3D.new()
    add_child(crop_visual)
    for i in range(3):
        var stem := MeshInstance3D.new()
        var mesh := CylinderMesh.new()
        mesh.top_radius = 0.035
        mesh.bottom_radius = 0.07
        mesh.height = 0.65 * height_factor
        stem.mesh = mesh
        stem.position = Vector3(-0.35 + i * 0.35, 0.18 + mesh.height * 0.5, 0)
        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color(0.28, 0.55, 0.22) if state == 1 else Color(0.77, 0.68, 0.29)
        stem.material_override = mat
        crop_visual.add_child(stem)
        var leaf := MeshInstance3D.new()
        var leaf_mesh := SphereMesh.new()
        leaf_mesh.radius = 0.18 * height_factor
        leaf.mesh = leaf_mesh
        leaf.position = stem.position + Vector3(0, 0.28 * height_factor, 0.1)
        leaf.material_override = mat
        crop_visual.add_child(leaf)
