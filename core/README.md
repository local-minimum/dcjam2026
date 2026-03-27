# Setting up a project

# Globals
It is expected that you make a version of:

- `signal_bus_core.gd` called `signal_bus.gd` as global `__SignalBus`
- `global_game_state_core.gd` called `global_game_state.gd` as global `__GlobalGameState`

Add global `__AudioHub` (`audio_hub.gd` as it is). Create an `AudioBusLayout` resource in the
root of the project with channels `Dialogue`, `Music`, `SFX`.


And global `__BindingHints` (`binding_hints.gd` as it is).


After including these you might need to reload the current project two three times before everyting compiles

# Activate addons

You need to activate the miniumum convenience addon and then create default configs:

Then create an `AudioHubConfig` called `audio_hub_config.tres` in the project root.
Then create a `BindingHintsConfig` called `binding_hints_config.tres` in the project root.

# Bindings
Expected bindings: `crawl_forward`, `crawl_backward`, `crawl_strafe_left`, `crawl_strafe_right`, `crawl_turn_left`,
`crawl_turn_right`,`crawl_search`,`hot_key_1`,`hot_key_2`,`hot_key_3`,`crawl_pause`,`toggle_free_look_cam_keyb`
`toggle_free_look_cam_mouse`.

These should have been created by activating the `minimum_convenience` plugin.
You will have to reload the project before they show up though.
