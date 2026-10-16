extends Node3D

@export var chunk_size: int = 16
@export var chunk_height: int = 64
@export var render_distance: int = 3  # chunks

var chunks: Dictionary = {}
var player_ref: Node3D = null

func _ready():
    if not player_ref:
        var p: Node3D = get_tree().current_scene.get_node_or_null("World/Player")
        if p:
            player_ref = p
    if player_ref:
        var cx: int = floori(float(player_ref.global_position.x) / chunk_size)
        var cz: int = floori(float(player_ref.global_position.z) / chunk_size)
        for dx in range(-render_distance, render_distance+1):
            for dz in range(-render_distance, render_distance+1):
                load_chunk(cx+dx, cz+dz)

func set_player(p: Node3D):
    player_ref = p

func get_chunk_key(cx: int, cz: int) -> Vector2i:
    return Vector2i(cx, cz)

func load_chunk(cx: int, cz: int):
    var key: Vector2i = get_chunk_key(cx, cz)
    if chunks.has(key):
        return chunks[key]
    var chunk: Chunk = preload("res://scripts/world/chunk.gd").new()
    chunk.chunk_x = cx
    chunk.chunk_z = cz
    chunk.set_size(chunk_size, chunk_height, chunk_size)
    # generate
    generate_chunk(chunk)
    # build mesh
    var mesh: ArrayMesh = build_chunk_mesh(chunk)
    var mi: MeshInstance3D = MeshInstance3D.new()
    mi.name = "chunk_" + str(cx) + "_" + str(cz)
    mi.mesh = mesh
    mi.position = Vector3(cx * chunk_size, 0, cz * chunk_size)
    add_child(mi)
    chunk.mesh_dirty = false
    chunks[key] = {"chunk": chunk, "instance": mi}
    return chunk

func unload_chunk(cx: int, cz: int):
    var key: Vector2i = get_chunk_key(cx, cz)
    if chunks.has(key):
        var data: Dictionary = chunks[key]
        if data["instance"]:
            data["instance"].queue_free()
        chunks.erase(key)

func get_block_world(x: int, y: int, z: int) -> int:
    # returns block id from chunk or neighbor
    var cx: int = floori(float(x) / chunk_size)
    var cz: int = floori(float(z) / chunk_size)
    var lx: int = x - cx * chunk_size
    var lz: int = z - cz * chunk_size
    var chunk: Chunk = get_chunk(cx, cz)
    if chunk:
        return chunk.get_block(lx, y, lz)
    return 0

func set_block_world(x: int, y: int, z: int, id: int):
    var cx: int = floori(float(x) / chunk_size)
    var cz: int = floori(float(z) / chunk_size)
    var lx: int = x - cx * chunk_size
    var lz: int = z - cz * chunk_size
    var chunk := load_chunk(cx, cz)
    chunk.set_block(lx, y, lz, id)
    # rebuild this chunk
    var data := chunks.get(get_chunk_key(cx, cz))
    if data:
        var mesh: ArrayMesh = build_chunk_mesh(chunk)
        data["instance"].mesh = mesh
    # rebuild neighbors if at boundary (simplified: rebuild all loaded around)
    for dx in range(-1,2):
        for dz in range(-1,2):
            var nkey := get_chunk_key(cx+dx, cz+dz)
            if chunks.has(nkey):
                var nchunk := chunks[nkey]["chunk"]
                var nmesh := build_chunk_mesh(nchunk)
                chunks[nkey]["instance"].mesh = nmesh

func get_chunk(cx: int, cz: int) -> Chunk:
    var key: Vector2i = get_chunk_key(cx, cz)
    if chunks.has(key):
        return chunks[key]["chunk"]
    return null

func generate_chunk(chunk: Chunk):
    # simple noise terrain
    var noise := OpenSimplexNoise.new()
    noise.period = 256
    noise.octaves = 3
    for x in range(chunk_size):
        for z in range(chunk_size):
            var wx := chunk.chunk_x * chunk_size + x
            var wz := chunk.chunk_z * chunk_size + z
            var h := int(30 + noise.get_noise_2d(wx, wz) * 14)
            if h < 4: h = 4
            for y in range(chunk_height):
                if y == 0:
                    chunk.set_block(x, y, z, 4)  # bedrock
                elif y < h - 3:
                    chunk.set_block(x, y, z, 3)  # stone
                elif y < h:
                    chunk.set_block(x, y, z, 2)  # dirt
                elif y == h:
                    chunk.set_block(x, y, z, 1)  # grass
                elif y < 32:
                    chunk.set_block(x, y, z, 11)  # water
                else:
                    chunk.set_block(x, y, z, 0)
            # tree occasionally
            if h > 5 and x > 2 and x < chunk_size-3 and z > 2 and z < chunk_size-3:
                if noise.get_noise_2d(wx*2, wz*2) > 0.6:
                    for bh in range(h+1, min(h+4, chunk_height)):
                        if bh >= chunk_height: break
                        chunk.set_block(x, bh, z, 7)
                    if h+4 < chunk_height:
                        chunk.set_block(x, h+4, z, 8)  # leaves
                        for dx in range(-1,2):
                            for dz in range(-1,2):
                                if abs(dx)+abs(dz) <= 1 and h+3 < chunk_height:
                                    chunk.set_block(x+dx, h+3, z+dz, 8)

func build_chunk_mesh(chunk: Chunk) -> ArrayMesh:
    var array_mesh := ArrayMesh.new()
    # We'll collect surfaces per block texture, but for simplicity use one generic surface with white material and rely on vertex colors? No.
    # Alternative: use a simple cube mesh for each block but merge into one MeshInstance with merge? Not easy.
    # Simplest working approach: create a MeshInstance per chunk using MeshInstance3D's mesh built from a Script with one surface that uses a UV atlas? Not feasible quickly.
    # Given time, I'll use MeshInstance3D per visible solid block inside chunk at build time, but only for chunks currently loaded (max ~9 chunks * ~500 blocks = 4500 instances) which could lag.
    # To balance, I'll create a basic block mesh per chunk by combining quads into one ArrayMesh using a single texture (dirt) just for demo, and note that full multi-texture is done via material swap per surface in real engine. Actually let's do multi-surface properly but simplified: create one surface per unique texture found in chunk.
    # Each surface uses a material loaded from texture.
    # We will collect vertices per texture in dictionaries.
    var surfaces: Dictionary = {}
    # Predefine face quad vertices (local to block at x,y,z)
    for x in range(chunk_size):
        for y in range(chunk_height):
            for z in range(chunk_size):
                var id: int = chunk.get_block(x,y,z)
                if id == 0 or id == 11:  # skip air and water for mesh (water can be separate, skip for simplicity)
                    continue
                # Check visibility: if any neighbor is solid, skip face (simplified: always add all faces for demo to ensure it looks blocky, but that's slow)
                # To keep mesh size reasonable, only add face if neighbor is air/transparent/empty
                var tex := get_texture_name(id)
                if tex == "": tex = "stone"
                if not surfaces.has(tex):
                    surfaces[tex] = {"verts": PackedVector3Array(), "normals": PackedVector3Array(), "uvs": PackedVector2Array(), "indices": PackedInt32Array()}
                var s: Dictionary = surfaces[tex]
                var cx := float(x)
                var cy := float(y)
                var cz := float(z)
                # define 6 face directions
                # top (y+1)
                if y+1 >= chunk_height or chunk.get_block(x, y+1, z) == 0 or chunk.get_block(x, y+1, z) == 11 or chunk.get_block(x, y+1, z) == 8:
                    # top
                    s["verts"].append(Vector3(cx, cy+1, cz+1))
                    s["verts"].append(Vector3(cx+1, cy+1, cz+1))
                    s["verts"].append(Vector3(cx+1, cy+1, cz))
                    s["verts"].append(Vector3(cx, cy+1, cz))
                    s["normals"].append(Vector3(0,1,0)); s["normals"].append(Vector3(0,1,0)); s["normals"].append(Vector3(0,1,0)); s["normals"].append(Vector3(0,1,0))
                    s["uvs"].append(Vector2(0,0)); s["uvs"].append(Vector2(1,0)); s["uvs"].append(Vector2(1,1)); s["uvs"].append(Vector2(0,1))
                    var base: int = s["verts"].size() - 4
                    s["indices"].append(base); s["indices"].append(base+1); s["indices"].append(base+2)
                    s["indices"].append(base); s["indices"].append(base+2); s["indices"].append(base+3)
                # bottom (y-1)
                if y-1 < 0 or chunk.get_block(x, y-1, z) == 0 or chunk.get_block(x, y-1, z) == 11 or chunk.get_block(x, y-1, z) == 8:
                    s["verts"].append(Vector3(cx, cy, cz))
                    s["verts"].append(Vector3(cx+1, cy, cz))
                    s["verts"].append(Vector3(cx+1, cy, cz+1))
                    s["verts"].append(Vector3(cx, cy, cz+1))
                    s["normals"].append(Vector3(0,-1,0)); s["normals"].append(Vector3(0,-1,0)); s["normals"].append(Vector3(0,-1,0)); s["normals"].append(Vector3(0,-1,0))
                    s["uvs"].append(Vector2(0,1)); s["uvs"].append(Vector2(1,1)); s["uvs"].append(Vector2(1,0)); s["uvs"].append(Vector2(0,0))
                    var base: int = s["verts"].size() - 4
                    s["indices"].append(base); s["indices"].append(base+1); s["indices"].append(base+2)
                    s["indices"].append(base); s["indices"].append(base+2); s["indices"].append(base+3)
                # north (z-1)
                if z-1 < 0 or chunk.get_block(x, y, z-1) == 0 or chunk.get_block(x, y, z-1) == 11 or chunk.get_block(x, y, z-1) == 8:
                    s["verts"].append(Vector3(cx+1, cy, cz))
                    s["verts"].append(Vector3(cx+1, cy+1, cz))
                    s["verts"].append(Vector3(cx, cy+1, cz))
                    s["verts"].append(Vector3(cx, cy, cz))
                    s["normals"].append(Vector3(0,0,-1)); s["normals"].append(Vector3(0,0,-1)); s["normals"].append(Vector3(0,0,-1)); s["normals"].append(Vector3(0,0,-1))
                    s["uvs"].append(Vector2(1,0)); s["uvs"].append(Vector2(1,1)); s["uvs"].append(Vector2(0,1)); s["uvs"].append(Vector2(0,0))
                    var base: int = s["verts"].size() - 4
                    s["indices"].append(base); s["indices"].append(base+1); s["indices"].append(base+2)
                    s["indices"].append(base); s["indices"].append(base+2); s["indices"].append(base+3)
                # south (z+1)
                if z+1 >= chunk_size or chunk.get_block(x, y, z+1) == 0 or chunk.get_block(x, y, z+1) == 11 or chunk.get_block(x, y, z+1) == 8:
                    s["verts"].append(Vector3(cx, cy, cz+1))
                    s["verts"].append(Vector3(cx, cy+1, cz+1))
                    s["verts"].append(Vector3(cx+1, cy+1, cz+1))
                    s["verts"].append(Vector3(cx+1, cy, cz+1))
                    s["normals"].append(Vector3(0,0,1)); s["normals"].append(Vector3(0,0,1)); s["normals"].append(Vector3(0,0,1)); s["normals"].append(Vector3(0,0,1))
                    s["uvs"].append(Vector2(0,1)); s["uvs"].append(Vector2(1,1)); s["uvs"].append(Vector2(1,0)); s["uvs"].append(Vector2(0,0))
                    var base: int = s["verts"].size() - 4
                    s["indices"].append(base); s["indices"].append(base+1); s["indices"].append(base+2)
                    s["indices"].append(base); s["indices"].append(base+2); s["indices"].append(base+3)
                # east (x+1)
                if x+1 >= chunk_size or chunk.get_block(x+1, y, z) == 0 or chunk.get_block(x+1, y, z) == 11 or chunk.get_block(x+1, y, z) == 8:
                    s["verts"].append(Vector3(cx+1, cy, cz+1))
                    s["verts"].append(Vector3(cx+1, cy+1, cz+1))
                    s["verts"].append(Vector3(cx+1, cy+1, cz))
                    s["verts"].append(Vector3(cx+1, cy, cz))
                    s["normals"].append(Vector3(1,0,0)); s["normals"].append(Vector3(1,0,0)); s["normals"].append(Vector3(1,0,0)); s["normals"].append(Vector3(1,0,0))
                    s["uvs"].append(Vector2(1,0)); s["uvs"].append(Vector2(1,1)); s["uvs"].append(Vector2(0,1)); s["uvs"].append(Vector2(0,0))
                    var base: int = s["verts"].size() - 4
                    s["indices"].append(base); s["indices"].append(base+1); s["indices"].append(base+2)
                    s["indices"].append(base); s["indices"].append(base+2); s["indices"].append(base+3)
                # west (x-1)
                if x-1 < 0 or chunk.get_block(x-1, y, z) == 0 or chunk.get_block(x-1, y, z) == 11 or chunk.get_block(x-1, y, z) == 8:
                    s["verts"].append(Vector3(cx, cy, cz))
                    s["verts"].append(Vector3(cx, cy+1, cz))
                    s["verts"].append(Vector3(cx, cy+1, cz+1))
                    s["verts"].append(Vector3(cx, cy, cz+1))
                    s["normals"].append(Vector3(-1,0,0)); s["normals"].append(Vector3(-1,0,0)); s["normals"].append(Vector3(-1,0,0)); s["normals"].append(Vector3(-1,0,0))
                    s["uvs"].append(Vector2(0,0)); s["uvs"].append(Vector2(0,1)); s["uvs"].append(Vector2(1,1)); s["uvs"].append(Vector2(1,0))
                    var base: int = s["verts"].size() - 4
                    s["indices"].append(base); s["indices"].append(base+1); s["indices"].append(base+2)
                    s["indices"].append(base); s["indices"].append(base+2); s["indices"].append(base+3)
    # Build surfaces
    var surface_index := 0
    for tex in surfaces:
        var s: Dictionary = surfaces[tex]
        array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, {
            "vertex": s["verts"],
            "normal": s["normals"],
            "uv": s["uvs"],
            "index": s["indices"]
        })
        # create material from texture
        var mat := StandardMaterial3D.new()
        var tex_res := load("res://assets/textures/" + tex + ".png")
        if tex_res:
            mat.albedo_texture = tex_res
        mat.roughness = 0.9
        array_mesh.surface_set_material(surface_index, mat)
        surface_index += 1
    array_mesh.create_convex_collision()  # optional; not needed but okay
    return array_mesh

func get_texture_name(id: int) -> String:
    var db := preload("res://scripts/world/block_database.gd").new()
    return db.get_texture(id)
