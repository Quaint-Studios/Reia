class_name TitleScreen extends Control

@onready var btn_play_online: Button = %BtnPlayOnline
@onready var btn_play_solo: Button = %BtnPlaySolo
@onready var btn_host_play: Button = %BtnHostPlay
@onready var btn_host_only: Button = %BtnHostOnly

func _ready() -> void:
	UIUtils.safe_connect(btn_play_online.pressed, _on_play_online, "TitleScreen btn_play_online.pressed")
	UIUtils.safe_connect(btn_play_solo.pressed, _on_play_solo, "TitleScreen btn_play_solo.pressed")
	UIUtils.safe_connect(btn_host_play.pressed, _on_host_play, "TitleScreen btn_host_play.pressed")
	UIUtils.safe_connect(btn_host_only.pressed, _on_host_only, "TitleScreen btn_host_only.pressed")

func _on_play_online() -> void:
	# Eventually we will pull from a server list or config file
	var target_ip := "127.0.0.1"
	UIEventBus.session.intent_play_online.emit(target_ip, 7777)

func _on_play_solo() -> void:
	# The Orchestrator will handle booting the local hidden server
	UIEventBus.session.intent_play_solo.emit()

func _on_host_play() -> void:
	# Boots a server on 7777 and a client on 127.0.0.1:7777
	UIEventBus.session.intent_host_and_play.emit(7777)

func _on_host_only() -> void:
	# Boots a server on 7777 but does not start a client
	UIEventBus.session.intent_host_only.emit(7777)
