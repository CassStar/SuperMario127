class_name input_settings_util


const CONTROLLER_SUFFIX = " (Controller)"


static func change_setting(input_group: String, input_key: String, keybind_array: Array, is_controller: bool):
	LocalSettings.change_setting(input_group + get_group_suffix(is_controller), input_key, keybind_array)


static func get_setting(input_group: String, input_key: String) -> Array:
	var keybind_array: Array = []
	keybind_array += get_setting_partial(input_group, input_key, false)
	keybind_array += get_setting_partial(input_group, input_key, true)
	return keybind_array


static func get_setting_partial(input_group: String, input_key: String, is_controller: bool) -> Array:
	return LocalSettings.load_setting(input_group + get_group_suffix(is_controller), input_key, [])


static func get_group_suffix(is_controller: bool) -> String:
	return "" if not is_controller else CONTROLLER_SUFFIX
