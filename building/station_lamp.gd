extends Node3D

const NIGHT_LIGHT_THRESHOLD: float = 0.25

func _process(delta: float) -> void:
	var on = Daytime.night_light > NIGHT_LIGHT_THRESHOLD
	%SpotLight1.visible = on
	%SpotLight2.visible = on