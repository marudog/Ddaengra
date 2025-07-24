extends Node2D

var base_y : float
var time : float = 0.0
var moving_to_player : bool = true

@onready var bird = get_tree().get_root().get_node("main/bird") # main 씬 구조에 따라 경로 조정


func _ready():
	base_y = position.y
	base_y = position.y
	# y축 거리가 40 이상이면 이동 시작
	if abs(position.y - bird.position.y) <= 30:
		moving_to_player = false
		base_y = position.y

func _process(delta):
	if moving_to_player:
		# 플레이어 y좌표로 서서히 이동
		var target_y = bird.position.y
		position.y = lerp(position.y, target_y, delta * 2.0)
		if abs(position.y - target_y) < 2.0:
			moving_to_player = false
			base_y = position.y
	else:
		time += delta
		position.y = base_y + 60 * sin(time * 5.0)

func _on_area_2d_body_entered(body:Node2D) -> void:
	pass # Replace with function body.
