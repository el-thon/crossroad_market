# Crossroad Market — Day 1 Mechanic Polish

## 1. Purpose

Day 1 focuses on **mechanic polish without final art assets**. The goal is not to add major new mechanics, but to make the existing shop loop more stable, readable, testable, and ready for future Aseprite asset integration.

Main rule:

```text
Do not add major new mechanics.
Polish the mechanics that already exist.
Prepare the project so final assets can be swapped in safely later.
```

Every AI Agent / Codex task should improve clarity, stability, feedback, onboarding, UI readability, or asset-readiness without expanding gameplay scope.

---

## 2. Current Polish Context

Core loop:

```text
Player collects stock
→ Player places item on shelf
→ NPC enters the store
→ NPC walks to shelf
→ NPC searches for item
→ NPC takes item
→ NPC queues at cashier
→ Player scans the item
→ Checkout outcome is resolved
→ NPC exits the store
→ Revenue, trust, or story consequence is updated
```

Recent playtest notes that must be treated as **revision tasks**:

```text
- Interaction hint appears after pressing the button, but it should appear before the button is pressed.
- Objective text exists, but its purpose and source must be audited.
- Item/object hover should show the item/object name.
- Shelf pickup after placement is still awkward.
- Trust should appear above relevant NPCs, not as permanent player HUD state.
- Cashier restricted/no-drop area needs visual danger line feedback.
- Input mapping is inconsistent: E/Q/F usage must be standardized.
- Store entry position does not align with the door.
- Cashier Ask Again UI is hard to read because NPC dialogue overlaps the cashier panel.
- Day 1 revenue pacing must ensure normal NPCs provide 40G before the Gooby night branch.
- In-game time / phase split must make Night start at a sensible hour, not keep 18:00 as Day.
```

---

## 3. Scope

### In Scope

- Stabilize player interaction.
- Standardize input mapping for get/place actions.
- Stabilize NPC state flow.
- Improve shelf placement, pickup, and shelf item feedback.
- Improve cashier scan, ask-again, and checkout UI clarity.
- Improve notification, hover label, and dialogue feedback.
- Improve Gooby night choice logic.
- Improve trust/revenue feedback for Gooby.
- Move trust display to NPC world-space UI.
- Add cashier restricted area danger line as non-blocking visual feedback.
- Improve Day 1 time pacing and NPC spawn pacing.
- Prepare placeholder node structure for later sprite replacement.
- Document mechanic behavior and expected outcomes.

### Out of Scope

- Farming, crafting, skill tree, store expansion, or new major gameplay system.
- New story branches beyond existing Gooby night choice.
- Complex quest system, full minimap, or cutscene tutorial system.
- Replacing all final assets before the asset pack is ready.
- Reworking the whole architecture at once.

If a proposed change creates a new way to play, it is likely a new mechanic. If it explains, stabilizes, clarifies, or makes an existing action readable, it can be treated as polish.

---

## 4. Recommended Execution Order

Use this document as a task spec.

```text
1 prompt = 1 task or 1 small subtask
```

Recommended revised order:

```text
Task 1  — Standardize Input Mapping: E Get, Q Put
Task 2  — Revise Interaction Prompt Timing
Task 3  — Add Hover / Object Name Feedback
Task 4  — Polish Shelf Pickup Reachability
Task 5  — Fix Store Door Entry Alignment
Task 6  — Move Trust Display to NPC World UI
Task 7  — Polish Cashier Restricted Area Danger Line
Task 8  — Polish Cashier Ask Again UI
Task 9  — Audit Objective HUD Guidance
Task 10 — Validate Gooby Night Choice
Task 11 — Polish Day Revenue Pacing to 40G
Task 12 — Polish Time / Phase Split
Task 13 — Polish Activity Board / Action Guidance
Task 14 — Polish NPC Flow
Task 15 — Polish Cashier Flow
Task 16 — Polish Shelf and Item Flow
Task 17 — Polish Feedback and Notifications
Task 18 — Review Core Loop
Task 19 — Prepare Asset-Ready Node Structure
Task 20 — Documentation Update
```

Current task status:

```text
Task 1  — Pending revision
Task 2  — Pending revision
Task 3  — Pending
Task 4  — Pending revision
Task 5  — Pending
Task 6  — Pending revision
Task 7  — Pending
Task 8  — Pending
Task 9  — Pending audit / possible revision
Task 10 — Implemented, needs validation
Task 11 — Pending
Task 12 — Pending
Task 13 — Implemented, needs validation
Task 14 — Implemented, needs validation
Task 15 — Implemented, needs validation
Task 16 — Implemented, needs validation
Task 17 — Implemented, needs validation
Task 18 — Pending manual full-loop playtest
Task 19 — Implemented, needs validation
Task 20 — Ongoing
```

---

## 5. Task 1 — Standardize Input Mapping: E Get, Q Put

### Goal

Standardize player input so the interaction language is consistent across shelves, shelf items, and supply boxes.

Final Day 1 input rule:

```text
E = get / take / pick up / retrieve / interact
Q = put / place / stock / drop
```

Expected mapping:

```text
SupplyBox:
- Press E to get stock/item from supply box.

Shelf object:
- Press E to pick up / retrieve shelf.
- Press Q to put/drop shelf in store.

Shelf item slot:
- Press Q to put/place currently carried item into shelf.
- Press E to get/take item from shelf if that action is available.

Cashier:
- Press E to interact / serve customer.
```

### Checklist

- [ ] Input hints use the same wording everywhere.
- [ ] SupplyBox uses E for get/take stock.
- [ ] Shelf pickup uses E.
- [ ] Shelf drop/place uses Q.
- [ ] Shelf stocking uses Q.
- [ ] Shelf item retrieval uses E if available.
- [ ] Cashier interaction remains E.
- [ ] No prompt still says F for get/pickup unless F is intentionally kept as secondary/debug.
- [ ] Existing input map is audited so `carry`, `interact`, and `take_shelf_item` naming does not confuse implementation.

### Test Cases

```text
INPUT-01 — SupplyBox Get
Move near supply box.
Expected: Prompt says Press E to get stock.

INPUT-02 — Shelf Pickup
Move near shelf.
Expected: Prompt says Press E to pick up shelf.

INPUT-03 — Shelf Put / Drop
Carry shelf in store.
Expected: Prompt or feedback says Press Q to put/drop shelf.

INPUT-04 — Shelf Stocking
Carry item near shelf.
Expected: Prompt says Press Q to place item on shelf.
```

### AI Agent Prompt

```text
Analisa dan implementasikan Task 1 — Standardize Input Mapping: E Get, Q Put dari docs/polish/day-1-mechanic-polish.md.

Batasan:
- Jangan tambah mechanic baru.
- Fokus existing input mapping, hints, player interaction, shelf, and supply box.
- E harus menjadi action untuk get/take/pick up/retrieve.
- Q harus menjadi action untuk put/place/stock/drop.
- Cashier tetap E untuk interact/serve.
- Update prompt text agar konsisten dengan mapping baru.
- Cek project.godot input map, Player, Shelf, SupplyBox, Store, HUD interaction hints.

Expected output:
- File yang dicek.
- Mapping input sebelum/sesudah.
- Perubahan yang dibuat.
- Test INPUT-01 sampai INPUT-04.
```

---

## 6. Task 2 — Revise Interaction Prompt Timing

### Goal

Interaction prompts must appear **before** the player presses the action key.

Expected flow:

```text
Player enters object InteractionArea / CollisionShape2D
→ Prompt appears immediately
→ Prompt says object name and available action
→ Player presses input
→ Action happens
```

Tutorial explanation for new object/item/activity should run only once per object type or item type.

### Checklist

- [ ] Prompt appears when player enters interaction area.
- [ ] Prompt appears before button press.
- [ ] Prompt identifies object/item name.
- [ ] Prompt explains the correct input using new E/Q rule.
- [ ] Prompt disappears when player leaves area.
- [ ] Prompt does not block player input.
- [ ] Tutorial explanation runs once per item/object type.
- [ ] Compact action prompt can repeat if needed.
- [ ] Prompt works for shelf, supply box, cashier, activity board, ghost shelf, and items.

### AI Agent Prompt

```text
Analisa dan implementasikan Task 2 — Revise Interaction Prompt Timing dari docs/polish/day-1-mechanic-polish.md.

Batasan:
- Jangan tambah mechanic baru.
- Prompt harus muncul saat player memasuki area interaksi, sebelum tombol ditekan.
- Tutorial explanation hanya muncul 1 kali per item/object/activity baru.
- Prompt harus mengikuti mapping baru: E=get/interact, Q=put/place.
- Jangan gunakan notification blocking untuk prompt kecil.

Expected output:
- Penyebab timing hint salah.
- File yang dicek.
- Perubahan yang dibuat.
- Test prompt shelf, supplybox, cashier, item baru.
```

---

## 7. Task 3 — Add Hover / Object Name Feedback

### Goal

When player hovers or enters interaction range of an item/object, the game should show the object name.

Expected behavior:

```text
Player enters item/object hover area
→ Name label appears
→ Optional action prompt appears
→ Player leaves area
→ Name label disappears
```

Hover/name feedback can repeat. Tutorial explanation should not loop.

### Checklist

- [ ] Hover/proximity label shows object name.
- [ ] Label appears before input.
- [ ] Label disappears when player leaves range.
- [ ] Label works for items, shelves, cashier, board, and supply boxes.
- [ ] Label follows E/Q prompt wording.
- [ ] Label does not overlap major HUD elements.

---

## 8. Task 4 — Polish Shelf Pickup Reachability

### Goal

Fix shelf pickup and shelf placement usability, especially after player places shelf in the store and needs to retrieve another shelf.

Design rule:

```text
CollisionShape2D = physical blocking / body collision.
InteractionArea = detection for prompt and pickup.
```

Do not make the physical collision huge just to make pickup easier. Expand the interaction area instead.

### Checklist

- [ ] Shelf physical collision stays normal.
- [ ] Shelf pickup detection uses larger reachable interaction area.
- [ ] Prompt appears before pickup input.
- [ ] Shelf pickup uses E.
- [ ] Shelf put/drop uses Q.
- [ ] Player can pick shelf up again after placing it in store.
- [ ] Enlarged interaction area does not conflict with cashier, door, or activity board.
- [ ] Shelf still cannot be placed in invalid no-drop zones.

---

## 9. Task 5 — Fix Store Door Entry Alignment

### Goal

Fix player spawn/return position when entering the store so it matches the actual door location.

Current issue:

```text
Player enters store, but the resulting position does not visually align with the door.
```

### Design Requirements

- Door transition should place player at the correct marker near the door.
- Player should face away from the door after entering, if facing direction is supported.
- Return marker should not place player inside collision, door trigger, shelf, cashier area, or wall.
- Storage return and yard/store return should be checked separately.
- Marker names should be explicit and stable for asset integration.

Recommended marker naming:

```text
StorageReturnPos
YardReturnPos
StoreEntranceReturnPos
PlayerSpawn
```

### Checklist

- [ ] Store entry position aligns with visible door.
- [ ] Storage return marker aligns with StorageDoor.
- [ ] Yard return marker aligns with YardDoor if applicable.
- [ ] Player does not spawn inside door trigger and instantly transition again.
- [ ] Player does not spawn inside wall/collision/shelf/cashier restricted area.
- [ ] Spawn marker remains stable for final asset replacement.

### AI Agent Prompt

```text
Analisa dan implementasikan Task 5 — Fix Store Door Entry Alignment dari docs/polish/day-1-mechanic-polish.md.

Batasan:
- Jangan tambah mechanic baru.
- Fokus marker/door transition position yang sudah ada.
- Player harus muncul sesuai posisi door saat kembali ke store.
- Jangan spawn player di dalam trigger door sehingga langsung masuk lagi.
- Cek Store.tscn, Storage.tscn, Store.gd, transition controller, marker nodes.

Expected output:
- File/scene yang dicek.
- Penyebab posisi enter store tidak sesuai.
- Marker yang diperbaiki.
- Test return from storage, no instant re-entry, blocked return safety.
```

---

## 10. Task 6 — Move Trust Display to NPC World UI

### Goal

Trust is not a permanent player HUD score. Trust belongs to relevant story NPCs and should be displayed near/above the NPC.

Expected temporary display:

```text
Gooby
Trust: 20/100
```

### Checklist

- [ ] Remove or hide permanent Gooby Trust label from player HUD.
- [ ] Add trust label/bar above Gooby or story NPC visual root.
- [ ] Trust label follows NPC movement.
- [ ] Trust updates after Gooby interaction.
- [ ] RelationshipManager remains source of truth.
- [ ] Generic NPCs do not show unnecessary trust bars.

---

## 11. Task 7 — Polish Cashier Restricted Area Danger Line

### Goal

Cashier restricted/no-drop area must have clear visual feedback when player tries to place a shelf too close to cashier/counter.

Expected behavior:

```text
Player carries shelf
→ Player tries to put/drop shelf in cashier restricted area
→ Drop is rejected
→ Player keeps carrying shelf
→ Danger line appears around cashier restricted area
→ Danger line fades in/out for 2 seconds
→ Animation repeats 3 times
→ Danger line hides again
```

### Checklist

- [ ] Cashier restricted area exists and is used by shelf drop validation.
- [ ] Invalid shelf drop near cashier is rejected.
- [ ] Player keeps carrying shelf after invalid drop.
- [ ] Feedback text appears.
- [ ] Danger line surrounds restricted area.
- [ ] Danger line fades in/out for 2 seconds.
- [ ] Fade cycle repeats 3 times.
- [ ] Danger line hides after animation.
- [ ] Animation can be triggered again after another invalid attempt.
- [ ] Danger line does not interfere with NPC queue/cashier UI.

---

## 12. Task 8 — Polish Cashier Ask Again UI

### Goal

Fix cashier Ask Again readability. The player should not need to “peek” behind the cashier panel to read NPC dialogue.

Current issue:

```text
When Ask Again is pressed, NPC speech/dialogue appears but is visually covered or hidden by the cashier panel.
```

### Recommended UI Direction

Best temporary solution:

```text
Show repeated customer request inside the cashier panel itself.
```

Example panel layout:

```text
SCAN
Customer: Gooby
Request: "I want Phantom Ice Cream."
Selected: - | Total 0G

[Confirm Scan] [Ask Again 1/3] [Close]
```

When Ask Again is pressed:

```text
Request text inside the panel updates / flashes.
NPC world bubble is optional, but it should not be required to understand the request.
```

### Checklist

- [ ] Ask Again response is readable inside cashier panel.
- [ ] NPC dialogue bubble can still appear, but it is not the only source of information.
- [ ] Cashier panel does not cover critical request text.
- [ ] Ask Again count remains visible.
- [ ] Player can still close/back/confirm safely.
- [ ] Works for normal NPC and Gooby.
- [ ] UI remains readable at 480x270.

### AI Agent Prompt

```text
Analisa dan implementasikan Task 8 — Polish Cashier Ask Again UI dari docs/polish/day-1-mechanic-polish.md.

Batasan:
- Jangan tambah cashier minigame baru.
- Fokus readability Ask Again pada existing cashier panel.
- Ketika Ask Again ditekan, requested item/dialog harus terbaca di panel cashier.
- NPC bubble boleh tetap ada, tapi tidak boleh menjadi satu-satunya sumber info.
- Jangan merusak Gooby choice panel.
- Cek Cashier.gd, CashierPanel.gd, NPC repeat_checkout_request/dialog flow.

Expected output:
- File yang dicek.
- Penyebab Ask Again sulit dibaca.
- Perubahan UI yang dibuat.
- Test normal NPC Ask Again, Gooby Ask Again, overlay safety.
```

---

## 13. Task 9 — Audit Objective HUD Guidance

### Goal

Clarify whether objective text should exist as HUD, activity board, or contextual hint.

Recommendation for Day 1:

```text
Contextual interaction hints = primary guidance.
Activity Board = optional backup guidance.
HUD objective = only if short, non-overlapping, and clearly useful.
```

### Checklist

- [ ] Identify where ObjectiveLabel is created.
- [ ] Identify which file updates objective text.
- [ ] Decide whether objective remains in HUD, moves to board, or is replaced by contextual hints.
- [ ] If retained, objective is one-line only.
- [ ] If removed, board/hints still guide the player.

---

## 14. Task 10 — Validate Gooby Night Choice

### Goal

Validate existing Gooby branch.

Expected branch:

```text
Gift Gooby
→ Trust increases
→ Revenue +0G
→ Slime does not spawn
→ Daily target can be missed

Refuse Gooby
→ Trust behavior follows agreed story rule
→ Revenue +0G from Gooby
→ Item returns to ghost shelf
→ Slime spawns once
→ Slime buys item normally
→ Revenue reaches target
```

### Checklist

- [ ] Gooby gift option visible.
- [ ] Gift does not add gold/revenue.
- [ ] Gift increases trust.
- [ ] Gift does not spawn Slime.
- [ ] Refuse returns item.
- [ ] Refuse spawns Slime once.
- [ ] Slime purchase adds revenue normally.
- [ ] Trust display appears above Gooby or relevant NPC, not permanent HUD.

---

## 15. Task 11 — Polish Day Revenue Pacing to 40G

### Goal

Before the Gooby night branch, normal NPC purchases should total **40G**, leaving the final 10G decision to the Gooby/Slime branch.

Design target:

```text
Before Night / before Gooby consequence:
Normal NPC revenue = 40G
Daily target = 50G
Remaining gap = 10G

Gift Gooby:
+0G, trust increases, target remains 40/50.

Refuse Gooby:
+0G from Gooby, Slime appears and buys item for +10G, target becomes 50/50.
```

### NPC Pacing Idea

If player finishes shelf setup at time `T`, and the Day customer window ends at `18:00`, spawn 4 normal buying NPCs evenly across the remaining window.

Example:

```text
Player finishes shelf management at 10:00
Day customer window: 10:00 → 18:00 = 8 hours
Normal NPC count: 4
Spawn interval: 8 / 4 = 2 hours
```

If remaining window is 10 hours and 4 NPCs are needed:

```text
Spawn interval = 10 / 4 = 2.5 hours
```

### Checklist

- [ ] Normal Day NPCs total 40G before night branch.
- [ ] Day 1 target remains 50G.
- [ ] Revenue path is branch-dependent only for last 10G.
- [ ] Gift Gooby keeps target missed.
- [ ] Refuse Gooby allows Slime to finish target.
- [ ] Spawn interval adapts to time remaining before 18:00.
- [ ] Store setup completion time controls when normal customer pacing starts.
- [ ] No duplicate NPC spawn exploit.

### AI Agent Prompt

```text
Analisa dan implementasikan Task 11 — Polish Day Revenue Pacing to 40G dari docs/polish/day-1-mechanic-polish.md.

Batasan:
- Jangan tambah mechanic baru.
- Fokus Day 1 normal NPC spawn/revenue pacing yang sudah ada.
- Target harian tetap 50G.
- Normal NPC sebelum night harus menghasilkan total 40G.
- Gooby tidak menambah revenue.
- Gift Gooby membuat target tetap tidak tercapai.
- Refuse Gooby memicu Slime sebagai jalur sisa 10G.
- Hitung interval spawn berdasarkan waktu selesai setup shelf sampai jam 18:00.
- Cek NPCScheduler, TimeManager, EconomyManager, Store progression readiness.

Expected output:
- File yang dicek.
- Revenue pacing saat ini.
- Perubahan spawn interval/revenue yang dibuat.
- Test store ready early, gift Gooby, refuse Gooby, late store setup.
```

---

## 16. Task 12 — Polish Time / Phase Split

### Goal

Fix in-game time phase split so `18:00` is not treated as Day. Night should begin at a sensible hour.

Recommended Day 1 phase split:

```text
Morning / Setup: 08:00 → 10:00
Day / Store Open: 10:00 → 18:00
Night / Strange Customers: 18:00 → 22:00
End / Report: after 22:00
```

Alternative if the prototype needs more setup time:

```text
Morning / Setup: 08:00 → 11:00
Day / Store Open: 11:00 → 18:00
Night / Strange Customers: 18:00 → 22:00
```

Recommendation:

```text
Use 18:00 as the start of Night.
Do not keep 18:00 inside Day.
```

### Checklist

- [ ] 18:00 is Night, not Day.
- [ ] Day NPCs spawn before 18:00.
- [ ] Gooby spawns after Night starts.
- [ ] Slime consequence has enough time to happen during Night.
- [ ] HUD phase label matches current time.
- [ ] Existing TimeManager signals still work.

### AI Agent Prompt

```text
Analisa dan implementasikan Task 12 — Polish Time / Phase Split dari docs/polish/day-1-mechanic-polish.md.

Batasan:
- Jangan tambah mechanic baru.
- Fokus TimeManager / phase boundary yang sudah ada.
- 18:00 harus menjadi Night, bukan Day.
- Day NPC pacing harus selesai sebelum 18:00.
- Gooby dan Slime hanya berjalan pada Night.
- HUD time/phase harus sesuai.
- Jangan merusak day_started, phase_changed, day_ended, daily report flow.

Expected output:
- File yang dicek.
- Pembagian waktu saat ini.
- Pembagian waktu baru.
- Perubahan yang dibuat.
- Test 17:59 Day, 18:00 Night, Gooby spawn, Slime consequence.
```

---

## 17. Task 13 — Polish Activity Board / Action Guidance

Checklist:

- [ ] Board explains current activity clearly.
- [ ] Board text updates at major existing milestones if implemented.
- [ ] Board does not introduce new rewards/unlocks.
- [ ] Board UI can be closed safely.
- [ ] Board does not conflict with cashier UI.
- [ ] Board can be replaced with final board sprite later.

---

## 18. Task 14 — Polish NPC Flow

Checklist:

- [ ] NPC spawns at entrance.
- [ ] NPC walks to correct shelf.
- [ ] NPC does not exit without clear reason.
- [ ] NPC pauses/searches briefly at shelf.
- [ ] NPC takes item if available.
- [ ] NPC joins queue after taking item.
- [ ] NPC only enters checkout when first in queue.
- [ ] NPC exits after checkout outcome resolves.
- [ ] Gooby and Slime follow readable NPC movement flow.

---

## 19. Task 15 — Polish Cashier Flow

Checklist:

- [ ] Cashier only processes valid checkout NPC.
- [ ] Cashier tells player if no customer is waiting.
- [ ] Cashier tells player if customer is still walking.
- [ ] Scan mismatch gives clear feedback.
- [ ] Correct scan leads to checkout resolution.
- [ ] Normal paid checkout increases daily revenue.
- [ ] Gooby checkout uses Gooby choice panel.
- [ ] Ask Again UI is readable inside the cashier panel.
- [ ] Checkout state resets after payment, gift, refusal, or cancel.

---

## 20. Task 16 — Polish Shelf and Item Flow

Checklist:

- [ ] Player can place valid item on matching shelf type.
- [ ] Wrong shelf placement gives clear feedback.
- [ ] Shelf slot limit is respected.
- [ ] Item leaves inventory when placed on shelf.
- [ ] Item leaves shelf when taken by NPC.
- [ ] Item can return to shelf after Gooby refusal.
- [ ] Returned Phantom Ice Cream can be found by Slime.
- [ ] No item duplication after Gooby refusal.
- [ ] No item loss after Gooby gift.
- [ ] Shelf placement rejects no-drop zones.
- [ ] If all drop positions are unsafe, player keeps carrying shelf.

---

## 21. Task 17 — Polish Feedback and Notifications

Checklist:

- [ ] Notifications explain important state changes.
- [ ] Interaction prompts are not blocking long notifications.
- [ ] Hover/object labels are separate from tutorial prompts.
- [ ] Gooby gift/refuse feedback is readable.
- [ ] Cashier danger line feedback is non-blocking.
- [ ] Notification does not cover cashier choices.

---

## 22. Task 18 — Review Core Loop

Checklist:

- [ ] Player can start Day 1 and understand first action.
- [ ] Player can bring shelf from storage.
- [ ] Player can stock human shelf.
- [ ] Day NPCs can buy enough for 40G before Night.
- [ ] Ghost shelf / mystery flow can be reached.
- [ ] Night starts at 18:00.
- [ ] Gooby arrives at Night.
- [ ] Gift path misses daily target.
- [ ] Refuse path enables Slime to finish target.
- [ ] Interaction prompts appear before input.
- [ ] Hover/object name feedback is readable.
- [ ] Shelf pickup remains reliable.
- [ ] Cashier restricted area danger line appears correctly.
- [ ] Player never loses control due to stuck UI state.

---

## 23. Task 19 — Prepare Asset-Ready Node Structure

Recommended pattern:

```text
NPC
├── VisualRoot
│   ├── PlaceholderRect
│   └── AnimatedSprite2D
├── NameLabel
├── TrustBar / TrustLabel
├── DialogBubble
├── CollisionShape2D
└── InteractionArea
```

Checklist:

- [ ] Visual nodes are separated from logic nodes.
- [ ] Collision shapes do not depend directly on placeholder size.
- [ ] Interaction areas remain stable when sprite changes.
- [ ] NPC trust world UI can later be replaced with final trust bar art.
- [ ] Cashier danger line can later be replaced with final warning floor art.
- [ ] Interaction hint UI can later be replaced with final prompt art.

---

## 24. Task 20 — Documentation Update

Checklist:

- [ ] Mark tasks as done / partially done / pending.
- [ ] Add discovered bugs to relevant task sections.
- [ ] Add new test cases if playtest reveals missing cases.
- [ ] Keep implementation notes aligned with actual behavior.
- [ ] Keep Day 1 scope focused on polish, not feature expansion.

---

## 25. Definition of Done — Day 1

Day 1 can be considered done when:

- [ ] E consistently means get/take/pick up/interact.
- [ ] Q consistently means put/place/stock/drop.
- [ ] Core shop loop can be played from setup to checkout.
- [ ] Store door entry/return position aligns with visible door.
- [ ] Day NPCs generate 40G before Night branch.
- [ ] Night starts at 18:00.
- [ ] Gooby gift path gives trust and 0G revenue.
- [ ] Gooby gift path leaves target missed.
- [ ] Gooby refuse path enables Slime revenue path.
- [ ] Slime can complete the remaining 10G target.
- [ ] Trust display appears on relevant NPC, not as permanent player HUD stat.
- [ ] Interaction prompts appear before pressing input.
- [ ] New item/object tutorial prompt runs once per item/object type.
- [ ] Hover/object name feedback works.
- [ ] Player can reliably pick up shelves after placement.
- [ ] Cashier Ask Again text is readable inside cashier panel.
- [ ] Cashier restricted area shows danger line fade in/out 2 seconds x 3 cycles.
- [ ] Objective guidance source is understood and does not confuse HUD purpose.
- [ ] Temporary UI is readable at 480x270.
- [ ] Project remains ready for Aseprite asset integration.

---

## 26. Suggested Trello / Branch Naming

Trello activities:

```text
standardize_input_e_get_q_put_day_1
revise_interaction_prompt_timing_day_1
add_hover_object_name_feedback_day_1
polish_shelf_pickup_reachability_day_1
fix_store_door_entry_alignment_day_1
move_trust_display_to_npc_world_ui_day_1
polish_cashier_restricted_danger_line_day_1
polish_cashier_ask_again_ui_day_1
audit_objective_hud_guidance_day_1
validate_gooby_night_choice_day_1
polish_day_revenue_pacing_to_40g_day_1
polish_time_phase_split_day_1
review_core_loop_day_1
prepare_asset_ready_node_structure_day_1
```

Branch:

```text
polish/day-1-mechanic-polish
```

Suggested commit messages:

```text
docs: add input timing pacing and cashier ui revision tasks
fix: standardize player input mapping
fix: align store door return marker
fix: improve cashier ask again readability
fix: pace day one npc revenue before night branch
fix: start night phase at 18
```
