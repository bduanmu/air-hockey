extends Node2D

# MUST BE SET TO AUTOLOAD NAMED "Online" (Project -> Project Settings -> Autoload)


const MAX_PLAYERS := 2


enum {
	NONE,
	STEAM,
}


enum Channel {
	CLIENT = 0,
	SERVER = 1,
}

# Enumerates high level connection states.
enum NetworkingConnectionState {
	# Dummy value used to indicate an error condition in the API.
	# Specified connection doesn't exist or has already been closed.
	NONE = 0,

	# We are trying to establish whether peers can talk to each other,
	# whether they WANT to talk to each other, perform basic auth,
	# and exchange crypt keys.
	#
	# - For connections on the "client" side (initiated locally):
	#   We're in the process of trying to establish a connection.
	#   Depending on the connection type, we might not know who they are.
	#   Note that it is not possible to tell if we are waiting on the
	#   network to complete handshake packets, or for the application layer
	#   to accept the connection.
	#
	# - For connections on the "server" side (accepted through listen socket):
	#   We have completed some basic handshake and the client has presented
	#   some proof of identity.  The connection is ready to be accepted
	#   using AcceptConnection().
	#
	# In either case, any unreliable packets sent now are almost certain
	# to be dropped.  Attempts to receive packets are guaranteed to fail.
	# You may send messages if the send mode allows for them to be queued.
	# but if you close the connection before the connection is actually
	# established, any queued messages will be discarded immediately.
	# (We will not attempt to flush the queue and confirm delivery to the
	# remote host, which ordinarily happens when a connection is closed.)
	CONNECTING = 1,

	# Some connection types use a back channel or trusted 3rd party
	# for earliest communication.  If the server accepts the connection,
	# then these connections switch into the rendezvous state.  During this
	# state, we still have not yet established an end-to-end route (through
	# the relay network), and so if you send any messages unreliable, they
	# are going to be discarded.
	FINDING_ROUTE = 2,

	# We've received communications from our peer (and we know
	# who they are) and are all good.  If you close the connection now,
	# we will make our best effort to flush out any reliable sent data that
	# has not been acknowledged by the peer.  (But note that this happens
	# from within the application process, so unlike a TCP connection, you are
	# not totally handing it off to the operating system to deal with it.)
	CONNECTED = 3,

	# Connection has been closed by our peer, but not closed locally.
	# The connection still exists from an API perspective.  You must close the
	# handle to free up resources.  If there are any messages in the inbound queue,
	# you may retrieve them.  Otherwise, nothing may be done with the connection
	# except to close it.
	#
	# This stats is similar to CLOSE_WAIT in the TCP state machine.
	CLOSED_BY_PEER = 4,

	# A disruption in the connection has been detected locally.  (E.g. timeout,
	# local internet connection disrupted, etc.)
	#
	# The connection still exists from an API perspective.  You must close the
	# handle to free up resources.
	#
	# Attempts to send further messages will fail.  Any remaining received messages
	# in the queue are available.
	PROBLEM_DETECTED_LOCALLY = 5,
}


# NOTE: EOS only supports UNRELIABLE = 0, RELIABLE_UNORDERED = 1, and RELIABLE_ORDERED = 2
enum Send {
	UNRELIABLE = 0,
	# Send the message unreliably. Can be lost. Messages *can* be larger than a single MTU (UDP packet),
	# but there is no retransmission, so if any piece of the message is lost,
	# the entire message will be dropped. The sending API does have some knowledge of the underlying connection,
	# so if there is no NAT-traversal accomplished or there is a recognized adjustment happening on the connection,
	# the packet will be batched until the connection is open again.
	
	# Migration note: This is not exactly the same as k_EP2PSendUnreliable! You probably want k_ESteamNetworkingSendType_UnreliableNoNagle
	
	NO_NAGLE = 1,
	# Disable Nagle's algorithm.
	
	# By default, Nagle's algorithm is applied to all outbound messages.
	# This means that the message will NOT be sent immediately,
	# in case further messages are sent soon after you send this,
	# which can be grouped together. Any time there is enough buffered data to fill a packet,
	# the packets will be pushed out immediately, but partially-full packets not be sent until the Nagle timer expires.
	# See Steam.FlushMessagesOnConnection(), Steam.FlushMessagesToUser()
	
	# NOTE: Don't just send every message without Nagle because you want packets to "get there quicker".
	# Make sure you understand the problem that Nagle is solving before disabling it.
	# If you are sending small messages, often many at the same time,
	# then it is very likely that it will be more efficient to leave Nagle enabled.
	# A typical proper use of this flag is when you are sending what you know will be the last message sent for a while
	# (e.g. the last in the server simulation tick to a particular client), and you use this flag to flush all messages.
	
	UNRELIABLE_NO_NAGLE = 0|1,
	# Send a message unreliably, bypassing Nagle's algorithm for this message
	# and any messages currently pending on the Nagle timer.
	# This is equivalent to using UNRELIABLE and then immediately flushing the messages
	# using Steam.FlushMessagesOnConnection() or Steam.FlushMessagesToUser().
	# (But using this flag is more efficient since you only make one API call.)
	
	NO_DELAY = 4,
	# If the message cannot be sent very soon (because the connection is still doing some initial handshaking, route negotiations, etc),
	# then just drop it. This is only applicable for unreliable messages.
	# Using this flag on reliable messages is invalid.
	
	UNRELIABLE_NO_DELAY = 0|4|1,
	# Send an unreliable message, but if it cannot be sent relatively quickly,
	# just drop it instead of queuing it. This is useful for messages that are
	# not useful if they are excessively delayed, such as voice data.
	
	# A message will be dropped under the following circumstances:
	# - the connection is not fully connected. (E.g. the "Connecting" or "FindingRoute" states)
	# - there is a sufficiently large number of messages queued up already such that
	#	the current message will not be placed on the wire in the next ~200ms or so.
	
	# If a message is dropped for these reasons, k_EResultIgnored will be returned.
	
	# NOTE: The Nagle algorithm is not used, and if the message is not dropped,
	# any messages waiting on the Nagle timer are immediately flushed.
	
	RELIABLE = 8,
	# Reliable message send. Can send up to k_cbMaxSteamNetworkingSocketsMessageSizeSend bytes in a single message.
	# Does fragmentation/re-assembly of messages under the hood, as well as a sliding window for efficient sends of large chunks of data.
	
	# The Nagle algorithm is used. See notes on UNRELIABLE for more details.
	# See RELIABLE_NO_NAGLE, Steam.FlushMessagesOnConnection(), Steam.FlushMessagesToUser()
	
	# Migration note: This is NOT the same as k_EP2PSendReliable, it's more like k_EP2PSendReliableWithBuffering
	
	RELIABLE_NO_NAGLE = 8|1,
	# Send a message reliably, but bypass Nagle's algorithm.
	
	# Migration note: This is equivalent to k_EP2PSendReliable
}


enum DisconnectReason {
	CLIENT_KICKED,
	SERVER_FULL,
	CLIENT_DISCONNECT,
}


enum Status {
	CLIENT_NOT_CONNECTED,
	CLIENT_CONNECTED_PENDING_AUTH,
	CLIENT_CONNECTED_AND_AUTHENTICATED,
}


enum NetworkConnection {
	INVALID = -1
}


enum Result {
	OK = 1,
}


var API := NONE


# Initialize our online API
static func init() -> bool:
	if Steam.steamInit()["status"] == Result.OK:
		Online.API = STEAM
		connect_client_signals()
		connect_server_signals()
		connect_lobby_signals()
		return true
	return false


static func connect_client_signals() -> void:
	if Online.API == STEAM:
		# Utility
		Steam.connect("steam_shutdown", Online, "_on_steam_shutdown")
		
		# Lobby
		Steam.connect("lobby_joined", Online, "_on_steam_lobby_entered")
		Steam.connect("join_requested", Online, "_on_steam_lobby_join_requested")


static func connect_server_signals() -> void:
	if Online.API == STEAM:
		Steam.connect("network_messages_session_request", Online, "_on_steam_network_messages_session_request")


static func connect_lobby_signals() -> void:
	if Online.API == STEAM:
		Steam.connect("lobby_chat_update", Online, "_on_steam_lobby_chat_update")
		Steam.connect("lobby_message", Online, "_on_steam_lobby_message")
		Steam.connect("lobby_created", Online, "_on_steam_lobby_created")
		Steam.connect("lobby_data_update", Online, "_on_steam_lobby_data_update")


# Run our API callbacks
static func run_callbacks() -> void:
	if Online.API == STEAM:
		Steam.run_callbacks()


# NETWORKING MESSAGES ##########################################################


static func send_message_to_user(online_id: int, message: PoolByteArray, flags: int, channel: int) -> int:
	if Online.API == STEAM:
		# Sends a message to the specified host. If we don't already have a session with that user,
		# a session is implicitly created. There might be some handshaking that needs to happen before
		# we can actually begin sending message data. If this handshaking fails and we can't get through,
		# an error will be posted via the callback SteamNetworkingMessagesSessionFailed_t.
		# There is no notification when the operation succeeds. (We should have the peer send a reply for this purpose.)
		
		# Sending a message to a host will also implicitly accept any incoming connection from that host.
		
		# `flags` is a bitmask of k_nSteamNetworkingSend_xxx options
		
		# `channel` is a routing number we can use to help route message to different systems.
		# We'll have to call ReceiveMessagesOnChannel with the same channel number in order to
		# retrieve the data on the other end.
		
		# Using different channels to talk to the same user will still use the same underlying connection,
		# saving on resources. If we don't need this feature, use 0. Otherwise, small integers are the most efficient.
		
		# It is guaranteed that reliable messages to the same host on the same channel will be be received
		# by the remote host (if they are received at all) exactly once, and in the same order that they were sent.
		
		# NO other order guarantees exist! In particular, unreliable messages may be dropped,
		# received out of order with respect to each other and with respect to reliable data,
		# or may be received multiple times. Messages on different channels are *not* guaranteed to be received
		# in the order they were sent.
		
		# A note for those familiar with TCP/IP ports, or converting an existing codebase that opened multiple sockets:
		# We might notice that there is only one channel, and with TCP/IP each endpoint has a port number.
		# We can think of the channel number as the destination port. If we need each message to also include a source port
		# (so the recipient can route the reply), then just put that in our message. That is essentially how UDP works!
		
		# Returns:
		# 	k_EResultOK on success.
		# 	k_EResultNoConnection will be returned if the session has failed or was closed by the peer,
		# 		and k_nSteamNetworkingSend_AutoRestartBrokenSession is not used.
		# 		(We can use GetSessionConnectionInfo to get the details.)
		#		In order to acknowledge the broken session and start a new one, we must call CloseSessionWithUser
		#	See ISteamNetworkingSockets::SendMessageToConnection for more possible return values.
		return Steam.sendMessageToUser("steamid:" + str(online_id), message, flags, channel)
	return 0


static func receive_messages_on_channel(channel: int, max_messages: int) -> Array:
	if Online.API == STEAM:
		# Returns an array of these dictionaries:
		# {"payload": data, "size": message_size, "identity", "user_data": channel_messages[i].m_nConnUserData,
		#	"time_received", "message_number", "channel", "flags"}
		return Steam.receiveMessagesOnChannel(channel, max_messages)
	return []


static func accept_session_with_user(online_id: int) -> bool:
	if Online.API == STEAM:
		# Call this in response to a SteamNetworkingMessagesSessionRequest_t callback.
		# SteamNetworkingMessagesSessionRequest_t are posted when a user tries to send we a message,
		# and we haven't tried to talk to them first. If we don't want to talk to them, just ignore the request.
		# If the user continues to send we messages, SteamNetworkingMessagesSessionRequest_t callbacks will
		# continue to be posted periodically.
		
		# Returns false if there is no session with the user pending or otherwise.
		# If there is an existing active session, this function will return true, even if it is not pending.
		
		# Calling SendMessageToUser will implicitly accepts any pending session request to that user.
		return Steam.acceptSessionWithUser("steamid:" + str(online_id))
	return false


static func close_session_with_user(reference_name: String) -> bool:
	if Online.API == STEAM:
		# Call this when we're done talking to a user to immediately free up resources under-the-hood.
		# If the remote user tries to send data to us again,
		# another SteamNetworkingMessagesSessionRequest_t callback will be posted.
		
		# Note that sessions that go unused for a few minutes are automatically timed out.
		return Steam.closeSessionWithUser(reference_name)
	return false


static func close_channel_with_user(reference_name: String, channel: int) -> bool:
	if Online.API == STEAM:
		return Steam.closeChannelWithUser(reference_name, channel)
	return false


signal session_request


func _on_steam_network_messages_session_request(identity: String) -> void:
	emit_signal("session_request", identity)


# NETWORKING TYPES #############################################################


static func add_identity(online_id: int) -> bool:
	if Online.API == STEAM:
		return Steam.addIdentity("steamid:" + str(online_id))
	return false


static func clear_identity(online_id: int) -> void:
	if Online.API == STEAM:
		Steam.clearIdentity("steamid:" + str(online_id))


static func get_identities() -> Array:
	if Online.API == STEAM:
		return Steam.getIdentities()
	return []


static func is_identity_invalid(online_id: int) -> bool:
	if Online.API == STEAM:
		return Steam.isIdentityInvalid("steamid:" + str(online_id))
	return true


static func set_identity_id(id: int, bit_64 := true) -> void:
	if Online.API == STEAM:
		if !bit_64:
			Steam.setIdentitySteamID("steamid:" + str(id), id)
		else:
			Steam.setIdentitySteamID64("steamid:" + str(id), id)


static func get_identity_id(identity: String, bit_64 := true) -> int:
	if Online.API == STEAM:
		if !bit_64:
			return Steam.getIdentitySteamID(identity)
		else:
			return Steam.getIdentitySteamID64(identity)
	return 0


# LOBBY ########################################################################


enum LobbyType {
	PRIVATE,
	FRIENDS_ONLY,
	PUBLIC,
	INVISIBLE,
}


static func create_lobby(lobby_type: int, max_players: int) -> void:
	if Online.API == STEAM:
		Steam.createLobby(lobby_type, max_players)
#		if lobby_type == Online.LobbyType.PUBLIC:
#			Steam.createLobby(SteamAPI.LobbyType.PUBLIC, max_players)
#		elif lobby_type == Online.LobbyType.PRIVATE:
#			Steam.createLobby(SteamAPI.LobbyType.PRIVATE, max_players)
#		elif lobby_type == Online.LobbyType.FRIENDS_ONLY:
#			Steam.createLobby(SteamAPI.LobbyType.FRIENDS_ONLY, max_players)
#		elif lobby_type == Online.LobbyType.INVISIBLE:
#			Steam.createLobby(SteamAPI.LobbyType.INVISIBLE, max_players)


# Join the requested lobby.
static func join_lobby(lobby_id: int) -> void:
	if Online.API == STEAM:
		Steam.joinLobby(lobby_id)


# Leave the requested lobby.
static func leave_lobby(lobby_id: int) -> void:
	if Online.API == STEAM:
		Steam.leaveLobby(lobby_id)


# Gets per-user metadata for someone in this lobby.
static func get_lobby_member_data(lobby_id: int, online_id: int, key: String) -> String:
	if Online.API == STEAM:
		return Steam.getLobbyMemberData(lobby_id, online_id, key)
	return ""


# Sets lobby data for myself.
static func set_lobby_member_data(lobby_id: int, key: String, value: String) -> void:
	if Online.API == STEAM:
		Steam.setLobbyMemberData(lobby_id, key, value)


static func get_lobby_member_by_index(lobby_id: int, index: int) -> int:
	if Online.API == STEAM:
		# MUST call get_num_lobby_members() first!
		return Steam.getLobbyMemberByIndex(lobby_id, index)
	return 0


static func get_num_lobby_members(lobby_id: int) -> int:
	if lobby_id == 0:
		return 1
	if Online.API == STEAM:
		return Steam.getNumLobbyMembers(lobby_id)
	return 1


# Returns 0 if no limit is defined.
static func get_lobby_member_limit(lobby_id: int) -> int:
	if Online.API == STEAM:
		return Steam.getLobbyMemberLimit(lobby_id)
	return 0


static func set_lobby_member_limit(lobby_id: int, max_members: int) -> bool:
	if Online.API == STEAM:
		return Steam.setLobbyMemberLimit(lobby_id, max_members)
	return false


static func get_lobby_data(lobby_id: int, key: String) -> String:
	if Online.API == STEAM:
		return Steam.getLobbyData(lobby_id, key)
	return ""


static func set_lobby_data(lobby_id: int, key: String, value: String) -> void:
	if Online.API == STEAM:
		Steam.setLobbyData(lobby_id, key, value)


static func delete_lobby_data(lobby_id: int, key: String) -> bool:
	if Online.API == STEAM:
		return Steam.deleteLobbyData(lobby_id, key)
	return false


static func get_lobby_owner(lobby_id: int) -> int:
	if Online.API == STEAM:
		return Steam.getLobbyOwner(lobby_id)
	return 0


static func set_lobby_owner(lobby_id: int, online_id: int) -> bool:
	if Online.API == STEAM:
		return Steam.setLobbyOwner(lobby_id, online_id)
	return false


static func send_lobby_chat_msg(lobby_id: int, message: String) -> void:
	if Online.API == STEAM:
		Steam.sendLobbyChatMsg(lobby_id, message)


static func activate_invite_dialog(lobby_id: int) -> void:
	if Online.API == STEAM:
		Steam.activateGameOverlayInviteDialog(lobby_id)


signal lobby_created
signal lobby_entered
signal lobby_data_update
signal lobby_chat_update
signal lobby_message
signal lobby_join_requested


# Flags describing how a users lobby state has changed. This is provided from lobby_chat_update.
enum ChatMemberStateChange {
	ENTERED = 1,
	LEFT = 2,
	DISCONNECTED = 4,
	KICKED = 8,
	BANNED = 10,
}


func _on_steam_lobby_created(result: int, lobby_id: int) -> void:
	emit_signal("lobby_created", result, lobby_id)


func _on_steam_lobby_entered(lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response == 1: # Success. Response == 5 if somehow failed
		emit_signal("lobby_entered", lobby_id)


# If `member_id` is a user in the lobby, then use get_lobby_member_data() to access per-user details.
# otherwise, if `member_id` == lobby_id, use get_lobby_data() to access the lobby metadata.
func _on_steam_lobby_data_update(lobby_id: int, member_id: int, success: bool) -> void:
	if success:
		emit_signal("lobby_data_update", lobby_id, member_id)


# A lobby chat room state has changed, this is usually sent when a user has joined or left the lobby.
func _on_steam_lobby_chat_update(lobby_id: int, changed_id: int, _making_change_id: int, chat_state: int) -> void:
	emit_signal("lobby_chat_update", lobby_id, changed_id, chat_state)


func _on_steam_lobby_message(lobby_id: int, sender_id: int, msg: String, chat_type: int) -> void:
	emit_signal("lobby_message", lobby_id, sender_id, msg, chat_type)


func _on_steam_lobby_join_requested(lobby_id: int, friend_id: int) -> void:
	emit_signal("lobby_join_requested", lobby_id, friend_id)


# NETWORKING SOCKETS ###########################################################


static func init_authentication() -> int:
	if Online.API == STEAM:
		return Steam.initAuthentication()
	return 0


# If we know that we are going to be using the relay network (for example, because we anticipate
# making P2P connections), call this to initialize the relay network. If we do not call this, the
# initialization will be delayed until the first time we use a feature that requires access to the
# relay network, which will delay that first access.
#
# We can also call this to force a retry if the previous attempt has failed. Performing any action
# that requires access to the relay network will also trigger a retry, and so calling this function
# is never strictly necessary, but it can be useful to call it a program launch time, if access to
# the relay network is anticipated. Use GetRelayNetworkStatus or listen for SteamRelayNetworkStatus_t
# callbacks to know when initialization has completed. Typically initialization completes in a few seconds.
#
# Note: dedicated servers hosted in known data centers do *not* need to call this, since they do not
# make routing decisions. However, if the dedicated server will be using P2P functionality, it will
# act as a "client" and this should be called.
static func init_relay_network_access() -> void:
	if Online.API == STEAM:
		Steam.initRelayNetworkAccess()


# Creates a "server" socket that listens for clients connecting via ConnectP2P. The connection will
# be relayed through the Valve network.
# `port` specifies how clients can connect to this socket using ConnectP2P. It's very common for
# applications to only have one listening socket; in that case, use zero. If we need to open multiple
# listen sockets and have clients be able to connect to one or the other, then `port` should be a
# small integer (<1000) unique to each listen socket we create.
# If we use this, we probably want to call init_relay_network_access() when our app initializes.

# TODO: Fill out array options!
static func create_listen_socket_p2p(port: int) -> int:
	if Online.API == STEAM:
		return Steam.createListenSocketP2P(port, [])
	return 0


# Destroy a listen socket. All the connections that were accepted on the listen socket are closed ungracefully.
static func close_listen_socket(socket: int) -> bool:
	if Online.API == STEAM:
		return Steam.closeListenSocket(socket)
	return false


# A poll group is a set of connections that can be polled efficiently.
# (In this API, to "poll" a connection means to retrieve all pending messages.
# We actually don't have an API to "poll" the connection state, like BSD sockets).
static func create_poll_group() -> int:
	if Online.API == STEAM:
		return Steam.createPollGroup()
	return 0


# Destroy a poll group created with create_poll_group.
# If there are any connections in the poll group, they are removed from the group, and left in a
# state where they are not part of any poll group. Returns false if passed an invalid poll group handle.
static func destroy_poll_group(poll_group: int) -> bool:
	if Online.API == STEAM:
		return Steam.destroyPollGroup(poll_group)
	return false


static func receive_messages_on_poll_group(poll_group: int, num_messages: int) -> Array:
	if Online.API == STEAM:
		return Steam.receiveMessagesOnPollGroup(poll_group, num_messages)
	return []


# Accept an incoming connection that has been received on a listen socket.
static func accept_connection(connection: int) -> int:
	if Online.API == STEAM:
		return Steam.acceptConnection(connection)
	return 0


# Disconnects from the remote host and invalidates the connection handle.
# Any unread data on the connection is discarded.
static func close_connection(peer: int, reason: int, message: String, linger := false) -> bool:
	if Online.API == STEAM:
		return Steam.closeConnection(peer, reason, message, linger)
	return false


# Assign a connection to a poll group. Note that a connection may only belong to a single poll group.
# Adding a connection to a poll group implicitly removes it from any other poll group it is in.
static func set_connection_poll_group(connection: int, poll_group: int) -> bool:
	if Online.API == STEAM:
		return Steam.setConnectionPollGroup(connection, poll_group)
	return false


static func send_message_to_connection(connection: int, message: PoolByteArray, flags: int) -> Dictionary:
	if Online.API == STEAM:
		return Steam.sendMessageToConnection(connection, message, flags)
	return {}


# UTILITY ######################################################################


signal online_api_shutdown


func _on_steam_shutdown() -> void:
	emit_signal("online_api_shutdown")


func get_online_id() -> int:
	if Online.API == STEAM:
		return Steam.getSteamID()
	return 0


# FRIENDS ######################################################################


func get_friend_persona_name(online_id: int) -> String:
	if Online.API == STEAM:
		return Steam.getFriendPersonaName(online_id)
	return "Me (Offline)"
