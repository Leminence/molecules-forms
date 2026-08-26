extends Camera3D

@export var move_speed: float = 5.0
@export var move_speed_fast: float = 15.0   # Shift para acelerar
@export var sensitivity: float = 0.003

@export var zoom_speed: float = 2.0
@export var zoom_min: float = 1.0
@export var zoom_max: float = 100.0

# Rotação acumulada separada para evitar gimbal lock
var _yaw: float = 0.0    # rotação horizontal (Y global)
var _pitch: float = 0.0  # rotação vertical (X local)

const PITCH_LIMIT := deg_to_rad(89.0)


func _ready() -> void:
    # Inicializa yaw/pitch a partir da rotação atual da câmera
    _yaw = rotation.y
    _pitch = rotation.x


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            _zoom(-zoom_speed)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            _zoom(zoom_speed)

    if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
        _yaw   -= event.relative.x * sensitivity
        _pitch -= event.relative.y * sensitivity
        _pitch  = clamp(_pitch, -PITCH_LIMIT, PITCH_LIMIT)
        _apply_rotation()


func _process(delta: float) -> void:
    _move(delta)


# ─── Rotação ──────────────────────────────────────────────

func _apply_rotation() -> void:
    # Aplica yaw no eixo Y global e pitch no X local — sem gimbal lock
    transform.basis = Basis.IDENTITY
    rotate_y(_yaw)
    rotate_object_local(Vector3.RIGHT, _pitch)


# ─── Movimento ────────────────────────────────────────────

func _move(delta: float) -> void:
    var dir := Vector3.ZERO

    if Input.is_action_pressed("camera_forward"):
        dir -= global_basis.z   # frente na direção que a câmera olha
    if Input.is_action_pressed("camera_backward"):
        dir += global_basis.z
    if Input.is_action_pressed("camera_left"):
        dir -= global_basis.x
    if Input.is_action_pressed("camera_right"):
        dir += global_basis.x
    if Input.is_action_pressed("camera_up"):
        dir += Vector3.UP       # sobe sempre no Y global
    if Input.is_action_pressed("camera_down"):
        dir -= Vector3.UP

    if dir == Vector3.ZERO:
        return

    var speed := move_speed_fast if Input.is_key_pressed(KEY_SHIFT) else move_speed
    global_position += dir.normalized() * speed * delta


# ─── Zoom ─────────────────────────────────────────────────

func _zoom(delta: float) -> void:
    # Avança na direção que a câmera está olhando em vez de mexer só em Z
    var forward := -global_basis.z
    var new_pos := global_position + forward * (-delta * (global_position.length() * 0.1 + 1.0))
    global_position = new_pos