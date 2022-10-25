class_name Protobuf extends Node


# Size of data. Change as required.
const SIZE_OF_MSG_TYPE := 5 # 32

# CUSTOM DATA ##################################################################
const SIZE_OF_POSITION := 12 # 4096
################################################################################


enum Client {
	INITIATE_CONNECTION = 1,
	# CUSTOM ENUMS #############################################################
	PLAYER_INPUT,
	############################################################################
}


enum Server {
	START_GAME = 1,
	# CUSTOM ENUMS #############################################################
	PLAYER_UPDATE,
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


static func create_client_input_msg(mouse_posn_x: int, mouse_posn_y: int) -> PoolByteArray:
	var data := mouse_posn_y
	
	data <<= SIZE_OF_POSITION
	data |= mouse_posn_x
	
	data <<= SIZE_OF_MSG_TYPE
	data |= Client.PLAYER_INPUT
	
	return to_bytes(data)


static func create_server_player_update_msg(posn_x: int, posn_y: int) -> PoolByteArray:
	var data := posn_y
	
	data <<= SIZE_OF_POSITION
	data |= posn_x
	
	data <<= SIZE_OF_MSG_TYPE
	data |= Server.PLAYER_UPDATE
	
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
		message["posn_x"] = data & (1 << SIZE_OF_POSITION) - 1
		data >>= SIZE_OF_POSITION
		
		message["posn_y"] = data & (1 << SIZE_OF_POSITION) - 1
		data >>= SIZE_OF_POSITION
	############################################################################
	
	return message