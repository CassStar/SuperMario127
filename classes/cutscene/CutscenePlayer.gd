extends VideoPlayer
class_name CutscenePlayer

signal cutscene_started()
signal cutscene_ended()

onready var skip_button: Button = $"%Button"

const CUTSCENE_DIR: String = "user://New Campaign/Cutscenes/"
const FILE_EXTENSION: String = ".ogv"

var video_file: String setget set_video_file,get_video_file
var is_paused: bool = false
var is_loaded: bool = false

export var is_finished: bool = false
export var video_position: float = 0 setget set_video_position,get_video_position
export var video_name: String setget set_video_name,get_video_name

export var scene_from: String setget set_scene_from,get_scene_from
export var scene_to: String setget set_scene_to,get_scene_to

func set_video_file(value: String) -> void:
	
	set_video_name(value)
	video_file =  CUTSCENE_DIR+value+FILE_EXTENSION

func get_video_file() -> String:
	
	return video_file

func set_video_name(value: String) -> void:
	
	video_name = value

func get_video_name() -> String:
	
	return video_name

func set_video_position(value: float) -> void:
	
	video_position = value

func get_video_position() -> float:
	
	return video_position

func set_scene_from(value: String) -> void:
	
	scene_from = value

func get_scene_from() -> String:
	
	return scene_from

func set_scene_to(value: String) -> void:
	
	scene_to = value

func get_scene_to() -> String:
	
	return scene_to

## ^ Setters and Getters ^
##-------------------------
## v Functionality v

## Initializes a new cutscene player with the given from and to scenes.
## When a cutscene ends, to_scene is loaded and run.
func _init(from_scene: String, to_scene: String) -> void:
	
	set_scene_from(from_scene)
	set_scene_to(to_scene)
	
	connect("finished", self, "cutscene_ended")
	connect("pressed", skip_button, "cutscene_ended")

## Loads a video to be played as a cutscene.
## Note: You only need to pass the name of the video, the file path and
## extenstion will be added automatically.
func load_video(video: String) -> void:
	
	is_loaded = false
	
	set_video_file(video)
	stream.set_file(get_video_file())
	set_stream(stream)
	
	is_loaded = true

## Starts the cutscene, alse emits the cutscene_started signal
func start() -> void:
	
	is_paused = true
	is_finished = false
	set_video_position(0)
	
	play_video()
	
	emit_signal("cutscene_started", get_video_name())

## Method for playing the video. This is needed for pause/unpause functionality.
func play_video() -> void:
	
	if (!is_paused): return
	
	set_stream_position(get_video_position())
	play()
	
	is_paused = false

## Pauses the cutscene.
func pause() -> void:
	
	if (is_paused): return
	
	set_video_position(get_stream_position())
	stop()
	
	is_paused = true

## Function that is called after the cutscene video finishes playing or is
## skipped by pressing the skip button.
func cutscene_ended() -> void:
	
	emit_signal("cutscene_ended", get_video_name())
	
	is_finished = true
	
	get_tree().change_scene(get_scene_to())

## Handle key input for pausing cutscenes
func _unhandled_key_input(event: InputEventKey) -> void:
	
	if (event.is_action_pressed("p")):
		
		pause()

# Unused, keeping just in case.
func process(_delta: float) -> void:
	pass
