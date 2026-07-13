# Crossroad Market — Day 1 Mechanic Polish

## 1. Purpose

Day 1 focuses on **mechanic polish without final art assets**. The goal is not to add major new mechanics, but to make the existing shop loop more stable, readable, testable, and ready for future Aseprite asset integration.

Main rule:

```text
Do not add major new mechanics.
Polish the mechanics that already exist.
Prepare the project so final assets can be swapped in safely later.
```

This document is intended to guide AI Agent / Codex work. Use it as a task spec.

```text
1 prompt = 1 task or 1 small subtask
```

---

## 2. Current Revision Context

Important user decisions:

```text
E = get / take / pick up / interact / serve
Q = put / place / drop / stock
18:00 = Night
Trust belongs to NPC world UI, not permanent player HUD
Normal Day revenue should reach 40G before the Gooby / Slime branch
Gooby gift = trust path, revenue missed
Gooby refuse = revenue path through Slime
```

Recent playtest notes:

```text
- Interaction hints should appear before input.
- Player needs button/click guidance at least once.
- Objective text source must be audited.
- Item/object hover should show names.
- Shelf pickup after placement should be easier.
- Cashier restricted area needs danger-line feedback.
- Cashier restricted warning visual and actual no-drop validation are currently mismatched.
- Store entry position should align with door.
- Cashier Ask Again UI should be readable inside the panel.
- Day/Night timing and Day revenue pacing need adjustment.
- Slime should come after Gooby outcome and react to item availability.
```

---

## 3. Scope

### 3.1 In Scope

Allowed Day 1 polish:

- Stabilize existing player interaction.
- Standardize E/Q input mapping.
- Improve interaction hints and one-time button guidance.
- Improve cashier panel readability and button/click instructions.
- Improve shelf placement, pickup, and no-drop safety.
- Improve cashier restricted area feedback.
- Sync cashier restricted warning visual with actual no-drop validation.
- Improve door transition / entry alignment.
- Improve NPC state flow and normal Day revenue pacing.
- Improve TimeManager phase split so Night starts at 18:00.
- Improve Gooby / Slime night branch clarity.
- Move trust display from player HUD to NPC world-space UI.
- Add hover/name labels for existing items and objects.
- Prepare UI and scene structure for later Aseprite asset replacement.
- Document expected behavior and test cases.

### 3.2 Out of Scope

Not allowed for Day 1 polish:

- Adding farming, crafting, skill trees, or store expansion.
- Adding new maps not needed for the current loop.
- Adding complex quest systems or quest rewards.
- Adding complex relationship systems beyond simple trust tracking.
- Replacing all final assets before the asset pack is ready.
- Reworking the whole architecture at once.
- Adding new story branches beyond the existing Gooby / Slime night decision.

If a proposed change only explains, stabilizes, or clarifies an existing action, it is polish. If it creates a new way to play, treat it as a new mechanic and keep it out of Day 1.

---

## 4. Recommended Execution Order

```text
Task 1  — Standardize Input Mapping: E Get, Q Put
Task 2  — Revise Interaction Prompt Timing
Task 3  — Add One-Time Button / Click Guidance
Task 4  — Add Hover / Object Name Feedback
Task 5  — Polish Shelf Pickup Reachability
Task 6  — Polish Shelf Placement Safety / No-Drop Zones
Task 7  — Polish Cashier Restricted Area Danger Line
Task 8  — Sync Cashier Restricted Area and Warning Visual
Task 9  — Fix Store Door Entry Alignment
Task 10 — Move Trust Display to NPC World UI
Task 11 — Polish Cashier Ask Again UI
Task 12 — Polish Cashier Panel Button Guidance
Task 13 — Audit Objective HUD Guidance
Task 14 — Polish Activity Board / Action Guidance
Task 15 — Polish Time / Phase Split
Task 16 — Polish Day Revenue Pacing to 40G
Task 17 — Revise Gooby / Slime Follow-Up Logic
Task 18 — Validate Gooby Night Choice
Task 19 — Review Full Core Loop
Task 20 — Prepare Asset-Ready Node Structure
Task 21 — Documentation Update
```

Current status:

```text
Treat tasks as pending or needing validation unless Codex has implemented and tested them after this document update.
```

---

## 5. Task 1 — Standardize Input Mapping: E Get, Q Put

### Goal

Make player input consistent across shelf, supply box, cashier, board, and item interactions.

Recommended mapping:

```text
E = interact / get / take / pick up / serve / read
Q = put / place / drop / stock
Esc = close / cancel UI
```

### Checklist

- [ ] Input action names are consistent.
- [ ] Prompt text follows the same E/Q rule.
- [ ] SupplyBox uses E for get/take stock.
- [ ] Shelf pickup uses E.
- [ ] Shelf placement / drop uses Q.
- [ ] Shelf stocking uses Q.
- [ ] Cashier interaction uses E.
- [ ] Board interaction uses E.
- [ ] No prompt contradicts the mapping.

### Codex Prompt

```text
Analisa dan implementasikan Task 1 — Standardize Input Mapping: E Get, Q Put dari docs/polish/day-1-mechanic-polish.md.

Batasan:
- Jangan tambah mechanic baru.
- Fokus konsistensi input existing.
- E berarti interact/get/take/pick up/serve/read.
- Q berarti put/place/drop/stock.
- Update prompt/hint text agar tidak kontradiktif.
- Cek project input map, Player, Shelf, SupplyBox, Cashier, ActivityBoard, HUD hint text sebelum edit.

Expected output:
- File yang dicek.
- Mapping input final.
- Perubahan yang dibuat.
- Test supply box, shelf pickup, shelf placement, shelf stock, cashier, board.
```

---

## 6. Task 2 — Revise Interaction Prompt Timing

### Goal

Prompt interaction should appear **before** the player presses the input, when the player enters the relevant interaction area.

Expected flow:

```text
Player enters object InteractionArea / CollisionShape2D
→ Prompt appears immediately
→ Prompt shows object name and available action
→ Player presses E or Q
→ Action happens
```

### Checklist

- [ ] Prompt appears on area enter / hover / proximity.
- [ ] Prompt appears before pressing E/Q.
- [ ] Prompt disappears on area exit.
- [ ] Prompt identifies object/item name.
- [ ] Prompt explains the correct input.
- [ ] Prompt does not block player movement.
- [ ] Prompt does not overlap cashier modal / board modal.

### Codex Prompt

```text
Analisa dan implementasikan Task 2 — Revise Interaction Prompt Timing dari docs/polish/day-1-mechanic-polish.md.

Batasan:
- Jangan tambah mechanic baru.
- Prompt harus muncul saat player memasuki interaction area, sebelum input ditekan.
- Prompt harus mengikuti mapping E/Q dari Task 1.
- Jangan gunakan blocking notification untuk prompt kecil.
- Cek Player interaction detection, HUD hint label, Shelf, SupplyBox, Cashier, ActivityBoard, dan item/object interaction areas.

Expected output:
- Penyebab timing hint salah.
- File yang dicek.
- Perubahan yang dibuat.
- Test prompt shelf, supply box, cashier, board, item.
```

---

## 7. Task 3 — Add One-Time Button / Click Guidance

### Goal

Player should receive clear guidance at least once about what each input/button does. This is especially important because E/Q are contextual.

### Expected Behavior

```text
First time near Supply Box:
Show: Supply Box — Press E to take stock.

First time carrying an item near Shelf:
Show: Shelf — Press Q to place item here.

First time near placed Shelf:
Show: Shelf — Press E to pick up shelf.

First time opening Cashier Panel:
Show short panel guide explaining what each button does.
```

After the first explanation:

```text
Only compact prompts repeat, not the long tutorial explanation.
```

### Cashier Panel Button Guidance

```text
Confirm Scan — process selected item.
Ask Again — repeat the customer's request.
Close — cancel / leave cashier panel.
Give Item — give item for trust, no gold.
Refuse Sale — return item and continue the night consequence.
Receive Payment — finish normal paid checkout.
```

### Checklist

- [ ] First-time button guidance exists for core input mapping.
- [ ] Cashier panel has clear button labels or one-time guidance.
- [ ] Guidance runs once per input/object/panel category.
- [ ] Guidance does not loop every time.
- [ ] Guidance does not block cashier decision flow.
- [ ] Compact prompts still appear after first-time guidance.

### Codex Prompt

```text
Analisa dan implementasikan Task 3 — Add One-Time Button / Click Guidance dari docs/polish/day-1-mechanic-polish.md.

Batasan:
- Jangan tambah mechanic baru.
- Tambahkan informasi button/click minimal sekali agar player tidak bingung.
- Jangan membuat tutorial panjang yang selalu looping.
- Cashier panel harus menjelaskan fungsi tombol penting dengan jelas.
- Gunakan flag/set sederhana untuk first-time guidance jika dibutuhkan.

Expected output:
- File yang dicek.
- Control/button yang butuh first-time guidance.
- Perubahan UI/prompt yang dibuat.
- Test bahwa guidance muncul sekali dan tidak looping.
```

---

## 8. Task 4 — Add Hover / Object Name Feedback

### Goal

When player hovers or enters interaction range of an item/object, show the item/object name.

### Examples

```text
Bread
Water
Bandage
Human Shelf
Ghost Shelf
Phantom Ice Cream
Cashier
Supply Box
Activity Board
```

### Checklist

- [ ] Hover/proximity label shows object name.
- [ ] Label appears before input.
- [ ] Label disappears on exit.
- [ ] Label works for items, shelves, cashier, board, and supply boxes.
- [ ] Hover name is separate from one-time tutorial explanation.
- [ ] Label does not overlap major HUD or modal panels.

### Codex Prompt

```text
Analisa dan implementasikan Task 4 — Add Hover / Object Name Feedback dari docs/polish/day-1-mechanic-polish.md.

Batasan:
- Jangan tambah mechanic baru.
- Fokus existing items/objects.
- Hover/proximity label harus muncul sebelum input.
- Tutorial explanation dan hover name harus dipisah.
- Cek Player interaction detection dan HUD/Label display sebelum edit.

Expected output:
- File yang dicek.
- Cara object name ditentukan.
- Perubahan yang dibuat.
- Test item name, shelf name, cashier name.
```

---

## 9. Task 5 — Polish Shelf Pickup Reachability

### Goal

Fix shelf pickup usability after player places a shelf in the store, especially before returning to get the ghost shelf.

### Design Requirement

```text
CollisionShape2D = physical blocking / body collision
InteractionArea = detection for prompt and pickup
```

Do not make the physical collision huge just to make pickup easier. Expand the interaction area, not the physics collision.

### Checklist

- [ ] Shelf can still be physically blocked by its normal collision.
- [ ] Shelf pickup detection uses larger reachable interaction area.
- [ ] Prompt appears before pickup input.
- [ ] Player can pick shelf up again after placing it in the store.
- [ ] Player can continue ghost shelf flow without touching a tiny exact collision shape.
- [ ] Enlarged area does not conflict with cashier, door, or activity board interaction.

### Codex Prompt

```text
Analisa dan implementasikan Task 5 — Polish Shelf Pickup Reachability dari docs/polish/day-1-mechanic-polish.md.

Batasan:
- Jangan tambah mechanic baru.
- Jangan memperbesar physics collision secara asal.
- Pisahkan CollisionShape2D fisik dan InteractionArea untuk pickup.
- InteractionArea shelf boleh diperbesar agar pickup lebih mudah.
- Pastikan prompt muncul sebelum menekan E.
- Pastikan tidak konflik dengan StorageDoor, Cashier, atau ActivityBoard.

Expected output:
- File/scene yang dicek.
- Penyebab shelf sulit diambil.
- Perubahan InteractionArea yang dibuat.
- Test pickup human shelf dan ghost shelf.
```

---

## 10. Task 6 — Polish Shelf Placement Safety / No-Drop Zones

### Goal

Prevent shelf placement in positions that break navigation, block doors, block cashier, or make the shelf difficult to retrieve.

### Checklist

- [ ] Shelf cannot be dropped on StorageDoor transition area.
- [ ] Shelf cannot be dropped on YardDoor transition area.
- [ ] Shelf cannot be dropped in cashier restricted area.
- [ ] Shelf cannot block main path or queue path.
- [ ] If first drop position is unsafe, fallback positions are tested.
- [ ] If all drop positions are unsafe, player keeps carrying shelf.
- [ ] Player receives clear feedback when drop is rejected.

### Codex Prompt

```text
Analisa dan implementasikan Task 6 — Polish Shelf Placement Safety / No-Drop Zones dari docs/polish/day-1-mechanic-polish.md.

Batasan:
- Jangan tambah mechanic baru.
- Fokus existing shelf carry/drop flow.
- Cegah shelf ditempatkan di pintu, cashier, path utama, atau posisi yang membuat shelf sulit diambil.
- Jika posisi utama invalid, coba fallback position.
- Jika semua invalid, shelf tetap dibawa player dan tampilkan feedback.

Expected output:
- File/scene yang dicek.
- No-drop zone yang ditemukan/dibuat.
- Perubahan validasi drop.
- Test drop dekat storage door, cashier, wall/corner.
```

---

## 11. Task 7 — Polish Cashier Restricted Area Danger Line

### Goal

Cashier restricted/no-drop area should be visually communicated when the player tries to place a shelf there.

### Visual Direction

```text
A danger line surrounds the cashier restricted area.
Hidden by default.
When invalid shelf drop happens near cashier:
→ danger line appears
→ fades in/out over 2 seconds
→ repeats 3 times
→ hides again
```

### Checklist

- [ ] Cashier restricted area exists or is clearly defined.
- [ ] Shelf drop in cashier restricted area is rejected.
- [ ] Player keeps carrying shelf after invalid drop.
- [ ] Danger line surrounds the cashier restricted area.
- [ ] Danger line is hidden by default.
- [ ] Danger line fades in/out over 2 seconds.
- [ ] Fade animation repeats 3 times.
- [ ] Danger line hides after animation.
- [ ] Animation does not block player input.
- [ ] Animation does not interfere with cashier UI or NPC queue.

### Codex Prompt

```text
Analisa dan implementasikan Task 7 — Polish Cashier Restricted Area Danger Line dari docs/polish/day-1-mechanic-polish.md.

Batasan:
- Jangan tambah mechanic baru.
- Fokus existing cashier restricted/no-drop area feedback.
- Shelf tetap tidak boleh diletakkan di area cashier/counter.
- Tambahkan visual danger line yang mengelilingi restricted area cashier.
- Danger line hidden by default.
- Saat invalid shelf drop di restricted area, danger line fade in/out selama 2 detik dan ulangi 3 kali.
- Setelah 3 kali, danger line harus hidden lagi.
- Player tetap membawa shelf jika drop invalid.
- Jangan buat modal blocking.
- Jangan ganggu cashier UI, queue NPC, atau interaction prompt.

Expected output:
- File/scene yang dicek.
- Lokasi restricted area cashier saat ini.
- Cara danger line dibuat.
- Cara animasi fade in/out 2 detik × 3 cycle dibuat.
- Test invalid drop, normal drop, repeated invalid drop, cashier UI.
```

---

## 12. Task 8 — Sync Cashier Restricted Area and Warning Visual

### Goal

Fix the mismatch between the actual cashier no-drop validation area and the visible danger-line/warning area.

Current playtest issue:

```text
- If player tries to place shelf inside the visible warning line, dialog and danger line appear correctly.
- If player tries near the cashier restricted area but outside the visible line, the restricted dialog can appear while the danger line does not visually cover the player's position.
- This makes the warning feel inconsistent because the invisible restriction is larger than the visible warning.
```

### Likely Cause

The implementation can accidentally use different concepts for restriction and visual feedback:

```text
- Cashier no-drop rect
- Customer main path no-drop area
- Customer queue path no-drop area
- Candidate/fallback drop context
- Danger line visual rect
```

If the dialog uses one area but the `Line2D` visual only draws another area, the player sees a restricted message without a matching visual boundary.

### Design Decision

Use **one source of truth** for cashier-related restricted feedback.

Preferred rule:

```text
If the rejection message is cashier-related, the danger line must outline the full area that caused the cashier-related rejection.
```

Do not let these two things diverge:

```text
Validation area != Warning visual area
```

### Recommended Implementation Direction

Create helper methods such as:

```text
_get_cashier_restricted_feedback_rect()
_is_cashier_restricted_rejection(reason, candidate, object)
_sync_cashier_restricted_danger_line_to_rect(rect)
```

Possible approaches:

#### Option A — Single Unified Rect

```text
cashier_restricted_feedback_rect = union of:
- cashier no-drop rect
- checkout queue path rect, if treated as cashier restricted
- nearby cashier/customer path segment, if its message is shown as cashier restricted
```

Then use the same rect for:

```text
- shelf drop rejection context
- danger line points
- warning visual placement
```

#### Option B — Separate Reasons, Separate Feedback

```text
If candidate hits exact cashier no-drop rect:
- message: This area is reserved for the cashier.
- show danger line around cashier rect.

If candidate hits customer path / checkout line:
- message: This blocks the customer path / checkout line.
- do not use cashier danger line unless a separate path warning visual exists.
```

For Day 1, prefer **Option A** if the user-facing experience treats all of that area as one cashier restricted zone.

### Checklist

- [ ] Identify every place where shelf drop can be rejected around cashier.
- [ ] Identify which rejection reasons currently trigger restricted dialog.
- [ ] Identify the rect/shape used to draw `CashierRestrictedDangerLine`.
- [ ] Make the visual warning boundary match the actual restricted validation area.
- [ ] If the restricted area is larger than the old line, expand the line to match it.
- [ ] If some rejection is not cashier-related, use a different message and do not show cashier warning.
- [ ] Do not rely on exact message string equality alone to decide whether danger line should play.
- [ ] Repeated invalid placement should replay or refresh the danger line consistently.
- [ ] Normal valid placement outside the visual restricted area should still work.

### Test Cases

#### RESTRICT-SYNC-01 — Inside Visible Line

```text
Carry shelf.
Stand inside / directly on cashier danger-line area.
Press Q to place.
Expected:
Drop is rejected.
Dialog appears.
Danger line appears and covers the rejected area.
```

#### RESTRICT-SYNC-02 — Near Cashier Edge

```text
Carry shelf.
Stand near cashier restricted edge where drop is rejected.
Press Q to place.
Expected:
If rejected as cashier restricted, danger line appears and includes that position.
No invisible restricted region exists without matching visual feedback.
```

#### RESTRICT-SYNC-03 — Customer Path / Queue Path

```text
Carry shelf.
Try to drop on customer path or checkout queue path.
Expected:
Either:
A) It is included in the cashier restricted danger-line boundary, or
B) It shows a different non-cashier message and does not pretend to be cashier restricted.
```

#### RESTRICT-SYNC-04 — Valid Nearby Drop

```text
Carry shelf.
Try to drop just outside the visible restricted boundary.
Expected:
Drop succeeds if no other no-drop rule is violated.
No restricted dialog appears.
```

### Codex Prompt

```text
Analisa dan implementasikan Task 8 — Sync Cashier Restricted Area and Warning Visual dari docs/polish/day-1-mechanic-polish.md.

Masalah:
Restricted dialog dan danger-line visual tidak selalu sinkron. Ada posisi di dekat cashier yang menolak shelf drop dan menampilkan dialog, tetapi danger line tidak mencakup posisi tersebut.

Batasan:
- Jangan tambah mechanic baru.
- Fokus sinkronisasi no-drop validation dan visual feedback.
- Identifikasi semua area yang menolak shelf drop di sekitar cashier: cashier no-drop rect, customer path, checkout queue path, fallback candidate context.
- Jika rejection dianggap cashier restricted, danger line harus menggambar area yang sama dengan area validasi.
- Jika rejection bukan cashier restricted, gunakan pesan berbeda dan jangan tampilkan cashier danger line.
- Jangan bergantung hanya pada perbandingan string message exact untuk trigger danger line.
- Player tetap membawa shelf setelah invalid drop.
- Jangan ganggu cashier UI, NPC queue, dan valid shelf placement di area yang benar-benar aman.

Expected output:
- File/scene yang dicek.
- Semua sumber area no-drop dekat cashier.
- Penyebab mismatch visual vs validation.
- Keputusan implementasi: unified cashier restricted rect atau separate feedback per reason.
- Perubahan helper/rect/line yang dibuat.
- Test RESTRICT-SYNC-01, 02, 03, 04.
```

---

## 13. Task 9 — Fix Store Door Entry Alignment

### Goal

Player entry/return position should match the actual door position.

### Checklist

- [ ] Returning from storage spawns player near StorageDoor.
- [ ] Returning from yard/outside spawns player near the correct door.
- [ ] Player does not spawn inside door trigger.
- [ ] Player does not instantly re-trigger transition.
- [ ] Player does not spawn inside wall/shelf/cashier restricted area.
- [ ] Door markers are visually aligned with door assets/placeholders.
- [ ] Player can use door while carrying shelf.
- [ ] Shelf remains carried after transition.

### Codex Prompt

```text
Analisa dan implementasikan Task 9 — Fix Store Door Entry Alignment dari docs/polish/day-1-mechanic-polish.md.

Batasan:
- Jangan tambah mechanic baru.
- Fokus marker/position transition existing.
- Posisi enter store harus sesuai posisi pintu.
- Jangan spawn player di dalam trigger pintu atau collision.
- Player harus bisa masuk/keluar door saat membawa shelf.
- Shelf harus tetap terbawa setelah transisi.
- Cek Store scene markers, door transition code, StorageReturnPos, YardReturnPos, PlayerSpawn.

Expected output:
- File/scene yang dicek.
- Marker pintu yang tidak align.
- Penyebab door terblokir saat carrying shelf jika ada.
- Perubahan posisi marker atau transition logic.
- Test return dari storage dan area lain sambil membawa shelf.
```

---

## 14. Task 10 — Move Trust Display to NPC World UI

### Goal

Trust is not permanent player HUD state. Trust belongs to the relevant NPC and should be displayed above that NPC when relevant.

### Checklist

- [ ] Remove/hide permanent Gooby Trust HUD label.
- [ ] Add trust label/bar above Gooby/story NPC.
- [ ] Trust display follows NPC movement.
- [ ] Trust updates after Gooby interaction.
- [ ] Generic NPCs do not show unnecessary trust bars.
- [ ] RelationshipManager remains source of truth.

### Codex Prompt

```text
Analisa dan implementasikan Task 10 — Move Trust Display to NPC World UI dari docs/polish/day-1-mechanic-polish.md.

Batasan:
- Jangan tambah relationship system kompleks.
- RelationshipManager tetap source of truth.
- Trust bukan permanent player HUD status.
- Trust harus tampil di atas NPC/story NPC yang relevan.
- Jangan merusak NameLabel/DialogBubble NPC.
- Pastikan Gooby trust update tetap jalan setelah gift/refuse flow.

Expected output:
- File yang dicek.
- Cara trust saat ini tampil di HUD.
- Perubahan untuk memindahkan trust ke NPC world UI.
- Test Gooby trust display, trust update, generic NPC.
```

---

## 15. Task 11 — Polish Cashier Ask Again UI

### Goal

When the player presses `Ask Again`, the customer's request should be readable inside the cashier panel. Player should not need to peek behind the cashier panel to read NPC bubble text.

### Preferred UI Behavior

```text
Cashier panel should include:
- Customer name
- Requested item
- Current scanned/selected item
- Total value
- Customer request text / repeated request text
- Clear buttons
```

Example layout:

```text
CHECKOUT
Customer: Gooby
Request: "I want Phantom Ice Cream."
Selected: Phantom Ice Cream
Total: 0G

[Confirm Scan] [Ask Again 1/3] [Close]
```

### Checklist

- [ ] Ask Again request appears inside cashier panel.
- [ ] NPC dialogue bubble can still exist, but it is not required to read request.
- [ ] Cashier panel does not cover its own important text.
- [ ] Buttons are spaced/readable at 480x270.
- [ ] Ask Again count, if used, is visible.
- [ ] Gooby choice panel remains clear.
- [ ] Panel closes/unlocks input correctly.

### Codex Prompt

```text
Analisa dan implementasikan Task 11 — Polish Cashier Ask Again UI dari docs/polish/day-1-mechanic-polish.md.

Batasan:
- Jangan tambah mechanic baru.
- Fokus readability panel cashier.
- Saat Ask Again, request NPC harus terlihat di dalam panel cashier.
- Jangan membuat player perlu melihat bubble NPC di belakang overlay.
- Jangan merusak normal checkout atau Gooby choice panel.
- Cek Cashier scene/script dan HUD/modal interaction lock.

Expected output:
- File yang dicek.
- Penyebab request sulit dibaca.
- Perubahan UI panel.
- Test Ask Again normal NPC dan Gooby.
```

---

## 16. Task 12 — Polish Cashier Panel Button Guidance

### Goal

Cashier panel should communicate what each button does, at least once, so player does not need to memorize controls or guess panel behavior.

### Example Helper Text

```text
Select the requested item, then confirm the scan.
Ask Again repeats what the customer wants.
Close cancels checkout.
```

For Gooby:

```text
Give Item increases trust but gives no gold.
Refuse Sale returns the item and continues the night event.
```

### Checklist

- [ ] Cashier panel explains core button functions at least once.
- [ ] Normal checkout button labels are clear.
- [ ] Gooby choice button labels are clear.
- [ ] Ask Again button has clear meaning.
- [ ] Guidance does not clutter panel permanently.
- [ ] Guidance does not block player control.
- [ ] Guidance follows E/Q mapping where keyboard prompts are shown.

### Codex Prompt

```text
Analisa dan implementasikan Task 12 — Polish Cashier Panel Button Guidance dari docs/polish/day-1-mechanic-polish.md.

Batasan:
- Jangan tambah mechanic baru.
- Fokus membuat UI cashier lebih jelas.
- Button/click guidance perlu muncul setidaknya sekali.
- Jangan buat tutorial panjang yang mengganggu flow.
- Pastikan normal checkout dan Gooby choice sama-sama jelas.

Expected output:
- File yang dicek.
- Button yang butuh guidance.
- Perubahan UI/helper text.
- Test normal checkout panel dan Gooby choice panel.
```

---

## 17. Task 13 — Audit Objective HUD Guidance

### Goal

Clarify whether objective text should exist as HUD, Activity Board content, or contextual hint.

### Recommended Direction

```text
Use contextual interaction hints as primary guidance.
Keep HUD objective only if it is short, non-overlapping, and clearly useful.
Activity Board can serve as optional backup guidance.
```

### Checklist

- [ ] Identify where objective text is created.
- [ ] Identify which file updates the objective text.
- [ ] Confirm whether objective belongs in HUD or board.
- [ ] Ensure objective does not overlap HUD labels.
- [ ] Ensure objective does not duplicate interaction hints too much.
- [ ] If retained, objective should be one-line only.
- [ ] If removed, board/hints must still guide the player.

### Codex Prompt

```text
Analisa Task 13 — Audit Objective HUD Guidance dari docs/polish/day-1-mechanic-polish.md.

Batasan:
- Jangan edit file dulu kecuali sudah jelas perlu revisi kecil.
- Jangan tambah mechanic baru.
- Jelaskan dari mana ObjectiveLabel dibuat dan siapa yang mengubahnya.
- Rekomendasikan apakah objective tetap di HUD, dipindah ke board, atau diganti contextual hints.

Expected output:
- File yang dicek.
- Sumber objective text.
- Kapan objective berubah.
- Apakah objective perlu dipertahankan.
- Rekomendasi perubahan.
```

---

## 18. Task 14 — Polish Activity Board / Action Guidance

### Goal

Activity Board should act as a stable place to check current actions without becoming a quest system.

### Recommended Board Content

```text
Today's Work
- Bring shelf from storage
- Stock human shelf
- Serve customers at cashier
```

After ghost flow begins:

```text
Strange Notes
- Check the dark storage corner
- Place the ghost shelf
- Stock Phantom Ice Cream
- Watch the store at night
```

During Gooby branch:

```text
Night Choice
- Give item: Trust +, Revenue 0G
- Refuse sale: Item returns, another customer may come
```

### Checklist

- [ ] Board explains current activity clearly.
- [ ] Board text updates at major existing milestones if implemented.
- [ ] Board does not introduce new gameplay requirements.
- [ ] Board UI can be closed safely.
- [ ] Board does not permanently lock input.
- [ ] Board does not conflict with cashier UI.
- [ ] Board can be replaced with final board sprite later.

### Codex Prompt

```text
Analisa dan implementasikan Task 14 — Polish Activity Board / Action Guidance dari docs/polish/day-1-mechanic-polish.md.

Batasan:
- Jangan tambah mechanic baru.
- Board hanya menjelaskan existing action.
- Jangan buat quest reward / completion system.
- Pastikan board bisa dibuka dan ditutup tanpa mengunci player.

Expected output:
- File yang dicek.
- Isi board per milestone.
- Perubahan board/UI yang dibuat.
- Test open/close board dan update guidance.
```

---

## 19. Task 15 — Polish Time / Phase Split

### Goal

Make in-game time phases more intuitive. 18:00 should be Night, not Day.

Recommended split:

```text
Morning / Setup: 08:00 → 10:00
Day / Store Open: 10:00 → 18:00
Night / Strange Customers: 18:00 → 22:00
End / Report: after 22:00
```

Preferred for Day 1:

```text
18:00 = Night
```

### Checklist

- [ ] Time display matches phase.
- [ ] Night starts at 18:00.
- [ ] Gooby/Slime night logic triggers only during Night.
- [ ] Day NPC revenue pacing stops before 18:00.
- [ ] End/report timing remains clear.

### Codex Prompt

```text
Analisa dan implementasikan Task 15 — Polish Time / Phase Split dari docs/polish/day-1-mechanic-polish.md.

Batasan:
- Jangan tambah mechanic baru.
- Fokus pembagian phase dan time display existing.
- 18:00 harus masuk Night.
- Pastikan normal Day NPC spawn berhenti sebelum Night.
- Pastikan Gooby/Slime night branch tidak berjalan sebelum Night.
- Cek TimeManager, NPCScheduler, HUD time/phase label.

Expected output:
- File yang dicek.
- Phase split sebelum/sesudah.
- Perubahan yang dibuat.
- Test 10:00 Day, 18:00 Night, Gooby Night trigger.
```

---

## 20. Task 16 — Polish Day Revenue Pacing to 40G

### Goal

Before the Gooby/Slime night branch, normal Day customers should produce 40G total revenue. The final 10G should depend on the Slime branch.

Expected Day economy:

```text
Daily target: 50G
Normal Day NPC revenue: 40G
Night item value / Slime purchase: 10G
```

### Dynamic Spawn Idea

After the player finishes managing shelf setup, calculate remaining time until 18:00 and divide it by 4 normal NPCs.

Example:

```text
Player finishes shelf setup at 10:00
Day window until Night: 10:00 → 18:00 = 8 hours
Normal NPC count: 4
Spawn interval: 8 / 4 = 2 hours per NPC
```

### Checklist

- [ ] Normal Day NPC revenue target is 40G.
- [ ] Normal Day NPC count or purchase value reliably reaches 40G.
- [ ] Spawn schedule considers remaining Day time until 18:00.
- [ ] Day NPCs do not continue generating revenue after Night begins.
- [ ] Slime remains the final 10G opportunity.
- [ ] Gift Gooby path can leave revenue at 40/50.
- [ ] Refuse Gooby path can allow Slime to reach 50/50.

### Codex Prompt

```text
Analisa dan implementasikan Task 16 — Polish Day Revenue Pacing to 40G dari docs/polish/day-1-mechanic-polish.md.

Batasan:
- Jangan tambah mechanic baru.
- Fokus existing NPCScheduler/EconomyManager/item pricing.
- Target harian 50G.
- Revenue normal sebelum Night harus 40G.
- Slime menjadi peluang final 10G.
- Jika player selesai setup shelf lebih cepat/lambat, jadwalkan 4 NPC normal dalam sisa waktu sampai 18:00.
- Cek TimeManager, NPCScheduler, EconomyManager, ItemData pricing, day customer spawning.

Expected output:
- File yang dicek.
- Cara revenue normal Day dihitung.
- Perubahan spawn/pacing yang dibuat.
- Test setup selesai jam 10:00, NPC normal total 40G, Night 18:00, Slime +10G.
```

---

## 21. Task 17 — Revise Gooby / Slime Follow-Up Logic

### Goal

Revise the night branch so Slime comes after Gooby's outcome, not only as a direct refusal spawn. The result depends on whether Phantom Ice Cream is still available.

### Revised Story Logic

```text
Night starts at 18:00
→ Gooby arrives and requests Phantom Ice Cream
→ Player resolves Gooby outcome
→ Shortly after Gooby outcome, Slime arrives
→ Slime asks for the same item
```

### Branch A — Give Item to Gooby

```text
Player gives Phantom Ice Cream to Gooby
→ Gooby Trust increases
→ Gooby pays 0G
→ Phantom Ice Cream is consumed / unavailable
→ Slime arrives shortly after
→ Slime asks for Phantom Ice Cream
→ Item is already gone
→ Player can respond that the item is out of stock
→ Slime cannot buy
→ Revenue remains 40/50
```

### Branch B — Refuse Gooby

```text
Player refuses to give Phantom Ice Cream to Gooby
→ Gooby pays 0G
→ Phantom Ice Cream remains available or returns to shelf
→ Slime arrives shortly after
→ Slime asks for Phantom Ice Cream
→ Item is available
→ Player sells item to Slime
→ Revenue increases by 10G
→ Revenue reaches 50/50
```

### Design Rule

```text
Give Gooby = trust path, daily target missed
Refuse Gooby = revenue path, daily target achieved through Slime
```

Recommended trust rule for prototype:

```text
Give Gooby = Trust +20
Refuse Gooby = Trust +0
```

### Checklist

- [ ] Slime is scheduled as a night follow-up after Gooby outcome.
- [ ] Slime can come after both Gooby gift and Gooby refusal.
- [ ] If Gooby received the item, Slime finds item unavailable.
- [ ] If Gooby was refused, item remains available / returns to shelf for Slime sale.
- [ ] Slime does not duplicate spawn.
- [ ] Slime does not buy unavailable item.
- [ ] Slime sale is the final 10G opportunity.
- [ ] Gift path ends at 40/50 revenue.
- [ ] Refuse path can reach 50/50 revenue.
- [ ] Notifications/panel text explain why Slime can or cannot buy.

### Codex Prompt

```text
Analisa dan implementasikan Task 17 — Revise Gooby / Slime Follow-Up Logic dari docs/polish/day-1-mechanic-polish.md.

Batasan:
- Jangan tambah story branch baru di luar Gooby/Slime Day 1 night branch.
- Slime harus datang setelah Gooby outcome, bukan hanya saat Gooby ditolak.
- Jika item diberikan ke Gooby, Slime datang tetapi item habis/tidak tersedia dan tidak ada revenue dari Slime.
- Jika Gooby ditolak, item tetap tersedia/kembali ke shelf dan Slime bisa membelinya.
- Give Gooby = trust path, revenue tetap 40/50.
- Refuse Gooby = revenue path, Slime +10G, target 50/50.
- Cegah duplicate Slime spawn.
- Cek Cashier, NPCScheduler, Store, Shelf, EconomyManager, RelationshipManager.

Expected output:
- File yang dicek.
- Flow Gooby gift setelah revisi.
- Flow Gooby refuse setelah revisi.
- Cara Slime follow-up dijadwalkan.
- Test gift path: Slime datang tapi tidak bisa beli.
- Test refuse path: Slime datang dan bisa beli.
```

---

## 22. Task 18 — Validate Gooby Night Choice

### Goal

Validate the complete night branch after Time, Revenue Pacing, and Gooby/Slime follow-up revisions.

### Checklist

- [ ] Normal Day revenue reaches 40G before Night.
- [ ] Night starts at 18:00.
- [ ] Gooby arrives during Night.
- [ ] Gooby asks for Phantom Ice Cream.
- [ ] Give Gooby increases trust and gives 0G.
- [ ] Slime still arrives after gift but cannot buy unavailable item.
- [ ] Gift path ends at 40/50.
- [ ] Refuse Gooby leaves/returns item available.
- [ ] Slime arrives after refusal and can buy item.
- [ ] Refuse path reaches 50/50.
- [ ] No duplicate Slime or duplicate revenue.

### Codex Prompt

```text
Validate Task 18 — Gooby Night Choice from docs/polish/day-1-mechanic-polish.md.

Batasan:
- Jangan tambah mechanic baru.
- Jangan edit file kecuali bug ditemukan.
- Fokus full branch after latest revisions.
- Pastikan revenue dan trust tetap reward path terpisah.

Expected output:
- File yang dicek.
- Status normal Day revenue 40G.
- Status Give Gooby path.
- Status Slime after gift path.
- Status Refuse Gooby path.
- Status Slime after refuse path.
- Bug yang ditemukan.
```

---

## 23. Task 19 — Review Full Core Loop

### Goal

Review the full playable Day 1 loop after all focused polish tasks.

### Checklist

- [ ] Player understands E/Q mapping.
- [ ] Player sees prompt before input.
- [ ] First-time guidance appears once and does not loop.
- [ ] Hover/object name feedback works.
- [ ] Player can bring shelf from storage.
- [ ] Door return positions are correct.
- [ ] Player can place and pick up shelves reliably.
- [ ] Cashier restricted danger line works.
- [ ] Cashier restricted visual boundary matches actual no-drop validation area.
- [ ] Cashier panel and Ask Again UI are readable.
- [ ] Trust display is above relevant NPC.
- [ ] Time phase split is readable.
- [ ] Normal Day revenue reaches 40G.
- [ ] Gooby/Slime branch works as designed.
- [ ] Temporary UI remains readable at 480x270.
- [ ] Player never loses control due to stuck UI state.

### Codex Prompt

```text
Review Task 19 — Review Full Core Loop dari docs/polish/day-1-mechanic-polish.md.

Batasan:
- Jangan edit file dulu.
- Jangan tambah mechanic baru.
- Jalankan review berdasarkan mechanic yang sudah ada.
- Fokus menemukan friction point, UI overlap, restricted area mismatch, atau bug.

Expected output:
- Status core loop dari awal sampai transaksi malam.
- Bagian yang sudah stabil.
- Bagian yang masih rawan.
- Rekomendasi task kecil berikutnya.
```

---

## 24. Task 20 — Prepare Asset-Ready Node Structure

### Goal

Prepare scenes so placeholder visuals can be swapped with Aseprite assets later without breaking mechanics.

### Checklist

- [ ] Visual nodes are separated from logic nodes.
- [ ] Placeholder visuals are grouped under a stable visual root where possible.
- [ ] Collision shapes do not depend directly on placeholder size.
- [ ] Interaction areas remain stable when sprite changes.
- [ ] Scene node names are stable.
- [ ] Script does not depend directly on `ColorRect` for gameplay logic.
- [ ] `Sprite2D` or `AnimatedSprite2D` replacement path is clear.
- [ ] Temporary UI / board / HUD layout can later be replaced by final UI assets.
- [ ] NPC trust world UI can later be replaced with final trust bar art.
- [ ] Interaction hint UI can later be replaced with final prompt art.
- [ ] Restricted danger line can later be replaced with final warning art.

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

### Codex Prompt

```text
Analisa dan implementasikan Task 20 — Prepare Asset-Ready Node Structure dari docs/polish/day-1-mechanic-polish.md.

Batasan:
- Jangan replace final assets dulu.
- Fokus struktur node agar sprite/UI final bisa masuk tanpa merusak gameplay.
- Jangan ubah behavior kecuali diperlukan untuk memisahkan visual dan logic.

Expected output:
- Scene yang dicek.
- Node visual yang masih bercampur dengan logic/collision.
- Perubahan struktur node yang dibuat.
- Risiko path script yang perlu diperhatikan.
```

---

## 25. Task 21 — Documentation Update

### Goal

Keep this file useful as an AI Agent task spec.

### Checklist

- [ ] Mark tasks as done / partially done / pending when appropriate.
- [ ] Add discovered bugs to the relevant task section.
- [ ] Add new test cases if playtest reveals missing cases.
- [ ] Keep Day 1 scope focused on polish, not feature expansion.
- [ ] Keep implementation notes aligned with actual behavior.

### Codex Prompt

```text
Update Task 21 — Documentation Update dari docs/polish/day-1-mechanic-polish.md.

Batasan:
- Jangan ubah mechanic.
- Update dokumentasi berdasarkan hasil validasi terakhir.
- Tandai task yang sudah done, partially done, dan pending.
- Tambahkan catatan bug/follow-up jika ada.
```

---

## 26. Definition of Done — Day 1

Day 1 can be considered done when:

- [ ] No new major mechanic was added.
- [ ] Core shop loop can be played from setup to checkout.
- [ ] Input mapping is consistent: E for interact/get, Q for put/place.
- [ ] Interaction prompts appear before input.
- [ ] First-time button/click guidance appears once and does not loop.
- [ ] Hover/object name feedback works.
- [ ] Player can reliably pick up and place shelves.
- [ ] Shelf no-drop validation prevents stuck/path-blocking placement.
- [ ] Cashier danger line matches actual restricted validation area.
- [ ] Door transitions align with door positions and work while carrying shelf.
- [ ] Cashier Ask Again and button guidance are readable.
- [ ] Trust display appears on relevant NPC, not as permanent player HUD stat.
- [ ] 18:00 is Night.
- [ ] Normal Day revenue reaches 40G.
- [ ] Gooby gift path gives trust without revenue and leaves target missed.
- [ ] Gooby refuse path enables Slime revenue to reach target.
- [ ] Slime follow-up works after both Gooby outcomes.
- [ ] Temporary UI is readable at 480x270.
- [ ] Project remains ready for Aseprite asset integration.

---

## 27. Suggested Trello / Branch Naming

Trello activities:

```text
standardize_input_mapping_e_get_q_put_day_1
revise_interaction_prompt_timing_day_1
add_one_time_button_guidance_day_1
add_hover_object_name_feedback_day_1
polish_shelf_pickup_reachability_day_1
polish_shelf_no_drop_zones_day_1
polish_cashier_restricted_danger_line_day_1
sync_cashier_restricted_warning_visual_day_1
fix_store_door_entry_alignment_day_1
move_trust_display_to_npc_world_ui_day_1
polish_cashier_ask_again_ui_day_1
polish_cashier_panel_button_guidance_day_1
audit_objective_hud_guidance_day_1
polish_activity_board_guidance_day_1
polish_time_phase_split_day_1
polish_day_revenue_pacing_40g_day_1
revise_gooby_slime_follow_up_logic_day_1
validate_gooby_night_choice_day_1
review_core_loop_day_1
prepare_asset_ready_node_structure_day_1
```

Branch:

```text
polish/day-1-mechanic-polish
```

Suggested commit messages:

```text
docs: add cashier restricted sync task
fix: sync cashier restricted visual with no drop validation
fix: standardize shelf placement rejection feedback
refactor: use shared cashier restricted rect for warning line
```
