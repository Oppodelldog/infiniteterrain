@tool
extends EditorPlugin

# A class member to hold the dock during the plugin life cycle.
var dock


func _enter_tree():
	# Initialization of the plugin goes here.
	# Load the dock scene and instantiate it.
	dock = preload("res://addons/infiniteterrain/plugin-dock.tscn").instantiate()
	dock.get_child(0).pressed.connect(on_generate_terrain)
	dock.get_child(1).pressed.connect(on_run_decorators)

	# Add the loaded scene to the docks.
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, dock)
	# Note that LEFT_UL means the left of the editor, upper-left dock.

func on_run_decorators():
	for terrain:TerrainGrid in get_tree().edited_scene_root.find_children("*","TerrainGrid",true,false):
		for dec in get_tree().edited_scene_root.find_children("*","Decorator",true,false):
			print("decorating %s " % dec.name)
			for y in terrain.tiles.keys():
				for x in terrain.tiles[y].keys():
					dec.undecorate_tile(x, y, terrain)
					dec.decorate_tile(x,y,terrain)
	
func on_generate_terrain():
	for terrain in get_tree().edited_scene_root.find_children("*","TerrainGrid",true,false):
		print("generate terrain %s " % terrain.name)
		terrain.create_new()
		
func _exit_tree():
	# Clean-up of the plugin goes here.
	# Remove the dock.
	remove_control_from_docks(dock)
	# Erase the control from the memory.
	dock.free()
