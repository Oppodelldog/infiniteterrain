@tool
class_name Decorator extends Node

@export var decoration:Array[PackedScene]
@export var amount:int=10
@export var min_height:float
@export var max_height:float
@export var fixed_height:float
@export var random_y_rot:bool=true
@export var offset:Vector3
@export var min_scale:float
@export var max_scale:float

func select_decoration()->PackedScene:
	return decoration.pick_random()

func decorate_tile(x:int, y:int, grid:TerrainGrid):
	var container = Node3D.new()
	container.name=container_name(x,y)
	add_child(container)
	
	var from = grid.get_from(x,y)
	var to=grid.get_to_exclusive(from)
	
	for _i in range(amount):
		var decoration = select_decoration()
		var deco     = decoration.instantiate()
		var random_x = randf_range(from.x, to.x)
		var random_y = randf_range(from.y, to.y)
		var height   = grid.height(random_x, random_y) + grid.global_position.y
		var y_rot    = randf_range(0, 2 * PI) if random_y_rot else 0.0
		var scale    = 1
		
		if fixed_height!=0:
			height=fixed_height
		else:
			if min_height != 0 and height < min_height: continue
			if max_height != 0 and height > max_height: continue
		
		if min_scale>0: scale = min_scale
		if max_scale>0: scale = randf_range(min_scale,max_scale)
			
		deco.position   = Vector3(random_x, height, random_y)+offset
		deco.rotation.y = y_rot
		deco.scale      = Vector3.ONE*scale
		container.add_child(deco)
		
func undecorate_tile(x:int, y:int, grid:TerrainGrid):
	var container = find_child(container_name(x,y),false,false)
	if container:
		if Engine.is_editor_hint(): container.free()
		else: container.queue_free()

func container_name(x:int,y:int):
	return str(x) + "_" + str(y)







