extends Node2D
class_name ClientState


var controlled_player: Player
var opposing_player: Player

var is_attacker: bool = false

@onready var your_side: PlayerSide = %YourSide
@onready var your_hp_label: Label = %YourHPLabel
@onready var opp_side: PlayerSide = %OppSide
@onready var opp_hp_label: Label = %OppHPLabel

@onready var button_undo: Button = %UndoButton
@onready var button_end: Button = %EndTurnButton
@onready var button_rescind_attack: Button = %RescindButton
@onready var card_manager: CardManager = %CardManager
@onready var combat_manager: CombatManager = %CombatManager
@onready var attack_indicator: Line2D = %AttackIndicator

@onready var server: ServerState = %ServerState
@onready var server_state_syncer: MultiplayerSynchronizer = %ServerStateSynchronizer
@onready var timeline: Timeline = %Timeline


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	button_undo.hide()
	button_rescind_attack.hide()
	button_undo.pressed.connect(undo_action)
	button_end.pressed.connect(end_turn)
	button_rescind_attack.pressed.connect(rescind_attack)
	combat_manager.attack_declared.connect(_on_attack_declared)
	combat_manager.attack_rescinded.connect(_on_attack_rescinded)
	set_status('')


func client_sync_player_state() -> void:
	if not multiplayer.is_server():
		await controlled_player.syncer.delta_synchronized


func client_sync_server_state() -> void:
	if not multiplayer.is_server():
		await server_state_syncer.delta_synchronized


func start_turn() -> void:
	set_status('')


@rpc("authority", "call_local", "reliable")
func wait_for_offense() -> void:
	sync_opponent()
	wait_for_turn()


func wait_for_turn() -> void:
	set_status("Waiting for opponent's action...")
	card_manager.dragging_enabled = false
	card_manager.attacking_enabled = false
	button_end.hide()
	button_undo.hide()


func sync_opponent() -> void:
	opp_side.realize_effect_state()


func set_status(text: String) -> void:
	(%StatusLabel as Label).text = text


func show_attack_indicator(from: Vector2, to: Vector2) -> void:
	attack_indicator.show()
	attack_indicator.set_point_position(0, from)
	attack_indicator.set_point_position(1, to)
	print(from, " | ", to)


@rpc("authority", "call_local", "reliable")
func visualize_combat() -> void:
	# await client_sync_server_state()
	# set_status("Resolving Combat")
	# var attacking_player: Player
	# var target_entity_slots: EntitySlotMarkers
	# if is_attacker:
	# 	attacking_player = controlled_player
	# 	target_entity_slots = opp_side.entity_slot_markers
	# else:
	# 	attacking_player = opposing_player
	# 	target_entity_slots = your_side.entity_slot_markers
	# # var attacking_entity: EntityCard = attacking_player.get_entity_card_at_slot(combat_manager.declared_attacker_slot)
	# # var target_position: Vector2 = target_entity_slots.get_position_at_slot(combat_manager.declared_target_slot)
	# var tween := create_tween() \
	# 	.set_ease(Tween.EASE_OUT) \
	# 	.set_trans(Tween.TRANS_QUAD)
	# # var original_position: Vector2 = attacking_entity.global_position
	# # tween.tween_property(attacking_entity, "global_position", target_position, 0.1)
	# # tween.tween_property(attacking_entity, "global_position", original_position, 0.1)
	# await tween.finished
	# attack_indicator.hide()
	# await Utils.sleep(1)
	# place_entities_on_field()
	# check_endgame()
	pass


func check_endgame() -> void:
	if server.player1.hp <= 0 or server.player2.hp <= 0:
		card_manager.dragging_enabled = false
		card_manager.attacking_enabled = false
		if controlled_player.hp <= 0:
			set_status('YOU LOSE. GAME OVER.')
		else:
			set_status('YOU WIN!')


@rpc("authority", "call_local", "reliable")
func start_client_offense() -> void:
	await client_sync_server_state()
	start_turn()
	is_attacker = true
	card_manager.dragging_enabled = true
	card_manager.attacking_enabled = true
	button_undo.hide()
	your_side.realize_effect_state()


func end_client_offense() -> void:
	button_undo.hide()
	wait_for_turn()


@rpc("authority", "call_local", "reliable")
func start_client_defense() -> void:
	await client_sync_server_state()
	start_turn()
	is_attacker = false
	card_manager.dragging_enabled = true
	card_manager.attacking_enabled = false
	# show_attack_indicator_via_players(
	# 	opp_side.entity_slot_markers,
	# 	your_side.entity_slot_markers,
	# 	combat_manager.declared_attacker_slot,
	# 	combat_manager.declared_target_slot,
	# )
	button_undo.hide()
	opp_side.realize_effect_state()
	reveal_attacking_entity()
	

func end_client_defense() -> void:
	button_undo.hide()
	wait_for_turn()


#region Player Actions
# TODO: Update
func declare_attack(attacker: EntityCard, target: EntityCard) -> void:
	server.send_attack.rpc_id(1, attacker.current_idx, target.current_idx)
	button_rescind_attack.show()


func rescind_attack() -> void:
	server.rescind_attack.rpc_id(1)
	button_rescind_attack.hide()


func attach_effect_to_entity(effect: EffectCard, entity: EntityCard) -> void:
	# Must break up variables into non-object variants for RPC
	assert(effect.data.usage_type == EffectCardData.UsageType.ATTACH, "Attach was attempted on a non-attach FX")
	var players: Node2D = %Players
	var owner_player_path: NodePath = players.get_path_to(effect.player)
	var effect_idx: int = effect.current_idx
	var entity_idx: int = entity.current_idx
	var target_player_path: NodePath = players.get_path_to(entity.player)
	timeline.register_effect_attachment.rpc(owner_player_path, effect_idx, target_player_path, entity_idx)


func use_effect(effect: EffectCard) -> void:
	assert(effect.data.usage_type == EffectCardData.UsageType.USE, "Use was attempted on a non-use FX")
	var players: Node2D = %Players
	var owner_player_path: NodePath = players.get_path_to(effect.player)
	var effect_idx: int = effect.current_idx
	timeline.register_effect_use.rpc(owner_player_path, effect_idx)
	

func undo_action() -> void:
	timeline.undo.rpc()


# TODO
func end_turn() -> void:
	server.request_end_turn.rpc_id(1)
	wait_for_turn()


#endregion


func reveal_attacking_entity() -> void:
	var attacker: EntityCard = combat_manager.get_current_attacker()
	attacker.is_veiled = false


func update_hp_label(new_hp: int, target_label: Label) -> void:
	target_label.text = str(new_hp)


func place_entities_on_field() -> void:
	your_side.realize_entity_state()
	opp_side.realize_entity_state()


func arrange_attached_effects() -> void:
	const CARD_SPACING = 32
	var attachments: Dictionary[EntityCard, int] = {}

	print(timeline.main_timeline_queue)
	for action in timeline.main_timeline_queue:
		if action.type != EffectCardData.UsageType.ATTACH:
			continue
		# Take the entity from the target
		# Place effect on entity
		var effect_card: EffectCard = action.effect
		var target_entity: EntityCard = action.entity
		if target_entity in attachments:
			attachments[target_entity] += 1
		else:
			attachments[target_entity] = 1
		var offset_idx: int = attachments[target_entity]
		var offset := Vector2(0, CARD_SPACING * (offset_idx))
		effect_card.slot_attachment_effects_enable()
		effect_card.z_index = Constants.MIN_ATTACHMENT_Z_INDEX - (offset_idx)
		effect_card.detectable = false

		var new_pos := target_entity.global_position - offset
		effect_card.global_position = new_pos


@rpc("authority", "call_local", "reliable")
func _finish_client_side_setup() -> void:
	await client_sync_player_state()
	_setup_board()
	place_entities_on_field()


@rpc("authority", "call_local", "reliable")
func _assign_client_player_number(player_number: int) -> void:
	if player_number == 1:
		controlled_player = server.player1
		opposing_player = server.player2
		(%PlayerNumberLabel as Label).text = "You are player 1"
	else:
		controlled_player = server.player2
		opposing_player = server.player1
		(%PlayerNumberLabel as Label).text = "You are player 2"


func _setup_board() -> void:
	your_side.player = controlled_player
	controlled_player.hp_changed.connect(update_hp_label.bind(your_hp_label))
	update_hp_label(controlled_player.hp, your_hp_label)
	
	opp_side.player = opposing_player
	opposing_player.hp_changed.connect(update_hp_label.bind(opp_hp_label))
	update_hp_label(opposing_player.hp, opp_hp_label)


func _on_timeline_timeline_modified() -> void:
	your_side.hand.update_hand_positions()
	opp_side.hand.update_hand_positions()
	arrange_attached_effects()
	if timeline.main_timeline_queue.is_empty():
		button_undo.hide()
	else:
		button_undo.show()


func _on_attack_declared() -> void:
	var attacker: EntityCard = combat_manager.get_current_attacker()
	var target: EntityCard = combat_manager.get_current_target()
	show_attack_indicator(attacker.global_position, target.global_position)


func _on_attack_rescinded() -> void:
	attack_indicator.hide()