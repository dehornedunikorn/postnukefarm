extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const PLOT_SCRIPT = preload("res://scripts/farm_plot.gd")

var player: CharacterBody3D
var status_label: Label
var seed_count := 8
var harvest_count := 0
var day := 1
var plots: Array[Node3D] = []

func _ready() -> void:
    _build_environment()
    _build_farm()
    _build_player()
    _build_ui()

func _mat(color: Color, roughness := 1.0) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = roughness
    return m

func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = size
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.position = pos
    node.material_override = _mat(color)
    parent.add_child(node)
    return node

func _build_environment() -> void:
    var ground := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(100, 100)
    ground.mesh = plane
    ground.material_override = _mat(Color(0.25, 0.39, 0.24))
    ground.position.y = -0.12
    add_child(ground)

    # A real collision floor prevents the player falling through the visual terrain.
    var ground_body := StaticBody3D.new()
    ground_body.position.y = -0.55
    var ground_collision := CollisionShape3D.new()
    var ground_shape := BoxShape3D.new()
    ground_shape.size = Vector3(100, 1, 100)
    ground_collision.shape = ground_shape
    ground_body.add_child(ground_collision)
    add_child(ground_body)

    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_SKY
    e.sky = Sky.new()
    e.sky.sky_material = ProceduralSkyMaterial.new()
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color(0.72, 0.79, 0.88)
    e.ambient_light_energy = 0.75
    env.environment = e
    add_child(env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -28, 0)
    sun.light_energy = 1.25
    sun.shadow_enabled = true
    add_child(sun)

    # Winding dirt paths and a small pond give the farm a readable layout.
    _box(self, Vector3(2.8, 0.08, 28), Vector3(0, -0.04, 1), Color(0.47, 0.34, 0.22))
    _box(self, Vector3(17, 0.07, 2.2), Vector3(-4, -0.035, 3), Color(0.47, 0.34, 0.22))
    var pond := MeshInstance3D.new()
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = 3.2
    cylinder.bottom_radius = 3.2
    cylinder.height = 0.08
    pond.mesh = cylinder
    pond.position = Vector3(-13, -0.04, -8)
    pond.material_override = _mat(Color(0.15, 0.43, 0.55), 0.25)
    add_child(pond)

    # Temporary stylized tree silhouettes; replaceable by Quaternius GLB assets.
    for i in range(44):
        var x := randf_range(-34, 34)
        var z := randf_range(-34, 34)
        if abs(x) < 10 and abs(z) < 13: continue
        if Vector2(x + 13, z + 8).length() < 5: continue
        _make_tree(Vector3(x, 0, z), randf_range(0.8, 1.35))

    # Distant hills.
    for i in range(12):
        var hill := MeshInstance3D.new()
        var sphere := SphereMesh.new()
        sphere.radius = randf_range(5.0, 9.0)
        sphere.height = sphere.radius * 1.2
        hill.mesh = sphere
        hill.position = Vector3(-42 + i * 8, -1.5, -43 - randf_range(0, 8))
        hill.material_override = _mat(Color(0.28, 0.42, 0.29))
        add_child(hill)

func _make_tree(pos: Vector3, scale_factor: float) -> void:
    var trunk := MeshInstance3D.new()
    var t := CylinderMesh.new()
    t.top_radius = 0.22 * scale_factor
    t.bottom_radius = 0.34 * scale_factor
    t.height = 2.4 * scale_factor
    trunk.mesh = t
    trunk.position = pos + Vector3(0, 1.2 * scale_factor, 0)
    trunk.material_override = _mat(Color(0.32, 0.20, 0.12))
    add_child(trunk)
    var crown := MeshInstance3D.new()
    var s := SphereMesh.new()
    s.radius = 1.35 * scale_factor
    s.height = 2.4 * scale_factor
    crown.mesh = s
    crown.position = pos + Vector3(0, 2.7 * scale_factor, 0)
    crown.material_override = _mat([Color(0.22,0.40,0.22), Color(0.29,0.47,0.25), Color(0.34,0.48,0.28)][randi_range(0,2)])
    add_child(crown)

func _build_farm() -> void:
    # Cottage
    _box(self, Vector3(6, 3.5, 5), Vector3(8, 1.75, -5), Color(0.73, 0.61, 0.43))
    var roof := MeshInstance3D.new()
    var roof_mesh := PrismMesh.new()
    roof_mesh.size = Vector3(7, 2.5, 6)
    roof.mesh = roof_mesh
    roof.position = Vector3(8, 4.5, -5)
    roof.rotation_degrees.z = 0
    roof.material_override = _mat(Color(0.34, 0.19, 0.16))
    add_child(roof)
    _box(self, Vector3(1.1, 2.2, 0.12), Vector3(8, 1.1, -2.43), Color(0.25, 0.15, 0.10))

    # Six tilled plots with individual interaction scripts.
    for row in range(2):
        for col in range(3):
            var plot := StaticBody3D.new()
            plot.set_script(PLOT_SCRIPT)
            plot.position = Vector3(-5 + col * 2.4, 0, -2 + row * 2.4)
            plot.set_meta("world", self)
            add_child(plot)
            plots.append(plot)

    # Well and lanterns.
    var well := MeshInstance3D.new()
    var well_mesh := CylinderMesh.new()
    well_mesh.top_radius = 0.85
    well_mesh.bottom_radius = 0.95
    well_mesh.height = 0.8
    well.mesh = well_mesh
    well.position = Vector3(3.5, 0.4, -1)
    well.material_override = _mat(Color(0.48, 0.48, 0.43))
    add_child(well)

    for p in [Vector3(-8,0,5), Vector3(10,0,5), Vector3(14,0,-10)]:
        _make_lantern(p)

func _make_lantern(p: Vector3) -> void:
    _box(self, Vector3(0.12, 2.1, 0.12), p + Vector3(0,1,0), Color(0.25,0.18,0.12))
    var glow := MeshInstance3D.new()
    var s := SphereMesh.new()
    s.radius = 0.24
    glow.mesh = s
    glow.position = p + Vector3(0,2.2,0)
    glow.material_override = _mat(Color(1.0,0.67,0.25),0.3)
    add_child(glow)
    var light := OmniLight3D.new()
    light.position = glow.position
    light.light_color = Color(1.0,0.62,0.25)
    light.light_energy = 0.7
    light.omni_range = 6
    add_child(light)

func _build_player() -> void:
    player = CharacterBody3D.new()
    player.set_script(PLAYER_SCRIPT)
    player.position = Vector3(0, 0.9, 8)
    add_child(player)

func _build_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var panel := PanelContainer.new()
    panel.position = Vector2(18, 16)
    panel.custom_minimum_size = Vector2(290, 94)
    layer.add_child(panel)
    var v := VBoxContainer.new()
    panel.add_child(v)
    var title := Label.new()
    title.text = "EVERDAWN  •  DAY 1"
    title.add_theme_font_size_override("font_size", 20)
    v.add_child(title)
    status_label = Label.new()
    status_label.text = "Seeds: 8   •   Harvest: 0\nWASD / arrows to move  •  E to tend plots"
    v.add_child(status_label)

    var hint := Label.new()
    hint.text = "A quiet valley at the edge of the old forest"
    hint.position = Vector2(18, 122)
    layer.add_child(hint)

    # Mobile touch controls: virtual directional pad and action button.
    var pad := Control.new()
    pad.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    pad.position = Vector2(24, -190)
    pad.size = Vector2(190, 160)
    layer.add_child(pad)
    _touch_button(pad, "▲", Vector2(64,0), "move_forward")
    _touch_button(pad, "▼", Vector2(64,104), "move_back")
    _touch_button(pad, "◀", Vector2(0,52), "move_left")
    _touch_button(pad, "▶", Vector2(128,52), "move_right")
    var action := Button.new()
    action.text = "USE"
    action.position = Vector2(-112, -92)
    action.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    action.custom_minimum_size = Vector2(88, 68)
    action.add_theme_font_size_override("font_size", 20)
    action.pressed.connect(_interact_nearby)
    layer.add_child(action)

func _touch_button(parent: Control, caption: String, pos: Vector2, action: String) -> void:
    var b := TouchScreenButton.new()
    b.position = pos
    b.action = action
    b.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS
    var shape := CircleShape2D.new()
    shape.radius = 30
    b.shape = shape
    parent.add_child(b)
    var label := Label.new()
    label.text = caption
    label.position = pos + Vector2(20, 12)
    label.add_theme_font_size_override("font_size", 22)
    parent.add_child(label)

func _interact_nearby() -> void:
    if player == null: return
    var nearest: Node3D
    var best := 3.2
    for p in plots:
        var d := player.global_position.distance_to(p.global_position)
        if d < best:
            best = d
            nearest = p
    if nearest:
        nearest.interact()
    else:
        status_label.text = "Walk closer to a garden bed to plant or harvest."

func update_hud() -> void:
    if status_label:
        status_label.text = "Seeds: %d   •   Harvest: %d\nMove: WASD / arrows / touch  •  Use: E" % [seed_count, harvest_count]

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("interact"):
        _interact_nearby()
