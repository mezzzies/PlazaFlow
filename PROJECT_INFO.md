# PlazaFlow — Project Information & Design Specification

## 1. Overview
**PlazaFlow** is a cozy, minimalist 3D urban plaza and crowd-ecosystem management game built in **Godot Engine 4.6**, inspired by the tactile tabletop diorama aesthetic of *Mini Motorways*, the clean transit cards of *Mini Metro*, and the 2.5D floating card feel of *Balatro*.

Players choose a city plaza scenario, manage their municipal **Budget** (using the in-game coin currency `🪙`), construct categorized **Facilities** (**Path**, **Dining**, **Service**, **Comfort**, **Utility**, and **Signature Landmarks**), rotate buildings (`Q` / `E`) to align their directional entrances with walkways, and hire **Plaza Staff** (**Janitors**, **Plaza Staff**, **Security Officers**, and unlockable **Cleaning Drones**) to keep a diverse crowd of citizens (**Normal**, **Elders**, **Business People**, **Couples**, **Children**) happy day and night.

---

## 2. Visual Direction, 2.5D Floating Menus & Continuous Diorama World
* **Continuous 3D Scene Architecture (Mini Motorways / Mini Metro / Balatro Style):**
  * **Main Menu Diorama (`z = -42`) & 2.5D Floating Start Menu:**
    * **3D Animated Title Diorama:** A gently bobbing miniature roundabout island with a central stone fountain, cozy shops, houses, strolling citizens, floating 3D hot-air balloons, and drifting low-poly clouds while the camera smoothly orbits.
    * **2.5D Floating Balatro-Style Menu Cards:** Presents a floating 2.5D **Logo Card** displaying `"PLAZA FLOW"` in a bold 3D-extruded slanted display logo font with wave-animated characters, alongside 3 floating action cards (`▶ PLAY`, `⚙ OPTIONS`, `✕ QUIT GAME`) that continuously bob, wobble in 2.5D, and tilt/pop dynamically toward the mouse cursor.
  * **Location Select Overview (Mini Metro-Style Location Cards):**
    * Smooth continuous camera flight to the main Plaza Diorama Board (`z = 0`), live-previewing each scenario's custom color palette and 3D landmarks **without pre-spawning gates** until the player confirms the location.
    * **Mini Metro Location Cards:** Each location is presented as a tactile postcard/transit card with a colored top header strip (`accent_color`), **Location Name**, **Map Size Pill Badge**, **Dynamic Starting Budget** (`🪙 90k–100k`), and a concise 1-line summary.
  * **Active Gameplay View:** Smooth continuous zoom and tilt into the interactive Bird's-Eye Gameplay Camera (`WASD` / `Middle-Mouse` pan, `Scroll` zoom).
* **4 Playable Locations & Dynamic Starting Budgets ([`LocationCatalog`](file:///d:/01_Working/07_Project/PlazaFlow/scripts/location_catalog.gd)):**
  * **Dynamic Starting Budget Formula ([`FacilityCatalog.calculate_starting_budget`](file:///d:/01_Working/07_Project/PlazaFlow/scripts/facility_catalog.gd#L638-L656)):**
    $$\text{Starting Budget} = \left\lceil \frac{(\text{Grid Width} \times 1,500\text{ 🪙}) + (6 \times \text{Avg Core Facility Cost})}{10,000} \right\rceil \times 10,000\text{ 🪙}$$
  1. **Old Town Square** (*Historic District — Relaxed — Initial `19×13` tiles*): **`90k 🪙`** dynamic starting budget. Warm cobblestone palette with a central stone fountain and flower planters.
  2. **Riverside Park** (*Green Belt — Moderate — Initial `25×17` tiles*): **`90k 🪙`** dynamic starting budget. Spacious park split by a North–South river and duck pond with an arched wooden bridge at `(2, 0)..(3, 0)`. High Comfort/Picnic demand.
  3. **Lantern Market** (*Old Harbour Lanes — Moderate — Initial `23×13` tiles*): **`90k 🪙`** dynamic starting budget. Twilight lavender/slate palette with market stalls forming narrow alleys under glowing lantern strings. High Dining demand.
  4. **Central Station Plaza** (*Downtown Transit Hub — Challenging — Initial `29×19` tiles*): **`100k 🪙`** dynamic starting budget. Grand concourse featuring a northern Train Station at `(0, -9)` that drops commuter waves every 40 seconds. High Restroom & Business demand.

---

## 3. Entrance Gate Generation & Weekly Vertical Map Expansion
1. **Initial Gate Pair (Upon Starting a Location):**
   * While browsing the Location Select screen, **no gates** are generated on the board.
   * Once the player selects a location and begins play, **1 pair of gates (1 Entry Gate + 1 Exit Gate)** is generated exclusively along the **Left or Right road edges** (top and bottom edges do not spawn gates initially). Both gates may appear on the same side (e.g., both on the Left edge) or opposite sides.
2. **Weekly Vertical Map Expansion (Every Monday from Week 2+):**
   * At the start of every new week (Monday morning, after Week 1), the plaza automatically expands vertically by **`+1` row at the top (`-Z`)** and **`+1` row at the bottom (`+Z`)**, giving the player more buildable room and extending road/river borders dynamically.
3. **Weekly Random Gate Spawning (Every Monday from Week 2+):**
   * Every Monday (excluding Week 1), **at least 1 new gate** (`50%` chance Entry Gate, `50%` chance Exit Gate) spawns on an empty tile in the plaza.
   * **Reputation Bonus Gates:** Higher Reputation grants an increasing chance to spawn **multiple new gates** on Monday (`extra_chance = clamp((Reputation - 2.0) × 0.12, 0.0, 0.85)`, up to 3 gates per Monday).

---

## 4.Rotational Multi-Tile Facilities, Blueprint Preview & Signature Landmarks
* **Directional Entrances & Rotation (`Q` / `E` Keys):**
  * Every placeable facility has a **directional entrance** on its front side (`rot_idx`: `0 = South +Z`, `1 = East +X`, `2 = North -Z`, `3 = West -X`). Customers must walk onto the **entrance tile** immediately in front of the facility to be served.
  * Players press **`Q`** (Counter-Clockwise `-90°`) or **`E`** (Clockwise `+90°`) while hovering to rotate the facility.
  * For **rectangular facilities** (`2×1`, `3×2`, `4×2`, `4×3`), rotating by `90°` or `270°` automatically swaps the X and Z grid footprint dimensions ([`FacilityCatalog.get_rotated_size`](file:///d:/01_Working/07_Project/PlazaFlow/scripts/facility_catalog.gd#L674-L678)) and centers the entrance along the active front edge ([`StallController.calculate_entrance_offset`](file:///d:/01_Working/07_Project/PlazaFlow/scripts/stall_controller.gd#L65-L78)).
* **3D Blueprint Hover Preview:**
  * Selecting any facility displays a translucent **3D Blueprint Mesh** of the actual building directly on the hovered grid tiles (cyan when valid, coral-red when blocked), along with a glowing **Entrance Direction Arrow** on the adjacent entrance tile.
* **Categorized Build Catalog ([`FacilityCatalog`](file:///d:/01_Working/07_Project/PlazaFlow/scripts/facility_catalog.gd)):**
  1. **🛤 Path & Gates (`Category.PATH`):**
     * **Walk Tile (`1,500 🪙`):** Standard `1×1` rounded walkway (`1.0×` speed, holds up to `10` people).
     * **Express Tile (`3,000 🪙`):** Golden-trimmed `1×1` fast walkway that boosts pedestrian walking speed by **`+40%`** (`1.4×` speed) and lowers A* routing cost (`0.68`).
     * **Fence (`500 🪙`):** Impassable barrier/wall that connects with adjacent fences.
     * **Entry Gate (`2,000 🪙`):** One-way entrance tile with green inward chevron for customers.
     * **Exit Gate (`2,000 🪙`):** One-way exit tile with coral outward chevron for customers.
     * **Demolish:** Removes placed paths, fences, or facilities for a **`50%` coin refund**.
  2. **🍔 Dining (`Category.DINING`):**
     * **Food Shop (`12k 🪙`, `1×1`):** Earns **`+350 🪙`** per customer served (`FOOD` need, capacity `4`).
     * **Drink Stall (`8k 🪙`, `1×1`):** Earns **`+220 🪙`** per customer served (`DRINK` need, capacity `4`).
  3. **🚻 Service (`Category.SERVICE`):**
     * **Restroom (`10k 🪙`, `1×1`):** Earns **`+120 🪙`** per customer served (`RESTROOM` need, capacity `4`).
     * **Info Kiosk (`6k 🪙`, `1×1`):** `0 🪙` fee; passively guides/prevents `Lost` customers within `3` tiles.
  4. **🪑 Comfort (`Category.COMFORT`):**
     * **Picnic Table (`7k 🪙`, `1×1`):** `0 🪙` fee; seats `4` for `SIT` needs & Staff rest.
     * **Park Bench (`3.5k 🪙`, `1×1`):** `0 🪙` fee; seats `2` for `SIT` needs & Staff rest, and grants **Scenic Bonus** to nearby Dining stalls.
  5. **🗑 Utility (`Category.UTILITY`):**
     * **Trashcan (`1.5k 🪙`, `1×1`):** Absorbs litter from customers within `2.5` tiles.
     * **Lamp Post (`1.2k 🪙`, `1×1`):** Illuminates paths at night and reduces getting lost.
  6. **🏛 Signature Landmarks (`Category.SIGNATURE` — 24 Unique Items, Max 1 Each in Park, `1×1` to `5×5`):**
     * Strictly **1 of each Signature item** can exist in the plaza at a time (`BUILT` badge shown once placed; demolishing re-unlocks placement).
     * Browseable via `<` and `>` pagination buttons in the Signature dock (`8` cards per page).

| ID | Landmark Name | Size | Cost | Income | Need | Benefit (`✔`) | Disadvantage (`✖`) |
| :- | :--- | :-: | :-: | :-: | :-: | :--- | :--- |
| `13` | **Flower Garden** | `2×2` | `9k 🪙` | `0 🪙` | `SIT` (6) | Elders `+120%` & Comfort service `+30%` faster | `0 🪙` direct revenue & `2×2` space |
| `14` | **Duck Pond** | `3×2` | `9.5k 🪙` | `0 🪙` | `SIT` (6) | Couples/Kids `+100%` & prevents getting Lost nearby | `3×2` footprint & `300 🪙/day` upkeep |
| `15` | **Coffee Roaster** | `1×1` | `14k 🪙` | `+320 🪙` | `DRINK` (4) | Business `+120%` & all Dining income `+30%` | Generates `2×` trash from coffee cups |
| `16` | **Street Stage** | `2×1` | `13k 🪙` | `+180 🪙` | `SIT` (6) | Couples/Normal `+80%` & queue patience `+35%` | `2×1` footprint & crowds gather longer (`2.8s`) |
| `18` | **Clock Tower** | `2×2` | `15k 🪙` | `+90 🪙` | `SIT` (5) | Guides Lost visitors (`6` tiles) & walk speed `+10%` | Mechanical upkeep costs `500 🪙/day` |
| `19` | **Carousel** | `3×3` | `16k 🪙` | `+480 🪙` | `SIT` (8) | Earns `+480 🪙`/ride & boosts Kids/Couples arrivals | Music & lights upkeep costs `700 🪙/day` |
| `20` | **Ferris Wheel** | `4×3` | `22k 🪙` | `+950 🪙` | `SIT` (10) | Earns `+950 🪙`/ticket & `+20%` Daily City Grant | Long ride (`4.2s`) & `1,200 🪙/day` upkeep |
| `21` | **Zen Shrine** | `3×3` | `14.5k 🪙` | `+150 🪙` | `SIT` (6) | Prevents Lost (`5` tiles) & `+5` min daily Happiness | Calm aura slows visitor walking speed by `-8%` |
| `22` | **Gold Monolith** | `2×2` | `18k 🪙` | `+600 🪙` | `SIT` (4) | Boosts all facility service income by `+20%` | Commercial vibe reduces Daily City Grant by `-15%` |
| `23` | **Wishing Well** | `1×1` | `8.5k 🪙` | `+420 🪙` | `SIT` (4) | Compact `1×1` coin magnet (`+420 🪙`/wish) | Distracts visitors (`+15%` chance to get Lost) |
| `24` | **Cyber Arcade** | `3×2` | `17k 🪙` | `+680 🪙` | `SIT` (6) | High-tech gaming (`+680 🪙`/play, fast `2.0s` turns) | Neon power & snacks cost `900 🪙/day` + extra litter |
| `25` | **Botanic Dome** | `3×3` | `16.5k 🪙` | `+260 🪙` | `SIT` (8) | Scenic Bonus (`3.5` tiles) & `-25%` littering | Climate control costs `650 🪙/day` upkeep |
| `26` | **Triumph Arch** | `3×2` | `19k 🪙` | `+200 🪙` | `SIT` (6) | Boosts Reputation gain from happy visitors by `+25%` | Monument maintenance costs `800 🪙/day` |
| `27` | **Gelato Pavilion** | `1×1` | `13.5k 🪙` | `+520 🪙` | `FOOD` (5) | Artisanal gelato (`+520 🪙`, fast `1.4s` service) | Increases visitor Drink need & wrapper litter |
| `28` | **Biergarten** | `3×2` | `15.5k 🪙` | `+580 🪙` | `DRINK` (8) | High-capacity (`8`) beverage hall (`+580 🪙`/patron) | Increases Restroom demand & `500 🪙/day` upkeep |
| `29` | **Planetarium** | `3×3` | `20k 🪙` | `+820 🪙` | `SIT` (8) | Star-dome show (`+820 🪙`) & prevents Lost (`5` tiles) | Long showtime (`3.8s`) & `1,000 🪙/day` upkeep |
| `30` | **Skate Bowl** | `4×2` | `12.5k 🪙` | `+310 🪙` | `SIT` (6) | Boosts visitor walking speed by `+12%` park-wide | Rowdy noise increases Elder impatience |
| `31` | **Onsen Spa** | `3×2` | `17.5k 🪙` | `+640 🪙` | `RESTROOM` (6) | Luxury bathhouse (`+640 🪙`) & Staff tire `-30%` slower | Heated spring water costs `850 🪙/day` upkeep |
| `32` | **Sky Tower** | `3×3` | `21k 🪙` | `+880 🪙` | `SIT` (8) | Guides Lost across `8` tiles & `+880 🪙`/ticket | Elevator & tower upkeep costs `1,100 🪙/day` |
| `33` | **Matcha House** | `2×1` | `13k 🪙` | `+460 🪙` | `DRINK` (5) | Ceremonial tea (`+460 🪙`) & `+25%` queue patience | Careful tea ceremony takes `2.6s` per guest |
| `34` | **Art Obelisk** | `1×1` | `11k 🪙` | `+250 🪙` | `SIT` (4) | Boosts Business tips by `+25%` & Scenic Bonus (`3` tiles) | Polarizing modern art (`400 🪙/day` upkeep) |
| `35` | **Grand Circus** | `4×4` | `19.5k 🪙` | `+1,400 🪙` | `SIT` (12) | Massive `12`-seat big top (`+1.4k 🪙`) & `+30%` arrival rate | Confetti & popcorn double litter drops |
| `36` | **Steam Train** | `4×2` | `18.5k 🪙` | `+1,200 🪙` | `SIT` (10) | Earns `+1.2k 🪙`/ride & `+50%` Scenic Bonus (`3.5` tiles) | Coal & track maintenance costs `1,300 🪙/day` |
| `37` | **Diamond Hall** | `5×5` | `25k 🪙` | `+2,000 🪙` | `SIT` (8) | Luxury exhibition (`+2k 🪙`/patron) & `+20%` City Grant | High security needs increase Staff daily wages by `+25%` |

---

## 5. Economic Ecosystem, Scenic Combos & Weekly Calendar
* **In-Game Currency (`🪙`):** All UI elements, floating income popups, settlement cards, and tooltips use the game coin symbol (`🪙`) rather than real-world currency.
* **Scenic Combo System (`+25%` to `+50%` Dining Price Bonus):**
  * Placing a **Flower Garden**, **Duck Pond**, **Park Bench**, **Botanic Dome**, **Art Obelisk**, or **Steam Train** within range of a **Dining** facility (**Food Shop**, **Drink Stall**, **Coffee Roaster**, **Gelato Pavilion**, **Biergarten**, **Matcha House**) triggers a **Scenic Bonus**, increasing the Dining facility's service payout and displaying a golden `✨ +X 🪙` popup.
* **Daily City Grant, Staff Payroll & Animated Settlement Announcement Card:**
  * Every in-game day lasts **60 seconds** (`30s` Day / `30s` Night).
  * **City Grant Formula:**
    $$\text{Daily Grant} = \text{round}\!\left(\left(12,000\text{ 🪙} + 4,500\text{ 🪙} \times \left(\text{Reputation} - 1.0\right)\right) \times \left(\frac{\text{Happiness}}{100}\right)^{1.15} \times \text{grant\_mult}\right)$$
  * Deducts daily **Staff Wages** (`1k 🪙` Janitor, `2k 🪙` Plaza Staff, `3k 🪙` Security Officer, `500 🪙` Cleaning Drone) and any **Signature Landmark Upkeep** at the end of each day.
  * If Plaza Happiness drops to `≤ 10` at end-of-day inspection, **Game Over** is triggered.
* **Weekly Event Schedule (Thursday & Sunday):**
  * **Every Thursday (`day_index == 3`) — Facility Upgrade Day (2 Choices):**
    * Players choose between **2 unbuilt Signature Landmarks**, unlocking the chosen landmark and receiving **1 Free Voucher (`FREE (1)`)** to place it at `0 🪙` cost.
  * **Every Sunday Morning (`day_index == 6`) — 3-Tier Municipal Perk Draft (18 Perks):**
    * Players pick **1 of 3 Trade-Off Perks** scaled by current Week/Reputation (**Tier 1 Standard**, **Tier 2 Advanced**, **Tier 3 Master**, plus Special Unlock Perks like **Autonomous Drone Program** that unlocks the **Cleaning Drone** in the Staff menu).

---

## 6. Reputation-Synchronized Customer Spawning, Rush Hour & Archetypes
* **Reputation Progression (Unlimited, Starts at `1.0★`):**
  * Reputation starts at **`1.0★`** with **no upper limit**.
  * Every customer who exits the plaza with **100% Happiness** (all needs fulfilled and not angry) immediately increases Reputation by **`+0.1★`**.
* **Reputation-Synchronized Arrival Rate & Active Crowd Cap:**
  * Within every **10-second window**, **`floor(Reputation)`** customers are scheduled at randomized timestamps inside `[0.2s, 9.8s]` and enter through randomly chosen **Entry Gates**.
  * **Active Plaza Cap:** To prevent overcrowding bugs, total active customers in the plaza are strictly synchronized with Reputation (`max_active_customers = max(3, int(ceil(Reputation) * 3.0))`), and scheduled wave timestamps clear cleanly on location resets.
* **Daily Rush Hour Events (`08:00–10:00` & `17:00–19:00`):**
  * Twice each day (**Morning Commute** and **Evening Rush**), a golden HUD banner (`⚡ RUSH HOUR: Morning Commute / Evening Rush`) announces a `1.8×` arrival surge with heavily boosted **Business** commuter weight (`3.2×`).
* **5 Customer Archetypes:**
  1. **Normal (`NORMAL`):** Standard speed (`2.6 m/s`), `0–2` needs; happy (`❤️`) when served, unhappy (`😠`) if delayed.
  2. **Elder (`ELDER`):** Slow walker (`1.35 m/s`); always requires a `SIT` facility; can become **Lost**.
  3. **Business (`BUSINESS`):** Fast commuter (`3.8 m/s`) with urgent needs; tips **`+35%` extra** (`+60%` with **Art Obelisk**) when served promptly.
  4. **Couple (`COUPLE`):** Walks side-by-side (`1` customer set, `2` tile headcount), visiting every facility together.
  5. **Children (`CHILD`):** Energetic young visitors (`0.68×` scale) who easily become **Lost** until guided by **Plaza Staff**, **Security**, **Info Kiosk**, or landmark auras.

---

## 7. Cozy Minimal Floating Dock UI & Staff Navigation
* **Always-Visible Cozy Minimal Floating Category Dock:**
  * Located at the bottom-center of the screen with **7 floating rounded icon pills** (`🛤 Path`, `🍔 Dining`, `🚻 Service`, `🪑 Comfort`, `🗑 Utility`, `🏛 Signature`, `🧹 Staff`).
  * Clicking a category pops up compact facility cards above the dock (`88×92` px) with pagination (`<` / `>`) for large categories like **Signature**.
  * Hovering over any facility card displays a **rich floating detail tooltip** showing exact footprint size (`[3×2]`, `[5×5]`, etc.), cost, service income, capacity, and Landmark Benefit (`✔`) / Disadvantage (`✖`).
* **Staff Gate Navigation Fix & 4 Staff Types:**
  * All staff members (`Janitor`, `Plaza Staff`, `Security Officer`, `Cleaning Drone`) can walk freely in **both directions** through **Entry Gates** and **Exit Gates** (`allow_all_gates = true` in [`PathNetwork`](file:///d:/01_Working/07_Project/PlazaFlow/scripts/path_network.gd)) so they never get stranded outside one-way customer gates.

---

## 8. Technical Architecture & Folder Structure

```text
res://
├── GAME_SUMMARY.md             # Player-facing game summary, categories, landmarks & controls
├── PROJECT_INFO.md             # Complete design specification & technical architecture reference
├── project.godot               # Godot 4.6 configuration (Forward+ PC / Mobile fallback)
├── assets/
│   ├── models/                 # Modular 3D meshes / .glb exports
│   ├── materials/              # Cozy matte palette materials & emissive night materials
│   └── audio/                  # UI clicks, placement pops, ambient city/plaza soundscape
├── scenes/
│   ├── main.tscn               # Master game scene (Title Diorama, Plaza World, Camera, UI)
│   ├── map_grid.tscn           # Plaza terrain, city road borders, and rounded path renderer
│   ├── peep.tscn               # Citizen pawn with archetype visuals & desire badges
│   └── stall.tscn              # Multi-category solid facility scene
└── scripts/
    ├── game_director.gd        # Economy, calendar, rush hour, 18 perks, floating dock UI
    ├── facility_catalog.gd     # 37 items (incl. 24 Signature Landmarks up to 5×5) & staff data
    ├── location_catalog.gd     # 4 playable scenarios, palettes, and obstacle layouts
    ├── camera_rig.gd           # Continuous camera transitions & bird's-eye WASD/MMB pan
    ├── day_night_cycle.gd      # 30s day / 30s night lighting, brightness slider & lamps
    ├── grid_manager.gd         # Rotatable footprints, 3D blueprint preview, weekly expansion
    ├── path_network.gd         # Dual AStar2D, express tiles, one-way customer gates & staff bypass
    ├── peep_agent.gd           # 5 citizen archetypes, 0-2 needs, entrance queueing & littering
    ├── staff_agent.gd          # Janitor, Plaza Staff, Security Officer & flying Cleaning Drone
    ├── stall_controller.gd     # Multi-tile rotated entrance offsets, scenic bonus & queues
    └── procedural_props.gd     # 3D diorama builders for all 37 facilities, archetypes & props
```
