extends SynergyBehavior


# Draw 1 Effect card every time Synergy activates.
func on_activate() -> void:
    print("Midnight Corridor activated!")
    player.draw_effects(1)