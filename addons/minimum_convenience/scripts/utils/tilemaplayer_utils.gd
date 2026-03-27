class_name TileMapLayerUtils
    
## Local space bounding box
static func get_tile_bbox(layer: TileMapLayer, local_coords: Vector2i) -> Rect2:
    if layer == null:
        return Rect2()
        
    return Rect2(
        Vector2(layer.tile_set.tile_size.x * local_coords.x, layer.tile_set.tile_size.y * local_coords.y), 
        layer.tile_set.tile_size,
    )

## Local space bounding box for content of tile map layer    
static func bounding_box(layer: TileMapLayer) -> Rect2:
    if layer == null:
        return Rect2()
        
    var size: Vector2i = layer.tile_set.tile_size
    var local_logical_rect: Rect2i = layer.get_used_rect() if layer != null else Rect2i()
    return Rect2(local_logical_rect.position * size, local_logical_rect.size * size)

## Perimeter of tile map layer, assuming one contigious mass
static func perimeter(layer: TileMapLayer, allow_truncated: bool = false) -> PackedVector2Array:
    if layer == null:
        return []
        
    var local_coords: Array[Vector2i] = layer.get_used_cells()
    if local_coords.is_empty():
        return []
    
    if local_coords.size() == 1:
        return PackedVector2Array(RectUtils.corners(bounding_box(layer)))
        
    local_coords.sort_custom(func (a: Vector2i, b: Vector2i) -> bool: return a.y < b.y || a.y == b.y && a.x < b.x)
   
    var direction: CardinalDirections.CardinalDirection = CardinalDirections.CardinalDirection.EAST
    var current_coords: Vector2i = local_coords[0]
    var visited_coords: Array[Vector2i] = []
    var visited_sides: Array[CardinalDirections.CardinalDirection] = []
    var points: PackedVector2Array = [get_tile_bbox(layer, current_coords).position]
    if points.resize(local_coords.size() * 4) != OK:
        push_warning("Perimeter points array could not be set to useful size")
    var pt_idx: int = 0
    var pos_x: bool = true
    var pos_y: bool = true
    
    var lap_done: Callable = func (c: Vector2i, s: CardinalDirections.CardinalDirection) -> bool:
        var start: int = 0
        var i: int = 0
        while i < 10:
            var idx: int = visited_coords.find(c, start)
            if idx < 0:
                return false
            if visited_sides[idx] == s:
                return true
            start = idx + 1
            i += 1
            
        return false
            
    while !lap_done.call(current_coords, direction): 
        visited_coords.append(current_coords)                        
        visited_sides.append(direction)        
        
        # Update direction
        var shift_coordinates: bool = false
        var updated_direction: bool = false
        var yaw_ccw: CardinalDirections.CardinalDirection = CardinalDirections.yaw_ccw(direction)[0]
        if local_coords.has(CardinalDirections.translate2d(current_coords, yaw_ccw)):
            direction = yaw_ccw
            updated_direction = true
            match direction:
                CardinalDirections.CardinalDirection.EAST:
                    pos_x = false
                    pos_y = true
                CardinalDirections.CardinalDirection.NORTH:
                    pos_x = true
                    pos_y = true
                CardinalDirections.CardinalDirection.WEST:
                    pos_x = true
                    pos_y = false
                CardinalDirections.CardinalDirection.SOUTH:
                    pos_x = false
                    pos_y = false
            # print_debug("%s has a %s neighbour by ccw rotation" % [current_coords, CardinalDirections.name(direction)])
            shift_coordinates = true
        elif local_coords.has(CardinalDirections.translate2d(current_coords, direction)):
            # We are just continuing on a straight line
            # print_debug("%s has a %s neighbour by straight line" % [current_coords, CardinalDirections.name(direction)])
            shift_coordinates = true
            
        else:
            var yaw_cw: CardinalDirections.CardinalDirection = CardinalDirections.yaw_cw(direction)[0]
            direction = yaw_cw
            updated_direction = true
            match direction:
                CardinalDirections.CardinalDirection.EAST:
                    pos_x = true
                    pos_y = true
                CardinalDirections.CardinalDirection.NORTH:
                    pos_x = true
                    pos_y = false
                CardinalDirections.CardinalDirection.WEST:
                    pos_x = false
                    pos_y = false
                CardinalDirections.CardinalDirection.SOUTH:
                    pos_x = false
                    pos_y = true
            if local_coords.has(CardinalDirections.translate2d(current_coords, yaw_cw)):
                # print_debug("%s has a %s neighbour by cw rotation" % [current_coords, CardinalDirections.name(direction)])
                shift_coordinates = true            
        
        if pt_idx + 1 >= points.size():
            push_error("[TileMapLayer Utils] Constructing the perimeter for %s we ran out of allocated corners %s" % [layer, points])
            if allow_truncated:
                return points
            return []
                         
        # Add point
        if updated_direction:
            var tile_bbox: Rect2 = get_tile_bbox(layer, current_coords)
            # print_debug("Going %s to %s has rect %s" % [CardinalDirections.name(direction), current_coords, tile_bbox])
            pt_idx += 1
            var pt: Vector2 = Vector2(
                tile_bbox.position.x if pos_x else tile_bbox.end.x,
                tile_bbox.position.y if pos_y else tile_bbox.end.y,
            )

            points[pt_idx] = pt
        
        if shift_coordinates:
            # print_debug("Shift coords %s %s" % [current_coords, CardinalDirections.name(direction)])
            current_coords = CardinalDirections.translate2d(current_coords, direction)
            

    if pt_idx > 0 && points[pt_idx] == points[0]:
        pt_idx -= 1
        
    # print_debug("Completed lap %s at %s" % [visited_coords, current_coords])
    points.resize(pt_idx + 1)
    return points
