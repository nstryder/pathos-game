@tool
extends Node

# TODO: Detect when csv has been changed (probably via hash comparison)

@export var entity_cards: Dictionary[String, EntityCardData] = {} # {Code: EntityCardData}
@export var effect_cards: Dictionary[String, EffectCardData] = {} # {Code: EffectCardData}
@export var entity_cards_indexed_by_name: Dictionary[String, String] = {} # {Nickname: Code}
@export var effect_cards_indexed_by_name: Dictionary[String, String] = {} # {Nickname: Code}
@export_tool_button("Build Card Data From CSV", "Callable") var build_button = _build_all_data


func get_entity_by_name(entity_name: String) -> EntityCardData:
	return entity_cards[entity_cards_indexed_by_name[entity_name]]


func _build_all_data():
	_build_entity_card_data()
	_build_effect_card_data()
	notify_property_list_changed()


func _build_entity_card_data():
	var entity_card_array: Array[Dictionary] = csv_parse("res://src/globals/entities.csv")
	for entity_entry in entity_card_array:
		var entity_resource := EntityCardData.new()
		entity_resource.nickname = entity_entry["Nickname"]
		entity_resource.base_attack = entity_entry["ATK"]
		entity_resource.base_shield = entity_entry["SHD"]
		entity_resource.rarity = EntityCardData.Rarity[entity_entry["Rarity"].to_upper()]
		# TODO: Fill in rest of data once they are implemented
		entity_cards[entity_entry["Code"]] = entity_resource
		entity_cards_indexed_by_name[entity_resource.nickname] = entity_entry["Code"]


func _build_effect_card_data():
	var effect_card_array: Array[Dictionary] = csv_parse("res://src/globals/effects.csv")
	for effect_entry in effect_card_array:
		var effect_resource := EffectCardData.new()
		effect_resource.effect_name = effect_entry["Nickname"]
		effect_resource.effect_type = EffectCardData.EffectType[effect_entry["Effect Type"].to_upper()]
		effect_resource.identifier = EffectCardData.Identifier[effect_entry["Identifier"].to_upper()]
		effect_resource.ability_phase = EffectCardData.AbilityPhase[effect_entry["Ability Phase"].to_upper()]
		effect_resource.usage_type = EffectCardData.UsageType[effect_entry["Use/Attach"].to_upper()]
		effect_resource.timeline_condition = EffectCardData.TimelineCondition[effect_entry["Timeline Condition"].to_upper()]
		# TODO: Fill in rest of data once they are implemented
		effect_cards[effect_entry["Code"]] = effect_resource
		effect_cards_indexed_by_name[effect_resource.effect_name] = effect_entry["Code"]


static func csv_parse(csv_path: String) -> Array[Dictionary]:
	var file := FileAccess.open(csv_path, FileAccess.READ)
	
	var final_arr: Array[Dictionary] = []
	var headers = file.get_csv_line()
	while not file.eof_reached():
		var dict = {}
		var line = file.get_csv_line()
		if line.size() < headers.size(): continue
		for i in headers.size():
			var header = headers[i]
			var value = line[i]
			
			if value.is_valid_float():
				dict[header] = float(value)
			else:
				dict[header] = value
		final_arr.append(dict)
		
	return final_arr