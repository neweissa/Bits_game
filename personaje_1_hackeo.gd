extends CharacterBody2D
# PERSONAJE 1: HACKEO DE ROBOTS (Energía)
# Tecla E: corta la energía de los enemigos cercanos (grupo "enemigos") por unos segundos.
# Si el enemigo tiene el método apagar(duracion) (como perro_enemigo.gd), se usa ese.
# Relación real: los inhibidores cortan el camino de la energía, como los interruptores
# de separación que mantienen apagado un CubeSat dentro de su desplegador.

@export var velocidad: float = 250.0
@export var radio_hackeo: float = 160.0
@export var duracion_apagado: float = 4.0

var _pulso: float = 0.0


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
	var anim := get_node_or_null("Animated") as AnimatedSprite2D
	if anim != null:
		if velocity.length() > 5.0:
			if abs(velocity.y) > abs(velocity.x):
				if velocity.y < 0.0:
					anim.play("caminar_arriba")
				else:
					anim.play("caminar_abajo")
			else:
				anim.play("caminar_lado")
				anim.flip_h = velocity.x < 0.0
		else:
			anim.play("estatico")

	if Input.is_action_just_pressed("habilidad"):
		_hackear()

	if _pulso > 0.0:
		_pulso = maxf(0.0, _pulso - delta)
		queue_redraw()


func _hackear() -> void:
	_pulso = 0.4
	for enemigo in get_tree().get_nodes_in_group("enemigos"):
		if enemigo is Node2D and global_position.distance_to(enemigo.global_position) <= radio_hackeo:
			if enemigo.has_method("apagar"):
				enemigo.apagar(duracion_apagado)


func _draw() -> void:
	if _pulso > 0.0:
		draw_arc(Vector2.ZERO, radio_hackeo, 0.0, TAU, 48, Color(1.0, 1.0, 0.0, _pulso / 0.4), 2.0)
