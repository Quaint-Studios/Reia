## res://client/ui/components/organisms/chat_box.gd
class_name ChatBox extends VBoxContainer

var chat_log: RichTextLabel
var input_field: LineEdit

func _ready() -> void:
	custom_minimum_size = Vector2(400, 250)
	
	chat_log = RichTextLabel.new()
	chat_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chat_log.scroll_following = true
	chat_log.add_theme_font_override("normal_font", preload("res://client/assets/fonts/roboto-latin-900-normal.ttf"))
	chat_log.add_theme_font_size_override("normal_font_size", 14)
	add_child(chat_log)
	
	input_field = LineEdit.new()
	input_field.placeholder_text = "Press Enter to chat..."
	add_child(input_field)
	
	UIUtils.safe_connect(input_field.text_submitted, _on_text_submitted, "ChatBox text_submitted")
	UIUtils.safe_connect(UIEventBus.world.chat_message_received, _on_message_received, "ChatBox chat_message_received")

func _on_text_submitted(text: String) -> void:
	if text.strip_edges().is_empty(): return
	
	# 1. Clear input
	input_field.text = ""
	input_field.release_focus()
	
	# 2. Tell the network router to send the chat packet
	# (In a real app, you serialize this using Godot's StreamPeerBuffer to match rkyv)
	var writer := StreamPeerBuffer.new()
	writer.put_string(text)
	NetworkRouter.client.queue_packet(0, OpCode.ID.SEND_CHAT, writer.data_array)

func _on_message_received(sender: String, message: String) -> void:
	chat_log.append_text("[b]%s:[/b] %s\n" % [sender, message])
