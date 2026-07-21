# Store marker-only navigation

The Store customer runtime uses eight hand-authored markers and deterministic route composition.

## Invariants

- Before item pickup, customers move only through orthogonal segments.
- A shelf visit is valid only while the shelf belongs to the Store, is in the `shelves` group, is not carried, and has a finite fixed-offset access point.
- Queue positions are logical slots backed by `StorePathQueueFront`, `StorePathQueueBack1`, and `StorePathQueueBack2`.
- After item pickup, a direct segment to the assigned queue slot is allowed.
- Checkout facing uses `StorePathCashier`; service standing uses `StorePathQueueFront`.
- No Store navigation grid, A*, Theta*, D* Lite, path graph, shelf metadata warmup, or background access job is used.
- Shelf placement anchors remain available only for player placement.

## Recovery

An unavailable shelf returns no route. `NPCLiveQueueStateFlow` keeps the NPC in `WAIT_FOR_SHELF`, retries selection, and abandons after its existing timeout. The route controller rebuilds only when the target changes or the stuck watchdog clears the route.
