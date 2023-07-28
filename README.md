# Terrain Generator - Godot v4.1.1  
This Godot project can create a chunk based mesh-array with collisions and navigation.  

It's **not yet ready** to be used in a real project! It's just a fun project of mine to learn mesh generation (I added some explanations as comments for myself, maybe they're helpful for you too).  

## Usage  
If you do want to use it in you project, just follow these steps:  
1) Copy the script ``TerrainGenerator.gd`` and attach it to a ``Node3D``  
2) Save your scene and then reload the saved scene  
3) Fill in the exported variables with values you like  
4) Hit ``Create New Terrain``, ``Create Water Mesh``, ``Create Collision Mesh`` & ``Create Navigation Region``  

## Hints  
- Don't set ``d_draw_spheres`` to true for big terrains or high values of ``terrain_resolution``. Godot likes to crash if you do..  
- It takes around 6 to 7 seconds for a terrain of size 1024x1024 with a chunk size of 64 <sub><sup>(On an i5-9400 with 8GB of RAM - integrated GPU)</sup></sub>  
- Be careful with the noise configuration values, too harsh of a change might make your terrain look funky  
- Try to balance the ``noise_height_modifier`` & the ``heightmap_modifier`` when sampling a heightmap  
- Edit the exported variable ``navigation_mesh`` to adapt it to your requirements  
- The same is true for the exported variable ``shader_material`` that's currently used to color the terrain  

## ToDo  
- [ ] Create a water mesh & shader  
- [ ] Add signals  
- [ ] Better shaders <sub><sup>(Urgent! Current shader looks real bad for bigger terrain..)</sup></sub>  
- [ ] Add ``center_terrain`` <sub><sup>(You can set the flag but it's not doing anything..)</sup></sub>  
- [ ] Add edge falloff by heightmap or by code <sub><sup>(Could take some percentage and check against current x/z position -> Should be faster than sampling another heightmap)</sub></sup>  
- [ ] ...  
