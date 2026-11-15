extends CharacterBody2D
# PERSONAJE 2: GRAVEDAD 0 (Propulsión + Orientación)
# Tecla E: activa o desactiva el modo gravedad 0.
#  - Propulsión: te mueves por empuje y sigues flotando por inercia (como la vela solar).
#  - Orientación: la nave gira sola hacia donde va (como los giroscopios).

@export var velocidad: float = 250.0
@export var aceleracion: float = 500.0
@export var velocidad_maxima: float = 400.0
@export var giro: float = 8.0

var gravedad_cero: bool = false


func _ready() -> void:
	_crear_accion("izquierda", KEY_A)
	_crear_accion("derecha", KEY_D)
	_crear_accion("arriba", KEY_W)
	_crear_accion("abajo", KEY_S)
	_crear_accion("habilidad", KEY_E)
	var colision := CollisionShape2D.new()
	var forma := CircleShape2D.new()
	forma.radius = 16.0
	colision.shape = forma
	add_child(colision)
	add_to_group("jugador")


func _crear_accion(nombre: String, tecla: Key) -> void:
	if not InputMap.has_action(nombre):
		InputMap.add_action(nombre)
		var evento := InputEventKey.new()
		evento.physical_keycode = tecla
		InputMap.action_add_event(nombre, evento)


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("habilidad"):
		gravedad_cero = not gravedad_cero
		modulate = Color(0.5, 0.8, 1.0) if gravedad_cero else Color.WHITE

	var direccion := Input.get_vector("izquierda", "derecha", "arriba", "abajo")

	if gravedad_cero:
		# Propulsión: se acelera y no hay fricción, se sigue deslizando.
		velocity += direccion * aceleracion * delta
		velocity = velocity.limit_length(velocidad_maxima)
		# Orientación: gira suavemente hacia la dirección de movimiento.
		if velocity.length() > 5.0:
			rotation = lerp_angle(rotation, velocity.angle(), giro * delta)
	else:
		velocity = direccion * velocidad
		rotation = lerp_angle(rotation, 0.0, giro * delta)

	move_and_slide()
	var anim := get_node_or_null("Animated") as AnimatedSprite2D
	if anim != null:
		if velocity.length() > 5.0:
			if abs(velocity.y) > abs(velocity.x):
				if velocity.y < 0.0:
					anim.play("caminar_arriba")
				else:
					anim.play("caminar_abajo")
			else:
				anim.play("caminar_lado_d")
				anim.flip_h = velocity.x < 0.0
		else:
			anim.play("estatico")


func _draw() -> void:
	draw_circle(Vector2.ZERO, 16.0, Color(0.3, 0.6, 1.0))
	# La línea blanca marca hacia dónde mira la nave.
	draw_line(Vector2.ZERO, Vector2(24.0, 0.0), Color.WHITE, 3.0)
