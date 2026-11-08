class_name FacilityCatalog
extends RefCounted

enum Category {
	PATH = 0,
	DINING = 1,
	SERVICE = 2,
	COMFORT = 3,
	UTILITY = 4,
	STAFF = 5,
	SIGNATURE = 6
}

enum ItemId {
	PATH_TILE = 0,
	FOOD_SHOP = 1,
	DRINK_STALL = 2,
	RESTROOM = 3,
	INFO_KIOSK = 4,
	PICNIC_TABLE = 5,
	BENCH = 6,
	TRASHCAN = 7,
	LAMP_POST = 8,
	ERASE_TOOL = 9,
	FENCE = 10,
	ENTRY_GATE = 11,
	EXIT_GATE = 12,
	FLOWER_GARDEN = 13,
	DUCK_POND = 14,
	COFFEE_ROASTER = 15,
	STREET_STAGE = 16,
	STAFF_HOUSE = 17,
	GRAND_CLOCKTOWER = 18,
	VINTAGE_CAROUSEL = 19,
	FERRIS_WHEEL = 20,
	ZEN_SHRINE = 21,
	GOLDEN_MONOLITH = 22,
	WISHING_WELL = 23,
	CYBER_ARCADE = 24,
	BOTANICAL_DOME = 25,
	TRIUMPH_ARCH = 26,
	GELATO_PAVILION = 27,
	BIERGARTEN = 28,
	PLANETARIUM = 29,
	SKATE_BOWL = 30,
	SPA_BATHHOUSE = 31,
	OBSERVATION_TOWER = 32,
	TEA_HOUSE = 33,
	ART_OBELISK = 34,
	CIRCUS_TENT = 35,
	STEAM_TRAIN = 36,
	DIAMOND_PAVILION = 37
}

enum StaffId {
	JANITOR = 0,
	PLAZA_STAFF = 1,
	SECURITY = 2,
	DRONE = 3
}

enum NeedType {
	FOOD = 0,
	DRINK = 1,
	RESTROOM = 2,
	SIT = 3
}

const ITEMS: Dictionary = {
	ItemId.PATH_TILE: {
		"id": ItemId.PATH_TILE,
		"name": "Walk Tile",
		"category": Category.PATH,
		"cost": 1500,
		"income": 0,
		"service_time": 0.0,
		"capacity": 10,
		"need": -1,
		"size": Vector2i(1, 1),
		"summary": "Walkway tile (1.5k 🪙). Max 10 people/tile."
	},
	ItemId.FOOD_SHOP: {
		"id": ItemId.FOOD_SHOP,
		"name": "Food Shop",
		"category": Category.DINING,
		"cost": 12000,
		"income": 750,
		"service_time": 2.2,
		"capacity": 6,
		"need": NeedType.FOOD,
		"size": Vector2i(1, 1),
		"summary": "Dining (12k 🪙). Earns +750 🪙 per customer + big tips!"
	},
	ItemId.DRINK_STALL: {
		"id": ItemId.DRINK_STALL,
		"name": "Drink Stall",
		"category": Category.DINING,
		"cost": 8000,
		"income": 500,
		"service_time": 1.4,
		"capacity": 6,
		"need": NeedType.DRINK,
		"size": Vector2i(1, 1),
		"summary": "Dining (8k 🪙). Fast service, earns +500 🪙/use."
	},
	ItemId.RESTROOM: {
		"id": ItemId.RESTROOM,
		"name": "Restroom",
		"category": Category.SERVICE,
		"cost": 10000,
		"income": 250,
		"service_time": 1.8,
		"capacity": 5,
		"need": NeedType.RESTROOM,
		"size": Vector2i(1, 1),
		"summary": "Service (10k 🪙). Earns +250 🪙 per customer."
	},
	ItemId.INFO_KIOSK: {
		"id": ItemId.INFO_KIOSK,
		"name": "Info Kiosk",
		"category": Category.SERVICE,
		"cost": 6000,
		"income": 0,
		"service_time": 0.0,
		"capacity": 0,
		"need": -1,
		"size": Vector2i(1, 1),
		"summary": "Service (6k 🪙). Guides lost visitors within 3 tiles."
	},
	ItemId.PICNIC_TABLE: {
		"id": ItemId.PICNIC_TABLE,
		"name": "Picnic Table",
		"category": Category.COMFORT,
		"cost": 7000,
		"income": 0,
		"service_time": 4.0,
		"capacity": 4,
		"need": NeedType.SIT,
		"size": Vector2i(1, 1),
		"summary": "Comfort (7k 🪙, Free). Seats 4 for Elders & Staff rest."
	},
	ItemId.BENCH: {
		"id": ItemId.BENCH,
		"name": "Park Bench",
		"category": Category.COMFORT,
		"cost": 3500,
		"income": 0,
		"service_time": 3.5,
		"capacity": 2,
		"need": NeedType.SIT,
		"size": Vector2i(1, 1),
		"summary": "Comfort (3.5k 🪙, Free). Seats 2 for Elders & Staff rest."
	},
	ItemId.TRASHCAN: {
		"id": ItemId.TRASHCAN,
		"name": "Trashcan",
		"category": Category.UTILITY,
		"cost": 1500,
		"income": 0,
		"service_time": 0.0,
		"capacity": 15,
		"need": -1,
		"size": Vector2i(1, 1),
		"summary": "Utility (1.5k 🪙). Prevents littering within 2.5 tiles."
	},
	ItemId.LAMP_POST: {
		"id": ItemId.LAMP_POST,
		"name": "Lamp Post",
		"category": Category.UTILITY,
		"cost": 1200,
		"income": 0,
		"service_time": 0.0,
		"capacity": 0,
		"need": -1,
		"size": Vector2i(1, 1),
		"summary": "Utility (1.2k 🪙). Illuminates paths & prevents getting lost."
	},
	ItemId.ERASE_TOOL: {
		"id": ItemId.ERASE_TOOL,
		"name": "Demolish",
		"category": Category.UTILITY,
		"cost": 0,
		"income": 0,
		"service_time": 0.0,
		"capacity": 0,
		"need": -1,
		"size": Vector2i(1, 1),
		"summary": "Remove path, fence, gate, or facility (50% refund)."
	},
	ItemId.FENCE: {
		"id": ItemId.FENCE,
		"name": "Fence",
		"category": Category.PATH,
		"cost": 500,
		"income": 0,
		"service_time": 0.0,
		"capacity": 0,
		"need": -1,
		"size": Vector2i(1, 1),
		"summary": "Barrier (500 🪙). Blocks anyone from walking through."
	},
	ItemId.ENTRY_GATE: {
		"id": ItemId.ENTRY_GATE,
		"name": "Entry Gate",
		"category": Category.PATH,
		"cost": 2000,
		"income": 0,
		"service_time": 0.0,
		"capacity": 10,
		"need": -1,
		"size": Vector2i(1, 1),
		"summary": "One-way Gate (2k 🪙). Only allows customers to walk IN."
	},
	ItemId.EXIT_GATE: {
		"id": ItemId.EXIT_GATE,
		"name": "Exit Gate",
		"category": Category.PATH,
		"cost": 2000,
		"income": 0,
		"service_time": 0.0,
		"capacity": 10,
		"need": -1,
		"size": Vector2i(1, 1),
		"summary": "One-way Gate (2k 🪙). Only allows customers to walk OUT."
	},
	ItemId.FLOWER_GARDEN: {
		"id": ItemId.FLOWER_GARDEN,
		"name": "Flower Garden",
		"category": Category.SIGNATURE,
		"cost": 9000,
		"income": 0,
		"service_time": 2.6,
		"capacity": 8,
		"need": NeedType.SIT,
		"size": Vector2i(2, 2),
		"unique": true,
		"benefit": "✔ Benefit: Stalls within 3.2 tiles earn +50% Scenic Bonus; attracts Elders",
		"disadvantage": "✖ Disadvantage: Falling petals increase plaza floor littering by +20%",
		"summary": "2×2 Signature Landmark (9k 🪙). Gives nearby stalls +50% coins, but petals add +20% litter."
	},
	ItemId.DUCK_POND: {
		"id": ItemId.DUCK_POND,
		"name": "Duck Pond",
		"category": Category.SIGNATURE,
		"cost": 9500,
		"income": 0,
		"service_time": 2.8,
		"capacity": 8,
		"need": NeedType.SIT,
		"size": Vector2i(3, 2),
		"unique": true,
		"benefit": "✔ Benefit: Stalls within 3.2 tiles earn +50% Scenic Bonus & guides lost visitors",
		"disadvantage": "✖ Disadvantage: Visitors linger 30% longer at all Comfort facilities",
		"summary": "3×2 Signature Landmark (9.5k 🪙). Nearby stalls earn +50% coins, but comfort turnover is 30% slower."
	},
	ItemId.COFFEE_ROASTER: {
		"id": ItemId.COFFEE_ROASTER,
		"name": "Coffee Roaster",
		"category": Category.SIGNATURE,
		"cost": 14000,
		"income": 950,
		"service_time": 1.1,
		"capacity": 7,
		"need": NeedType.DRINK,
		"size": Vector2i(1, 1),
		"unique": true,
		"benefit": "✔ Benefit: Fast +950 🪙 espresso & boosts all Dining stall revenue by +25%",
		"disadvantage": "✖ Disadvantage: Caffeinated visitors have -15% queue patience plaza-wide",
		"summary": "1×1 Signature Landmark (14k 🪙). Boosts all Dining +25%, but lowers queue patience by 15%."
	},
	ItemId.STREET_STAGE: {
		"id": ItemId.STREET_STAGE,
		"name": "Street Stage",
		"category": Category.SIGNATURE,
		"cost": 13000,
		"income": 600,
		"service_time": 2.4,
		"capacity": 8,
		"need": NeedType.SIT,
		"size": Vector2i(2, 1),
		"unique": true,
		"benefit": "✔ Benefit: Earns +600 🪙 tips & increases all facility queue patience by +35%",
		"disadvantage": "✖ Disadvantage: Loud music slows walking speed by 15% within 3 tiles",
		"summary": "2×1 Signature Landmark (13k 🪙). +35% queue patience across plaza, but slows nearby walkers."
	},
	ItemId.STAFF_HOUSE: {
		"id": ItemId.STAFF_HOUSE,
		"name": "Staff House",
		"category": Category.UTILITY,
		"cost": 15000,
		"income": 0,
		"service_time": 0.0,
		"capacity": 4,
		"need": -1,
		"size": Vector2i(1, 1),
		"special_unlock": true,
		"summary": "Utility (15k 🪙). Restores staff energy 2.5x faster in a single visit."
	},
	ItemId.GRAND_CLOCKTOWER: {
		"id": ItemId.GRAND_CLOCKTOWER,
		"name": "Clocktower",
		"category": Category.SIGNATURE,
		"cost": 16000,
		"income": 0,
		"service_time": 0.0,
		"capacity": 0,
		"need": -1,
		"size": Vector2i(2, 2),
		"unique": true,
		"benefit": "✔ Benefit: Guides lost visitors within 6 tiles & speeds up all facilities +20%",
		"disadvantage": "✖ Disadvantage: Hourly chimes make Business patrons lose patience 20% faster",
		"summary": "2×2 Signature Landmark (16k 🪙). 6-tile guide beacon & +20% service speed; Business patience -20%."
	},
	ItemId.VINTAGE_CAROUSEL: {
		"id": ItemId.VINTAGE_CAROUSEL,
		"name": "Carousel",
		"category": Category.SIGNATURE,
		"cost": 18000,
		"income": 1100,
		"service_time": 2.5,
		"capacity": 10,
		"need": NeedType.SIT,
		"size": Vector2i(3, 3),
		"unique": true,
		"upkeep": 1500,
		"benefit": "✔ Benefit: Earns +1,100 🪙/ride & restores +2 Plaza Happiness for Kids/Couples",
		"disadvantage": "✖ Disadvantage: Mechanical maintenance costs 1.5k 🪙/day in daily upkeep",
		"summary": "3×3 Signature Landmark (18k 🪙). Earns +1.1k 🪙 & boosts Happiness; 1.5k 🪙/day upkeep."
	},
	ItemId.FERRIS_WHEEL: {
		"id": ItemId.FERRIS_WHEEL,
		"name": "Ferris Wheel",
		"category": Category.SIGNATURE,
		"cost": 24000,
		"income": 1600,
		"service_time": 3.2,
		"capacity": 12,
		"need": NeedType.SIT,
		"size": Vector2i(4, 3),
		"unique": true,
		"upkeep": 2500,
		"benefit": "✔ Benefit: Earns +1,600 🪙/ride & increases Reputation gain from happy exits +50%",
		"disadvantage": "✖ Disadvantage: Slow boarding (3.2s) and costs 2.5k 🪙/day in daily upkeep",
		"summary": "4×3 Signature Landmark (24k 🪙). Massive +1.6k 🪙 ticket & +50% Rep gain; 2.5k 🪙/day upkeep."
	},
	ItemId.ZEN_SHRINE: {
		"id": ItemId.ZEN_SHRINE,
		"name": "Zen Shrine",
		"category": Category.SIGNATURE,
		"cost": 12000,
		"income": 400,
		"service_time": 2.0,
		"capacity": 8,
		"need": NeedType.SIT,
		"size": Vector2i(3, 3),
		"unique": true,
		"benefit": "✔ Benefit: Reduces all Plaza Happiness penalties by 40% & calms visitors",
		"disadvantage": "✖ Disadvantage: Mindful atmosphere reduces Dining stall spending by -15%",
		"summary": "3×3 Signature Landmark (12k 🪙). Cuts Happiness loss by 40%, but reduces Dining revenue -15%."
	},
	ItemId.GOLDEN_MONOLITH: {
		"id": ItemId.GOLDEN_MONOLITH,
		"name": "Burger Monolith",
		"category": Category.SIGNATURE,
		"cost": 19000,
		"income": 1350,
		"service_time": 1.8,
		"capacity": 9,
		"need": NeedType.FOOD,
		"size": Vector2i(2, 2),
		"unique": true,
		"benefit": "✔ Benefit: Serves gourmet feasts (+1,350 🪙) & boosts all Food Shops +40%",
		"disadvantage": "✖ Disadvantage: Heavy wrappers increase plaza-wide littering by +35%",
		"summary": "2×2 Signature Landmark (19k 🪙). +1.35k 🪙 feast & +40% Food Shop income; +35% trash rate."
	},
	ItemId.WISHING_WELL: {
		"id": ItemId.WISHING_WELL,
		"name": "Wishing Well",
		"category": Category.SIGNATURE,
		"cost": 11000,
		"income": 800,
		"service_time": 1.2,
		"capacity": 6,
		"need": NeedType.SIT,
		"size": Vector2i(1, 1),
		"unique": true,
		"benefit": "✔ Benefit: Fast lucky coin tosses (+800 🪙) & restores +15 visitor patience",
		"disadvantage": "✖ Disadvantage: Unattended coins increase Pickpocket attraction (+50%)",
		"summary": "1×1 Signature Landmark (11k 🪙). +800 🪙 in 1.2s & restores patience, but lures Pickpockets."
	},
	ItemId.CYBER_ARCADE: {
		"id": ItemId.CYBER_ARCADE,
		"name": "Cyber Arcade",
		"category": Category.SIGNATURE,
		"cost": 17000,
		"income": 1250,
		"service_time": 2.0,
		"capacity": 10,
		"need": NeedType.SIT,
		"size": Vector2i(3, 2),
		"unique": true,
		"benefit": "✔ Benefit: Earns +1,250 🪙/play & doubles ticket revenue at Night (2×)",
		"disadvantage": "✖ Disadvantage: Neon hype attracts Skaters & Smartphone Zombies (+60%)",
		"summary": "3×2 Signature Landmark (17k 🪙). +1.25k 🪙 (2.5k 🪙 at night!), but spawns Skaters & Zombies."
	},
	ItemId.BOTANICAL_DOME: {
		"id": ItemId.BOTANICAL_DOME,
		"name": "Botanical Dome",
		"category": Category.SIGNATURE,
		"cost": 15000,
		"income": 650,
		"service_time": 2.2,
		"capacity": 10,
		"need": NeedType.SIT,
		"size": Vector2i(3, 3),
		"unique": true,
		"upkeep": 1200,
		"benefit": "✔ Benefit: +50% Scenic Bonus within 4 tiles & restores +3 Happiness daily",
		"disadvantage": "✖ Disadvantage: Climate-controlled glass dome costs 1.2k 🪙/day in upkeep",
		"summary": "3×3 Signature Landmark (15k 🪙). 4-tile +50% Scenic Aura & +3 daily Happiness; 1.2k 🪙/d upkeep."
	},
	ItemId.TRIUMPH_ARCH: {
		"id": ItemId.TRIUMPH_ARCH,
		"name": "Triumph Arch",
		"category": Category.SIGNATURE,
		"cost": 20000,
		"income": 0,
		"service_time": 0.0,
		"capacity": 0,
		"need": -1,
		"size": Vector2i(3, 2),
		"unique": true,
		"benefit": "✔ Benefit: Boosts daily City Grant payout by +35% & +0.2 ★ Rep every Monday",
		"disadvantage": "✖ Disadvantage: Heritage zoning increases Walk Tile & Fence cost by +25%",
		"summary": "3×2 Signature Landmark (20k 🪙). +35% City Grant & weekly Rep; +25% path/fence build cost."
	},
	ItemId.GELATO_PAVILION: {
		"id": ItemId.GELATO_PAVILION,
		"name": "Gelato Pavilion",
		"category": Category.SIGNATURE,
		"cost": 13500,
		"income": 1050,
		"service_time": 1.3,
		"capacity": 8,
		"need": NeedType.FOOD,
		"size": Vector2i(1, 1),
		"unique": true,
		"benefit": "✔ Benefit: Rapid sweet treats (+1,050 🪙 in 1.3s) & +6 visitor patience",
		"disadvantage": "✖ Disadvantage: Sticky drips cause patrons to drop 2× litter after eating",
		"summary": "1×1 Signature Landmark (13.5k 🪙). Fast +1,050 🪙 treats & patience boost; extra litter."
	},
	ItemId.BIERGARTEN: {
		"id": ItemId.BIERGARTEN,
		"name": "Biergarten",
		"category": Category.SIGNATURE,
		"cost": 16500,
		"income": 1300,
		"service_time": 2.0,
		"capacity": 10,
		"need": NeedType.DRINK,
		"size": Vector2i(3, 2),
		"unique": true,
		"benefit": "✔ Benefit: Earns +1,300 🪙/stein & boosts all Drink Stall revenue by +35%",
		"disadvantage": "✖ Disadvantage: 40% of served patrons immediately need a Restroom visit",
		"summary": "3×2 Signature Landmark (16.5k 🪙). +1.3k 🪙 & +35% Drink Stall income; creates Restroom demand."
	},
	ItemId.PLANETARIUM: {
		"id": ItemId.PLANETARIUM,
		"name": "Planetarium",
		"category": Category.SIGNATURE,
		"cost": 21000,
		"income": 1450,
		"service_time": 2.8,
		"capacity": 10,
		"need": NeedType.SIT,
		"size": Vector2i(3, 3),
		"unique": true,
		"benefit": "✔ Benefit: Earns +1,450 🪙 & illuminates the entire plaza at Night",
		"disadvantage": "✖ Disadvantage: Daytime matinee shows earn 30% less ticket revenue",
		"summary": "3×3 Signature Landmark (21k 🪙). Full-plaza night lighting & +1.45k 🪙; -30% daytime income."
	},
	ItemId.SKATE_BOWL: {
		"id": ItemId.SKATE_BOWL,
		"name": "Skate Bowl",
		"category": Category.SIGNATURE,
		"cost": 12500,
		"income": 700,
		"service_time": 1.6,
		"capacity": 8,
		"need": NeedType.SIT,
		"size": Vector2i(4, 2),
		"unique": true,
		"benefit": "✔ Benefit: Earns +700 🪙 & boosts all visitor walking speed on paths +15%",
		"disadvantage": "✖ Disadvantage: Loud tricks make Elders lose 15% patience when queuing",
		"summary": "4×2 Signature Landmark (12.5k 🪙). +15% path walk speed & +700 🪙; Elders have -15% patience."
	},
	ItemId.SPA_BATHHOUSE: {
		"id": ItemId.SPA_BATHHOUSE,
		"name": "Spa Bathhouse",
		"category": Category.SIGNATURE,
		"cost": 17500,
		"income": 1150,
		"service_time": 2.0,
		"capacity": 8,
		"need": NeedType.RESTROOM,
		"size": Vector2i(3, 2),
		"unique": true,
		"upkeep": 1400,
		"benefit": "✔ Benefit: Luxury restroom (+1,150 🪙) restores 100% Happiness to patrons",
		"disadvantage": "✖ Disadvantage: Heated pools & towel service cost 1.4k 🪙/day in upkeep",
		"summary": "3×2 Signature Landmark (17.5k 🪙). +1.15k 🪙 & guarantees 100% patron Happiness; 1.4k 🪙/d upkeep."
	},
	ItemId.OBSERVATION_TOWER: {
		"id": ItemId.OBSERVATION_TOWER,
		"name": "Sky Tower",
		"category": Category.SIGNATURE,
		"cost": 22000,
		"income": 1500,
		"service_time": 2.5,
		"capacity": 10,
		"need": NeedType.SIT,
		"size": Vector2i(3, 3),
		"unique": true,
		"benefit": "✔ Benefit: Earns +1,500 🪙 & guides lost visitors anywhere on the entire map",
		"disadvantage": "✖ Disadvantage: Elevator bottlenecks make its service 25% slower during daytime",
		"summary": "3×3 Signature Landmark (22k 🪙). Map-wide lost visitor beacon & +1.5k 🪙; slower by day."
	},
	ItemId.TEA_HOUSE: {
		"id": ItemId.TEA_HOUSE,
		"name": "Matcha House",
		"category": Category.SIGNATURE,
		"cost": 13000,
		"income": 900,
		"service_time": 1.6,
		"capacity": 7,
		"need": NeedType.DRINK,
		"size": Vector2i(2, 1),
		"unique": true,
		"benefit": "✔ Benefit: Ceremonial tea (+900 🪙) & Staff recover energy +30% faster",
		"disadvantage": "✖ Disadvantage: Quiet rules reduce Street Stage & entertainment tips by -20%",
		"summary": "2×1 Signature Landmark (13k 🪙). +900 🪙 & +30% Staff rest recovery; -20% stage tips."
	},
	ItemId.ART_OBELISK: {
		"id": ItemId.ART_OBELISK,
		"name": "Art Obelisk",
		"category": Category.SIGNATURE,
		"cost": 14500,
		"income": 0,
		"service_time": 0.0,
		"capacity": 0,
		"need": -1,
		"size": Vector2i(1, 1),
		"unique": true,
		"benefit": "✔ Benefit: Avant-garde prestige increases all visitor tip multipliers +25%",
		"disadvantage": "✖ Disadvantage: Polarizing design causes 10% of visitors to critique (-0.5 ♥)",
		"summary": "1×1 Signature Landmark (14.5k 🪙). +25% tips across all stalls, but 10% of patrons critique it."
	},
	ItemId.CIRCUS_TENT: {
		"id": ItemId.CIRCUS_TENT,
		"name": "Grand Circus",
		"category": Category.SIGNATURE,
		"cost": 19500,
		"income": 1400,
		"service_time": 2.6,
		"capacity": 12,
		"need": NeedType.SIT,
		"size": Vector2i(4, 4),
		"unique": true,
		"benefit": "✔ Benefit: Huge capacity (12) earning +1,400 🪙 & +30% customer arrival rate",
		"disadvantage": "✖ Disadvantage: Confetti & popcorn double litter drops from Circus patrons",
		"summary": "4×4 Signature Landmark (19.5k 🪙). +1.4k 🪙 & +30% customer arrival rate; extra circus litter."
	},
	ItemId.STEAM_TRAIN: {
		"id": ItemId.STEAM_TRAIN,
		"name": "Steam Train",
		"category": Category.SIGNATURE,
		"cost": 18500,
		"income": 1200,
		"service_time": 2.2,
		"capacity": 10,
		"need": NeedType.SIT,
		"size": Vector2i(4, 2),
		"unique": true,
		"upkeep": 1300,
		"benefit": "✔ Benefit: Earns +1,200 🪙/ride & gives +50% Scenic Bonus within 3.5 tiles",
		"disadvantage": "✖ Disadvantage: Coal & track maintenance costs 1.3k 🪙/day in upkeep",
		"summary": "4×2 Signature Landmark (18.5k 🪙). +1.2k 🪙 & +50% Scenic Bonus aura; 1.3k 🪙/d upkeep."
	},
	ItemId.DIAMOND_PAVILION: {
		"id": ItemId.DIAMOND_PAVILION,
		"name": "Diamond Hall",
		"category": Category.SIGNATURE,
		"cost": 25000,
		"income": 2000,
		"service_time": 3.0,
		"capacity": 8,
		"need": NeedType.SIT,
		"size": Vector2i(5, 5),
		"unique": true,
		"benefit": "✔ Benefit: Luxury exhibition (+2,000 🪙/patron) & +20% daily City Grant",
		"disadvantage": "✖ Disadvantage: High security needs increase all Staff daily wages by +25%",
		"summary": "5×5 Signature Landmark (25k 🪙). +2k 🪙/patron & +20% City Grant; Staff daily wages +25%."
	}
}

const STAFF: Dictionary = {
	StaffId.JANITOR: {
		"id": StaffId.JANITOR,
		"name": "Janitor",
		"daily_wage": 1000,
		"hire_cost": 1000,
		"summary": "Wage: 1k 🪙/day. Walks off-path to clean floor trash & empty bins."
	},
	StaffId.PLAZA_STAFF: {
		"id": StaffId.PLAZA_STAFF,
		"name": "Plaza Staff",
		"daily_wage": 2000,
		"hire_cost": 2000,
		"summary": "Wage: 2k 🪙/day. Guides lost Elders/Children; rests on benches."
	},
	StaffId.SECURITY: {
		"id": StaffId.SECURITY,
		"name": "Security",
		"daily_wage": 3000,
		"hire_cost": 3000,
		"summary": "Wage: 3k 🪙/day. Guides lost visitors & speeds up crowded tiles."
	},
	StaffId.DRONE: {
		"id": StaffId.DRONE,
		"name": "Cleaning Drone",
		"daily_wage": 500,
		"hire_cost": 2000,
		"special_unlock": true,
		"summary": "Wage: 500 🪙/day. Autonomous flying drone cleans litter without fatigue."
	}
}

static func calculate_starting_budget(grid_half_width: int) -> int:
	var path_cost := get_cost(ItemId.PATH_TILE)
	var num_row_tiles := grid_half_width * 2 + 1
	var row_cost := float(num_row_tiles * path_cost)
	var core_facilities: Array[int] = [
		ItemId.FOOD_SHOP,
		ItemId.DRINK_STALL,
		ItemId.RESTROOM,
		ItemId.INFO_KIOSK,
		ItemId.PICNIC_TABLE,
		ItemId.BENCH
	]
	var fac_sum := 0.0
	for fid in core_facilities:
		fac_sum += float(get_cost(fid))
	var six_fac_avg_cost := (fac_sum / float(core_facilities.size())) * 6.0
	var raw_total := row_cost + six_fac_avg_cost
	# Round up to the next multiple of 10k (e.g. 98k -> 100k, 114k -> 120k)
	return int(ceilf(raw_total / 10000.0) * 10000.0)

static func get_item(item_id: int) -> Dictionary:
	return ITEMS.get(item_id, ITEMS[ItemId.PATH_TILE])

static func get_cost(item_id: int) -> int:
	return int(get_item(item_id).get("cost", 0))

static func get_refund(item_id: int) -> int:
	return int(get_cost(item_id) * 0.5)

static func get_staff_info(staff_id: int) -> Dictionary:
	return STAFF.get(staff_id, STAFF[StaffId.JANITOR])

static func get_facility_size(item_id: int) -> Vector2i:
	var item := get_item(item_id)
	return item.get("size", Vector2i(1, 1))

static func get_rotated_size(item_id: int, rot_idx: int = 0) -> Vector2i:
	var s := get_facility_size(item_id)
	if posmod(rot_idx, 4) % 2 == 1:
		return Vector2i(s.y, s.x)
	return s

static func is_signature_item(item_id: int) -> bool:
	var item := get_item(item_id)
	return int(item.get("category", -1)) == Category.SIGNATURE or bool(item.get("unique", false))

static func get_signature_item_ids() -> Array[int]:
	var ids: Array[int] = [
		ItemId.FLOWER_GARDEN,
		ItemId.DUCK_POND,
		ItemId.COFFEE_ROASTER,
		ItemId.STREET_STAGE,
		ItemId.GRAND_CLOCKTOWER,
		ItemId.VINTAGE_CAROUSEL,
		ItemId.FERRIS_WHEEL,
		ItemId.ZEN_SHRINE,
		ItemId.GOLDEN_MONOLITH,
		ItemId.WISHING_WELL,
		ItemId.CYBER_ARCADE,
		ItemId.BOTANICAL_DOME,
		ItemId.TRIUMPH_ARCH,
		ItemId.GELATO_PAVILION,
		ItemId.BIERGARTEN,
		ItemId.PLANETARIUM,
		ItemId.SKATE_BOWL,
		ItemId.SPA_BATHHOUSE,
		ItemId.OBSERVATION_TOWER,
		ItemId.TEA_HOUSE,
		ItemId.ART_OBELISK,
		ItemId.CIRCUS_TENT,
		ItemId.STEAM_TRAIN,
		ItemId.DIAMOND_PAVILION
	]
	return ids

static func format_money(amount: int) -> String:
	if absi(amount) >= 1000:
		var k := float(amount) / 1000.0
		if is_zero_approx(fmod(k, 1.0)):
			return "%dk 🪙" % roundi(k)
		return "%.1fk 🪙" % k
	return "%d 🪙" % amount
