extends RefCounted

var recipes := []

func _init():
    var f := FileAccess.open("res://resources/data/recipes.json", FileAccess.READ)
    if f:
        var text := f.get_as_text()
        var json := JSON.new()
        json.parse(text)
        if json.get_error() == OK:
            var root := json.get_data()
            if root.has("recipes"):
                recipes = root["recipes"]
        f.close()

func find_recipe(slots: Array) -> Dictionary:
    # slots is array of item names (strings) length 9 or 4; simple match for now
    var grid := {}
    for s in slots:
        grid[s] = grid.get(s, 0) + 1
    for r in recipes:
        if r.get("requires_crafting_table", false) and slots.size() < 9:
            continue
        # Simple exact ingredient count check (not layout-sensitive for speed)
        var ing := r.get("ingredients", {})
        var ok := true
        for k,v in ing.items():
            if grid.get(k, 0) < v:
                ok = false
                break
        if ok:
            # Check no extra non-ingredient items if 2x2 or 3x3 used fully (simplified)
            return r
    return {}
