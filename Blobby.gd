extends KinematicBody

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var floor_normal = Vector3(0,1,0)

export var speed = 10
export var decay_rate = 0.998

export var takes_input = false

var eaten = false
var starving = false

onready var color = $Armature/blob.get_surface_material(0).albedo_color
onready var ColorTween = $ColorTween
onready var RotTween = $RotationTween

var look_at_body
var info

var run_away = false

var age = 0

var features
# Called when the node enters the scene tree for the first time.
func _ready():
	features = [randf(), randf(), randf()]
	# ColorTween.start()
	#$Tween.start()
	var look_at = randf()*360 - 180
	#print(look_at - int(rad2deg(rotation.y))%360)
	RotTween.interpolate_property(self, "rotation_degrees", rotation_degrees, Vector3(rotation_degrees.x, look_at, rotation_degrees.z), 0.3, Tween.TRANS_LINEAR, Tween.EASE_OUT_IN)
	RotTween.start()
	var mat = $Armature/blob.get_surface_material(0).duplicate()
	mat.albedo_color=color
	$Armature/blob.set_surface_material(0,mat)
	_on_RotationTween_tween_completed(null, null)

func set_text():
	var above_head = get_node("Position3D")
	var label = get_node("Label")
	var camera = get_tree().get_root().get_camera()
	label.text = str(age/100) + str(info) + str(look_at_body)
	var offset = Vector2(label.rect_size.x/2, 0)
	label.set_position(camera.unproject_position(above_head.global_transform.origin))

func process_input(movement, delta):
	if is_on_floor():
		if Input.is_action_pressed("ui_up"):# or $Armature/AnimationPlayer.is_playing():
			movement.z = -1
			
	if Input.is_action_pressed("ui_left"):
		rotate_y(deg2rad(1)*speed*10*delta)
	if Input.is_action_pressed("ui_right"):
		rotate_y(deg2rad(-1)*speed*10*delta)
	return movement
		
func _physics_process(delta):
	var movement = Vector3(0,-1,0)
	
	age = age+1
	set_text()
	if self.scale[0] <= 0.3 and !starving:
		self.starve()
	else:
		self.scale *= decay_rate
	
	if takes_input:
		movement = process_input(movement, delta)
	else:
		#_on_RotationTween_tween_completed(null, null)
		movement.z -= features[0]
	
	#rotate_y(clamp(deg2rad(look_at - int(rad2deg(rotation.y))%360), -deg2rad(-1)*speed*10*delta, deg2rad(-1)*speed*10*delta))
	#rotate_y(deg2rad(look_at - int(rad2deg(rotation.y))%360))
	if movement.z != 0:
		if !$Armature/AnimationPlayer.is_playing():
			$Armature/AnimationPlayer.play("ArmatureAction")
	#movement.rotated(10)
	movement = movement.rotated(Vector3(0,1,0),self.rotation.y)
	movement = movement * speed
	move_and_slide(movement, floor_normal)
	var collision = move_and_collide(movement)
	if collision and collision.collider.is_class("KinematicBody"):
		#print(collision.collider)
		if (scale/collision.collider.scale)[0] >= 1.5 and !collision.collider.eaten:
			collision.collider.consume()
			self.scale += collision.collider.scale*0.1
			self.starving = false
			#print("EAT", collision.collider.speed)
	if !is_on_floor() and $death.is_stopped():
		$death.start()
	
	#print(rotation_degrees.y, look_at)
	$Armature/blob.get_surface_material(0).albedo_color = color
	$Sensors/Area.transform = transform
	#print($Armature/blob.get_surface_material(0).albedo_color)
	
	#$Armature/blob.get_surface_material(0).albedo_color = target_color
	#print(is_coll
	
	
func consume():
	eaten = true
	print("EATEN")
	#$death.start()
	var target_color = Color(1, 0, 0, 1)
	ColorTween.interpolate_property(self, "color", color, target_color, 1, Tween.TRANS_BACK, Tween.EASE_OUT)
	ColorTween.start()
	$death.start()

func starve():
	var target_color = Color(0, 0, 1, 1)
	ColorTween.interpolate_property(self, "color", color, target_color, 1, Tween.TRANS_BACK, Tween.EASE_OUT)
	starving = true	
	$death.start()
	ColorTween.start()

func _on_death_timeout():
	if !is_on_floor() or eaten or starving:
		queue_free()


func _on_RotationTween_tween_completed(object, key):
	var look_at = randf()*360
	if look_at_body and look_at_body.get_ref():
		print(self, "I Have a mission")
		var body = look_at_body.get_ref()
		var A = Vector2( global_transform.origin.x , global_transform.origin.z)
		var B = Vector2( body.global_transform.origin.x, body.global_transform.origin.z)
		look_at = 90 + rad2deg(B.angle_to(A))
		#print(self.rotation_degrees.y, " ", look_at)
		if run_away:
			look_at = 180 + look_at
	#self.rotation_degrees.y = look_at
	#print(look_at - int(rad2deg(rotation.y))%360)
	if !takes_input:
		RotTween.interpolate_property(self, "rotation_degrees", rotation_degrees, Vector3(rotation_degrees.x, look_at, rotation_degrees.z), 1, Tween.TRANS_LINEAR, Tween.EASE_OUT_IN)
		RotTween.start()


func _on_Area_body_entered(body):
	if body.is_class("KinematicBody") and body != self:
		if body.scale > scale:
			#look_at = body.transform.origin.angle_to(transform.origin)
			look_at_body = weakref(body)
			run_away = true
			info="R"
		else:
			look_at_body = weakref(body)
			info="C"
		#_on_RotationTween_tween_completed( null, null)

func _on_ColorTween_tween_completed(object, key):
	pass # Replace with function body.


func _on_Area_body_exited(body):
	if !look_at_body or !look_at_body.get_ref():
		return
	elif look_at_body.get_ref() == body:
		look_at_body = null