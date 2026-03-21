extends Node2D
class_name ClientState


var controlled_player: Player
var opposing_player: Player

var is_attacker: bool = false
var is_taking_turn: bool = false:
	set(value):
		is_taking_turn = value
		button_end.visible = value

@onready var your_side: PlayerSide = %YourSide
@onready var your_hp_label: Label = %YourHPLabel
@onready var opp_side: PlayerSide = %OppSide
@onready var opp_hp_label: Label = %OppHPLabel

@onready var button_undo: Button = %UndoButton
@onready var button_end: Button = %EndTurnButton
@onready var card_manager: CardManager = %CardManager
@onready var combat_manager: CombatManager = %CombatManager
@onready var attack_indicator: Line2D = %AttackIndicator

@onready var server: ServerState = %ServerState
@onready var server_state_syncer: MultiplayerSynchronizer = %ServerStateSynchronizer
@onready var timeline: Timeline = %Timeline


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	button_undo.hide()
	button_undo.pressed.connect(undo_action)
	button_end.pressed.connect(end_turn)
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
	is_taking_turn = true
	button_undo.hide()


@rpc("authority", "call_local", "reliable")
func wait_for_offense() -> void:
	await client_sync_server_state()
	sync_hands()
	wait_for_turn()


@rpc("authority", "call_local", "reliable")
func wait_for_defense() -> void:
	reveal_combating_entities()


func wait_for_turn() -> void:
	set_status("Waiting for opponent's action...")
	is_taking_turn = false
	card_manager.dragging_enabled = false
	card_manager.attacking_enabled = false
	button_undo.hide()

func sync_hands() -> void:
	your_side.realize_effect_state()
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
	await client_sync_server_state()
	set_status("Resolving Combat")
	var attacking_entity: EntityCard = combat_manager.get_current_attacker()
	var target_position: Vector2 = combat_manager.get_current_target().global_position
	var tween := create_tween() \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_QUAD)
	var original_position: Vector2 = attacking_entity.global_position
	tween.tween_property(attacking_entity, "global_position", target_position, 0.1)
	tween.tween_property(attacking_entity, "global_position", original_position, 0.1)
	await tween.finished
	attack_indicator.hide()
	await Utils.sleep(1)
	update_entities_on_field()
	check_endgame()
	pass


@rpc("authority", "call_local", "reliable")
func visualize_combat_phase_fx(action_dict: Dictionary) -> void:
	var action := Timeline.Action.from_dict(action_dict)
	var presentation_point: Node2D = %PresentationPoint
	var board_center: Node2D = %BoardCenter
	action.effect.slot_attachment_effects_disable()
	action.effect.is_veiled = false
	action.effect.global_position = board_center.global_position
	var tween := create_tween()
	tween.tween_property(action.effect, "global_position", presentation_point.global_position, 0.1)
	tween.tween_interval(0.9)
	tween.tween_property(action.effect, "global_position:y", action.effect.global_position.y + 400, 0.1)
	await tween.finished
	action.effect.hide_from_field()


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
	sync_hands()
	start_turn()
	is_attacker = true
	card_manager.dragging_enabled = true
	card_manager.attacking_enabled = true
	

@rpc("authority", "call_local", "reliable")
func start_client_defense() -> void:
	await client_sync_server_state()
	sync_hands()
	start_turn()
	is_attacker = false
	card_manager.dragging_enabled = true
	card_manager.attacking_enabled = false
	reveal_combating_entities()
	

#region Player Actions
func declare_attack(attacker: EntityCard, target: EntityCard) -> void:
	server.send_attack.rpc_id(1, attacker.current_idx, target.current_idx)


func rescind_attack() -> void:
	server.rescind_attack.rpc_id(1)


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


func end_turn() -> void:
	server.request_end_turn.rpc_id(1)
	wait_for_turn()


#endregion


func reveal_combating_entities() -> void:
	if combat_manager.attack_is_declared():
		combat_manager.get_current_attacker().is_veiled = false
		combat_manager.get_current_target().is_veiled = false


func update_hp_label(new_hp: int, target_label: Label) -> void:
	target_label.text = str(new_hp)


func update_entities_on_field() -> void:
	your_side.realize_entity_state()
	opp_side.realize_entity_state()


func arrange_attached_effects() -> void:
	const CARD_SPACING = 32
	var attachments: Dictionary[EntityCard, int] = {}

	for action in timeline.get_queue():
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
	update_entities_on_field()


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
	sync_hands()
	arrange_attached_effects()
	if is_taking_turn:
		var your_queue := timeline.get_queue_filtered_by_player(controlled_player)
		print("Your queue: ", your_queue)
		if your_queue.is_empty():
			button_undo.hide()
		else:
			button_undo.show()


func _on_attack_declared() -> void:
	var attacker: EntityCard = combat_manager.get_current_attacker()
	var target: EntityCard = combat_manager.get_current_target()
	show_attack_indicator(attacker.global_position, target.global_position)


func _on_attack_rescinded() -> void:
	attack_indicator.hide()