class_name OnlinePlayer extends KinematicBody2D # Change superclass as required.


var local_id: int # Small unique id (0, 1, 2, ...)
var online_id: int # Unique id from online API (e.g. steamID)
var is_local: bool # Am I the local player
