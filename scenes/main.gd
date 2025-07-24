extends Node

@export var pipe_scene : PackedScene
@export var flag_scene : PackedScene
@export var jump_se : AudioStreamPlayer2D 
@export var flag_se : AudioStreamPlayer2D
@export var hit_se : AudioStreamPlayer2D

var game_running : bool
var game_over : bool
var scroll
var score
var hi_score : int = 0
var scroll_speed : float = 4.0
var scroll_accel : float = 0.002 
var screen_size : Vector2i
var ground_height : int 
var pipes : Array
var pipe_delay : int = 100
var flag : Node = null       
const PIPE_RANGE : int = 200

# Call when the node enters the scene tree for the first time
func _ready():
	screen_size = get_window().size
	ground_height = 0
		
	new_game()
	
func new_game():
	# reset variable
	game_running = false
	game_over = false
	score = 0
	scroll_speed = 4.0
	$scorelabel.text = "HI SCORE : " + str(hi_score) + "\n CLICK OR TOUCH"
	$gameover.hide()
	get_tree().call_group("pipes", "queue_free")
	get_tree().call_group("flag", "queue_free")
	scroll = 0
	pipes.clear()
	# generate starting pipes
	generate_pipe()	
	$bird.reset()
	
	

func _input(event):
	if game_over == false:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				if game_running == false:
					start_game()
				else:
					if $bird.flying:
						$bird.flap()
						jump_se.play()
						check_top()
					
func start_game():
	$scorelabel.text = "SCORE : 0"
	game_running = true
	$bird.flying = true
	$bird.flap()
	# start pipe timer
	$pipetimer.start()
	
# Called every frame. 'delta' is the elapsed time since the previous frame
func _process(delta):
	if game_running:
		#reset scroll
		if scroll >= screen_size.x:
			scroll = 0;
		# move ground node
		$ground.position.x = -scroll_speed
		# 파이프 이동 및 화면 밖이면 제거
		for pipe in pipes.duplicate():
			pipe.position.x -= scroll_speed
			if pipe.position.x < -100: # -100은 파이프 너비보다 충분히 작은 값으로 조정
				pipe.queue_free()
				pipes.erase(pipe)

		# 3. flag 이동 및 화면 밖이면 제거
		if flag != null:
			flag.position.x -= scroll_speed
			if flag.position.x < -50:
				flag.queue_free()
				flag = null

func _on_pipe_timer_timeout() :
	generate_pipe()

func generate_pipe() :
	var pipe = pipe_scene.instantiate()
	pipe.position.x = screen_size.x
	pipe.position.y = (screen_size.y - ground_height) / 2 + randi_range(-PIPE_RANGE, PIPE_RANGE)
	pipe.hit.connect(bird_hit)
	pipe.scored.connect(scored)
	add_child(pipe)
	pipes.append(pipe)

func scored():
	score += 1
	$scorelabel.text = "SCORE : " + str(score) 

	if flag == null and randi_range(1, 100) > 50:
		spawn_flag()

func spawn_flag():
	if pipes.size() < 2:
		# 파이프가 2개 미만이면 기존 방식 사용
		var flag_y = randi_range(50, screen_size.y - ground_height - 50)
		var flag_x = screen_size.x + 50
		flag = flag_scene.instantiate()
		flag.position = Vector2(flag_x, flag_y)
		call_deferred("add_child", flag)
		call_deferred("_connect_flag_signal")
		return

	# 1. 파이프 x좌표 정렬
	var sorted_pipes = pipes.duplicate()
	sorted_pipes.sort_custom(func(a, b): return a.position.x < b.position.x)

	# 2. 파이프 사이 구간 리스트 생성
	var gaps = []
	for i in range(sorted_pipes.size() - 1):
		var left_pipe = sorted_pipes[i]
		var right_pipe = sorted_pipes[i + 1]
		var gap_x = (left_pipe.position.x + right_pipe.position.x) / 2
		# 화면 안쪽에만 생성
		if gap_x > 0 and gap_x < screen_size.x:
			gaps.append(gap_x)

	# 3. 구간이 없으면 기존 방식 사용
	if gaps.size() == 0:
		var flag_y = randi_range(50, screen_size.y - ground_height - 50)
		var flag_x = screen_size.x + 50
		flag = flag_scene.instantiate()
		flag.position = Vector2(flag_x, flag_y)
		call_deferred("add_child", flag)
		call_deferred("_connect_flag_signal")
		return

	# 4. 랜덤 구간 선택(혹은 플레이어와 가장 가까운 구간 선택)
	var gap_index = randi() % gaps.size()
	var pipe_gap_offset = 120  # 파이프 하나 간격(원하는 값으로 조정)
	var flag_x = gaps[gap_index] + pipe_gap_offset

	# 화면 밖으로 너무 멀리 나가지 않게 보정
	if flag_x > screen_size.x:
		flag_x = screen_size.x - 10

	var flag_y = 0
	if randi() % 2 == 0:
		flag_y = 10 # 최상단 (여유값 10)
	else:
		flag_y = screen_size.y - ground_height - 10 # 최하단 (여유값 10)

	flag = flag_scene.instantiate()
	flag.position = Vector2(flag_x, flag_y)
	call_deferred("add_child", flag)
	call_deferred("_connect_flag_signal")

func _connect_flag_signal():
	if flag:
		flag.connect("body_entered", Callable(self, "_on_flag_body_entered"))

func _on_flag_body_entered(body):
	if !game_running:
		return

	if body == $bird:
		score += 5
		$scorelabel.text = "SCORE : " + str(score)
		flag_se.play()
		flag.queue_free()
		flag = null

func check_top():
	if $bird.position.y < 0:
		$bird.falling = true
		stop_game()
		
func stop_game():
	$pipetimer.stop()
	$gameover.show()
	$bird.flying = false
	game_running = false
	game_over = true
	hit_se.play()

	if hi_score < score:
		hi_score = score
	
func bird_hit():
	if !game_running:
		return

	$bird.falling = true
	stop_game()


func _on_ground_hit() :
	if !game_running:
		return

	$bird.falling = false
	stop_game()

func _on_gameover_restart() -> void:
	new_game()
