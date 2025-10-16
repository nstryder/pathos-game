extends Node2D
class_name ServerState

signal attack_declared
signal defense_declared

const Timeline = CombatManager.Timeline

@onready var player1: Player = %Players/Player1
@onready var player2: Player = %Players/Player2

@onready var client: ClientState = %ClientState
@onready var combat_manager: CombatManager = %CombatManager

@onready var battle_screen: BattleScreen = owner


#region SERVER METHODS

func initialize_board() -> void:
	if not multiplayer.is_server():
		return
	_assign_player_ids()
	_setup_player_decks()
	_draw_initial_entities()
	client._finish_client_side_setup.rpc()
	await get_tree().create_timer(1.0).timeout
	# At this point, assume game state is synced and ready to start
	start_game()


func start_game() -> void:
	if multiplayer.is_server():
		start_timeline()

# TODO
func start_timeline() -> void:
	combat_manager.current_phase = Timeline.PLAYER1_OFFENSE
	player1.draw_effects()
	combat_manager.attacking_player = player1
	combat_manager.defending_player = player2
	client.start_client_offense.rpc_id(player1.id)
	client.wait_for_turn.rpc_id(player2.id)
	await attack_declared
	# TODO: Check for skip

	combat_manager.current_phase = Timeline.PLAYER2_DEFENSE
	client.start_client_defense.rpc_id(player2.id)
	await defense_declared
	
	combat_manager.resolve_combat()
		
		# FX cards get drawn if not 1st turn
		# Enable FX cards to be dragged
		# Enable Entities to declare attack
		# await attack declaration
		# - Player sends: FX placed & attack declared (or skip declared)
		# - Advance the timeline
	# For defensive phase:
		# Enable FX cards to be dragged
		# await confirm
		# Player sends: FX placed (or skip declared)
	# Resolve combat
	# Advance turn counter
	# Advance timeline
	# Back to offense


@rpc("any_peer", "call_local", "reliable")
func send_attack(attacker_slot: int, target_slot: int, effect_attachments: Array[Array]) -> void:
	if not multiplayer.is_server():
		return
	print("This is server...", attacker_slot, " ", target_slot, " ", effect_attachments)
	combat_manager.declared_attacker_slot = attacker_slot
	combat_manager.declared_target_slot = target_slot

	if attacker_slot == -1:
		# Skip was declared
		attack_declared.emit()
		return

	combat_manager.attacking_player.merge_effect_attachments(effect_attachments)
	attack_declared.emit()


@rpc("any_peer", "call_local", "reliable")
func send_defense(effect_attachments: Array[Array]) -> void:
	if not multiplayer.is_server():
		return
	print("This is server...", effect_attachments)
	combat_manager.defending_player.merge_effect_attachments(effect_attachments)
	defense_declared.emit()


func _assign_player_ids() -> void:
	# NOTE: get_peers() does NOT include caller's own ID
	# so we need to include it manually (for the server it is 1)
	var peer_ids := [1, multiplayer.get_peers()[0]]
	# peer_ids.shuffle()
	player1.id = peer_ids[0]
	player2.id = peer_ids[1]
	client._assign_client_player_number.rpc_id(player1.id, 1)
	client._assign_client_player_number.rpc_id(player2.id, 2)


func _setup_player_decks() -> void:
	for entity_name in battle_screen.template_entity_deck:
		player1.base_entity_deck.append(CardDb.entity_cards_indexed_by_name[entity_name])
	for effect_name in battle_screen.template_effect_deck:
		player1.base_effect_deck.append(CardDb.effect_cards_indexed_by_name[effect_name])
	player2.base_entity_deck = player1.base_entity_deck.duplicate()
	player2.base_effect_deck = player1.base_effect_deck.duplicate()
	player1.initialize_decks()
	player2.initialize_decks()


func _draw_initial_entities() -> void:
	player1.draw_entities()
	player2.draw_entities()
