extends RefCounted

var item_data: Dictionary = {}

func _init():
    var f := FileAccess.open("res://resources/data/items.json", FileAccess.READ)
    if f:
        var text := f.get_as_text()
        var json := JSON.new()
        json.parse(text)
        if json.get_error() == OK:
            var root := json.get_data()
            if root.has("items"):
                item_data = root["items"]
        f.close()

func get_item(name: String) -> Dictionary:
    if item_data.has(name):
        return item_data[name]
    return {}

func get_id(name: String) -> int:
    var d := get_item(name)
    return d.get("id", 0)

func get_name(name: String) -> String:
    var d := get_item(name)
    return d.get("name", name)

func get_stack_size(name: String) -> int:
    var d := get_item(name)
    return d.get("stack", 64)
