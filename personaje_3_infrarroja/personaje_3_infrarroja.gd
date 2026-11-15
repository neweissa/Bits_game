extends CharacterBody2D
# PERSONAJE 3: LUZ INFRARROJA (Térmico)
# Tecla E: detecta el calor de los enemigos cercanos y los resalta en rojo,
# incluso si estaban ocultos. Dura unos segundos.
# Los enemigos deben estar en el grupo "enemigos".

@export var velocidad: float = 250.0
@export var radio_deteccion: float = 300.0  # antes 450
@export var duracion: float = 5.0

var activa: bool = false


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


func _physics_process(_delta: float) -> void:
	var direccion := Input.get_vector("izquierda", "derecha", "arriba", "abajo")
	velocity = direccion * velocidad
	move_and_slide()

	if Input.is_action_just_pressed("habilidad") and not activa:
		_luz_infrarroja()


func _luz_infrarroja() -> void:
	activa = true
	queue_redraw()

	var detectados: Array[Node2D] = []
	for enemigo in get_tree().get_nodes_in_group("enemigos"):
		if enemigo is Node2D and global_position.distance_to(enemigo.global_position) <= radio_deteccion:
			detectados.append(enemigo)
			enemigo.set_meta("color_original", enemigo.modulate)
			enemigo.set_meta("visible_original", enemigo.visible)
			enemigo.modulate = Color(1.0, 0.2, 0.1)  # se ve el calor
			enemigo.visible = true

	await get_tree().create_timer(duracion).timeout

	for enemigo in detectados:
		if is_instance_valid(enemigo):
			enemigo.modulate = enemigo.get_meta("color_original", Color.WHITE)
			enemigo.visible = enemigo.get_meta("visible_original", true)
	activa = false
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 16.0, Color(1.0, 0.5, 0.2))
	if activa:
		draw_arc(Vector2.ZERO, radio_deteccion, 0.0, TAU, 96, Color(1.0, 0.2, 0.1, 0.6), 2.0)
