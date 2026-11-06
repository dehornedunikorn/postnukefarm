extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const PLOT_SCRIPT = preload("res://scripts/farm_plot.gd")

# Quaternius Stylized Nature MegaKit models (CC0). The GLB files are loaded
# once from a public mirror; instances are then reused throughout the valley.
const MODEL_URLS := {
    "tree_a": "https://raw.githubusercontent.com/anshaneja5/skyline-run/main/public/assets/models/tree1.glb",
    "tree_b": "https://raw.githubusercontent.com/anshaneja5/skyline-run/main/public/assets/models/tree2.glb",
    "tree_c": "https://raw.githubusercontent.com/anshaneja5/skyline-run/main/public/assets/models/tree3.glb",
    "bush": "https://raw.githubusercontent.com/anshaneja5/skyline-run/main/public/assets/models/bush.glb"
}

var player: CharacterBody3D
var status_label: Label
var seed_count := 8
var harvest_count := 0
var day := 1
var plots: Array[Node3D] = []
var model_scenes: Dictionary = {}
var tree_keys: Array[String] = []
var bush_keys: Array[String] = []
var clover_keys: Array[String] = []
var rock_keys: Array[String] = []
var model_load_status := "Loading the valley's living art..."
var load_count := 0
var model_root: Node3D

func _ready() -> void:
    randomize()
    _build_environment()
    _build_farm()
    _build_player()
    _build_ui()
    _load_quaternius_models()

func _mat(color: Color, roughness := 1.0) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = roughness
    return m

func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, material: Material = null) -> MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = size
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.position = pos
    node.material_override = material if material else _mat(color)
    parent.add_child(node)
    return node

func _build_environment() -> void:
    var ground := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(120, 120)
    ground.mesh = plane
    ground.material_override = _mat(Color("#6c9252"))
    ground.position.y = -0.12
    add_child(ground)

    var ground_body := StaticBody3D.new()
    ground_body.position.y = -0.55
    var ground_collision := CollisionShape3D.new()
    var ground_shape := BoxShape3D.new()
    ground_shape.size = Vector3(120, 1, 120)
    ground_collision.shape = ground_shape
    ground_body.add_child(ground_collision)
    add_child(ground_body)

    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_SKY
    e.sky = Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color("#4b7890")
    sky_mat.sky_horizon_color = Color("#c8d9c4")
    sky_mat.ground_bottom_color = Color("#536c49")
    sky_mat.ground_horizon_color = Color("#a5b98c")
    e.sky.sky_material = sky_mat
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color("#d8e4cb")
    e.ambient_light_energy = 0.8
    e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    e.fog_enabled = true
    e.fog_light_color = Color("#c1d0ad")
    e.fog_density = 0.006
    env.environment = e
    add_child(env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-42, -32, 0)
    sun.light_energy = 1.35
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 65
    add_child(sun)

    # Soft rolling hills frame the playable farm.
    for i in range(16):
        var hill := MeshInstance3D.new()
        var sphere := SphereMesh.new()
        sphere.radius = randf_range(6.0, 11.0)
        sphere.height = sphere.radius * 1.1
        hill.mesh = sphere
        hill.position = Vector3(-62 + i * 8, -2.5, -52 - randf_range(0, 14))
        hill.material_override = _mat([Color("#587e4b"), Color("#668b50"), Color("#78955b")][i % 3])
        add_child(hill)

    # Curved-looking farm lanes built from overlapping, softly rounded segments.
    var path_mat := _mat(Color("#b69a6d"))
    for i in range(9):
        var seg := _box(self, Vector3(3.3, 0.035, 4.4), Vector3(0, -0.035, 12 - i * 3.4), Color.WHITE, path_mat)
        seg.rotation_degrees.y = sin(float(i) * 0.55) * 8
    for i in range(6):
        var seg := _box(self, Vector3(4.2, 0.035, 3.2), Vector3(-1.8 - i * 2.5, -0.03, 1.0), Color.WHITE, path_mat)
        seg.rotation_degrees.y = -18

    # Pond with a grassy shoreline.
    var bank := MeshInstance3D.new()
    var bank_mesh := CylinderMesh.new()
    bank_mesh.top_radius = 4.7
    bank_mesh.bottom_radius = 4.7
    bank_mesh.height = 0.12
    bank.mesh = bank_mesh
    bank.position = Vector3(-17, -0.06, -9)
    bank.material_override = _mat(Color("#a3a76b"))
    add_child(bank)
    var pond := MeshInstance3D.new()
    var water := CylinderMesh.new()
    water.top_radius = 3.9
    water.bottom_radius = 3.9
    water.height = 0.08
    pond.mesh = water
    pond.position = Vector3(-17, 0.0, -9)
    pond.material_override = _mat(Color("#4c9ca6"), 0.18)
    add_child(pond)

    model_root = Node3D.new()
    model_root.name = "QuaterniusNature"
    add_child(model_root)

func _build_farm() -> void:
    # Warm timber-and-plaster farmhouse, with layered roof and visible trim.
    var house := Node3D.new()
    house.name = "Farmhouse"
    house.position = Vector3(9, 0, -7)
    add_child(house)
    _box(house, Vector3(7.2, 3.6, 5.6), Vector3(0, 1.8, 0), Color("#e8d5ad"))
    _box(house, Vector3(7.5, 0.22, 5.9), Vector3(0, 0.18, 0), Color("#72533a"))
    var roof_mat := _mat(Color("#9a5540"))
    var roof_a := _box(house, Vector3(4.2, 0.25, 6.4), Vector3(-1.35, 4.0, 0), Color.WHITE, roof_mat)
    roof_a.rotation_degrees.z = 29
    var roof_b := _box(house, Vector3(4.2, 0.25, 6.4), Vector3(1.35, 4.0, 0), Color.WHITE, roof_mat)
    roof_b.rotation_degrees.z = -29
    _box(house, Vector3(1.2, 2.4, 0.16), Vector3(0, 1.2, 2.88), Color("#68452f"))
    _box(house, Vector3(1.6, 1.25, 0.12), Vector3(-2.1, 2.45, 2.88), Color("#82a8a0"))
    _box(house, Vector3(1.6, 1.25, 0.12), Vector3(2.1, 2.45, 2.88), Color("#82a8a0"))
    _box(house, Vector3(0.14, 1.4, 0.14), Vector3(-2.1, 2.45, 2.96), Color("#f1e4c8"))
    _box(house, Vector3(0.14, 1.4, 0.14), Vector3(2.1, 2.45, 2.96), Color("#f1e4c8"))

    # Six generous beds with enough room to walk between them.
    for row in range(2):
        for col in range(3):
            var plot := StaticBody3D.new()
            plot.set_script(PLOT_SCRIPT)
            plot.position = Vector3(-5.3 + col * 2.65, 0, -2.4 + row * 2.65)
            plot.set_meta("world", self)
            add_child(plot)
            plots.append(plot)

    _make_well(Vector3(4.4, 0, -1.2))
    _make_lantern(Vector3(-9, 0, 5))
    _make_lantern(Vector3(12, 0, 4))
    _make_fence()

func _make_well(p: Vector3) -> void:
    var well := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.8
    mesh.bottom_radius = 0.95
    mesh.height = 0.9
    well.mesh = mesh
    well.position = p + Vector3(0, 0.45, 0)
    well.material_override = _mat(Color("#b9aa88"))
    add_child(well)
    _box(self, Vector3(2.1, 0.15, 0.18), p + Vector3(0, 1.55, 0), Color("#65442e"))
    _box(self, Vector3(0.15, 1.4, 0.15), p + Vector3(-0.8, 1.1, 0), Color("#65442e"))
    _box(self, Vector3(0.15, 1.4, 0.15), p + Vector3(0.8, 1.1, 0), Color("#65442e"))

func _make_fence() -> void:
    var wood := _mat(Color("#87603d"))
    for x in range(-13, 16, 2):
        _box(self, Vector3(0.14, 0.85, 0.14), Vector3(float(x), 0.42, 7.5), Color.WHITE, wood)
    _box(self, Vector3(28, 0.12, 0.12), Vector3(1, 0.65, 7.5), Color.WHITE, wood)
    _box(self, Vector3(28, 0.12, 0.12), Vector3(1, 0.32, 7.5), Color.WHITE, wood)

func _make_lantern(p: Vector3) -> void:
    _box(self, Vector3(0.13, 2.0, 0.13), p + Vector3(0, 1, 0), Color("#62442f"))
    var glow := MeshInstance3D.new()
    var s := SphereMesh.new()
    s.radius = 0.23
    glow.mesh = s
    glow.position = p + Vector3(0, 2.1, 0)
    glow.material_override = _mat(Color("#ffd17a"), 0.25)
    add_child(glow)
    var light := OmniLight3D.new()
    light.position = glow.position
    light.light_color = Color("#ffc66f")
    light.light_energy = 0.55
    light.omni_range = 7
    add_child(light)

func _collect_model_paths(folder: String, output: Array[String]) -> void:
    var dir := DirAccess.open(folder)
    if dir == null: return
    dir.list_dir_begin()
    var entry := dir.get_next()
    while entry != "":
        if dir.current_is_dir():
            if not entry.begins_with("."):
                _collect_model_paths(folder.path_join(entry), output)
        elif entry.to_lower().ends_with(".gltf") or entry.to_lower().ends_with(".glb"):
            output.append(folder.path_join(entry))
        entry = dir.get_next()
    dir.list_dir_end()

func _load_quaternius_models() -> void:
    # Prefer the actual CC0 Standard archive extracted during CI.
    var paths: Array[String] = []
    _collect_model_paths("res://assets/quaternius", paths)
    paths.sort()
    for path in paths:
        var filename := path.get_file().get_basename().to_lower()
        var category := ""
        if filename.contains("tree") or filename.contains("pine") or filename.contains("birch"):
            category = "tree"
        elif filename.contains("bush") or filename.contains("shrub"):
            category = "bush"
        elif filename.contains("clover") or filename.contains("flower"):
            category = "clover"
        elif filename.contains("rock"):
            category = "rock"
        if category == "": continue
        var packed := ResourceLoader.load(path) as PackedScene
        if packed == null: continue
        var index := tree_keys.size() if category == "tree" else bush_keys.size() if category == "bush" else clover_keys.size() if category == "clover" else rock_keys.size()
        var key: String = category + "_" + str(index)
        model_scenes[key] = packed
        if category == "tree":
            tree_keys.append(key)
        elif category == "bush":
            bush_keys.append(key)
        elif category == "clover":
            clover_keys.append(key)
        elif category == "rock":
            rock_keys.append(key)

    if tree_keys.size() > 0:
        _populate_quaternius_forest()
        model_load_status = "Quaternius nature: %d trees · %d bushes · %d clovers · %d rocks" % [tree_keys.size(), bush_keys.size(), clover_keys.size(), rock_keys.size()]
        update_hud()
        return

    # Development fallback when the Standard archive has not been imported locally.
    for key in MODEL_URLS.keys():
        var req := HTTPRequest.new()
        req.timeout = 30.0
        add_child(req)
        req.request_completed.connect(_on_model_downloaded.bind(key, req))
        var err := req.request(MODEL_URLS[key])
        if err != OK:
            model_load_status = "Could not start nature model download."
            req.queue_free()

func _on_model_downloaded(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, key: String, req: HTTPRequest) -> void:
    req.queue_free()
    load_count += 1
    if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
        var doc := GLTFDocument.new()
        var state := GLTFState.new()
        var err := doc.append_from_buffer(body, "", state)
        if err == OK:
            model_scenes[key] = doc.generate_scene(state)
            if key.begins_with("tree"):
                tree_keys.append(key)
            elif key == "bush":
                bush_keys.append(key)
    if load_count >= MODEL_URLS.size():
        _populate_quaternius_forest()
        model_load_status = "Quaternius nature loaded" if tree_keys.size() > 0 else "Nature models unavailable — reconnect to load"
        update_hud()

func _spawn_model(key: String, pos: Vector3, scale_factor: float, yaw: float = 0.0) -> void:
    if not model_scenes.has(key): return
    var source = model_scenes[key]
    var instance: Node3D
    if source is PackedScene:
        instance = source.instantiate() as Node3D
    elif source is Node3D:
        instance = source.duplicate() as Node3D
    if instance == null: return
    instance.position = pos
    instance.scale = Vector3.ONE * scale_factor
    instance.rotation.y = yaw
    model_root.add_child(instance)

func _populate_quaternius_forest() -> void:
    if tree_keys.is_empty(): return
    var placements := [
        Vector3(-34,0,-28), Vector3(-27,0,-35), Vector3(-19,0,-31), Vector3(-8,0,-35),
        Vector3(2,0,-34), Vector3(18,0,-34), Vector3(29,0,-29), Vector3(36,0,-18),
        Vector3(-36,0,-8), Vector3(-33,0,12), Vector3(-29,0,27), Vector3(-18,0,32),
        Vector3(2,0,34), Vector3(19,0,31), Vector3(32,0,24), Vector3(37,0,8),
        Vector3(27,0,15), Vector3(-23,0,17), Vector3(-30,0,-20), Vector3(25,0,-21)
    ]
    for i in range(placements.size()):
        var key: String = tree_keys[i % tree_keys.size()]
        _spawn_model(key, placements[i], [1.15, 1.35, 1.0, 1.25][i % 4], float(i) * 0.61)
    if not bush_keys.is_empty():
        for i in range(28):
            var x := randf_range(-23, 24)
            var z := randf_range(-24, 26)
            if abs(x) < 13 and abs(z) < 13: continue
            var bush_key: String = bush_keys[i % bush_keys.size()]
            _spawn_model(bush_key, Vector3(x, 0, z), randf_range(0.55, 0.9), randf_range(0.0, TAU))
    if not clover_keys.is_empty():
        for i in range(42):
            var x := randf_range(-26, 26)
            var z := randf_range(-26, 26)
            if abs(x) < 9 and abs(z) < 9: continue
            var clover_key: String = clover_keys[i % clover_keys.size()]
            _spawn_model(clover_key, Vector3(x, 0, z), randf_range(0.45, 0.8), randf_range(0.0, TAU))
    if not rock_keys.is_empty():
        var rock_spots := [Vector3(-20,0,-8), Vector3(-14,0,-13), Vector3(-21,0,-14), Vector3(23,0,-15), Vector3(29,0,-8), Vector3(21,0,19), Vector3(-25,0,19), Vector3(14,0,29)]
        for i in range(rock_spots.size()):
            var rock_key: String = rock_keys[i % rock_keys.size()]
            _spawn_model(rock_key, rock_spots[i], randf_range(0.7, 1.25), randf_range(0.0, TAU))
func _build_player() -> void:
    player = CharacterBody3D.new()
    player.set_script(PLAYER_SCRIPT)
    player.position = Vector3(0, 0.9, 10)
    add_child(player)
    player.set_physics_process(false)

func _build_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var panel := PanelContainer.new()
    panel.position = Vector2(18, 16)
    panel.custom_minimum_size = Vector2(320, 108)
    layer.add_child(panel)
    var v := VBoxContainer.new()
    panel.add_child(v)
    var title := Label.new()
    title.text = "EVERDAWN  /  THE GREEN VALE"
    title.add_theme_font_size_override("font_size", 20)
    v.add_child(title)
    status_label = Label.new()
    status_label.text = "DAY 01   •   SEEDS 08   •   HARVEST 00\nWASD / arrows / touch • E to tend the beds"
    v.add_child(status_label)

    var hint := Label.new()
    hint.text = "A quiet valley, where every seed has a story."
    hint.position = Vector2(20, 132)
    layer.add_child(hint)

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
    action.text = "TEND"
    action.position = Vector2(-116, -96)
    action.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    action.custom_minimum_size = Vector2(96, 72)
    action.add_theme_font_size_override("font_size", 19)
    action.pressed.connect(_interact_nearby)
    layer.add_child(action)

    var menu := ColorRect.new()
    menu.name = "TitleScreen"
    menu.color = Color(0.035, 0.065, 0.045, 0.88)
    menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(menu)
    var card := PanelContainer.new()
    card.set_anchors_preset(Control.PRESET_CENTER)
    card.position = Vector2(-220, -155)
    card.custom_minimum_size = Vector2(440, 310)
    menu.add_child(card)
    var menu_stack := VBoxContainer.new()
    menu_stack.alignment = BoxContainer.ALIGNMENT_CENTER
    menu_stack.add_theme_constant_override("separation", 14)
    card.add_child(menu_stack)
    var game_title := Label.new()
    game_title.text = "EVERDAWN"
    game_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    game_title.add_theme_font_size_override("font_size", 44)
    menu_stack.add_child(game_title)
    var subtitle := Label.new()
    subtitle.text = "THE GREEN VALE"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 18)
    menu_stack.add_child(subtitle)
    var story := Label.new()
    story.text = "A little farm. A living valley.\nYour story starts with one seed."
    story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    story.add_theme_font_size_override("font_size", 16)
    menu_stack.add_child(story)
    var start_button := Button.new()
    start_button.text = "ENTER THE GREEN VALE"
    start_button.custom_minimum_size = Vector2(0, 54)
    start_button.add_theme_font_size_override("font_size", 18)
    menu_stack.add_child(start_button)
    start_button.pressed.connect(func() -> void:
        menu.queue_free()
        player.set_physics_process(true)
    )
    var controls := Label.new()
    controls.text = "WASD / arrows / touch to move  •  E / TEND to farm"
    controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    controls.add_theme_font_size_override("font_size", 12)
    menu_stack.add_child(controls)

func _touch_button(parent: Control, caption: String, pos: Vector2, action: String) -> void:
    var b := TouchScreenButton.new()
    b.position = pos
    b.action = action
    b.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS
    var shape := CircleShape2D.new()
    shape.radius = 31
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
    var best := 3.4
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
        status_label.text = "DAY %02d   •   SEEDS %02d   •   HARVEST %02d\n%s" % [day, seed_count, harvest_count, model_load_status]
