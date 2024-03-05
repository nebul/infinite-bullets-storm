extends CharacterBody2D

var speed = 250
@onready var debug = $debug
@onready var progress_bar =$ProgressBar

var health = 100:
	set(value):
		health = value
		progress_bar.value = value

func set_status(bullet_type):
	match bullet_type:
		0: fire()
		1: fire()
		2: slow()
		3: stun()

func fire():
	debug.text = "fire"
	health -=10

func poison():
	debug.text = "poison"
	for i in range(5):
		health -=2
		await get_tree().create_timer(1).timeout

func slow():
	debug.text = "slow"
	speed = 50

func stun():
		debug.text = "stun"
		speed = 0
		await get_tree().create_timer(2.5).timeout
		speed=250

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass # Replace with function body.*

func _physics_process(delta):
	velocity = Input.get_vector("ui_left","ui_right","ui_up","ui_down") * speed
	move_and_slide()
