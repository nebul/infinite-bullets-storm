extends Node2D

class_name State

@onready var debug = owner.find_child("debug")
@onready var player = owner.get_parent().find_child("player")
@onready var speed = owner.find_child("Speed")
@onready var duration = owner.find_child("Duration")

var can_transition : bool = false

func enter():
	set_physics_process(true)
	can_transition = false
	duration.start()

func exit():
	set_physics_process(false)

func transition():
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	set_physics_process(false)
	duration.timeout.connect(_on_duration_timeout)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass # Replace with function body.*

func _physics_process(_delta):
	transition()
	debug.text = name

func _on_duration_timeout():
	can_transition = true
