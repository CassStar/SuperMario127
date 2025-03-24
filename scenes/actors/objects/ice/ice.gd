extends GameObject
class_name Ice

onready var sprite = $Sprite
onready var sprite2 = $Sprite/Sprite2

onready var collision_shape = $StaticBody2D/CollisionShape2D

export var normal_texture : Texture
export var recolorable_texture : Texture 

var color := Color(0,0,1)
var parts := 2
var part_height = 1

var last_parts := 2

onready var platform_area_collision_shape = $StaticBody2D/Area2D/CollisionShape2D

onready var left_width = sprite.patch_margin_left
onready var right_width = sprite.patch_margin_right
onready var part_width = sprite.texture.get_width() - left_width - right_width

var scale_x : float
export var override_part_width := 0 # If this value is not equal to 0, this'll replace part_width with it's value

func _set_properties():
	savable_properties = ["color", "parts"]
	editable_properties = ["color", "parts"]
	
func _set_property_values():
	set_property("color", color, true)
	set_property("parts", parts, true)

static func cache_raycast(body, raycast: RayCast2D)-> void:
	# Caches the given raycast for future use
	# Only used for bone goonies because they are weird
	
	body.cached_raycast = raycast.duplicate(8)

static func reset_raycast_values(raycast: RayCast2D,values: Array)-> void:
	# Resets the raycast used in the ice check to the values it had before the check was done
	raycast.position = values[0]
	raycast.rotation_degrees = values[1]
	raycast.scale = values[2]
	raycast.cast_to = values[3]
	
	for x in range(16):
		# Resetting the collision mask
		raycast.set_collision_mask_bit(x,values[x+4])

static func set_is_sliding(body, value: bool)-> void:
	
	if ("is_sliding" in body):
		body.is_sliding = value
	else: # For koopa shells only, probably
		body.get_parent().is_sliding = value

"""
This function checks if a given body should be sliding on an ice object
It's static so it can be called anywhere with 'Ice.check_is_sliding(body,raycast_node)'
The raycast node is required and is used to determine what is directly below the body
If you want to add ice physics to a new enemy/object make sure it has a raycast node in its scene
Don't worry about making the raycast node have certain properties, they're all set manually in this function
You also need to actually implement the physics change in each object, it can't(shouldn't) be done from here
Use the is_sliding property, it's what gets set by this function
"""
static func check_is_sliding(body,raycast_node: RayCast2D)-> void:
	
	var base_raycast_attributes: Array = [raycast_node.position,raycast_node.rotation_degrees,
			raycast_node.scale,raycast_node.cast_to]
	var collision_mask: Array = []
	
	for x in range(16): # get all the collision mask bits
		collision_mask.append(raycast_node.get_collision_mask_bit(x))
	base_raycast_attributes.append_array(collision_mask)
	
	var is_character: bool = (body.name.find("Character") != -1)
	
	# Checking if the body is grounded/floored
	if (body.has_method("is_grounded")):
		if (!body.is_grounded()):
			reset_raycast_values(raycast_node,base_raycast_attributes)
			return # Not grounded, nothing to make the character slide on
	elif (body is KinematicBody2D):
		if (!body.is_on_floor()):
			reset_raycast_values(raycast_node,base_raycast_attributes)
			return
	elif ("kinematic_body" in body):
		if (!body.kinematic_body.is_on_floor()):
			reset_raycast_values(raycast_node,base_raycast_attributes)
			return
	elif ("physicsbody" in body): # NPCs
		if (!body.physicsbody.is_on_floor()):
			reset_raycast_values(raycast_node,base_raycast_attributes)
			return
	elif ("wingless_body" in body): # Bone goonies
		if (!is_instance_valid(body.wingless_body) or !body.wingless_body.is_on_floor()):
			reset_raycast_values(raycast_node,base_raycast_attributes)
			return
	else: # Koopas and Nippers only, probably
		if (!body.body.is_on_floor()):
			reset_raycast_values(raycast_node,base_raycast_attributes)
			return
	
	raycast_node.set_collision_mask_bit(0,true)
	raycast_node.set_collision_mask_bit(4,true)
	var raycast_length: float
	var sprite_base = body.find_node("Sprite")
	if (!is_instance_valid(sprite_base)):
		sprite_base = body.find_node("AnimatedSprite")
	if (!is_instance_valid(sprite_base)): # NPC check
		sprite_base = body.find_node("Body")
	if (!is_instance_valid(sprite_base)): # For only fludd nozzle objects
		match body.nozzle_type:
			"HoverNozzle":
				sprite_base = body.get_node("Sprite_HoverNozzle")
			"TurboNozzle":
				sprite_base = body.get_node("Sprite_TurboNozzle")
			"RocketNozzle":
				sprite_base = body.get_node("Sprite_RocketNozzle")
	
	if (is_character): # Player check
		
		if !body.ground_collision_dive.disabled:
			raycast_node = body.ground_check_dive
			raycast_node.cast_to = Vector2(0, 7.5)
		else:
			raycast_node.cast_to = Vector2(0, 26)
		
	elif (sprite_base is AnimatedSprite): # Animated objects
		var body_sprites: AnimatedSprite = sprite_base
		var body_anim: SpriteFrames = body_sprites.frames
		var body_texture: Texture = body_anim.get_frame(body_sprites.animation,body_sprites.frame)
		
		raycast_length  = body_texture.get_height()
	
		raycast_node.position = Vector2.ZERO
		raycast_node.rotation_degrees = 0
		raycast_node.scale = Vector2.ONE
		raycast_node.cast_to = Vector2(0, raycast_length)
		
	else: # Static image objects
		var body_sprite: Sprite = sprite_base
		var body_texture: Texture = body_sprite.texture
		
		raycast_length  = body_texture.get_height()
	
		raycast_node.position = Vector2.ZERO
		raycast_node.rotation_degrees = 0
		raycast_node.scale = Vector2.ONE
		raycast_node.cast_to = Vector2(0, raycast_length)
	
	var collider = raycast_node.get_collider()
	
	if (!is_instance_valid(collider)):
		reset_raycast_values(raycast_node,base_raycast_attributes)
		return
	
	if (collider.name.find("StaticBody2D") == -1):
		set_is_sliding(body,false)
		reset_raycast_values(raycast_node,base_raycast_attributes)
		return # Not on top of an object, so return and stop sliding
		
	var owners = collider.get_shape_owners()
	var collision_owner
	
	if (collider != null && owners != null):
		
		collision_owner = collider.shape_owner_get_owner(owners[0])
		var parent = collision_owner.get_parent().get_parent()
		set_is_sliding(body,false)
		
		# ice is slippery, right? :3
		if (parent.name.find("Ice") != -1):
			
			set_is_sliding(body,true)
	reset_raycast_values(raycast_node,base_raycast_attributes)

func _ready():
	collision_shape.shape = collision_shape.shape.duplicate(true)
	collision_shape.disabled = !enabled
		
	update_parts()

func update_parts():
	
	sprite.rect_position.x = -(left_width + (part_width * parts) + right_width) / 2
	sprite.rect_size.x = left_width + right_width + part_width * parts
	if(sprite.rect_size != null && sprite2 != null && sprite2.rect_size != null && sprite != null):
		sprite2.rect_size.x = sprite.rect_size.x
	platform_area_collision_shape.shape.extents.x = (left_width + (part_width * parts) + right_width) / 2 + 20
	collision_shape.shape.extents.x = (left_width + (part_width * parts) + right_width) / 2
	
	#calculate the total scale
	scale_x = scale.x * (left_width + right_width + part_width * parts) / (left_width + right_width + part_width)

func _process(_delta):
	if color == Color(0,0,1):
		sprite.texture = normal_texture
		sprite2.visible = false
		sprite.self_modulate = Color(1, 1, 1)
	else:
		sprite.texture = recolorable_texture
		sprite2.visible = true
		var temp_colour: Color = color
		temp_colour.v *= 1.5
		sprite.self_modulate = temp_colour
	
	if parts != last_parts:
		update_parts()
	last_parts = parts

func _input(event):
	parts_input_handler(event,self)
