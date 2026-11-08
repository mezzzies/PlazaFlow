# PlazaFlow — Game Summary

## What Is PlazaFlow?
**PlazaFlow** is a cozy, minimalist 3D urban plaza and crowd-flow management game built in **Godot Engine 4.6**. Inspired by the clean tabletop diorama aesthetic of *Mini Motorways* and *Mini Metro*, combined with tactile 2.5D floating card menus inspired by *Balatro*, **PlazaFlow** puts you in charge of designing, expanding, and maintaining a bustling public city plaza day and night.

Citizens continuously enter your plaza from surrounding city streets. Some are simply commuting through, while others stop to grab food, buy a drink, use the restroom, rest on a park bench, or visit grand **Signature Landmarks**. Your goal is to lay down efficient walkways, orient facilities and their entrances, hire helpful plaza staff, and shape your plaza's identity week by week so citizen **Happiness** stays high and your plaza's **Reputation** grows!

---

## Core Gameplay Loop
1. **Choose a Plaza Location Card:**
   * Select from 4 distinct city plaza cards (*Old Town Square*, *Riverside Park*, *Lantern Night Market*, and *Central Station Plaza*), each with its own initial map size (`Small 19×13` up to `Grand 29×19`), dynamic starting budget (`90k–100k 🪙`, calculated from `[1 full row of walk tiles] + [6 core facilities average cost]` rounded up to the nearest `10k 🪙`), 3D landmarks, and visitor habits.
   * Gates are **not** shown while browsing locations; once you start a location, **1 initial Entry + Exit gate pair** appears on the left/right road edges (they can even spawn on the same side).
2. **Design Walkways, Rotatable Facilities & Signature Landmarks:**
   * Use the **Always-Visible Cozy Minimal Floating Category Dock** at the bottom of the screen (`Path`, `Dining`, `Service`, `Comfort`, `Utility`, `Signature`, `Staff`).
   * Place **Walk Tiles** (`1.5k 🪙`), **Express Tiles** (`3k 🪙`, `+40%` walking speed), **Entry/Exit Gates** (`2k 🪙`), and **Fences** (`500 🪙`).
   * Construct facilities with **directional entrances** and a live **3D Blueprint Hover Preview** showing the building footprint and entrance arrow. Press **`Q` / `E`** to rotate facilities counter-clockwise or clockwise (`90°` steps, automatically swapping width and depth for rectangular footprints).
   * Build **Signature Landmarks** (`1×1` up to `5×5`, including rectangular `2×1`, `3×2`, `4×2`, `4×3` shapes) — strictly **1 per item** in the entire park — each carrying a unique **Benefit (`✔`)** and **Disadvantage (`✖`)**.
3. **Dynamic Reputation Spawning, Rush Hours & Weekly Map Expansion:**
   * **Reputation** starts at `1.0★` with **no upper limit**, increasing by **`+0.1★`** for every customer who leaves the plaza with **100% Happiness**.
   * Customer arrival rate is synchronized with Reputation: every **10-second window**, **`floor(Reputation)`** customers arrive at randomized times across random Entry Gates, capped so active customers in the plaza never exceed **`ceil(Reputation) × 3`**.
   * **Daily Rush Hours** (`08:00–10:00` Morning Commute & `17:00–19:00` Evening Rush) temporarily boost arrival flow (`1.8×`) with extra **Business** commuters.
   * **Every Monday (from Week 2 onward):** The plaza **expands vertically** (`+1` row at the top and `+1` row at the bottom), and **1 or more new random Entry/Exit gates** spawn on empty tiles (with higher Reputation increasing the chance of multiple gates).
4. **Manage Crowd Flow, Scenic Combos & Cleanliness:**
   * Each walking tile holds up to **10 people**; overcrowded paths slow pedestrians down. If a walkway or gate becomes gridlocked, frustrated citizens (`😠`) step off the path to walk around the crowd.
   * Placing **Flower Gardens**, **Duck Ponds**, or **Park Benches** within `2` tiles of **Dining** stalls grants a **Scenic Bonus (`+25%` dining price)** with golden floating popups.
   * Visitors finishing food or drinks may drop litter if no **Trashcan** is nearby, slowing down dirty tiles and hurting daily Happiness unless cleaned by a **Janitor** or **Cleaning Drone**.
5. **End-of-Day Settlement & Weekly Events (Thursday & Sunday):**
   * Every in-game day lasts **1 minute** (`30s` Day / `30s` Night), followed by a 2.5D **Settlement Announcement Card** summarizing **Happiness**, **Reputation**, **Daily City Grant**, **Service Income**, and **Staff Wages** in game currency (`🪙`). If Happiness drops to `10` or below, the city closes the plaza (**Game Over**).
   * **Thursday — Facility Upgrade Day (2 Choices):** Choose between 2 Signature Landmarks to unlock and receive **1 Free Voucher** (`FREE (1)`).
   * **Sunday Morning — Trade-Off Perk Selection (3 Choices):** Choose 1 of 3 municipal Perks (18 total perks across 3 tiers) where every bonus comes with a strategic drawback.

---

## Meet the Citizens (5 Archetypes)
* **Normal Citizens:** Stroll through the plaza with `0–2` needs; happy (`❤️`) when served promptly, unhappy (`😠`) if queues are full.
* **Elders:** Walk slowly and always need a comfortable place to sit (`SIT` need). Can occasionally get **Lost**.
* **Business Commuters:** Rush through the plaza (`+45%` speed) with urgent needs, especially during **Rush Hour**; they tip **`+35%` extra** when served quickly, but lose patience fast.
* **Couples:** Walk side-by-side as a pair (`1` customer set, `2` people on a tile), sharing every facility stop together.
* **Children:** Energetic young visitors who easily get **Lost** and wander off-path until guided by **Plaza Staff**, **Security**, or an **Info Kiosk**.

---

## Categories, Facilities & Staff At a Glance

### Build Categories (Cozy Minimal Floating Icon Dock)
* **🛤 Path:** Walk Tile (`1.5k 🪙`), Express Tile (`3k 🪙`, `+40%` speed), Fence (`500 🪙`), Entry Gate (`2k 🪙`), Exit Gate (`2k 🪙`), Demolish (`50%` refund).
* **🍔 Dining:** Food Shop (`12k 🪙`, earns `+350 🪙`), Drink Stall (`8k 🪙`, earns `+220 🪙`).
* **🚻 Service:** Restroom (`10k 🪙`, earns `+120 🪙`), Info Kiosk (`6k 🪙`, guides lost visitors within `3` tiles).
* **🪑 Comfort:** Picnic Table (`7k 🪙`, seats `4`), Park Bench (`3.5k 🪙`, seats `2`).
* **🗑 Utility:** Trashcan (`1.5k 🪙`, absorbs litter within `2.5` tiles), Lamp Post (`1.2k 🪙`, lights night paths & reduces getting lost).
* **🏛 Signature Landmarks (24 Unique Items — Max 1 Each in Park, `1×1` up to `5×5`):**
  * **1×1 Compact:** *Coffee Roaster*, *Wishing Well*, *Gelato Pavilion*, *Art Obelisk*.
  * **2×1 Rectangular:** *Street Stage*, *Matcha House*.
  * **2×2 Medium Square:** *Flower Garden*, *Clock Tower*, *Gold Monolith*.
  * **3×2 Rectangular:** *Duck Pond*, *Cyber Arcade*, *Triumph Arch*, *Biergarten*, *Onsen Spa*.
  * **4×2 Long Rectangular:** *Skate Bowl*, *Steam Train*.
  * **3×3 Large Square:** *Carousel*, *Zen Shrine*, *Botanic Dome*, *Planetarium*, *Sky Tower*.
  * **4×3 Grand Rectangular:** *Ferris Wheel*.
  * **4×4 Extra-Large Square:** *Grand Circus*.
  * **5×5 Maximum Size:** *Diamond Hall*.
* **🧹 Staff (Can Walk Through Both Entry & Exit Gates Freely):**
  * **Janitor (`1k 🪙/day`):** Walks freely across grass and paths to clean floor litter and empty trashcans.
  * **Plaza Staff (`2k 🪙/day`):** Guides **Lost** Elders and Children back on track; rests on benches when tired.
  * **Security Officer (`3k 🪙/day`):** Guides **Lost** visitors and projects a **Crowd Flow Aura** that speeds up congested walkways.
  * **Cleaning Drone (`500 🪙/day`, `2k 🪙` hire — Special Perk Unlock):** Autonomous flying drone that cleans floor litter at high speed (`4.2 m/s`) without ever getting tired.

---

## Controls & Shortcuts
* **Camera Pan:** `W`, `A`, `S`, `D` or `Middle Mouse Button` drag
* **Camera Zoom:** `Mouse Wheel Up / Down`
* **Rotate Facility Blueprint:** `Q` (Counter-Clockwise `-90°`) / `E` (Clockwise `+90°`)
* **Place / Paint:** `Left Mouse Button` (click or drag for paths/fences)
* **Quick Demolish / Unselect:** `Right Mouse Button` or `Escape`
* **Time Speed Controls:**
  * `Spacebar`: Pause / Resume Time
  * `1`: Normal Speed (`1x`)
  * `2`: Fast Speed (`1.5x`)
  * `3`: Double Speed (`2x`)
