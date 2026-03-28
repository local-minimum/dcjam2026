extends ColorRect

@export var _loot_root: Control
@export var _loot_previews: Array[LootPreviewUI]
@export var _weapons_smith: WeaponsSmith
@export var _start_weapon_value: int = 3

func _enter_tree() -> void:
    if __SignalBus.on_battle_end.connect(_handle_battle_end) != OK:
        push_error("Failed to connect battle end")

func _ready() -> void:
    if __GlobalGameState.weapon == null:
        if _weapons_smith != null:
            __GlobalGameState.weapon = _weapons_smith.create_weapon(_start_weapon_value)
        else:
            __GlobalGameState.weapon = Weapon.new(Weapon.Quality.POOR, Weapon.Mat.BRASS, Weapon.Base.PLASMA_BATON)

    hide()

func _handle_battle_end(credits: int) -> void:
    var active_weapon_value: int = __GlobalGameState.weapon.score
    var weapons: Array[Weapon] = []

    for idx: int in _loot_previews.size():
        if credits <= 0:
            _loot_previews[idx].hide()

        var use_credits: int = mini(credits, roundi(active_weapon_value * 1.5))
        if idx == _loot_previews.size() - 1:
            use_credits = credits

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

    _loot_root.show()
    show()
