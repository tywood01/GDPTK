class_name TerrainGeneration
extends Node

var mesh : MeshInstance3D
var size_depth : int = 100
var size_width : int = 100
var mesh_resolution : int = 2
var HEIGHT_SCALE : int = 50

@export var height : FastNoiseLite
@export var moisture : FastNoiseLite

@export var textureGrass : Texture
@export var textureDesert : Texture
@export var textureSnow : Texture

@export var mymatrial : Material

func _ready():
	generate()
	
func generate():
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(size_width, size_depth)
	plane_mesh.subdivide_depth = size_depth * mesh_resolution
	plane_mesh.subdivide_width = size_width * mesh_resolution
	plane_mesh.material = preload("res://assets/Textures/test_material.tres")
	
	var surface = SurfaceTool.new()
	var data = MeshDataTool.new()
	surface.create_from(plane_mesh, 0)
	
	var array_plane = surface.commit()
	data.create_from_surface(array_plane, 0)
	
	for i in range(data.get_vertex_count()):
		var vertex = data.get_vertex(i)
		vertex.y = height.get_noise_2d(vertex.x, vertex.z) * HEIGHT_SCALE
		data.set_vertex(i, vertex)
		
	array_plane.clear_surfaces()
	
	data.commit_to_surface(array_plane)
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.create_from(array_plane, 0)
	surface.generate_normals()
	
	mesh = MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.create_trimesh_collision()
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	# Add navigation to our mesh.
	mesh.add_to_group("NavSource")
	
	add_child(mesh)
