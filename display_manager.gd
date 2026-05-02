class_name DisplayManager

static var _full_mode: DisplayServer.WindowMode

static var fullscreen: bool:
    get():
        match DisplayServer.window_get_mode():
            DisplayServer.WindowMode.WINDOW_MODE_EXCLUSIVE_FULLSCREEN, DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN:
                return true
            _:
                return false

    set(value):
        if fullscreen == value:
            return

        if fullscreen:
            _full_mode = DisplayServer.window_get_mode()

            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED);

        else:

            DisplayServer.window_set_mode(_full_mode);
