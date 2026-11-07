extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const PLOT_SCRIPT = preload("res://scripts/farm_plot.gd")
const ANIMAL_SCRIPT = preload("res://scripts/grazing_animal.gd")

# Quaternius CC0 models are bundled locally by the build script. No third-party
# runtime model downloads or non-Quaternius stock assets are used.
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
var pathrock_keys: Array[String] = []
var flower_keys: Array[String] = []
var grass_keys: Array[String] = []
var crop_families: Dictionary = {}
var character_scenes: Array[PackedScene] = []
var animal_scenes: Dictionary = {}
var building_scenes: Dictionary = {}
var model_load_status := "Loading the valley's living art..."
var load_count := 0
var model_root: Node3D

func _ready() -> void:
    randomize()
    _build_environment()
    _build_farm()
    _build_ui()
    _load_quaternius_models()
    # Instantiate the player after local Quaternius scenes are ready.
    _build_player()

func _unhandled_input(event: InputEvent) -> void:
    if player != null and player.is_physics_processing() and event is InputEventKey:
        if event.pressed and not event.echo and event.keycode == KEY_E:
            _interact_nearby()

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
    var pond_body := StaticBody3D.new()
    var pond_collision := CollisionShape3D.new()
    var pond_shape := CylinderShape3D.new()
    pond_shape.radius = 3.9
    pond_shape.height = 2.2
    pond_collision.shape = pond_shape
    pond_collision.position = Vector3(-17, 1.05, -9)
    pond_body.add_child(pond_collision)
    add_child(pond_body)

    # Invisible perimeter keeps the player inside the designed valley.
    for edge in range(4):
        var boundary := StaticBody3D.new()
        var boundary_collision := CollisionShape3D.new()
        var boundary_shape := BoxShape3D.new()
        if edge < 2:
            boundary_shape.size = Vector3(120, 5, 1)
            boundary.position = Vector3(0, 2.5, -59.5 if edge == 0 else 59.5)
        else:
            boundary_shape.size = Vector3(1, 5, 120)
            boundary.position = Vector3(-59.5 if edge == 2 else 59.5, 2.5, 0)
        boundary_collision.shape = boundary_shape
        boundary.add_child(boundary_collision)
        add_child(boundary)

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
    var house_body := StaticBody3D.new()
    var house_collision := CollisionShape3D.new()
    var house_shape := BoxShape3D.new()
    house_shape.size = Vector3(7.2, 3.6, 5.6)
    house_collision.shape = house_shape
    house_collision.position.y = 1.8
    house_body.add_child(house_collision)
    house.add_child(house_body)

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
        elif entry.to_lower().ends_with(".gltf") or entry.to_lower().ends_with(".glb") or entry.to_lower().ends_with(".fbx") or entry.to_lower().ends_with(".obj"):
            output.append(folder.path_join(entry))
        entry = dir.get_next()
    dir.list_dir_end()

func _load_quaternius_models() -> void:
    var paths: Array[String] = []
    _collect_model_paths("res://assets/quaternius", paths)
    paths.sort()
    var loaded_asset_names: Dictionary = {}
    for path in paths:
        var asset_name := path.get_file().get_basename().to_lower()
        if loaded_asset_names.has(asset_name):
            continue
        loaded_asset_names[asset_name] = true
        var filename := asset_name.replace(" ", "_")
        var packed := ResourceLoader.load(path) as PackedScene
        if packed == null: continue

        if path.to_lower().contains("/characters/"):
            character_scenes.append(packed)
            continue
        if path.to_lower().contains("/animals/"):
            for species in ["cow", "sheep", "pig", "horse", "llama", "dog"]:
                if filename.contains(species):
                    animal_scenes[species] = packed
                    break
            continue
        if path.to_lower().contains("/buildings/"):
            building_scenes[filename] = packed
            continue
        if path.to_lower().contains("/crops/"):
            var family := filename.split("_")[0]
            var variants: Array = crop_families.get(family, [])
            variants.append(packed)
            crop_families[family] = variants
            continue
        if filename.contains("tree") or filename.contains("pine") or filename.contains("birch"):
            var tree_key := "tree_%d" % tree_keys.size()
            model_scenes[tree_key] = packed
            tree_keys.append(tree_key)
        elif filename.contains("bush") or filename.contains("shrub"):
            var bush_key := "bush_%d" % bush_keys.size()
            model_scenes[bush_key] = packed
            bush_keys.append(bush_key)
        elif filename.contains("clover"):
            var clover_key := "clover_%d" % clover_keys.size()
            model_scenes[clover_key] = packed
            clover_keys.append(clover_key)
        elif filename.contains("flower"):
            var flower_key := "flower_%d" % flower_keys.size()
            model_scenes[flower_key] = packed
            flower_keys.append(flower_key)
        elif filename.contains("grass") or filename.contains("plant"):
            var grass_key := "grass_%d" % grass_keys.size()
            model_scenes[grass_key] = packed
            grass_keys.append(grass_key)
        elif filename.contains("rockpath"):
            var path_key := "pathrock_%d" % pathrock_keys.size()
            model_scenes[path_key] = packed
            pathrock_keys.append(path_key)
        elif filename.contains("rock"):
            var rock_key := "rock_%d" % rock_keys.size()
            model_scenes[rock_key] = packed
            rock_keys.append(rock_key)

    if tree_keys.size() > 0:
        _populate_quaternius_forest()
    _populate_farm_animals()
    _replace_farmhouse_with_quaternius()
    model_load_status = "Quaternius CC0 · %d trees · %d bushes · %d flowers · %d crop families · %d animal types" % [tree_keys.size(), bush_keys.size(), flower_keys.size() + clover_keys.size(), crop_families.size(), animal_scenes.size()]
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
    if key.begins_with("tree"):
        var trunk_body := StaticBody3D.new()
        trunk_body.position = pos
        var trunk_collision := CollisionShape3D.new()
        var trunk_shape := CylinderShape3D.new()
        trunk_shape.radius = 0.42 * scale_factor
        trunk_shape.height = 2.5 * scale_factor
        trunk_collision.shape = trunk_shape
        trunk_collision.position.y = 1.25 * scale_factor
        trunk_body.add_child(trunk_collision)
        model_root.add_child(trunk_body)
    elif key.begins_with("rock_"):
        var rock_body := StaticBody3D.new()
        rock_body.position = pos
        var rock_collision := CollisionShape3D.new()
        var rock_shape := SphereShape3D.new()
        rock_shape.radius = 0.5 * scale_factor
        rock_collision.shape = rock_shape
        rock_collision.position.y = 0.45 * scale_factor
        rock_body.add_child(rock_collision)
        model_root.add_child(rock_body)

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
        for i in range(32):
            var x := randf_range(-23, 24)
            var z := randf_range(-24, 26)
            if abs(x) < 13 and abs(z) < 13: continue
            var bush_key: String = bush_keys[i % bush_keys.size()]
            _spawn_model(bush_key, Vector3(x, 0, z), randf_range(0.55, 0.9), randf_range(0.0, TAU))
    var ground_flora := clover_keys + flower_keys + grass_keys
    if not ground_flora.is_empty():
        for i in range(90):
            var x := randf_range(-28, 28)
            var z := randf_range(-28, 28)
            if abs(x) < 10 and abs(z) < 10: continue
            var flora_key: String = ground_flora[i % ground_flora.size()]
            _spawn_model(flora_key, Vector3(x, 0, z), randf_range(0.35, 0.8), randf_range(0.0, TAU))
    if not pathrock_keys.is_empty():
        for i in range(18):
            var z := 12.5 - float(i) * 1.45
            var x := sin(float(i) * 0.55) * 1.0
            var path_key: String = pathrock_keys[i % pathrock_keys.size()]
            _spawn_model(path_key, Vector3(x, 0.015, z), randf_range(0.75, 0.95), randf_range(-0.12, 0.12))
    if not rock_keys.is_empty():
        var rock_spots := [Vector3(-20,0,-8), Vector3(-14,0,-13), Vector3(-21,0,-14), Vector3(23,0,-15), Vector3(29,0,-8), Vector3(21,0,19), Vector3(-25,0,19), Vector3(14,0,29)]
        for i in range(rock_spots.size()):
            var rock_key: String = rock_keys[i % rock_keys.size()]
            _spawn_model(rock_key, rock_spots[i], randf_range(0.7, 1.25), randf_range(0.0, TAU))

func _replace_farmhouse_with_quaternius() -> void:
    var chosen_key := ""
    for key in building_scenes.keys():
        if key.contains("house") and not key.contains("wall") and not key.contains("roof"):
            chosen_key = key
            break
    if chosen_key == "":
        return
    var old_house := get_node_or_null("Farmhouse")
    if old_house:
        old_house.queue_free()
    var farmhouse := building_scenes[chosen_key].instantiate() as Node3D
    if farmhouse == null: return
    farmhouse.name = "QuaterniusFarmhouse"
    farmhouse.position = Vector3(9, 0, -7)
    farmhouse.scale = Vector3.ONE * 1.5
    model_root.add_child(farmhouse)
    var body := StaticBody3D.new()
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(7.2, 4.0, 6.0)
    collision.shape = shape
    collision.position.y = 2.0
    body.add_child(collision)
    farmhouse.add_child(body)

func _populate_farm_animals() -> void:
    var placements := {
        "cow": [Vector3(18, 0, 14), Vector3(21, 0, 19)],
        "sheep": [Vector3(25, 0, 15), Vector3(28, 0, 19)],
        "pig": [Vector3(-18, 0, 15)],
        "horse": [Vector3(29, 0, 5)],
        "llama": [Vector3(-25, 0, 11)],
        "dog": [Vector3(13, 0, 12)]
    }
    for species in animal_scenes.keys():
        var spots: Array = placements.get(species, [])
        for i in range(spots.size()):
            var wanderer := Node3D.new()
            wanderer.set_script(ANIMAL_SCRIPT)
            wanderer.position = spots[i]
            wanderer.rotation.y = float(i) * 1.1
            var instance := animal_scenes[species].instantiate() as Node3D
            if instance == null: continue
            instance.scale = Vector3.ONE * (0.78 if species == "cow" or species == "horse" else 0.62)
            wanderer.add_child(instance)
            model_root.add_child(wanderer)

func get_character_scene() -> PackedScene:
    if character_scenes.is_empty(): return null
    return character_scenes[0]

func get_crop_scene(family_index: int, stage: float) -> PackedScene:
    if crop_families.is_empty(): return null
    var families: Array = crop_families.keys()
    families.sort()
    var family: String = families[posmod(family_index, families.size())]
    var variants: Array = crop_families[family]
    if variants.is_empty(): return null
    var stage_index := clampi(int(round(clampf(stage, 0.0, 1.0) * float(variants.size() - 1))), 0, variants.size() - 1)
    return variants[stage_index] as PackedScene
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
    panel.custom_minimum_size = Vector2(340, 112)
    var hud_style := StyleBoxFlat.new()
    hud_style.bg_color = Color("#1b3428", 0.88)
    hud_style.border_color = Color("#c4a36b", 0.9)
    hud_style.set_border_width_all(2)
    hud_style.set_corner_radius_all(12)
    hud_style.content_margin_left = 16
    hud_style.content_margin_right = 16
    hud_style.content_margin_top = 12
    hud_style.content_margin_bottom = 12
    panel.add_theme_stylebox_override("panel", hud_style)
    layer.add_child(panel)
    var v := VBoxContainer.new()
    panel.add_child(v)
    var title := Label.new()
    title.text = "EVERDAWN  /  THE GREEN VALE"
    title.add_theme_font_size_override("font_size", 19)
    title.add_theme_color_override("font_color", Color("#f2d49a"))
    v.add_child(title)
    status_label = Label.new()
    status_label.text = "DAY 01   •   SEEDS 08   •   HARVEST 00\nWASD / arrows / touch • E to tend the beds"
    v.add_child(status_label)

    var hint := Label.new()
    hint.text = "A quiet valley, where every seed has a story."
    hint.add_theme_color_override("font_color", Color("#f0e2c3"))
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
    action.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    action.position = Vector2(-116, -96)
    action.custom_minimum_size = Vector2(96, 72)
    action.add_theme_font_size_override("font_size", 19)
    action.add_theme_color_override("font_color", Color("#fff2d5"))
    var action_style := StyleBoxFlat.new()
    action_style.bg_color = Color("#416b48")
    action_style.border_color = Color("#d5b778")
    action_style.set_border_width_all(2)
    action_style.set_corner_radius_all(14)
    action.add_theme_stylebox_override("normal", action_style)
    var action_hover := action_style.duplicate() as StyleBoxFlat
    action_hover.bg_color = Color("#5b8a5a")
    action.add_theme_stylebox_override("hover", action_hover)
    action.pressed.connect(_interact_nearby)
    layer.add_child(action)

    var menu := ColorRect.new()
    menu.name = "TitleScreen"
    menu.color = Color(0.025, 0.055, 0.04, 0.78)
    menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(menu)
    var card := PanelContainer.new()
    var menu_style := StyleBoxFlat.new()
    menu_style.bg_color = Color("#203b2d", 0.96)
    menu_style.border_color = Color("#d0ad72")
    menu_style.set_border_width_all(3)
    menu_style.set_corner_radius_all(20)
    menu_style.content_margin_left = 24
    menu_style.content_margin_right = 24
    menu_style.content_margin_top = 24
    menu_style.content_margin_bottom = 24
    card.add_theme_stylebox_override("panel", menu_style)
    card.set_anchors_preset(Control.PRESET_CENTER)
    var card_width := maxf(300.0, minf(440.0, get_viewport().get_visible_rect().size.x - 32.0))
    card.position = Vector2(-card_width * 0.5, -155)
    card.custom_minimum_size = Vector2(card_width, 310)
    menu.add_child(card)
    var menu_stack := VBoxContainer.new()
    menu_stack.alignment = BoxContainer.ALIGNMENT_CENTER
    menu_stack.add_theme_constant_override("separation", 14)
    card.add_child(menu_stack)
    var game_title := Label.new()
    game_title.text = "EVERDAWN"
    game_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    game_title.add_theme_font_size_override("font_size", 46)
    game_title.add_theme_color_override("font_color", Color("#f4d49a"))
    menu_stack.add_child(game_title)
    var subtitle := Label.new()
    subtitle.text = "THE GREEN VALE"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 18)
    subtitle.add_theme_color_override("font_color", Color("#c5d9b3"))
    menu_stack.add_child(subtitle)
    var story := Label.new()
    story.text = "A little farm. A living valley.\nYour story starts with one seed."
    story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    story.add_theme_font_size_override("font_size", 16)
    story.add_theme_color_override("font_color", Color("#f1e5d0"))
    menu_stack.add_child(story)
    var start_button := Button.new()
    start_button.text = "ENTER THE GREEN VALE"
    start_button.custom_minimum_size = Vector2(0, 54)
    start_button.add_theme_font_size_override("font_size", 18)
    start_button.add_theme_color_override("font_color", Color("#fff4dc"))
    var start_style := StyleBoxFlat.new()
    start_style.bg_color = Color("#537d4e")
    start_style.border_color = Color("#e2c28a")
    start_style.set_border_width_all(2)
    start_style.set_corner_radius_all(12)
    start_style.content_margin_top = 8
    start_style.content_margin_bottom = 8
    start_button.add_theme_stylebox_override("normal", start_style)
    var start_hover := start_style.duplicate() as StyleBoxFlat
    start_hover.bg_color = Color("#6c985c")
    start_button.add_theme_stylebox_override("hover", start_hover)
    var start_pressed := start_style.duplicate() as StyleBoxFlat
    start_pressed.bg_color = Color("#385b3a")
    start_button.add_theme_stylebox_override("pressed", start_pressed)
    menu_stack.add_child(start_button)
    start_button.pressed.connect(func() -> void:
        menu.queue_free()
        player.set_physics_process(true)
    )
    var controls := Label.new()
    controls.text = "WASD / arrows / touch to move  •  E / TEND to farm"
    controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    controls.add_theme_font_size_override("font_size", 12)
    controls.add_theme_color_override("font_color", Color("#c7d0bd"))
    menu_stack.add_child(controls)

func _touch_button(parent: Control, caption: String, pos: Vector2, action: String) -> void:
    var button := Button.new()
    button.text = caption
    button.position = pos
    button.size = Vector2(58, 58)
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 23)
    button.add_theme_color_override("font_color", Color("#fff0d2"))
    var normal := StyleBoxFlat.new()
    normal.bg_color = Color("#203b2d", 0.76)
    normal.border_color = Color("#d0ad72", 0.9)
    normal.set_border_width_all(2)
    normal.set_corner_radius_all(18)
    button.add_theme_stylebox_override("normal", normal)
    var hover := normal.duplicate() as StyleBoxFlat
    hover.bg_color = Color("#416b48", 0.92)
    button.add_theme_stylebox_override("hover", hover)
    var pressed := normal.duplicate() as StyleBoxFlat
    pressed.bg_color = Color("#71915b", 0.98)
    button.add_theme_stylebox_override("pressed", pressed)
    button.button_down.connect(func() -> void: Input.action_press(action))
    button.button_up.connect(func() -> void: Input.action_release(action))
    parent.add_child(button)

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
