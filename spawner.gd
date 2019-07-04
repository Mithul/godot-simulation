extends Spatial

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export (PackedScene) var character
var ground
var min_pos
var max_pos
# Called when the node enters the scene tree for the first time.
func _ready():
	ground = get_parent().get_node("Ground")
	$spawn_timer.start()
	var size = ground.mesh.size * ground.scale
	min_pos = ground.transform.origin - size/2
	max_pos = ground.transform.origin + size/2
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_spawn_timer_timeout():
	var new_blob = character.instance()
	new_blob.transform.origin = Vector3(randi()%int(max_pos.x - min_pos.x) + min_pos.x, 0 , randi()%int(max_pos.z - min_pos.z) + min_pos.z)
	new_blob.rotate_y(deg2rad(randi()%360))
	var scale_factor = clamp(randf()*2, 0.5, 2)
	new_blob.scale *= scale_factor
	new_blob.speed = 5/ scale_factor
	self.add_child(new_blob)
