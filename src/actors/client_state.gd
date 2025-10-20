extends Node2D
class_name ClientState

const SLOT_COUNT = 3
const CARD_SPACING = 32

var controlled_player: Player
var opposing_player: Player

var is_attacker: bool = false

var queued_effect_attachments: Array[Array] = [[], [], []]
var slot_attachment_history_stack: Array[int] = []

@onready var your_side: PlayerSide = %YourSide
@onready var your_hp_label: Label = %YourHPLabel
@onready var opp_side: PlayerSide = %OppSide
@onready var opp_hp_label: Label = %OppHPLabel

@onready var button_undo: Button = %UndoButton
@onready var button_skip: Button = %SkipButton
@onready var button_confirm: Button = %ConfirmButton
@onready var card_manager: CardManager = %CardManager
@onready var combat_manager: CombatManager = %CombatManager
@onready var attack_indicator: Line2D = %AttackIndicator

@onready var server: ServerState = %ServerState
@onready var server_state_syncer: MultiplayerSynchronizer = %ServerStateSynchronizer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	button_undo.hide()
	button_undo.pressed.connect(undo_attachment)
	button_skip.hide()
	button_skip.pressed.connect(skip_phase)
	button_confirm.hide()
	button_confirm.pressed.connect(declare_defense)
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
func wait_for_turn() -> void:
	set_status("Waiting for opponent's action...")
	card_manager.dragging_enabled = false
	card_manager.attacking_enabled = false


func set_status(text: String) -> void:
	(%StatusLabel as Label).text = text


func show_attack_indicator(from: Vector2, to: Vector2) -> void:
	attack_indicator.show()
	attack_indicator.set_point_position(0, from)
	attack_indicator.set_point_position(1, to)


func show_attack_indicator_via_players(attacker_player: Player, target_player: Player, attacker_slot: int, target_slot: int) -> void:
	var attacker_pos := attacker_player.get_entity_card_at_slot(attacker_slot).global_position
	var target_pos := target_player.get_entity_card_at_slot(target_slot).global_position
	show_attack_indicator(attacker_pos, target_pos)


# TODO
@rpc("authority", "call_local", "reliable")
func visualize_combat() -> void:
	await client_sync_server_state()
	set_status("Resolving Combat")
	var attacking_player: Player
	var target_entity_slots: EntitySlotMarkers
	if is_attacker:
		attacking_player = controlled_player
		target_entity_slots = opp_side.entity_slot_markers
	else:
		attacking_player = opposing_player
		target_entity_slots = your_side.entity_slot_markers
		
	var attacking_entity: EntityCard = attacking_player.get_entity_card_at_slot(combat_manager.declared_attacker_slot)
	var target_position: Vector2 = target_entity_slots.get_position_at_slot(combat_manager.declared_target_slot)
	var tween := create_tween() \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_QUAD)

	var original_position: Vector2 = attacking_entity.global_position
	tween.tween_property(attacking_entity, "global_position", target_position, 0.1)
	tween.tween_property(attacking_entity, "global_position", original_position, 0.1)
	await tween.finished
	attack_indicator.hide()
	await Utils.sleep(1)
	place_entities_on_field()
	check_endgame()


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
	button_skip.show()
	button_undo.hide()
	reset_queued_attachments()
	your_side.realize_effect_state()


func end_client_offense() -> void:
	reset_queued_attachments()
	button_skip.hide()
	button_undo.hide()
	wait_for_turn()


@rpc("authority", "call_local", "reliable")
func start_client_defense() -> void:
	await client_sync_server_state()
	start_turn()
	is_attacker = false
	card_manager.dragging_enabled = true
	card_manager.attacking_enabled = false
	show_attack_indicator_via_players(
		opposing_player,
		controlled_player,
		combat_manager.declared_attacker_slot,
		combat_manager.declared_target_slot
	)
	arrange_attached_effects(opposing_player, opposing_player.attached_effects)
	button_skip.show()
	button_undo.hide()
	button_confirm.hide()
	reset_queued_attachments()
	

func end_client_defense() -> void:
	reset_queued_attachments()
	button_skip.hide()
	button_undo.hide()
	button_confirm.hide()
	wait_for_turn()


func declare_attack(attacker_slot: int, target_slot: int) -> void:
	server.send_attack.rpc_id(1, attacker_slot, target_slot, queued_effect_attachments)
	if attacker_slot != -1:
		show_attack_indicator_via_players(controlled_player, opposing_player, attacker_slot, target_slot)
	end_client_offense()


func declare_defense() -> void:
	server.send_defense.rpc_id(1, queued_effect_attachments)
	end_client_defense()


func skip_phase() -> void:
	if combat_manager.phase_is_offense():
		declare_attack(-1, -1)
	else:
		declare_defense()


func reset_queued_attachments() -> void:
	queued_effect_attachments = [[], [], []]
	slot_attachment_history_stack = []


func attach_effect_to_entity_at_slot(effect_idx: int, entity_slot: int) -> void:
	var effect_card: EffectCard = controlled_player.get_effect_card_at_index(effect_idx)
	your_side.hand.remove_card_from_hand(effect_card)
	queued_effect_attachments[entity_slot].append(effect_idx)
	slot_attachment_history_stack.append(entity_slot)
	if combat_manager.phase_is_defense():
		button_confirm.show()
	button_undo.show()
	button_skip.hide()
	var preview_attachments := build_preview_attachments()
	arrange_attached_effects(controlled_player, preview_attachments)


func undo_attachment() -> void:
	if slot_attachment_history_stack.is_empty():
		return
	
	var last_slot_used: int = slot_attachment_history_stack.pop_back()
	var last_effect_used: int = queued_effect_attachments[last_slot_used].pop_back()
	return_effect_back_to_hand(last_effect_used)
	if slot_attachment_history_stack.is_empty():
		button_skip.show()
		button_undo.hide()
		button_confirm.hide()


func build_preview_attachments() -> Array[Array]:
	var preview_attachments: Array[Array] = [[], [], []]
	for slot_num in SLOT_COUNT:
		var preview_slot: Array = []
		preview_slot.append_array(controlled_player.attached_effects[slot_num])
		preview_slot.append_array(queued_effect_attachments[slot_num])
		preview_attachments[slot_num] = preview_slot
	return preview_attachments


func arrange_attached_effects(from_player: Player, attachments: Array[Array]) -> void:
	for slot_num in SLOT_COUNT:
		var slot_attachments: Array = attachments[slot_num]
		for i in slot_attachments.size():
			var effect_idx: int = slot_attachments[i]
			var effect_card := from_player.get_effect_card_at_index(effect_idx)
			
			effect_card.slot_attachment_effects_enable()
			effect_card.z_index = Constants.MIN_ATTACHMENT_Z_INDEX + (i + 1)
			effect_card.detectable = false

			var target_entity := from_player.get_entity_card_at_slot(slot_num)
			var offset := Vector2(0, CARD_SPACING * (i + 1))
			var new_pos := target_entity.global_position + offset
			effect_card.global_position = new_pos


func return_effect_back_to_hand(effect_idx: int) -> void:
	var effect_card := controlled_player.get_effect_card_at_index(effect_idx)
	effect_card.detectable = true
	effect_card.slot_attachment_effects_disable()
	your_side.hand.add_card_to_hand(effect_card)


func update_hp_label(new_hp: int, target_label: Label) -> void:
	target_label.text = str(new_hp)


func place_entities_on_field() -> void:
	your_side.realize_entity_state()
	opp_side.realize_entity_state(true)


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


#endregion
