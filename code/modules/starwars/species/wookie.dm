/datum/species/wookie
	//Wookies
	name = "Wookiee"
	id = "wookie"
	ignored_by = list(/mob/living/simple_animal/hostile/faithless)
	default_color = "FFFFFF"
	species_traits = list(EYECOLOR,LIPS,FACEHAIR,MUTCOLORS)
	default_features = list("mcolor" = "FFF", "wings" = "None")
	skinned_type = /obj/item/stack/sheet/animalhide/human
	disliked_food = GROSS | RAW
	liked_food = JUNKFOOD | FRIED
	changesource_flags = MIRROR_BADMIN | WABBAJACK | MIRROR_MAGIC | MIRROR_PRIDE | ERT_SPAWN | RACE_SWAP | SLIME_EXTRACT


/datum/species/wookie/qualifies_for_rank(rank, list/features)
	return TRUE	//Wookies are always allowed in all roles
