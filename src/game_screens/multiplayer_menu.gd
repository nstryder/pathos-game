extends CenterContainer


@onready var lobby: LobbyScreen = owner
@onready var status_label: Label = $%StatusLabel
@onready var host_port_box: SpinBox = $%HostPort
@onready var join_port_box: SpinBox = $%JoinPort
@onready var join_address_box: LineEdit = $%JoinAddress

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)

	if OS.has_feature("debug"):
		var args := OS.get_cmdline_args()
		var is_server := "server" in args
		if is_server:
			get_window().title = "Pathos Server"
			_on_host_button_pressed()
		else:
			_on_join_button_pressed()


func status_out(text: Variant) -> void:
	status_label.text = str(text)


@rpc("authority", "reliable", "call_local")
func start_game() -> void:
	status_out("Let's do this: " + str(multiplayer.get_unique_id()))
	await get_tree().create_timer(1).timeout
	hide()
	if multiplayer.is_server():
		lobby.start_game()


func _on_host_button_pressed() -> void:
	var port := host_port_box.value as int
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, Constants.MAX_CLIENTS)
	if error:
		status_out(error)
		return
	status_out("Hosting on " + str(port))
	multiplayer.multiplayer_peer = peer


func _on_join_button_pressed() -> void:
	var address: String = join_address_box.text
	var port := join_port_box.value as int
	print("Joining on ", address, " on port ", port)
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address, port)
	if error:
		status_out(error)
		return
	multiplayer.multiplayer_peer = peer
	peer.get_peer(1).set_timeout(0, 0, 2000)
	status_out("Joining...")


func _on_peer_connected(_id: int) -> void:
	if multiplayer.is_server():
		status_out("Client connected.")
		start_game.rpc()

	
func _on_connected_ok() -> void:
	print("Connected ok")
	status_out("We are connected!")


func _on_connected_fail() -> void:
	multiplayer.multiplayer_peer = null
	print("connected fail")
	status_out("Failed to connect to server.")
