extends RefCounted

var block_db := preload("res://scripts/world/block_database.gd").new()

func get_break_time(id: int, tool: String) -> float:
    var h := block_db.get_hardness(id)
    if tool == "pickaxe" and (id == 3 or id == 12 or id == 13 or id == 14 or id == 15 or id == 20 or id == 17 or id == 10):
        return h / 2.0
    if tool == "axe" and (id == 7 or id == 8 or id == 9 or id == 16):
        return h / 2.0
    if tool == "shovel" and (id == 1 or id == 2 or id == 5 or id == 6 or id == 19):
        return h / 2.0
    return h

func can_break(id: int, tool: String) -> bool:
    # basic check
    if id == 4: return false  # bedrock
    return true
