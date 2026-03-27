extends SignalBusCore
class_name SignalBus

@warning_ignore_start("unused_signal")
signal on_change_xp_max(new_max: float)
signal on_change_xp(value: float)

signal on_change_ability_level(ablity_id: String, level: int)
signal on_change_autoclicker_count(clickers: int)
signal on_autoclick(efficiency: float)
@warning_ignore_restore("unused_signal")
