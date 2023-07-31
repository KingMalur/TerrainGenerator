# Terrain Generator - Godot v4.1.1  
This Godot project can create a chunk based mesh-array with collisions and navigation.  

It's **not yet ready** to be used in a real project! It's just a fun project of mine to learn mesh generation (I added some explanations as comments for myself, maybe they're helpful for you too).  

## Usage  
If you do want to use it in your project, just follow these steps:  
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
- Try to balance the values for ``noise_height_modifier`` & ``max_rock_height`` (in the shader settings) with the ``terrain_unit_size`` <sub><sup>(Multiplying both values with the ``terrain_unit_size`` seems to work pretty good from a bit of testing)<sub><sup>  

## ToDo  
- [x] Add unit size changing <sub><sup>(1u in Godot multiplied by X to stretch the terrain)<sub><sup>  
- [x] Add ``center_terrain`` <sub><sup>~~(You can set the flag but it's not doing anything..)~~</sup></sub>  
- [ ] Add signals  
- [ ] Add edge falloff by heightmap or by code <sub><sup>(Could take some percentage and check against current x/z position -> Should be faster than sampling another heightmap)</sub></sup>  
- [ ] Better shaders <sub><sup>(Urgent! Current shader looks real bad for bigger terrain..)</sup></sub>  
- [ ] Create a water mesh & shader  
- [ ] Fix shader breaking on window resize  
- [ ] Add unit tests :see_no_evil:  
- [ ] ...  
