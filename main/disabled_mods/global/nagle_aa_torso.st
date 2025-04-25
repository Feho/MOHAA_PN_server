// ***FEHO***
// Updates: added grenade launcher to rifles 26/08/2011 (search "grenade launcher")
// added squadmaker (search "jv_map")
// added BAR cadence mod (search "cadence BAR")
// added medicmod (feho/spawn.scr, check_weapons)
// added global/feho/dropitems.scr (state KILLED)


	// ======================================================= //
	// Action state machine for Mike Powell, the hero of MoH PC //
	// ======================================================= //

// Authored by Carl glave and Michael Boon, 5-23-2000

// The action state machine takes care of
// a) all torso-only animations which are layer on top of leg animations
// b) most full-body animations
// c) which states are to take their full-body animations from the leg state
//    machine.
// The states which control only torso animations have "movetype legs" and 
// animations under the token "action".  This allows the leg state to continue
// controlling the leg animations.  The states which control the whole body have
// movetype not legs and animations under the token "action". This overrides the
// leg state machine. States such as STAND, below, which have "none" specified
// as the torso animation, take the torso animation from the leg animaiton
// specified in the legs state machine.

//------------------------------------------------------------------
// jv_map's notes:
//------------------------------------------------------------------
// Mike torso extended to use support guns and report weapon raise 
// events to squadmaker. Includes fixes for landsharking, 'grenade' 
// crash exploit and teamswitch-on-ladder bug. Currently does not 
// fix bugs associated with static turret guns. I recommend just 
// removing these guns (removeclass TurretGun in map script) 
// because in most cases they cannot be used effectively by players 
// unless they are exploiting the various bugs.
//------------------------------------------------------------------
// If you wish to combine this statefile with another, copy all 
// sections labelled 'jv_map'.
//------------------------------------------------------------------

//==============================================================================
//==============================================================================
//
// Stand (really means not doing an action)
//
//==============================================================================

state STAND
{
	movetype legs

	camera behind

	entrycommands
	{		
		viewmodelanim idle
		exec global/states/player_spawn.scr
	}
	
	action
	{
		none : default // no torso animation
	}

	states
	{
		KILLED					: KILLED
		PAIN					: PAIN

		VEHICLE_START			: IS_USING_VEHICLE
		TURRET_START			: IS_USING_TURRET 

		// if we're on a ladder, make sure we're climbing the ladder
		LADDER_IDLE_LEFT		: ON_LADDER

		// Some grab and hang stuff will be implemented in the final game, probably 
		// not all of this, but it's in here as a placeholder.
//		CLIMB_LADDER			: ONGROUND +FORWARD !BACKWARD AT_LADDER

//		CLIMB_LADDER_IMPACT		: !ONGROUND FORWARD !BACKWARD AT_LADDER	// For grabbing onto walls when
													// flying through the air
	
		// Using objects is dictated by the object being used.  The three objects 
		// here are for objects which trigger interactive actions when touched, 
		// for objects which the player uses (such as doors), and for when the 
		// player tries to use an object that is not usable.
//		USE_USEANIM				: ONGROUND TOUCHEDUSEANIM
//		USE_USEANIM				: ONGROUND USE AT_USEANIM
		USE_LADDER				: ONGROUND +USE AT_LADDER CHECK_HEIGHT "stand"
//		USE_LADDER				: ONGROUND AT_LADDER // this is full auto use of ladders
		// latch onto ladder in mid-air
		USE_LADDER				: +USE AT_LADDER CHECK_HEIGHT "stand" // can also latch onto a ladder in mid-air
		// auto use of ladder when at the bottom (AT_LADDER check is last because it does a trace)
		USE_LADDER				: ONGROUND FORWARD LOOKING_UP "35" !PUTAWAYMAIN !NEW_WEAPON !RELOAD !ATTACK_PRIMARY !ATTACK_SECONDARY AT_LADDER CHECK_HEIGHT "stand"
		// auto use of ladder when at the top (AT_LADDER check is last because it does a trace)
		USE_LADDER				: ONGROUND FORWARD !LOOKING_UP "-35" !PUTAWAYMAIN !NEW_WEAPON !RELOAD !ATTACK_PRIMARY !ATTACK_SECONDARY AT_LADDER CHECK_HEIGHT "stand"
//		GENERIC_USE				: ONGROUND +USE
	
		// This is not functional for the prototype, but is here as a placeholder for
		// future functionality.
		// While the player can only fire weapons with his right hand, he can switch them 
		// to his left if he wants to use an item with his left.  Gameplay-wise, this should 
		// be the same as putting the weapon away, but it will create a nice graphical "cool 
		// factor" which is always good in computer games.
		// When we have two items out, the game code will flag them both as putaway, and we 
		// need to put the right one away first, followed by the left.
		PUTAWAY_MAIN			: PUTAWAYMAIN	// Basic put weapon away move.
		RAISE_WEAPON			: NEW_WEAPON

		RELOAD_WEAPON			: RELOAD

		// jv_map
		// semi auto mg must be a support gun
		//----------------->
		ATTACK_SUPPORT					: ATTACK_PRIMARY_BUTTON IS_WEAPONCLASS_ACTIVE "mainhand" "mg" IS_WEAPON_SEMIAUTO "mainhand"
		//<-----------------
		
		GENERIC_USE_PROPER				: +USE !IS_USING_TURRET
	
		CHECK_PRIMARY_ATTACK_SEMIAUTO	: +ATTACK_PRIMARY IS_WEAPON_SEMIAUTO "mainhand" IS_WEAPON_READY_TO_FIRE "mainhand"
		CHECK_PRIMARY_ATTACK_FULLAUTO	: ATTACK_PRIMARY !IS_WEAPON_SEMIAUTO "mainhand" IS_WEAPON_READY_TO_FIRE "mainhand"
		CHECK_SECONDARY_ATTACK			: +ATTACK_SECONDARY
		
		//feho
		//revive mod
		//----------->
		GENERIC_USE_PROPER				: +USE !IS_USING_TURRET
		//<-----------
		
		// jv_map
		// quick unholster
		//----------------->
		QUICK_UNHOLSTER		: !HAS_WEAPON +ATTACK_PRIMARY_BUTTON
		//<-----------------
		
		//feho
		//check_weapons
		//----------->
		DROPPED_WEAPONS			: -HAS_WEAPON
		//<-----------
		
		//feho
		//voices ----------->
		//PLAYER_VOICES					: +BACKWARD
		//<-----------------
		
	}
}

// Custom state by feho
//------------->
// state PLAYER_VOICES
// {
	// movetype legs

	// entrycommands
	// {
		// exec global/feho/voices2.scr "1"
	// }

	// states
	// {
		// STAND : default
	// }
// }


state DROPPED_WEAPONS
{
	movetype legs

	entrycommands
	{
		// exec global/AA/check_weapons.scr "0"
	}

	states
	{
		STAND : default
	}
}
// End of custom state by feho

// Custom states by jv_map
//----------------->
state QUICK_UNHOLSTER
{
	entrycommands
	{
		useweaponclass grenade
		useweaponclass pistol
		useweaponclass rifle
		useweaponclass smg
		useweaponclass mg
		useweaponclass heavy
	}
	
	states
	{
		STAND : default
	}
}

state ATTACK_SUPPORT
{
	movetype legs
	
	entrycommands
	{
		exec global/support/shell.scr fire_support_weapon
	}
	
	states
	{
		STAND : KILLED
		
		// script should force me outta this when needed
	}
}

// called by script only
state ATTACK_SUPPORT_FIRE
{
	movetype legs
	
	action
	{
		mg_stand_fire : default
	}
	
	states
	{
		STAND : KILLED
		
		// script should force me outta this when needed
	}
}
//<-----------------
// End of custom states by jv_map

//==============================================================================
//==============================================================================
//
// Primary Attacks - Full Auto
//
//==============================================================================

state CHECK_PRIMARY_ATTACK_FULLAUTO
{
	movetype legs

	action
	{
		none : default // stop torso animation
	}

	states
	{
		STAND					: KILLED
//		PAIN					: PAIN
	
		STAND					: NEW_WEAPON
		STAND					: RELOAD
		STAND					: !IS_WEAPON_READY_TO_FIRE "mainhand"
		
//		ATTACK_PISTOL_PRIMARY	: IS_WEAPONCLASS_READY_TO_FIRE "mainhand" "pistol"
//		ATTACK_RIFLE_PRIMARY	: IS_WEAPONCLASS_READY_TO_FIRE "mainhand" "rifle"
//		CHARGE_ATTACK_GRENADE	: IS_WEAPONCLASS_READY_TO_FIRE "mainhand" "grenade"
		ATTACK_SMG_PRIMARY		: IS_WEAPONCLASS_READY_TO_FIRE "mainhand" "smg"
		ATTACK_MG_PRIMARY		: IS_WEAPONCLASS_READY_TO_FIRE "mainhand" "mg"
//		ATTACK_ITEM_PRIMARY		: IS_WEAPONCLASS_READY_TO_FIRE "mainhand" "item"
		
//		STAND					: IS_WEAPON_ACTIVE "Error"  // Generates an error if no appropriate
															// attack state is chosen
		STAND					: !ATTACK_PRIMARY
	}
}

state ATTACK_SMG_PRIMARY
{
	movetype legs

	entrycommands
	{
		viewmodelanim fire 1
		// Feho
		// Tracer bullets ------------>
		// exec global/feho/tracerbullet.scr
		//<----------------------------
	}

	action
	{
		mp40_stand_run_fire		: IS_WEAPON_ACTIVE "mainhand" "MP40" POSITION_TYPE "standing" MOVEMENT_TYPE "running"
		mp40_crouch_run_fire	: IS_WEAPON_ACTIVE "mainhand" "MP40" POSITION_TYPE "crouching" MOVEMENT_TYPE "running"
		mp40_crouch_fire		: IS_WEAPON_ACTIVE "mainhand" "MP40" POSITION_TYPE "crouching"
		mp40_stand_fire			: IS_WEAPON_ACTIVE "mainhand" "MP40"

		smg_stand_run_fire		: POSITION_TYPE "standing" MOVEMENT_TYPE "running"
		smg_crouch_run_fire		: POSITION_TYPE "crouching" MOVEMENT_TYPE "running"
		smg_crouch_fire			: POSITION_TYPE "crouching"
		smg_stand_fire			: default
	}

	states
	{
		STAND							: KILLED
//		PAIN							: PAIN

		STAND							: !ATTACK_PRIMARY ANIMDONE_TORSO 
		STAND							: ANIMDONE_TORSO !IS_WEAPON_READY_TO_FIRE "mainhand"
//		STAND							: RELOAD !ATTACK_PRIMARY IS_WEAPON_READY_TO_FIRE "mainhand"
		STAND							: RELOAD !ATTACK_PRIMARY
//		STAND							: RELOAD !HAS_AMMO_IN_CLIP "mainhand" IS_WEAPON_READY_TO_FIRE "mainhand"
		
		CHECK_PRIMARY_ATTACK_FULLAUTO	: ATTACK_PRIMARY +IS_WEAPON_READY_TO_FIRE "mainhand"
		CHECK_PRIMARY_ATTACK_FULLAUTO	: +ATTACK_PRIMARY IS_WEAPON_READY_TO_FIRE "mainhand"
	}
}

state ATTACK_MG_PRIMARY
{
	movetype legs

	entrycommands
	{
		viewmodelanim fire 1
		// Feho
		// Tracer bullets ------------>
		// exec global/feho/tracerbullet.scr
		//<----------------------------
		
		//semiauto MP44 ---->
		exec global/feho/semiauto.scr "1"
		//<------------------
	}

	action
	{
		mp44_stand_run_fire		: IS_WEAPON_ACTIVE "mainhand" "StG 44" POSITION_TYPE "standing" MOVEMENT_TYPE "running"
		mp44_crouch_run_fire	: IS_WEAPON_ACTIVE "mainhand" "StG 44" POSITION_TYPE "crouching" MOVEMENT_TYPE "running"
		mp44_crouch_fire		: IS_WEAPON_ACTIVE "mainhand" "StG 44" POSITION_TYPE "crouching"
		mp44_stand_fire			: IS_WEAPON_ACTIVE "mainhand" "StG 44"

		mg_stand_run_fire		: POSITION_TYPE "standing" MOVEMENT_TYPE "running"
		mg_crouch_run_fire		: POSITION_TYPE "crouching" MOVEMENT_TYPE "running"
		mg_crouch_fire			: POSITION_TYPE "crouching"
		mg_stand_fire			: default
	}

	states
	{
		STAND							: KILLED
//		PAIN							: PAIN

//		STAND							: !ATTACK_PRIMARY ANIMDONE_TORSO 
//		STAND							: RELOAD !ATTACK_PRIMARY IS_WEAPON_READY_TO_FIRE "mainhand"
	
		STAND							: !ATTACK_PRIMARY ANIMDONE_TORSO 
		STAND							: ANIMDONE_TORSO !IS_WEAPON_READY_TO_FIRE "mainhand"
//		STAND							: RELOAD !ATTACK_PRIMARY IS_WEAPON_READY_TO_FIRE "mainhand"
		STAND							: RELOAD !ATTACK_PRIMARY
//		STAND							: RELOAD !HAS_AMMO_IN_CLIP "mainhand" IS_WEAPON_READY_TO_FIRE "mainhand"
		
		CHECK_PRIMARY_ATTACK_FULLAUTO	: ATTACK_PRIMARY +IS_WEAPON_READY_TO_FIRE "mainhand"
		CHECK_PRIMARY_ATTACK_FULLAUTO	: +ATTACK_PRIMARY IS_WEAPON_READY_TO_FIRE "mainhand"
	}
}

//==============================================================================
//==============================================================================
//
// Primary Attacks - Semi-Auto
//
//==============================================================================

state CHECK_PRIMARY_ATTACK_SEMIAUTO
{
	movetype legs

	action
	{
		none : default // stop torso animation
	}

	states
	{
		STAND					: KILLED
//		PAIN					: PAIN
	
		STAND					: NEW_WEAPON
		STAND					: RELOAD
		STAND					: !IS_WEAPON_READY_TO_FIRE "mainhand"
		
		ATTACK_PISTOL_PRIMARY	: IS_WEAPONCLASS_READY_TO_FIRE "mainhand" "pistol"
		ATTACK_RIFLE_PRIMARY	: IS_WEAPONCLASS_READY_TO_FIRE "mainhand" "rifle"
		CHARGE_ATTACK_GRENADE	: IS_WEAPONCLASS_READY_TO_FIRE "mainhand" "grenade"
		ATTACK_ITEM_PRIMARY		: IS_WEAPONCLASS_READY_TO_FIRE "mainhand" "item"
		ATTACK_BAZOOKA_PRIMARY	: IS_WEAPON_ACTIVE "mainhand" "Bazooka"
		ATTACK_BAZOOKA_PRIMARY	: IS_WEAPON_ACTIVE "mainhand" "Panzerschreck"
		ATTACK_SHOTGUN_PRIMARY	: IS_WEAPON_ACTIVE "mainhand" "Shotgun"
	
//		STAND					: IS_WEAPON_ACTIVE "Error" // Generates an error if no appropriate
											// attack state is chosen
		STAND					: !ATTACK_PRIMARY
	}
}

state ATTACK_RIFLE_PRIMARY
{
	movetype legs

	entrycommands
	{
		//feho
		//nade launcher
		//----->
		exec global/naderemove.scr
		//<-----
		
		// Feho
		// Tracer bullets ------------>
		// exec global/feho/tracerbullet.scr
		//<----------------------------
		viewmodelanim fire 1
	}

	action
	{
		// Fire from the hip when jogging,
		// from the shoulder when walking or standing
		rifle_stand_run_fire	: POSITION_TYPE "standing" MOVEMENT_TYPE "running"
		rifle_crouch_run_fire	: POSITION_TYPE "crouching" MOVEMENT_TYPE "running"
		rifle_stand_walk_fire	: POSITION_TYPE "standing" MOVEMENT_TYPE "walking"
		rifle_crouch_fire		: POSITION_TYPE "crouching"
		rifle_stand_fire		: default
	}

	states
	{
		STAND							: KILLED
//		PAIN							: PAIN

//		STAND							: !ATTACK_PRIMARY ANIMDONE_TORSO 
		ATTACK_SPRINGFIELD_RECHAMBER	: ANIMDONE_TORSO IS_WEAPON_ACTIVE "mainhand" "Springfield '03 Sniper"
		ATTACK_KAR98_RECHAMBER			: ANIMDONE_TORSO IS_WEAPON_ACTIVE "mainhand" "Mauser KAR 98K"
		ATTACK_KAR98_RECHAMBER			: ANIMDONE_TORSO IS_WEAPON_ACTIVE "mainhand" "KAR98 - Sniper"		
		STAND							: ANIMDONE_TORSO 
		CHECK_PRIMARY_ATTACK_SEMIAUTO	: +ATTACK_PRIMARY IS_WEAPON_READY_TO_FIRE "mainhand"
	}
}

state ATTACK_SPRINGFIELD_RECHAMBER
{
	movetype legs
	
	entrycommands
	{
		viewmodelanim rechamber
//		safezoom 0
	}
	
//	exitcommands
//	{
//		safezoom 1
//	}
	
	action
	{
		springfield_crouch_rechamber	: POSITION_TYPE "crouching"
		springfield_stand_rechamber		: default
	}
	
	states
	{
		STAND							: KILLED
//		PAIN							: PAIN
	
		STAND							: ANIMDONE_TORSO 
	}
}

state ATTACK_KAR98_RECHAMBER
{
	movetype legs
	
	entrycommands
	{
		viewmodelanim rechamber
//		safezoom 0
	}
	
//	exitcommands
//	{
//		safezoom 1
//	}
	
	action
	{
		kar98_crouch_rechamber	: POSITION_TYPE "crouching"
		kar98_stand_rechamber	: default
	}
	
	states
	{
		STAND						: KILLED
//		PAIN						: PAIN
	
		STAND						: ANIMDONE_TORSO 
	}
}

state ATTACK_PISTOL_PRIMARY
{
	movetype legs

	entrycommands
	{
		viewmodelanim fire 1
	}

	action
	{
		// Fire from the hip when jogging, from the shoulder when
		// walking, or standing

		pistol_silenced_stand_run_fire	: POSITION_TYPE "standing" MOVEMENT_TYPE "running" IS_WEAPON_ACTIVE "mainhand" "Hi-Standard Silenced"
		pistol_silenced_crouch_run_fire	: POSITION_TYPE "crouching" MOVEMENT_TYPE "running" IS_WEAPON_ACTIVE "mainhand" "Hi-Standard Silenced"
		pistol_silenced_crouch_fire		: POSITION_TYPE "crouching" IS_WEAPON_ACTIVE "mainhand" "Hi-Standard Silenced"
		pistol_silenced_stand_fire		: IS_WEAPON_ACTIVE "mainhand" "Hi-Standard Silenced"

		pistol_stand_run_fire	: POSITION_TYPE "standing" MOVEMENT_TYPE "running"
		pistol_crouch_run_fire	: POSITION_TYPE "crouching" MOVEMENT_TYPE "running"
		pistol_crouch_fire		: POSITION_TYPE "crouching"
		pistol_stand_fire		: default
	}

	states
	{
		STAND							: KILLED
//		PAIN							: PAIN

//		STAND							: !ATTACK_PRIMARY ANIMDONE_TORSO 
		STAND							: ANIMDONE_TORSO 
		CHECK_PRIMARY_ATTACK_SEMIAUTO	: +ATTACK_PRIMARY IS_WEAPON_READY_TO_FIRE "mainhand"

		// allow pistol whip immediatly after firing
		ATTACK_PISTOL_SECONDARY			: +ATTACK_SECONDARY IS_WEAPON_READY_TO_FIRE "mainhand"
	}
}

state ATTACK_ITEM_PRIMARY
{
	movetype legs

	entrycommands
	{
		weaponcommand mainhand anim fire
		exec global/fire_for_effect/binoculars_fire.scr
	}
	
	states
	{
		STAND							: KILLED
//		PAIN							: PAIN

		STAND							: !ATTACK_PRIMARY
		CHECK_PRIMARY_ATTACK_SEMIAUTO	: +ATTACK_PRIMARY IS_WEAPON_READY_TO_FIRE "mainhand"
	}
}

state ATTACK_BAZOOKA_PRIMARY
{
	movetype legs
	
	entrycommands
	{
		viewmodelanim fire 1
	}
	
	action
	{
		bazooka_stand_run_fire	: POSITION_TYPE "standing" MOVEMENT_TYPE "running"
		bazooka_crouch_run_fire	: POSITION_TYPE "crouching" MOVEMENT_TYPE "running"
		bazooka_crouch_fire		: POSITION_TYPE "crouching"
		bazooka_stand_fire		: default
	}
	
	states
	{
		STAND							: KILLED
//		PAIN							: PAIN

		//STAND							: !ATTACK_PRIMARY ANIMDONE_TORSO // jv_map
		
		// jv_map
		// comment-out or remove this one
		//----------------->
		//STAND							: !ATTACK_PRIMARY ANIMDONE_TORSO
		// then replace by
		STAND							: ANIMDONE_TORSO
		//<-----------------
		
		CHECK_PRIMARY_ATTACK_SEMIAUTO	: +ATTACK_PRIMARY IS_WEAPON_READY_TO_FIRE "mainhand"
	}
}

state ATTACK_SHOTGUN_PRIMARY
{
	movetype legs
	
	entrycommands
	{
		viewmodelanim fire 1
	}
	
	action
	{
		shotgun_stand_run_fire	: POSITION_TYPE "standing" MOVEMENT_TYPE "running"
		shotgun_crouch_run_fire	: POSITION_TYPE "crouching" MOVEMENT_TYPE "running"
		shotgun_crouch_fire		: POSITION_TYPE "crouching"
		shotgun_stand_fire		: default
	}
	
	states
	{
		STAND							: KILLED
//		PAIN							: PAIN

		//STAND							: !ATTACK_PRIMARY ANIMDONE_TORSO //jv_map
		
		// jv_map
		// comment-out or remove this one
		//----------------->
		//STAND							: !ATTACK_PRIMARY ANIMDONE_TORSO
		// then replace by
		STAND							: ANIMDONE_TORSO
		//<-----------------
		
		CHECK_PRIMARY_ATTACK_SEMIAUTO	: +ATTACK_PRIMARY IS_WEAPON_READY_TO_FIRE "mainhand"
	}
}

//==============================================================================
//==============================================================================
//
// Secondary Attacks (Always Semi-Auto fire)
//
//==============================================================================
state CHECK_SECONDARY_ATTACK
{
	movetype legs

	action
	{
		none : default // no torso animation
	}

	states
	{
		STAND					: KILLED
//		PAIN					: PAIN
	
		STAND					: RELOAD
		
		// jv_map
		// quick holstering of support weapon
		//----------------->
		HOLSTER_SUPPORT_WEAPON	: IS_WEAPONCLASS_ACTIVE "mainhand" "mg" IS_WEAPON_SEMIAUTO "mainhand"
		//<-----------------
		
		ATTACK_PISTOL_SECONDARY	: IS_WEAPONCLASS_READY_TO_FIRE "mainhand" "pistol" "secondary"
		
		//feho
		//grenade launcher rifle
		//------------->
		ATTACK_RIFLE_SECONDARY	: IS_WEAPONCLASS_READY_TO_FIRE "mainhand" "rifle" "secondary"
		//<-------------
		
		//feho
		// cadence BAR + SMG/STG44 bash
		//-------------->
		ATTACK_BAR_SECONDARY		: IS_WEAPON_ACTIVE "mainhand" "BAR" "secondary"
		ATTACK_MP44_SECONDARY		: IS_WEAPON_ACTIVE "mainhand" "StG 44" "secondary"
		ATTACK_MP40_SECONDARY		: IS_WEAPON_ACTIVE "mainhand" "MP40" "secondary"
		ATTACK_THOMPSON_SECONDARY		: IS_WEAPON_ACTIVE "mainhand" "Thompson" "secondary"
		ATTACK_SHOTGUN_SECONDARY		: IS_WEAPON_ACTIVE "mainhand" "Shotgun" "secondary"
		//<-------------
		
//		ATTACK_RIFLE_2NDARY		: IS_WEAPON_ACTIVE "mainhand" "M1_Garand"
//		ATTACK_GRENADE_2NDARY	: IS_WEAPON_ACTIVE "mainhand" "FragGrenade"
//		ATTACK_RIFLE_2NDARY		: IS_WEAPON_ACTIVE "mainhand" "MP40"

//		ATTACK_RIFLE_2NDARY		: IS_WEAPONCLASS_READY_TO_FIRE "mainhand" "rifle" "secondary"

		CHARGE_ATTACK_GRENADE_SECONDARY	: IS_WEAPONCLASS_READY_TO_FIRE "mainhand" "grenade" "secondary"

		PUT_AWAY_ITEM			: IS_WEAPON_ACTIVE "mainhand" "Spy Camera"
		PUT_AWAY_ITEM			: IS_WEAPON_ACTIVE "mainhand" "Binoculars"
	
//		STAND					: IS_WEAPON_ACTIVE "Error"
//		STAND					: !ATTACK_PRIMARY

		// Has to be last checked... or else it will prevent pistol whips and grenade cooks etc
		HOLD_SNIPER				: IS_WEAPON_ACTIVE "mainhand" "Springfield '03 Sniper"
		HOLD_SNIPER				: IS_WEAPON_ACTIVE "mainhand" "KAR98 - Sniper" 
		HOLD_RMB 				: default //+ATTACK_SECONDARY
		//STAND					: default
		
		//Feho
		//All weapons bash
		//---------->
		//BASH_ATTACK					: default
		//<---------
	}
}

// quickly holsters the support gun
// custom state by jv_map
//----------------->
state HOLSTER_SUPPORT_WEAPON
{
	entrycommands
	{
		deactivateweapon mainhand
	}
	
	states
	{
		STAND : default
	}
}
//<-----------------

// Pistol whip for silent kills
// Pistol whip for silent kills
state ATTACK_PISTOL_SECONDARY
{
	movetype legs

	entrycommands
	{
		viewmodelanim fire_secondary 1
		exec global/states/player_info.scr "rmb_on"
	}
	exitcommands
	{
		exec global/states/player_info.scr "rmb_off"
	}

	action
	{
		pistol_butt	: default
	}
	
	states
	{
		STAND	 	: KILLED
		
		STAND	 	: ANIMDONE_TORSO
	}
}

//feho
//grenade launcher rifle
//----------------------->
state ATTACK_RIFLE_SECONDARY
{
	movetype legs

	entrycommands
	{
		exec global/nadeattach.scr
	}

	action
	{

	}
	
	states
	{
		STAND	 	: KILLED
		
		STAND	 	: ANIMDONE_TORSO
	}
}
//<-------------------

//feho
// cadence BAR + SMG bash + spawn bots
//---------------------->
state ATTACK_BAR_SECONDARY
{
	movetype legs

	entrycommands
	{
		exec global/feho/cadenceBAR.scr
	}

	action
	{

	}
	
	states
	{
		STAND	 	: KILLED
		
		STAND	 	: ANIMDONE_TORSO
	}
}

state ATTACK_MP40_SECONDARY
{
	movetype legs

	entrycommands
	{
		weaponcommand mainhand name "Colt 45"
		viewmodelanim fire_secondary 1
		commanddelay 0.25 weaponcommand mainhand shoot secondary
		weaponcommand mainhand name "MP40"
		exec global/weapbash.scr
	}
	action
	{
		pistol_butt	: default
	}
	
	states
	{
		STAND	 	: KILLED
		
		STAND	 	: ANIMDONE_TORSO
	}
}

state ATTACK_MP44_SECONDARY
{
	movetype legs

	entrycommands
	{
		// weaponcommand mainhand name "Colt 45"
		// viewmodelanim fire_secondary 1
		// commanddelay 0.25 weaponcommand mainhand shoot secondary
		// weaponcommand mainhand name "StG 44"
		// exec global/weapbash.scr
		
		//Feho - MP44 semi-auto ---->
		// exec global/feho/semiauto.scr
		//<--------------------------
	}
	action
	{
		// pistol_butt	: default
	}
	
	states
	{
		STAND	 	: KILLED
		
		STAND	 	: ANIMDONE_TORSO
	}
}

state ATTACK_THOMPSON_SECONDARY
{
	movetype legs

	entrycommands
	{
		weaponcommand mainhand name "Colt 45"
		viewmodelanim fire_secondary 1
		commanddelay 0.25 weaponcommand mainhand shoot secondary
		weaponcommand mainhand name "Thompson"
		exec global/weapbash.scr
	}
	action
	{
		pistol_butt	: default
	}
	
	states
	{
		STAND	 	: KILLED
		
		STAND	 	: ANIMDONE_TORSO
	}
}

state ATTACK_SHOTGUN_SECONDARY
{
	movetype legs

	entrycommands
	{
		// exec global/bot_spawn.scr
	}

	action
	{

	}
	
	states
	{
		STAND	 	: KILLED
		
		STAND	 	: ANIMDONE_TORSO
	}
}
//<----------------------

// put away the item and pull out the last active weapon
state PUT_AWAY_ITEM
{
	entrycommands
	{
//		deactivateweapon righthand

		//Feho FFE ----------->
		exec global/fire_for_effect/binoculars_fire2.scr
		//<--------------------
		
		commanddelay 0.05 uselast
	}

	states
	{
		STAND		: default
	}
	
//	exitcommands
//	{
//		uselast
//	}
}


//==============================================================================
//==============================================================================
//
// Primary Charge Up Attacks (grenades)
//
//==============================================================================

state CHARGE_ATTACK_GRENADE
{
	movetype legs

	entrycommands
	{
		viewmodelanim charge
		exec global/feho/grenade_alert.scr
	}
	
	action
	{
		steilhandgranate_crouch_charge	: IS_WEAPON_ACTIVE "mainhand" "Stielhandgranate" POSITION_TYPE "crouching"
		steilhandgranate_stand_charge	: IS_WEAPON_ACTIVE "mainhand" "Stielhandgranate"
	
		grenade_crouch_charge			: POSITION_TYPE "crouching"
		grenade_stand_charge			: default
	}

	states
	{
		STAND 				: !HAS_WEAPON
		STAND 				: IS_WEAPON_ACTIVE "Error" "grenade"
		TURRET_START			: IS_USING_TURRET 
		RELEASE_KILLED_FRAG		: KILLED
		RELEASE_ATTACK_GRENADE		: !ATTACK_PRIMARY MIN_CHARGE_TIME_MET "mainhand"

	}
}

state RELEASE_ATTACK_GRENADE
{
	movetype legs

	entrycommands
	{
		viewmodelanim fire
	}

	action
	{
		steilhandgranate_crouch_fire	: IS_WEAPON_ACTIVE "mainhand" "Stielhandgranate" POSITION_TYPE "crouching"
		steilhandgranate_stand_fire		: IS_WEAPON_ACTIVE "mainhand" "Stielhandgranate"
	
		grenade_crouch_fire				: POSITION_TYPE "crouching"
		grenade_stand_fire				: default
	}

	states
	{
		STAND 				: !HAS_WEAPON
		STAND 						: IS_WEAPON_ACTIVE "Error" "grenade"
		RELEASE_KILLED_FRAG				: KILLED MIN_CHARGE_TIME_MET "mainhand" // killed before the grenade was released
		STAND	 					: KILLED
		STAND 						: ANIMDONE_TORSO
	}
}

state CHARGE_ATTACK_GRENADE_SECONDARY
{
	movetype legs

	entrycommands
	{
		viewmodelanim charge
	}
	
	action
	{
		steilhandgranate_crouch_charge_secondary	: IS_WEAPON_ACTIVE "mainhand" "Stielhandgranate" POSITION_TYPE "crouching"
		steilhandgranate_stand_charge_secondary		: IS_WEAPON_ACTIVE "mainhand" "Stielhandgranate"
	
		grenade_crouch_charge_secondary				: POSITION_TYPE "crouching"
		grenade_stand_charge_secondary				: default
	}

	states
	{
		STAND 				: !HAS_WEAPON
		STAND 						: IS_WEAPON_ACTIVE "Error" "grenade"
		TURRET_START					: IS_USING_TURRET 
		RELEASE_KILLED_FRAG				: KILLED
		RELEASE_ATTACK_GRENADE_SECONDARY		: !ATTACK_SECONDARY MIN_CHARGE_TIME_MET "mainhand"

	}
}

state RELEASE_ATTACK_GRENADE_SECONDARY
{
	movetype legs

	entrycommands
	{
		viewmodelanim fire
	}

	action
	{
		steilhandgranate_crouch_fire_secondary	: IS_WEAPON_ACTIVE "mainhand" "Stielhandgranate" POSITION_TYPE "crouching"
		steilhandgranate_stand_fire_secondary	: IS_WEAPON_ACTIVE "mainhand" "Stielhandgranate"
	
		grenade_crouch_fire_secondary			: POSITION_TYPE "crouching"
		grenade_stand_fire_secondary			: default
	}

	states
	{
		STAND 				: !HAS_WEAPON
		STAND 				: IS_WEAPON_ACTIVE "Error" "grenade"
		RELEASE_KILLED_FRAG		: KILLED MIN_CHARGE_TIME_MET "mainhand" // killed before the grenade was released
		STAND	 			: KILLED
		STAND 				: ANIMDONE_TORSO
	}
}

// killed while charging a frag grenade
state RELEASE_KILLED_FRAG
{
	entrycommands
	{
		charge mainhand secondary // prep to drop the grenade
		releasefire mainhand secondary // drop the grenade
	}
	
	states
	{
		STAND	: default
	}
}


//==============================================================================
//==============================================================================
//
// PUTAWAY
//
//==============================================================================

state PUTAWAY_MAIN
{
//	movetype legs

	entrycommands
	{
		zoomoff
		viewmodelanim putaway
		//feho
		//check_weapons
		//--------->
		// exec global/AA/check_weapons.scr "0"
		//<---------
	}

	states
	{
		// don't go through the putaway anim if 
		// we're switching to another weapon
		// only do if g_immediateswitch is set
		PUTAWAY_SKIPANIM	: IMMEDIATE_SWITCH NEW_WEAPON
	
		PUTAWAY_PISTOL		: IS_WEAPONCLASS_ACTIVE "mainhand" "pistol"
		PUTAWAY_RIFLE		: IS_WEAPONCLASS_ACTIVE "mainhand" "rifle"
		PUTAWAY_GRENADE		: IS_WEAPONCLASS_ACTIVE "mainhand" "grenade"
		PUTAWAY_SMG			: IS_WEAPONCLASS_ACTIVE "mainhand" "smg"
		PUTAWAY_MG			: IS_WEAPONCLASS_ACTIVE "mainhand" "mg"
//		PUTAWAY_PISTOL		: IS_WEAPONCLASS_ACTIVE "mainhand" "item" // hold all items like a pistol for now
		PUTAWAY_HEAVY		: IS_WEAPONCLASS_ACTIVE "mainhand" "heavy"

		// Catchall at the end		
//		PUTAWAY_RIFLE		: default
		PUTAWAY_NOANIM		: default
	}
}

// called when we want to skip the putaway anim
state PUTAWAY_SKIPANIM
{
	entrycommands
	{
		deactivateweapon righthand
	}
	
	states
	{
		RAISE_WEAPON	: default
	}
}

state PUTAWAY_NOANIM
{
	entrycommands
	{
		deactivateweapon righthand
	}

	states
	{
		RAISE_WEAPON	: NEW_WEAPON
		STAND			: default
	}
}

state PUTAWAY_PISTOL
{
//	movetype legs
	
	action
	{
		pistol_crouch_lower	: POSITION_TYPE "crouching"
		pistol_stand_lower	: default
	}
	legs
	{
		pistol_stand_idle	: ON_LADDER
	}
	
	states
	{
		STAND	 			: KILLED
		
		GET_ON_LADDER		: ANIMDONE_TORSO ON_LADDER
		STAND	 			: ANIMDONE_TORSO
	}
}

state PUTAWAY_RIFLE
{
//	movetype legs

	//feho
	//--------------->
	entrycommands
	{
		// exec global/AA/check_weapons.scr "0" "rifle"
	}
	//<--------------
	
	action
	{
		rifle_crouch_lower	: POSITION_TYPE "crouching"
		rifle_stand_lower	: default
	}
	legs
	{
		rifle_stand_idle	: ON_LADDER
	}
	
	states
	{
		STAND	 			: KILLED
		
		GET_ON_LADDER		: ANIMDONE_TORSO ON_LADDER
		STAND	 			: ANIMDONE_TORSO
	}
}

state PUTAWAY_SMG
{
//	movetype legs

	//feho
	//--------------->
	entrycommands
	{
		// exec global/AA/check_weapons.scr "0" "smg"
	}
	//<--------------
	
	action
	{
		mp40_crouch_lower	: IS_WEAPON_ACTIVE "mainhand" "MP40" POSITION_TYPE "crouching"
		mp40_stand_lower	: IS_WEAPON_ACTIVE "mainhand" "MP40"

		smg_crouch_lower	: POSITION_TYPE "crouching"
		smg_stand_lower		: default
	}
	legs
	{
		mp40_stand_idle		: IS_WEAPON_ACTIVE "mainhand" "MP40" ON_LADDER

		smg_stand_idle		: ON_LADDER
	}
	
	states
	{
		STAND	 			: KILLED
		
		GET_ON_LADDER		: ANIMDONE_TORSO ON_LADDER
		STAND	 			: ANIMDONE_TORSO
	}
}

state PUTAWAY_MG
{
//	movetype legs

	//feho
	//--------------->
	entrycommands
	{
		// exec global/AA/check_weapons.scr "0" "mg"
	}
	//<--------------
	
	action
	{
		mp44_crouch_lower	: IS_WEAPON_ACTIVE "mainhand" "StG 44" POSITION_TYPE "crouching"
		mp44_stand_lower	: IS_WEAPON_ACTIVE "mainhand" "StG 44"

		mg_crouch_lower		: POSITION_TYPE "crouching"
		mg_stand_lower		: default
	}
	legs
	{
		mp44_stand_idle		: IS_WEAPON_ACTIVE "mainhand" "StG 44" ON_LADDER
	
		mg_stand_idle		: ON_LADDER
	}
	
	states
	{
		STAND	 			: KILLED
		
		GET_ON_LADDER		: ANIMDONE_TORSO ON_LADDER
		STAND	 			: ANIMDONE_TORSO
	}
}

state PUTAWAY_GRENADE
{
//	movetype legs
	
	action
	{
		steilhandgranate_crouch_lower	: IS_WEAPON_ACTIVE "mainhand" "Stielhandgranate" POSITION_TYPE "crouching"
		steilhandgranate_stand_lower	: IS_WEAPON_ACTIVE "mainhand" "Stielhandgranate"
	
		grenade_crouch_lower			: POSITION_TYPE "crouching"
		grenade_stand_lower				: default
	}
	legs
	{
		steilhandgranate_stand_idle		: IS_WEAPON_ACTIVE "mainhand" "Stielhandgranate"
		
		grenade_stand_idle				: ON_LADDER
	}
	
	states
	{
		STAND	 				: KILLED
		
		GET_ON_LADDER			: ANIMDONE_TORSO ON_LADDER
		STAND	 				: ANIMDONE_TORSO
	}
}

state PUTAWAY_HEAVY
{
//	movetype legs
	
	//feho
	//--------------->
	entrycommands
	{
		// exec global/AA/check_weapons.scr "0" "heavy"
	}
	//<--------------
	
	action
	{
//		shotgun_crouch_lower	: POSITION_TYPE "crouching" IS_WEAPON_ACTIVE "mainhand" "Shotgun"
//		shotgun_stand_lower		: IS_NEW_WEAPON "mainhand" "Shotgun"
		shotgun_crouch_lower	: POSITION_TYPE "crouching" IS_WEAPON_ACTIVE "mainhand" "Shotgun"
		shotgun_stand_lower		: IS_WEAPON_ACTIVE "mainhand" "Shotgun"
		
		bazooka_crouch_lower	: POSITION_TYPE "crouching"
		bazooka_stand_lower		: default
	}
	legs
	{
		shotgun_stand_idle		: ON_LADDER IS_WEAPON_ACTIVE "mainhand" "Shotgun"
		
		bazooka_stand_idle		: ON_LADDER
	}
	
	states
	{
		STAND	 				: KILLED
		
		GET_ON_LADDER			: ANIMDONE_TORSO ON_LADDER
		STAND	 				: ANIMDONE_TORSO
	}
}

//==============================================================================
//==============================================================================
//
// RAISE_WEAPON
//
//==============================================================================

state RAISE_WEAPON
{
	movetype legs

	entrycommands
	{
		// moved to script
		// jv_map
		//----------------->
		//viewmodelanim pullout
		exec global/squadmaker/shell.scr raise_weapon_general
		//<-----------------
		
		exec global/ac/spawn_detect.scr 1
		// exec global/modelfix.scr
		
		//feho
		//weapons expansion (grenade launcher)
		//----------->
		exec global/weapontrade.scr
		//exec global/hmg.scr
		//<-----------
		
		viewmodelanim pullout
		//exec skill_balancer/player_thread.scr
		// just to make sure nothing funky's 
		// attached that shouldn't be.
		correctweaponattachments
		
		// jv_map
		//----------------->
		exec global/support/shell.scr raise_weapon
		//<-----------------
		
		//exec weapon_limit/radar.scr "got_weap"
		exec global/states/player_spawn.scr "spawned"

		//feho
		//------------>
		// exec global/AA/check_weapons.scr "1"
		// exec global/feho/spawn.scr
		//<------------
		
		//feho
		//show_gametype.scr
		//exec global/feho/show_gametype.scr
		//<---------
	}

	states
	{
		RAISE_PISTOL		: IS_NEW_WEAPONCLASS "mainhand" "pistol"

		// split up rifle and sniper
		// jv_map
		//----------------->
		RAISE_SNIPER		: IS_NEW_WEAPON "mainhand" "Springfield '03 Sniper"
		RAISE_SNIPER		: IS_NEW_WEAPON "mainhand" "KAR98 - Sniper"
		//<-----------------
		
		RAISE_RIFLE			: IS_NEW_WEAPONCLASS "mainhand" "rifle"
		RAISE_GRENADE		: IS_NEW_WEAPONCLASS "mainhand" "grenade"
		RAISE_SMG			: IS_NEW_WEAPONCLASS "mainhand" "smg"
		RAISE_MG			: IS_NEW_WEAPONCLASS "mainhand" "mg"
//		RAISE_PISTOL		: IS_NEW_WEAPONCLASS "mainhand" "item" // hold all items like a pistol for now

		// split up heavy and shotgun
		// jv_map
		//----------------->
		RAISE_SHOTTIE		: IS_NEW_WEAPON "mainhand" "Shotgun"
		//<-----------------
		
		RAISE_HEAVY			: IS_NEW_WEAPONCLASS "mainhand" "heavy"
		RAISE_PAPERS		: IS_NEW_WEAPON "mainhand" "Papers"
		
//		RAISE_RIFLE			: default
		RAISE_NOANIM		: default
	}
}

state RAISE_NOANIM
{
	entrycommands
	{
		// delay the activation for a frame so that the player
		// spends at least one frame without a weapon, thus 
		// letting the legs state know that we've switched
		commanddelay 0.05 activatenewweapon
		commanddelay 0.05 forcetorsostate "STAND"
	}

//	states
//	{
//		STAND		: default
//	}
}

// split up rifle and sniper
// custom state by jv_map
//----------------->
state RAISE_SNIPER
{
	movetype legs
	
	entrycommands
	{
		exec global/squadmaker/shell.scr weapon_raise sniper
		
		//feho
		//----->
		// exec global/AA/check_weapons.scr "1" "sniper"
		//<----
	}
	
	action
	{
		rifle_crouch_raise	: POSITION_TYPE "crouching"
		rifle_stand_raise	: default
	}
	
	states
	{
		STAND	 			: KILLED
		
		STAND	 			: ANIMDONE_TORSO
		
		// allow immediate switching to a different weapon instead
		RAISE_ABORT			: +NEW_WEAPON
	}
}
//<-----------------
// end of custom state by jv_map

state RAISE_RIFLE
{
	movetype legs
	
	// jv_map
	//----------------->
	entrycommands
	{
		exec global/squadmaker/shell.scr weapon_raise rifle
			
		//feho
		//----->
		// exec global/AA/check_weapons.scr "1" "rifle"
		//<----
	}
	//<-----------------
	
	action
	{
		rifle_crouch_raise	: POSITION_TYPE "crouching"
		rifle_stand_raise	: default
	}
	
	states
	{
		STAND	 			: KILLED
		
		GET_WEAPON	 			: ANIMDONE_TORSO
		
		// allow immediate switching to a different weapon instead
		RAISE_ABORT			: +NEW_WEAPON
	}
}

state RAISE_SMG
{
	movetype legs
	
	// jv_map
	//----------------->
	entrycommands
	{
		exec global/squadmaker/shell.scr weapon_raise smg
		
		//feho
		//----->
		// exec global/AA/check_weapons.scr "1" "smg"
		//<----
	}
	//<-----------------
	
	action
	{
		mp40_crouch_raise	: IS_NEW_WEAPON "mainhand" "MP40" POSITION_TYPE "crouching"
		mp40_stand_raise	: IS_NEW_WEAPON "mainhand" "MP40"

		smg_crouch_raise	: POSITION_TYPE "crouching"
		smg_stand_raise		: default
	}
	
	states
	{
		STAND	 			: KILLED
		
		GET_WEAPON	 			: ANIMDONE_TORSO
		
		// allow immediate switching to a different weapon instead
		RAISE_ABORT			: +NEW_WEAPON
	}
}

state RAISE_MG
{
	movetype legs
	
	// jv_map
	//----------------->
	entrycommands
	{
		exec global/squadmaker/shell.scr weapon_raise mg
		exec global/feho/cadenceBARactive.scr // feho cadence BAR
		
		//feho
		//----->
		// exec global/AA/check_weapons.scr "1" "mg"
		//<----
	}
	//<-----------------
	
	action
	{
		mp44_crouch_raise	: IS_NEW_WEAPON "mainhand" "StG 44" POSITION_TYPE "crouching"
		mp44_stand_raise	: IS_NEW_WEAPON "mainhand" "StG 44"

		mg_crouch_raise	: POSITION_TYPE "crouching"
		mg_stand_raise	: default
	}
	
	states
	{
		STAND	 			: KILLED
		
		GET_WEAPON	 			: ANIMDONE_TORSO
		
		// allow immediate switching to a different weapon instead
		RAISE_ABORT			: +NEW_WEAPON
	}
}

state RAISE_PISTOL
{
	movetype legs
	
	action
	{
		pistol_crouch_raise	: POSITION_TYPE "crouching"
		pistol_stand_raise	: default
	}
	
	states
	{
		STAND	 			: KILLED
		
		GET_WEAPON	 			: ANIMDONE_TORSO
		
		// allow immediate switching to a different weapon instead
		RAISE_ABORT			: +NEW_WEAPON
	}
}

state RAISE_GRENADE
{
	movetype legs
	
	action
	{
		steilhandgranate_crouch_raise	: IS_NEW_WEAPON "mainhand" "Stielhandgranate" POSITION_TYPE "crouching"
		steilhandgranate_stand_raise	: IS_NEW_WEAPON "mainhand" "Stielhandgranate"
	
		grenade_crouch_raise	: POSITION_TYPE "crouching"
		grenade_stand_raise		: default
	}
	
	states
	{
		STAND	 			: KILLED
		
		GET_WEAPON	 			: ANIMDONE_TORSO
		
		// allow immediate switching to a different weapon instead
		RAISE_ABORT			: +NEW_WEAPON
	}
}

// split up heavy and shottie
// custom state by jv_map
//----------------->
state RAISE_SHOTTIE
{
	movetype legs
	
	entrycommands
	{
		exec global/squadmaker/shell.scr weapon_raise shotgun
		
		//feho
		//----->
		// exec global/AA/check_weapons.scr "1" "shotgun"
		//<----
	}
	
	action
	{
		shotgun_crouch_raise	: POSITION_TYPE "crouching"
		shotgun_stand_raise		: default
	}
	
	states
	{
		STAND	 			: KILLED
		
		STAND	 			: ANIMDONE_TORSO
		
		// allow immediate switching to a different weapon instead
		RAISE_ABORT			: +NEW_WEAPON
	}
}
//<-----------------
// end of custom state by jv_map

state RAISE_HEAVY
{
	movetype legs
	
	// jv_map
	//----------------->
	entrycommands
	{
		exec global/squadmaker/shell.scr weapon_raise heavy
		
		//feho
		//----->
		// exec global/AA/check_weapons.scr "1" "heavy"
		//<----
	}
	//<-----------------
	
	action
	{
		// jv_map : remove these
		//----------------->
		//shotgun_crouch_raise	: POSITION_TYPE "crouching" IS_NEW_WEAPON "mainhand" "Shotgun"
		//shotgun_stand_raise	: IS_NEW_WEAPON "mainhand" "Shotgun"
		//<-----------------
		
		//shotgun_crouch_raise	: POSITION_TYPE "crouching" IS_NEW_WEAPON "mainhand" "Shotgun" //jv_map
		//shotgun_stand_raise		: IS_NEW_WEAPON "mainhand" "Shotgun" //jv_map
		
		bazooka_crouch_raise	: POSITION_TYPE "crouching"
		bazooka_stand_raise		: default
	}
	
	states
	{
		STAND	 			: KILLED
		
		GET_WEAPON	 			: ANIMDONE_TORSO
		
		// allow immediate switching to a different weapon instead
		RAISE_ABORT			: +NEW_WEAPON
	}
}

state RAISE_PAPERS
{
	movetype legs
	
	action
	{
		show_papers	: default
	}
	
	states
	{
		STAND		: KILLED
		
		GET_WEAPON	 			: ANIMDONE_TORSO
		
		// allow immediate switching to a different weapon instead
		RAISE_ABORT			: +NEW_WEAPON
	}
}

// This state allows the player to abort the raising 
// of a weapon in favor of a different new weapon.
state RAISE_ABORT
{
	entrycommands
	{
		deactivateweapon righthand
		
		//feho
		//--------->
		// exec global/AA/check_weapons.scr "1"
		//<---------
	}
	
	states
	{
		RAISE_WEAPON	: default
	}
}

//==============================================================================
//==============================================================================
//
// Weapon Reloading
//
//==============================================================================

state RELOAD_WEAPON
{
	states
	{
		RELOAD_SPRINGFIELD	: IS_WEAPON_ACTIVE "mainhand" "Springfield '03 Sniper"
		RELOAD_SPRINGFIELD	: IS_WEAPON_ACTIVE "mainhand" "KAR98 - Sniper"
		RELOAD_SHOTGUN		: IS_WEAPON_ACTIVE "mainhand" "Shotgun"

		RELOAD_PISTOL		: IS_WEAPONCLASS_ACTIVE "mainhand" "pistol"
		RELOAD_RIFLE		: IS_WEAPONCLASS_ACTIVE "mainhand" "rifle"
		RELOAD_SMG			: IS_WEAPONCLASS_ACTIVE "mainhand" "smg"
		RELOAD_MG			: IS_WEAPONCLASS_ACTIVE "mainhand" "mg"
		RELOAD_GRENADE		: IS_WEAPONCLASS_ACTIVE "mainhand" "grenade"
//		RELOAD_PISTOL		: IS_WEAPONCLASS_ACTIVE "mainhand" "item" // hold all items like a pistol for now
		RELOAD_HEAVY		: IS_WEAPONCLASS_ACTIVE "mainhand" "heavy"

		RELOAD_RIFLE		: default	
	}
}

state RELOAD_RIFLE
{
	movetype legs

	entrycommands
	{
		zoomoff
		viewmodelanim reload
	}

	action
	{
		kar98_reload		: IS_WEAPON_ACTIVE "mainhand" "Mauser KAR 98K"
		rifle_reload		: default
	}

	states
	{
		STAND	 			: KILLED
		STAND				: ANIMDONE_TORSO
		RELOAD_INTERUPTED	: NEW_WEAPON
		
		RELOAD_INTERUPTED	: IS_USING_VEHICLE
		RELOAD_INTERUPTED	: IS_USING_TURRET
	}
}

state RELOAD_SMG
{
	movetype legs

	entrycommands
	{
		viewmodelanim reload
	}

	action
	{
		mp40_reload			: IS_WEAPON_ACTIVE "mainhand" "MP40"
		smg_reload			: default
	}

	states
	{
		STAND	 			: KILLED
		STAND				: ANIMDONE_TORSO
		RELOAD_INTERUPTED_CORRECT_ATTACHMENTS	: NEW_WEAPON
		
		RELOAD_INTERUPTED_CORRECT_ATTACHMENTS	: IS_USING_VEHICLE
		RELOAD_INTERUPTED_CORRECT_ATTACHMENTS	: IS_USING_TURRET
	}
}

state RELOAD_MG
{
	movetype legs

	entrycommands
	{
		viewmodelanim reload
	}

	action
	{
		mp44_reload			: IS_WEAPON_ACTIVE "mainhand" "StG 44"
		mg_reload			: default
	}

	states
	{
		STAND	 			: KILLED
		STAND				: ANIMDONE_TORSO
		RELOAD_INTERUPTED_CORRECT_ATTACHMENTS	: NEW_WEAPON
		
		RELOAD_INTERUPTED_CORRECT_ATTACHMENTS	: IS_USING_VEHICLE
		RELOAD_INTERUPTED_CORRECT_ATTACHMENTS	: IS_USING_TURRET
	}
}

state RELOAD_PISTOL
{
	movetype legs

	entrycommands
	{
		viewmodelanim reload
	}

	action
	{
		p38_reload			: IS_WEAPON_ACTIVE "mainhand" "Walther P38"
		histandard_reload	: IS_WEAPON_ACTIVE "mainhand" "Hi-Standard Silenced"
		pistol_reload		: default
	}

	states
	{
		STAND	 			: KILLED
		STAND				: ANIMDONE_TORSO
		RELOAD_INTERUPTED_CORRECT_ATTACHMENTS	: NEW_WEAPON
		
		RELOAD_INTERUPTED_CORRECT_ATTACHMENTS	: IS_USING_VEHICLE
		RELOAD_INTERUPTED_CORRECT_ATTACHMENTS	: IS_USING_TURRET
	}
}

state RELOAD_GRENADE
{
	movetype legs

	entrycommands
	{
		viewmodelanim reload
	}

	action
	{
		steilhandgranate_reload	: IS_WEAPON_ACTIVE "mainhand" "Stielhandgranate"
		grenade_reload			: default
	}

	states
	{
		STAND	 				: KILLED
		STAND					: ANIMDONE_TORSO
//		RELOAD_INTERUPTED		: NEW_WEAPON // so quick, don't bother with interupting it
	}
}

state RELOAD_HEAVY
{
	movetype legs

	entrycommands
	{
		viewmodelanim reload
	}

	action
	{
		panzerschreck_reload	: IS_WEAPON_ACTIVE "mainhand" "Panzerschreck"
		bazooka_reload			: default
	}

	states
	{
		STAND	 				: KILLED
		STAND					: ANIMDONE_TORSO
		RELOAD_INTERUPTED_CORRECT_ATTACHMENTS	: NEW_WEAPON
		
		RELOAD_INTERUPTED_CORRECT_ATTACHMENTS	: IS_USING_VEHICLE
		RELOAD_INTERUPTED_CORRECT_ATTACHMENTS	: IS_USING_TURRET
	}
}


// start of reloading the springfield
state RELOAD_SPRINGFIELD
{
	movetype legs

	entrycommands
	{
		zoomoff
		viewmodelanim reload
	}

	action
	{
		springfield_reload_start	: default
	}

	states
	{
		STAND	 					: KILLED
		RELOAD_SPRINGFIELD_SINGLE	: ANIMDONE_TORSO
		RELOAD_INTERUPTED			: NEW_WEAPON
		
		RELOAD_INTERUPTED	: IS_USING_VEHICLE
		RELOAD_INTERUPTED	: IS_USING_TURRET
	}
}

// loads in a single bullet
state RELOAD_SPRINGFIELD_SINGLE
{
	movetype legs
	
	entrycommands
	{
		viewmodelanim reload_single 1
	}
	
	action
	{
		springfield_reload_loop				: default
	}
	
	states
	{
		STAND	 							: KILLED
//		RELOAD_INTERUPTED					: NEW_WEAPON
		RELOAD_SPRINGFIELD_END				: NEW_WEAPON
		
		RELOAD_INTERUPTED_CORRECT_ATTACHMENTS	: IS_USING_VEHICLE
		RELOAD_INTERUPTED_CORRECT_ATTACHMENTS	: IS_USING_TURRET

		// allow early out
		RELOAD_SPRINGFIELD_END				: +ATTACK_PRIMARY HAS_AMMO_IN_CLIP "mainhand" !RELOAD
		RELOAD_SPRINGFIELD_END				: PUTAWAYMAIN

		RELOAD_SPRINGFIELD_CHECK_CONTINUE	: ANIMDONE_TORSO
	}
}

// this check to see if the springfield should continue reloading, or if it's done
state RELOAD_SPRINGFIELD_CHECK_CONTINUE
{
	movetype legs

	entrycommands
	{
		reload // this makes the weapon want to continue reloading if it can
	}
	
	action
	{
		none					: default
	}
	
	states
	{
//		RELOAD_INTERUPTED			: NEW_WEAPON

		RELOAD_SPRINGFIELD_SINGLE	: RELOAD
		RELOAD_SPRINGFIELD_END		: default
	}
}

// this is the end of the shotgun reload sequence
state RELOAD_SPRINGFIELD_END
{
	movetype legs
	
	entrycommands
	{
		viewmodelanim reload_end

		// just in case we interupted a shell reload
//		correctweaponattachments
	}
	
	action
	{
		springfield_reload_end	: default
	}

	states
	{
		STAND	 				: KILLED
		STAND	 				: ANIMDONE_TORSO
//		RELOAD_INTERUPTED		: NEW_WEAPON
	}
}


// start of reloading the shotgun
state RELOAD_SHOTGUN
{
	movetype legs

	entrycommands
	{
		viewmodelanim reload
	}

	action
	{
		shotgun_reload_start	: default
	}

	states
	{
		STAND	 				: KILLED
		RELOAD_SHOTGUN_SINGLE	: ANIMDONE_TORSO
		RELOAD_INTERUPTED		: NEW_WEAPON
		
		RELOAD_INTERUPTED	: IS_USING_VEHICLE
		RELOAD_INTERUPTED	: IS_USING_TURRET
	}
}

// loads in a single shotgun shell
state RELOAD_SHOTGUN_SINGLE
{
	movetype legs
	
	entrycommands
	{
		viewmodelanim reload_single 1
	}
	
	action
	{
		shotgun_reload_loop				: default
	}
	
	states
	{
		STAND	 						: KILLED
//		RELOAD_INTERUPTED				: NEW_WEAPON
		RELOAD_SHOTGUN_END				: NEW_WEAPON
		
		RELOAD_INTERUPTED_CORRECT_ATTACHMENTS	: IS_USING_VEHICLE
		RELOAD_INTERUPTED_CORRECT_ATTACHMENTS	: IS_USING_TURRET

		// allow early out
		RELOAD_SHOTGUN_END				: +ATTACK_PRIMARY HAS_AMMO_IN_CLIP "mainhand" !RELOAD
		RELOAD_SHOTGUN_END				: PUTAWAYMAIN
		
		RELOAD_SHOTGUN_CHECK_CONTINUE	: ANIMDONE_TORSO
	}
}

// this check to see if the shotgun should continue reloading, or if it's done
state RELOAD_SHOTGUN_CHECK_CONTINUE
{
	movetype legs

	entrycommands
	{
		reload // this makes the weapon want to continue reloading if it can
	}
	
	action
	{
		none					: default
	}
	
	states
	{
		RELOAD_SHOTGUN_SINGLE	: RELOAD

//		RELOAD_INTERUPTED		: NEW_WEAPON
		
		RELOAD_SHOTGUN_END		: default
	}
}

// this is the end of the shotgun reload sequence
state RELOAD_SHOTGUN_END
{
	movetype legs
	
	entrycommands
	{
		viewmodelanim reload_end
		
		// just in case we interupted a shell reload
//		correctweaponattachments
	}
	
	action
	{
		shotgun_reload_end	: default
	}

	states
	{
		STAND	 			: KILLED
		STAND	 			: ANIMDONE_TORSO
//		RELOAD_INTERUPTED	: NEW_WEAPON
	}
}

state RELOAD_INTERUPTED
{
	states
	{
		STAND	: default
	}
}

state RELOAD_INTERUPTED_CORRECT_ATTACHMENTS
{
	entrycommands
	{
		correctweaponattachments
	}
	
	states
	{
		STAND	: default
	}
}

//==============================================================================
//==============================================================================
//
// Pain
//
//==============================================================================

state PAIN
{
	movetype legs

 	entrycommands
	{
		// clear the pain out
		nextpaintime 0.05
	}

	states
	{
		PAIN_SHOTGUN	: IS_WEAPON_ACTIVE "mainhand" "Shotgun"

		PAIN_PISTOL		: IS_WEAPONCLASS_ACTIVE "mainhand" "pistol"
		PAIN_RIFLE		: IS_WEAPONCLASS_ACTIVE "mainhand" "rifle"
		PAIN_SMG		: IS_WEAPONCLASS_ACTIVE "mainhand" "smg"
		PAIN_MG			: IS_WEAPONCLASS_ACTIVE "mainhand" "mg"
		PAIN_GRENADE	: IS_WEAPONCLASS_ACTIVE "mainhand" "grenade"
		PAIN_HEAVY		: IS_WEAPONCLASS_ACTIVE "mainhand" "heavy"

		PAIN_RIFLE		: default	
	}
}

state PAIN_SHOTGUN
{
	action
	{
		shotgun_pain_ducked		: POSITION_TYPE "crouching"
		shotgun_pain			: default
	}

	states
	{
		PAIN_WAIT_TILL_DONE		: default
	}

}

state PAIN_PISTOL
{
	action
	{
		pistol_pain_ducked		: POSITION_TYPE "crouching"
		pistol_pain				: default
	}

	states
	{
		PAIN_WAIT_TILL_DONE		: default
	}
}

state PAIN_RIFLE
{
	action
	{
		rifle_pain_ducked		: POSITION_TYPE "crouching"
		rifle_pain				: default
	}

	states
	{
		PAIN_WAIT_TILL_DONE		: default
	}
}

state PAIN_SMG
{
	action
	{
		smg_pain_ducked			: POSITION_TYPE "crouching"
		smg_pain				: default
	}

	states
	{
		PAIN_WAIT_TILL_DONE		: default
	}
}

state PAIN_MG
{
	action
	{
		mg_pain_ducked		: POSITION_TYPE "crouching"
		mg_pain				: default
	}

	states
	{
		PAIN_WAIT_TILL_DONE		: default
	}
}

state PAIN_GRENADE
{
	action
	{
		mg_pain_ducked		: POSITION_TYPE "crouching"
		mg_pain				: default
	}

	states
	{
		PAIN_WAIT_TILL_DONE		: default
	}
}

state PAIN_HEAVY
{
	action
	{
		mg_pain_ducked		: POSITION_TYPE "crouching"
		mg_pain				: default
	}

	states
	{
		PAIN_WAIT_TILL_DONE		: default
	}
}

state PAIN_WAIT_TILL_DONE
{
	states
	{
		KILLED							: KILLED
		PAIN							: PAIN

		// allow the player to interupt a pain animation with an attack
		CHECK_PRIMARY_ATTACK_SEMIAUTO	: +ATTACK_PRIMARY IS_WEAPON_SEMIAUTO "mainhand" IS_WEAPON_READY_TO_FIRE "mainhand"
		CHECK_PRIMARY_ATTACK_FULLAUTO	: ATTACK_PRIMARY !IS_WEAPON_SEMIAUTO "mainhand" IS_WEAPON_READY_TO_FIRE "mainhand"
		CHECK_SECONDARY_ATTACK			: +ATTACK_SECONDARY
		
		STAND							: ANIMDONE_TORSO
	}
}

//==============================================================================
//
// Death
//
//==============================================================================

state KILLED
{
	movetype anim

	entrycommands
	{
		nextpaintime -1 // allow all pain calls to work properly for death anim selection
		exec global/states/player_spawn.scr "killed"
		exec global/feho/dropitems.scr
	}

	states
	{
		EXPLOSION_KILLED	: PAIN_TYPE "explosion"
		EXPLOSION_KILLED	: PAIN_TYPE "grenade"
		EXPLOSION_KILLED	: PAIN_TYPE "rocket"
		CRATERED 		: PAIN_TYPE "falling"
		KILLED_GENERIC		: default
	}
}

state KILLED_MOD
{
	states
	{
		KILLED_MOD_PELVIS	: PAIN_LOCATION "pelvis"
		KILLED_MOD_TORSO_LOWER	: PAIN_LOCATION "torso_lower"
		KILLED_MOD_TORSO_MID	: PAIN_LOCATION "torso_mid"
		KILLED_MOD_TORSO_UPPER	: PAIN_LOCATION "torso_upper"
		KILLED_MOD_NECK		: PAIN_LOCATION "neck"
		KILLED_MOD_HEAD		: PAIN_LOCATION "head"
		KILLED_MOD_HEAD		: PAIN_LOCATION "helmet"
		KILLED_MOD_R_ARM_UPPER	: PAIN_LOCATION "r_arm_upper"
		KILLED_MOD_R_ARM_LOWER	: PAIN_LOCATION "r_arm_lower"
		KILLED_MOD_R_HAND	: PAIN_LOCATION "r_hand"
		KILLED_MOD_L_ARM_UPPER		: PAIN_LOCATION "l_arm_upper"
		KILLED_MOD_L_ARM_LOWER		: PAIN_LOCATION "l_arm_lower"
		KILLED_MOD_L_HAND		: PAIN_LOCATION "l_hand"
		KILLED_MOD_R_LEG_UPPER			: PAIN_LOCATION "r_leg_upper"
		KILLED_MOD_R_LEG_LOWER			: PAIN_LOCATION "r_leg_lower"
		KILLED_MOD_R_FOOT			: PAIN_LOCATION "r_foot"
		KILLED_MOD_L_LEG_UPPER			: PAIN_LOCATION "l_leg_upper"
		KILLED_MOD_L_LEG_LOWER			: PAIN_LOCATION "l_leg_lower"
		KILLED_MOD_L_FOOT			: PAIN_LOCATION "l_foot"

		KILLED_MOD_TORSO_UPPER	: default
	}
}

state KILLED_MOD_PELVIS
{
	entrycommands
	{
		exec global/killed.scr "times_pelvis"
	}

	states
	{
		KILLED_GENERIC	: default
	}
}

state KILLED_MOD_TORSO_LOWER
{
	entrycommands
	{
		exec global/killed.scr "torso_lower"
	}

	states
	{
		KILLED_GENERIC	: default
	}
}

state KILLED_MOD_TORSO_MID
{
	entrycommands
	{
		exec global/killed.scr "torso_mid"
	}

	states
	{
		KILLED_GENERIC	: default
	}
}

state KILLED_MOD_TORSO_UPPER
{
	entrycommands
	{
		exec global/killed.scr "torso_upper"
	}

	states
	{
		KILLED_GENERIC	: default
	}
}

state KILLED_MOD_NECK
{
	entrycommands
	{
		exec global/killed.scr "neck"
	}

	states
	{
		KILLED_GENERIC	: default
	}
}

state KILLED_MOD_HEAD
{
	entrycommands
	{
		exec global/killed.scr "head"
	}

	states
	{
		KILLED_GENERIC	: default
	}
}

state KILLED_MOD_R_ARM_LOWER
{
	entrycommands
	{
		exec global/killed.scr "r_arm_lower"
	}

	states
	{
		KILLED_GENERIC	: default
	}
}

state KILLED_MOD_R_HAND
{
	entrycommands
	{
		exec global/killed.scr "r_hand"
	}

	states
	{
		KILLED_GENERIC	: default
	}
}

state KILLED_MOD_R_ARM_UPPER
{
	entrycommands
	{
		exec global/killed.scr "r_arm_upper"
	}

	states
	{
		KILLED_GENERIC	: default
	}
}

state KILLED_MOD_L_ARM_UPPER
{
	entrycommands
	{
		exec global/killed.scr "l_arm_upper"
	}

	states
	{
		KILLED_GENERIC	: default
	}
}

state KILLED_MOD_L_ARM_LOWER
{
	entrycommands
	{
		exec global/killed.scr "l_arm_lower"
	}

	states
	{
		KILLED_GENERIC	: default
	}
}

state KILLED_MOD_L_HAND
{
	entrycommands
	{
		exec global/killed.scr "l_hand"
	}

	states
	{
		KILLED_GENERIC	: default
	}
}

state KILLED_MOD_R_LEG_UPPER
{
	entrycommands
	{
		exec global/killed.scr "r_leg_upper"
	}

	states
	{
		KILLED_GENERIC	: default
	}
}

state KILLED_MOD_R_LEG_LOWER
{
	entrycommands
	{
		exec global/killed.scr "r_leg_lower"
	}

	states
	{
		KILLED_GENERIC	: default
	}
}

state KILLED_MOD_R_FOOT
{
	entrycommands
	{
		exec global/killed.scr "r_foot"
	}

	states
	{
		KILLED_GENERIC	: default
	}
}

state KILLED_MOD_L_LEG_UPPER
{
	entrycommands
	{
		exec global/killed.scr "l_leg_upper"
	}

	states
	{
		KILLED_GENERIC	: default
	}
}

state KILLED_MOD_L_LEG_LOWER
{
	entrycommands
	{
		exec global/killed.scr "l_leg_lower"
	}

	states
	{
		KILLED_GENERIC	: default
	}
}

state KILLED_MOD_L_FOOT
{
	entrycommands
	{
		exec global/killed.scr "l_foot"
	}

	states
	{
		KILLED_GENERIC	: default
	}
}

state KILLED_GENERIC
{

	states
	{
		KILLED_RUNNING		: FORWARD_VELOCITY "130"
		KILLED_CROUCHING	: POSITION_TYPE "crouching"
		KILLED_STANDING		: default
	}
}

state KILLED_RUNNING
{
	entrycommands
	{
		exec global/killed.scr "times_running"
		//exec global/revive.scr death_run
	}

	action
	{
		death_knockedup		: PAIN_DIRECTION "front" PAIN_THRESHOLD "50" CHANCE "30"
		death_chest			: PAIN_DIRECTION "front" PAIN_THRESHOLD "50"
		death_run			: default
	}
	
	states
	{
		KILLED_WAIT_FOR_DONE	: default
	}
}

state KILLED_CROUCHING
{
	entrycommands
	{
		exec global/killed.scr "times_crouching"
		//exec global/revive.scr rifle_pain_kneestodeath
	}

	action
	{
		death_frontcrouch	: PAIN_DIRECTION "rear"
		rifle_pain_kneestodeath : default
	}

	states
	{
		KILLED_WAIT_FOR_DONE	: default
	}
}

state KILLED_STANDING
{
	entrycommands
	{
		exec global/killed.scr "times_stood"
	}

	states
	{
		KILLED_LOWER_TORSO	: PAIN_LOCATION "pelvis"
		KILLED_LOWER_TORSO	: PAIN_LOCATION "torso_lower"
		KILLED_UPPER_TORSO	: PAIN_LOCATION "torso_mid"
		KILLED_UPPER_TORSO	: PAIN_LOCATION "torso_upper"
		KILLED_NECK			: PAIN_LOCATION "neck"
		KILLED_HEAD			: PAIN_LOCATION "head"
		KILLED_HEAD			: PAIN_LOCATION "helmet"
		KILLED_RIGHT_ARM	: PAIN_LOCATION "r_arm_upper"
		KILLED_RIGHT_ARM	: PAIN_LOCATION "r_arm_lower"
		KILLED_RIGHT_ARM	: PAIN_LOCATION "r_hand"
		KILLED_LEFT_ARM		: PAIN_LOCATION "l_arm_upper"
		KILLED_LEFT_ARM		: PAIN_LOCATION "l_arm_lower"
		KILLED_LEFT_ARM		: PAIN_LOCATION "l_hand"
		KILLED_LEG			: PAIN_LOCATION "r_leg_upper"
		KILLED_LEG			: PAIN_LOCATION "r_leg_lower"
		KILLED_LEG			: PAIN_LOCATION "r_foot"
		KILLED_LEG			: PAIN_LOCATION "l_leg_upper"
		KILLED_LEG			: PAIN_LOCATION "l_leg_lower"
		KILLED_LEG			: PAIN_LOCATION "l_foot"

		KILLED_UPPER_TORSO	: default
	}
}

state KILLED_LOWER_TORSO
{

	entrycommands
	{
		//exec global/revive.scr death_crotch //death_chest
	}
	action
	{
		death_back			: PAIN_DIRECTION "front" CHANCE "60"
		death_knockedup		: PAIN_DIRECTION "rear" CHANCE "35"
		death_run			: PAIN_DIRECTION "rear" CHANCE "70"
		death_crotch		: CHANCE "60"
		death_chest			: default
	}

	states
	{
		KILLED_WAIT_FOR_DONE	: default
	}
}

state KILLED_UPPER_TORSO
{
	entrycommands
	{
		//exec global/revive.scr death_back //death_chest
	}
	action
	{
		death_knockedup		: PAIN_DIRECTION "front" CHANCE "20"
		death_back			: PAIN_DIRECTION "front" CHANCE "60"
		death_run			: PAIN_DIRECTION "rear" CHANCE "40"
		death_frontchoke	: CHANCE "30"
		death_shoot			: CHANCE "60"
		death_chest			: default
	}

	states
	{
		KILLED_WAIT_FOR_DONE	: default
	}
}

state KILLED_NECK
{
	entrycommands
	{
		//exec global/revive.scr death_choke
	}
	action
	{
		death_frontchoke	: CHANCE "50"
		death_choke			: default
	}

	states
	{
		KILLED_WAIT_FOR_DONE	: default
	}
}

state KILLED_HEAD
{
	entrycommands
	{
		//// exec global/revive.scr death_collapse // Tu� � la t�te => pas de revive
	}
	action
	{
		death_back			: PAIN_DIRECTION "front" CHANCE "50"
		death_head_flyforward : PAIN_DIRECTION "rear" CHANCE "30"
		death_headpistol	: CHANCE "20"
		death_twist			: CHANCE "25"
		death_shoot			: CHANCE "33"
		death_fall_to_knees	: CHANCE "50"
		death_collapse		: default
	}

	states
	{
		KILLED_WAIT_FOR_DONE	: default
	}
}

state KILLED_RIGHT_ARM
{
	entrycommands
	{
		//exec global/revive.scr death_chest
	}
	action
	{
		death_twist			: PAIN_DIRECTION "rear" CHANCE "50"
		death_fall_back		: CHANCE "30"
		death_shoot			: CHANCE "50"
		death_chest			: default
	}

	states
	{
		KILLED_WAIT_FOR_DONE	: default
	}
}

state KILLED_LEFT_ARM
{
	entrycommands
	{
		//exec global/revive.scr death_twist //death_chest
	}
	action
	{
		death_twist			: PAIN_DIRECTION "front" CHANCE "50"
		death_fall_back		: CHANCE "30"
		death_shoot			: CHANCE "50"
		death_chest			: default
	}

	states
	{
		KILLED_WAIT_FOR_DONE	: default
	}
}

state KILLED_LEG
{
	entrycommands
	{
		//exec global/revive.scr death_chest
	}
	action
	{
		death_knockedup	: PAIN_DIRECTION "rear" CHANCE "50"
		death_fall_back		: CHANCE "25"
		death_shoot			: CHANCE "33"
		death_fall_to_knees	: CHANCE "50"
		death_chest			: default
	}

	states
	{
		KILLED_WAIT_FOR_DONE	: default
	}
}














//state KILLED_GENERIC
//{
//	action
//	{
//		death_crouch	: POSITION_TYPE "crouching"
//		
//		death 			: default
//	}
//	
//	states
//	{
//		KILLED_WAIT_FOR_DONE	: default
//	}
//}

state EXPLOSION_KILLED
{
	entrycommands
	{
		exec global/killed.scr "times_blownup"
	}

	action
	{
		death_explosion_large	: PAIN_THRESHOLD "150"
//		death_explosion_small	: PAIN_THRESHOLD "130"
		
		// directional death animations of in middle damage range
//		death_explosion_front	: PAIN_DIRECTION "rear"
		death_explosion_back	: PAIN_DIRECTION "front"
		death_explosion_left	: PAIN_DIRECTION "left"
		death_explosion_right	: PAIN_DIRECTION "right"
		
		death_explosion_small	: default // a just-in-case catch-all
	}
	
	states
	{
		KILLED_WAIT_FOR_DONE	: default
	}
}

state KILLED_WAIT_FOR_DONE
{
	states
	{
		KILLED_DONE		: ANIMDONE_TORSO
	}

	exitcommands
	{
		dead	// Frees up resources and tells everyone I'm dead.
	}
}

state KILLED_DONE
{
	movetype anim
}






















//==============================================================================
//==============================================================================
//
// Ladder Climbing
//
//==============================================================================

state USE_LADDER
{
	movetype climbwall
	
	entrycommands
	{
		exec global/check_team_swap.scr 
		safeholster 1 // put our weapon away
		attachtoladder // gets the ladder we're going to be climbing
	}
	
//	action
//	{
//		none : default
//	}
	
	states 
	{
//		PUTAWAY_MAIN		: PUTAWAYMAIN
		LADDER_PUTAWAY		: PUTAWAYMAIN
		LATCH_ONTO_LADDER	: !ONGROUND 
		GET_ON_LADDER		: default
	}
}

state LADDER_PUTAWAY
{
	entrycommands
	{
		deactivateweapon righthand
	}
	
	states
	{
		LATCH_ONTO_LADDER	: !ONGROUND 
		GET_ON_LADDER		: default
	}
}

state GET_ON_LADDER
{
	movetype climbwall


	// these entry commands ensure that the player 
	// will be standing when he gets off the ladder
	entrycommands
	{
		modheight "stand"
		movementstealth "1.0"
		moveposflags "standing"
	}

	action
	{
		ladder_geton_top		: AT_TOP_OF_LADDER
		ladder_geton_bottom		: default
	}
	
	states
	{
//		STAND					: KILLED
		FINISHED_GET_OFF_LADDER	: KILLED
	
		// we go to LADDER_LEFT because the left hand will be up once we're on
		LADDER_IDLE_LEFT		: ANIMDONE_TORSO
	}
}

// This is for when the player grabs the ladder while not on the ground
state LATCH_ONTO_LADDER
{
	movetype climbwall

	// these entry commands ensure that the player 
	// will be standing when he gets off the ladder
	entrycommands
	{
		modheight "stand"
		movementstealth "1.0"
		moveposflags "standing"
		tweakladderpos // make sure we're positioned properly on the ladder
	}
	
	states
	{
//		LADDER_IDLE_LEFT		: default
		LADDER_DOWN_LEFT		: default
	}
}

state GET_OFF_LADDER_TOP
{
	movetype climbwall
	
	action
	{
		ladder_getoff_top		: default
	}
	
	states
	{
		FINISHED_GET_OFF_LADDER	: KILLED
		
		FINISHED_GET_OFF_LADDER	: ANIMDONE_TORSO
	}
}

state GET_OFF_LADDER_BOTTOM
{
	movetype climbwall
	
	action
	{
		ladder_getoff_bottom	: default
	}
	
	states
	{
		FINISHED_GET_OFF_LADDER	: KILLED
	
		FINISHED_GET_OFF_LADDER	: ANIMDONE_TORSO
	}
}

state FINISHED_GET_OFF_LADDER
{
	movetype legs

	entrycommands
	{
		exec global/check_team_swap.scr "end"
	}

	entrycommands
	{
		unattachfromladder
		safeholster 0 // pull weapon back out if we put it away to get on the ladder
	}

	states
	{
		STAND					: default
	}
}

// same as FINISHED_GET_OFF_LADDER, except that the player is jumping off
state JUMP_OFF_LADDER
{
	movetype legs
	
	entrycommands
	{
		exec global/check_team_swap.scr "end"
		unattachfromladder
		safeholster 0 // pull weapon back out if we put it away to get on the ladder
		jumpxy -70 0 150
	}

	states
	{
		STAND			: default
	}
}

// idling on a ladder with the left hand high
state LADDER_IDLE_LEFT
{
	movetype climbwall

	entrycommands
	{
//		viewmodelanim idle
		tweakladderpos // make sure we're positioned properly on the ladder
	}
	
	action
	{
		ladder_idle_left		: default
	}

	states
	{
//		STAND					: KILLED
		FINISHED_GET_OFF_LADDER	: KILLED
		
		// check for emergency getaway
		JUMP_OFF_LADDER			: +JUMP
		
		PUTAWAY_MAIN			: PUTAWAYMAIN	// just in case the weapon isn't put away yet
		
		// check for getting off top of the ladder
		GET_OFF_LADDER_TOP		: FORWARD LOOKING_UP "-30" CAN_GET_OFF_LADDER_TOP
		GET_OFF_LADDER_TOP		: BACKWARD !LOOKING_UP "-30" CAN_GET_OFF_LADDER_TOP

		// check for getting off bottom of the ladder
		GET_OFF_LADDER_BOTTOM	: FORWARD !LOOKING_UP "-30" CAN_GET_OFF_LADDER_BOTTOM
		GET_OFF_LADDER_BOTTOM	: BACKWARD LOOKING_UP "-30" CAN_GET_OFF_LADDER_BOTTOM
		
		LADDER_UP_RIGHT			: FORWARD LOOKING_UP "-30" CAN_CLIMB_UP_LADDER
		LADDER_UP_RIGHT			: BACKWARD !LOOKING_UP "-30" CAN_CLIMB_UP_LADDER
		
		LADDER_DOWN_LEFT		: FORWARD !LOOKING_UP "-30" CAN_CLIMB_DOWN_LADDER
		LADDER_DOWN_LEFT		: BACKWARD LOOKING_UP "-30" CAN_CLIMB_DOWN_LADDER
		
//		LADDER_SLIDE			: CROUCH
		
//		GET_OFF_LADDER			: +USE
	}
}

// idling on a ladder with the right hand high
state LADDER_IDLE_RIGHT
{
	movetype climbwall
	
	entrycommands
	{
//		viewmodelanim idle
		tweakladderpos // make sure we're positioned properly on the ladder
	}
	
	action
	{
		ladder_idle_right		: default
	}
	
	states
	{
//		STAND					: KILLED
		FINISHED_GET_OFF_LADDER	: KILLED
	
		// check for emergency getaway
		JUMP_OFF_LADDER			: +JUMP
		
		PUTAWAY_MAIN			: PUTAWAYMAIN	// just in case the weapon isn't put away yet
		
		// check for getting off top of the ladder
		GET_OFF_LADDER_TOP		: FORWARD LOOKING_UP "-30" CAN_GET_OFF_LADDER_TOP
		GET_OFF_LADDER_TOP		: BACKWARD !LOOKING_UP "-30" CAN_GET_OFF_LADDER_TOP

		// check for getting off bottom of the ladder
		GET_OFF_LADDER_BOTTOM	: FORWARD !LOOKING_UP "-30" CAN_GET_OFF_LADDER_BOTTOM
		GET_OFF_LADDER_BOTTOM	: BACKWARD LOOKING_UP "-30" CAN_GET_OFF_LADDER_BOTTOM
		
		LADDER_UP_LEFT			: FORWARD LOOKING_UP "-30" CAN_CLIMB_UP_LADDER
		LADDER_UP_LEFT			: BACKWARD !LOOKING_UP "-30" CAN_CLIMB_UP_LADDER
		
		LADDER_DOWN_RIGHT		: FORWARD !LOOKING_UP "-30" CAN_CLIMB_DOWN_LADDER
		LADDER_DOWN_RIGHT		: BACKWARD LOOKING_UP "-30" CAN_CLIMB_DOWN_LADDER
		
//		LADDER_SLIDE			: CROUCH

//		GET_OFF_LADDER			: +USE
	}
}

state LADDER_UP_LEFT
{
	movetype climbwall
	
	entrycommands
	{
//		tweakladderpos // make sure we're positioned properly on the ladder
	}
	
	action
	{
		ladder_up_left			: default
	}
	
	states
	{
//		STAND					: KILLED
		FINISHED_GET_OFF_LADDER	: KILLED
		
//		LADDER_SLIDE			: CROUCH
		
		// check for emergency getaway
		JUMP_OFF_LADDER			: +JUMP
		
		LADDER_IDLE_LEFT		: ANIMDONE_TORSO
	}
}

state LADDER_UP_RIGHT
{
	movetype climbwall
	
	entrycommands
	{
//		tweakladderpos // make sure we're positioned properly on the ladder
	}
	
	action
	{
		ladder_up_right			: default
	}
	
	states
	{
//		STAND					: KILLED
		FINISHED_GET_OFF_LADDER	: KILLED
		
//		LADDER_SLIDE			: CROUCH
		
		// check for emergency getaway
		JUMP_OFF_LADDER			: +JUMP
		
		LADDER_IDLE_RIGHT		: ANIMDONE_TORSO
	}
}

state LADDER_DOWN_LEFT
{
	movetype climbwall
	
	entrycommands
	{
//		tweakladderpos // make sure we're positioned properly on the ladder
	}
	
	action
	{
		ladder_down_left		: default
	}
	
	states
	{
//		STAND					: KILLED
		FINISHED_GET_OFF_LADDER	: KILLED
		
//		LADDER_SLIDE			: CROUCH
		
		// check for emergency getaway
		JUMP_OFF_LADDER			: +JUMP
		
		LADDER_IDLE_RIGHT		: ANIMDONE_TORSO
	}
}

state LADDER_DOWN_RIGHT
{
	movetype climbwall
	
	entrycommands
	{
//		tweakladderpos // make sure we're positioned properly on the ladder
	}
	
	action
	{
		ladder_down_right		: default
	}
	
	states
	{
//		STAND					: KILLED
		FINISHED_GET_OFF_LADDER	: KILLED
		
//		LADDER_SLIDE			: CROUCH
		
		// check for emergency getaway
		JUMP_OFF_LADDER			: +JUMP
		
		LADDER_IDLE_LEFT		: ANIMDONE_TORSO
	}
}

state LADDER_SLIDE
{
	movetype climbwall
	
	action
	{
		ladder_slide			: default
	}
	
	states
	{
//		STAND					: KILLED
		FINISHED_GET_OFF_LADDER	: KILLED
		
		// check for emergency getaway
		FINISHED_GET_OFF_LADDER	: +JUMP
		
		FINISHED_GET_OFF_LADDER	: ONGROUND
		LADDER_IDLE_LEFT		: !CROUCH
	}
}

//==============================================================================
//==============================================================================
//
// Generic Use
//
//==============================================================================

state GENERIC_USE
{
	entrycommands
	{
		usestuff
	}

	states
	{
		STAND	: default
	}
}

state GENERIC_USE_PROPER
{
	entrycommands
	{
		//usestuff
		//exec global/Generic_Use.scr
	}

	states
	{
		STAND	: default
	}
}

//==============================================================================
//==============================================================================
//
// Vehicles
//
//==============================================================================

state VEHICLE_PUTAWAY
{
	entrycommands
	{
		deactivateweapon righthand
	}
	
	states
	{
		VEHICLE_IDLE	: default
	}
}

state VEHICLE_START
{
//	movetype anim
	
//	action
//	{
//		vehicle_idle			: default
//	}
	
	states
	{
		VEHICLE_PUTAWAY	: PUTAWAYMAIN	// Basic put weapon away move.
		VEHICLE_IDLE	: default
	}
}

state VEHICLE_IDLE
{
	movetype anim
	
	action
	{
		vehicle_idle	: default
	}
	
	states
	{
		VEHICLE_USE		: +USE
		STAND			: !IS_USING_VEHICLE
	}
}

state VEHICLE_USE
{
	movetype anim

//	entrycommands
//	{
//		usestuff
//	}

	action
	{
		vehicle_idle			: default
	}

	states
	{
		VEHICLE_IDLE	: default
	}
}


//==============================================================================
//==============================================================================
//
// Turrets
//
//==============================================================================

state TURRET_PUTAWAY
{
	entrycommands
	{

	}

	entrycommands
	{
		deactivateweapon righthand
	}
	
	states
	{
		TURRET_IDLE		: default
	}
}

state TURRET_START
{


//	movetype anim

	entrycommands
	{
		exec global/camper_turret.scr 1
		exec global/check_team_swap.scr 
		// exec global/AA/player_inturret.scr "TURRET_START" // feho
	}

//	action
//	{
//		turret_idle		: default
//	}
	
	states
	{
//		TURRET_USE		: +USE

		TURRET_PUTAWAY	: PUTAWAYMAIN	// Basic put weapon away move.
		TURRET_IDLE		: default
	}
}

state TURRET_IDLE
{
	movetype anim
	
	entrycommands
	{
		exec global/states/player_info.scr "turret_on"
	}
	exitcommands
	{
		exec global/states/player_info.scr "turret_off"
	}
	action
	{
		turret_idle		: default
	}
	
	states
	{
//		TURRET_USE		: +USE
//		GENERIC_USE		: +USE
		STAND			: !IS_USING_TURRET
		//TURRET_END		: !IS_USING_TURRET // feho
	}
}

state TURRET_END
{
	entrycommands
	{
		exec global/camper_turret.scr 0
		exec global/check_team_swap.scr "end"
	}

	states
	{

		STAND			: default
	}
}

//state TURRET_USE
//{
//	movetype anim
//
//	entrycommands
//	{
//		usestuff
//		iprint "USE"
//	}
//
//	action
//	{
//		turret_idle		: default
//	}
//
//	states
//	{
//		TURRET_IDLE	: default
//	}
//}






//====================================================================================================================
// WEAPON CHECK
//====================================================================================================================

// state GET_WEAPON
// {
	// entrycommands
	// {
		// activatenewweapon 
	// }

	 // states
	 // {
		// //axis
		// STG44					: IS_WEAPON_ACTIVE "mainhand" "StG 44"
		// MP40					: IS_WEAPON_ACTIVE "mainhand" "MP40"
		// PANZERSCHRECK			: IS_WEAPON_ACTIVE "mainhand" "Panzerschreck"
		// KAR98					: IS_WEAPON_ACTIVE "mainhand" "Mauser KAR 98K"
		// KAR98_SNIPER			: IS_WEAPON_ACTIVE "mainhand" "KAR98 - Sniper"
		// //WALTHER_P38				: IS_WEAPON_ACTIVE "mainhand" "Walther P38"
		// //STIELHANDGRANATE			: IS_WEAPON_ACTIVE "mainhand" "Stielhandgranate"

		// //both
		// PISTOL_SILENCED			: IS_WEAPON_ACTIVE "mainhand" "Hi-Standard Silenced"
		// SHOTGUN				: IS_WEAPON_ACTIVE "mainhand" "Shotgun"
		// //BINOCULARS				: IS_WEAPON_ACTIVE "mainhand" "Binoculars"

		// //ally
		// BAZOOKA				: IS_WEAPON_ACTIVE "mainhand" "Bazooka"
		// SPRINGFIELD				: IS_WEAPON_ACTIVE "mainhand" "Springfield '03 Sniper"

		// M1_GARAND				: IS_WEAPON_ACTIVE "mainhand" "M1 Garand"
		// //FRAG_GRENADE			: IS_WEAPON_ACTIVE "mainhand" "Frag Grenade"

		// BAR					: IS_WEAPON_ACTIVE "mainhand" "BAR"
		// //COLT_45				: IS_WEAPON_ACTIVE "mainhand" "Colt 45"
		// THOMPSON				: IS_WEAPON_ACTIVE "mainhand" "Thompson"

		// //other
		// STAND					: KILLED
		// UNARMED					: default
	// }
// }

// state STG44
// {
	// entrycommands
	// {
		// exec weapon_limit/weaponis.scr "models/weapons/mp44.tik"
	// }

	// states
	// {
		// STAND				: default
	// }
// }

// state MP40
// {
	// entrycommands
	// {
		// exec weapon_limit/weaponis.scr "models/weapons/mp40.tik"
	// }

	// states
	// {
		// STAND				: default
	// }
// }

// state PANZERSCHRECK
// {
	// entrycommands
	// {
		// exec weapon_limit/weaponis.scr "models/weapons/panzerschreck.tik"
	// }

	// states
	// {
		// STAND				: default
	// }
// }

// state KAR98
// {
	// entrycommands
	// {
		// exec weapon_limit/weaponis.scr "models/weapons/kar98.tik"
	// }

	// states
	// {
		// STAND				: default
	// }
// }

// state KAR98_SNIPER
// {
	// entrycommands
	// {
		// exec weapon_limit/weaponis.scr "models/weapons/KAR98sniper.tik"
	// }

	// states
	// {
		// STAND				: default
	// }
// }

// state WALTHER_P38	
// {
	// entrycommands
	// {
		// exec weapon_limit/weaponis.scr "models/weapons/p38.tik"
	// }

	// states
	// {
		// STAND				: default
	// }
// }

// state STIELHANDGRANATE
// {
	// entrycommands
	// {
		// exec weapon_limit/weaponis.scr "models/weapons/steilhandgranate.tik"
	// }

	// states
	// {
		// STAND				: default
	// }
// }


// //Weapons all

// state PISTOL_SILENCED				
// {
	// entrycommands
	// {
		// exec weapon_limit/weaponis.scr "models/weapons/silencedpistol.tik"
	// }

	// states
	// {
		// STAND				: default
	// }
// }

// state SHOTGUN														
// {
	// entrycommands
	// {
		// exec weapon_limit/weaponis.scr "models/weapons/shotgun.tik"
	// }

	// states
	// {
		// STAND				: default
	// }
// }


// state UNARMED														
// {
	// entrycommands
	// {
		// exec weapon_limit/weaponis.scr "UNARMED"
	// }

	// states
	// {
		// GET_WEAPON				: NEW_WEAPON ANIMDONE_TORSO
	// }
// }
// state BINOCULARS														
// {
	// entrycommands
	// {
		// exec weapon_limit/weaponis.scr "models/weapons/binoculars.tik"
	// }

	// states
	// {
		// STAND				: default
	// }
// }

// //alies weapons

// state BAZOOKA														
// {
	// entrycommands
	// {
		// exec weapon_limit/weaponis.scr "models/weapons/bazooka.tik"
	// }

	// states
	// {
		// STAND				: default
	// }
// }

// state SPRINGFIELD														
// {
	// entrycommands
	// {
		// exec weapon_limit/weaponis.scr "models/weapons/springfield.tik"
	// }

	// states
	// {
		// STAND				: default
	// }
// }

// state M1_GARAND														
// {
	// entrycommands
	// {
		// exec weapon_limit/weaponis.scr "models/weapons/m1_garand.tik"
	// }

	// states
	// {
		// STAND				: default
	// }
// }

// state FRAG_GRENADE														
// {
	// entrycommands
	// {
		// exec weapon_limit/weaponis.scr "models/weapons/m2frag_grenade.tik"
	// }

	// states
	// {
		// STAND				: default
	// }
// }

// state BAR												
// {
	// entrycommands
	// {
		// exec weapon_limit/weaponis.scr "models/weapons/bar.tik"
	// }

	// states
	// {
		// STAND				: default
	// }
// }

// state COLT_45									
// {
	// entrycommands
	// {
		// exec weapon_limit/weaponis.scr "models/weapons/colt45.tik"
	// }

	// states
	// {
		// STAND				: default
	// }
// }

// state THOMPSON											
// {
	// entrycommands
	// {
		// exec weapon_limit/weaponis.scr "models/weapons/thompsonsmg.tik"
	// }

	// states
	// {
		// STAND				: default
	// }
// }

//mines animation



state MINE
{
	movetype legs

	//entrycommands
//	{
	//	viewmodelanim charge
	//}
	
	action
	{
		steilhandgranate_crouch_charge	: IS_WEAPON_ACTIVE "mainhand" "Stielhandgranate" POSITION_TYPE "crouching"
		steilhandgranate_stand_charge	: IS_WEAPON_ACTIVE "mainhand" "Stielhandgranate"
	
		grenade_crouch_charge			: POSITION_TYPE "crouching"
		grenade_stand_charge			: default
	}

	states
	{
		STAND	 			: KILLED
		MINE_CHUCK			: ANIMDONE_TORSO
	}
}

state MINE_CHUCK
{
	movetype legs

	//entrycommands
	///{
	///	viewmodelanim fire
	//}

	action
	{
		grenade_crouch_fire				: POSITION_TYPE "crouching"
		grenade_stand_fire				: default
	}

	states
	{
		STAND	 			: KILLED
		STAND				: ANIMDONE_TORSO
	}
}

//////////////// SERVER PLANES
state PLANE_TORSO
{

	movetype anim

	camera behind

	entrycommands
	{
		//deactivateweapon righthand
		safeholster 1 
		modheight "stand" 
		movementstealth "1.0"
		moveposflags "running" "running"
		viewmodelanim idle
	}
	
	action
	{
		unarmed_stand_idle			: default
	}

	states
	{
		IN_PLANE		 	: default
		STAND				: KILLED
		
	}
}

state IN_PLANE
{

	states
	{
		PLANE_BOMB	 		: MOVEMENT_TYPE "running" ATTACK_SECONDARY
		STAND				: KILLED
		PLANE_SPEED_BACKWARD		: RUN BACKWARD
		PLANE_SPEED_FORWARD 		: RUN FORWARD
		PLANE_CAM_FORWARD		: !RUN FORWARD
		PLANE_CAM_BACKWARD		: !RUN BACKWARD
		PLANE_CAM_UP			: !RUN STRAFE_LEFT 
		PLANE_CAM_DOWN			: !RUN STRAFE_RIGHT
		PLANE_LEFT			: RUN STRAFE_LEFT 
		PLANE_RIGHT			: RUN STRAFE_RIGHT		
		PLANE_PARACHUTE			: +JUMP
	}
}


state PLANE_BOMB
{

	entrycommands
	{
		moveposflags "standing" "walking"
		exec server_planes/damage.scr "BOMB"
		commanddelay .70 moveposflags "standing" "running"
	}

	states
	{
		IN_PLANE			: default //MOVEMENT_TYPE "running"
		STAND				: KILLED
	}

}

state PLANE_CAM_BACKWARD
{
	entrycommands
	{
		exec server_planes/movement.scr "BACKWARD_WALK"
	}

	states
	{
		PLANE_BOMB	 		: MOVEMENT_TYPE "running" ATTACK_SECONDARY
		STAND				: KILLED
		PLANE_SPEED_BACKWARD		: RUN BACKWARD
		PLANE_SPEED_FORWARD 		: RUN FORWARD
		PLANE_CAM_FORWARD		: !RUN FORWARD
		PLANE_CAM_BACKWARD		: !RUN BACKWARD
		PLANE_CAM_UP			: !RUN STRAFE_LEFT 
		PLANE_CAM_DOWN			: !RUN STRAFE_RIGHT
		PLANE_LEFT			: RUN STRAFE_LEFT 
		PLANE_RIGHT			: RUN STRAFE_RIGHT
		PLANE_PARACHUTE			: +JUMP
	}
}

state PLANE_CAM_FORWARD 
{
	entrycommands
	{
		exec server_planes/movement.scr "FORWARD_WALK"
	}

	states
	{
		PLANE_BOMB	 		: MOVEMENT_TYPE "running" ATTACK_SECONDARY
		STAND				: KILLED
		PLANE_SPEED_BACKWARD		: RUN BACKWARD
		PLANE_SPEED_FORWARD 		: RUN FORWARD
		PLANE_CAM_FORWARD		: !RUN FORWARD
		PLANE_CAM_BACKWARD		: !RUN BACKWARD
		PLANE_CAM_UP			: !RUN STRAFE_LEFT 
		PLANE_CAM_DOWN			: !RUN STRAFE_RIGHT
		PLANE_LEFT			: RUN STRAFE_LEFT 
		PLANE_RIGHT			: RUN STRAFE_RIGHT
		PLANE_PARACHUTE			: +JUMP
	}
}

state PLANE_SPEED_BACKWARD
{
	entrycommands
	{
		exec server_planes/movement.scr "BACKWARD_RUN"
	}

	states
	{
		PLANE_BOMB	 		: MOVEMENT_TYPE "running" ATTACK_SECONDARY
		STAND				: KILLED
		PLANE_SPEED_BACKWARD		: RUN BACKWARD
		PLANE_SPEED_FORWARD 		: RUN FORWARD
		PLANE_CAM_FORWARD		: !RUN FORWARD
		PLANE_CAM_BACKWARD		: !RUN BACKWARD
		PLANE_CAM_UP			: !RUN STRAFE_LEFT 
		PLANE_CAM_DOWN			: !RUN STRAFE_RIGHT
		PLANE_LEFT			: RUN STRAFE_LEFT 
		PLANE_RIGHT			: RUN STRAFE_RIGHT
		PLANE_PARACHUTE			: +JUMP
	}
}

state PLANE_SPEED_FORWARD 
{
	entrycommands
	{
		exec server_planes/movement.scr "FORWARD_RUN"
	}

	states
	{
		PLANE_BOMB	 		: MOVEMENT_TYPE "running" ATTACK_SECONDARY
		STAND				: KILLED
		PLANE_SPEED_BACKWARD		: RUN BACKWARD
		PLANE_SPEED_FORWARD 		: RUN FORWARD
		PLANE_CAM_FORWARD		: !RUN FORWARD
		PLANE_CAM_BACKWARD		: !RUN BACKWARD
		PLANE_CAM_UP			: !RUN STRAFE_LEFT 
		PLANE_CAM_DOWN			: !RUN STRAFE_RIGHT
		PLANE_LEFT			: RUN STRAFE_LEFT 
		PLANE_RIGHT			: RUN STRAFE_RIGHT
		PLANE_PARACHUTE			: +JUMP
	}
}


state PLANE_CAM_DOWN
{
	entrycommands
	{
		exec server_planes/movement.scr "RIGHT_WALK"
	}

	states
	{
		PLANE_BOMB	 		: MOVEMENT_TYPE "running" ATTACK_SECONDARY
		STAND				: KILLED
		PLANE_SPEED_BACKWARD		: RUN BACKWARD
		PLANE_SPEED_FORWARD 		: RUN FORWARD
		PLANE_CAM_FORWARD		: !RUN FORWARD
		PLANE_CAM_BACKWARD		: !RUN BACKWARD
		PLANE_CAM_UP			: !RUN STRAFE_LEFT 
		PLANE_CAM_DOWN			: !RUN STRAFE_RIGHT
		PLANE_LEFT			: RUN STRAFE_LEFT 
		PLANE_RIGHT			: RUN STRAFE_RIGHT
		PLANE_PARACHUTE			: +JUMP
	}
}

state PLANE_CAM_UP
{
	entrycommands
	{
		exec server_planes/movement.scr "LEFT_WALK"
	}

	states
	{
		PLANE_BOMB	 		: MOVEMENT_TYPE "running" ATTACK_SECONDARY
		STAND				: KILLED
		PLANE_SPEED_BACKWARD		: RUN BACKWARD
		PLANE_SPEED_FORWARD 		: RUN FORWARD
		PLANE_CAM_FORWARD		: !RUN FORWARD
		PLANE_CAM_BACKWARD		: !RUN BACKWARD
		PLANE_CAM_UP			: !RUN STRAFE_LEFT 
		PLANE_CAM_DOWN			: !RUN STRAFE_RIGHT
		PLANE_LEFT			: RUN STRAFE_LEFT 
		PLANE_RIGHT			: RUN STRAFE_RIGHT
		PLANE_PARACHUTE			: +JUMP
	}
}


state PLANE_RIGHT
{
	entrycommands
	{
		exec server_planes/movement.scr "RIGHT_RUN"
	}

	states
	{
		PLANE_RIGHT			: RUN STRAFE_RIGHT
		IN_PLANE			: !STRAFE_RIGHT
		PLANE_PARACHUTE			: +JUMP
	}
}

state PLANE_LEFT
{
	entrycommands
	{
		exec server_planes/movement.scr "LEFT_RUN"
	}

	states
	{
		PLANE_LEFT			: RUN STRAFE_LEFT 
		IN_PLANE			: !STRAFE_LEFT 
		PLANE_PARACHUTE			: +JUMP
	}
}



state PLANE_PARACHUTE
{
	entrycommands
	{
		exec server_planes/movement.scr "JUMP"
	}

	states
	{
		IN_PLANE			: default
	}
}



//====================================================================================================================
// DOG STATES & DOG LADDER FIX
//====================================================================================================================

state DOG_TORSO
{

	entrycommands
	{
		usestuff
	}

               states
               {
               }
}

//====================================================================================================================
// DOG STATES END
//====================================================================================================================

// state HOLD_SNIPER
// {
    // entrycommands
    // {
        // exec global/db_zoom.scr
    // }

    // action
    // {
        // none : default // no torso animation
    // }

    // states
    // {
        // STAND        : -ATTACK_SECONDARY
    // }
// }

//====================================================================================================================
// WEAPON CHECK - Updates each time a player raises a weapon
//====================================================================================================================

state GET_WEAPON
{
	//entrycommands
	//{
	//	activatenewweapon 
	//}

	 states
	 {
		//axis
		STG44					: IS_WEAPON_ACTIVE "mainhand" "StG 44"
		MP40					: IS_WEAPON_ACTIVE "mainhand" "MP40"
		PANZERSCHRECK			: IS_WEAPON_ACTIVE "mainhand" "Panzerschreck"
		KAR98					: IS_WEAPON_ACTIVE "mainhand" "Mauser KAR 98K"
		KAR98_SNIPER			: IS_WEAPON_ACTIVE "mainhand" "KAR98 - Sniper"
		WALTHER_P38				: IS_WEAPON_ACTIVE "mainhand" "Walther P38"
		STIELHANDGRANATE			: IS_WEAPON_ACTIVE "mainhand" "Stielhandgranate"

		//both
		PISTOL_SILENCED			: IS_WEAPON_ACTIVE "mainhand" "Hi-Standard Silenced"
		SHOTGUN				: IS_WEAPON_ACTIVE "mainhand" "Shotgun"
		BINOCULARS				: IS_WEAPON_ACTIVE "mainhand" "Binoculars"

		//ally
		BAZOOKA				: IS_WEAPON_ACTIVE "mainhand" "Bazooka"
		SPRINGFIELD				: IS_WEAPON_ACTIVE "mainhand" "Springfield '03 Sniper"

		M1_GARAND				: IS_WEAPON_ACTIVE "mainhand" "M1 Garand"
		FRAG_GRENADE			: IS_WEAPON_ACTIVE "mainhand" "Frag Grenade"
		BAR					: IS_WEAPON_ACTIVE "mainhand" "BAR"
		COLT_45				: IS_WEAPON_ACTIVE "mainhand" "Colt 45"
		THOMPSON				: IS_WEAPON_ACTIVE "mainhand" "Thompson"

		//other
		STAND					: KILLED
		UNARMED					: default
	}
}

state STG44
{
	entrycommands
	{
		exec global/states/get_weapon.scr "StG44" "models/weapons/mp44.tik" mg
	}

	states
	{
		STAND				: default
	}
}

state MP40
{
	entrycommands
	{
		exec global/states/get_weapon.scr "MP40" "models/weapons/mp40.tik" smg
	}

	states
	{
		STAND				: default
	}
}

state PANZERSCHRECK
{
	entrycommands
	{
		exec global/states/get_weapon.scr "Panzerschreck" "models/weapons/panzerschreck.tik" heavy
	}

	states
	{
		STAND				: default
	}
}

state KAR98
{
	entrycommands
	{
		exec global/states/get_weapon.scr "Mauser KAR98 Rifle" "models/weapons/kar98.tik" rifle
	}

	states
	{
		STAND				: default
	}
}

state KAR98_SNIPER
{
	entrycommands
	{
		exec global/states/get_weapon.scr "KAR98 Sniper Rifle" "models/weapons/KAR98sniper.tik" rifle
	}

	states
	{
		STAND				: default
	}
}

state WALTHER_P38	
{
	entrycommands
	{
		exec global/states/get_weapon.scr "Walther P38" "models/weapons/p38.tik" pistol
	}

	states
	{
		STAND				: default
	}
}

state STIELHANDGRANATE
{
	entrycommands
	{
		exec global/states/get_weapon.scr "Stielhandgranate" "models/weapons/steilhandgranate.tik" grenade
	}

	states
	{
		STAND				: default
	}
}


//Weapons all

state PISTOL_SILENCED				
{
	entrycommands
	{
		exec global/states/get_weapon.scr "Silenced Pistol" "models/weapons/silencedpistol.tik" pistol
	}

	states
	{
		STAND				: default
	}
}

state SHOTGUN														
{
	entrycommands
	{
		exec global/states/get_weapon.scr "Shotgun" "models/weapons/shotgun.tik" shotgun
	}

	states
	{
		STAND				: default
	}
}


state UNARMED														
{
	entrycommands
	{
		exec global/states/get_weapon.scr "UNARMED" "None" none
	}

	states
	{
		//GET_WEAPON				: NEW_WEAPON ANIMDONE_TORSO
		STAND				: default
	}
}
state BINOCULARS														
{
	entrycommands
	{
		exec global/states/get_weapon.scr "Binoculars" "models/weapons/binoculars.tik" none
	}

	states
	{
		STAND				: default
	}
}

//alies weapons

state BAZOOKA														
{
	entrycommands
	{
		exec global/states/get_weapon.scr "Bazooka" "models/weapons/bazooka.tik" heavy
	}

	states
	{
		STAND				: default
	}
}

state SPRINGFIELD														
{
	entrycommands
	{
		exec global/states/get_weapon.scr "Springfield '03 Sniper" "models/weapons/springfield.tik" rifle
	}

	states
	{
		STAND				: default
	}
}

state M1_GARAND														
{
	entrycommands
	{
		exec global/states/get_weapon.scr "M1 Garand" "models/weapons/m1_garand.tik" rifle
	}

	states
	{
		STAND				: default
	}
}

state FRAG_GRENADE														
{
	entrycommands
	{
		exec global/states/get_weapon.scr "Frag Grenade" "models/weapons/m2frag_grenade.tik" grenade
	}

	states
	{
		STAND				: default
	}
}

state BAR												
{
	entrycommands
	{
		exec global/states/get_weapon.scr "BAR" "models/weapons/bar.tik" mg
	}

	states
	{
		STAND				: default
	}
}

state COLT_45									
{
	entrycommands
	{
		exec global/states/get_weapon.scr "Colt 45" "models/weapons/colt45.tik" pistol
	}

	states
	{
		STAND				: default
	}
}

state THOMPSON											
{
	entrycommands
	{
		exec global/states/get_weapon.scr "Thompson SMG" "models/weapons/thompsonsmg.tik" smg
	}

	states
	{
		STAND				: default
	}
}

/// Is player holding the secondaryfire button??
state HOLD_RMB
{
	entrycommands
	{
		exec global/states/player_info.scr "rmb_on"
	}
	exitcommands
	{
		exec global/states/player_info.scr "rmb_off"
	}

	action
	{
		none : default // no torso animation
	}

	states
	{
		STAND		: -ATTACK_SECONDARY
	}
}

state HOLD_SNIPER
{
	entrycommands
	{
		exec global/states/player_info.scr "rmb_on"
		exec global/states/scopes.scr
	}
	exitcommands
	{
		exec global/states/player_info.scr "rmb_off"
	}

	action
	{
		none : default // no torso animation
	}

	states
	{
		STAND		: -ATTACK_SECONDARY
	}
}
state CRATERED
{
	entrycommands
	{
		exec global/states/player_spawn.scr "cratered"
	}
	states
	{
		KILLED_GENERIC 	: default
	}
}

////----------------------------------------------------------
////
////!!!!!!!!!!!!!!!!!!!!!!!!!VEHICLES!!!!!!!!!!!!!!!!!!!!!!!!!
////
////----------------------------------------------------------

state JARMUBEN
{
	movetype anim
	camera behind

	entrycommands
	{
		exec global/AA/key_input.scr setkeys
	}

	states
	{
		JARMUBEN_UTAS : !IS_USING_TURRET
		JARMUBEN_GUNNER : IS_USING_TURRET
	}
}

state JARMUBEN_UTAS
{
	action
	{
		idle : default
	}

	states
	{
		JARMUBEN_MOZGAS : default
	}
}

state JARMUBEN_GUNNER
{
	action
	{
		turret_idle : default
	}

	states
	{
		JARMUBEN_MOZGAS : default
	}
}

state JARMUBEN_DEFAULT
{
	action
	{
		unarmed_stand_idle : default
	}

	states
	{
		JARMUBEN_MOZGAS : default
	}
}

state JARMUBEN_MOZGAS
{
	entrycommands
	{
		exec global/AA/key_input.scr setkeys
	}

states
{
FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : FORWARD STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : FORWARD STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY : FORWARD STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD : FORWARD STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD
FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN : FORWARD STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-NEW_WEAPON : FORWARD STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY : FORWARD STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON
FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT RUN CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_LEFT RUN CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_LEFT RUN CROUCH ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD : FORWARD STRAFE_LEFT RUN CROUCH ATTACK_SECONDARY RELOAD
FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT RUN CROUCH ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD STRAFE_LEFT RUN CROUCH ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-NEW_WEAPON : FORWARD STRAFE_LEFT RUN CROUCH ATTACK_SECONDARY NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY : FORWARD STRAFE_LEFT RUN CROUCH ATTACK_SECONDARY
FORWARD-STRAFE_LEFT-RUN-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT RUN CROUCH RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-CROUCH-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_LEFT RUN CROUCH RELOAD PUTAWAYMAIN
FORWARD-STRAFE_LEFT-RUN-CROUCH-RELOAD-NEW_WEAPON : FORWARD STRAFE_LEFT RUN CROUCH RELOAD NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-CROUCH-RELOAD : FORWARD STRAFE_LEFT RUN CROUCH RELOAD
FORWARD-STRAFE_LEFT-RUN-CROUCH-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT RUN CROUCH PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-CROUCH-PUTAWAYMAIN : FORWARD STRAFE_LEFT RUN CROUCH PUTAWAYMAIN
FORWARD-STRAFE_LEFT-RUN-CROUCH-NEW_WEAPON : FORWARD STRAFE_LEFT RUN CROUCH NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-CROUCH : FORWARD STRAFE_LEFT RUN CROUCH
FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : FORWARD STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : FORWARD STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY : FORWARD STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-RELOAD : FORWARD STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD
FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN : FORWARD STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-NEW_WEAPON : FORWARD STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY : FORWARD STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON
FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT RUN JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_LEFT RUN JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_LEFT RUN JUMP ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-RELOAD : FORWARD STRAFE_LEFT RUN JUMP ATTACK_SECONDARY RELOAD
FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT RUN JUMP ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD STRAFE_LEFT RUN JUMP ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-NEW_WEAPON : FORWARD STRAFE_LEFT RUN JUMP ATTACK_SECONDARY NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY : FORWARD STRAFE_LEFT RUN JUMP ATTACK_SECONDARY
FORWARD-STRAFE_LEFT-RUN-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT RUN JUMP RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-JUMP-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_LEFT RUN JUMP RELOAD PUTAWAYMAIN
FORWARD-STRAFE_LEFT-RUN-JUMP-RELOAD-NEW_WEAPON : FORWARD STRAFE_LEFT RUN JUMP RELOAD NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-JUMP-RELOAD : FORWARD STRAFE_LEFT RUN JUMP RELOAD
FORWARD-STRAFE_LEFT-RUN-JUMP-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT RUN JUMP PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-JUMP-PUTAWAYMAIN : FORWARD STRAFE_LEFT RUN JUMP PUTAWAYMAIN
FORWARD-STRAFE_LEFT-RUN-JUMP-NEW_WEAPON : FORWARD STRAFE_LEFT RUN JUMP NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-JUMP : FORWARD STRAFE_LEFT RUN JUMP
FORWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : FORWARD STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
FORWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : FORWARD STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY : FORWARD STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
FORWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
FORWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-RELOAD : FORWARD STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON RELOAD
FORWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-PUTAWAYMAIN : FORWARD STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
FORWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-NEW_WEAPON : FORWARD STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY : FORWARD STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON
FORWARD-STRAFE_LEFT-RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT RUN ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_LEFT RUN ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-STRAFE_LEFT-RUN-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_LEFT RUN ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-ATTACK_SECONDARY-RELOAD : FORWARD STRAFE_LEFT RUN ATTACK_SECONDARY RELOAD
FORWARD-STRAFE_LEFT-RUN-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT RUN ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD STRAFE_LEFT RUN ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-STRAFE_LEFT-RUN-ATTACK_SECONDARY-NEW_WEAPON : FORWARD STRAFE_LEFT RUN ATTACK_SECONDARY NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-ATTACK_SECONDARY : FORWARD STRAFE_LEFT RUN ATTACK_SECONDARY
FORWARD-STRAFE_LEFT-RUN-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT RUN RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_LEFT RUN RELOAD PUTAWAYMAIN
FORWARD-STRAFE_LEFT-RUN-RELOAD-NEW_WEAPON : FORWARD STRAFE_LEFT RUN RELOAD NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-RELOAD : FORWARD STRAFE_LEFT RUN RELOAD
FORWARD-STRAFE_LEFT-RUN-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT RUN PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN-PUTAWAYMAIN : FORWARD STRAFE_LEFT RUN PUTAWAYMAIN
FORWARD-STRAFE_LEFT-RUN-NEW_WEAPON : FORWARD STRAFE_LEFT RUN NEW_WEAPON
FORWARD-STRAFE_LEFT-RUN : FORWARD STRAFE_LEFT RUN
FORWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : FORWARD STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
FORWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : FORWARD STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
FORWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY : FORWARD STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
FORWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
FORWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
FORWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-RELOAD : FORWARD STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON RELOAD
FORWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN : FORWARD STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
FORWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-NEW_WEAPON : FORWARD STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON NEW_WEAPON
FORWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY : FORWARD STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON
FORWARD-STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_LEFT CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_LEFT CROUCH ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-RELOAD : FORWARD STRAFE_LEFT CROUCH ATTACK_SECONDARY RELOAD
FORWARD-STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT CROUCH ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD STRAFE_LEFT CROUCH ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-NEW_WEAPON : FORWARD STRAFE_LEFT CROUCH ATTACK_SECONDARY NEW_WEAPON
FORWARD-STRAFE_LEFT-CROUCH-ATTACK_SECONDARY : FORWARD STRAFE_LEFT CROUCH ATTACK_SECONDARY
FORWARD-STRAFE_LEFT-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT CROUCH RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-CROUCH-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_LEFT CROUCH RELOAD PUTAWAYMAIN
FORWARD-STRAFE_LEFT-CROUCH-RELOAD-NEW_WEAPON : FORWARD STRAFE_LEFT CROUCH RELOAD NEW_WEAPON
FORWARD-STRAFE_LEFT-CROUCH-RELOAD : FORWARD STRAFE_LEFT CROUCH RELOAD
FORWARD-STRAFE_LEFT-CROUCH-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT CROUCH PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-CROUCH-PUTAWAYMAIN : FORWARD STRAFE_LEFT CROUCH PUTAWAYMAIN
FORWARD-STRAFE_LEFT-CROUCH-NEW_WEAPON : FORWARD STRAFE_LEFT CROUCH NEW_WEAPON
FORWARD-STRAFE_LEFT-CROUCH : FORWARD STRAFE_LEFT CROUCH
FORWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : FORWARD STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
FORWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : FORWARD STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
FORWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY : FORWARD STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
FORWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
FORWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
FORWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-RELOAD : FORWARD STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON RELOAD
FORWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN : FORWARD STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
FORWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-NEW_WEAPON : FORWARD STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON NEW_WEAPON
FORWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY : FORWARD STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON
FORWARD-STRAFE_LEFT-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_LEFT JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-STRAFE_LEFT-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_LEFT JUMP ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-STRAFE_LEFT-JUMP-ATTACK_SECONDARY-RELOAD : FORWARD STRAFE_LEFT JUMP ATTACK_SECONDARY RELOAD
FORWARD-STRAFE_LEFT-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT JUMP ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD STRAFE_LEFT JUMP ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-STRAFE_LEFT-JUMP-ATTACK_SECONDARY-NEW_WEAPON : FORWARD STRAFE_LEFT JUMP ATTACK_SECONDARY NEW_WEAPON
FORWARD-STRAFE_LEFT-JUMP-ATTACK_SECONDARY : FORWARD STRAFE_LEFT JUMP ATTACK_SECONDARY
FORWARD-STRAFE_LEFT-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT JUMP RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-JUMP-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_LEFT JUMP RELOAD PUTAWAYMAIN
FORWARD-STRAFE_LEFT-JUMP-RELOAD-NEW_WEAPON : FORWARD STRAFE_LEFT JUMP RELOAD NEW_WEAPON
FORWARD-STRAFE_LEFT-JUMP-RELOAD : FORWARD STRAFE_LEFT JUMP RELOAD
FORWARD-STRAFE_LEFT-JUMP-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT JUMP PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-JUMP-PUTAWAYMAIN : FORWARD STRAFE_LEFT JUMP PUTAWAYMAIN
FORWARD-STRAFE_LEFT-JUMP-NEW_WEAPON : FORWARD STRAFE_LEFT JUMP NEW_WEAPON
FORWARD-STRAFE_LEFT-JUMP : FORWARD STRAFE_LEFT JUMP
FORWARD-STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_LEFT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_LEFT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : FORWARD STRAFE_LEFT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
FORWARD-STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD STRAFE_LEFT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : FORWARD STRAFE_LEFT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
FORWARD-STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY : FORWARD STRAFE_LEFT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
FORWARD-STRAFE_LEFT-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_LEFT ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
FORWARD-STRAFE_LEFT-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_LEFT ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
FORWARD-STRAFE_LEFT-ATTACK_PRIMARY-RELOAD : FORWARD STRAFE_LEFT ATTACK_PRIMARY_BUTTON RELOAD
FORWARD-STRAFE_LEFT-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-ATTACK_PRIMARY-PUTAWAYMAIN : FORWARD STRAFE_LEFT ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
FORWARD-STRAFE_LEFT-ATTACK_PRIMARY-NEW_WEAPON : FORWARD STRAFE_LEFT ATTACK_PRIMARY_BUTTON NEW_WEAPON
FORWARD-STRAFE_LEFT-ATTACK_PRIMARY : FORWARD STRAFE_LEFT ATTACK_PRIMARY_BUTTON
FORWARD-STRAFE_LEFT-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_LEFT ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-STRAFE_LEFT-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_LEFT ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-STRAFE_LEFT-ATTACK_SECONDARY-RELOAD : FORWARD STRAFE_LEFT ATTACK_SECONDARY RELOAD
FORWARD-STRAFE_LEFT-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD STRAFE_LEFT ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-STRAFE_LEFT-ATTACK_SECONDARY-NEW_WEAPON : FORWARD STRAFE_LEFT ATTACK_SECONDARY NEW_WEAPON
FORWARD-STRAFE_LEFT-ATTACK_SECONDARY : FORWARD STRAFE_LEFT ATTACK_SECONDARY
FORWARD-STRAFE_LEFT-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_LEFT RELOAD PUTAWAYMAIN
FORWARD-STRAFE_LEFT-RELOAD-NEW_WEAPON : FORWARD STRAFE_LEFT RELOAD NEW_WEAPON
FORWARD-STRAFE_LEFT-RELOAD : FORWARD STRAFE_LEFT RELOAD
FORWARD-STRAFE_LEFT-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_LEFT PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_LEFT-PUTAWAYMAIN : FORWARD STRAFE_LEFT PUTAWAYMAIN
FORWARD-STRAFE_LEFT-NEW_WEAPON : FORWARD STRAFE_LEFT NEW_WEAPON
FORWARD-STRAFE_LEFT : FORWARD STRAFE_LEFT
FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : FORWARD STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY : FORWARD STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD : FORWARD STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD
FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN : FORWARD STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY : FORWARD STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON
FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_RIGHT RUN CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN CROUCH ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD : FORWARD STRAFE_RIGHT RUN CROUCH ATTACK_SECONDARY RELOAD
FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN CROUCH ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD STRAFE_RIGHT RUN CROUCH ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN CROUCH ATTACK_SECONDARY NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY : FORWARD STRAFE_RIGHT RUN CROUCH ATTACK_SECONDARY
FORWARD-STRAFE_RIGHT-RUN-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN CROUCH RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-CROUCH-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_RIGHT RUN CROUCH RELOAD PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-RUN-CROUCH-RELOAD-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN CROUCH RELOAD NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-CROUCH-RELOAD : FORWARD STRAFE_RIGHT RUN CROUCH RELOAD
FORWARD-STRAFE_RIGHT-RUN-CROUCH-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN CROUCH PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-CROUCH-PUTAWAYMAIN : FORWARD STRAFE_RIGHT RUN CROUCH PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-RUN-CROUCH-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN CROUCH NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-CROUCH : FORWARD STRAFE_RIGHT RUN CROUCH
FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : FORWARD STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY : FORWARD STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-RELOAD : FORWARD STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD
FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN : FORWARD STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY : FORWARD STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON
FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_RIGHT RUN JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN JUMP ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-RELOAD : FORWARD STRAFE_RIGHT RUN JUMP ATTACK_SECONDARY RELOAD
FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN JUMP ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD STRAFE_RIGHT RUN JUMP ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN JUMP ATTACK_SECONDARY NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY : FORWARD STRAFE_RIGHT RUN JUMP ATTACK_SECONDARY
FORWARD-STRAFE_RIGHT-RUN-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN JUMP RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-JUMP-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_RIGHT RUN JUMP RELOAD PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-RUN-JUMP-RELOAD-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN JUMP RELOAD NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-JUMP-RELOAD : FORWARD STRAFE_RIGHT RUN JUMP RELOAD
FORWARD-STRAFE_RIGHT-RUN-JUMP-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN JUMP PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-JUMP-PUTAWAYMAIN : FORWARD STRAFE_RIGHT RUN JUMP PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-RUN-JUMP-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN JUMP NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-JUMP : FORWARD STRAFE_RIGHT RUN JUMP
FORWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : FORWARD STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
FORWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY : FORWARD STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
FORWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-RELOAD : FORWARD STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON RELOAD
FORWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-PUTAWAYMAIN : FORWARD STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY : FORWARD STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON
FORWARD-STRAFE_RIGHT-RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_RIGHT RUN ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-RUN-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-ATTACK_SECONDARY-RELOAD : FORWARD STRAFE_RIGHT RUN ATTACK_SECONDARY RELOAD
FORWARD-STRAFE_RIGHT-RUN-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD STRAFE_RIGHT RUN ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-RUN-ATTACK_SECONDARY-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN ATTACK_SECONDARY NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-ATTACK_SECONDARY : FORWARD STRAFE_RIGHT RUN ATTACK_SECONDARY
FORWARD-STRAFE_RIGHT-RUN-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_RIGHT RUN RELOAD PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-RUN-RELOAD-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN RELOAD NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-RELOAD : FORWARD STRAFE_RIGHT RUN RELOAD
FORWARD-STRAFE_RIGHT-RUN-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN-PUTAWAYMAIN : FORWARD STRAFE_RIGHT RUN PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-RUN-NEW_WEAPON : FORWARD STRAFE_RIGHT RUN NEW_WEAPON
FORWARD-STRAFE_RIGHT-RUN : FORWARD STRAFE_RIGHT RUN
FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : FORWARD STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : FORWARD STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY : FORWARD STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-RELOAD : FORWARD STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON RELOAD
FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN : FORWARD STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-NEW_WEAPON : FORWARD STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON NEW_WEAPON
FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY : FORWARD STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON
FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_RIGHT CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_RIGHT CROUCH ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-RELOAD : FORWARD STRAFE_RIGHT CROUCH ATTACK_SECONDARY RELOAD
FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT CROUCH ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD STRAFE_RIGHT CROUCH ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-NEW_WEAPON : FORWARD STRAFE_RIGHT CROUCH ATTACK_SECONDARY NEW_WEAPON
FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY : FORWARD STRAFE_RIGHT CROUCH ATTACK_SECONDARY
FORWARD-STRAFE_RIGHT-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT CROUCH RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-CROUCH-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_RIGHT CROUCH RELOAD PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-CROUCH-RELOAD-NEW_WEAPON : FORWARD STRAFE_RIGHT CROUCH RELOAD NEW_WEAPON
FORWARD-STRAFE_RIGHT-CROUCH-RELOAD : FORWARD STRAFE_RIGHT CROUCH RELOAD
FORWARD-STRAFE_RIGHT-CROUCH-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT CROUCH PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-CROUCH-PUTAWAYMAIN : FORWARD STRAFE_RIGHT CROUCH PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-CROUCH-NEW_WEAPON : FORWARD STRAFE_RIGHT CROUCH NEW_WEAPON
FORWARD-STRAFE_RIGHT-CROUCH : FORWARD STRAFE_RIGHT CROUCH
FORWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : FORWARD STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
FORWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : FORWARD STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
FORWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY : FORWARD STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
FORWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
FORWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-RELOAD : FORWARD STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON RELOAD
FORWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN : FORWARD STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-NEW_WEAPON : FORWARD STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON NEW_WEAPON
FORWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY : FORWARD STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON
FORWARD-STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_RIGHT JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_RIGHT JUMP ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-RELOAD : FORWARD STRAFE_RIGHT JUMP ATTACK_SECONDARY RELOAD
FORWARD-STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT JUMP ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD STRAFE_RIGHT JUMP ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-NEW_WEAPON : FORWARD STRAFE_RIGHT JUMP ATTACK_SECONDARY NEW_WEAPON
FORWARD-STRAFE_RIGHT-JUMP-ATTACK_SECONDARY : FORWARD STRAFE_RIGHT JUMP ATTACK_SECONDARY
FORWARD-STRAFE_RIGHT-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT JUMP RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-JUMP-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_RIGHT JUMP RELOAD PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-JUMP-RELOAD-NEW_WEAPON : FORWARD STRAFE_RIGHT JUMP RELOAD NEW_WEAPON
FORWARD-STRAFE_RIGHT-JUMP-RELOAD : FORWARD STRAFE_RIGHT JUMP RELOAD
FORWARD-STRAFE_RIGHT-JUMP-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT JUMP PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-JUMP-PUTAWAYMAIN : FORWARD STRAFE_RIGHT JUMP PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-JUMP-NEW_WEAPON : FORWARD STRAFE_RIGHT JUMP NEW_WEAPON
FORWARD-STRAFE_RIGHT-JUMP : FORWARD STRAFE_RIGHT JUMP
FORWARD-STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_RIGHT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_RIGHT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : FORWARD STRAFE_RIGHT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
FORWARD-STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD STRAFE_RIGHT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : FORWARD STRAFE_RIGHT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
FORWARD-STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY : FORWARD STRAFE_RIGHT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
FORWARD-STRAFE_RIGHT-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_RIGHT ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_RIGHT ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
FORWARD-STRAFE_RIGHT-ATTACK_PRIMARY-RELOAD : FORWARD STRAFE_RIGHT ATTACK_PRIMARY_BUTTON RELOAD
FORWARD-STRAFE_RIGHT-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-ATTACK_PRIMARY-PUTAWAYMAIN : FORWARD STRAFE_RIGHT ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-ATTACK_PRIMARY-NEW_WEAPON : FORWARD STRAFE_RIGHT ATTACK_PRIMARY_BUTTON NEW_WEAPON
FORWARD-STRAFE_RIGHT-ATTACK_PRIMARY : FORWARD STRAFE_RIGHT ATTACK_PRIMARY_BUTTON
FORWARD-STRAFE_RIGHT-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_RIGHT ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD STRAFE_RIGHT ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-STRAFE_RIGHT-ATTACK_SECONDARY-RELOAD : FORWARD STRAFE_RIGHT ATTACK_SECONDARY RELOAD
FORWARD-STRAFE_RIGHT-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD STRAFE_RIGHT ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-ATTACK_SECONDARY-NEW_WEAPON : FORWARD STRAFE_RIGHT ATTACK_SECONDARY NEW_WEAPON
FORWARD-STRAFE_RIGHT-ATTACK_SECONDARY : FORWARD STRAFE_RIGHT ATTACK_SECONDARY
FORWARD-STRAFE_RIGHT-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-RELOAD-PUTAWAYMAIN : FORWARD STRAFE_RIGHT RELOAD PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-RELOAD-NEW_WEAPON : FORWARD STRAFE_RIGHT RELOAD NEW_WEAPON
FORWARD-STRAFE_RIGHT-RELOAD : FORWARD STRAFE_RIGHT RELOAD
FORWARD-STRAFE_RIGHT-PUTAWAYMAIN-NEW_WEAPON : FORWARD STRAFE_RIGHT PUTAWAYMAIN NEW_WEAPON
FORWARD-STRAFE_RIGHT-PUTAWAYMAIN : FORWARD STRAFE_RIGHT PUTAWAYMAIN
FORWARD-STRAFE_RIGHT-NEW_WEAPON : FORWARD STRAFE_RIGHT NEW_WEAPON
FORWARD-STRAFE_RIGHT : FORWARD STRAFE_RIGHT
FORWARD-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : FORWARD RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
FORWARD-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : FORWARD RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
FORWARD-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY : FORWARD RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
FORWARD-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : FORWARD RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
FORWARD-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : FORWARD RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
FORWARD-RUN-CROUCH-ATTACK_PRIMARY-RELOAD : FORWARD RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD
FORWARD-RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD RUN CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
FORWARD-RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN : FORWARD RUN CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
FORWARD-RUN-CROUCH-ATTACK_PRIMARY-NEW_WEAPON : FORWARD RUN CROUCH ATTACK_PRIMARY_BUTTON NEW_WEAPON
FORWARD-RUN-CROUCH-ATTACK_PRIMARY : FORWARD RUN CROUCH ATTACK_PRIMARY_BUTTON
FORWARD-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD RUN CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD RUN CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD RUN CROUCH ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-RUN-CROUCH-ATTACK_SECONDARY-RELOAD : FORWARD RUN CROUCH ATTACK_SECONDARY RELOAD
FORWARD-RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD RUN CROUCH ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD RUN CROUCH ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-RUN-CROUCH-ATTACK_SECONDARY-NEW_WEAPON : FORWARD RUN CROUCH ATTACK_SECONDARY NEW_WEAPON
FORWARD-RUN-CROUCH-ATTACK_SECONDARY : FORWARD RUN CROUCH ATTACK_SECONDARY
FORWARD-RUN-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD RUN CROUCH RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-RUN-CROUCH-RELOAD-PUTAWAYMAIN : FORWARD RUN CROUCH RELOAD PUTAWAYMAIN
FORWARD-RUN-CROUCH-RELOAD-NEW_WEAPON : FORWARD RUN CROUCH RELOAD NEW_WEAPON
FORWARD-RUN-CROUCH-RELOAD : FORWARD RUN CROUCH RELOAD
FORWARD-RUN-CROUCH-PUTAWAYMAIN-NEW_WEAPON : FORWARD RUN CROUCH PUTAWAYMAIN NEW_WEAPON
FORWARD-RUN-CROUCH-PUTAWAYMAIN : FORWARD RUN CROUCH PUTAWAYMAIN
FORWARD-RUN-CROUCH-NEW_WEAPON : FORWARD RUN CROUCH NEW_WEAPON
FORWARD-RUN-CROUCH : FORWARD RUN CROUCH
FORWARD-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : FORWARD RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
FORWARD-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : FORWARD RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
FORWARD-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY : FORWARD RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
FORWARD-RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : FORWARD RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
FORWARD-RUN-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : FORWARD RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
FORWARD-RUN-JUMP-ATTACK_PRIMARY-RELOAD : FORWARD RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD
FORWARD-RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD RUN JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
FORWARD-RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN : FORWARD RUN JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
FORWARD-RUN-JUMP-ATTACK_PRIMARY-NEW_WEAPON : FORWARD RUN JUMP ATTACK_PRIMARY_BUTTON NEW_WEAPON
FORWARD-RUN-JUMP-ATTACK_PRIMARY : FORWARD RUN JUMP ATTACK_PRIMARY_BUTTON
FORWARD-RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD RUN JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD RUN JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-RUN-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD RUN JUMP ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-RUN-JUMP-ATTACK_SECONDARY-RELOAD : FORWARD RUN JUMP ATTACK_SECONDARY RELOAD
FORWARD-RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD RUN JUMP ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD RUN JUMP ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-RUN-JUMP-ATTACK_SECONDARY-NEW_WEAPON : FORWARD RUN JUMP ATTACK_SECONDARY NEW_WEAPON
FORWARD-RUN-JUMP-ATTACK_SECONDARY : FORWARD RUN JUMP ATTACK_SECONDARY
FORWARD-RUN-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD RUN JUMP RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-RUN-JUMP-RELOAD-PUTAWAYMAIN : FORWARD RUN JUMP RELOAD PUTAWAYMAIN
FORWARD-RUN-JUMP-RELOAD-NEW_WEAPON : FORWARD RUN JUMP RELOAD NEW_WEAPON
FORWARD-RUN-JUMP-RELOAD : FORWARD RUN JUMP RELOAD
FORWARD-RUN-JUMP-PUTAWAYMAIN-NEW_WEAPON : FORWARD RUN JUMP PUTAWAYMAIN NEW_WEAPON
FORWARD-RUN-JUMP-PUTAWAYMAIN : FORWARD RUN JUMP PUTAWAYMAIN
FORWARD-RUN-JUMP-NEW_WEAPON : FORWARD RUN JUMP NEW_WEAPON
FORWARD-RUN-JUMP : FORWARD RUN JUMP
FORWARD-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : FORWARD RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
FORWARD-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : FORWARD RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
FORWARD-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY : FORWARD RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
FORWARD-RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD RUN ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : FORWARD RUN ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
FORWARD-RUN-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : FORWARD RUN ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
FORWARD-RUN-ATTACK_PRIMARY-RELOAD : FORWARD RUN ATTACK_PRIMARY_BUTTON RELOAD
FORWARD-RUN-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD RUN ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
FORWARD-RUN-ATTACK_PRIMARY-PUTAWAYMAIN : FORWARD RUN ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
FORWARD-RUN-ATTACK_PRIMARY-NEW_WEAPON : FORWARD RUN ATTACK_PRIMARY_BUTTON NEW_WEAPON
FORWARD-RUN-ATTACK_PRIMARY : FORWARD RUN ATTACK_PRIMARY_BUTTON
FORWARD-RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD RUN ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD RUN ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-RUN-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD RUN ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-RUN-ATTACK_SECONDARY-RELOAD : FORWARD RUN ATTACK_SECONDARY RELOAD
FORWARD-RUN-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD RUN ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-RUN-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD RUN ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-RUN-ATTACK_SECONDARY-NEW_WEAPON : FORWARD RUN ATTACK_SECONDARY NEW_WEAPON
FORWARD-RUN-ATTACK_SECONDARY : FORWARD RUN ATTACK_SECONDARY
FORWARD-RUN-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD RUN RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-RUN-RELOAD-PUTAWAYMAIN : FORWARD RUN RELOAD PUTAWAYMAIN
FORWARD-RUN-RELOAD-NEW_WEAPON : FORWARD RUN RELOAD NEW_WEAPON
FORWARD-RUN-RELOAD : FORWARD RUN RELOAD
FORWARD-RUN-PUTAWAYMAIN-NEW_WEAPON : FORWARD RUN PUTAWAYMAIN NEW_WEAPON
FORWARD-RUN-PUTAWAYMAIN : FORWARD RUN PUTAWAYMAIN
FORWARD-RUN-NEW_WEAPON : FORWARD RUN NEW_WEAPON
FORWARD-RUN : FORWARD RUN
FORWARD-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : FORWARD CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
FORWARD-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : FORWARD CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
FORWARD-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY : FORWARD CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
FORWARD-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : FORWARD CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
FORWARD-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : FORWARD CROUCH ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
FORWARD-CROUCH-ATTACK_PRIMARY-RELOAD : FORWARD CROUCH ATTACK_PRIMARY_BUTTON RELOAD
FORWARD-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
FORWARD-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN : FORWARD CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
FORWARD-CROUCH-ATTACK_PRIMARY-NEW_WEAPON : FORWARD CROUCH ATTACK_PRIMARY_BUTTON NEW_WEAPON
FORWARD-CROUCH-ATTACK_PRIMARY : FORWARD CROUCH ATTACK_PRIMARY_BUTTON
FORWARD-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD CROUCH ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-CROUCH-ATTACK_SECONDARY-RELOAD : FORWARD CROUCH ATTACK_SECONDARY RELOAD
FORWARD-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD CROUCH ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD CROUCH ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-CROUCH-ATTACK_SECONDARY-NEW_WEAPON : FORWARD CROUCH ATTACK_SECONDARY NEW_WEAPON
FORWARD-CROUCH-ATTACK_SECONDARY : FORWARD CROUCH ATTACK_SECONDARY
FORWARD-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD CROUCH RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-CROUCH-RELOAD-PUTAWAYMAIN : FORWARD CROUCH RELOAD PUTAWAYMAIN
FORWARD-CROUCH-RELOAD-NEW_WEAPON : FORWARD CROUCH RELOAD NEW_WEAPON
FORWARD-CROUCH-RELOAD : FORWARD CROUCH RELOAD
FORWARD-CROUCH-PUTAWAYMAIN-NEW_WEAPON : FORWARD CROUCH PUTAWAYMAIN NEW_WEAPON
FORWARD-CROUCH-PUTAWAYMAIN : FORWARD CROUCH PUTAWAYMAIN
FORWARD-CROUCH-NEW_WEAPON : FORWARD CROUCH NEW_WEAPON
FORWARD-CROUCH : FORWARD CROUCH
FORWARD-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : FORWARD JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
FORWARD-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : FORWARD JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
FORWARD-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY : FORWARD JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
FORWARD-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : FORWARD JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
FORWARD-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : FORWARD JUMP ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
FORWARD-JUMP-ATTACK_PRIMARY-RELOAD : FORWARD JUMP ATTACK_PRIMARY_BUTTON RELOAD
FORWARD-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
FORWARD-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN : FORWARD JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
FORWARD-JUMP-ATTACK_PRIMARY-NEW_WEAPON : FORWARD JUMP ATTACK_PRIMARY_BUTTON NEW_WEAPON
FORWARD-JUMP-ATTACK_PRIMARY : FORWARD JUMP ATTACK_PRIMARY_BUTTON
FORWARD-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD JUMP ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-JUMP-ATTACK_SECONDARY-RELOAD : FORWARD JUMP ATTACK_SECONDARY RELOAD
FORWARD-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD JUMP ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD JUMP ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-JUMP-ATTACK_SECONDARY-NEW_WEAPON : FORWARD JUMP ATTACK_SECONDARY NEW_WEAPON
FORWARD-JUMP-ATTACK_SECONDARY : FORWARD JUMP ATTACK_SECONDARY
FORWARD-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD JUMP RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-JUMP-RELOAD-PUTAWAYMAIN : FORWARD JUMP RELOAD PUTAWAYMAIN
FORWARD-JUMP-RELOAD-NEW_WEAPON : FORWARD JUMP RELOAD NEW_WEAPON
FORWARD-JUMP-RELOAD : FORWARD JUMP RELOAD
FORWARD-JUMP-PUTAWAYMAIN-NEW_WEAPON : FORWARD JUMP PUTAWAYMAIN NEW_WEAPON
FORWARD-JUMP-PUTAWAYMAIN : FORWARD JUMP PUTAWAYMAIN
FORWARD-JUMP-NEW_WEAPON : FORWARD JUMP NEW_WEAPON
FORWARD-JUMP : FORWARD JUMP
FORWARD-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : FORWARD ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
FORWARD-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : FORWARD ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
FORWARD-ATTACK_PRIMARY-ATTACK_SECONDARY : FORWARD ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
FORWARD-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : FORWARD ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
FORWARD-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : FORWARD ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
FORWARD-ATTACK_PRIMARY-RELOAD : FORWARD ATTACK_PRIMARY_BUTTON RELOAD
FORWARD-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
FORWARD-ATTACK_PRIMARY-PUTAWAYMAIN : FORWARD ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
FORWARD-ATTACK_PRIMARY-NEW_WEAPON : FORWARD ATTACK_PRIMARY_BUTTON NEW_WEAPON
FORWARD-ATTACK_PRIMARY : FORWARD ATTACK_PRIMARY_BUTTON
FORWARD-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : FORWARD ATTACK_SECONDARY RELOAD PUTAWAYMAIN
FORWARD-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : FORWARD ATTACK_SECONDARY RELOAD NEW_WEAPON
FORWARD-ATTACK_SECONDARY-RELOAD : FORWARD ATTACK_SECONDARY RELOAD
FORWARD-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : FORWARD ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
FORWARD-ATTACK_SECONDARY-PUTAWAYMAIN : FORWARD ATTACK_SECONDARY PUTAWAYMAIN
FORWARD-ATTACK_SECONDARY-NEW_WEAPON : FORWARD ATTACK_SECONDARY NEW_WEAPON
FORWARD-ATTACK_SECONDARY : FORWARD ATTACK_SECONDARY
FORWARD-RELOAD-PUTAWAYMAIN-NEW_WEAPON : FORWARD RELOAD PUTAWAYMAIN NEW_WEAPON
FORWARD-RELOAD-PUTAWAYMAIN : FORWARD RELOAD PUTAWAYMAIN
FORWARD-RELOAD-NEW_WEAPON : FORWARD RELOAD NEW_WEAPON
FORWARD-RELOAD : FORWARD RELOAD
FORWARD-PUTAWAYMAIN-NEW_WEAPON : FORWARD PUTAWAYMAIN NEW_WEAPON
FORWARD-PUTAWAYMAIN : FORWARD PUTAWAYMAIN
FORWARD-NEW_WEAPON : FORWARD NEW_WEAPON
FORWARD : FORWARD
BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : BACKWARD STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY : BACKWARD STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD : BACKWARD STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD
BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN : BACKWARD STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY : BACKWARD STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON
BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_LEFT RUN CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN CROUCH ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD : BACKWARD STRAFE_LEFT RUN CROUCH ATTACK_SECONDARY RELOAD
BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN CROUCH ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD STRAFE_LEFT RUN CROUCH ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN CROUCH ATTACK_SECONDARY NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY : BACKWARD STRAFE_LEFT RUN CROUCH ATTACK_SECONDARY
BACKWARD-STRAFE_LEFT-RUN-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN CROUCH RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-CROUCH-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_LEFT RUN CROUCH RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-RUN-CROUCH-RELOAD-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN CROUCH RELOAD NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-CROUCH-RELOAD : BACKWARD STRAFE_LEFT RUN CROUCH RELOAD
BACKWARD-STRAFE_LEFT-RUN-CROUCH-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN CROUCH PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-CROUCH-PUTAWAYMAIN : BACKWARD STRAFE_LEFT RUN CROUCH PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-RUN-CROUCH-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN CROUCH NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-CROUCH : BACKWARD STRAFE_LEFT RUN CROUCH
BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : BACKWARD STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY : BACKWARD STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-RELOAD : BACKWARD STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD
BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN : BACKWARD STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY : BACKWARD STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON
BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_LEFT RUN JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN JUMP ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-RELOAD : BACKWARD STRAFE_LEFT RUN JUMP ATTACK_SECONDARY RELOAD
BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN JUMP ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD STRAFE_LEFT RUN JUMP ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN JUMP ATTACK_SECONDARY NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY : BACKWARD STRAFE_LEFT RUN JUMP ATTACK_SECONDARY
BACKWARD-STRAFE_LEFT-RUN-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN JUMP RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-JUMP-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_LEFT RUN JUMP RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-RUN-JUMP-RELOAD-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN JUMP RELOAD NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-JUMP-RELOAD : BACKWARD STRAFE_LEFT RUN JUMP RELOAD
BACKWARD-STRAFE_LEFT-RUN-JUMP-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN JUMP PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-JUMP-PUTAWAYMAIN : BACKWARD STRAFE_LEFT RUN JUMP PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-RUN-JUMP-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN JUMP NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-JUMP : BACKWARD STRAFE_LEFT RUN JUMP
BACKWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : BACKWARD STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
BACKWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY : BACKWARD STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
BACKWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-RELOAD : BACKWARD STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON RELOAD
BACKWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-PUTAWAYMAIN : BACKWARD STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY : BACKWARD STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON
BACKWARD-STRAFE_LEFT-RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_LEFT RUN ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-RUN-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-ATTACK_SECONDARY-RELOAD : BACKWARD STRAFE_LEFT RUN ATTACK_SECONDARY RELOAD
BACKWARD-STRAFE_LEFT-RUN-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD STRAFE_LEFT RUN ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-RUN-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN ATTACK_SECONDARY NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-ATTACK_SECONDARY : BACKWARD STRAFE_LEFT RUN ATTACK_SECONDARY
BACKWARD-STRAFE_LEFT-RUN-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_LEFT RUN RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-RUN-RELOAD-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN RELOAD NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-RELOAD : BACKWARD STRAFE_LEFT RUN RELOAD
BACKWARD-STRAFE_LEFT-RUN-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN-PUTAWAYMAIN : BACKWARD STRAFE_LEFT RUN PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-RUN-NEW_WEAPON : BACKWARD STRAFE_LEFT RUN NEW_WEAPON
BACKWARD-STRAFE_LEFT-RUN : BACKWARD STRAFE_LEFT RUN
BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : BACKWARD STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY : BACKWARD STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-RELOAD : BACKWARD STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON RELOAD
BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN : BACKWARD STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-NEW_WEAPON : BACKWARD STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON NEW_WEAPON
BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY : BACKWARD STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON
BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_LEFT CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_LEFT CROUCH ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-RELOAD : BACKWARD STRAFE_LEFT CROUCH ATTACK_SECONDARY RELOAD
BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT CROUCH ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD STRAFE_LEFT CROUCH ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD STRAFE_LEFT CROUCH ATTACK_SECONDARY NEW_WEAPON
BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_SECONDARY : BACKWARD STRAFE_LEFT CROUCH ATTACK_SECONDARY
BACKWARD-STRAFE_LEFT-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT CROUCH RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-CROUCH-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_LEFT CROUCH RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-CROUCH-RELOAD-NEW_WEAPON : BACKWARD STRAFE_LEFT CROUCH RELOAD NEW_WEAPON
BACKWARD-STRAFE_LEFT-CROUCH-RELOAD : BACKWARD STRAFE_LEFT CROUCH RELOAD
BACKWARD-STRAFE_LEFT-CROUCH-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT CROUCH PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-CROUCH-PUTAWAYMAIN : BACKWARD STRAFE_LEFT CROUCH PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-CROUCH-NEW_WEAPON : BACKWARD STRAFE_LEFT CROUCH NEW_WEAPON
BACKWARD-STRAFE_LEFT-CROUCH : BACKWARD STRAFE_LEFT CROUCH
BACKWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : BACKWARD STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
BACKWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
BACKWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY : BACKWARD STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
BACKWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
BACKWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-RELOAD : BACKWARD STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON RELOAD
BACKWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN : BACKWARD STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-NEW_WEAPON : BACKWARD STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON NEW_WEAPON
BACKWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY : BACKWARD STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON
BACKWARD-STRAFE_LEFT-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_LEFT JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_LEFT JUMP ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-STRAFE_LEFT-JUMP-ATTACK_SECONDARY-RELOAD : BACKWARD STRAFE_LEFT JUMP ATTACK_SECONDARY RELOAD
BACKWARD-STRAFE_LEFT-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT JUMP ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD STRAFE_LEFT JUMP ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-JUMP-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD STRAFE_LEFT JUMP ATTACK_SECONDARY NEW_WEAPON
BACKWARD-STRAFE_LEFT-JUMP-ATTACK_SECONDARY : BACKWARD STRAFE_LEFT JUMP ATTACK_SECONDARY
BACKWARD-STRAFE_LEFT-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT JUMP RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-JUMP-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_LEFT JUMP RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-JUMP-RELOAD-NEW_WEAPON : BACKWARD STRAFE_LEFT JUMP RELOAD NEW_WEAPON
BACKWARD-STRAFE_LEFT-JUMP-RELOAD : BACKWARD STRAFE_LEFT JUMP RELOAD
BACKWARD-STRAFE_LEFT-JUMP-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT JUMP PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-JUMP-PUTAWAYMAIN : BACKWARD STRAFE_LEFT JUMP PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-JUMP-NEW_WEAPON : BACKWARD STRAFE_LEFT JUMP NEW_WEAPON
BACKWARD-STRAFE_LEFT-JUMP : BACKWARD STRAFE_LEFT JUMP
BACKWARD-STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_LEFT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_LEFT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : BACKWARD STRAFE_LEFT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
BACKWARD-STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD STRAFE_LEFT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD STRAFE_LEFT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
BACKWARD-STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY : BACKWARD STRAFE_LEFT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
BACKWARD-STRAFE_LEFT-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_LEFT ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_LEFT ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
BACKWARD-STRAFE_LEFT-ATTACK_PRIMARY-RELOAD : BACKWARD STRAFE_LEFT ATTACK_PRIMARY_BUTTON RELOAD
BACKWARD-STRAFE_LEFT-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-ATTACK_PRIMARY-PUTAWAYMAIN : BACKWARD STRAFE_LEFT ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-ATTACK_PRIMARY-NEW_WEAPON : BACKWARD STRAFE_LEFT ATTACK_PRIMARY_BUTTON NEW_WEAPON
BACKWARD-STRAFE_LEFT-ATTACK_PRIMARY : BACKWARD STRAFE_LEFT ATTACK_PRIMARY_BUTTON
BACKWARD-STRAFE_LEFT-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_LEFT ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_LEFT ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-STRAFE_LEFT-ATTACK_SECONDARY-RELOAD : BACKWARD STRAFE_LEFT ATTACK_SECONDARY RELOAD
BACKWARD-STRAFE_LEFT-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD STRAFE_LEFT ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD STRAFE_LEFT ATTACK_SECONDARY NEW_WEAPON
BACKWARD-STRAFE_LEFT-ATTACK_SECONDARY : BACKWARD STRAFE_LEFT ATTACK_SECONDARY
BACKWARD-STRAFE_LEFT-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_LEFT RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-RELOAD-NEW_WEAPON : BACKWARD STRAFE_LEFT RELOAD NEW_WEAPON
BACKWARD-STRAFE_LEFT-RELOAD : BACKWARD STRAFE_LEFT RELOAD
BACKWARD-STRAFE_LEFT-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_LEFT PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_LEFT-PUTAWAYMAIN : BACKWARD STRAFE_LEFT PUTAWAYMAIN
BACKWARD-STRAFE_LEFT-NEW_WEAPON : BACKWARD STRAFE_LEFT NEW_WEAPON
BACKWARD-STRAFE_LEFT : BACKWARD STRAFE_LEFT
BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : BACKWARD STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY : BACKWARD STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD : BACKWARD STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD
BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY : BACKWARD STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON
BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT RUN CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN CROUCH ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD : BACKWARD STRAFE_RIGHT RUN CROUCH ATTACK_SECONDARY RELOAD
BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN CROUCH ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT RUN CROUCH ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN CROUCH ATTACK_SECONDARY NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY : BACKWARD STRAFE_RIGHT RUN CROUCH ATTACK_SECONDARY
BACKWARD-STRAFE_RIGHT-RUN-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN CROUCH RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-CROUCH-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT RUN CROUCH RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-RUN-CROUCH-RELOAD-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN CROUCH RELOAD NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-CROUCH-RELOAD : BACKWARD STRAFE_RIGHT RUN CROUCH RELOAD
BACKWARD-STRAFE_RIGHT-RUN-CROUCH-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN CROUCH PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-CROUCH-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT RUN CROUCH PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-RUN-CROUCH-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN CROUCH NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-CROUCH : BACKWARD STRAFE_RIGHT RUN CROUCH
BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : BACKWARD STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY : BACKWARD STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-RELOAD : BACKWARD STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD
BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY : BACKWARD STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON
BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT RUN JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN JUMP ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-RELOAD : BACKWARD STRAFE_RIGHT RUN JUMP ATTACK_SECONDARY RELOAD
BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN JUMP ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT RUN JUMP ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN JUMP ATTACK_SECONDARY NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY : BACKWARD STRAFE_RIGHT RUN JUMP ATTACK_SECONDARY
BACKWARD-STRAFE_RIGHT-RUN-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN JUMP RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-JUMP-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT RUN JUMP RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-RUN-JUMP-RELOAD-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN JUMP RELOAD NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-JUMP-RELOAD : BACKWARD STRAFE_RIGHT RUN JUMP RELOAD
BACKWARD-STRAFE_RIGHT-RUN-JUMP-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN JUMP PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-JUMP-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT RUN JUMP PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-RUN-JUMP-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN JUMP NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-JUMP : BACKWARD STRAFE_RIGHT RUN JUMP
BACKWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : BACKWARD STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
BACKWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY : BACKWARD STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
BACKWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-RELOAD : BACKWARD STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON RELOAD
BACKWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY : BACKWARD STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON
BACKWARD-STRAFE_RIGHT-RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT RUN ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-RUN-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-ATTACK_SECONDARY-RELOAD : BACKWARD STRAFE_RIGHT RUN ATTACK_SECONDARY RELOAD
BACKWARD-STRAFE_RIGHT-RUN-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT RUN ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-RUN-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN ATTACK_SECONDARY NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-ATTACK_SECONDARY : BACKWARD STRAFE_RIGHT RUN ATTACK_SECONDARY
BACKWARD-STRAFE_RIGHT-RUN-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT RUN RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-RUN-RELOAD-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN RELOAD NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-RELOAD : BACKWARD STRAFE_RIGHT RUN RELOAD
BACKWARD-STRAFE_RIGHT-RUN-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT RUN PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-RUN-NEW_WEAPON : BACKWARD STRAFE_RIGHT RUN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RUN : BACKWARD STRAFE_RIGHT RUN
BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : BACKWARD STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY : BACKWARD STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-RELOAD : BACKWARD STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON RELOAD
BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-NEW_WEAPON : BACKWARD STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON NEW_WEAPON
BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY : BACKWARD STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON
BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_RIGHT CROUCH ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-RELOAD : BACKWARD STRAFE_RIGHT CROUCH ATTACK_SECONDARY RELOAD
BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT CROUCH ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT CROUCH ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD STRAFE_RIGHT CROUCH ATTACK_SECONDARY NEW_WEAPON
BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY : BACKWARD STRAFE_RIGHT CROUCH ATTACK_SECONDARY
BACKWARD-STRAFE_RIGHT-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT CROUCH RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-CROUCH-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT CROUCH RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-CROUCH-RELOAD-NEW_WEAPON : BACKWARD STRAFE_RIGHT CROUCH RELOAD NEW_WEAPON
BACKWARD-STRAFE_RIGHT-CROUCH-RELOAD : BACKWARD STRAFE_RIGHT CROUCH RELOAD
BACKWARD-STRAFE_RIGHT-CROUCH-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT CROUCH PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-CROUCH-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT CROUCH PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-CROUCH-NEW_WEAPON : BACKWARD STRAFE_RIGHT CROUCH NEW_WEAPON
BACKWARD-STRAFE_RIGHT-CROUCH : BACKWARD STRAFE_RIGHT CROUCH
BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : BACKWARD STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY : BACKWARD STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-RELOAD : BACKWARD STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON RELOAD
BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-NEW_WEAPON : BACKWARD STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON NEW_WEAPON
BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY : BACKWARD STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON
BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_RIGHT JUMP ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-RELOAD : BACKWARD STRAFE_RIGHT JUMP ATTACK_SECONDARY RELOAD
BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT JUMP ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT JUMP ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD STRAFE_RIGHT JUMP ATTACK_SECONDARY NEW_WEAPON
BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_SECONDARY : BACKWARD STRAFE_RIGHT JUMP ATTACK_SECONDARY
BACKWARD-STRAFE_RIGHT-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT JUMP RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-JUMP-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT JUMP RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-JUMP-RELOAD-NEW_WEAPON : BACKWARD STRAFE_RIGHT JUMP RELOAD NEW_WEAPON
BACKWARD-STRAFE_RIGHT-JUMP-RELOAD : BACKWARD STRAFE_RIGHT JUMP RELOAD
BACKWARD-STRAFE_RIGHT-JUMP-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT JUMP PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-JUMP-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT JUMP PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-JUMP-NEW_WEAPON : BACKWARD STRAFE_RIGHT JUMP NEW_WEAPON
BACKWARD-STRAFE_RIGHT-JUMP : BACKWARD STRAFE_RIGHT JUMP
BACKWARD-STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_RIGHT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : BACKWARD STRAFE_RIGHT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
BACKWARD-STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD STRAFE_RIGHT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
BACKWARD-STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY : BACKWARD STRAFE_RIGHT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
BACKWARD-STRAFE_RIGHT-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_RIGHT ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
BACKWARD-STRAFE_RIGHT-ATTACK_PRIMARY-RELOAD : BACKWARD STRAFE_RIGHT ATTACK_PRIMARY_BUTTON RELOAD
BACKWARD-STRAFE_RIGHT-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-ATTACK_PRIMARY-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-ATTACK_PRIMARY-NEW_WEAPON : BACKWARD STRAFE_RIGHT ATTACK_PRIMARY_BUTTON NEW_WEAPON
BACKWARD-STRAFE_RIGHT-ATTACK_PRIMARY : BACKWARD STRAFE_RIGHT ATTACK_PRIMARY_BUTTON
BACKWARD-STRAFE_RIGHT-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD STRAFE_RIGHT ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-STRAFE_RIGHT-ATTACK_SECONDARY-RELOAD : BACKWARD STRAFE_RIGHT ATTACK_SECONDARY RELOAD
BACKWARD-STRAFE_RIGHT-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD STRAFE_RIGHT ATTACK_SECONDARY NEW_WEAPON
BACKWARD-STRAFE_RIGHT-ATTACK_SECONDARY : BACKWARD STRAFE_RIGHT ATTACK_SECONDARY
BACKWARD-STRAFE_RIGHT-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RELOAD-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT RELOAD PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-RELOAD-NEW_WEAPON : BACKWARD STRAFE_RIGHT RELOAD NEW_WEAPON
BACKWARD-STRAFE_RIGHT-RELOAD : BACKWARD STRAFE_RIGHT RELOAD
BACKWARD-STRAFE_RIGHT-PUTAWAYMAIN-NEW_WEAPON : BACKWARD STRAFE_RIGHT PUTAWAYMAIN NEW_WEAPON
BACKWARD-STRAFE_RIGHT-PUTAWAYMAIN : BACKWARD STRAFE_RIGHT PUTAWAYMAIN
BACKWARD-STRAFE_RIGHT-NEW_WEAPON : BACKWARD STRAFE_RIGHT NEW_WEAPON
BACKWARD-STRAFE_RIGHT : BACKWARD STRAFE_RIGHT
BACKWARD-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : BACKWARD RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
BACKWARD-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
BACKWARD-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY : BACKWARD RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
BACKWARD-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : BACKWARD RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
BACKWARD-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : BACKWARD RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
BACKWARD-RUN-CROUCH-ATTACK_PRIMARY-RELOAD : BACKWARD RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD
BACKWARD-RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD RUN CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
BACKWARD-RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN : BACKWARD RUN CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
BACKWARD-RUN-CROUCH-ATTACK_PRIMARY-NEW_WEAPON : BACKWARD RUN CROUCH ATTACK_PRIMARY_BUTTON NEW_WEAPON
BACKWARD-RUN-CROUCH-ATTACK_PRIMARY : BACKWARD RUN CROUCH ATTACK_PRIMARY_BUTTON
BACKWARD-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD RUN CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD RUN CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD RUN CROUCH ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-RUN-CROUCH-ATTACK_SECONDARY-RELOAD : BACKWARD RUN CROUCH ATTACK_SECONDARY RELOAD
BACKWARD-RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD RUN CROUCH ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD RUN CROUCH ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-RUN-CROUCH-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD RUN CROUCH ATTACK_SECONDARY NEW_WEAPON
BACKWARD-RUN-CROUCH-ATTACK_SECONDARY : BACKWARD RUN CROUCH ATTACK_SECONDARY
BACKWARD-RUN-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD RUN CROUCH RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-RUN-CROUCH-RELOAD-PUTAWAYMAIN : BACKWARD RUN CROUCH RELOAD PUTAWAYMAIN
BACKWARD-RUN-CROUCH-RELOAD-NEW_WEAPON : BACKWARD RUN CROUCH RELOAD NEW_WEAPON
BACKWARD-RUN-CROUCH-RELOAD : BACKWARD RUN CROUCH RELOAD
BACKWARD-RUN-CROUCH-PUTAWAYMAIN-NEW_WEAPON : BACKWARD RUN CROUCH PUTAWAYMAIN NEW_WEAPON
BACKWARD-RUN-CROUCH-PUTAWAYMAIN : BACKWARD RUN CROUCH PUTAWAYMAIN
BACKWARD-RUN-CROUCH-NEW_WEAPON : BACKWARD RUN CROUCH NEW_WEAPON
BACKWARD-RUN-CROUCH : BACKWARD RUN CROUCH
BACKWARD-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : BACKWARD RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
BACKWARD-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
BACKWARD-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY : BACKWARD RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
BACKWARD-RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : BACKWARD RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
BACKWARD-RUN-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : BACKWARD RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
BACKWARD-RUN-JUMP-ATTACK_PRIMARY-RELOAD : BACKWARD RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD
BACKWARD-RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD RUN JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
BACKWARD-RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN : BACKWARD RUN JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
BACKWARD-RUN-JUMP-ATTACK_PRIMARY-NEW_WEAPON : BACKWARD RUN JUMP ATTACK_PRIMARY_BUTTON NEW_WEAPON
BACKWARD-RUN-JUMP-ATTACK_PRIMARY : BACKWARD RUN JUMP ATTACK_PRIMARY_BUTTON
BACKWARD-RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD RUN JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD RUN JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-RUN-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD RUN JUMP ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-RUN-JUMP-ATTACK_SECONDARY-RELOAD : BACKWARD RUN JUMP ATTACK_SECONDARY RELOAD
BACKWARD-RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD RUN JUMP ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD RUN JUMP ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-RUN-JUMP-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD RUN JUMP ATTACK_SECONDARY NEW_WEAPON
BACKWARD-RUN-JUMP-ATTACK_SECONDARY : BACKWARD RUN JUMP ATTACK_SECONDARY
BACKWARD-RUN-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD RUN JUMP RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-RUN-JUMP-RELOAD-PUTAWAYMAIN : BACKWARD RUN JUMP RELOAD PUTAWAYMAIN
BACKWARD-RUN-JUMP-RELOAD-NEW_WEAPON : BACKWARD RUN JUMP RELOAD NEW_WEAPON
BACKWARD-RUN-JUMP-RELOAD : BACKWARD RUN JUMP RELOAD
BACKWARD-RUN-JUMP-PUTAWAYMAIN-NEW_WEAPON : BACKWARD RUN JUMP PUTAWAYMAIN NEW_WEAPON
BACKWARD-RUN-JUMP-PUTAWAYMAIN : BACKWARD RUN JUMP PUTAWAYMAIN
BACKWARD-RUN-JUMP-NEW_WEAPON : BACKWARD RUN JUMP NEW_WEAPON
BACKWARD-RUN-JUMP : BACKWARD RUN JUMP
BACKWARD-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : BACKWARD RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
BACKWARD-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
BACKWARD-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY : BACKWARD RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
BACKWARD-RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD RUN ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : BACKWARD RUN ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
BACKWARD-RUN-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : BACKWARD RUN ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
BACKWARD-RUN-ATTACK_PRIMARY-RELOAD : BACKWARD RUN ATTACK_PRIMARY_BUTTON RELOAD
BACKWARD-RUN-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD RUN ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
BACKWARD-RUN-ATTACK_PRIMARY-PUTAWAYMAIN : BACKWARD RUN ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
BACKWARD-RUN-ATTACK_PRIMARY-NEW_WEAPON : BACKWARD RUN ATTACK_PRIMARY_BUTTON NEW_WEAPON
BACKWARD-RUN-ATTACK_PRIMARY : BACKWARD RUN ATTACK_PRIMARY_BUTTON
BACKWARD-RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD RUN ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD RUN ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-RUN-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD RUN ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-RUN-ATTACK_SECONDARY-RELOAD : BACKWARD RUN ATTACK_SECONDARY RELOAD
BACKWARD-RUN-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD RUN ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-RUN-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD RUN ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-RUN-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD RUN ATTACK_SECONDARY NEW_WEAPON
BACKWARD-RUN-ATTACK_SECONDARY : BACKWARD RUN ATTACK_SECONDARY
BACKWARD-RUN-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD RUN RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-RUN-RELOAD-PUTAWAYMAIN : BACKWARD RUN RELOAD PUTAWAYMAIN
BACKWARD-RUN-RELOAD-NEW_WEAPON : BACKWARD RUN RELOAD NEW_WEAPON
BACKWARD-RUN-RELOAD : BACKWARD RUN RELOAD
BACKWARD-RUN-PUTAWAYMAIN-NEW_WEAPON : BACKWARD RUN PUTAWAYMAIN NEW_WEAPON
BACKWARD-RUN-PUTAWAYMAIN : BACKWARD RUN PUTAWAYMAIN
BACKWARD-RUN-NEW_WEAPON : BACKWARD RUN NEW_WEAPON
BACKWARD-RUN : BACKWARD RUN
BACKWARD-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : BACKWARD CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
BACKWARD-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
BACKWARD-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY : BACKWARD CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
BACKWARD-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : BACKWARD CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
BACKWARD-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : BACKWARD CROUCH ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
BACKWARD-CROUCH-ATTACK_PRIMARY-RELOAD : BACKWARD CROUCH ATTACK_PRIMARY_BUTTON RELOAD
BACKWARD-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
BACKWARD-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN : BACKWARD CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
BACKWARD-CROUCH-ATTACK_PRIMARY-NEW_WEAPON : BACKWARD CROUCH ATTACK_PRIMARY_BUTTON NEW_WEAPON
BACKWARD-CROUCH-ATTACK_PRIMARY : BACKWARD CROUCH ATTACK_PRIMARY_BUTTON
BACKWARD-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD CROUCH ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-CROUCH-ATTACK_SECONDARY-RELOAD : BACKWARD CROUCH ATTACK_SECONDARY RELOAD
BACKWARD-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD CROUCH ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD CROUCH ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-CROUCH-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD CROUCH ATTACK_SECONDARY NEW_WEAPON
BACKWARD-CROUCH-ATTACK_SECONDARY : BACKWARD CROUCH ATTACK_SECONDARY
BACKWARD-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD CROUCH RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-CROUCH-RELOAD-PUTAWAYMAIN : BACKWARD CROUCH RELOAD PUTAWAYMAIN
BACKWARD-CROUCH-RELOAD-NEW_WEAPON : BACKWARD CROUCH RELOAD NEW_WEAPON
BACKWARD-CROUCH-RELOAD : BACKWARD CROUCH RELOAD
BACKWARD-CROUCH-PUTAWAYMAIN-NEW_WEAPON : BACKWARD CROUCH PUTAWAYMAIN NEW_WEAPON
BACKWARD-CROUCH-PUTAWAYMAIN : BACKWARD CROUCH PUTAWAYMAIN
BACKWARD-CROUCH-NEW_WEAPON : BACKWARD CROUCH NEW_WEAPON
BACKWARD-CROUCH : BACKWARD CROUCH
BACKWARD-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : BACKWARD JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
BACKWARD-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
BACKWARD-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY : BACKWARD JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
BACKWARD-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : BACKWARD JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
BACKWARD-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : BACKWARD JUMP ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
BACKWARD-JUMP-ATTACK_PRIMARY-RELOAD : BACKWARD JUMP ATTACK_PRIMARY_BUTTON RELOAD
BACKWARD-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
BACKWARD-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN : BACKWARD JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
BACKWARD-JUMP-ATTACK_PRIMARY-NEW_WEAPON : BACKWARD JUMP ATTACK_PRIMARY_BUTTON NEW_WEAPON
BACKWARD-JUMP-ATTACK_PRIMARY : BACKWARD JUMP ATTACK_PRIMARY_BUTTON
BACKWARD-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD JUMP ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-JUMP-ATTACK_SECONDARY-RELOAD : BACKWARD JUMP ATTACK_SECONDARY RELOAD
BACKWARD-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD JUMP ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD JUMP ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-JUMP-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD JUMP ATTACK_SECONDARY NEW_WEAPON
BACKWARD-JUMP-ATTACK_SECONDARY : BACKWARD JUMP ATTACK_SECONDARY
BACKWARD-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD JUMP RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-JUMP-RELOAD-PUTAWAYMAIN : BACKWARD JUMP RELOAD PUTAWAYMAIN
BACKWARD-JUMP-RELOAD-NEW_WEAPON : BACKWARD JUMP RELOAD NEW_WEAPON
BACKWARD-JUMP-RELOAD : BACKWARD JUMP RELOAD
BACKWARD-JUMP-PUTAWAYMAIN-NEW_WEAPON : BACKWARD JUMP PUTAWAYMAIN NEW_WEAPON
BACKWARD-JUMP-PUTAWAYMAIN : BACKWARD JUMP PUTAWAYMAIN
BACKWARD-JUMP-NEW_WEAPON : BACKWARD JUMP NEW_WEAPON
BACKWARD-JUMP : BACKWARD JUMP
BACKWARD-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : BACKWARD ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
BACKWARD-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
BACKWARD-ATTACK_PRIMARY-ATTACK_SECONDARY : BACKWARD ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
BACKWARD-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : BACKWARD ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
BACKWARD-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : BACKWARD ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
BACKWARD-ATTACK_PRIMARY-RELOAD : BACKWARD ATTACK_PRIMARY_BUTTON RELOAD
BACKWARD-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
BACKWARD-ATTACK_PRIMARY-PUTAWAYMAIN : BACKWARD ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
BACKWARD-ATTACK_PRIMARY-NEW_WEAPON : BACKWARD ATTACK_PRIMARY_BUTTON NEW_WEAPON
BACKWARD-ATTACK_PRIMARY : BACKWARD ATTACK_PRIMARY_BUTTON
BACKWARD-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : BACKWARD ATTACK_SECONDARY RELOAD PUTAWAYMAIN
BACKWARD-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : BACKWARD ATTACK_SECONDARY RELOAD NEW_WEAPON
BACKWARD-ATTACK_SECONDARY-RELOAD : BACKWARD ATTACK_SECONDARY RELOAD
BACKWARD-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : BACKWARD ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
BACKWARD-ATTACK_SECONDARY-PUTAWAYMAIN : BACKWARD ATTACK_SECONDARY PUTAWAYMAIN
BACKWARD-ATTACK_SECONDARY-NEW_WEAPON : BACKWARD ATTACK_SECONDARY NEW_WEAPON
BACKWARD-ATTACK_SECONDARY : BACKWARD ATTACK_SECONDARY
BACKWARD-RELOAD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD RELOAD PUTAWAYMAIN NEW_WEAPON
BACKWARD-RELOAD-PUTAWAYMAIN : BACKWARD RELOAD PUTAWAYMAIN
BACKWARD-RELOAD-NEW_WEAPON : BACKWARD RELOAD NEW_WEAPON
BACKWARD-RELOAD : BACKWARD RELOAD
BACKWARD-PUTAWAYMAIN-NEW_WEAPON : BACKWARD PUTAWAYMAIN NEW_WEAPON
BACKWARD-PUTAWAYMAIN : BACKWARD PUTAWAYMAIN
BACKWARD-NEW_WEAPON : BACKWARD NEW_WEAPON
BACKWARD : BACKWARD
STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY : STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD : STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD
STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN : STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-NEW_WEAPON : STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON NEW_WEAPON
STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY : STRAFE_LEFT RUN CROUCH ATTACK_PRIMARY_BUTTON
STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT RUN CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : STRAFE_LEFT RUN CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN
STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : STRAFE_LEFT RUN CROUCH ATTACK_SECONDARY RELOAD NEW_WEAPON
STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD : STRAFE_LEFT RUN CROUCH ATTACK_SECONDARY RELOAD
STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT RUN CROUCH ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN : STRAFE_LEFT RUN CROUCH ATTACK_SECONDARY PUTAWAYMAIN
STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-NEW_WEAPON : STRAFE_LEFT RUN CROUCH ATTACK_SECONDARY NEW_WEAPON
STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY : STRAFE_LEFT RUN CROUCH ATTACK_SECONDARY
STRAFE_LEFT-RUN-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT RUN CROUCH RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-RUN-CROUCH-RELOAD-PUTAWAYMAIN : STRAFE_LEFT RUN CROUCH RELOAD PUTAWAYMAIN
STRAFE_LEFT-RUN-CROUCH-RELOAD-NEW_WEAPON : STRAFE_LEFT RUN CROUCH RELOAD NEW_WEAPON
STRAFE_LEFT-RUN-CROUCH-RELOAD : STRAFE_LEFT RUN CROUCH RELOAD
STRAFE_LEFT-RUN-CROUCH-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT RUN CROUCH PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-RUN-CROUCH-PUTAWAYMAIN : STRAFE_LEFT RUN CROUCH PUTAWAYMAIN
STRAFE_LEFT-RUN-CROUCH-NEW_WEAPON : STRAFE_LEFT RUN CROUCH NEW_WEAPON
STRAFE_LEFT-RUN-CROUCH : STRAFE_LEFT RUN CROUCH
STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY : STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-RELOAD : STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD
STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN : STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-NEW_WEAPON : STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON NEW_WEAPON
STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY : STRAFE_LEFT RUN JUMP ATTACK_PRIMARY_BUTTON
STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT RUN JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : STRAFE_LEFT RUN JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN
STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : STRAFE_LEFT RUN JUMP ATTACK_SECONDARY RELOAD NEW_WEAPON
STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-RELOAD : STRAFE_LEFT RUN JUMP ATTACK_SECONDARY RELOAD
STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT RUN JUMP ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN : STRAFE_LEFT RUN JUMP ATTACK_SECONDARY PUTAWAYMAIN
STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-NEW_WEAPON : STRAFE_LEFT RUN JUMP ATTACK_SECONDARY NEW_WEAPON
STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY : STRAFE_LEFT RUN JUMP ATTACK_SECONDARY
STRAFE_LEFT-RUN-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT RUN JUMP RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-RUN-JUMP-RELOAD-PUTAWAYMAIN : STRAFE_LEFT RUN JUMP RELOAD PUTAWAYMAIN
STRAFE_LEFT-RUN-JUMP-RELOAD-NEW_WEAPON : STRAFE_LEFT RUN JUMP RELOAD NEW_WEAPON
STRAFE_LEFT-RUN-JUMP-RELOAD : STRAFE_LEFT RUN JUMP RELOAD
STRAFE_LEFT-RUN-JUMP-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT RUN JUMP PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-RUN-JUMP-PUTAWAYMAIN : STRAFE_LEFT RUN JUMP PUTAWAYMAIN
STRAFE_LEFT-RUN-JUMP-NEW_WEAPON : STRAFE_LEFT RUN JUMP NEW_WEAPON
STRAFE_LEFT-RUN-JUMP : STRAFE_LEFT RUN JUMP
STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY : STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
STRAFE_LEFT-RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
STRAFE_LEFT-RUN-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
STRAFE_LEFT-RUN-ATTACK_PRIMARY-RELOAD : STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON RELOAD
STRAFE_LEFT-RUN-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-RUN-ATTACK_PRIMARY-PUTAWAYMAIN : STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
STRAFE_LEFT-RUN-ATTACK_PRIMARY-NEW_WEAPON : STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON NEW_WEAPON
STRAFE_LEFT-RUN-ATTACK_PRIMARY : STRAFE_LEFT RUN ATTACK_PRIMARY_BUTTON
STRAFE_LEFT-RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT RUN ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : STRAFE_LEFT RUN ATTACK_SECONDARY RELOAD PUTAWAYMAIN
STRAFE_LEFT-RUN-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : STRAFE_LEFT RUN ATTACK_SECONDARY RELOAD NEW_WEAPON
STRAFE_LEFT-RUN-ATTACK_SECONDARY-RELOAD : STRAFE_LEFT RUN ATTACK_SECONDARY RELOAD
STRAFE_LEFT-RUN-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT RUN ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-RUN-ATTACK_SECONDARY-PUTAWAYMAIN : STRAFE_LEFT RUN ATTACK_SECONDARY PUTAWAYMAIN
STRAFE_LEFT-RUN-ATTACK_SECONDARY-NEW_WEAPON : STRAFE_LEFT RUN ATTACK_SECONDARY NEW_WEAPON
STRAFE_LEFT-RUN-ATTACK_SECONDARY : STRAFE_LEFT RUN ATTACK_SECONDARY
STRAFE_LEFT-RUN-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT RUN RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-RUN-RELOAD-PUTAWAYMAIN : STRAFE_LEFT RUN RELOAD PUTAWAYMAIN
STRAFE_LEFT-RUN-RELOAD-NEW_WEAPON : STRAFE_LEFT RUN RELOAD NEW_WEAPON
STRAFE_LEFT-RUN-RELOAD : STRAFE_LEFT RUN RELOAD
STRAFE_LEFT-RUN-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT RUN PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-RUN-PUTAWAYMAIN : STRAFE_LEFT RUN PUTAWAYMAIN
STRAFE_LEFT-RUN-NEW_WEAPON : STRAFE_LEFT RUN NEW_WEAPON
STRAFE_LEFT-RUN : STRAFE_LEFT RUN
STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY : STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-RELOAD : STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON RELOAD
STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN : STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-NEW_WEAPON : STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON NEW_WEAPON
STRAFE_LEFT-CROUCH-ATTACK_PRIMARY : STRAFE_LEFT CROUCH ATTACK_PRIMARY_BUTTON
STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : STRAFE_LEFT CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN
STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : STRAFE_LEFT CROUCH ATTACK_SECONDARY RELOAD NEW_WEAPON
STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-RELOAD : STRAFE_LEFT CROUCH ATTACK_SECONDARY RELOAD
STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT CROUCH ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN : STRAFE_LEFT CROUCH ATTACK_SECONDARY PUTAWAYMAIN
STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-NEW_WEAPON : STRAFE_LEFT CROUCH ATTACK_SECONDARY NEW_WEAPON
STRAFE_LEFT-CROUCH-ATTACK_SECONDARY : STRAFE_LEFT CROUCH ATTACK_SECONDARY
STRAFE_LEFT-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT CROUCH RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-CROUCH-RELOAD-PUTAWAYMAIN : STRAFE_LEFT CROUCH RELOAD PUTAWAYMAIN
STRAFE_LEFT-CROUCH-RELOAD-NEW_WEAPON : STRAFE_LEFT CROUCH RELOAD NEW_WEAPON
STRAFE_LEFT-CROUCH-RELOAD : STRAFE_LEFT CROUCH RELOAD
STRAFE_LEFT-CROUCH-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT CROUCH PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-CROUCH-PUTAWAYMAIN : STRAFE_LEFT CROUCH PUTAWAYMAIN
STRAFE_LEFT-CROUCH-NEW_WEAPON : STRAFE_LEFT CROUCH NEW_WEAPON
STRAFE_LEFT-CROUCH : STRAFE_LEFT CROUCH
STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY : STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
STRAFE_LEFT-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
STRAFE_LEFT-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
STRAFE_LEFT-JUMP-ATTACK_PRIMARY-RELOAD : STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON RELOAD
STRAFE_LEFT-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN : STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
STRAFE_LEFT-JUMP-ATTACK_PRIMARY-NEW_WEAPON : STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON NEW_WEAPON
STRAFE_LEFT-JUMP-ATTACK_PRIMARY : STRAFE_LEFT JUMP ATTACK_PRIMARY_BUTTON
STRAFE_LEFT-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : STRAFE_LEFT JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN
STRAFE_LEFT-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : STRAFE_LEFT JUMP ATTACK_SECONDARY RELOAD NEW_WEAPON
STRAFE_LEFT-JUMP-ATTACK_SECONDARY-RELOAD : STRAFE_LEFT JUMP ATTACK_SECONDARY RELOAD
STRAFE_LEFT-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT JUMP ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN : STRAFE_LEFT JUMP ATTACK_SECONDARY PUTAWAYMAIN
STRAFE_LEFT-JUMP-ATTACK_SECONDARY-NEW_WEAPON : STRAFE_LEFT JUMP ATTACK_SECONDARY NEW_WEAPON
STRAFE_LEFT-JUMP-ATTACK_SECONDARY : STRAFE_LEFT JUMP ATTACK_SECONDARY
STRAFE_LEFT-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT JUMP RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-JUMP-RELOAD-PUTAWAYMAIN : STRAFE_LEFT JUMP RELOAD PUTAWAYMAIN
STRAFE_LEFT-JUMP-RELOAD-NEW_WEAPON : STRAFE_LEFT JUMP RELOAD NEW_WEAPON
STRAFE_LEFT-JUMP-RELOAD : STRAFE_LEFT JUMP RELOAD
STRAFE_LEFT-JUMP-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT JUMP PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-JUMP-PUTAWAYMAIN : STRAFE_LEFT JUMP PUTAWAYMAIN
STRAFE_LEFT-JUMP-NEW_WEAPON : STRAFE_LEFT JUMP NEW_WEAPON
STRAFE_LEFT-JUMP : STRAFE_LEFT JUMP
STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : STRAFE_LEFT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : STRAFE_LEFT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : STRAFE_LEFT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : STRAFE_LEFT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : STRAFE_LEFT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY : STRAFE_LEFT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
STRAFE_LEFT-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : STRAFE_LEFT ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
STRAFE_LEFT-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : STRAFE_LEFT ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
STRAFE_LEFT-ATTACK_PRIMARY-RELOAD : STRAFE_LEFT ATTACK_PRIMARY_BUTTON RELOAD
STRAFE_LEFT-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-ATTACK_PRIMARY-PUTAWAYMAIN : STRAFE_LEFT ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
STRAFE_LEFT-ATTACK_PRIMARY-NEW_WEAPON : STRAFE_LEFT ATTACK_PRIMARY_BUTTON NEW_WEAPON
STRAFE_LEFT-ATTACK_PRIMARY : STRAFE_LEFT ATTACK_PRIMARY_BUTTON
STRAFE_LEFT-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : STRAFE_LEFT ATTACK_SECONDARY RELOAD PUTAWAYMAIN
STRAFE_LEFT-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : STRAFE_LEFT ATTACK_SECONDARY RELOAD NEW_WEAPON
STRAFE_LEFT-ATTACK_SECONDARY-RELOAD : STRAFE_LEFT ATTACK_SECONDARY RELOAD
STRAFE_LEFT-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-ATTACK_SECONDARY-PUTAWAYMAIN : STRAFE_LEFT ATTACK_SECONDARY PUTAWAYMAIN
STRAFE_LEFT-ATTACK_SECONDARY-NEW_WEAPON : STRAFE_LEFT ATTACK_SECONDARY NEW_WEAPON
STRAFE_LEFT-ATTACK_SECONDARY : STRAFE_LEFT ATTACK_SECONDARY
STRAFE_LEFT-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-RELOAD-PUTAWAYMAIN : STRAFE_LEFT RELOAD PUTAWAYMAIN
STRAFE_LEFT-RELOAD-NEW_WEAPON : STRAFE_LEFT RELOAD NEW_WEAPON
STRAFE_LEFT-RELOAD : STRAFE_LEFT RELOAD
STRAFE_LEFT-PUTAWAYMAIN-NEW_WEAPON : STRAFE_LEFT PUTAWAYMAIN NEW_WEAPON
STRAFE_LEFT-PUTAWAYMAIN : STRAFE_LEFT PUTAWAYMAIN
STRAFE_LEFT-NEW_WEAPON : STRAFE_LEFT NEW_WEAPON
STRAFE_LEFT : STRAFE_LEFT
STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY : STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD : STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD
STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN : STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-NEW_WEAPON : STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON NEW_WEAPON
STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY : STRAFE_RIGHT RUN CROUCH ATTACK_PRIMARY_BUTTON
STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT RUN CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : STRAFE_RIGHT RUN CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN
STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : STRAFE_RIGHT RUN CROUCH ATTACK_SECONDARY RELOAD NEW_WEAPON
STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD : STRAFE_RIGHT RUN CROUCH ATTACK_SECONDARY RELOAD
STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT RUN CROUCH ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN : STRAFE_RIGHT RUN CROUCH ATTACK_SECONDARY PUTAWAYMAIN
STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-NEW_WEAPON : STRAFE_RIGHT RUN CROUCH ATTACK_SECONDARY NEW_WEAPON
STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY : STRAFE_RIGHT RUN CROUCH ATTACK_SECONDARY
STRAFE_RIGHT-RUN-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT RUN CROUCH RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-RUN-CROUCH-RELOAD-PUTAWAYMAIN : STRAFE_RIGHT RUN CROUCH RELOAD PUTAWAYMAIN
STRAFE_RIGHT-RUN-CROUCH-RELOAD-NEW_WEAPON : STRAFE_RIGHT RUN CROUCH RELOAD NEW_WEAPON
STRAFE_RIGHT-RUN-CROUCH-RELOAD : STRAFE_RIGHT RUN CROUCH RELOAD
STRAFE_RIGHT-RUN-CROUCH-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT RUN CROUCH PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-RUN-CROUCH-PUTAWAYMAIN : STRAFE_RIGHT RUN CROUCH PUTAWAYMAIN
STRAFE_RIGHT-RUN-CROUCH-NEW_WEAPON : STRAFE_RIGHT RUN CROUCH NEW_WEAPON
STRAFE_RIGHT-RUN-CROUCH : STRAFE_RIGHT RUN CROUCH
STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY : STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-RELOAD : STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD
STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN : STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-NEW_WEAPON : STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON NEW_WEAPON
STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY : STRAFE_RIGHT RUN JUMP ATTACK_PRIMARY_BUTTON
STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT RUN JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : STRAFE_RIGHT RUN JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN
STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : STRAFE_RIGHT RUN JUMP ATTACK_SECONDARY RELOAD NEW_WEAPON
STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-RELOAD : STRAFE_RIGHT RUN JUMP ATTACK_SECONDARY RELOAD
STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT RUN JUMP ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN : STRAFE_RIGHT RUN JUMP ATTACK_SECONDARY PUTAWAYMAIN
STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-NEW_WEAPON : STRAFE_RIGHT RUN JUMP ATTACK_SECONDARY NEW_WEAPON
STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY : STRAFE_RIGHT RUN JUMP ATTACK_SECONDARY
STRAFE_RIGHT-RUN-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT RUN JUMP RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-RUN-JUMP-RELOAD-PUTAWAYMAIN : STRAFE_RIGHT RUN JUMP RELOAD PUTAWAYMAIN
STRAFE_RIGHT-RUN-JUMP-RELOAD-NEW_WEAPON : STRAFE_RIGHT RUN JUMP RELOAD NEW_WEAPON
STRAFE_RIGHT-RUN-JUMP-RELOAD : STRAFE_RIGHT RUN JUMP RELOAD
STRAFE_RIGHT-RUN-JUMP-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT RUN JUMP PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-RUN-JUMP-PUTAWAYMAIN : STRAFE_RIGHT RUN JUMP PUTAWAYMAIN
STRAFE_RIGHT-RUN-JUMP-NEW_WEAPON : STRAFE_RIGHT RUN JUMP NEW_WEAPON
STRAFE_RIGHT-RUN-JUMP : STRAFE_RIGHT RUN JUMP
STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY : STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
STRAFE_RIGHT-RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
STRAFE_RIGHT-RUN-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
STRAFE_RIGHT-RUN-ATTACK_PRIMARY-RELOAD : STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON RELOAD
STRAFE_RIGHT-RUN-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-RUN-ATTACK_PRIMARY-PUTAWAYMAIN : STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
STRAFE_RIGHT-RUN-ATTACK_PRIMARY-NEW_WEAPON : STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON NEW_WEAPON
STRAFE_RIGHT-RUN-ATTACK_PRIMARY : STRAFE_RIGHT RUN ATTACK_PRIMARY_BUTTON
STRAFE_RIGHT-RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT RUN ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : STRAFE_RIGHT RUN ATTACK_SECONDARY RELOAD PUTAWAYMAIN
STRAFE_RIGHT-RUN-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : STRAFE_RIGHT RUN ATTACK_SECONDARY RELOAD NEW_WEAPON
STRAFE_RIGHT-RUN-ATTACK_SECONDARY-RELOAD : STRAFE_RIGHT RUN ATTACK_SECONDARY RELOAD
STRAFE_RIGHT-RUN-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT RUN ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-RUN-ATTACK_SECONDARY-PUTAWAYMAIN : STRAFE_RIGHT RUN ATTACK_SECONDARY PUTAWAYMAIN
STRAFE_RIGHT-RUN-ATTACK_SECONDARY-NEW_WEAPON : STRAFE_RIGHT RUN ATTACK_SECONDARY NEW_WEAPON
STRAFE_RIGHT-RUN-ATTACK_SECONDARY : STRAFE_RIGHT RUN ATTACK_SECONDARY
STRAFE_RIGHT-RUN-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT RUN RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-RUN-RELOAD-PUTAWAYMAIN : STRAFE_RIGHT RUN RELOAD PUTAWAYMAIN
STRAFE_RIGHT-RUN-RELOAD-NEW_WEAPON : STRAFE_RIGHT RUN RELOAD NEW_WEAPON
STRAFE_RIGHT-RUN-RELOAD : STRAFE_RIGHT RUN RELOAD
STRAFE_RIGHT-RUN-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT RUN PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-RUN-PUTAWAYMAIN : STRAFE_RIGHT RUN PUTAWAYMAIN
STRAFE_RIGHT-RUN-NEW_WEAPON : STRAFE_RIGHT RUN NEW_WEAPON
STRAFE_RIGHT-RUN : STRAFE_RIGHT RUN
STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY : STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-RELOAD : STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON RELOAD
STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN : STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-NEW_WEAPON : STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON NEW_WEAPON
STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY : STRAFE_RIGHT CROUCH ATTACK_PRIMARY_BUTTON
STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : STRAFE_RIGHT CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN
STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : STRAFE_RIGHT CROUCH ATTACK_SECONDARY RELOAD NEW_WEAPON
STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-RELOAD : STRAFE_RIGHT CROUCH ATTACK_SECONDARY RELOAD
STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT CROUCH ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN : STRAFE_RIGHT CROUCH ATTACK_SECONDARY PUTAWAYMAIN
STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-NEW_WEAPON : STRAFE_RIGHT CROUCH ATTACK_SECONDARY NEW_WEAPON
STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY : STRAFE_RIGHT CROUCH ATTACK_SECONDARY
STRAFE_RIGHT-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT CROUCH RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-CROUCH-RELOAD-PUTAWAYMAIN : STRAFE_RIGHT CROUCH RELOAD PUTAWAYMAIN
STRAFE_RIGHT-CROUCH-RELOAD-NEW_WEAPON : STRAFE_RIGHT CROUCH RELOAD NEW_WEAPON
STRAFE_RIGHT-CROUCH-RELOAD : STRAFE_RIGHT CROUCH RELOAD
STRAFE_RIGHT-CROUCH-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT CROUCH PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-CROUCH-PUTAWAYMAIN : STRAFE_RIGHT CROUCH PUTAWAYMAIN
STRAFE_RIGHT-CROUCH-NEW_WEAPON : STRAFE_RIGHT CROUCH NEW_WEAPON
STRAFE_RIGHT-CROUCH : STRAFE_RIGHT CROUCH
STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY : STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-RELOAD : STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON RELOAD
STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN : STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-NEW_WEAPON : STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON NEW_WEAPON
STRAFE_RIGHT-JUMP-ATTACK_PRIMARY : STRAFE_RIGHT JUMP ATTACK_PRIMARY_BUTTON
STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : STRAFE_RIGHT JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN
STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : STRAFE_RIGHT JUMP ATTACK_SECONDARY RELOAD NEW_WEAPON
STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-RELOAD : STRAFE_RIGHT JUMP ATTACK_SECONDARY RELOAD
STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT JUMP ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN : STRAFE_RIGHT JUMP ATTACK_SECONDARY PUTAWAYMAIN
STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-NEW_WEAPON : STRAFE_RIGHT JUMP ATTACK_SECONDARY NEW_WEAPON
STRAFE_RIGHT-JUMP-ATTACK_SECONDARY : STRAFE_RIGHT JUMP ATTACK_SECONDARY
STRAFE_RIGHT-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT JUMP RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-JUMP-RELOAD-PUTAWAYMAIN : STRAFE_RIGHT JUMP RELOAD PUTAWAYMAIN
STRAFE_RIGHT-JUMP-RELOAD-NEW_WEAPON : STRAFE_RIGHT JUMP RELOAD NEW_WEAPON
STRAFE_RIGHT-JUMP-RELOAD : STRAFE_RIGHT JUMP RELOAD
STRAFE_RIGHT-JUMP-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT JUMP PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-JUMP-PUTAWAYMAIN : STRAFE_RIGHT JUMP PUTAWAYMAIN
STRAFE_RIGHT-JUMP-NEW_WEAPON : STRAFE_RIGHT JUMP NEW_WEAPON
STRAFE_RIGHT-JUMP : STRAFE_RIGHT JUMP
STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : STRAFE_RIGHT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : STRAFE_RIGHT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : STRAFE_RIGHT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : STRAFE_RIGHT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : STRAFE_RIGHT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY : STRAFE_RIGHT ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
STRAFE_RIGHT-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : STRAFE_RIGHT ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
STRAFE_RIGHT-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : STRAFE_RIGHT ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
STRAFE_RIGHT-ATTACK_PRIMARY-RELOAD : STRAFE_RIGHT ATTACK_PRIMARY_BUTTON RELOAD
STRAFE_RIGHT-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-ATTACK_PRIMARY-PUTAWAYMAIN : STRAFE_RIGHT ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
STRAFE_RIGHT-ATTACK_PRIMARY-NEW_WEAPON : STRAFE_RIGHT ATTACK_PRIMARY_BUTTON NEW_WEAPON
STRAFE_RIGHT-ATTACK_PRIMARY : STRAFE_RIGHT ATTACK_PRIMARY_BUTTON
STRAFE_RIGHT-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : STRAFE_RIGHT ATTACK_SECONDARY RELOAD PUTAWAYMAIN
STRAFE_RIGHT-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : STRAFE_RIGHT ATTACK_SECONDARY RELOAD NEW_WEAPON
STRAFE_RIGHT-ATTACK_SECONDARY-RELOAD : STRAFE_RIGHT ATTACK_SECONDARY RELOAD
STRAFE_RIGHT-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-ATTACK_SECONDARY-PUTAWAYMAIN : STRAFE_RIGHT ATTACK_SECONDARY PUTAWAYMAIN
STRAFE_RIGHT-ATTACK_SECONDARY-NEW_WEAPON : STRAFE_RIGHT ATTACK_SECONDARY NEW_WEAPON
STRAFE_RIGHT-ATTACK_SECONDARY : STRAFE_RIGHT ATTACK_SECONDARY
STRAFE_RIGHT-RELOAD-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT RELOAD PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-RELOAD-PUTAWAYMAIN : STRAFE_RIGHT RELOAD PUTAWAYMAIN
STRAFE_RIGHT-RELOAD-NEW_WEAPON : STRAFE_RIGHT RELOAD NEW_WEAPON
STRAFE_RIGHT-RELOAD : STRAFE_RIGHT RELOAD
STRAFE_RIGHT-PUTAWAYMAIN-NEW_WEAPON : STRAFE_RIGHT PUTAWAYMAIN NEW_WEAPON
STRAFE_RIGHT-PUTAWAYMAIN : STRAFE_RIGHT PUTAWAYMAIN
STRAFE_RIGHT-NEW_WEAPON : STRAFE_RIGHT NEW_WEAPON
STRAFE_RIGHT : STRAFE_RIGHT
RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY : RUN CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
RUN-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
RUN-CROUCH-ATTACK_PRIMARY-RELOAD : RUN CROUCH ATTACK_PRIMARY_BUTTON RELOAD
RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : RUN CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN : RUN CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
RUN-CROUCH-ATTACK_PRIMARY-NEW_WEAPON : RUN CROUCH ATTACK_PRIMARY_BUTTON NEW_WEAPON
RUN-CROUCH-ATTACK_PRIMARY : RUN CROUCH ATTACK_PRIMARY_BUTTON
RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : RUN CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : RUN CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN
RUN-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : RUN CROUCH ATTACK_SECONDARY RELOAD NEW_WEAPON
RUN-CROUCH-ATTACK_SECONDARY-RELOAD : RUN CROUCH ATTACK_SECONDARY RELOAD
RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : RUN CROUCH ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN : RUN CROUCH ATTACK_SECONDARY PUTAWAYMAIN
RUN-CROUCH-ATTACK_SECONDARY-NEW_WEAPON : RUN CROUCH ATTACK_SECONDARY NEW_WEAPON
RUN-CROUCH-ATTACK_SECONDARY : RUN CROUCH ATTACK_SECONDARY
RUN-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON : RUN CROUCH RELOAD PUTAWAYMAIN NEW_WEAPON
RUN-CROUCH-RELOAD-PUTAWAYMAIN : RUN CROUCH RELOAD PUTAWAYMAIN
RUN-CROUCH-RELOAD-NEW_WEAPON : RUN CROUCH RELOAD NEW_WEAPON
RUN-CROUCH-RELOAD : RUN CROUCH RELOAD
RUN-CROUCH-PUTAWAYMAIN-NEW_WEAPON : RUN CROUCH PUTAWAYMAIN NEW_WEAPON
RUN-CROUCH-PUTAWAYMAIN : RUN CROUCH PUTAWAYMAIN
RUN-CROUCH-NEW_WEAPON : RUN CROUCH NEW_WEAPON
RUN-CROUCH : RUN CROUCH
RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY : RUN JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
RUN-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
RUN-JUMP-ATTACK_PRIMARY-RELOAD : RUN JUMP ATTACK_PRIMARY_BUTTON RELOAD
RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : RUN JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN : RUN JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
RUN-JUMP-ATTACK_PRIMARY-NEW_WEAPON : RUN JUMP ATTACK_PRIMARY_BUTTON NEW_WEAPON
RUN-JUMP-ATTACK_PRIMARY : RUN JUMP ATTACK_PRIMARY_BUTTON
RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : RUN JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : RUN JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN
RUN-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : RUN JUMP ATTACK_SECONDARY RELOAD NEW_WEAPON
RUN-JUMP-ATTACK_SECONDARY-RELOAD : RUN JUMP ATTACK_SECONDARY RELOAD
RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : RUN JUMP ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN : RUN JUMP ATTACK_SECONDARY PUTAWAYMAIN
RUN-JUMP-ATTACK_SECONDARY-NEW_WEAPON : RUN JUMP ATTACK_SECONDARY NEW_WEAPON
RUN-JUMP-ATTACK_SECONDARY : RUN JUMP ATTACK_SECONDARY
RUN-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON : RUN JUMP RELOAD PUTAWAYMAIN NEW_WEAPON
RUN-JUMP-RELOAD-PUTAWAYMAIN : RUN JUMP RELOAD PUTAWAYMAIN
RUN-JUMP-RELOAD-NEW_WEAPON : RUN JUMP RELOAD NEW_WEAPON
RUN-JUMP-RELOAD : RUN JUMP RELOAD
RUN-JUMP-PUTAWAYMAIN-NEW_WEAPON : RUN JUMP PUTAWAYMAIN NEW_WEAPON
RUN-JUMP-PUTAWAYMAIN : RUN JUMP PUTAWAYMAIN
RUN-JUMP-NEW_WEAPON : RUN JUMP NEW_WEAPON
RUN-JUMP : RUN JUMP
RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
RUN-ATTACK_PRIMARY-ATTACK_SECONDARY : RUN ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : RUN ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : RUN ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
RUN-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : RUN ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
RUN-ATTACK_PRIMARY-RELOAD : RUN ATTACK_PRIMARY_BUTTON RELOAD
RUN-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : RUN ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
RUN-ATTACK_PRIMARY-PUTAWAYMAIN : RUN ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
RUN-ATTACK_PRIMARY-NEW_WEAPON : RUN ATTACK_PRIMARY_BUTTON NEW_WEAPON
RUN-ATTACK_PRIMARY : RUN ATTACK_PRIMARY_BUTTON
RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : RUN ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : RUN ATTACK_SECONDARY RELOAD PUTAWAYMAIN
RUN-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : RUN ATTACK_SECONDARY RELOAD NEW_WEAPON
RUN-ATTACK_SECONDARY-RELOAD : RUN ATTACK_SECONDARY RELOAD
RUN-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : RUN ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
RUN-ATTACK_SECONDARY-PUTAWAYMAIN : RUN ATTACK_SECONDARY PUTAWAYMAIN
RUN-ATTACK_SECONDARY-NEW_WEAPON : RUN ATTACK_SECONDARY NEW_WEAPON
RUN-ATTACK_SECONDARY : RUN ATTACK_SECONDARY
RUN-RELOAD-PUTAWAYMAIN-NEW_WEAPON : RUN RELOAD PUTAWAYMAIN NEW_WEAPON
RUN-RELOAD-PUTAWAYMAIN : RUN RELOAD PUTAWAYMAIN
RUN-RELOAD-NEW_WEAPON : RUN RELOAD NEW_WEAPON
RUN-RELOAD : RUN RELOAD
RUN-PUTAWAYMAIN-NEW_WEAPON : RUN PUTAWAYMAIN NEW_WEAPON
RUN-PUTAWAYMAIN : RUN PUTAWAYMAIN
RUN-NEW_WEAPON : RUN NEW_WEAPON
RUN : RUN
CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY : CROUCH ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : CROUCH ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : CROUCH ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
CROUCH-ATTACK_PRIMARY-RELOAD : CROUCH ATTACK_PRIMARY_BUTTON RELOAD
CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN : CROUCH ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
CROUCH-ATTACK_PRIMARY-NEW_WEAPON : CROUCH ATTACK_PRIMARY_BUTTON NEW_WEAPON
CROUCH-ATTACK_PRIMARY : CROUCH ATTACK_PRIMARY_BUTTON
CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : CROUCH ATTACK_SECONDARY RELOAD PUTAWAYMAIN
CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : CROUCH ATTACK_SECONDARY RELOAD NEW_WEAPON
CROUCH-ATTACK_SECONDARY-RELOAD : CROUCH ATTACK_SECONDARY RELOAD
CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : CROUCH ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN : CROUCH ATTACK_SECONDARY PUTAWAYMAIN
CROUCH-ATTACK_SECONDARY-NEW_WEAPON : CROUCH ATTACK_SECONDARY NEW_WEAPON
CROUCH-ATTACK_SECONDARY : CROUCH ATTACK_SECONDARY
CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON : CROUCH RELOAD PUTAWAYMAIN NEW_WEAPON
CROUCH-RELOAD-PUTAWAYMAIN : CROUCH RELOAD PUTAWAYMAIN
CROUCH-RELOAD-NEW_WEAPON : CROUCH RELOAD NEW_WEAPON
CROUCH-RELOAD : CROUCH RELOAD
CROUCH-PUTAWAYMAIN-NEW_WEAPON : CROUCH PUTAWAYMAIN NEW_WEAPON
CROUCH-PUTAWAYMAIN : CROUCH PUTAWAYMAIN
CROUCH-NEW_WEAPON : CROUCH NEW_WEAPON
CROUCH : CROUCH
JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY : JUMP ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : JUMP ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON : JUMP ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
JUMP-ATTACK_PRIMARY-RELOAD : JUMP ATTACK_PRIMARY_BUTTON RELOAD
JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
JUMP-ATTACK_PRIMARY-PUTAWAYMAIN : JUMP ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
JUMP-ATTACK_PRIMARY-NEW_WEAPON : JUMP ATTACK_PRIMARY_BUTTON NEW_WEAPON
JUMP-ATTACK_PRIMARY : JUMP ATTACK_PRIMARY_BUTTON
JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : JUMP ATTACK_SECONDARY RELOAD PUTAWAYMAIN
JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : JUMP ATTACK_SECONDARY RELOAD NEW_WEAPON
JUMP-ATTACK_SECONDARY-RELOAD : JUMP ATTACK_SECONDARY RELOAD
JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : JUMP ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
JUMP-ATTACK_SECONDARY-PUTAWAYMAIN : JUMP ATTACK_SECONDARY PUTAWAYMAIN
JUMP-ATTACK_SECONDARY-NEW_WEAPON : JUMP ATTACK_SECONDARY NEW_WEAPON
JUMP-ATTACK_SECONDARY : JUMP ATTACK_SECONDARY
JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON : JUMP RELOAD PUTAWAYMAIN NEW_WEAPON
JUMP-RELOAD-PUTAWAYMAIN : JUMP RELOAD PUTAWAYMAIN
JUMP-RELOAD-NEW_WEAPON : JUMP RELOAD NEW_WEAPON
JUMP-RELOAD : JUMP RELOAD
JUMP-PUTAWAYMAIN-NEW_WEAPON : JUMP PUTAWAYMAIN NEW_WEAPON
JUMP-PUTAWAYMAIN : JUMP PUTAWAYMAIN
JUMP-NEW_WEAPON : JUMP NEW_WEAPON
JUMP : JUMP
ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD PUTAWAYMAIN
ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON : ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD NEW_WEAPON
ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD : ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY RELOAD
ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN : ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY PUTAWAYMAIN
ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON : ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY NEW_WEAPON
ATTACK_PRIMARY-ATTACK_SECONDARY : ATTACK_PRIMARY_BUTTON ATTACK_SECONDARY
ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN NEW_WEAPON
ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN : ATTACK_PRIMARY_BUTTON RELOAD PUTAWAYMAIN
ATTACK_PRIMARY-RELOAD-NEW_WEAPON : ATTACK_PRIMARY_BUTTON RELOAD NEW_WEAPON
ATTACK_PRIMARY-RELOAD : ATTACK_PRIMARY_BUTTON RELOAD
ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON : ATTACK_PRIMARY_BUTTON PUTAWAYMAIN NEW_WEAPON
ATTACK_PRIMARY-PUTAWAYMAIN : ATTACK_PRIMARY_BUTTON PUTAWAYMAIN
ATTACK_PRIMARY-NEW_WEAPON : ATTACK_PRIMARY_BUTTON NEW_WEAPON
ATTACK_PRIMARY : ATTACK_PRIMARY_BUTTON
ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON : ATTACK_SECONDARY RELOAD PUTAWAYMAIN NEW_WEAPON
ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN : ATTACK_SECONDARY RELOAD PUTAWAYMAIN
ATTACK_SECONDARY-RELOAD-NEW_WEAPON : ATTACK_SECONDARY RELOAD NEW_WEAPON
ATTACK_SECONDARY-RELOAD : ATTACK_SECONDARY RELOAD
ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON : ATTACK_SECONDARY PUTAWAYMAIN NEW_WEAPON
ATTACK_SECONDARY-PUTAWAYMAIN : ATTACK_SECONDARY PUTAWAYMAIN
ATTACK_SECONDARY-NEW_WEAPON : ATTACK_SECONDARY NEW_WEAPON
ATTACK_SECONDARY : ATTACK_SECONDARY
RELOAD-PUTAWAYMAIN-NEW_WEAPON : RELOAD PUTAWAYMAIN NEW_WEAPON
RELOAD-PUTAWAYMAIN : RELOAD PUTAWAYMAIN
RELOAD-NEW_WEAPON : RELOAD NEW_WEAPON
RELOAD : RELOAD
PUTAWAYMAIN-NEW_WEAPON : PUTAWAYMAIN NEW_WEAPON
PUTAWAYMAIN : PUTAWAYMAIN
NEW_WEAPON : NEW_WEAPON
NONE : default
}
}

state FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4021
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1973
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2997
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 949
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3509
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1461
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2485
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 437
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3765
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1717
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2741
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 693
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3253
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1205
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2229
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 181
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3893
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1845
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2869
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 821
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3381
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1333
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2357
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 309
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3637
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-CROUCH-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1589
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-CROUCH-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2613
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-CROUCH-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 565
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-CROUCH-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3125
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-CROUCH-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1077
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-CROUCH-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2101
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-CROUCH
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 53
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4053
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2005
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3029
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 981
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3541
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1493
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2517
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 469
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3797
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1749
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2773
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 725
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3285
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1237
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2261
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 213
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3925
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1877
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2901
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 853
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3413
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1365
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2389
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 341
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3669
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-JUMP-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1621
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-JUMP-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2645
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-JUMP-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 597
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-JUMP-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3157
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-JUMP-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1109
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-JUMP-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2133
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-JUMP
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 85
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3989
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1941
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2965
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 917
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3477
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1429
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2453
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 405
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3733
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1685
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2709
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 661
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3221
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1173
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2197
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 149
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3861
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1813
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2837
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 789
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3349
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1301
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2325
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 277
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3605
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1557
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2581
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 533
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3093
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1045
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2069
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RUN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 21
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4005
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1957
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2981
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 933
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3493
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1445
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2469
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 421
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3749
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1701
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2725
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 677
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3237
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1189
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2213
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 165
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3877
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1829
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2853
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 805
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3365
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1317
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2341
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-CROUCH-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 293
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3621
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-CROUCH-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1573
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-CROUCH-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2597
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-CROUCH-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 549
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-CROUCH-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3109
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-CROUCH-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1061
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-CROUCH-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2085
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-CROUCH
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 37
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4037
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1989
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3013
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 965
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3525
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1477
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2501
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 453
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3781
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1733
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2757
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 709
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3269
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1221
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2245
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 197
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3909
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1861
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2885
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-JUMP-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 837
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3397
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1349
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-JUMP-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2373
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-JUMP-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 325
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3653
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-JUMP-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1605
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-JUMP-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2629
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-JUMP-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 581
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-JUMP-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3141
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-JUMP-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1093
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-JUMP-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2117
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-JUMP
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 69
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3973
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1925
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
SV packet 68.142.232.33:27243 : getstatus
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2949
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 901
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3461
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1413
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2437
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 389
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3717
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1669
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2693
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 645
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3205
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1157
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2181
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 133
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3845
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1797
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2821
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 773
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3333
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1285
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2309
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 261
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3589
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1541
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2565
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 517
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3077
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1029
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2053
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_LEFT
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 5
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4025
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1977
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3001
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 953
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3513
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1465
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2489
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 441
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3769
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1721
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2745
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 697
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3257
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1209
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2233
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 185
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3897
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1849
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2873
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 825
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3385
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1337
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2361
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 313
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3641
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-CROUCH-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1593
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-CROUCH-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2617
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-CROUCH-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 569
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-CROUCH-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3129
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-CROUCH-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1081
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-CROUCH-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2105
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-CROUCH
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 57
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4057
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2009
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3033
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 985
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3545
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1497
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2521
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 473
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3801
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1753
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2777
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 729
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3289
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1241
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2265
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 217
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3929
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1881
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2905
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 857
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3417
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1369
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2393
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 345
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3673
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-JUMP-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1625
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-JUMP-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2649
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-JUMP-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 601
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-JUMP-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3161
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-JUMP-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1113
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-JUMP-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2137
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-JUMP
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 89
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3993
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1945
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2969
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 921
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3481
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1433
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2457
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 409
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3737
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1689
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2713
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 665
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3225
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1177
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2201
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 153
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3865
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1817
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2841
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 793
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3353
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1305
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2329
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 281
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3609
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1561
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2585
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 537
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3097
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1049
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2073
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RUN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 25
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4009
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1961
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2985
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 937
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3497
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1449
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2473
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 425
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3753
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1705
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2729
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 681
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3241
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1193
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2217
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 169
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3881
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1833
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2857
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 809
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3369
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1321
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2345
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 297
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3625
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-CROUCH-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1577
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-CROUCH-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2601
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-CROUCH-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 553
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-CROUCH-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3113
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-CROUCH-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1065
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-CROUCH-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2089
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-CROUCH
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 41
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4041
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1993
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3017
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 969
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3529
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1481
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2505
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 457
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3785
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1737
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2761
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 713
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3273
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1225
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2249
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 201
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3913
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1865
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2889
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 841
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3401
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1353
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2377
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-JUMP-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 329
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3657
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-JUMP-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1609
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-JUMP-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2633
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-JUMP-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 585
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-JUMP-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3145
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-JUMP-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1097
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-JUMP-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2121
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-JUMP
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 73
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3977
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1929
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2953
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 905
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3465
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1417
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2441
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 393
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3721
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1673
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2697
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 649
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3209
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1161
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2185
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 137
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3849
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1801
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2825
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 777
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3337
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1289
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2313
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 265
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3593
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1545
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2569
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 521
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3081
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1033
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2057
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-STRAFE_RIGHT
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 9
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4017
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1969
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2993
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 945
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3505
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1457
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2481
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 433
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3761
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1713
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2737
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-CROUCH-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 689
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3249
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1201
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-CROUCH-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2225
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-CROUCH-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 177
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3889
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1841
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2865
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-CROUCH-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 817
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3377
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1329
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-CROUCH-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2353
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-CROUCH-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 305
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3633
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-CROUCH-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1585
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-CROUCH-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2609
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-CROUCH-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 561
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-CROUCH-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3121
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-CROUCH-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1073
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-CROUCH-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2097
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-CROUCH
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 49
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4049
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2001
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3025
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 977
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3537
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1489
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2513
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 465
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3793
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1745
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2769
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-JUMP-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 721
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3281
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1233
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-JUMP-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2257
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-JUMP-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 209
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3921
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1873
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2897
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-JUMP-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 849
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3409
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1361
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-JUMP-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2385
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-JUMP-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 337
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3665
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-JUMP-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1617
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-JUMP-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2641
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-JUMP-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 593
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-JUMP-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3153
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-JUMP-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1105
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-JUMP-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2129
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-JUMP
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 81
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3985
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1937
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2961
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 913
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3473
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1425
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2449
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 401
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3729
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1681
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2705
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 657
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3217
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1169
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2193
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 145
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3857
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1809
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2833
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 785
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3345
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1297
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2321
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 273
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3601
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1553
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2577
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 529
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3089
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1041
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2065
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RUN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 17
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4001
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1953
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2977
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 929
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3489
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1441
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2465
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 417
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3745
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1697
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2721
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-CROUCH-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 673
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3233
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1185
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-CROUCH-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2209
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-CROUCH-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 161
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3873
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1825
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2849
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-CROUCH-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 801
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3361
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1313
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-CROUCH-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2337
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-CROUCH-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 289
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3617
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-CROUCH-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1569
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-CROUCH-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2593
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-CROUCH-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 545
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-CROUCH-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3105
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-CROUCH-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1057
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-CROUCH-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2081
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-CROUCH
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 33
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4033
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1985
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3009
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 961
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3521
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1473
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2497
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 449
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3777
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1729
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2753
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-JUMP-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 705
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3265
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1217
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-JUMP-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2241
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-JUMP-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 193
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3905
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1857
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2881
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-JUMP-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 833
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3393
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1345
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-JUMP-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2369
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-JUMP-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 321
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3649
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-JUMP-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1601
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-JUMP-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2625
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-JUMP-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 577
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-JUMP-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3137
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-JUMP-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1089
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-JUMP-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2113
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-JUMP
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 65
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3969
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1921
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2945
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 897
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3457
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1409
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2433
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 385
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3713
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1665
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2689
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 641
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3201
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1153
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2177
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 129
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3841
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1793
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2817
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 769
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3329
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1281
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2305
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 257
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3585
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1537
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2561
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 513
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3073
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1025
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2049
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state FORWARD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4022
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1974
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2998
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 950
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3510
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1462
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2486
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 438
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3766
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1718
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2742
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 694
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3254
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1206
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2230
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 182
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3894
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1846
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2870
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 822
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3382
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1334
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2358
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 310
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3638
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-CROUCH-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1590
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-CROUCH-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2614
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-CROUCH-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 566
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-CROUCH-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3126
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-CROUCH-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1078
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-CROUCH-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2102
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-CROUCH
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 54
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4054
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2006
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3030
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 982
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3542
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1494
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2518
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 470
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3798
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1750
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2774
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 726
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3286
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1238
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2262
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 214
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3926
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1878
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2902
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 854
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3414
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1366
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2390
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 342
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3670
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-JUMP-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1622
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-JUMP-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2646
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-JUMP-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 598
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-JUMP-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3158
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-JUMP-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1110
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-JUMP-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2134
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-JUMP
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 86
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3990
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1942
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2966
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 918
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3478
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1430
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2454
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 406
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3734
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1686
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2710
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 662
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3222
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1174
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2198
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 150
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3862
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1814
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2838
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 790
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3350
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1302
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2326
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 278
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3606
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1558
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2582
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 534
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3094
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1046
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2070
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RUN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 22
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4006
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1958
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2982
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 934
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3494
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1446
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2470
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 422
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3750
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1702
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2726
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 678
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3238
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1190
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2214
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 166
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3878
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1830
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2854
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 806
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3366
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1318
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2342
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-CROUCH-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 294
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3622
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-CROUCH-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1574
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-CROUCH-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2598
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-CROUCH-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 550
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-CROUCH-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3110
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-CROUCH-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1062
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-CROUCH-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2086
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-CROUCH
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 38
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4038
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1990
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3014
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 966
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3526
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1478
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2502
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 454
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3782
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1734
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2758
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 710
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3270
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1222
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2246
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-JUMP-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 198
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3910
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1862
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2886
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-JUMP-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 838
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3398
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1350
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-JUMP-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2374
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-JUMP-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 326
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3654
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-JUMP-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1606
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-JUMP-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2630
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-JUMP-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 582
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-JUMP-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3142
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-JUMP-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1094
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-JUMP-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2118
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-JUMP
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 70
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3974
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1926
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2950
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 902
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3462
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1414
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2438
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 390
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3718
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1670
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2694
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 646
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3206
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1158
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2182
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 134
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3846
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1798
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2822
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 774
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3334
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1286
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2310
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 262
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3590
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1542
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2566
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 518
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3078
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1030
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2054
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_LEFT
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 6
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4026
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1978
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3002
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 954
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3514
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1466
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2490
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 442
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3770
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1722
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2746
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 698
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3258
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1210
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2234
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 186
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3898
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1850
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2874
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 826
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3386
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1338
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2362
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 314
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3642
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-CROUCH-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1594
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-CROUCH-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2618
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-CROUCH-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 570
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-CROUCH-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3130
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-CROUCH-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1082
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-CROUCH-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2106
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-CROUCH
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 58
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4058
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2010
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3034
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 986
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3546
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1498
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2522
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 474
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3802
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1754
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2778
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 730
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3290
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1242
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2266
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 218
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3930
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1882
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2906
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 858
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3418
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1370
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2394
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 346
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3674
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-JUMP-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1626
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-JUMP-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2650
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-JUMP-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 602
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-JUMP-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3162
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-JUMP-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1114
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-JUMP-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2138
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-JUMP
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 90
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3994
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1946
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2970
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 922
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3482
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1434
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2458
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 410
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3738
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1690
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2714
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 666
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3226
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1178
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2202
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 154
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3866
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1818
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2842
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 794
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3354
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1306
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2330
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 282
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3610
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1562
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2586
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 538
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3098
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1050
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2074
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RUN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 26
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4010
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1962
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2986
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 938
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3498
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1450
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2474
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 426
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3754
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1706
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2730
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 682
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3242
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1194
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2218
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 170
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3882
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1834
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2858
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 810
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3370
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1322
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2346
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 298
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3626
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-CROUCH-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1578
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-CROUCH-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2602
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-CROUCH-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 554
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-CROUCH-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3114
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-CROUCH-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1066
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-CROUCH-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2090
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-CROUCH
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 42
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4042
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1994
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3018
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 970
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3530
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1482
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2506
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 458
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3786
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1738
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2762
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 714
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3274
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1226
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2250
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 202
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3914
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1866
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2890
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 842
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3402
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1354
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2378
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-JUMP-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 330
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3658
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-JUMP-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1610
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-JUMP-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2634
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-JUMP-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 586
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-JUMP-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3146
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-JUMP-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1098
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-JUMP-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2122
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-JUMP
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 74
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3978
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1930
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2954
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 906
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3466
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1418
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2442
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 394
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3722
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1674
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2698
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 650
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3210
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1162
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2186
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 138
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3850
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1802
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2826
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 778
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3338
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1290
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2314
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 266
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3594
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1546
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2570
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 522
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3082
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1034
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2058
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-STRAFE_RIGHT
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 10
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4018
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1970
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2994
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 946
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3506
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1458
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2482
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 434
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3762
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1714
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2738
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-CROUCH-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 690
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3250
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1202
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-CROUCH-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2226
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-CROUCH-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 178
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3890
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1842
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2866
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-CROUCH-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 818
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3378
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1330
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-CROUCH-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2354
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-CROUCH-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 306
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3634
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-CROUCH-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1586
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-CROUCH-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2610
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-CROUCH-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 562
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-CROUCH-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3122
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-CROUCH-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1074
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-CROUCH-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2098
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-CROUCH
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 50
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4050
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2002
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3026
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 978
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3538
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1490
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2514
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 466
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3794
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1746
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2770
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-JUMP-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 722
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3282
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1234
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-JUMP-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2258
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-JUMP-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 210
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3922
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1874
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2898
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-JUMP-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 850
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3410
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1362
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-JUMP-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2386
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-JUMP-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 338
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3666
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-JUMP-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1618
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-JUMP-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2642
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-JUMP-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 594
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-JUMP-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3154
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-JUMP-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1106
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-JUMP-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2130
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-JUMP
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 82
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3986
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1938
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2962
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 914
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3474
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1426
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2450
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 402
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3730
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1682
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2706
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 658
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3218
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1170
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2194
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 146
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3858
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1810
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2834
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 786
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3346
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1298
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2322
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 274
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3602
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1554
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2578
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 530
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3090
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1042
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2066
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RUN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 18
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4002
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1954
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2978
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 930
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3490
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1442
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2466
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 418
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3746
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1698
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2722
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-CROUCH-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 674
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3234
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1186
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-CROUCH-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2210
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-CROUCH-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 162
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3874
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1826
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2850
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-CROUCH-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 802
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3362
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1314
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-CROUCH-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2338
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-CROUCH-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 290
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3618
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-CROUCH-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1570
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-CROUCH-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2594
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-CROUCH-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 546
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-CROUCH-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3106
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-CROUCH-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1058
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-CROUCH-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2082
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-CROUCH
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 34
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4034
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1986
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3010
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 962
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3522
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1474
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2498
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 450
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3778
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1730
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2754
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-JUMP-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 706
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3266
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1218
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-JUMP-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2242
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-JUMP-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 194
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3906
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1858
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2882
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-JUMP-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 834
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3394
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1346
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-JUMP-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2370
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-JUMP-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 322
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3650
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-JUMP-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1602
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-JUMP-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2626
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-JUMP-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 578
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-JUMP-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3138
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-JUMP-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1090
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-JUMP-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2114
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-JUMP
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 66
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3970
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1922
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2946
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 898
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3458
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1410
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2434
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 386
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3714
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1666
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2690
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 642
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3202
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1154
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2178
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 130
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3842
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1794
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2818
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 770
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3330
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1282
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2306
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 258
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3586
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1538
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2562
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 514
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3074
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1026
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2050
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state BACKWARD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4020
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1972
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2996
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 948
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3508
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1460
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2484
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 436
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3764
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1716
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2740
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 692
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3252
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1204
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2228
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-CROUCH-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 180
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3892
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1844
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2868
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 820
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3380
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1332
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2356
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-CROUCH-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 308
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3636
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-CROUCH-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1588
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-CROUCH-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2612
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-CROUCH-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 564
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-CROUCH-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3124
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-CROUCH-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1076
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-CROUCH-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2100
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-CROUCH
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 52
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4052
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2004
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3028
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 980
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3540
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1492
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2516
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 468
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3796
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1748
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2772
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 724
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3284
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1236
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2260
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-JUMP-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 212
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3924
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1876
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2900
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 852
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3412
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1364
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2388
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-JUMP-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 340
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3668
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-JUMP-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1620
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-JUMP-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2644
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-JUMP-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 596
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-JUMP-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3156
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-JUMP-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1108
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-JUMP-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2132
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-JUMP
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 84
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3988
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1940
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2964
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 916
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3476
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1428
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2452
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 404
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3732
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1684
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2708
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 660
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3220
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1172
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2196
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 148
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3860
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1812
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2836
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 788
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3348
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1300
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2324
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 276
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3604
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1556
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2580
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 532
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3092
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1044
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2068
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RUN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 20
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4004
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1956
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2980
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 932
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3492
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1444
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2468
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 420
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3748
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1700
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2724
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 676
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3236
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1188
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-CROUCH-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2212
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-CROUCH-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 164
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3876
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1828
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2852
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 804
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3364
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1316
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-CROUCH-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2340
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-CROUCH-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 292
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3620
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-CROUCH-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1572
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-CROUCH-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2596
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-CROUCH-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 548
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-CROUCH-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3108
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-CROUCH-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1060
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-CROUCH-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2084
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-CROUCH
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 36
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4036
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1988
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3012
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 964
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3524
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1476
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2500
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 452
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3780
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1732
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2756
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-JUMP-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 708
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3268
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1220
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-JUMP-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2244
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-JUMP-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 196
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3908
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1860
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2884
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-JUMP-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 836
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3396
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1348
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-JUMP-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2372
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-JUMP-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 324
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3652
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-JUMP-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1604
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-JUMP-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2628
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-JUMP-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 580
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-JUMP-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3140
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-JUMP-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1092
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-JUMP-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2116
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-JUMP
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 68
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3972
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1924
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2948
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 900
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3460
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1412
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2436
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 388
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3716
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1668
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2692
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 644
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3204
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1156
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2180
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 132
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3844
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1796
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2820
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 772
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3332
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1284
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2308
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 260
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3588
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1540
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2564
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 516
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3076
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1028
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2052
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_LEFT
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4024
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1976
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3000
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 952
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3512
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1464
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2488
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 440
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3768
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1720
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2744
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 696
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3256
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1208
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2232
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-CROUCH-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 184
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3896
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1848
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2872
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 824
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3384
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1336
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2360
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-CROUCH-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 312
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3640
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-CROUCH-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1592
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-CROUCH-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2616
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-CROUCH-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 568
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-CROUCH-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3128
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-CROUCH-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1080
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-CROUCH-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2104
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-CROUCH
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 56
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4056
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2008
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3032
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 984
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3544
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1496
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2520
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 472
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3800
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1752
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2776
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 728
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3288
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1240
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2264
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-JUMP-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 216
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3928
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1880
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2904
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 856
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3416
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1368
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2392
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-JUMP-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 344
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3672
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-JUMP-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1624
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-JUMP-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2648
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-JUMP-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 600
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-JUMP-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3160
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-JUMP-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1112
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-JUMP-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2136
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-JUMP
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 88
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3992
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1944
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2968
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 920
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3480
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1432
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2456
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 408
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3736
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1688
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2712
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 664
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3224
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1176
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2200
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 152
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3864
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1816
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2840
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 792
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3352
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1304
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2328
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 280
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3608
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1560
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2584
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 536
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3096
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1048
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2072
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RUN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 24
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4008
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1960
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2984
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 936
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3496
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1448
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2472
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 424
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3752
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1704
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2728
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 680
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3240
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1192
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2216
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-CROUCH-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 168
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3880
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1832
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2856
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 808
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3368
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1320
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2344
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-CROUCH-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 296
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3624
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-CROUCH-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1576
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-CROUCH-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2600
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-CROUCH-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 552
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-CROUCH-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3112
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-CROUCH-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1064
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-CROUCH-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2088
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-CROUCH
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 40
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4040
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1992
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3016
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 968
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3528
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1480
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2504
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 456
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3784
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1736
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2760
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 712
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3272
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1224
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-JUMP-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2248
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-JUMP-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 200
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3912
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1864
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2888
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 840
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3400
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1352
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-JUMP-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2376
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-JUMP-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 328
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3656
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-JUMP-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1608
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-JUMP-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2632
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-JUMP-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 584
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-JUMP-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3144
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-JUMP-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1096
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-JUMP-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2120
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-JUMP
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 72
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3976
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1928
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2952
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 904
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3464
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1416
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2440
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 392
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3720
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1672
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2696
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 648
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3208
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1160
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2184
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 136
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3848
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1800
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2824
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 776
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3336
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1288
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2312
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 264
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3592
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1544
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2568
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 520
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3080
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1032
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2056
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state STRAFE_RIGHT
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 8
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4016
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1968
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2992
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 944
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3504
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1456
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2480
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 432
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3760
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1712
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2736
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-CROUCH-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 688
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3248
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1200
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-CROUCH-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2224
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-CROUCH-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 176
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3888
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1840
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2864
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-CROUCH-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 816
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3376
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1328
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-CROUCH-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2352
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-CROUCH-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 304
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3632
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-CROUCH-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1584
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-CROUCH-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2608
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-CROUCH-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 560
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-CROUCH-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3120
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-CROUCH-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1072
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-CROUCH-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2096
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-CROUCH
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 48
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4048
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2000
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3024
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 976
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3536
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1488
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2512
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 464
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3792
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1744
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2768
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-JUMP-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 720
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3280
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-JUMP-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1232
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-JUMP-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2256
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-JUMP-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 208
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3920
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1872
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2896
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-JUMP-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 848
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3408
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-JUMP-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1360
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-JUMP-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2384
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-JUMP-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 336
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3664
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-JUMP-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1616
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-JUMP-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2640
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-JUMP-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 592
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-JUMP-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3152
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-JUMP-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1104
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-JUMP-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2128
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-JUMP
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 80
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3984
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1936
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2960
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 912
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3472
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1424
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2448
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 400
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3728
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1680
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2704
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 656
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3216
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1168
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2192
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 144
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3856
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1808
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2832
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 784
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3344
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1296
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2320
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 272
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3600
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1552
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2576
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 528
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3088
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1040
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2064
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RUN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 16
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4000
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1952
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2976
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 928
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3488
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1440
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2464
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state CROUCH-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 416
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3744
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state CROUCH-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1696
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state CROUCH-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2720
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state CROUCH-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 672
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3232
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state CROUCH-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1184
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state CROUCH-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2208
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state CROUCH-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 160
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3872
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state CROUCH-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1824
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state CROUCH-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2848
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state CROUCH-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 800
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3360
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state CROUCH-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1312
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state CROUCH-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2336
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state CROUCH-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 288
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state CROUCH-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3616
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state CROUCH-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1568
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state CROUCH-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2592
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state CROUCH-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 544
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state CROUCH-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3104
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state CROUCH-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1056
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state CROUCH-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2080
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state CROUCH
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 32
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 4032
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1984
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3008
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 960
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3520
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1472
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2496
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state JUMP-ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 448
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3776
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state JUMP-ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1728
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state JUMP-ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2752
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state JUMP-ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 704
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state JUMP-ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3264
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state JUMP-ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1216
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state JUMP-ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2240
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state JUMP-ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 192
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3904
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state JUMP-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1856
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state JUMP-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2880
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state JUMP-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 832
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state JUMP-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3392
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state JUMP-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1344
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state JUMP-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2368
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state JUMP-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 320
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state JUMP-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3648
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state JUMP-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1600
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state JUMP-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2624
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state JUMP-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 576
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state JUMP-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3136
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state JUMP-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1088
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state JUMP-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2112
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state JUMP
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 64
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3968
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1920
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2944
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state ATTACK_PRIMARY-ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 896
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3456
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state ATTACK_PRIMARY-ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1408
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state ATTACK_PRIMARY-ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2432
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state ATTACK_PRIMARY-ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 384
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3712
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state ATTACK_PRIMARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1664
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state ATTACK_PRIMARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2688
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state ATTACK_PRIMARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 640
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state ATTACK_PRIMARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3200
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state ATTACK_PRIMARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1152
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state ATTACK_PRIMARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2176
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state ATTACK_PRIMARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 128
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3840
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state ATTACK_SECONDARY-RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1792
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state ATTACK_SECONDARY-RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2816
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state ATTACK_SECONDARY-RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 768
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state ATTACK_SECONDARY-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3328
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state ATTACK_SECONDARY-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1280
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state ATTACK_SECONDARY-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2304
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state ATTACK_SECONDARY
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 256
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RELOAD-PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3584
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RELOAD-PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1536
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RELOAD-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2560
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state RELOAD
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 512
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state PUTAWAYMAIN-NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 3072
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state PUTAWAYMAIN
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 1024
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state NEW_WEAPON
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 2048
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

state NONE
{
entrycommands
{
exec global/AA/key_input.scr set_next_input 0
moveposflags "crouching"
commanddelay 0.05 moveposflags "standing"
}
states
{
JARMUBEN_MOZGAS : POSITION_TYPE "standing"
}
}

//////////////////////////////////////
//
//	Woot! scripted ladder States
//
//////////////////////////////////////


state USE_LADDER_SORRID_TOP
{
	movetype climbwall
	
	entrycommands
	{
		safeholster 1 // put our weapon away
	}
	

	states 
	{
		LADDER_PUTAWAY_SORRID_TOP	: PUTAWAYMAIN
		GET_ON_LADDER_SORRID_TOP	: default
	}
}


state LADDER_PUTAWAY_SORRID_TOP
{
	entrycommands
	{
		deactivateweapon righthand
	}
	
	states
	{
		GET_ON_LADDER_SORRID_TOP		: default
	}
}

state GET_ON_LADDER_SORRID_TOP
{
	movetype climbwall

	entrycommands
	{
		modheight "stand"
		movementstealth "1.0"
		moveposflags "standing"
	}

	action
	{
		ladder_geton_top		: default
	}
	
	states
	{
		LADDER_IDLE_LEFT_SORRID	: ANIMDONE_TORSO
		FINISHED_GET_OFF_LADDER	: KILLED
	}
}




state USE_LADDER_SORRID_BOT
{
	movetype climbwall
	
	entrycommands
	{
		safeholster 1 // put our weapon away
	}
	

	states 
	{
		LADDER_PUTAWAY_SORRID_BOT	: PUTAWAYMAIN
		GET_ON_LADDER_SORRID_BOT	: default
	}
}





state LADDER_PUTAWAY_SORRID_BOT
{
	entrycommands
	{
		deactivateweapon righthand
	}
	
	states
	{
		GET_ON_LADDER_SORRID_BOT		: default
	}
}

state GET_ON_LADDER_SORRID_BOT
{
	movetype climbwall

	entrycommands
	{
		modheight "stand"
		movementstealth "1.0"
		moveposflags "standing"
	}

	action
	{
		ladder_geton_bottom		: default
	}
	
	states
	{
		LADDER_IDLE_LEFT_SORRID	: ANIMDONE_TORSO
		FINISHED_GET_OFF_LADDER	: KILLED
	}
}

state LADDER_IDLE_LEFT_SORRID
{
	movetype climbwall
	
	action
	{
		ladder_idle_left		: default
	}

	states
	{
		
		PUTAWAY_MAIN			: PUTAWAYMAIN	// just in case the weapon isn't put away yet
		
		LADDER_UP_RIGHT_SORRID			: FORWARD LOOKING_UP "-30"
		LADDER_UP_RIGHT_SORRID			: BACKWARD !LOOKING_UP "-30" 
		
		LADDER_DOWN_LEFT_SORRID		: FORWARD !LOOKING_UP "-30" 
		LADDER_DOWN_LEFT_SORRID		: BACKWARD LOOKING_UP "-30" 
		FINISHED_GET_OFF_LADDER	: KILLED
		JUMP_OFF_LADDER_SORRID		: +JUMP
		
	}
}

// idling on a ladder with the right hand high
state LADDER_IDLE_RIGHT_SORRID
{
	movetype climbwall
	
	action
	{
		ladder_idle_right		: default
	}
	
	states
	{
		
		PUTAWAY_MAIN			: PUTAWAYMAIN	// just in case the weapon isn't put away yet
		
		LADDER_UP_LEFT_SORRID			: FORWARD LOOKING_UP "-30"
		LADDER_UP_LEFT_SORRID			: BACKWARD !LOOKING_UP "-30" 
		
		LADDER_DOWN_RIGHT_SORRID		: FORWARD !LOOKING_UP "-30"
		LADDER_DOWN_RIGHT_SORRID		: BACKWARD LOOKING_UP "-30" 
		FINISHED_GET_OFF_LADDER	: KILLED
		JUMP_OFF_LADDER_SORRID		: +JUMP

	}
}

state LADDER_UP_LEFT_SORRID
{
	movetype climbwall
	
	action
	{
		ladder_up_left			: default
	}
	
	states
	{
		
		LADDER_IDLE_LEFT_SORRID		: ANIMDONE_TORSO
		FINISHED_GET_OFF_LADDER	: KILLED
		JUMP_OFF_LADDER_SORRID		: +JUMP
	}

	exitcommands
	{
	exec global/ladderspawn.scr 0 0 0 0 0 1
	}
}

state LADDER_UP_RIGHT_SORRID
{
	movetype climbwall
	
	
	action
	{
		ladder_up_right			: default
	}
	
	states
	{
		
		LADDER_IDLE_RIGHT_SORRID		: ANIMDONE_TORSO
		FINISHED_GET_OFF_LADDER	: KILLED
		JUMP_OFF_LADDER_SORRID		: +JUMP
	}
}

state LADDER_DOWN_LEFT_SORRID
{
	movetype climbwall
	
	
	action
	{
		ladder_down_left		: default
	}
	
	states
	{
		
		LADDER_IDLE_RIGHT_SORRID		: ANIMDONE_TORSO
		FINISHED_GET_OFF_LADDER	: KILLED
		JUMP_OFF_LADDER_SORRID		: +JUMP
	}

	exitcommands
	{
	exec global/ladderspawn.scr 0 0 0 0 0 1
	}
}

state LADDER_DOWN_RIGHT_SORRID
{
	movetype climbwall
	
	
	action
	{
		ladder_down_right		: default
	}
	
	states
	{

		LADDER_IDLE_LEFT_SORRID		: ANIMDONE_TORSO
		FINISHED_GET_OFF_LADDER		: KILLED
		JUMP_OFF_LADDER_SORRID		: +JUMP
	}
}

state JUMP_OFF_LADDER_SORRID
{
	movetype legs
	
	entrycommands
	{
		safeholster 0 // pull weapon back out if we put it away to get on the ladder
		jumpxy -70 0 150
		exec "global/ladderspawn.scr" 0 0 0 0 jump 0
	}

	states
	{
		STAND			: default
	}


}

state GET_OFF_LADDER_TOP_SORRID
{
	movetype climbwall
	
	action
	{
		ladder_getoff_top		: default
	}
	
	states
	{
		FINISHED_GET_OFF_LADDER	: KILLED
		
		FINISHED_GET_OFF_LADDER_SORRID	: ANIMDONE_TORSO
	}
}

state GET_OFF_LADDER_BOTTOM_SORRID
{
	movetype climbwall
	
	action
	{
		ladder_getoff_bottom	: default
	}
	
	states
	{
		FINISHED_GET_OFF_LADDER	: KILLED
	
		FINISHED_GET_OFF_LADDER_SORRID	: ANIMDONE_TORSO
	}
}

state FINISHED_GET_OFF_LADDER_SORRID
{
	movetype legs
	
	entrycommands
	{
		unattachfromladder
		safeholster 0 // pull weapon back out if we put it away to get on the ladder
	}

	states
	{
		STAND					: default
	}

	exitcommands
	{
	commanddelay 2 exec "global/ladderspawn.scr" 0 0 0 0 1 0
	}
}

//Ajout feho
//------------------------------------->
// Weaponclass Bash States
// 	By: =|95th|=GenDonut
//
//==============================================================


state BASH_ATTACK
{
	movetype legs

	action


	{
		none : default
	}

	states
	{	
		STAND					: RELOAD
		ATTACK_2NDARY				: IS_WEAPONCLASS_READY_TO_FIRE "mainhand" "rifle" "secondary"
		ATTACK_2NDARY				: IS_WEAPONCLASS_READY_TO_FIRE "mainhand" "smg" "secondary"
		ATTACK_2NDARY				: IS_WEAPONCLASS_READY_TO_FIRE "mainhand" "mg" "secondary"
		STAND					: default
	}

}



// RIFLE BASHING
state ATTACK_2NDARY
{
	movetype legs

	entrycommands
	{
		exec global/weapbash.scr "damage_player"
	}

	action
	{
		none : default
	}

	states
	{	
		STAND					: RELOAD

		//Do State Based on Weapon Name
		//All weapons except bazzoka's and Snipers can bash...
		
		ATTACK_THOMPSON_2NDARY			: IS_WEAPON_ACTIVE "mainhand" "Thompson"
		ATTACK_SHOTGUN_2NDARY			: IS_WEAPON_ACTIVE "mainhand" "Shotgun"
		ATTACK_MP44_2NDARY			: IS_WEAPON_ACTIVE "mainhand" "StG 44"
		ATTACK_MP40_2NDARY			: IS_WEAPON_ACTIVE "mainhand" "MP40"

		STAND					: default
	}
}



//==============================================================
//



// Specific Weapon Bash States
// 	By: =|95th|=GenDonut
//

//==============================================================

state ATTACK_THOMPSON_2NDARY
{
	movetype legs

	entrycommands
	{
		weaponcommand mainhand name "Colt 45"
		viewmodelanim fire_secondary 1
		commanddelay 0.25 weaponcommand mainhand shoot secondary
		weaponcommand mainhand name "Thompson"
	}

	action
	{
		pistol_butt	: default
	}
	
	states
	{
		STAND	 	: KILLED
		
		STAND	 	: ANIMDONE_TORSO
	}
}

state ATTACK_SHOTGUN_2NDARY
{
	movetype legs

	entrycommands
	{
		weaponcommand mainhand name "Colt 45"
		viewmodelanim fire_secondary 1
		commanddelay 0.25 weaponcommand mainhand shoot secondary
		weaponcommand mainhand name "Shotgun"
	}

	action
	{
		pistol_butt	: default
	}
	
	states
	{
		STAND	 	: KILLED
		
		STAND	 	: ANIMDONE_TORSO
	}
}
state ATTACK_MP44_2NDARY
{
	movetype legs

	entrycommands
	{
		weaponcommand mainhand name "Colt 45"
		viewmodelanim fire_secondary 1
		commanddelay 0.25 weaponcommand mainhand shoot secondary
		weaponcommand mainhand name "StG 44"
	}
	action
	{
		pistol_butt	: default
	}
	
	states
	{
		STAND	 	: KILLED
		
		STAND	 	: ANIMDONE_TORSO
	}
}
state ATTACK_MP40_2NDARY
{
	movetype legs

	entrycommands
	{
		weaponcommand mainhand name "Colt 45"
		viewmodelanim fire_secondary 1
		commanddelay 0.25 weaponcommand mainhand shoot secondary
		weaponcommand mainhand name "MP40"
	}

	action
	{
		pistol_butt	: default
	}
	
	states
	{
		STAND	 	: KILLED
		
		STAND	 	: ANIMDONE_TORSO
	}
}
//<------------------------------------------