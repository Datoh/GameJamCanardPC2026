extends Node3D

func _ready() -> void:
  _setup_environment()
  _create_floor()
  _create_walls()
  _create_player()
  _create_robot()
  _create_objects()
  _create_machines()

func _setup_environment() -> void:
  var world_env := WorldEnvironment.new()
  var env := Environment.new()
  env.background_mode = Environment.BG_COLOR
  env.background_color = Color(0.15, 0.15, 0.2)
  env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
  env.ambient_light_color = Color(0.7, 0.7, 0.7)
  env.ambient_light_energy = 1.0
  world_env.environment = env
  add_child(world_env)

  var light := DirectionalLight3D.new()
  light.rotation_degrees = Vector3(-50, 30, 0)
  light.light_energy = 1.2
  light.shadow_enabled = true
  add_child(light)

func _create_floor() -> void:
  var body := StaticBody3D.new()
  body.name = "Sol"

  var mesh_inst := MeshInstance3D.new()
  var mesh := PlaneMesh.new()
  mesh.size = Vector2(24, 24)
  var mat := StandardMaterial3D.new()
  mat.albedo_color = Color(0.35, 0.3, 0.25)
  mesh.surface_set_material(0, mat)
  mesh_inst.mesh = mesh
  body.add_child(mesh_inst)

  var col := CollisionShape3D.new()
  col.shape = WorldBoundaryShape3D.new()
  body.add_child(col)

  add_child(body)

func _create_walls() -> void:
  var mat := StandardMaterial3D.new()
  mat.albedo_color = Color(0.75, 0.72, 0.68)

  var wall_data: Array = [
    ["MurNord",  Vector3(0,    2, -12), Vector3(24, 4, 0.3)],
    ["MurSud",   Vector3(0,    2,  12), Vector3(24, 4, 0.3)],
    ["MurOuest", Vector3(-12,  2,   0), Vector3(0.3, 4, 24)],
    ["MurEst",   Vector3( 12,  2,   0), Vector3(0.3, 4, 24)],
    ["Plafond",  Vector3(0,  4.15,  0), Vector3(24, 0.3, 24)],
  ]

  for d in wall_data:
    var body := StaticBody3D.new()
    body.name = d[0]
    body.position = d[1]

    var mesh_inst := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = d[2]
    mesh.surface_set_material(0, mat)
    mesh_inst.mesh = mesh
    body.add_child(mesh_inst)

    var col := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = d[2]
    col.shape = shape
    body.add_child(col)

    add_child(body)

func _create_player() -> void:
  var player := preload("res://scenes/player.tscn").instantiate()
  player.name = "Player"
  player.position = Vector3(0, 0.9, 4)
  player.add_to_group("player")
  add_child(player)

func _create_robot() -> void:
  var robot := preload("res://scenes/robot.tscn").instantiate()
  robot.position = Vector3(0, 0.9, 0)
  add_child(robot)

func _make_cube(node_name: String, pos: Vector3, color: Color, size: Vector3, group: String = "") -> StaticBody3D:
  var body := StaticBody3D.new()
  body.name = node_name
  body.position = pos
  if group != "":
    body.add_to_group(group)

  var mesh_inst := MeshInstance3D.new()
  var mesh := BoxMesh.new()
  mesh.size = size
  var mat := StandardMaterial3D.new()
  mat.albedo_color = color
  mesh.surface_set_material(0, mat)
  mesh_inst.mesh = mesh
  body.add_child(mesh_inst)

  var col := CollisionShape3D.new()
  var shape := BoxShape3D.new()
  shape.size = size
  col.shape = shape
  body.add_child(col)

  var label := Label3D.new()
  label.text = node_name.replace("_", " ")
  label.position = Vector3(0, size.y * 0.5 + 0.25, 0)
  label.font_size = 22
  label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
  label.modulate = Color.WHITE
  body.add_child(label)

  return body

func _create_objects() -> void:
  var root := Node3D.new()
  root.name = "Objets"
  add_child(root)

  # Petits cubes 0.5x0.5x0.5 posés au sol
  var items: Array = [
    ["Dictionnaire", Vector3(-4, 0.25,  2), Color(1.0, 0.85, 0.15)],
    ["Fromage",      Vector3(-4, 0.25, -2), Color(1.0, 0.92, 0.3)],
    ["Joint",        Vector3(-6, 0.25,  1), Color(0.3, 0.75, 0.3)],
    ["Feutres",      Vector3(-6, 0.25, -1), Color(0.95, 0.35, 0.1)],
  ]
  for item in items:
    root.add_child(_make_cube(item[0], item[1], item[2], Vector3(0.5, 0.5, 0.5), "objets"))

func _create_machines() -> void:
  var root := Node3D.new()
  root.name = "Machines"
  add_child(root)

  # Grands cubes 1.5x1.5x1.5 le long du mur nord
  var items: Array = [
    ["Oscilloscope",  Vector3(-8,   0.75, -10), Color(0.1,  0.9,  0.9)],
    ["SUTOM",         Vector3(-4.5, 0.75, -10), Color(0.85, 0.1,  0.85)],
    ["Tele",          Vector3(-1,   0.75, -10), Color(0.1,  0.1,  0.1)],
    ["Labyrinthe",    Vector3( 2.5, 0.75, -10), Color(0.55, 0.35, 0.15)],
    ["PC",            Vector3( 6,   0.75, -10), Color(0.9,  0.15, 0.15)],
  ]
  for item in items:
    root.add_child(_make_cube(item[0], item[1], item[2], Vector3(1.5, 1.5, 1.5)))
