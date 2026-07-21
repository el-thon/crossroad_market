from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def replace_once(path: str, old: str, new: str) -> None:
    target = ROOT / path
    text = target.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"Expected one match in {path}, found {count}: {old!r}")
    target.write_text(text.replace(old, new), encoding="utf-8")


replace_once(
    "scripts/npc/runtime/NPCRouteController.gd",
    '''func get_store_route_provider() -> Node:
\t@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
\tvar tree: SceneTree = npc.get_tree()

\tif tree == null:
\t\treturn null

\treturn tree.get_first_node_in_group("store")''',
    '''func get_store_route_provider() -> Node:
\tvar tree: SceneTree = npc.get_tree()
\tif tree == null:
\t\treturn null

\tvar store_node: Node = tree.get_first_node_in_group("store")
\tif store_node == null:
\t\treturn null

\tvar route_provider_variant: Variant = store_node.get("npc_routes")
\tif is_instance_valid(route_provider_variant) and route_provider_variant is Node:
\t\treturn route_provider_variant as Node
\treturn store_node''',
)

replace_once(
    "scripts/npc/runtime/NPCRouteController.gd",
    '''\t\t# Never replace a failed store route with a direct segment. Direct
\t\t# fallbacks were allowing NPCs to skip markers and cross PhysicsBody2D
\t\t# obstacles. An exiting NPC waits and retries; other states safely
\t\t# transition to the normal graph-based exit state.''',
    '''\t\t# Never replace a failed pre-item Store route with an unplanned direct
\t\t# segment. The marker provider owns the allowed direct movement after
\t\t# item pickup; failures here wait/retry through the watchdog.''',
)

replace_once(
    "scripts/npc/runtime/NPCRouteController.gd",
    '''\t# Store movement must wait for a valid graph route. Falling back to a
\t# direct destination makes NPCs cut across queue markers, shelves, items,
\t# counters, and other static physics bodies.''',
    '''\t# Store movement waits for a valid marker route. Direct post-item travel
\t# is returned explicitly by the marker provider, never invented here.''',
)

store_path = ROOT / "scripts/locations/store/Store.gd"
store_text = store_path.read_text(encoding="utf-8")

old_block = '''func get_npc_route_to_cashier_from(from_position: Vector2) -> Array[Vector2]:
\tif npc_routes != null:
\t\treturn npc_routes.get_npc_route_to_cashier_from(from_position)

\treturn []


@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func get_npc_route_to_queue_target_from(from_position: Vector2, queue_index: int) -> Array[Vector2]:
\tif npc_routes != null:
\t\treturn npc_routes.get_npc_route_to_queue_target_from(from_position, queue_index)

\treturn []
'''

new_block = '''func get_npc_route_to_cashier_from(
\tfrom_position: Vector2,
\tnpc_node: Node = null
) -> Array[Vector2]:
\tif npc_routes != null:
\t\treturn npc_routes.get_npc_route_to_cashier_from(
\t\t\tfrom_position,
\t\t\tnpc_node
\t\t)
\treturn []


@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func get_npc_route_to_queue_target_from(
\tfrom_position: Vector2,
\tqueue_index: int,
\tnpc_node: Node = null
) -> Array[Vector2]:
\tif npc_routes != null:
\t\treturn npc_routes.get_npc_route_to_queue_target_from(
\t\t\tfrom_position,
\t\t\tqueue_index,
\t\t\tnpc_node
\t\t)
\treturn []


@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func get_npc_route_from_shelf_to_queue_target(
\tshelf: Shelf,
\tfrom_position: Vector2,
\tqueue_index: int,
\tnpc_node: Node = null
) -> Array[Vector2]:
\tif npc_routes != null:
\t\treturn npc_routes.get_npc_route_from_shelf_to_queue_target(
\t\t\tshelf,
\t\t\tfrom_position,
\t\t\tqueue_index,
\t\t\tnpc_node
\t\t)
\treturn []
'''

if store_text.count(old_block) != 1:
    raise SystemExit("Store route wrapper block did not match exactly")
store_text = store_text.replace(old_block, new_block)

old_cashier = '''func get_npc_cashier_target(fallback_position: Vector2) -> Vector2:
\tif npc_routes != null:
\t\treturn npc_routes.get_npc_cashier_target(fallback_position)

\treturn fallback_position
'''
new_cashier = old_cashier + '''

@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func get_npc_cashier_face_target(fallback_position: Vector2) -> Vector2:
\tif npc_routes != null:
\t\treturn npc_routes.get_npc_cashier_face_target(fallback_position)
\treturn fallback_position
'''
if store_text.count(old_cashier) != 1:
    raise SystemExit("Cashier target wrapper did not match exactly")
store_text = store_text.replace(old_cashier, new_cashier)

old_shelf_cashier = '''func get_npc_route_from_shelf_to_cashier(shelf: Shelf) -> Array[Vector2]:
\tif npc_routes != null:
\t\treturn npc_routes.get_npc_route_from_shelf_to_cashier(shelf)

\treturn []
'''
new_shelf_cashier = '''func get_npc_route_from_shelf_to_cashier(
\tshelf: Shelf,
\tnpc_node: Node = null
) -> Array[Vector2]:
\tif npc_routes != null:
\t\treturn npc_routes.get_npc_route_from_shelf_to_cashier(
\t\t\tshelf,
\t\t\tnpc_node
\t\t)
\treturn []
'''
if store_text.count(old_shelf_cashier) != 1:
    raise SystemExit("Shelf-to-cashier wrapper did not match exactly")
store_text = store_text.replace(old_shelf_cashier, new_shelf_cashier)

old_exit = '''func get_npc_exit_route_from(from_position: Vector2) -> Array[Vector2]:
\tif npc_routes != null:
\t\treturn npc_routes.get_npc_exit_route_from(from_position)

\treturn []
'''
new_exit = '''func get_npc_exit_route_from(
\tfrom_position: Vector2,
\tnpc_node: Node = null
) -> Array[Vector2]:
\tif npc_routes != null:
\t\treturn npc_routes.get_npc_exit_route_from(from_position, npc_node)
\treturn []


@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func get_npc_single_customer_exit_route(
\tfrom_position: Vector2,
\tnpc_node: Node = null
) -> Array[Vector2]:
\tif npc_routes != null:
\t\treturn npc_routes.get_npc_single_customer_exit_route(
\t\t\tfrom_position,
\t\t\tnpc_node
\t\t)
\treturn []


@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func get_npc_exit_route_from_shelf(
\tshelf: Shelf,
\tfrom_position: Vector2,
\tnpc_node: Node = null
) -> Array[Vector2]:
\tif npc_routes != null:
\t\treturn npc_routes.get_npc_exit_route_from_shelf(
\t\t\tshelf,
\t\t\tfrom_position,
\t\t\tnpc_node
\t\t)
\treturn []
'''
if store_text.count(old_exit) != 1:
    raise SystemExit("Exit wrapper did not match exactly")
store_text = store_text.replace(old_exit, new_exit)

old_cashier_exit = '''func get_npc_exit_route_from_cashier(from_position: Vector2) -> Array[Vector2]:
\tif npc_routes != null:
\t\treturn npc_routes.get_npc_exit_route_from_cashier(from_position)

\treturn []
'''
new_cashier_exit = '''func get_npc_exit_route_from_cashier(
\tfrom_position: Vector2,
\tnpc_node: Node = null
) -> Array[Vector2]:
\tif npc_routes != null:
\t\treturn npc_routes.get_npc_exit_route_from_cashier(
\t\t\tfrom_position,
\t\t\tnpc_node
\t\t)
\treturn []
'''
if store_text.count(old_cashier_exit) != 1:
    raise SystemExit("Cashier exit wrapper did not match exactly")
store_text = store_text.replace(old_cashier_exit, new_cashier_exit)

store_path.write_text(store_text, encoding="utf-8")

for redundant in (
    "docs/store-marker-only-api.md",
    "docs/store-marker-only-migration-scope.md",
    "docs/store-marker-only-notes.md",
    "docs/store-marker-only-review-checklist.md",
):
    path = ROOT / redundant
    if path.exists():
        path.unlink()

print("Marker-only route facade finalized.")
