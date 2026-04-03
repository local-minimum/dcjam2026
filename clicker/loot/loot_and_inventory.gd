extends ColorRect
class_name LootAndInventory

@export var _loot_root: Control
@export var _loot_previews: Array[LootPreviewUI]
@export var _weapons_smith: WeaponsSmith
@export var _gear_smith: GearSmith
@export var _start_weapon_value: int = 2
@export var _start_gear_value: int = 1

func _enter_tree() -> void:
    if __SignalBus.on_battle_end.connect(_handle_battle_end) != OK:
        push_error("Failed to connect battle end")

func _ready() -> void:
    if __GlobalGameState.weapon == null:
        if _weapons_smith != null:
            __GlobalGameState.weapon = _weapons_smith.create_weapon(
                _start_weapon_value if __GlobalGameState.replay == 0 else 2 * _start_weapon_value
            )
            print_debug("Creating start weapon %s" % [__GlobalGameState.weapon])
        else:
            __GlobalGameState.weapon = Weapon.new(
                Weapon.Quality.POOR,
                Weapon.Mat.BRASS,
                Weapon.Base.PLASMA_BATON,
            ) if __GlobalGameState.replay == 0 else Weapon.new(
                Weapon.Quality.ORDINARY,
                Weapon.Mat.PLASTIC,
                Weapon.Base.PLASMA_SWORD,
            )
            print_debug("Creating start weapon without smith %s" % [__GlobalGameState.weapon])

    if __GlobalGameState.is_naked():
        if _gear_smith != null:
            __GlobalGameState.set_gear(_gear_smith.create_gear(
                _start_gear_value if __GlobalGameState.replay == 0 else 3 * _start_gear_value
            ))
        else:
            print_debug("Creating start gear without smith")
            __GlobalGameState.set_gear(
                Gear.new(Gear.Quality.SOILED, Gear.Mat.PLASTIC, Gear.Base.LOWER_BODY)
                if __GlobalGameState.replay == 0 else
                Gear.new(Gear.Quality.BASIC, Gear.Mat.CARDBOARD, Gear.Base.UPPER_BODY)
            )

    hide()

func _handle_battle_end(credits: int) -> void:
    PhysicsGridPlayerController.last_connected_player.add_cinematic_blocker(self)

    var active_weapon_value: int = __GlobalGameState.weapon.score
    var gear_value: int = __GlobalGameState.get_average_gear_score()
    var gear_or_weapon_rng_value: int = active_weapon_value + gear_value + 25
    var make_weapon_threshold: int = gear_value + 5

    print_debug("[Loot] Active Weapon (%s) and Avg Gear (%s) credits %s" % [active_weapon_value, gear_value, credits])
    var weapons: Array[Weapon] = []
    var gears: Array[Gear] = []

    for idx: int in _loot_previews.size():
        if credits <= 0:
            _loot_previews[idx].hide()
            continue
        print_debug("[Loot] Weapon bias rng(%s) < %s" % [gear_or_weapon_rng_value, make_weapon_threshold])
        if randi_range(0, gear_or_weapon_rng_value) < make_weapon_threshold:
            var use_credits: int = clampi(
                roundi(active_weapon_value * 1.5),
                roundi(credits * float(idx + 1.0) / (1.5 + _loot_previews.size())),
                mini(credits, roundi(credits * float(idx + 2.0) / _loot_previews.size())),
            )
            if idx == _loot_previews.size() - 1:
                use_credits = mini(credits, roundi(active_weapon_value * 2.5))

            print_debug("[Loot] Asking for %s weapon vs current %s" % [use_credits, active_weapon_value])
            var weapon = _weapons_smith.create_weapon(use_credits)

            var dupe: bool = false
            for other: Weapon in weapons:
                if other.is_same(weapon):
                    dupe = true
                    break

            if dupe:
                _loot_previews[idx].hide()
            else:
                weapons.append(weapon)
                credits -= weapon.score

                _loot_previews[idx].preview_weapon(weapon)
                _loot_previews[idx].show()
                _loot_previews[idx].loot_and_inventory = self

                make_weapon_threshold = maxi(make_weapon_threshold - 1, 10)
        else:
            var use_credits: int = clampi(
                roundi(gear_value * 1.5),
                roundi(credits * float(idx + 1.0) / (1.5 + _loot_previews.size())),
                mini(credits, roundi(credits * float(idx + 2.0) / _loot_previews.size())),
            )
            if idx == _loot_previews.size() - 1:
                use_credits = mini(credits, roundi(gear_value * 2.5))

            print_debug("[Loot] Asking for %s gear" % use_credits)
            var gear = _gear_smith.create_gear(use_credits)
            var dupe: bool = false
            for other: Gear in gears:
                if other.is_same(gear):
                    dupe = true
                    break

            if dupe:
                _loot_previews[idx].hide()
            else:
                gears.append(gear)
                credits -= gear.score
                _loot_previews[idx].preview_gear(gear)
                _loot_previews[idx].show()
                _loot_previews[idx].loot_and_inventory = self

                make_weapon_threshold = mini(make_weapon_threshold + 1, gear_or_weapon_rng_value - 15)
    _loot_root.show()
    show()

func check_remaining_loot() -> void:
    for preview: LootPreviewUI in _loot_previews:
        if preview.visible:
            return

    close_ui()

func close_ui() -> void:
    PhysicsGridPlayerController.last_connected_player.remove_cinematic_blocker(self)
    hide()


func _on_close_button_pressed() -> void:
    close_ui()
