# infinite terrain
a godot addon

*WIP* this project is a heavy work in progress and solves the following purpose 

* experiment with infinite terrain generation
* getting godot plugin system to know
* sharing progress while evolving this piece of software

## Description
The terrain is meant to be infinite and generated at runtime while the player moves in the world.
The terrain shall be perceived huge.
The terrain shall be editable in order to raise or lower the terrain on user demands.
Tunnels or caves are no requirement.

To find a balance between mesh generation and rendering a huge landscape the terrain is built as a grid of tiles.
The mesh resolution of each tile decreases with increasing distance to the player.

	
