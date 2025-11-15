/datum/ordnance_tech
	///name that shows up in the TGUI
	var/name = "Something."
	///desc of what it is
	var/desc = "You shouldn't be seeing this."
	///the price of the tech
	var/value = 1
	// Added so we don't have to print disks all the time
	var/is_item = TRUE
	///path to the item

	var/item_path
	///if it's an unlock in a lathe, what unlock is it?
	var/list/tech_unlock = list()
	///is this tech or an actual item?

	var/item_type
	///should this add a new category? also stops from being purchaseable
	var/add_category = FALSE
	///can this be bought multiple times?
	var/can_rebuy = FALSE




/datum/ordnance_tech/proc/purchase(turf/location)
	if(isnull(item_path))
		return
	new item_path(location)
	playsound(location, 'sound/machines/twobeep.ogg', 15, 1)

//items

/datum/ordnance_tech/item
	name = "Items"
	item_type = ORDNANCE_UPGRADE_ITEM
	add_category = TRUE

/datum/ordnance_tech/item/analyzer
	name = "Data Analyzer"
	desc = "Analyzes the explosion caused by the casing and the amount of targets hit, granting ordnance technology credits."
	item_path = /obj/item/ordnance/data_analyzer
	add_category = FALSE
	can_rebuy = TRUE

/datum/ordnance_tech/item/explosive_paper
	name = "Explosive Reagent Recipe"
	desc = "Grants a research paper with a recipe on how to synthesize a chemical with explosive level 3"
	add_category = FALSE
	value = 20

/datum/ordnance_tech/item/explosive_paper/purchase(turf/location)
	var/datum/reagent/generated/reagent = new /datum/reagent/generated
	reagent.id = "ordnance_custom_explosive"
	reagent.name = reagent.generate_name()
	reagent.chemclass = CHEM_CLASS_NONE //can't scan this for research credits
	reagent.gen_tier = 1
	reagent.properties = list()
	reagent.overdose = 30
	reagent.overdose_critical = 60
	reagent.save_chemclass()
	reagent.color = text("#[][][]",num2hex(rand(0,255)),num2hex(rand(0,255)),num2hex(rand(0,255)))
	reagent.burncolor = reagent.color
	GLOB.chemical_reagents_list[reagent.id] = reagent
	reagent.add_property(PROPERTY_EXPLOSIVE, 3)
	reagent.generate_assoc_recipe(list(CHEM_CLASS_BASIC, CHEM_CLASS_BASIC, CHEM_CLASS_BASIC))
	reagent.generate_description()
	reagent.print_report(location)
	playsound(location, 'sound/machines/twobeep.ogg', 15, 1)

//upgrades

/datum/ordnance_tech/technology
	name = "Technologies"
	item_type = ORDNANCE_UPGRADE_TECH
	is_item = FALSE
	add_category = TRUE

/datum/ordnance_tech/technology/purchase(turf/location)
	// For technologies with is_item = FALSE, we just unlock them directly
	// No disk printing needed

	// Ensure tech_unlock is a list
	var/list/techs_to_unlock = islist(tech_unlock) ? tech_unlock : list(tech_unlock)

	for(var/unlock in techs_to_unlock)
		GLOB.ordnance_research.tech_bought += unlock

	// Update all armylathes with the new technology
	for(var/obj/structure/machinery/autolathe/armylathe/lathe in GLOB.machines)
		lathe.update_ordnance_tech(techs_to_unlock)

	playsound(location, 'sound/machines/twobeep.ogg', 15, 1)

/datum/ordnance_tech/technology/plastic_explosive
	name = "C4 Plastic Casing"
	desc = "A custom plastic explosive."
	tech_unlock = CUSTOM_C4
	value = 5
	add_category = FALSE

/datum/ordnance_tech/technology/mine
	name = "M20 Mine Casing"
	desc = "A custom chemical mine built from an M20 casing."
	tech_unlock = CUSTOM_CLAYMORE
	value = 12
	add_category = FALSE

/datum/ordnance_tech/technology/shell
	name = "80mm Mortar Shell"
	desc = "An 80mm mortar shell."
	tech_unlock = list(CUSTOM_SHELL, CUSTOM_SHELL_WARHEAD, CUSTOM_SHELL_CAMERA)
	value = 30
	add_category = FALSE

/datum/ordnance_tech/technology/rocket
	name = "84mm Rocket"
	desc = "An 84mm custom rocket."
	tech_unlock = list(CUSTOM_ROCKET, CUSTOM_ROCKET_WARHEAD)
	value = 35
	add_category = FALSE

/datum/ordnance_tech/technology/custom_ob
	name = "Custom Orbital Bombardment"
	desc = "An orbital bombardment shell able to be filled with custom reagents, only one can be deployed per operation."
	value = 50
	add_category = FALSE

/datum/ordnance_tech/technology/custom_ob/purchase(turf/location)
	ai_announcement("Custom Ordnance Orbital Warhead authorized and delivered to ASRS")
	var/datum/supply_order/order = new /datum/supply_order()
	order.ordernum = GLOB.supply_controller.ordernum++
	var/actual_type = GLOB.supply_packs_types["OB Custom Crate"]
	order.objects = list(GLOB.supply_packs_datums[actual_type])
	order.orderedby = MAIN_AI_SYSTEM

	GLOB.supply_controller.shoppinglist += order

//armylathe upgrades

/datum/ordnance_tech/lathe_upgrade
	name = "Armylathe Upgrades"
	item_type = ORDNANCE_UPGRADE_LATHE
	item_path = /obj/item/ordnance/tech_disk
	add_category = TRUE

/datum/ordnance_tech/lathe_upgrade/lathe_half_mats
	name = "Armylathe Efficiency Upgrade"
	desc = "Halves the material cost of all armylathe assemblies"
	tech_unlock = ARMYLATHE_MATS_UPGRADE
	value = 20
	add_category = FALSE

/datum/ordnance_tech/lathe_upgrade/purchase(turf/location)
	if(isnull(item_path))
		return
	var/obj/item/ordnance/tech_disk/disk = new item_path(location)
	disk.name = "upgrade disk for [name]"
	disk.desc = "Insert this in an armylathe to upgrade it."
	disk.tech_type = item_type
	disk.tech += tech_unlock
	playsound(location, 'sound/machines/fax.ogg', 15, 1)

//dispenser upgrades

/datum/ordnance_tech/dispenser_upgrade
	name = "Dispenser Upgrades"
	item_type = ORDNANCE_UPGRADE_DISPENSER
	is_item = FALSE
	add_category = TRUE

/datum/ordnance_tech/dispenser_upgrade/purchase(turf/location)
	// Ensure tech_unlock is a list
	var/list/reagents_to_unlock = islist(tech_unlock) ? tech_unlock : list(tech_unlock)

	// Add to separate dispenser reagents list
	for(var/reagent in reagents_to_unlock)
		GLOB.ordnance_research.dispenser_reagents += reagent
		GLOB.ordnance_research.tech_bought += name // Add the upgrade name for duplicate checking

	// Update all ordnance dispensers with the new reagents
	for(var/obj/structure/machinery/chem_dispenser/ordnance/dispenser in GLOB.machines)
		if(!istype(dispenser))
			continue
		//dispenser.update_ordnance_reagents(reagents_to_unlock)

	playsound(location, 'sound/machines/twobeep.ogg', 15, 1)

// Example dispenser upgrades - add your own reagent IDs here
/datum/ordnance_tech/dispenser_upgrade/ammonia_synthesis
	name = "Ammonia Synthesis Upgrade"
	desc = "Unlocks access to advanced chemical compounds in the ordnance dispenser."
	tech_unlock = list("ammonia", "nitrogen")
	value = 10 //cheap as ammonia is cheap to make but not near efficient
	add_category = FALSE

/datum/ordnance_tech/dispenser_upgrade/polytrinic_synthesis
	name = "Polytrinic Synthesis Upgrade"
	desc = "Unlocks access to advanced chemical compounds in the ordnance dispenser."
	tech_unlock = list("chlorine", "potassium", "pacid")
	value = 10
	add_category = FALSE
/datum/ordnance_tech/dispenser_upgrade/methane_synthesis
	name = "Methane Synthesis Upgrade"
	desc = "Unlocks access to advanced chemical compounds in the ordnance dispenser."
	tech_unlock = list("methane")
	value = 25 //Direct synthesis of methane is fairly energy efficient
	add_category = FALSE
