# PlazaFlow — Project Information & Design Specification

## 1. Overview
**PlazaFlow** is a cozy, minimalist 3D urban plaza and crowd-ecosystem management game built in **Godot Engine 4**, inspired by the tactile tabletop diorama aesthetic of *Mini Motorways* and the living park simulation of classic cozy tycoon games.

Players choose a city plaza scenario, manage their municipal **Budget**, construct categorized **Facilities** (**Path**, **Dining**, **Service**, **Comfort**, **Utility**), and hire **Plaza Staff** (**Janitors**, **Plaza Guides**, **Security Officers**) to keep a diverse crowd of citizens (**Normal**, **Elders**, **Business People**, **Couples**, **Children**) happy day and night.

---

## 2. Visual Direction & Continuous Diorama World
* **Continuous 3D Scene Architecture (Mini Motorways Style):**
  * **Main Menu Diorama (`z = -42`):** A dedicated miniature roundabout island with a stone fountain, cozy shops, houses, and strolling citizens while the camera gently orbits.
  * **Location Select Overview:** Smooth continuous camera flight to the main Plaza Diorama Board (`z = 0`), live-previewing each scenario's custom color palette and 3D landmarks.
  * **Active Gameplay View:** Smooth continuous zoom and tilt into the interactive Bird's-Eye Gameplay Camera (`WASD` / `Middle-Mouse` pan, `Scroll` zoom).
* **4 Playable Locations & Custom Map Sizes ([`LocationCatalog`](file:///d:/01_Working/07_Project/PlazaFlow/scripts/location_catalog.gd)):**
  1. **Old Town Square** (*Historic District — Relaxed — Small `19×13` tiles*): `$200,000` starting budget. Warm cobblestone palette with a central stone fountain and flower planters.
  2. **Riverside Park** (*Green Belt — Moderate — Large `25×17` tiles*): `$230,000` starting budget. Spacious park split by a North–South river and duck pond with an arched wooden bridge at `(2, 0)..(3, 0)`. High Comfort/Picnic demand.
  3. **Lantern Night Market** (*Old Harbour Lanes — Moderate — Medium `23×13` tiles*): `$190,000` starting budget. Twilight lavender/slate palette with market stalls forming narrow alleys under glowing lantern strings. High Dining demand.
  4. **Central Station Plaza** (*Downtown Transit Hub — Challenging — Grand `29×19` tiles*): `$240,000` starting budget. Grand concourse featuring a northern Train Station at `(0, -9)` that drops commuter waves every 40 seconds. High Restroom & Business demand.

---

## 3. Economic Ecosystem & Weekly Event Calendar
* **Starting Budget:** Doubled for balanced expansion (`$200,000` default on Old Town Square; `$190k–$240k` across scenarios).
* **Placement Costs & Categorized Facilities:**
  1. **Path & Gates (`Category.PATH`):**
     * **Walk Tile (`$1,500`):** Fuller `1x1` rounded walkway; holds up to `10` people simultaneously. Recommended route for customers (`weight = 1.0` vs off-path `weight = 8.5`). Any Walk Tile placed at the left/right plaza edge acts as a two-way gate!
     * **Fence (`$500`):** Impassable barrier/wall that connects with adjacent fences. Nobody (customers or staff) can walk through a Fence.
     * **Entry Gate (`$2,000`):** One-way entrance tile with green inward chevron; only allows customers to walk **IN** to the plaza.
     * **Exit Gate (`$2,000`):** One-way exit tile with coral outward chevron; only allows customers to walk **OUT** from the plaza.
  2. **Dining (Paid Service):**
     * **Food Shop (`$12,000`):** Earns **`+$150`** per customer served (`FOOD` need).
     * **Drink Stall (`$8,000`):** Earns **`+$90`** per customer served (`DRINK` need, fast service).
  3. **Service:**
     * **Restroom (`$10,000`):** Earns **`+$25`** per customer served (`RESTROOM` need).
     * **Info Kiosk (`$6,000`):** `$0` fee; passively guides/prevents `Lost` customers within `3` tiles.
  4. **Comfort (Free Public Amenities):**
     * **Picnic Table (`$7,000`):** `$0` fee; seats `4` for Elder/Customer `SIT` needs & Staff rest.
     * **Park Bench (`$3,500`):** `$0` fee; seats `2` for compact Elder `SIT` needs & Staff rest.
  5. **Utility:**
     * **Trashcan (`$1,500`):** `$0` fee; absorbs litter from customers within `2.5` tiles.
     * **Lamp Post (`$1,200`):** `$0` fee; illuminates paths at night and reduces getting lost.
* **Daily City Grant & Staff Payroll (Settled at the End of Every Day):**
  * **City Grant Formula:**
    $$\text{Daily Grant} = \text{round}\!\left(\left(\$8,000 + \$3,500 \times \text{Reputation}\right) \times \left(\frac{\text{Happiness}}{100}\right)^{1.2}\right)$$
  * **Daily Staff Wages:** Deducted automatically at the end of each day (`$1k` Janitor, `$2k` Plaza Staff, `$3k` Security Officer).
* **Weekly Upgrade & Special Card Schedule:**
  * **Every Thursday & Monday (from Week 2 Monday onward):** **Facility & Expansion Upgrade Draft** — Choose 1 of 3 municipal expansion packages (free facility vouchers + budget grants).
  * **Every Wednesday & Saturday:** **Special Perk / Prize Card** — Choose 1 of 3 special prizes or permanent perks (e.g., *Receive `$10k`*, *Receive `$18k`*, *Free 2 Park Benches*, *Free 8 Walk Tiles*, *Volunteer Janitor*, *`+25%` Permanent Service Income*, *Street Music Festival `+25%` Happiness & `+0.50★` Reputation*).

---

## 4. Customer Humanity, Archetypes & Reputation Spawning
* **Needs, Recommended Paths & Emoji Feedback:**
  * Citizens can have **`0` to `2` needs** (`FOOD`, `DRINK`, `RESTROOM`, `SIT`) or simply stroll through the plaza.
  * Most customers strongly prefer walking on placed **Walk Tiles**, while some customers (such as **Lost** customers or casual wanderers) stroll freely around the plaza.
  * **Minimal Overhead Feedback:** Customers have no permanent text above their heads. When a customer is happy/served, a heart emoji (`❤️`) appears above their head for a few seconds. When a customer becomes unhappy, an angry emoji + complaint (`😠 Need Food!`, `😠 Need WC!`, `😠 Crowded!`) appears above their head for a few seconds.
* **5 Customer Archetypes:**
  1. **Normal (`NORMAL`):** Standard speed (`2.6 m/s`), `0–2` needs; becomes unhappy if a need is not fulfilled in time.
  2. **Elder (`ELDER`):** Walks very slowly (`1.35 m/s`); requires sitting down on a **Picnic Table** or **Bench** for a while before leaving; becomes unhappy without rest and can get **Lost** in the plaza.
  3. **Business (`BUSINESS`):** Rushes everywhere (`3.8 m/s`) with `1–2` urgent needs and a short patience timer; pays a `1.5x` tip when served quickly, but becomes unhappy quickly if delayed.
  4. **Couple (`COUPLE`):** A single unified pair of two side-by-side citizens who always stay together through paths and facilities. Counts as **`1` customer set** when spawning, **`2` people on a tile** (`get_tile_headcount() == 2`) for crowd density, and otherwise behaves identically to a Normal customer.
  5. **Children (`CHILD`):** Tiny energetic customers (`0.68x` scale) who easily become **Lost** in the plaza, wandering aimlessly until guided by **Plaza Staff / Security** (or eventually finding the exit).
* **Reputation & Customer Set Spawning:**
  * **Reputation** starts at `1.0`, **never decreases**, and has **no maximum cap**.
  * Higher Reputation reduces the time between customer sets down to a **minimum of `1.0` second**.
  * **Customer Set Size** (number of customers arriving per spawn tick) starts at `1` and scales randomly with Reputation (`1–2` at low reputation up to `4–10` customers of mixed types at high reputation).
* **Littering:**
  * Customers finishing food/drinks may drop **Trash** on the floor if no **Trashcan** is within `2.5` tiles. Floor trash slows walkers and reduces visitor satisfaction until cleaned by a **Janitor**.

---

## 5. Edge Gates, Fences, Water Restrictions & Crowd Escape
* **Edge Gates & One-Way Flow:**
  * Fixed 3D gate arches are removed. Any **Walk Tile** placed at the left or right plaza edge acts as a two-way gate.
  * **Entry Gate** tiles only allow customers to walk **IN** to the plaza; **Exit Gate** tiles only allow customers to walk **OUT** from the plaza.
* **Impassable Water & Fences:**
  * Nobody (neither customers nor staff/Janitors) can ever walk on **water tiles** (`river`, `pond`) or through player-placed **Fences**.
* **Tile Capacity (`Max 10 People / Tile`) & Crowd Escape:**
  * Each `1x1` walking tile holds a maximum of **`10` people** (`1` person = `100%` speed $\rightarrow$ `10` people = `5%` speed).
  * If a customer gets stuck at a congested walking path or gate, they become **unhappy** (`😠 Crowded!`) and **walk freely** off-path (around the crowd, while still respecting water, fences, and solid facilities) to exit the plaza.

---

## 6. Minimal & Cozy HUD
* **Top-Left Vertical Card:**
  * **Row 1:** Happiness (`0–100` number, e.g., `♥ 100`).
  * **Row 2:** Reputation (`★ 1.0`, unlimited, without spawn-rate clutter).
  * **Row 3:** Budget (`💰 $200k`).
* **Top-Right Card:**
  * Shows only the **Day of the Week** (`MON`..`SUN`, no plaza name or week number), Day/Night indicator, and speed controls (`Space`, `1`, `2`, `3`).
* **Auto-Hiding Bottom Build Dock:**
  * Hidden by default during gameplay. Moving the mouse to the bottom of the screen reveals the **Category Bar** (`Path`, `Dining`, `Service`, `Comfort`, `Utility`, `Staff` — no `All` tab). Clicking a category expands the items for that category.

---

## 6. Plaza Service Staff
1. **Janitor (`$1,000 / day`):** Cleans floor trash and empties trashcans. Can walk **off-path across the grass** to reach messes directly.
2. **Plaza Staff (`$2,000 / day`):** Patrols walkways and guides **Lost** customers (Children & Elders) to their needed facility or exit. Accumulates exhaustion and must rest on a **Bench** or **Picnic Table** before returning to work.
3. **Security Officer (`$3,000 / day`):** Guides **Lost** customers, rests when exhausted, and projects a **Crowd Flow Aura** that makes crowded customers move significantly faster through congested tiles.

---

## 7. Technical Architecture & Folder Structure

```text
res://
├── PROJECT_INFO.md             # Project overview, gameplay rules, and architecture reference
├── project.godot               # Godot 4 configuration (Forward+ PC / Mobile fallback)
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
    ├── game_director.gd        # Economy, calendar, reputation waves, staff dispatcher, UI
    ├── facility_catalog.gd     # Categorized facility definitions, costs, income, staff wages
    ├── location_catalog.gd     # 4 playable scenarios, budgets, palettes, and obstacles
    ├── camera_rig.gd           # Continuous camera transitions & bird's-eye WASD/MMB pan
    ├── day_night_cycle.gd      # 30s day / 30s night lighting, brightness slider & lamps
    ├── grid_manager.gd         # Budget-aware placement, solid footprints & trash props
    ├── path_network.gd         # Dual AStar2D (shortest vs crowd-diverting) & tile occupancy
    ├── peep_agent.gd           # 5 citizen archetypes, 0-2 needs, lost state & littering
    ├── staff_agent.gd          # Autonomous Janitor (off-path), Plaza Staff & Security Officer
    ├── stall_controller.gd     # Facility service queue, revenue emission, benches & trashcans
    └── procedural_props.gd     # Cozy 3D builders for facilities, archetypes, staff & city props
```
