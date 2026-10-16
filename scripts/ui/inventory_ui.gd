extends Control

@export var grid_columns := 9

var slots := {}

func _ready():
    for i in range(9):
        var btn := Button.new()
        btn.name = "InvSlot" + str(i)
        btn.custom_minimum_size = Vector2(60, 60)
        btn.text = ""
        add_child(btn)
        slots[i] = btn

func update_inventory(inv: RefCounted):
    for i in range(9):
        var name: String = inv.get_slot_name(i) if inv else ""
        var amt: int = inv.get_slot_amount(i) if inv else 0
        if slots.has(i):
            slots[i].text = name + (" x" + str(amt) if amt > 0 else "")
