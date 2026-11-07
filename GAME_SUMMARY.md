# PlazaFlow — Game Summary

## What Is PlazaFlow?
**PlazaFlow** is a cozy, minimalist 3D urban plaza and crowd-flow management game built in **Godot Engine 4**. Inspired by the clean tabletop aesthetic of *Mini Motorways* and *Mini Metro*, combined with tactile 2.5D floating card menus inspired by *Balatro*, **PlazaFlow** puts you in charge of designing, expanding, and maintaining a bustling public city plaza day and night.

Citizens continuously enter your plaza from surrounding city streets. Some are simply commuting through, while others stop to grab food, buy a drink, use the restroom, or rest on a park bench. Your goal is to lay down efficient walkways, place the right mix of facilities, hire helpful plaza staff, and shape your plaza's identity week by week so citizen **Happiness** stays high and your plaza's **Reputation** grows!

---

## Core Gameplay Loop
1. **Choose a Plaza Location Card:**
   * Select from 4 distinct city plaza cards (*Old Town Square*, *Riverside Park*, *Lantern Night Market*, and *Central Station Plaza*), each with its own map size (`Small 19×13` up to `Grand 29×19`), starting budget (`$190k–$240k`), 3D landmarks, and visitor habits.
2. **Design Walkways, Gates & Facilities:**
   * Place **Walk Tiles** to guide foot traffic, **Entry/Exit Gates** at the plaza edges to organize one-way flow, and **Fences** to block off restricted areas.
   * Construct **Dining**, **Service**, **Comfort**, and **Utility** facilities to fulfill citizen needs (`Food`, `Drink`, `Restroom`, `Sit`) and keep the plaza clean and well-lit.
3. **Manage Crowd Flow & Cleanliness:**
   * Each walking tile holds up to **10 people**; overcrowded paths slow pedestrians down. If a walkway or gate becomes completely gridlocked, frustrated citizens (`😠`) will step off the path and walk freely around the crowd to exit.
   * Visitors finishing food or drinks may drop litter if no **Trashcan** is nearby, reducing walking speed on dirty tiles and hurting your daily Happiness rating unless cleaned by a **Janitor**.
4. **End-of-Day Settlement Announcement:**
   * Every in-game day lasts **1 minute** (`30s` Day / `30s` Night).
   * At the end of each day, a cozy animated **Settlement Announcement Card** pops onto the screen, summarizing your **Happiness**, **Reputation** growth, **Daily City Grant**, **Service Income**, and **Staff Wages**.
   * If Plaza Happiness drops to `10` or below at the end-of-day inspection, the city closes the plaza (**Game Over**).
5. **Shape Your Plaza Every Wednesday & Sunday:**
   * **Wednesday Facility Upgrade (2 Choices):** Choose between 2 special landmark facilities (such as **Flower Garden** vs. **Duck Pond**, or **Coffee Roaster** vs. **Street Stage**) that unlock a new buildable facility and permanently shift which types of citizens visit your plaza.
   * **Sunday Morning Perk Selection (Benefit & Disadvantage):** Choose 1 of 3 municipal trade-off Perks where every bonus comes with a strategic drawback (for example, *Service Income `×2.0` but Staff Cost `×1.5`*, or *Receive `+$50k` Budget but `-15%` Reputation*).

---

## Meet the Citizens (5 Archetypes)
* **Normal Citizens:** Stroll through the plaza with `0–2` needs; happy (`❤️`) when served promptly, unhappy (`😠`) if queues are full.
* **Elders:** Walk slowly and always need a comfortable place to sit (**Park Bench**, **Picnic Table**, **Flower Garden**, or **Duck Pond**). Can occasionally get **Lost**.
* **Business Commuters:** Rush through the plaza in a hurry with urgent needs; they tip **`+35%` extra** when served quickly, but lose patience fast.
* **Couples:** Walk side-by-side as a pair (`1` customer set, `2` people on a tile), sharing every facility stop together.
* **Children:** Energetic young visitors who easily get **Lost** and wander off-path until guided by **Plaza Staff**, **Security**, or an **Info Kiosk**.

---

## Facilities & Staff At a Glance

### Build Categories (Auto-Hiding Bottom Dock)
* **Path:** Walk Tile (`$1.5k`), Fence (`$500`), Entry Gate (`$2k`), Exit Gate (`$2k`), Demolish (`50%` refund).
* **Dining:** Food Shop (`$12k`, earns `+$150`), Drink Stall (`$8k`, earns `+$90`), *Coffee Roaster* (`$14k`, earns `+$140`, Wednesday unlock).
* **Service:** Restroom (`$10k`, earns `+$25`), Info Kiosk (`$6k`, guides lost visitors), *Street Stage* (`$13k`, earns `+$60`, Wednesday unlock).
* **Comfort:** Picnic Table (`$7k`, seats `4`), Park Bench (`$3.5k`, seats `2`), *Flower Garden* (`$9k`, Wednesday unlock), *Duck Pond* (`$9.5k`, Wednesday unlock).
* **Utility:** Trashcan (`$1.5k`, prevents littering), Lamp Post (`$1.2k`, lights night paths & prevents getting lost).
* **Staff:**
  * **Janitor (`$1k/day`):** Walks freely across grass and paths to clean floor litter and empty trashcans.
  * **Plaza Staff (`$2k/day`):** Guides **Lost** Elders and Children back on track; rests on benches when tired.
  * **Security Officer (`$3k/day`):** Guides **Lost** visitors and projects a **Crowd Flow Aura** that speeds up congested walkways.

---

## Controls & Shortcuts
* **Camera Pan:** `W`, `A`, `S`, `D` or `Middle Mouse Button` drag
* **Camera Zoom:** `Mouse Wheel Up / Down`
* **Place / Paint:** `Left Mouse Button` (click or drag for paths/fences)
* **Quick Demolish / Unselect:** `Right Mouse Button` or `Escape`
* **Time Speed Controls:**
  * `Spacebar`: Pause / Resume Time
  * `1`: Normal Speed (`1x`)
  * `2`: Fast Speed (`1.5x`)
  * `3`: Double Speed (`2x`)
