extends Resource
class_name Synergy


enum Trigger {
    ON_ACTIVATE
}

@export var name: String
@export var description: String
@export var trigger: Trigger = Trigger.ON_ACTIVATE