extends Node2D

const DummyNetworkAdaptor = preload("res://addons/delta_rollback/DummyNetworkAdaptor.gd")

@onready var main_menu = $CanvasLayer/MainMenu
@onready var connection_panel = $CanvasLayer/ConnectionPanel
@onready var host_field = $CanvasLayer/ConnectionPanel/VBoxContainer/GridContainer/HostField
@onready var port_field = $CanvasLayer/ConnectionPanel/VBoxContainer/GridContainer/PortField
@onready var message_label = $CanvasLayer/MessageLabel
@onready var sync_lost_label = $CanvasLayer/SyncLostLabel
@onready var reset_button = $CanvasLayer/ResetButton

const LOG_FILE_DIRECTORY = 'user://detailed_logs'

var logging_enabled := false

func _ready() -> void:
	multiplayer.peer_connected.connect(self._on_peer_connected)
	multiplayer.peer_disconnected.connect(self._on_peer_disconnected)
	multiplayer.connected_to_server.connect(self._on_server_connected)
	multiplayer.server_disconnected.connect(self._on_server_disconnected)

	SyncManager.sync_started.connect(self._on_SyncManager_sync_started)
	SyncManager.sync_stopped.connect(self._on_SyncManager_sync_stopped)
	SyncManager.sync_lost.connect(self._on_SyncManager_sync_lost)
	SyncManager.sync_regained.connect(self._on_SyncManager_sync_regained)
	SyncManager.sync_error.connect(self._on_SyncManager_sync_error)

	$ServerPlayer.set_multiplayer_authority(1)
	$ServerPlayer.spawn_parent = $SpawnParent
	$ClientPlayer.spawn_parent = $SpawnParent

	var cmdline_args = OS.get_cmdline_args()
	if "server" in cmdline_args:
		_on_ServerButton_pressed()
	elif "client" in cmdline_args:
		_on_ClientButton_pressed()

	if SyncReplay.active:
		main_menu.visible = false
		connection_panel.visible = false
		reset_button.visible = false

func _on_OnlineButton_pressed() -> void:
	connection_panel.popup_centered()
	SyncManager.reset_network_adaptor()

func _on_LocalButton_pressed() -> void:
	main_menu.visible = false
	$ServerPlayer.input_prefix = "player2_"
	SyncManager.network_adaptor = DummyNetworkAdaptor.new()
	SyncManager.start()

func _on_ServerButton_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(int(port_field.text))
	multiplayer.multiplayer_peer = peer
	print(SyncManager.network_adaptor.get_network_unique_id())
	connection_panel.visible = false
	main_menu.visible = false

func _on_ClientButton_pressed() -> void:
	_start_client()

func _on_SpectatorButton_pressed() -> void:
	_start_client()

func _start_client() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(host_field.text, int(port_field.text))
	multiplayer.multiplayer_peer = peer
	print(SyncManager.network_adaptor.get_network_unique_id())
	connection_panel.visible = false
	main_menu.visible = false
	message_label.text = "Connecting..."

func _on_peer_connected(peer_id: int):
	# Tell sibling peers about ourselves.
	if not multiplayer.is_server() and peer_id != 1:
		register_player.rpc_id(peer_id, {})

func _on_peer_disconnected(peer_id: int):
	var peer = SyncManager.peers.get(peer_id)
	if peer:
		message_label.text = "Disconnected"
	SyncManager.remove_peer(peer_id)

func _on_server_connected() -> void:
	$ClientPlayer.set_multiplayer_authority(multiplayer.get_unique_id())
	SyncManager.add_peer(1)
	# Tell server about ourselves.
	register_player.rpc_id(1, {})

func _on_server_disconnected() -> void:
	_on_peer_disconnected(1)

@rpc("any_peer")
func register_player(options: Dictionary = {}) -> void:
	var peer_id = multiplayer.get_remote_sender_id()
	if not peer_id == SyncManager.network_adaptor.get_network_unique_id():
		SyncManager.add_peer(peer_id)
		var peer = SyncManager.peers[peer_id]

	$ClientPlayer.set_multiplayer_authority(peer_id)

	if multiplayer.is_server():
		multiplayer.multiplayer_peer.refuse_new_connections = true

		message_label.text = "Starting..."
		# Give a little time to get ping data.
		await get_tree().create_timer(2.0).timeout
		SyncManager.start()

func _on_SyncManager_sync_started() -> void:
	message_label.text = "Started!"

	if logging_enabled and not SyncReplay.active:
		if not DirAccess.dir_exists_absolute(LOG_FILE_DIRECTORY):
			DirAccess.make_dir_absolute(LOG_FILE_DIRECTORY)

		var datetime := Time.get_datetime_dict_from_system(true)
		var log_file_name = "%04d%02d%02d-%02d%02d%02d-peer-%d.log" % [
			datetime['year'],
			datetime['month'],
			datetime['day'],
			datetime['hour'],
			datetime['minute'],
			datetime['second'],
			multiplayer.get_unique_id(),
		]

		SyncManager.start_logging(LOG_FILE_DIRECTORY + '/' + log_file_name)

func _on_SyncManager_sync_stopped() -> void:
	if logging_enabled:
		SyncManager.stop_logging()

func _on_SyncManager_sync_lost() -> void:
	sync_lost_label.visible = true

func _on_SyncManager_sync_regained() -> void:
	sync_lost_label.visible = false

func _on_SyncManager_sync_error(msg: String) -> void:
	message_label.text = "Fatal sync error: " + msg
	sync_lost_label.visible = false

	var peer = multiplayer.multiplayer_peer
	if peer:
		peer.close()
	SyncManager.clear_peers()

func _on_ResetButton_pressed() -> void:
	SyncManager.stop()
	SyncManager.clear_peers()
	var peer = multiplayer.multiplayer_peer
	if peer:
		peer.close()
	get_tree().reload_current_scene()

func setup_match_for_replay(my_peer_id: int, peer_ids: Array, _match_info: Dictionary) -> void:
	var client_peer_id: int
	if my_peer_id == 1:
		client_peer_id = peer_ids[0] if len(peer_ids) > 0 else 1
	else:
		client_peer_id = my_peer_id
	$ClientPlayer.set_multiplayer_authority(client_peer_id)

