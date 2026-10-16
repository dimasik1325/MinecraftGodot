extends RefCounted

var slots := {}
# slots keyed by index 0-8, value = {"item":"name","amount":int}

func _init():
    for i in range(9):
        slots[i] = {"item":"","amount":0}

func add_item(name: String, amount: int):
    # find existing or empty
    var max_stack := 64
    var item_db := preload("res://scripts/inventory/item_database.gd").new()
    var info := item_db.get_item(name)
    if info.has("stack"):
        max_stack = info["stack"]
    for i in range(9):
        if slots[i]["item"] == name:
            var space := max_stack - slots[i]["amount"]
            if space > 0:
                var add_a := min(amount, space)
                slots[i]["amount"] += add_a
                amount -= add_a
                if amount <= 0: return true
    # empty slot
    for i in range(9):
        if slots[i]["item"] == "":
            slots[i]["item"] = name
            slots[i]["amount"] = amount
            return true
    # overflow: just throw away for demo
    return false

func remove_slot_amount(index: int, amount: int):
    if slots.has(index) and slots[index]["item"] != "":
        slots[index]["amount"] -= amount
        if slots[index]["amount"] <= 0:
            slots[index] = {"item":"","amount":0}

func get_slot_name(index: int) -> String:
    if slots.has(index):
        return slots[index]["item"]
    return ""

func get_slot_amount(index: int) -> int:
    if slots.has(index):
        return slots[index]["amount"]
    return 0

func get_all_items() -> Dictionary:
    return slots.duplicate()
