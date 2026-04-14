extends TextDatabase
class_name SubDatabase

const SUFFIX: String = ".subs.cfg"
const FALLBACK_LANGUAGE: String = "en"

var _file_path: String

func _initialize():
    define_from_struct(SubData.new)

func _schema_initialize():
    override_property_type("format", TYPE_INT)

func _postprocess_entry(entry: Dictionary):
    entry.format = SubData.int_to_text_format(entry.get('format', SubData.SubTextFormat.Regular))

func load_sub(audio_resource_uid: String) -> void:
    _file_path = "%s%s" % [ResourceUID.uid_to_path(audio_resource_uid), SUFFIX]
    load_from_path(_file_path, false)

func has_language(lang: String) -> bool:
    for data: SubData in get_struct_array():
        if data.lang == lang:
            return true

    return false

func get_subs(lang: String = "", use_fallback: bool = true) -> Array[SubData]:
    var ret: Array[SubData] = []

    if lang.is_empty():
        lang = Subtitles.get_language_code()

    if use_fallback && (lang.is_empty() || !has_language(lang)):
        lang = FALLBACK_LANGUAGE

    for data: SubData in get_struct_array():
        if data.lang == lang:
            ret.append(data)

    return ret

func serialize() -> void:
    var cfg_file: ConfigFile = ConfigFile.new()

    for data: SubData in get_struct_array():
        cfg_file.set_value(data.name, "start", data.start)
        cfg_file.set_value(data.name, "end", data.end)
        cfg_file.set_value(data.lang, "lang", data.lang)
        cfg_file.set_value(data.name, "text", data.text)
        cfg_file.set_value(data.name, "format", int(data.format))

    if cfg_file.save(_file_path) != OK:
        push_error("Canot save sub-database %s to '%s'" % [self, _file_path])
