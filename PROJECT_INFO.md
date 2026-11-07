# PlazaFlow — Project Information & Design Specification

## 1. Overview
**PlazaFlow** is a cozy, minimalist 3D urban plaza and crowd-ecosystem management game built in **Godot Engine 4**, inspired by the tactile tabletop diorama aesthetic of *Mini Motorways* and the living park simulation of classic cozy tycoon games.

Players choose a city plaza scenario, manage their municipal **Budget**, construct categorized **Facilities** (**Path**, **Dining**, **Service**, **Comfort**, **Utility**), and hire **Plaza Staff** (**Janitors**, **Plaza Guides**, **Security Officers**) to keep a diverse crowd of citizens (**Normal**, **Elders**, **Business People**, **Couples**, **Children**) happy day and night.

---

## 2. Visual Direction, 2.5D Floating Menus & Continuous Diorama World
* **Continuous 3D Scene Architecture (Mini Motorways / Mini Metro / Balatro Style):**
  * **Main Menu Diorama (`z = -42`) & 2.5D Floating Start Menu:**
    * **3D Animated Title Diorama:** A gently bobbing miniature roundabout island with a central stone fountain, cozy shops, houses, strolling citizens, floating 3D hot-air balloons, and drifting low-poly clouds while the camera smoothly orbits.
    * **2.5D Floating Balatro-Style Menu Cards:** Instead of a flat text box container, the Starting Menu presents a floating 2.5D **Logo Card** displaying **only** `"PLAZA FLOW"` in a bold 3D-extruded slanted display logo font with wave-animated characters (no extra subtitle or badge clutter inside the card), alongside 3 clean 2.5D floating action cards (`▶ PLAY`, `⚙ OPTIONS`, `✕ QUIT GAME`) that continuously bob, wobble in 2.5D, and tilt/pop dynamically toward the mouse cursor.
  * **Location Select Overview (Mini Metro-Style Location Cards):**
    * Smooth continuous camera flight to the main Plaza Diorama Board (`z = 0`), live-previewing each scenario's custom color palette and 3D landmarks.
    * **Mini Metro Location Cards:** Each location is presented as a tactile postcard/transit card with a colored top header strip (`accent_color`) and 2.5D hover/selection elevation:
      * **Main Information:** Prominent **Location Name** and colored **Map Size Pill Badge** (e.g., `SIZE: SMALL (19×13)`).
      * **Secondary Information:** **Starting Budget** (`💰 Budget: $200k`) and a **concise 1-line description** (no long text blocks).
  * **Active Gameplay View:** Smooth continuous zoom and tilt into the interactive Bird's-Eye Gameplay Camera (`WASD` / `Middle-Mouse` pan, `Scroll` zoom).
* **4 Playable Locations & Custom Map Sizes ([`LocationCatalog`](file:///d:/01_Working/07_Project/PlazaFlow/scripts/location_catalog.gd)):**
  1. **Old Town Square** (*Historic District — Relaxed — Small `19×13` tiles*): `$200,000` starting budget. Warm cobblestone palette with a central stone fountain and flower planters.
  2. **Riverside Park** (*Green Belt — Moderate — Large `25×17` tiles*): `$230,000` starting budget. Spacious park split by a North–South river and duck pond with an arched wooden bridge at `(2, 0)..(3, 0)`. High Comfort/Picnic demand.
  3. **Lantern Market** (*Old Harbour Lanes — Moderate — Medium `23×13` tiles*): `$190,000` starting budget. Twilight lavender/slate palette with market stalls forming narrow alleys under glowing lantern strings. High Dining demand.
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
     * **Coffee Roaster (`$14,000`, Wednesday Upgrade Unlock):** Earns **`+$140`** per customer served (`DRINK` need); attracts **Business** visitors (`+120%`) and boosts all Dining income by **`+30%`**.
  3. **Service:**
     * **Restroom (`$10,000`):** Earns **`+$25`** per customer served (`RESTROOM` need).
     * **Info Kiosk (`$6,000`):** `$0` fee; passively guides/prevents `Lost` customers within `3` tiles.
     * **Street Stage (`$13,000`, Wednesday Upgrade Unlock):** Earns **`+$60`** per visitor (`SIT` need); attracts **Couples & Normal** visitors (`+80%`) and increases queue patience across all facilities by **`+35%`**.
  4. **Comfort (Free Public Amenities):**
     * **Picnic Table (`$7,000`):** `$0` fee; seats `4` for Elder/Customer `SIT` needs & Staff rest.
     * **Park Bench (`$3,500`):** `$0` fee; seats `2` for compact Elder `SIT` needs & Staff rest.
     * **Flower Garden (`$9,000`, Wednesday Upgrade Unlock):** `$0` fee; seats `6` (`SIT` need); attracts **Elders** (`+120%`) and makes all Comfort facilities rest visitors **`30%` faster**.
     * **Duck Pond (`$9,500`, Wednesday Upgrade Unlock):** `$0` fee; seats `6` (`SIT` need); attracts **Couples & Children** (`+100%`) and calms nearby visitors so they do not get `Lost`.
  5. **Utility:**
     * **Trashcan (`$1,500`):** `$0` fee; absorbs litter from customers within `2.5` tiles.
     * **Lamp Post (`$1,200`):** `$0` fee; illuminates paths at night and reduces getting lost.
* **Daily City Grant, Staff Payroll & Animated Settlement Announcement Card (Settled at the End of Every Day):**
  * **Cozy Animated Settlement Announcement Card:** At the end of each day, a large, legible 2.5D **Settlement Announcement Card** pops in at the top-center of the screen with a cozy bounce and floating animation, clearly showing **Happiness & Reputation changes**, **City Grant**, **Service Income**, **Staff Wages**, and the **Daily Net Balance Pill**.
  * **End-of-Day Happiness & Reputation Settlement:**
    * Happiness is calculated at the end of each day based on visitor satisfaction ratio (happy exits vs unfulfilled exits), plaza cleanliness (total litter left on the ground), lost citizens guided, and stall overload events.
    * Reputation updates at end of day based on the day's Happiness (e.g. `+0.20★` to `+0.35★` on great days, stable on average days, and declining if neglected, floored at `1.0★`).
    * Game Over occurs at end-of-day inspection if Happiness drops to `≤ 10`.
  * **City Grant Formula:**
    $$\text{Daily Grant} = \text{round}\!\left(\left(\$7,000 + \$3,000 \times \left(\text{Reputation} - 1.0\right)\right) \times \left(\frac{\text{Happiness}}{100}\right)^{1.25} \times \text{multiplier}\right)$$
  * **Daily Staff Wages:** Deducted automatically at the end of each day (`$1k` Janitor, `$2k` Plaza Staff, `$3k` Security Officer, scaled by any active Perk wage multiplier).
* **Weekly Facility Upgrade & Trade-Off Perk Schedule:**
  * **Every Wednesday (`day_index == 2`):** **Plaza Direction Facility Upgrade (2 Choices Only)** — The player chooses between **2 landmark facilities** that shape the character of the plaza, unlocking the chosen facility in the build dock (+1 free voucher) and permanently shifting visitor demographics and facility performance:
    * **Flower Garden vs. Duck Pond:**
      * **Flower Garden:** **Elders** visit the plaza much more often (`+120%`), and all **Comfort** facilities rest visitors **`30%` faster**.
      * **Duck Pond:** **Couples & Kids** visit the plaza much more often (`+100%`), and nearby visitors are calmed so they do not get lost.
    * **Coffee Roaster vs. Street Stage:**
      * **Coffee Roaster:** **Business** customers visit much more often (`+120%`), and all **Dining** facilities earn **`+30%` income**.
      * **Street Stage:** **Couples & Normal** visitors arrive more often (`+80%`), and all facilities gain **`+35%` queue patience**.
  * **Every Sunday Morning (`day_index == 6`):** **Trade-Off Perk Selection (Benefit + Disadvantage)** — The player selects 1 of 3 municipal Perks where every card carries both a strong **Benefit (`✔`)** and a **Disadvantage (`✖`)**, such as:
    * **Commercial Boom:** `✔ Service Income ×2.0` / `✖ Staff Daily Cost ×1.5`
    * **Emergency City Grant:** `✔ Receive +$50k Budget immediately` / `✖ Reduce Reputation by -15%`
    * **Tourism Festival Blitz:** `✔ Reputation +30% & City Grant +25%` / `✖ Visitors drop 2× more Trash`
    * **Civic Union Pact:** `✔ Staff Cost ×0.5 & +1 Free Janitor` / `✖ Service Income -25%`
    * **Corporate Sponsorship:** `✔ Receive +$35k & +6 Free Walk Tiles` / `✖ Reduce Happiness by -15`

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
* **Facility Selection & Individual Agency:**
  * Customers evaluate facilities considering queue size, distance, and individual personality (`crowd_aversion`, `distance_tolerance`, and individual whim).
  * Less crowded facilities are strongly favored; customers actively avoid full queues (`fullness_penalty = 500`) and will walk to quieter stalls across the plaza.
* **Reputation & Customer Set Spawning:**
  * **Reputation** starts at `1.0` and evolves at end-of-day based on customer happiness.
  * Higher Reputation & Happiness smoothly scale customer wave intervals (down to a safe minimum of `2.5` seconds) and set size (`1–2` up to `2–5` visitors max).
* **Littering & 3 Cleanliness Levels:**
  * Customers finishing food/drinks may drop **Trash** on the floor if no **Trashcan** is within `2.5` tiles.
  * Tile Cleanliness affects walking speed:
    * **Clean** (`0` trash): `100%` walking speed.
    * **Dirty** (`1–2` trash): `80%` walking speed.
    * **Max Dirty** (`3+` trash): `60%` walking speed.
  * Uncleaned trash left at end of day reduces the daily Happiness rating until cleaned by a **Janitor**.

---

## 5. Edge Gates, Fences, Water Restrictions & Crowd Escape
* **Edge Gates, Connected Plaza Paths & One-Way Flow:**
  * Fixed 3D gate arches are removed. Any **Walk Tile** placed at the left or right plaza edge acts as a two-way gate.
  * When walk tiles connect (such as a 2×2 or 3×3 plaza grid), corner quadrant fillers seamlessly merge adjacent tiles without any central gap or seam.
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
  * When a facility or tool is selected to place, the menu **stays appeared** on screen while placing. It remains visible until the player unselects the facility (by clicking the facility again, clicking `✕ Done`, collapsing the category, or pressing `Escape`). Once unselected, moving the mouse away hides the menu again.

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
