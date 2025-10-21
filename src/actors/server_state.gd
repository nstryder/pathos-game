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
	await Utils.sleep(1)
	# At this point, assume game state is synced and ready to start
	start_game()


func start_game() -> void:
	if multiplayer.is_server():
		start_timeline()

# TODO
func start_timeline() -> void:
	while true:
		combat_manager.current_phase = Timeline.PLAYER1_OFFENSE
		await execute_offense_phase(player1, player2)
		
		if not combat_manager.skip_was_declared():
			combat_manager.current_phase = Timeline.PLAYER2_DEFENSE
			await execute_defense_phase()
			await execute_combat_phase()

		if player1.hp <= 0 or player2.hp <= 0:
			break
		
		combat_manager.current_phase = Timeline.PLAYER2_OFFENSE
		await execute_offense_phase(player2, player1)

		if not combat_manager.skip_was_declared():
			combat_manager.current_phase = Timeline.PLAYER1_DEFENSE
			await execute_defense_phase()
			await execute_combat_phase()
		
		if player1.hp <= 0 or player2.hp <= 0:
			break


func execute_offense_phase(attacker: Player, defender: Player) -> void:
	combat_manager.turn_count += 1
	if combat_manager.turn_count > 1:
		attacker.draw_effects()
	combat_manager.attacking_player = attacker
	combat_manager.defending_player = defender
	client.start_client_offense.rpc_id(attacker.id)
	client.wait_for_offense.rpc_id(defender.id)
	await attack_declared


func execute_defense_phase() -> void:
	client.start_client_defense.rpc_id(combat_manager.defending_player.id)
	await defense_declared


func execute_combat_phase() -> void:
	combat_manager.current_phase = Timeline.COMBAT
	combat_manager.start_combat()
	client.visualize_combat.rpc()
	await Utils.sleep(3)


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
