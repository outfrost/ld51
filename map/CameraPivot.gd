extends Node3D

const ZOOM_INCREMENT: float = 0.1
const CAMERA_LERP_RATE: float = 10.0
const SELF_LERP_RATE: float = 8.0
const MOVEMENT_SPEED: float = 160.0

@export var movement_aabb: Rect2

var min_zoom_translation: Vector3 = Vector3(0.0, 63.0, 63.0)
var min_zoom_rotation: Vector3 = Vector3(-40.0, 0.0, 0.0)

var max_zoom_translation: Vector3 = Vector3(0.0, 9.0, 12.0)
var max_zoom_rotation: Vector3 = Vector3(-35.0, 0.0, 0.0)

@onready var camera: Camera3D = $Camera3d
@onready var viewport: Viewport = get_viewport()
@onready var game = find_parent("Game")

var min_zoom_transform: Transform3D = Transform3D.IDENTITY
var max_zoom_transform: Transform3D = Transform3D.IDENTITY
var zoom: float = 0.25

var last_mouse_pos: Vector2 = Vector2.ZERO
var target_self_xform: Transform3D = transform

func _ready() -> void:
	min_zoom_transform = min_zoom_transform \
		.rotated(Vector3.RIGHT, deg_to_rad(min_zoom_rotation.x)) \
		.rotated(Vector3.UP, deg_to_rad(min_zoom_rotation.y)) \
		.rotated(Vector3.FORWARD, deg_to_rad(min_zoom_rotation.z))

	min_zoom_transform.origin = min_zoom_translation

	max_zoom_transform = max_zoom_transform \
		.rotated(Vector3.RIGHT, deg_to_rad(max_zoom_rotation.x)) \
		.rotated(Vector3.UP, deg_to_rad(max_zoom_rotation.y)) \
		.rotated(Vector3.FORWARD, deg_to_rad(max_zoom_rotation.z))

	max_zoom_transform.origin = max_zoom_translation

func _process(delta: float) -> void:
	if game.is_running:
		if Input.is_action_just_released("zoom_in"):
			zoom = clamp(zoom + ZOOM_INCREMENT, 0.0, 1.0)
		if Input.is_action_just_released("zoom_out"):
			zoom = clamp(zoom - ZOOM_INCREMENT, 0.0, 1.0)

	var target_camera_xform = min_zoom_transform.interpolate_with(
		max_zoom_transform,
		zoom)

	camera.transform = camera.transform.interpolate_with(
		target_camera_xform,
		clamp(delta * CAMERA_LERP_RATE, 0.0, 1.0))

	if game.is_running:
		var mouse_pos: Vector2 = viewport.get_mouse_position() / Vector2(viewport.size)
		if (Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
			or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)
		):
			target_self_xform.basis = target_self_xform.basis.rotated(
				Vector3.UP,
				(mouse_pos.x - last_mouse_pos.x) * TAU * -1.0)
		last_mouse_pos = mouse_pos

		var move: Vector3 = Vector3(
			Input.get_action_strength("right") - Input.get_action_strength("left"),
			0.0,
			Input.get_action_strength("down") - Input.get_action_strength("up"))
		move *= delta * MOVEMENT_SPEED

		target_self_xform.origin = clamp_pos_to_aabb(
			target_self_xform.origin + target_self_xform.basis * move,
			movement_aabb)

	transform = transform.interpolate_with(
		target_self_xform,
		clamp(delta * SELF_LERP_RATE, 0.0, 1.0))

func clamp_pos_to_aabb(pos: Vector3, aabb: Rect2) -> Vector3:
	pos.x = clamp(pos.x, aabb.position.x, aabb.end.x)
	pos.y = 0.0
	pos.z = clamp(pos.z, aabb.position.y, aabb.end.y)
	return pos
