extends Camera3D


@export var target: Node3D


@warning_ignore("unused_parameter")
func _process(delta):
	look_at(target.position)
