extends Resource
class_name SynergyData


enum Trigger {
    ON_ACTIVATE
}

@export var name: String
@export var description: String
@export var trigger: Trigger = Trigger.ON_ACTIVATE