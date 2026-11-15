extends CharacterBody2D
# PERSONAJE 1: HACKEO DE PERROS ESPACIALES (Energía)
# Tecla E: corta la energía de los robots enemigos cercanos (los apaga un tiempo).
# Los enemigos deben estar en el grupo "enemigos".

@export var velocidad: float = 250.0
@export var radio_hackeo: float = 200.0
@export var duracion_apagado: float = 4.0

var pulso: float = 0.0


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
	var direccion := Input.get_vector("izquierda", "derecha", "arriba", "abajo")
	velocity = direccion * velocidad
	move_and_slide()

	if Input.is_action_just_pressed("habilidad"):
		_hackear()

	if pulso > 0.0:
		pulso = max(0.0, pulso - delta)
		queue_redraw()


func _hackear() -> void:
	pulso = 0.4
	for enemigo in get_tree().get_nodes_in_group("enemigos"):
		if enemigo is Node2D and global_position.distance_to(enemigo.global_position) <= radio_hackeo:
			_cortar_energia(enemigo)


func _cortar_energia(enemigo: Node2D) -> void:
	if enemigo.has_meta("apagado"):
		return

	# Si el enemigo tiene su propio método "apagar", se usa ese.
	if enemigo.has_method("apagar"):
		enemigo.apagar(duracion_apagado)
		return

	# Si no, se le corta la energía: deja de procesar y se oscurece.
	enemigo.set_meta("apagado", true)
	enemigo.set_process(false)
	enemigo.set_physics_process(false)
	enemigo.modulate = Color(0.3, 0.3, 0.3)

	await get_tree().create_timer(duracion_apagado).timeout

	if is_instance_valid(enemigo):
		enemigo.set_process(true)
		enemigo.set_physics_process(true)
		enemigo.modulate = Color.WHITE
		enemigo.remove_meta("apagado")


func _draw() -> void:
	draw_circle(Vector2.ZERO, 16.0, Color(1.0, 0.8, 0.1))
	if pulso > 0.0:
		draw_arc(Vector2.ZERO, radio_hackeo, 0.0, TAU, 64, Color(1.0, 1.0, 0.0, pulso / 0.4), 3.0)
