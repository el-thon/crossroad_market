# Marker-only Store navigation test plan

1. Run the official Godot 4.7 recursive GDScript compile check.
2. Run `godot --headless --path . --quit`.
3. Repeatedly pick up and place a shelf while the Store is active; placement must not freeze.
4. Open a stocked Human Shelf and spawn a customer; entry and shelf movement must remain orthogonal.
5. After item pickup, verify direct movement to the assigned queue marker.
6. Test two and three customers through Back2 -> Back1 -> Front -> checkout -> exit.
7. Pick up a target shelf while a customer walks toward it; the customer waits, retries after replacement, or exits after timeout.
8. Stock and install the Ghost Shelf; night customer spawning must unlock.
9. Verify Store -> Storage -> Store shelf persistence.
