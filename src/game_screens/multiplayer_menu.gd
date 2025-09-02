extends CenterContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)

	if OS.has_feature("debug"):
		var args = OS.get_cmdline_args()
		var is_server = "server" in args
		if is_server:
			get_window().title = "Pathos Server"
			_on_host_button_pressed()
		else:
			_on_join_button_pressed()


func status_out(text) -> void:
	$%StatusLabel.text = str(text)


@rpc("authority", "reliable", "call_local")
func start_game():
	status_out("Let's do this: " + str(multiplayer.get_unique_id()))
	await get_tree().create_timer(1).timeout
	# get_tree().change_scene_to_file("res://src/game_screens/battle_screen.tscn")
	get_tree().change_scene_to_file("res://workspace/multiplayer_testing_ground.tscn")


func _on_host_button_pressed():
	var port := $%HostPort.value as int
	var peer := ENetMultiplayerPeer.new()
	var error = peer.create_server(port, Constants.MAX_CLIENTS)
	if error:
		status_out(error)
		return
	status_out("Hosting on " + str(port))
	multiplayer.multiplayer_peer = peer


func _on_join_button_pressed():
	var address: String = $%JoinAddress.text
	var port := $%JoinPort.value as int
	print("Joining on ", address, " on port ", port)
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, port)
	if error:
		status_out(error)
		return
	multiplayer.multiplayer_peer = peer
	peer.get_peer(1).set_timeout(0, 0, 2000)
	status_out("Joining...")


func _on_peer_connected(_id):
	if multiplayer.is_server():
		status_out("Client connected.")
		start_game.rpc()

	
func _on_connected_ok():
	print("Connected ok")
	status_out("We are connected!")


func _on_connected_fail():
	multiplayer.multiplayer_peer = null
	print("connected fail")
	status_out("Failed to connect to server.")
