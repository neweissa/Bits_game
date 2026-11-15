extends CharacterBody2D
# PERSONAJE 4: DESENCRIPTACIÓN (Comunicaciones)
# Tecla E: traduce los mensajes de los aliens cercanos y los muestra sobre ellos.
# Los aliens deben estar en el grupo "aliens".
# El texto se toma de:
#   1) un método traducir() en el alien, si existe; o
#   2) un metadato llamado "mensaje" (se puede escribir en el Inspector, pestaña Node > Metadata).

signal mensaje_traducido(texto: String)

@export var velocidad: float = 250.0
@export var radio_traduccion: float = 300.0
@export var duracion_texto: float = 4.0


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
		_desencriptar()


func _desencriptar() -> void:
	for alien in get_tree().get_nodes_in_group("aliens"):
		if alien is Node2D and global_position.distance_to(alien.global_position) <= radio_traduccion:
			var texto := _traducir(alien)
			mensaje_traducido.emit(texto)
			_mostrar_texto(alien, texto)


func _traducir(alien: Node2D) -> String:
	if alien.has_method("traducir"):
		return str(alien.traducir())
	return str(alien.get_meta("mensaje", "Mensaje alien traducido"))


func _mostrar_texto(alien: Node2D, texto: String) -> void:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.position = Vector2(-60.0, -50.0)
	etiqueta.add_theme_color_override("font_color", Color(0.921, 0.325, 0.645, 1.0))
	alien.add_child(etiqueta)

	await get_tree().create_timer(duracion_texto).timeout

	if is_instance_valid(etiqueta):
		etiqueta.queue_free()
