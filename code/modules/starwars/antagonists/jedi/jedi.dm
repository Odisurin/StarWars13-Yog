/datum/antagonist/jedi
	name = "Jedi"
	roundend_category = "Jedi"
	antagpanel_category = "Jedi"
	job_rank = ROLE_JEDI
	antag_moodlet = /datum/mood_event/focused
	var/give_objectives = TRUE
	var/strip = TRUE //strip before equipping
	var/allow_rename = TRUE
	var/hud_version = "jedi"
	var/datum/team/jedi/wiz_team //Only created if jedi summons apprentices
	var/move_to_lair = TRUE
	var/outfit_type = /datum/outfit/jedi
	var/wiz_age = JEDI_AGE_MIN /* Jedis by nature cannot be too young. */
	can_hijack = HIJACK_HIJACKER

/datum/antagonist/jedi/on_gain()
	register()
	equip_jedi()
	if(give_objectives)
		create_objectives()
	if(move_to_lair)
		send_to_lair()
	. = ..()
	if(allow_rename)
		rename_jedi()

/datum/antagonist/jedi/proc/register()
	SSticker.mode.jedis |= owner

/datum/antagonist/jedi/proc/unregister()
	SSticker.mode.jedis -= src

/datum/antagonist/jedi/create_team(datum/team/jedi/new_team)
	if(!new_team)
		return
	if(!istype(new_team))
		stack_trace("Wrong team type passed to [type] initialization.")
	wiz_team = new_team

/datum/antagonist/jedi/get_team()
	return wiz_team

/datum/team/jedi
	name = "jedi team"
	var/datum/antagonist/jedi/master_jedi

/datum/antagonist/jedi/proc/create_wiz_team()
	wiz_team = new(owner)
	wiz_team.name = "[owner.current.real_name] team"
	wiz_team.master_jedi = src
	update_wiz_icons_added(owner.current)

/datum/antagonist/jedi/proc/send_to_lair()
	if(!owner || !owner.current)
		return
	if(!GLOB.jedistart.len)
		SSjob.SendToLateJoin(owner.current)
		to_chat(owner, "HOT INSERTION, GO GO GO")
	owner.current.forceMove(pick(GLOB.jedistart))

/datum/antagonist/jedi/proc/create_objectives()
	switch(rand(1,100))
		if(1 to 30)
			var/datum/objective/assassinate/kill_objective = new
			kill_objective.owner = owner
			kill_objective.find_target()
			objectives += kill_objective

			if (!(locate(/datum/objective/escape) in objectives))
				var/datum/objective/escape/escape_objective = new
				escape_objective.owner = owner
				objectives += escape_objective

		if(31 to 60)
			var/datum/objective/steal/steal_objective = new
			steal_objective.owner = owner
			steal_objective.find_target()
			objectives += steal_objective

			if (!(locate(/datum/objective/escape) in objectives))
				var/datum/objective/escape/escape_objective = new
				escape_objective.owner = owner
				objectives += escape_objective

		if(61 to 85)
			var/datum/objective/assassinate/kill_objective = new
			kill_objective.owner = owner
			kill_objective.find_target()
			objectives += kill_objective

			var/datum/objective/steal/steal_objective = new
			steal_objective.owner = owner
			steal_objective.find_target()
			objectives += steal_objective

			if (!(locate(/datum/objective/survive) in objectives))
				var/datum/objective/survive/survive_objective = new
				survive_objective.owner = owner
				objectives += survive_objective

		else
			if (!(locate(/datum/objective/hijack) in objectives))
				var/datum/objective/hijack/hijack_objective = new
				hijack_objective.owner = owner
				objectives += hijack_objective

/datum/antagonist/jedi/on_removal()
	unregister()
	owner.RemoveAllSpells() // TODO keep track which spells are jedi spells which innate stuff
	return ..()

/datum/antagonist/jedi/proc/equip_jedi()
	if(!owner)
		return
	var/mob/living/carbon/human/H = owner.current
	if(!istype(H))
		return
	if(strip)
		H.delete_equipment()
	//Jedis are human by default. Use the mirror if you want something else.
	H.set_species(/datum/species/human)
	if(H.age < wiz_age)
		H.age = wiz_age
	H.equipOutfit(outfit_type)
	owner.AddSpell(new /obj/effect/proc_holder/spell/self/forceheal(null))
	owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/forcehealothers(null))
	owner.AddSpell(new /obj/effect/proc_holder/spell/self/forceprotect(null))
	owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/forcewall(null))

/datum/antagonist/jedi/greet()
	to_chat(owner, "<span class='boldannounce'>You are the Jedi!</span>")
	to_chat(owner, "<B>The Jedi has given you the following tasks:</B>")
	owner.announce_objectives()
	to_chat(owner, "You will find a list of available spells in your spell book. Choose your magic arsenal carefully.")
	to_chat(owner, "The spellbook is bound to you, and others cannot use it.")
	to_chat(owner, "In your pockets you will find a teleport scroll. Use it as needed.")
	to_chat(owner,"<B>Remember:</B> do not forget to prepare your spells.")

/datum/antagonist/jedi/farewell()
	to_chat(owner, "<span class='userdanger'>You have been brainwashed! You are no longer a jedi!</span>")

/datum/antagonist/jedi/proc/rename_jedi()
	set waitfor = FALSE

	var/jedi_name_first = pick(GLOB.jedi_first)
	var/jedi_name_second = pick(GLOB.jedi_second)
	var/randomname = "[jedi_name_first] [jedi_name_second]"
	var/mob/living/wiz_mob = owner.current
	var/newname = copytext(sanitize(input(wiz_mob, "You are the [name]. Would you like to change your name to something else?", "Name change", randomname) as null|text),1,MAX_NAME_LEN)

	if (!newname)
		newname = randomname

	wiz_mob.fully_replace_character_name(wiz_mob.real_name, newname)

/datum/antagonist/jedi/apply_innate_effects(mob/living/mob_override)
	var/mob/living/M = mob_override || owner.current
	update_wiz_icons_added(M, wiz_team ? TRUE : FALSE) //Don't bother showing the icon if you're solo jedi
	M.faction |= ROLE_JEDI

/datum/antagonist/jedi/remove_innate_effects(mob/living/mob_override)
	var/mob/living/M = mob_override || owner.current
	update_wiz_icons_removed(M)
	M.faction -= ROLE_JEDI


/datum/antagonist/jedi/get_admin_commands()
	. = ..()
	.["Send to Lair"] = CALLBACK(src,.proc/admin_send_to_lair)

/datum/antagonist/jedi/proc/admin_send_to_lair(mob/admin)
	owner.current.forceMove(pick(GLOB.jedistart))

/datum/antagonist/jedi/apprentice
	name = "Jedi Apprentice"
	hud_version = "apprentice"
	var/datum/mind/master
	var/school = APPRENTICE_DESTRUCTION
	outfit_type = /datum/outfit/jedi/apprentice
	wiz_age = APPRENTICE_AGE_MIN

/datum/antagonist/jedi/apprentice/greet()
	to_chat(owner, "<B>You are [master.current.real_name]'s apprentice! You are bound by the force to follow [master.p_their()] orders and help [master.p_them()] in accomplishing [master.p_their()] goals.")
	owner.announce_objectives()

/datum/antagonist/jedi/apprentice/register()
	SSticker.mode.apprentices |= owner

/datum/antagonist/jedi/apprentice/unregister()
	SSticker.mode.apprentices -= owner

/datum/antagonist/jedi/apprentice/equip_jedi()
	. = ..()
	if(!owner)
		return
	var/mob/living/carbon/human/H = owner.current
	if(!istype(H))
		return
	switch(school)
		if(APPRENTICE_DESTRUCTION)
			owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/projectile/magic_missile(null))
			owner.AddSpell(new /obj/effect/proc_holder/spell/aimed/fireball(null))
			to_chat(owner, "<B>Your service has not gone unrewarded, however. Studying under [master.current.real_name], you have learned powerful, destructive spells. You are able to cast magic missile and fireball.")
		if(APPRENTICE_BLUESPACE)
			owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/area_teleport/teleport(null))
			owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/ethereal_jaunt(null))
			to_chat(owner, "<B>Your service has not gone unrewarded, however. Studying under [master.current.real_name], you have learned reality bending mobility spells. You are able to cast teleport and ethereal jaunt.")
		if(APPRENTICE_HEALING)
			owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/charge(null))
			owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/forcewall(null))
			H.put_in_hands(new /obj/item/gun/magic/staff/healing(H))
			to_chat(owner, "<B>Your service has not gone unrewarded, however. Studying under [master.current.real_name], you have learned livesaving survival spells. You are able to cast charge and forcewall.")
		if(APPRENTICE_ROBELESS)
			owner.AddSpell(new /obj/effect/proc_holder/spell/aoe_turf/knock(null))
			owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/mind_transfer(null))
			to_chat(owner, "<B>Your service has not gone unrewarded, however. Studying under [master.current.real_name], you have learned stealthy, robeless spells. You are able to cast knock and mindswap.")

/datum/antagonist/jedi/apprentice/create_objectives()
	var/datum/objective/protect/new_objective = new /datum/objective/protect
	new_objective.owner = owner
	new_objective.target = master
	new_objective.explanation_text = "Protect [master.current.real_name], the jedi."
	objectives += new_objective

//Random event jedi
/datum/antagonist/jedi/apprentice/imposter
	name = "Jedi Imposter"
	allow_rename = FALSE
	move_to_lair = FALSE

/datum/antagonist/jedi/apprentice/imposter/greet()
	to_chat(owner, "<B>You are an imposter! Trick and confuse the crew to misdirect malice from your handsome original!</B>")
	owner.announce_objectives()

/datum/antagonist/jedi/apprentice/imposter/equip_jedi()
	var/mob/living/carbon/human/master_mob = master.current
	var/mob/living/carbon/human/H = owner.current
	if(!istype(master_mob) || !istype(H))
		return
	if(master_mob.ears)
		H.equip_to_slot_or_del(new master_mob.ears.type, SLOT_EARS)
	if(master_mob.w_uniform)
		H.equip_to_slot_or_del(new master_mob.w_uniform.type, SLOT_W_UNIFORM)
	if(master_mob.shoes)
		H.equip_to_slot_or_del(new master_mob.shoes.type, SLOT_SHOES)
	if(master_mob.wear_suit)
		H.equip_to_slot_or_del(new master_mob.wear_suit.type, SLOT_WEAR_SUIT)
	if(master_mob.head)
		H.equip_to_slot_or_del(new master_mob.head.type, SLOT_HEAD)
	if(master_mob.back)
		H.equip_to_slot_or_del(new master_mob.back.type, SLOT_BACK)

	//Operation: Fuck off and scare people
	owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/area_teleport/teleport(null))
	owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/turf_teleport/blink(null))
	owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/ethereal_jaunt(null))

/datum/antagonist/jedi/proc/update_wiz_icons_added(mob/living/wiz,join = TRUE)
	var/datum/atom_hud/antag/wizhud = GLOB.huds[ANTAG_HUD_WIZ]
	wizhud.join_hud(wiz)
	set_antag_hud(wiz, hud_version)

/datum/antagonist/jedi/proc/update_wiz_icons_removed(mob/living/wiz)
	var/datum/atom_hud/antag/wizhud = GLOB.huds[ANTAG_HUD_WIZ]
	wizhud.leave_hud(wiz)
	set_antag_hud(wiz, null)


/datum/antagonist/jedi/academy
	name = "Academy Teacher"
	outfit_type = /datum/outfit/jedi/academy

/datum/antagonist/jedi/academy/equip_jedi()
	. = ..()

	owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/ethereal_jaunt)
	owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/projectile/magic_missile)
	owner.AddSpell(new /obj/effect/proc_holder/spell/aimed/fireball)

	var/mob/living/M = owner.current
	if(!istype(M))
		return

	var/obj/item/implant/exile/Implant = new/obj/item/implant/exile(M)
	Implant.implant(M)

/datum/antagonist/jedi/academy/create_objectives()
	var/datum/objective/new_objective = new("Protect Jedi Academy from the intruders")
	new_objective.owner = owner
	objectives += new_objective

//Solo jedi report
/datum/antagonist/jedi/roundend_report()
	var/list/parts = list()

	parts += printplayer(owner)

	var/count = 1
	var/jediwin = 1
	for(var/datum/objective/objective in objectives)
		if(objective.check_completion())
			parts += "<B>Objective #[count]</B>: [objective.explanation_text] <span class='greentext'>Success!</span>"
		else
			parts += "<B>Objective #[count]</B>: [objective.explanation_text] <span class='redtext'>Fail.</span>"
			jediwin = 0
		count++

	if(jediwin)
		parts += "<span class='greentext'>The jedi was successful!</span>"
	else
		parts += "<span class='redtext'>The jedi has failed!</span>"

	if(owner.spell_list.len>0)
		parts += "<B>[owner.name] used the following spells: </B>"
		var/list/spell_names = list()
		for(var/obj/effect/proc_holder/spell/S in owner.spell_list)
			spell_names += S.name
		parts += spell_names.Join(", ")

	return parts.Join("<br>")

//Jedi with apprentices report
/datum/team/jedi/roundend_report()
	var/list/parts = list()

	parts += "<span class='header'>Jedis/witches of [master_jedi.owner.name] team were:</span>"
	parts += master_jedi.roundend_report()
	parts += " "
	parts += "<span class='header'>[master_jedi.owner.name] apprentices were:</span>"
	parts += printplayerlist(members - master_jedi.owner)

	return "<div class='panel redborder'>[parts.Join("<br>")]</div>"


