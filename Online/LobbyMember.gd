class_name LobbyMember extends Control


var member_name: String setget set_member_name
var online_id: int
var connected: bool


func set_member_name(value: String) -> void:
	member_name = value
	$NameLabel.text = value
