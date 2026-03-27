extends Node
class_name GameSettingsProvider

@warning_ignore_start("unused_private_class_variable")
static var _cache: Dictionary
@warning_ignore_restore("unused_private_class_variable")

func get_all_keys() -> Array[String]:
    var keys: Array[String]
    for key: Variant in _cache:
        if key is String:
            keys.append(key)

    return keys

func get_setting(_key: String, default: Variant = null) -> Variant:
    return default

func get_settingi(_key: String, default: int = 0) -> int:
    return default

func get_settingb(_key: String, default: bool = false) -> bool:
    return default

func get_settingf(_key: String, default: float = 0.0) -> float:
    return default

func set_setting(_key: String, _value: Variant) -> void:
    pass

func set_settingi(_key: String, _value: int) -> void:
    pass

func set_settingb(_key: String, _value: bool) -> void:
    pass

func set_settingf(_key: String, _value: float) -> void:
    pass

func remove_setting(key: String) -> void:
    @warning_ignore_start("return_value_discarded")
    _cache.erase(key)
    @warning_ignore_restore("return_value_discarded")
