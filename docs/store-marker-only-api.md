# Marker-only provider compatibility API

`StoreNpcRoutesRuntime` keeps the Store-facing route methods used by NPC state, shopping, queue, checkout, and exit flows. Legacy access-state methods resolve immediately to `ready` or `invalid`; they do not schedule work.
