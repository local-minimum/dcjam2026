extends SignalBusCore
class_name SignalBus

@warning_ignore_start("unused_signal")
signal on_change_xp_max(new_max: float)
signal on_change_xp(value: float, old_value: float)

signal on_hide_ability(ability_id: String)
signal on_show_ability(ability_id: String)
signal on_change_ability_level(ablity_id: String, level: int)
signal on_change_autoclicker_count(clickers: int)
signal on_gain_bonus_autoclickers(count: int)
signal on_autoclick(efficiency: float)

signal on_change_boredom(value: float)

signal on_player_death(phase: int)

signal on_player_spot_healing(station: HealthStation)
signal on_healing_refused(station: HealthStation)
signal on_player_max_health_changed()
signal on_player_health_changed(new_health: float, previous_health: float)

signal on_enemy_join_battle(enemy_data: EnemyData)
signal on_enemy_attack(enemy: BattleManager.Enemy, attack: int, hit: BattleManager.HitType)

signal on_player_attack(enemy: BattleManager.Enemy, weapon: Weapon, attack: int, hit: BattleManager.HitType)
signal on_battle_end(credits: int)
signal on_change_weapon(weapon: Weapon)
signal on_change_gear(slot: Gear.Base, gear: Gear)

signal on_gain_quest(quest_id: String)
signal on_progress_quest(quest_id: String, step: int)

signal on_ready_horror(subbed_audio: SubbedAudio)
signal on_transition_to_horror()
signal on_horror_loaded()
signal on_horror_failed()

signal on_collect_horror_key()
signal on_not_enough_horror_keys()
signal on_horror_outro_triggered()
signal on_trigger_keith(trigger: KeithTrigger)
signal on_jail_keith()

signal on_mute(what: MuteManager.MuteTarget)

@warning_ignore_restore("unused_signal")
