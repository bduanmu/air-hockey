class_name Protobuf extends Node


# Size of data. Change as required.
const SIZE_OF_MSG_TYPE := 5 # 32

# CUSTOM DATA ##################################################################
const SIZE_OF_PLAYER_ID := 2 # 4
const SIZE_OF_POSITION := 12 # 4096
const SIZE_OF_DIRECTION := 4 # up, down, left, right
const SIZE_OF_VELOCITY := 12
const SIZE_OF_POWERUP_ID := 2
const SIZE_OF_POWERUP_INDEX := 2
const SIZE_OF_OBJECTS_ID := 16 # Maximum ~65000 objects during a game
################################################################################


enum Client {
	INITIATE_CONNECTION = 1,
	# CUSTOM ENUMS #############################################################
	PLAYER_INPUT,
	POWERUP_USED,
	SHOT,
	############################################################################
	NUM_CLIENT_ENUMS,
}


enum Server {
	START_GAME = Client.NUM_CLIENT_ENUMS,
	# CUSTOM ENUMS #############################################################
	PLAYER_UPDATE,
	BALL_UPDATE,
	POWERUP_COLLECTED,
	POWERUP_USED,
	POWERUP_SPAWNED,
	SHOT,
	WALL_DESTROYED,
	############################################################################
}


static func to_bytes(data: int) -> PoolByteArray:
	var bytes := PoolByteArray()
	while data > 0:
		bytes.append(data)
		data >>= 8
	return bytes


static func create_simple_msg(msg_type: int) -> PoolByteArray:
	var data := msg_type
	
	return to_bytes(data)


# ADD CUSTOM MESSAGE INITIALIZERS AS REQUIRED ##################################


static func create_client_input_msg(id: int, direction: int) -> PoolByteArray:
	var data := direction
	
	data <<= SIZE_OF_PLAYER_ID
	data |= id
	
	data <<= SIZE_OF_MSG_TYPE
	data |= Client.PLAYER_INPUT
	
	return to_bytes(data)


static func create_server_player_update_msg(id: int, posn_x: int, posn_y: int, vel_x: int, vel_y: int) -> PoolByteArray:
	var data := vel_y
	
	data <<= SIZE_OF_VELOCITY
	data |= vel_x
	
	data <<= SIZE_OF_POSITION
	data |= posn_y
	
	data <<= SIZE_OF_POSITION
	data |= posn_x
	
	data <<= SIZE_OF_PLAYER_ID
	data |= id
	
	data <<= SIZE_OF_MSG_TYPE
	data |= Server.PLAYER_UPDATE
	
	return to_bytes(data)


static func create_server_ball_update_msg(posn_x: int, posn_y: int, vel_x: int, vel_y: int) -> PoolByteArray:
	var data := vel_y
	
	data <<= SIZE_OF_VELOCITY
	data |= vel_x
	
	data <<= SIZE_OF_POSITION
	data |= posn_y
	
	data <<= SIZE_OF_POSITION
	data |= posn_x
	
	data <<= SIZE_OF_MSG_TYPE
	data |= Server.BALL_UPDATE
	
	return to_bytes(data)


static func create_client_shot_msg(id: int, mouse_x: int, mouse_y: int) -> PoolByteArray:
	var data := mouse_y
	
	data <<= SIZE_OF_POSITION
	data |= mouse_x
	
	data <<= SIZE_OF_PLAYER_ID
	data |= id
	
	data <<= SIZE_OF_MSG_TYPE
	data |= Client.SHOT
	
	return to_bytes(data)


static func create_server_shot_msg(id: int, mouse_x: int, mouse_y: int) -> PoolByteArray:
	var data := mouse_y
	
	data <<= SIZE_OF_POSITION
	data |= mouse_x
	
	data <<= SIZE_OF_PLAYER_ID
	data |= id
	
	data <<= SIZE_OF_MSG_TYPE
	data |= Server.SHOT
	
	return to_bytes(data)


static func create_server_powerup_collected_msg(collector: int, id: int) -> PoolByteArray:
	var data := id
	
	data <<= SIZE_OF_PLAYER_ID
	data |= collector
	
	data <<= SIZE_OF_MSG_TYPE
	data |= Server.POWERUP_COLLECTED
	
	return to_bytes(data)


static func create_client_powerup_used_msg(player_id: int, mouse_x: int = 0, mouse_y: int = 0) -> PoolByteArray:
	var data := mouse_y
	
	data <<= SIZE_OF_POSITION
	data |= mouse_x
	
	data <<= SIZE_OF_PLAYER_ID
	data |= player_id
	
	data <<= SIZE_OF_MSG_TYPE
	data |= Client.POWERUP_USED
	
	return to_bytes(data)


static func create_server_powerup_used_msg(player_id: int, mouse_x: int = 0, mouse_y: int = 0) -> PoolByteArray:
	var data := mouse_y
	
	data <<= SIZE_OF_POSITION
	data |= mouse_x
	
	data <<= SIZE_OF_PLAYER_ID
	data |= player_id
	
	data <<= SIZE_OF_MSG_TYPE
	data |= Server.POWERUP_USED
	
	return to_bytes(data)


static func create_server_powerup_spawned_msg(powerup_type: int, powerup_index: int) -> PoolByteArray:
	var data := powerup_index
	
	data <<= SIZE_OF_POWERUP_ID
	data |= powerup_type
	
	data <<= SIZE_OF_MSG_TYPE
	data |= Server.POWERUP_SPAWNED
	
	return to_bytes(data)


static func create_server_destroy_wall_msg(id: int) -> PoolByteArray: 
	var data := id
	
	data <<= SIZE_OF_MSG_TYPE
	data |= Server.WALL_DESTROYED
	
	return to_bytes(data)


################################################################################


static func deserialize(bytes: PoolByteArray) -> Dictionary:
	var data := 0b0
	for i in range(bytes.size() - 1, -1, -1):
		data |= bytes[i]
		data <<= 8
	data >>= 8
	
	var msg_type := data & (1 << SIZE_OF_MSG_TYPE) - 1
	data >>= SIZE_OF_MSG_TYPE
	
	var message := {"type": msg_type}
	
	# DESERIALIZE CUSTOM MESSAGES ##############################################
	if msg_type == Client.PLAYER_INPUT:
		message["id"] = data & (1 << SIZE_OF_PLAYER_ID) - 1
		data >>= SIZE_OF_PLAYER_ID
		
		message["direction"] = data & (1 << SIZE_OF_DIRECTION) - 1
		data >>= SIZE_OF_DIRECTION
	
	elif msg_type == Server.PLAYER_UPDATE:
		message["id"] = data & (1 << SIZE_OF_PLAYER_ID) - 1
		data >>= SIZE_OF_PLAYER_ID
		
		message["posn_x"] = data & (1 << SIZE_OF_POSITION) - 1
		data >>= SIZE_OF_POSITION
		
		message["posn_y"] = data & (1 << SIZE_OF_POSITION) - 1
		data >>= SIZE_OF_POSITION
		
		message["vel_x"] = data & (1 << SIZE_OF_VELOCITY) - 1
		data >>= SIZE_OF_VELOCITY
		
		message["vel_y"] = data & (1 << SIZE_OF_VELOCITY) - 1
		data >>= SIZE_OF_VELOCITY
	
	elif msg_type == Client.SHOT or msg_type == Server.SHOT:
		message["id"] = data & (1 << SIZE_OF_PLAYER_ID) - 1
		data >>= SIZE_OF_PLAYER_ID
		
		message["mouse_x"] = data & (1 << SIZE_OF_POSITION) - 1
		data >>= SIZE_OF_POSITION
		
		message["mouse_y"] = data & (1 << SIZE_OF_POSITION) - 1
		data >>= SIZE_OF_POSITION
	
	elif msg_type == Server.BALL_UPDATE:
		message["posn_x"] = data & (1 << SIZE_OF_POSITION) - 1
		data >>= SIZE_OF_POSITION
		
		message["posn_y"] = data & (1 << SIZE_OF_POSITION) - 1
		data >>= SIZE_OF_POSITION
		
		message["vel_x"] = data & (1 << SIZE_OF_VELOCITY) - 1
		data >>= SIZE_OF_VELOCITY
		
		message["vel_y"] = data & (1 << SIZE_OF_VELOCITY) - 1
		data >>= SIZE_OF_VELOCITY
	
	elif msg_type == Server.POWERUP_COLLECTED:
		message["collector"] = data & (1 << SIZE_OF_PLAYER_ID) - 1
		data >>= SIZE_OF_PLAYER_ID
		
		message["id"] = data & (1 << SIZE_OF_POWERUP_ID) - 1
		data >>= SIZE_OF_POWERUP_ID
	
	elif msg_type == Client.POWERUP_USED or msg_type == Server.POWERUP_USED:
		message["player_id"] = data & (1 << SIZE_OF_PLAYER_ID) - 1
		data >>= SIZE_OF_PLAYER_ID
		
		message["mouse_x"] = data & (1 << SIZE_OF_POSITION) - 1
		data >>= SIZE_OF_POSITION
		
		message["mouse_y"] = data & (1 << SIZE_OF_POSITION) - 1
		data >>= SIZE_OF_POSITION
	
	elif msg_type == Server.POWERUP_SPAWNED:
		message["powerup_type"] = data & (1 << SIZE_OF_POWERUP_ID) - 1
		data >>= SIZE_OF_POWERUP_ID
		
		message["powerup_index"] = data & (1 << SIZE_OF_POWERUP_INDEX) - 1
		data >>= SIZE_OF_POWERUP_INDEX
	
	elif msg_type == Server.WALL_DESTROYED:
		message["id"] = data & (1 << SIZE_OF_OBJECTS_ID) - 1
		data >>= SIZE_OF_OBJECTS_ID
	
	
	############################################################################
	
	return message
