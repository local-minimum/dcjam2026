@tool
extends Node2D
class_name Grid2D

## If the grid is centered on the tiles, this should be half the tile size with relevant signs
@export var _tile_start_offset: Vector2:
    set(value):
        _tile_start_offset = value
        if show_grid:
            queue_redraw()

@export var tile_size: Vector2:
    set(value):
        tile_size = value
        if show_grid:
            queue_redraw()
            
@export var extent: Rect2i:
    set(value):
        extent = value
        if show_grid:
            queue_redraw()

## The bounding box of the grid, takes the tile start offset into account
var bounding_box: Rect2:
    get():
        return Rect2(Vector2(extent.position) * tile_size + _tile_start_offset, Vector2(extent.size) * tile_size)    
            
@export_group("Drawing")
@export var show_grid: bool:
    set(value):
        show_grid = value
        queue_redraw()
        
@export var line_width: float = 1:
    set(value):
        line_width = value
        if show_grid:
            queue_redraw()
            
@export var line_color: Color = Color.MIDNIGHT_BLUE:
    set(value):
        line_color = value
        if show_grid:
            queue_redraw()

func is_inside_grid(global_point: Vector2, tolerance: float = 0.0) -> bool:
    var local: Vector2 = to_local(global_point)
    return (
        local.x + tolerance >= extent.position.x * tile_size.x &&
        local.x - tolerance < extent.end.x * tile_size.x &&
        local.y + tolerance >= extent.position.y * tile_size.y &&
        local.y - tolerance < extent.end.y * tile_size.y
    )
    
func get_closest_coordinates(global_point: Vector2) -> Vector2i:
    var local: Vector2 = to_local(global_point)
    var coords: Vector2i = Vector2i(roundi(local.x / tile_size.x), roundi(local.y / tile_size.y))
    
    return RectUtils.clamp_pointi(extent, coords)

func get_global_point(coordinates: Vector2i, overflow: bool = false) -> Vector2:
    if !overflow:
        coordinates = RectUtils.clamp_pointi(extent, coordinates)
    
    return to_global(
        Vector2(
            coordinates.x * tile_size.x,
            coordinates.y * tile_size.y,
        )
    )
    
func get_global_pointf(coordinates: Vector2, overflow: bool = false) -> Vector2:
    if !overflow:
        coordinates = RectUtils.clamp_pointf(extent, coordinates)
    
    return to_global(
        Vector2(
            coordinates.x * tile_size.x,
            coordinates.y * tile_size.y,
        )
    )

# Get rect for tile/cell in the reference system of the grid    
func get_grid_cell_rect(coordinates: Vector2i, overflow: bool = false) -> Rect2:
    if !overflow:
        coordinates = RectUtils.clamp_pointi(extent, coordinates)
    
    return Rect2(
        Vector2(
            coordinates.x * tile_size.x + _tile_start_offset.x,
            coordinates.y * tile_size.y + _tile_start_offset.y,
        ),
        tile_size,
    )
    
func _ready() -> void:
    if show_grid:
        queue_redraw()

func _draw() -> void:
    if !show_grid:
        return
    
    if extent.size.x == 0 || extent.size.y == 0:
        return
        
    var bb: Rect2 = bounding_box
    for row: float in range(bb.position.y, bb.end.y, tile_size.y):
        draw_line(
            Vector2(bb.position.x, row), 
            Vector2(bb.end.x, row),
            line_color,
            line_width,
        )
    
    draw_line(
        Vector2(bb.position.x, bb.end.y),
        Vector2(bb.end.x, bb.end.y),
        line_color,
        line_width,
    )
    
    
    for col: float in range(bb.position.x, bb.end.x, tile_size.x):
        draw_line(
            Vector2(col, bb.position.y), 
            Vector2(col, bb.end.y),
            line_color,
            line_width,
        )
    
    draw_line(
        Vector2(bb.end.x, bb.position.y),
        Vector2(bb.end.x, bb.end.y),
        line_color,
        line_width,
    )
