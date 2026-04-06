extends Label

signal attack_appended(attack: String)

var attacks: Array[String]:
	set(attack):
		print(attack)
		attacks = attack

func _init() -> void:
	attack_appended.connect(_on_attack_appended)

func _on_attack_appended(_attack: String) -> void:
	var out: String
	for attack in attacks:
		out = out + " " + attack
	text = out

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("move_down"):
		add_attack("↓")
	if Input.is_action_just_pressed("move_left"):
		add_attack("←")
	if Input.is_action_just_pressed("move_up"):
		add_attack("↑")
	if Input.is_action_just_pressed("move_right"):
		add_attack("→")

func add_attack(attack: String) -> void:
	attacks.append(attack)
	attack_appended.emit(attack)
	
