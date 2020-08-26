extends Node2D

export(int, "p1", "p2") var preset = 0
# Called when the node enters the scene tree for the first time.
func _ready():
  $body.region_rect = Rect2(preset * 16, 0, 16, 16)
  pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#  pass
