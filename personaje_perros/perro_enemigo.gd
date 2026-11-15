extends CharacterBody2D
# PERRO ENEMIGO
# Persigue al jugador (grupo "jugador"), ladra cuando está cerca y muerde de cerca.
# Si el personaje de Hackeo lo hackea (tecla E), se le corta la energía:
# se queda quieto, se oscurece y vuelve a funcionar después de unos segundos.
# Animaciones usadas en el nodo "Animated": correr, estatica, ladrido
# (comiendo y desaparecer existen en tu escena, pero este script no las usa).

@export var velocidad: float = 120.0
@export var distancia_vision: float = 400.0
@export var distancia_ladrido: float = 90.0
@export var dano: int = 10
@export var tiempo_entre_mordidas: float = 1.0

var apagado: bool = false
var puede_morder: bool = true
var jugador: Node2D = null


func _ready() -> void:
	add_to_group("enemigos")
	var colision := CollisionShape2D.new()
	var forma := CircleShape2D.new()
	forma.radius = 14.0
	colision.shape = forma
	add_child(colision)


func _physics_process(_delta: float) -> void:
	var anim := get_node_or_null("Animated") as AnimatedSprite2D

	# Sin energía: no hace nada.
	if apagado:
		velocity = Vector2.ZERO
		if anim != null:
			anim.play("estatica")
		return

	if jugador == null or not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador") as Node2D

	if jugador == null:
		_reposo(anim)
		return

	var distancia := global_position.distance_to(jugador.global_position)

	if distancia > distancia_vision:
		_reposo(anim)
	elif distancia > distancia_ladrido:
		# Persigue al jugador.
		var direccion := global_position.direction_to(jugador.global_position)
		velocity = direccion * velocidad
		move_and_slide()
		if anim != null:
			anim.play("correr")
			if direccion.x != 0.0:
				# Si tu perro se ve al revés, cambia "> 0.0" por "< 0.0".
				anim.flip_h = direccion.x > 0.0
	else:
		# Está cerca: se detiene, ladra y muerde.
		velocity = Vector2.ZERO
		if anim != null:
			anim.play("ladrido")
		_morder()


func _reposo(anim: AnimatedSprite2D) -> void:
	velocity = Vector2.ZERO
	if anim != null:
		anim.play("estatica")


func _morder() -> void:
	if not puede_morder:
		return
	puede_morder = false
	# Solo le hace daño al personaje 5 (el que tiene recibir_dano).
	if jugador != null and jugador.has_method("recibir_dano"):
		jugador.recibir_dano(dano)
	await get_tree().create_timer(tiempo_entre_mordidas).timeout
	puede_morder = true


# El personaje de Hackeo llama a esta función: enemigo.apagar(duracion)
func apagar(duracion: float) -> void:
	if apagado:
		return
	apagado = true
	modulate = Color(0.3, 0.3, 0.3)

	await get_tree().create_timer(duracion).timeout

	if is_instance_valid(self):
		apagado = false
		modulate = Color.WHITE
