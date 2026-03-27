extends Node
class_name ProbabilityDespawner


@export var _options: Array[ProbabilityDespawnerConfig]
@export var _despawn_on_ready: bool = true

var _invoked: bool

func _ready() -> void:
    if _despawn_on_ready:
        despawn()

func despawn() -> void:
    if _invoked:
        return

    var probs: Array[float] = Array(
        _options.map(func (c: ProbabilityDespawnerConfig) -> float: return c.weight),
        TYPE_FLOAT,
        "",
        null,
    )

    var idx: int = ArrayUtils.pick_weighted_probability_index(probs)
    if idx < 0:
        push_error("%s despawn corrupt, didn't get any index to despawn from %s with total probs %s" % [
            self, _options, probs
        ])
        return

    print_debug("%s of %s will despawn using %s of %s" % [
        self,
        get_parent(),
        _options[idx],
        _options
    ])
    for despawner_path: NodePath in _options[idx].despawners:
        var despawner: Node = get_node(despawner_path)
        if despawner == null:
            push_warning("%s could not find a node at '%s' to despawn" % [self, despawner_path])
            continue

        despawner.queue_free()

    _invoked = true
