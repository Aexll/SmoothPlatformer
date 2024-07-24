extends HBoxContainer

enum VARTYPE {FLOAT, INT, STRING, BOOL}

@export var object:Node
@export var field_name:String
@export var type:VARTYPE

var default_value


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	default_value = object.get(field_name)
	$LineEdit.text = str(default_value)
	$Label.text = field_name
	if type==VARTYPE.BOOL:
		$CheckBox.show()
		$LineEdit.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER:
			$LineEdit.focus_mode = 0
			$LineEdit.focus_mode = 1
		

func _on_line_edit_text_changed(new_text: String) -> void:
	match type:
		VARTYPE.FLOAT:
			object.set(field_name,float(new_text))
		VARTYPE.INT:
			object.set(field_name,int(new_text))
		VARTYPE.STRING:
			object.set(field_name,str(new_text))
		#VARTYPE.BOOL:
			#object.set(field_name,bool(new_text))
	


func _on_check_box_toggled(toggled_on: bool) -> void:
	object.set(field_name,toggled_on)
	pass # Replace with function body.
