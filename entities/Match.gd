extends Node2D

var file
var dimensions = Vector2(0, 0)
var turns: Array
var map: Array
var turn = 0
var elapsed = 0
var explosions = []

const TURN_DURATION = 1

onready var http = $HTTPRequest
onready var tilemaps = [
  $background,
  $walls,
  $bricks,
  $players,
  $faces,
  $bombs,
  $explosions,
  $collectibles,
]

func _ready():
  get_tree().root.connect("size_changed", self, "adjust_dimensions")
  http.connect("request_completed", self, "_on_game_loaded")
  
  if OS.get_name() == "HTML5":
    load_game("http://127.0.0.1:3000/game.json")
  else:
    read_game("res://data/game.json")
   
func _process(delta):
  if not turns:
    return
    
  elapsed += delta

  if (elapsed > TURN_DURATION) and turn < turns.size():
    elapsed = 0
    turn += 1
    draw_turn()

func read_game(path):
  var file = File.new()
  file.open(path, File.READ)
  turns = JSON.parse(file.get_as_text()).result
  
  process_map()
  adjust_dimensions()
  draw_background()
  draw_turn()
  
func load_game(url):
  var error = http.request(url)
  if error != OK:
    push_error("An error occurred in the HTTP request.")
  
func _on_game_loaded(result, response_code, headers, body):
  print("_on_game_loaded(%s, %s, %s, %s)" % [result, response_code, headers, body])
  turns = JSON.parse(body.get_string_from_utf8()).result
  
  process_map()
  adjust_dimensions()
  draw_background()
  draw_turn()

func process_map():
  map = Array(turns[turn][1].split("\n")).slice(1, -2)
  for row in map.size():
    map[row] = map[row].split(" ", false)
  
  dimensions = Vector2(map[0].size(), map.size())
  
func draw_turn():
  if (turn > 5):
    return
    
  $turn.text = "Turn: %s" % (turn + 1)
  
  process_map()
  draw_tiles()

func draw_tiles():
  # $walls.clear()
  $bricks.clear()
  $players.clear()
  $faces.clear()
  $explosions.clear()
  
  explosions = []
  
  for y in range(dimensions.y):
    for x in range(dimensions.x):
      var cell = map[y][x]
      var pos = Vector2(x, y)
      
      # walls and bricks
      if cell == "w" and $walls.get_cellv(pos) != 0:
        $walls.set_cellv(pos, 0)
      if "r" in cell:
        $bricks.set_cellv(pos, 0)
         
      # players
      if "p0" in cell:
        $players.set_cellv(pos, 0)
        $faces.set_cellv(pos, 1)
      if "p1" in cell:
        $players.set_cellv(pos, 1)
        $faces.set_cellv(pos, 1)
      if "p" in cell and "k" in cell:
        $faces.set_cellv(pos, 8)
        
      # collectibles
      if "c" in cell and $collectibles.get_cellv(pos) != 0:
        $collectibles.set_cellv(pos, 0)
        
      # bombs
      if "b3" in cell:
        $bombs.set_cellv(pos, 0) # long fuse
      if "b2" in cell:
        $bombs.set_cellv(pos, 1) # med fuse
      if "b1" in cell:
        $bombs.set_cellv(pos, 2) # short fuse
      if "e" in cell:
        explosions.append(pos)
      
  for pos in explosions:
    draw_explosion(pos)

func draw_background():
  randomize()
  for x in range(dimensions.x):
    for y in range(dimensions.y):
      var d20 = randi() % 20
      var tile = 0

      match d20:
        1:
          tile = 1
        2:
          tile = 2
        3:
          tile = 3

      $background.set_cellv(Vector2(x, y), tile)

func draw_explosion(center):
  $bombs.set_cellv(center, -1)
  $explosions.set_cellv(center, 0)
  $explosions.update_bitmask_area(center)
  
  for direction in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
    for amount in range(1,3):
      var pos = center + (direction * amount)
      
      if $walls.get_cellv(pos) == 0:
        break
      else:
        $explosions.set_cellv(pos, 0)
        $bricks.set_cellv(pos, -1)
        $explosions.update_bitmask_area(pos)
  
func adjust_dimensions():
  var resolution = dimensions * $walls.cell_size
  var window_size = get_viewport().size 
  var _scale = (window_size / resolution).floor()
  var factor = min(_scale.x, _scale.y)
  
  _scale = Vector2(factor, factor)

  for tilemap in tilemaps:
    tilemap.scale = _scale
    tilemap.position = ((window_size - resolution * _scale) / 2).floor()
