class_name FacilityCatalog
extends RefCounted

enum Category {
	PATH = 0,
	DINING = 1,
	SERVICE = 2,
	COMFORT = 3,
	UTILITY = 4,
	STAFF = 5
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
	EXIT_GATE = 12
}

enum StaffId {
	JANITOR = 0,
	PLAZA_STAFF = 1,
	SECURITY = 2
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
		"summary": "Walkway tile ($1.5k). Max 10 people/tile."
	},
	ItemId.FOOD_SHOP: {
		"id": ItemId.FOOD_SHOP,
		"name": "Food Shop",
		"category": Category.DINING,
		"cost": 12000,
		"income": 150,
		"service_time": 2.2,
		"capacity": 6,
		"need": NeedType.FOOD,
		"summary": "Dining ($12k). Earns +$150 per customer."
	},
	ItemId.DRINK_STALL: {
		"id": ItemId.DRINK_STALL,
		"name": "Drink Stall",
		"category": Category.DINING,
		"cost": 8000,
		"income": 90,
		"service_time": 1.4,
		"capacity": 6,
		"need": NeedType.DRINK,
		"summary": "Dining ($8k). Fast service, earns +$90/use."
	},
	ItemId.RESTROOM: {
		"id": ItemId.RESTROOM,
		"name": "Restroom",
		"category": Category.SERVICE,
		"cost": 10000,
		"income": 25,
		"service_time": 1.8,
		"capacity": 5,
		"need": NeedType.RESTROOM,
		"summary": "Service ($10k). Earns +$25 per customer."
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
		"summary": "Service ($6k). Guides lost visitors within 3 tiles."
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
		"summary": "Comfort ($7k, Free). Seats 4 for Elders & Staff rest."
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
		"summary": "Comfort ($3.5k, Free). Seats 2 for Elders & Staff rest."
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
		"summary": "Utility ($1.5k). Prevents littering within 2.5 tiles."
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
		"summary": "Utility ($1.2k). Illuminates paths & prevents getting lost."
	},
	ItemId.ERASE_TOOL: {
		"id": ItemId.ERASE_TOOL,
		"name": "Demolish",
		"category": Category.PATH,
		"cost": 0,
		"income": 0,
		"service_time": 0.0,
		"capacity": 0,
		"need": -1,
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
		"summary": "Barrier ($500). Blocks anyone from walking through."
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
		"summary": "One-way Gate ($2k). Only allows customers to walk IN."
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
		"summary": "One-way Gate ($2k). Only allows customers to walk OUT."
	}
}

const STAFF: Dictionary = {
	StaffId.JANITOR: {
		"id": StaffId.JANITOR,
		"name": "Janitor",
		"daily_wage": 1000,
		"hire_cost": 1000,
		"summary": "Wage: $1k/day. Walks off-path to clean floor trash & empty bins."
	},
	StaffId.PLAZA_STAFF: {
		"id": StaffId.PLAZA_STAFF,
		"name": "Plaza Staff",
		"daily_wage": 2000,
		"hire_cost": 2000,
		"summary": "Wage: $2k/day. Guides lost Elders/Children; rests on benches."
	},
	StaffId.SECURITY: {
		"id": StaffId.SECURITY,
		"name": "Security",
		"daily_wage": 3000,
		"hire_cost": 3000,
		"summary": "Wage: $3k/day. Guides lost visitors & speeds up crowded tiles."
	}
}

static func get_item(item_id: int) -> Dictionary:
	return ITEMS.get(item_id, ITEMS[ItemId.PATH_TILE])

static func get_cost(item_id: int) -> int:
	return int(get_item(item_id).get("cost", 0))

static func get_refund(item_id: int) -> int:
	return int(get_cost(item_id) * 0.5)

static func get_staff_info(staff_id: int) -> Dictionary:
	return STAFF.get(staff_id, STAFF[StaffId.JANITOR])

static func format_money(amount: int) -> String:
	if absi(amount) >= 1000:
		var k := float(amount) / 1000.0
		if is_zero_approx(fmod(k, 1.0)):
			return "$%dk" % roundi(k)
		return "$%.1fk" % k
	return "$%d" % amount
