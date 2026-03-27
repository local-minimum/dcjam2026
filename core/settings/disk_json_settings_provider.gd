extends GameSettingsProvider
class_name DiskJsonSettingsProvider

@export var file_path: String = "user://game_settings.json"

func _load_cache() -> void:
    if !_cache.is_empty():
        return

    if !FileAccess.file_exists(file_path):
        return

    var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)

    if file == null:
        push_error("Could not open file at '%s' with read permissions" % file_path)
        return

    var json: JSON = JSON.new()
    if json.parse(file.get_line()) == OK:
        _cache = JSON.to_native(json.data)

func _store_cache() -> void:
    var data: String = JSON.stringify(JSON.from_native(_cache))

    var save_file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
    if save_file != null:
        if !save_file.store_line(data):
            push_error("Could not write data to file '%s'" % file_path)
    else:
        push_error("Could not open file '%s' with write permissions" % file_path)

func get_all_keys() -> Array[String]:
    _load_cache()
    return super.get_all_keys()

func get_setting(key: String, default: Variant = null) -> Variant:
    _load_cache()
    return _cache.get(key, default)

func get_settingi(key: String, default: int = 0) -> int:
    _load_cache()
    var value: Variant = _cache.get(key, default)
    if value is int:
        return value
    return default

func get_settingb(key: String, default: bool = false) -> bool:
    _load_cache()
    var value: Variant = _cache.get(key, default)
    if value is int:
        return value != 0
    return default

func get_settingf(key: String, default: float = 0.0) -> float:
    _load_cache()
    var value: Variant = _cache.get(key, default)
    if value is float:
        return value
    return default

func set_setting(key: String, value: Variant) -> void:
    _cache[key] = value
    _store_cache()

func set_settingi(key: String, value: int) -> void:
    _cache[key] = value
    _store_cache()

func set_settingb(key: String, value: bool) -> void:
    _cache[key] = 1 if value else 0
    _store_cache()

func set_settingf(key: String, value: float) -> void:
    _cache[key] = value
    _store_cache()

func remove_setting(key: String) -> void:
    super.remove_setting(key)
    _store_cache()
