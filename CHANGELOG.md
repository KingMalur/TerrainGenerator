# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.0.3] - 2023-08-01

## Added

- The mesh can now be centered around (0, 0, 0)
- Easing towards ``max_terrain_height`` for flat regions using a curve
- Easing towards 0 at the edges using ``ease_towards_edge`` and a curve

## Changed

- If ``create_on_start`` is active and the scene is run, a new seed get's
generated instead of using the one set in the editor
- Use ``d_ignore_max_terrain_height`` instead of setting it to ``-1``
- Changed some default editor values to make generating interesting terrain
easier when loading the scene

## Fixed

- Calculate correct UV-positions for chunk-positions greater (0, 0)
- Sampling of heightmap for values greater than 1 of ``terrain_unit_size``

## Removed

- ``d_draw_spheres`` was removed because it was only useful in the beginning
of the project and had no real purpose (except crashing Godot) now that I can
see changes on the mesh without them

## [0.0.2] - 2023-07-30

## Added

- The mesh can now be stretched by setting the ``terrain_unit_size``
A 1024x1024 size terrain can, using this method, be stretched to 16384x16384 
while keeping the same amount of geometry as before. It looks rougher though
- Ignore ``max_terrain_height`` by setting it to ``-1``

## [0.0.1] - 2023-07-28

### Added

- Project files and REAMDME

[unreleased]: https://github.com/KingMalur/TerrainGenerator/compare/v0.0.3...dev

[0.0.3]: https://github.com/KingMalur/TerrainGenerator/releases/tag/v0.0.3
[0.0.2]: https://github.com/KingMalur/TerrainGenerator/releases/tag/v0.0.2
[0.0.1]: https://github.com/KingMalur/TerrainGenerator/releases/tag/v0.0.1
