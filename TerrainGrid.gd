@tool
class_name TerrainGrid extends Node3D

@export var grid_extends_y:Vector2i
@export var grid_extends_x:Vector2i
@export var tile_size:int=10
@export var base_map:Texture2D
@export var base_map_height:int=1
@export var details_noise: FastNoiseLite
@export var details_noise_height:int=1
@export var base_noise: FastNoiseLite
@export var base_noise_height:int=1
@export var follow:Node3D
@export var material:ShaderMaterial
@export var generate_colliders:bool
@export var cleanup_distance:float

var actual_tile:Vector2
var height_overrride:Dictionary
var tiles:Dictionary={}
	
func _run():
	create_grid()
	
func _ready():	
	create_grid()

func create_grid():
	var start =Time.get_ticks_msec()
	var half_tile_size = int(float(tile_size) / 2)
	
	var total_num_verts={}
	var total_num_created=0
	for y in range(grid_extends_y.x, grid_extends_y.y + 1):
		for x in range(grid_extends_x.x, grid_extends_x.y + 1):
			var grid_x     = actual_tile.x + x
			var grid_y     = actual_tile.y + y
			var follow_y   = follow.global_position.y
			var v_from     = Vector2(float(grid_x * tile_size - half_tile_size), float(grid_y * tile_size - half_tile_size))
			var v_to       = Vector2(v_from.x + tile_size + 1, v_from.y + tile_size + 1)
			var v_center   = Vector2(v_from.x + half_tile_size, v_from.y + half_tile_size)
			var follow_pos = Vector2(follow.global_position.x,follow.global_position.z)
			var distance   = follow_pos.distance_to(v_center)

			var res = tile_size
			var create_collider=generate_colliders
			if distance > tile_size*2:
				res=20
				#create_collider=false
			if distance > tile_size*4:
				res=2
				#create_collider=false
				
			if tiles.has(grid_y) and tiles[grid_y].has(grid_x): continue
										
			var steps     = int(float(tile_size) / float(res))
			var tile_verts = create_tile_vertices(v_from, v_to, steps)
			
			for row in tile_verts:
				if not total_num_verts.has(res): total_num_verts[res]=0
				total_num_verts[res]+=row.size()
			
			var tile_name="mesh_%s|%s" % [grid_y, grid_x]
		
			remove_node_by_name(tile_name)
			var mesh_tile = create_mesh_tile(steps, tile_verts)
			mesh_tile.name="mesh_%s|%s-%s" % [grid_y, grid_x, Time.get_ticks_msec()]
			print("created tile %s" % mesh_tile)
						
			if create_collider: 
				var collider_name="collider_%s|%s" % [grid_y, grid_x]
				remove_node_by_name(tile_name)
				var collider = create_collider_tile(grid_x, grid_y, res, tile_verts)
				collider.name="mesh_%s|%s-%s" % [grid_y, grid_x, Time.get_ticks_msec()]
		
			if not tiles.has(grid_y): tiles[grid_y]={}
			if not tiles[grid_y].has(grid_x): tiles[grid_y][grid_x]={}
			tiles[grid_y][grid_x]={"res":res, "tile":mesh_tile}
			total_num_created+=1
			
	remove_tiles_by_distance()			

	print("grid generation (%s vertices) (%s tiles) in %s" % [total_num_verts,total_num_created,Time.get_ticks_msec() - start])
	
func remove_tiles_by_distance():
	if cleanup_distance==0: return
	
	for y in tiles.keys():
		for x in tiles[y].keys():
			var tile_pos = Vector3(x*tile_size,0,y*tile_size)
			var tile_distance=follow.global_position.distance_to(tile_pos)
			
			if tile_distance>=cleanup_distance:
				var tile=tiles[y][x].tile
				print("cleanup tile %s" % tile.name)
				tile.queue_free()
				remove_child(tile)
				tiles[y].erase(x)
			
func remove_node_by_name(name):
	var existing_tile = find_child(name+"*")
	if existing_tile: 
		print("remove by name %s"%existing_tile.name)
		remove_child(existing_tile)
		existing_tile.queue_free()
				
func clear_children():
	for n in get_children():
		print("remove child %s" % n.name)
		remove_child(n)
		n.queue_free()
		
func create_tile_vertices(from:Vector2, to:Vector2, steps:int) -> Array[PackedVector3Array]:
	var vertices: Array[PackedVector3Array]
	var half_size = int(float(tile_size) / 2)
	
	var base_map_size=0
	var base_map_img:Image
	if base_map:
		base_map_size=base_map.get_size().x-1
		base_map_img=base_map.get_image()
	
	for y in range(from.y, to.y, steps):
		var row=PackedVector3Array()
		for x in range(from.x, to.x, steps):
			
			var x_rel=float(x)/float(tile_size)+0.5
			var y_rel=float(y)/float(tile_size)+0.5
			var x_img=x_rel*base_map_size
			var y_img=x_rel*base_map_size
			
			var h = 0
			var base_map_h = base_map_img.get_pixel(x_img,y_img).r * base_map_height if base_map_img else 0
			var detail_h = details_noise.get_noise_2d(x, y) * details_noise_height if details_noise else 0
			var base_h = base_noise.get_noise_2d(x, y) * base_noise_height if base_noise else 0
			
			h += base_map_h
			h += base_h
			h += detail_h
			
			var yi=int(y)
			var xi=int(x)
			if height_overrride.has(yi):
				if height_overrride[yi].has(xi):
					h=height_overrride[yi][xi]
			row.push_back(Vector3(xi, h, yi))
		vertices.push_back(row)

	return vertices

func create_collider_tile(grid_x:int, grid_y:int,res:int, tile_verts:Array[PackedVector3Array])->CollisionShape3D:
	var heights=PackedFloat32Array()
	for row in tile_verts:
		for v in row:
			heights.push_back(v.y)

	var shape = HeightMapShape3D.new()
	shape.map_width=res + 1
	shape.map_depth=res + 1
	shape.map_data=heights
	
	var scale = tile_size/res
	var collider=CollisionShape3D.new()
	add_child(collider)
	collider.shape = shape
	collider.global_position = Vector3(grid_x * tile_size, 0, grid_y * tile_size)
	collider.scale = Vector3(scale,1,scale)
	
	return collider
	
func raise_terrain(x1:int,x2:int,y1:int,y2:int,h):
	for y in range(y1,y2):
		if not height_overrride.has(y): height_overrride[y]={}
		for x in range(x1,x2):
			if not height_overrride[y].has(x): height_overrride[y][x]={}
			height_overrride[y][x]=h

func create_mesh_tile(steps:int, tile_verts: Array[PackedVector3Array])->MeshInstance3D:
	var verts = PackedVector3Array()
	var uvs = PackedVector2Array()
	
	for y in range(tile_verts.size()-1):
		var	num_verts_per_row=tile_verts[y].size()
		for x in range(tile_verts[y].size()-1):			
			var top_left = tile_verts[y][x]
			var bottom_left = tile_verts[y+1][x]
			var top_right = tile_verts[y][x+1]
			var bottom_right = tile_verts[y+1][x+1]

			# first triangle
			verts.push_back(top_left)
			verts.push_back(bottom_right)
			verts.push_back(bottom_left)
			
			var uv_left=float(x)/float(num_verts_per_row)
			var uv_top=float(y)/float(num_verts_per_row)
			var uv_right=float(x+1)/float(num_verts_per_row)
			var uv_bottom=float(y+1)/float(num_verts_per_row)
			uv_left=0
			uv_right=1
			uv_top=0
			uv_bottom=1
			uvs.push_back(Vector2(uv_left, uv_top))
			uvs.push_back(Vector2(uv_right, uv_bottom))
			uvs.push_back(Vector2(uv_left, uv_bottom))
			
			# Second triangle
			verts.push_back(top_right)
			verts.push_back(bottom_right)
			verts.push_back(top_left)
			
			uvs.push_back(Vector2(uv_right, uv_top))
			uvs.push_back(Vector2(uv_right, uv_bottom))
			uvs.push_back(Vector2(uv_left, uv_top))

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(material)
	st.set_smooth_group(0)
	
	for i in range(verts.size()): 
		st.set_uv(uvs[i])
		st.add_vertex(verts[i])

	st.generate_normals()
	st.generate_tangents()
		
	var tmp_mesh = ArrayMesh.new()
	st.commit(tmp_mesh)
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = tmp_mesh
	add_child(mesh_instance)
	
	return mesh_instance
	
func _process(_delta):
	var tile_x = int(follow.global_position.x / tile_size)
	var tile_y = int(follow.global_position.z / tile_size)
	
	if tile_x != actual_tile.x or tile_y != actual_tile.y:
		print("center tile changed from %s,%s to %s,%s" % [actual_tile.x, actual_tile.y, tile_x, tile_y])
		actual_tile.x = tile_x
		actual_tile.y = tile_y
		create_grid()

