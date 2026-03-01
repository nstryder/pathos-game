extends Node2D
class_name ServerState

signal turn_ended

const Phases = CombatManager.Phases

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
		execute_phase_flow()


func execute_phase_flow() -> void:
	while true:
		combat_manager.current_phase = Phases.PLAYER1_OFFENSE
		execute_offense_phase(player1, player2)
		await turn_ended

		combat_manager.current_phase = Phases.PLAYER2_DEFENSE
		execute_defense_phase()
		await turn_ended

		await execute_combat_phase()

		if player1.hp <= 0 or player2.hp <= 0:
			break
		
		combat_manager.current_phase = Phases.PLAYER2_OFFENSE
		execute_offense_phase(player2, player1)
		await turn_ended

		combat_manager.current_phase = Phases.PLAYER1_DEFENSE
		execute_defense_phase()
		await turn_ended

		await execute_combat_phase()
		
		if player1.hp <= 0 or player2.hp <= 0:
			break


func execute_offense_phase(attacker: Player, defender: Player) -> void:
	combat_manager.turn_count += 1
	# if combat_manager.turn_count > 1:
	attacker.draw_effects()
	combat_manager.attacking_player_nodepath = attacker.get_path()
	combat_manager.defending_player_nodepath = defender.get_path()
	client.start_client_offense.rpc_id(attacker.id)
	client.wait_for_offense.rpc_id(defender.id)


func execute_defense_phase() -> void:
	client.start_client_defense.rpc_id(combat_manager.defending_player.id)


func execute_combat_phase() -> void:
	combat_manager.current_phase = Phases.COMBAT
	combat_manager.start_combat()
	client.visualize_combat.rpc()
	await Utils.sleep(3)


@rpc("any_peer", "call_local", "reliable")
func request_end_turn() -> void:
	if not multiplayer.is_server():
		return
	turn_ended.emit()
	

@rpc("any_peer", "call_local", "reliable")
func send_attack(attacker_idx: int, target_idx: int) -> void:
	if not multiplayer.is_server():
		return
	print("This is server...", attacker_idx, " ", target_idx)
	combat_manager.declare_attack.rpc(attacker_idx, target_idx)


@rpc("any_peer", "call_local", "reliable")
func rescind_attack() -> void:
	if not multiplayer.is_server():
		return
	combat_manager.rescind_attack.rpc()


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
