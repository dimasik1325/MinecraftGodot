extends RefCounted
class_name Chunk

var chunk_x: int = 0
var chunk_z: int = 0
var blocks: Array = []  # 3D array [x][y][z] flattened or nested
var mesh_dirty := true

func _init():
    pass

func set_size(size_x: int, size_y: int, size_z: int):
    blocks.resize(size_x)
    for x in range(size_x):
        blocks[x] = []
        blocks[x].resize(size_y)
        for y in range(size_y):
            blocks[x][y] = []
            blocks[x][y].resize(size_z)
            for z in range(size_z):
                blocks[x][y][z] = 0

def get_block(x: int, y: int, z: int) -> int:
    if x < 0 or x >= blocks.size(): return 0
    if y < 0 or y >= blocks[0].size(): return 0
    if z < 0 or z >= blocks[0][0].size(): return 0
    return blocks[x][y][z]

def set_block(x: int, y: int, z: int, id: int):
    if x < 0 or x >= blocks.size(): return
    if y < 0 or y >= blocks[0].size(): return
    if z < 0 or z >= blocks[0][0].size(): return
    blocks[x][y][z] = id
    mesh_dirty = true
