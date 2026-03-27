class_name ControlUtils

static func calculate_anchor_point(
    anchor: CanvasItem,
    floating: Control,
    offset: float = 0,
    forced_vp_margin: Vector2 = Vector2.ZERO,
    fallback_vp_relative_position: Vector2 = Vector2.ONE * 0.5,
) -> Vector2:
    var tt_rect: Rect2 = floating.get_global_rect()

    var vp_rect: Rect2 = anchor.get_viewport_rect()

    var anchor_local_bb: Rect2 = anchor.bounding_box()
    #print_debug(anchor_local_bb)
    var room_position: Vector2 = anchor.to_global(anchor_local_bb.position)
    var room_end: Vector2 = anchor.to_global(anchor_local_bb.end)
    var room_min_x: float = minf(room_position.x, room_end.x)
    var room_min_y: float = minf(room_position.y, room_end.y)
    var room_max_x: float = maxf(room_position.x, room_end.x)
    var room_max_y: float = maxf(room_position.y, room_end.y)

    var fits_above: bool = room_min_y - tt_rect.size.y - offset >= vp_rect.position.y + forced_vp_margin.y
    var fits_flow_right: bool = room_min_x + tt_rect.size.x < vp_rect.end.x - forced_vp_margin.x
    var fits_flow_left: bool = room_max_x - tt_rect.size.x >= vp_rect.position.x + forced_vp_margin.x
    var fits_below: bool = room_max_y + tt_rect.size.y + offset < vp_rect.end.y - forced_vp_margin.y

    if fits_above && fits_flow_right:
        # Use position as anchor and flow to the right
        return Vector2(room_min_x, room_min_y - tt_rect.size.y - offset)

    elif fits_above && fits_flow_left:
        # Use upper right corner as anchor and float to the left
        return Vector2(room_max_x - tt_rect.size.x, room_min_y - tt_rect.size.y - offset)

    elif fits_below && fits_flow_right:
        return Vector2(room_min_x, room_max_y + offset)

    elif fits_below && fits_flow_left:
        return Vector2(room_max_x - tt_rect.size.x, room_max_y + offset)

    else:
        return fallback_vp_relative_position * vp_rect.size + vp_rect.position
