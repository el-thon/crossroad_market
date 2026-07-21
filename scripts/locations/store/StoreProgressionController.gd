
class_name StoreProgressionController
extends RefCounted


static func can_unlock_mystery_phase(
    human_stock_count: int,
    required_stock: int,
    human_shelf_installed: bool,
    already_unlocked: bool
) -> bool:
    return (
        human_stock_count >= required_stock
        and human_shelf_installed
        and not already_unlocked
    )


static func can_unlock_customer_spawning(
    already_unlocked: bool,
    ghost_shelf_installed: bool,
    ghost_shelf: Shelf
) -> bool:
    if already_unlocked:
        return true
    if not ghost_shelf_installed:
        return false
    if ghost_shelf == null or not is_instance_valid(ghost_shelf):
        return false
    var tree: SceneTree = ghost_shelf.get_tree()
    if tree == null:
        return false
    var store: Node = tree.get_first_node_in_group("store")
    if store == null:
        return false
    var routes: Node = store.get("npc_routes") as Node
    if routes == null or not routes.has_method("can_npc_visit_shelf"):
        return false
    routes.call("mark_shelf_navigation_ready", ghost_shelf)
    return ghost_shelf.has_stock() and bool(
        routes.call("can_npc_visit_shelf", ghost_shelf)
    )


static func should_start_day_one_customers_now() -> bool:
    return (
        TimeManager.current_day == 1
        and TimeManager.current_phase != TimeManager.Phase.NIGHT
    )
