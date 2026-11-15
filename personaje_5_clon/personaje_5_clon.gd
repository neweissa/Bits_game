extends CharacterBody2D
# PERSONAJE 5: CLON HOLOGRÁFICO (Riesgo / redundancia)
# Tecla E: deja una copia de respaldo (holograma) en tu posición actual.
# Si tu vida llega a 0 y existe un clon, pasas a ocupar su lugar con la vida completa
# y el clon se consume. Sin clon, el personaje muere.
# Para dañar al personaje desde un enemigo: jugador.recibir_dano(20)

signal murio

@export var velocidad: float = 250.0
@export var vida_maxima: int = 100

var vida: int = 100
var clon: Node2D = null
var posicion_clon: Vector2 = Vector2.ZERO


func _ready() -> void:
	vida = vida_maxima
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
			anim.play("estatica")

	if Input.is_action_just_pressed("habilidad"):
		_crear_clon()


func _crear_clon() -> void:
	# Solo existe un clon a la vez: el nuevo reemplaza al anterior.
	if clon != null and is_instance_valid(clon):
		clon.queue_free()

	posicion_clon = global_position

	var anim := get_node_or_null("Animated") as AnimatedSprite2D
	if anim != null:
		# El holograma es una copia del sprite del personaje, en su pose estática.
		var copia := anim.duplicate() as AnimatedSprite2D
		get_parent().add_child(copia)
		copia.global_position = anim.global_position
		copia.global_scale = anim.global_scale
		copia.flip_h = anim.flip_h
		copia.z_index = -1
		copia.modulate = Color(0.3, 0.9, 1.0, 0.5)
		copia.play("estatica")
		clon = copia
	else:
		# Si el personaje no tiene sprite, se deja solo un marcador invisible.
		var marcador := Node2D.new()
		get_parent().add_child(marcador)
		marcador.global_position = global_position
		clon = marcador


func recibir_dano(cantidad: int) -> void:
	vida -= cantidad
	if vida <= 0:
		_usar_respaldo()


func _usar_respaldo() -> void:
	if clon != null and is_instance_valid(clon):
		global_position = posicion_clon
		clon.queue_free()
		clon = null
		vida = vida_maxima
	else:
		murio.emit()
		queue_free()
