extends MeshInstance3D

var mat: StandardMaterial3D = StandardMaterial3D.new()
var _start_point: Vector3
var _end_point: Vector3

# Called when the node enters the scene tree for the first time.
func _ready():
	mesh = ImmediateMesh.new()
	mat.no_depth_test = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	set_material_override(mat)

func draw_tracer(start_point, end_point, color: Color = Color.RED):
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, material_override)
	mesh.surface_set_color(color)
	mesh.surface_add_vertex(start_point)
	mesh.surface_add_vertex(end_point)
	mesh.surface_end()
	_start_point = start_point
	_end_point = end_point
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	mesh.clear_surfaces()
	if _start_point and _end_point:
		draw_tracer(_start_point, _end_point)
	