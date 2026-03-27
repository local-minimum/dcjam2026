class_name TextUtils

const _SPACERS: String = " -_:/[]().,;\\/?!*&"

static var _next_word: RegEx = RegEx.new()
static var _next_sentence: RegEx = RegEx.new()
static var _paragraph: RegEx = RegEx.new()

enum Segment { NONE, DEFAULT, PARAGRAPH, SENTENCE, WORD, CHARACTER }

static func init() -> void:
    if _next_word.compile("[^ \n]*[ \n]?") != OK:
        push_error("Next word pattern didn't compile")
    if _next_sentence.compile(".*?[.!?]+([ \n]|$)") != OK:
        push_error("Next sentence pattern didn't compile")
    if _paragraph.compile("\n*(.|\n)*?(\n\n|\\Z)") != OK:
        push_error("Next paragraph pattern didn't compile")

## Return end of next text segment
## NOTE: TextUtils.init() must have been called first for proper operations
static func find_message_segment_end(text: String, start: int, segment: Segment) -> int:
    match segment:
        Segment.CHARACTER:
            return start + (2 if start < text.length() && _SPACERS.contains(text[start]) else 1)

        Segment.WORD:
            var match: RegExMatch = _next_word.search(text, start)
            if match:
                return match.get_end()
            return text.length()

        Segment.SENTENCE:
            var match: RegExMatch = _next_sentence.search(text, start)
            if match:
                return match.get_end()
            return text.length()

        Segment.PARAGRAPH:
            var match: RegExMatch = _paragraph.search(text, start)
            if match:
                return match.get_start(2)
            return text.length()

    return text.length()

static func word_wrap(
    message: String,
    max_width: int,
    separators: PackedStringArray = [" ", "-", "\t"],
) -> PackedStringArray:
    if message.length() < max_width:
        # print_debug("no wrapping needed")
        return [message]

    var lines: PackedStringArray = []
    var line_start: int = 0
    var cursor: int = 0
    var length: int = message.length()

    var line: String

    while cursor + 1 < length:
        var next_cursor: int = -1
        for sep: String in separators:
            var idx: int = message.find(sep, cursor)
            if idx >= 0:
                if next_cursor == -1:
                    next_cursor = idx
                else:
                    next_cursor = mini(idx, next_cursor)

        if next_cursor == -1 && cursor == line_start:
            # print_debug("no safe linebreak")
            line = message.substr(line_start)
            if line.length() > max_width:
                line = message.substr(line_start, max_width - 1)
                next_cursor = line_start + line.length()
                line_start = next_cursor
                if !lines.append("%s-" % line):
                    push_error("Failed to add line %s" % line)

            else:
                # print_debug("Hit end of line")
                if !line.is_empty():
                    if !lines.append(line):
                        push_error("Failed to add line %s" % line)
                return lines

        elif next_cursor - line_start > max_width:
            line = message.substr(line_start, cursor - line_start).strip_edges(false, true)
            # print_debug("Adding line '%s' from %s to %s" % [line, line_start, cursor])
            if !lines.append(line):
                push_error("Failed to add line %s" % line)

            line_start = cursor
            next_cursor = cursor

        # print_debug("Cursor %s next %s with char at cursor '%s' and next '%s'" % [
        #    cursor,
        #    next_cursor,
        #     message.substr(cursor, 1),
        #    message.substr(next_cursor, 1),
        #])
        cursor = maxi(cursor + 1, next_cursor + 1)

    line = message.substr(line_start).strip_edges(false, true)
    if !line.is_empty():
        if !lines.append(line):
            push_error("Failed to append line %s" % line)

    return lines
