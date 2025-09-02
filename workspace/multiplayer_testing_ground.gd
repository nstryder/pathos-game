extends Control

"""
// QUESTIONS
1. What happens when mode is set to "authority" vs "any_peer"?
2. "call_local" vs "call_remote?"

// EXPERIMENTS
- When an authority rpc's a method set to authority + call_local:
	- The method is called on all remote peers
	- call_local also calls it locally
- When a puppet tries to rpc a method set to authority + call_local:
	- The rpc fails to go through on other peers
	- call_local ignores this and calls the method locally still
- When authority rpc_id's itself on a method set to call_remote:
	- Error shows up saying method cannot be called locally
- When authority rpc_id's itself on a method set to call_local:
	- Method is called normally.
	- No duplicate call happens.

// NOTES
- Default rpc parameters: "authority", "call_remote", "unreliable", 0
- authority means only the server can send out an rpc. 
	- if a puppet tries to rpc this method, the rpc does not get sent out.
	- if call_local is on, it still calls the method on itself, but nowhere else.
- any_peer behaves as you'd expect, with no restrictions on who can send out an rpc.
- call_local happens first before rpc
- there are no duplicate calls to worry about. 
	- So call_local shouldn't cause the function to be called twice.
- call_remote PREVENTS a node from rpc'ing itself, even if done explicity with rpc_id
- Under server authorative structure, players should get authority over only one thing: User input. 

// CONCLUSIONS
- RPC mode simply determines if the caller is allowed to signal other peers.
- It does NOT determine WHO receives the rpc call.
- Best to use rpc_id for DIRECTED calls.
- To enforce client/server architecture, you make heavy use of multiplayer.is_server()
	- It is NOT automatically enforced using the rpc mode

// APPLICATIONS
/// Dedicated Server setups
- rpc("authority", "call_remote", "reliable")
	- Server -> All Clients
	- Make sure to check is_server() == true first
	- If client tries to rpc this, it will fail
	- Call only using rpc() so the message can be sent to all clients. 
		- call_remote should prevent local-server-call bugs.
- rpc("any_peer", "call_remote", "reliable")
	- Client -> Server
	- Make sure to check is_server() == false
	- Only call using rpc_id(1) to enforce Client -> Server
	- Useful when ONLY Client needs to message Server one-sidedly
	- If server tries to rpc this to itself, it will fail.

/// Listen Server setups
- rpc("authority", "call_local", "reliable")
	- Server -> All Clients
	- Useful when in a Listen-Server situation, as Server is also a Client.
	- Make sure to check is_server() == true first
	- Call only using rpc() so every peer will run this method, including the server itself.
	- Great for syncing everyone up. 
- rpc("any_peer", "call_local", "reliable")
	- Client -> Server
	- Useful in Listen-Servers, since the "Client" sending stuff to the Server can be itself.
	- Only call using rpc_id(1) to enforce Client -> Server

"""


func _ready() -> void:
	($%BtnTestMode as Button).pressed.connect(_on_test_mode_pressed)
	$%BtnClientToServer.pressed.connect(_on_btn_client_to_server_pressed)
	$%BtnServerToClient.pressed.connect(_on_btn_server_to_client_pressed)


@rpc("any_peer", "call_local", "reliable")
func test_mode():
	print("This func was called by ", multiplayer.get_unique_id())


# Configuration for a client to send data to the server one-sidedly
# and call this using rpc_id(1)
# Need to check NOT is_server before doing rpc_id() to stop error
# Otherwise server can try to call itself which is not allowed
@rpc("any_peer", "call_remote", "reliable")
func test_client_to_server_communication(message: String):
	print("Hello, this is the server. ", message)

# For server to send data to clients
# Can call this using rpc(), just need to check is_server() first before doing rpc() to stop error
@rpc("authority", "call_remote", "reliable")
func test_server_to_client_communication(message: String):
	print("Client here. ", message)


func _on_test_mode_pressed():
	test_mode.rpc()


func _on_btn_client_to_server_pressed():
	if multiplayer.is_server():
		print("Attempted client-exclusive call from server.")
		return
	test_client_to_server_communication.rpc_id(1, "This is a message from a client!")


func _on_btn_server_to_client_pressed():
	if not multiplayer.is_server():
		print("Attempted server-exclusive call from client.")
		return
	test_server_to_client_communication.rpc("This is a message from the server.")