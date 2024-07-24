extends Button

var opened:bool = false

func _on_pressed() -> void:
	if opened:
		$"../VBoxContainer".hide()
		opened=false
		focus_mode=0
	else:
		$"../VBoxContainer".show()
		opened=true
