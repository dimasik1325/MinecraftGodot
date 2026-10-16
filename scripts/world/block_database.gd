extends RefCounted

var block_data := {}

func _init():
    var f := FileAccess.open("res://resources/data/blocks.json", FileAccess.READ)
    if f:
        var text := f.get_as_text()
        var json := JSON.new()
        json.parse(text)
        if json.get_error() == OK:
            var root := json.get_data()
            if root.has("blocks"):
                block_data = root["blocks"]
        f.close()

func get_id(name: String) -> int:
    for k in block_data:
        v = block_data[k]
        if v.get("name") == name:
            return int(k)
    return 0

func get_name(id: int) -> String:
    var key := str(id)
    if block_data.has(key):
        return block_data[key].get("name","unknown")
    return "unknown"

func is_solid(id: int) -> bool:
    var key := str(id)
    if block_data.has(key):
        return block_data[key].get("solid", false)
    return false

func is_transparent(id: int) -> bool:
    var key := str(id)
    if block_data.has(key):
        return block_data[key].get("transparent", true)
    return true

func get_hardness(id: int) -> float:
    var key := str(id)
    if block_data.has(key):
        return float(block_data[key].get("hardness", 1.0))
    return 1.0

func get_texture(id: int) -> String:
    var key := str(id)
    if block_data.has(key):
        return block_data[key].get("texture", "")
    return ""

func get_drop(id: int) -> String:
    var key := str(id)
    if block_data.has(key):
        return block_data[key].get("drop", "")
    return ""
