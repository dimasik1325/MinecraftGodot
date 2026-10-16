extends RefCounted

func save_world(world_name: String, seed: int, player_pos: Vector3, inventory_data: Dictionary, changed_blocks: Array, time_of_day: float, settings_dict: Dictionary):
    var dir := DirAccess.open("user://")
    if not dir.dir_exists("saves"):
        dir.make_dir("saves")
    var folder := "user://saves/" + world_name
    if not DirAccess.dir_exists_absolute(folder):
        DirAccess.make_dir_absolute(folder)
    var f := FileAccess.open(folder + "/world.dat", FileAccess.WRITE)
    if f:
        f.store_string(str(seed))
        f.store_string("\n")
        f.store_string(str(player_pos.x) + "," + str(player_pos.y) + "," + str(player_pos.z) + "\n")
        f.store_string(str(time_of_day) + "\n")
        # simple inventory strings
        for item in inventory_data:
            f.store_string(str(item) + ":" + str(inventory_data[item]) + "\n")
        # changed blocks
        for b in changed_blocks:
            f.store_string(str(b.x) + "," + str(b.y) + "," + str(b.z) + "," + str(b.id) + "\n")
        f.close()
    # settings
    var sf := FileAccess.open(folder + "/settings.json", FileAccess.WRITE)
    if sf:
        sf.store_string(JSON.stringify(settings_dict))
        sf.close()

func load_world(world_name: String) -> Dictionary:
    var result := {}
    var folder := "user://saves/" + world_name
    var f := FileAccess.open(folder + "/world.dat", FileAccess.READ)
    if f:
        result["seed"] = int(f.get_line())
        var pos_line := f.get_line()
        var parts := pos_line.split(",")
        result["player_pos"] = Vector3(float(parts[0]), float(parts[1]), float(parts[2]))
        result["time"] = float(f.get_line())
        result["inventory"] = {}
        while not f.eof_reached():
            var line := f.get_line()
            if line == "": break
            var kv := line.split(":")
            if kv.size() == 2:
                result["inventory"][kv[0]] = int(kv[1])
        result["blocks"] = []
        # Note: changed blocks could be loaded with extra parsing; simplified
        f.close()
    # settings
    var sf := FileAccess.open(folder + "/settings.json", FileAccess.READ)
    if sf:
        var text := sf.get_as_text()
        var j := JSON.new()
        j.parse(text)
        if j.get_error() == OK:
            result["settings"] = j.get_data()
        sf.close()
    return result
