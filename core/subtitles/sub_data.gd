extends RefCounted
class_name SubData

enum SubTextFormat { Regular, Bold, Italic }

## Identifier of the record
var name: String
## Start time in seconds for sub
var start: float
## End time in seconds for sub
var end: float
## Language code (extracted from locale) of sub
var lang: String
## The actual text
var text: String
## If the text need special formatting
var format: SubTextFormat = SubTextFormat.Regular


static func int_to_text_format(value: int) -> SubTextFormat:
    match value:
        0:
            return SubTextFormat.Regular
        1:
            return SubTextFormat.Bold
        2:
            return SubTextFormat.Italic
        _:
            push_error("Unexepected value %s for SubTextFormat" % [value])
            return SubTextFormat.Regular
