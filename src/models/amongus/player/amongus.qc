// Original model by Kaesar
// Optimizations and prettifications by Caramel Sweet

$modelname "amongus\player\player.mdl"

$bodygroup "Amongus"
{
	studio "Body.smd"
}


$surfaceprop "flesh"

$contents "solid"

$illumposition 0.01 2.98 29.483

$mostlyopaque

$cdmaterials "models\amongus\player\"

$cbox -10 -12 0 10 12 68

$bbox -10 -12 0 10 12 68

$definebone "BASE" "" 0 0 0 0 0 -179.999964 0 0 0 0 0 0
$definebone "Body" "BASE" 0 0.332459 -23.99197 0 0 -89.999982 0 0 0 0 0 0
$definebone "Leg.L" "Body" 8.448922 -8.939527 -0.294787 50.416505 3.243399 -175.79463 0 0 0 0 0 0
$definebone "Foot.L" "Leg.L" -0.523201 9.419728 -0.43141 0.000002 0 0 0 0 0 0 0 0
$definebone "Leg.R" "Body" -8.448922 -6.795097 -0.25734 -49.65596 10.670537 166.113985 0 0 0 0 0 0
$definebone "Foot.R" "Leg.R" -1.505676 11.768473 1.241527 -0.621249 9.281512 7.642452 0 0 0 0 0 0
$definebone "glasses" "Body" 0 23.007072 2.138193 0 0 89.999982 0 0 0 0 0 0
$definebone "backpack" "Body" 14.916036 18.643425 -6.359526 0 -179.999978 -4.254842 0 0 0 0 0 0


$sectionframes 30 30

$poseparameter "move_y" -1 1 loop 0
$poseparameter "move_x" -1 1 loop 0

$animation "a_idle" "amongus_anims\a_idle.smd" {
	fps 30
	loop
}

$animation "a_sit" "amongus_anims\a_sit.smd" {
	fps 30
}

$animation "a_inchat" "amongus_anims\a_inchat.smd" {
	fps 30
}

$animation "a_jump" "amongus_anims\a_jump.smd" {
	fps 30
}

$animation "a_wave" "amongus_anims\a_wave.smd" {
	fps 30
}

$animation "a_wave_b" "amongus_anims\a_wave_b.smd" {
	fps 30
}

$animation "a_salute" "amongus_anims\a_salute.smd" {
	fps 30
}

$animation "a_salute_b" "amongus_anims\a_salute_b.smd" {
	fps 30
}

$animation "a_idle_swim" "amongus_anims\a_idle_swim.smd" {
	fps 15
	loop
}

$animation "a_idle_crouch" "amongus_anims\a_idle_crouch.smd" {
	fps 30
	loop
}

$animation "a_idle_noclip" "amongus_anims\a_idle_noclip.smd" {
	fps 32
	loop
}

$animation "a_runN" "amongus_anims\a_runN.smd" {
	fps 15
	loop
}

$animation "a_runBack" "amongus_anims\a_runBack.smd" {
	fps 15
	loop
}

$animation "a_walkN" "amongus_anims\a_walkN.smd" {
	fps 10
	loop
}

$animation "a_walkS" "amongus_anims\a_walkS.smd" {
	fps 10
	loop
}

$animation "a_crouchN" "amongus_anims\a_crouchN.smd" {
	fps 7
	loop
}

$animation "a_crouchS" "amongus_anims\a_crouchS.smd" {
	fps 7
	loop
}

$animation "a_noclipN" "amongus_anims\a_noclipN.smd" {
	fps 17
	loop
}

$animation "a_noclipNW" "amongus_anims\a_noclipNW.smd" {
	fps 17
	loop
}

$animation "a_noclipNE" "amongus_anims\a_noclipNE.smd" {
	fps 17
	loop
}

$animation "a_noclipS" "amongus_anims\a_noclipS.smd" {
	fps 17
	loop
}

$animation "a_noclipSW" "amongus_anims\a_noclipSW.smd" {
	fps 17
	loop
}

$animation "a_noclipSE" "amongus_anims\a_noclipSE.smd" {
	fps 17
	loop
}

$animation "a_noclipW" "amongus_anims\a_noclipW.smd" {
	fps 17
	loop
}

$animation "a_noclipE" "amongus_anims\a_noclipE.smd" {
	fps 17
	loop
}

$sequence "ragdoll" {
	"amongus_anims\ragdoll.smd"
	activity "ACT_DIERAGDOLL" 1
	fadein 0.2
	fadeout 0.2
	fps 30
}

$sequence "idle_all_01" {
	"amongus_anims\idle_all_01.smd"
	fadein 0.2
	fadeout 0.2
	fps 30
	loop
}

$sequence "idle" {
	"a_idle"
	activity "ACT_HL2MP_IDLE" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_crouch" {
	"a_idle_crouch"
	activity "ACT_HL2MP_IDLE_CROUCH" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_swim" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_IDLE" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "swim" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "jump" {
	"a_jump"
	activity "ACT_HL2MP_JUMP" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "sit" {
	"a_sit"
	activity "ACT_HL2MP_SIT" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "inchat" {
	"a_inchat"
	activity "ACT_GMOD_IN_CHAT" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "taunt_salute" {
	"a_salute"
	fadein 0.2
	fadeout 0.2
}

$sequence "taunt_salute_b" {
	"a_salute_b"
	activity "ACT_GMOD_TAUNT_SALUTE" 1
	fadein 0.2
	fadeout 0.2
	addlayer "taunt_salute"
}

$sequence "drive_jeep" {
	"amongus_anims\drive_jeep.smd"
	activity "ACT_DRIVE_JEEP" 1
	fadein 0.2
	fadeout 0.2
	fps 30
}

$sequence "drive_airboat" {
	"amongus_anims\drive_airboat.smd"
	activity "ACT_DRIVE_AIRBOAT" 1
	fadein 0.2
	fadeout 0.2
	fps 30
}

$sequence "sit_rollercoaster" {
	"a_sit"
	activity "ACT_GMOD_SIT_ROLLERCOASTER" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "menu_walk" {
	"a_walkN"
	fadein 0.2
	fadeout 0.2
}

$sequence "run_all_01" {
	"a_runN"
	"a_runN"
	"a_runN"
	"a_runN"
	"a_idle"
	"a_runN"
	"a_runBack"
	"a_runBack"
	"a_runBack"
	activity "ACT_HL2MP_RUN" 1
	blend "move_y" -1 1
	blend "move_x" 1 -1
	fadein 0.2
	fadeout 0.2
	node "running"
}

$sequence "cwalk_all" {
	"a_crouchN"
	"a_crouchN"
	"a_crouchN"
	"a_crouchN"
	"a_idle_crouch"
	"a_crouchN"
	"a_crouchS"
	"a_crouchS"
	"a_crouchS"
	activity "ACT_HL2MP_WALK_CROUCH" 1
	blend "move_y" -1 1
	blend "move_x" 1 -1
	fadein 0.2
	fadeout 0.2
}

$sequence "walk_all" {
	"a_walkN"
	"a_walkN"
	"a_walkN"
	"a_walkN"
	"a_idle"
	"a_walkN"
	"a_walkS"
	"a_walkS"
	"a_walkS"
	activity "ACT_HL2MP_WALK" 1
	blend "move_y" -1 1
	blend "move_x" 1 -1
	fadein 0.2
	fadeout 0.5
}

$sequence "noclip" {
	"a_noclipNW"
	"a_noclipN"
	"a_noclipNE"
	"a_noclipW"
	"a_idle_noclip"
	"a_noclipE"
	"a_noclipSW"
	"a_noclipS"
	"a_noclipSE"
	activity "ACT_GMOD_NOCLIP_LAYER" 1
	blend "move_y" -1 1
	blend "move_x" 1 -1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_AR2" {
	"a_idle"
	activity "ACT_HL2MP_IDLE_AR2" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Crouch_AR2" {
	"a_idle_crouch"
	activity "ACT_HL2MP_IDLE_CROUCH_AR2" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Swim_AR2" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_IDLE_AR2" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "swim_AR2" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_AR2" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "run_AR2" {
	"a_runN"
	activity "ACT_HL2MP_RUN_AR2" 1
	fadein 0.2
	fadeout 0.2
	addlayer "run_all_01"
}

$sequence "crouch_AR2" {
	"a_crouchN"
	activity "ACT_HL2MP_WALK_CROUCH_AR2" 1
	fadein 0.2
	fadeout 0.2
	addlayer "cwalk_all"
}

$sequence "walk_AR2" {
	"a_walkN"
	activity "ACT_HL2MP_WALK_AR2" 1
	fadein 0.2
	fadeout 0.2
	addlayer "walk_all"
}

$sequence "jump_AR2" {
	"a_jump"
	activity "ACT_HL2MP_JUMP_AR2" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "sit_ar2" {
	"a_sit"
	activity "ACT_HL2MP_SIT_AR2" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_CAMERA" {
	"a_idle"
	activity "ACT_HL2MP_IDLE_CAMERA" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Crouch_CAMERA" {
	"a_idle_crouch"
	activity "ACT_HL2MP_IDLE_CROUCH_CAMERA" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Swim_CAMERA" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_IDLE_CAMERA" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "swim_CAMERA" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_CAMERA" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "run_CAMERA" {
	"a_runN"
	activity "ACT_HL2MP_RUN_CAMERA" 1
	fadein 0.2
	fadeout 0.2
	addlayer "run_all_01"
}

$sequence "crouch_CAMERA" {
	"a_crouchN"
	activity "ACT_HL2MP_WALK_CROUCH_CAMERA" 1
	fadein 0.2
	fadeout 0.2
	addlayer "cwalk_all"
}

$sequence "walk_CAMERA" {
	"a_walkN"
	activity "ACT_HL2MP_WALK_CAMERA" 1
	fadein 0.2
	fadeout 0.2
	addlayer "walk_all"
}

$sequence "jump_CAMERA" {
	"a_jump"
	activity "ACT_HL2MP_JUMP_CAMERA" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "sit_camera" {
	"a_sit"
	activity "ACT_HL2MP_SIT_CAMERA" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_CROSSBOW" {
	"a_idle"
	activity "ACT_HL2MP_IDLE_CROSSBOW" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Crouch_CROSSBOW" {
	"a_idle_crouch"
	activity "ACT_HL2MP_IDLE_CROUCH_CROSSBOW" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Swim_CROSSBOW" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_IDLE_CROSSBOW" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "swim_CROSSBOW" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_CROSSBOW" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "run_CROSSBOW" {
	"a_runN"
	activity "ACT_HL2MP_RUN_CROSSBOW" 1
	fadein 0.2
	fadeout 0.2
	addlayer "run_all_01"
}

$sequence "crouch_CROSSBOW" {
	"a_crouchN"
	activity "ACT_HL2MP_WALK_CROUCH_CROSSBOW" 1
	fadein 0.2
	fadeout 0.2
	addlayer "cwalk_all"
}

$sequence "walk_CROSSBOW" {
	"a_walkN"
	activity "ACT_HL2MP_WALK_CROSSBOW" 1
	fadein 0.2
	fadeout 0.2
	addlayer "walk_all"
}

$sequence "jump_CROSSBOW" {
	"a_jump"
	activity "ACT_HL2MP_JUMP_CROSSBOW" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "sit_crossbow" {
	"a_sit"
	activity "ACT_HL2MP_SIT_CROSSBOW" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_DUEL" {
	"a_idle"
	activity "ACT_HL2MP_IDLE_DUEL" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Crouch_DUEL" {
	"a_idle_crouch"
	activity "ACT_HL2MP_IDLE_CROUCH_DUEL" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Swim_DUEL" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_IDLE_DUEL" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "swim_DUEL" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_DUEL" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "run_DUEL" {
	"a_runN"
	activity "ACT_HL2MP_RUN_DUEL" 1
	fadein 0.2
	fadeout 0.2
	addlayer "run_all_01"
}

$sequence "crouch_DUEL" {
	"a_crouchN"
	activity "ACT_HL2MP_WALK_CROUCH_DUEL" 1
	fadein 0.2
	fadeout 0.2
	addlayer "cwalk_all"
}

$sequence "walk_DUEL" {
	"a_walkN"
	activity "ACT_HL2MP_WALK_DUEL" 1
	fadein 0.2
	fadeout 0.2
	addlayer "walk_all"
}

$sequence "jump_DUEL" {
	"a_jump"
	activity "ACT_HL2MP_JUMP_DUEL" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "sit_duel" {
	"a_sit"
	activity "ACT_HL2MP_SIT_DUEL" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_FIST" {
	"a_idle"
	activity "ACT_HL2MP_IDLE_FIST" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Crouch_FIST" {
	"a_idle_crouch"
	activity "ACT_HL2MP_IDLE_CROUCH_FIST" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Swim_FIST" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_IDLE_FIST" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "swim_FIST" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_FIST" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "run_FIST" {
	"a_runN"
	activity "ACT_HL2MP_RUN_FIST" 1
	fadein 0.2
	fadeout 0.2
	addlayer "run_all_01"
}

$sequence "crouch_FIST" {
	"a_crouchN"
	activity "ACT_HL2MP_WALK_CROUCH_FIST" 1
	fadein 0.2
	fadeout 0.2
	addlayer "cwalk_all"
}

$sequence "walk_FIST" {
	"a_walkN"
	activity "ACT_HL2MP_WALK_FIST" 1
	fadein 0.2
	fadeout 0.2
	addlayer "walk_all"
}

$sequence "jump_FIST" {
	"a_jump"
	activity "ACT_HL2MP_JUMP_FIST" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "sit_fist" {
	"a_sit"
	activity "ACT_HL2MP_SIT_FIST" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_GRENADE" {
	"a_idle"
	activity "ACT_HL2MP_IDLE_GRENADE" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Crouch_GRENADE" {
	"a_idle_crouch"
	activity "ACT_HL2MP_IDLE_CROUCH_GRENADE" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Swim_GRENADE" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_IDLE_GRENADE" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "swim_GRENADE" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_GRENADE" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "run_GRENADE" {
	"a_runN"
	activity "ACT_HL2MP_RUN_GRENADE" 1
	fadein 0.2
	fadeout 0.2
	addlayer "run_all_01"
}

$sequence "crouch_GRENADE" {
	"a_crouchN"
	activity "ACT_HL2MP_WALK_CROUCH_GRENADE" 1
	fadein 0.2
	fadeout 0.2
	addlayer "cwalk_all"
}

$sequence "walk_GRENADE" {
	"a_walkN"
	activity "ACT_HL2MP_WALK_GRENADE" 1
	fadein 0.2
	fadeout 0.2
	addlayer "walk_all"
}

$sequence "jump_GRENADE" {
	"a_jump"
	activity "ACT_HL2MP_JUMP_GRENADE" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "sit_grenade" {
	"a_sit"
	activity "ACT_HL2MP_SIT_GRENADE" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_KNIFE" {
	"a_idle"
	activity "ACT_HL2MP_IDLE_KNIFE" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Crouch_KNIFE" {
	"a_idle_crouch"
	activity "ACT_HL2MP_IDLE_CROUCH_KNIFE" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Swim_KNIFE" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_IDLE_KNIFE" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "swim_KNIFE" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_KNIFE" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "run_KNIFE" {
	"a_runN"
	activity "ACT_HL2MP_RUN_KNIFE" 1
	fadein 0.2
	fadeout 0.2
	addlayer "run_all_01"
}

$sequence "crouch_KNIFE" {
	"a_crouchN"
	activity "ACT_HL2MP_WALK_CROUCH_KNIFE" 1
	fadein 0.2
	fadeout 0.2
	addlayer "cwalk_all"
}

$sequence "walk_KNIFE" {
	"a_walkN"
	activity "ACT_HL2MP_WALK_KNIFE" 1
	fadein 0.2
	fadeout 0.2
	addlayer "walk_all"
}

$sequence "jump_KNIFE" {
	"a_jump"
	activity "ACT_HL2MP_JUMP_KNIFE" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "sit_knife" {
	"a_sit"
	activity "ACT_HL2MP_SIT_KNIFE" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_MELEE" {
	"a_idle"
	activity "ACT_HL2MP_IDLE_MELEE" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Crouch_MELEE" {
	"a_idle_crouch"
	activity "ACT_HL2MP_IDLE_CROUCH_MELEE" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Swim_MELEE" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_IDLE_MELEE" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "swim_MELEE" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_MELEE" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "run_MELEE" {
	"a_runN"
	activity "ACT_HL2MP_RUN_MELEE" 1
	fadein 0.2
	fadeout 0.2
	addlayer "run_all_01"
}

$sequence "crouch_MELEE" {
	"a_crouchN"
	activity "ACT_HL2MP_WALK_CROUCH_MELEE" 1
	fadein 0.2
	fadeout 0.2
	addlayer "cwalk_all"
}

$sequence "walk_MELEE" {
	"a_walkN"
	activity "ACT_HL2MP_WALK_MELEE" 1
	fadein 0.2
	fadeout 0.2
	addlayer "walk_all"
}

$sequence "jump_MELEE" {
	"a_jump"
	activity "ACT_HL2MP_JUMP_MELEE" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "sit_melee" {
	"a_sit"
	activity "ACT_HL2MP_SIT_MELEE" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_MELEE2" {
	"a_idle"
	activity "ACT_HL2MP_IDLE_MELEE2" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Crouch_MELEE2" {
	"a_idle_crouch"
	activity "ACT_HL2MP_IDLE_CROUCH_MELEE2" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Swim_MELEE2" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_IDLE_MELEE2" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "swim_MELEE2" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_MELEE2" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "run_MELEE2" {
	"a_runN"
	activity "ACT_HL2MP_RUN_MELEE2" 1
	fadein 0.2
	fadeout 0.2
	addlayer "run_all_01"
}

$sequence "crouch_MELEE2" {
	"a_crouchN"
	activity "ACT_HL2MP_WALK_CROUCH_MELEE2" 1
	fadein 0.2
	fadeout 0.2
	addlayer "cwalk_all"
}

$sequence "walk_MELEE2" {
	"a_walkN"
	activity "ACT_HL2MP_WALK_MELEE2" 1
	fadein 0.2
	fadeout 0.2
	addlayer "walk_all"
}

$sequence "jump_MELEE2" {
	"a_jump"
	activity "ACT_HL2MP_JUMP_MELEE2" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "sit_melee2" {
	"a_sit"
	activity "ACT_HL2MP_SIT_MELEE2" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_PASSIVE" {
	"a_idle"
	activity "ACT_HL2MP_IDLE_PASSIVE" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Crouch_PASSIVE" {
	"a_idle_crouch"
	activity "ACT_HL2MP_IDLE_CROUCH_PASSIVE" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Swim_PASSIVE" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_IDLE_PASSIVE" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "swim_PASSIVE" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_PASSIVE" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "run_PASSIVE" {
	"a_runN"
	activity "ACT_HL2MP_RUN_PASSIVE" 1
	fadein 0.2
	fadeout 0.2
	addlayer "run_all_01"
}

$sequence "crouch_PASSIVE" {
	"a_crouchN"
	activity "ACT_HL2MP_WALK_CROUCH_PASSIVE" 1
	fadein 0.2
	fadeout 0.2
	addlayer "cwalk_all"
}

$sequence "walk_PASSIVE" {
	"a_walkN"
	activity "ACT_HL2MP_WALK_PASSIVE" 1
	fadein 0.2
	fadeout 0.2
	addlayer "walk_all"
}

$sequence "jump_PASSIVE" {
	"a_jump"
	activity "ACT_HL2MP_JUMP_PASSIVE" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "sit_passive" {
	"a_sit"
	activity "ACT_HL2MP_SIT_PASSIVE" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_PISTOL" {
	"a_idle"
	activity "ACT_HL2MP_IDLE_PISTOL" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Crouch_PISTOL" {
	"a_idle_crouch"
	activity "ACT_HL2MP_IDLE_CROUCH_PISTOL" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Swim_PISTOL" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_IDLE_PISTOL" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "swim_PISTOL" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_PISTOL" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "run_PISTOL" {
	"a_runN"
	activity "ACT_HL2MP_RUN_PISTOL" 1
	fadein 0.2
	fadeout 0.2
	addlayer "run_all_01"
}

$sequence "crouch_PISTOL" {
	"a_crouchN"
	activity "ACT_HL2MP_WALK_CROUCH_PISTOL" 1
	fadein 0.2
	fadeout 0.2
	addlayer "cwalk_all"
}

$sequence "walk_PISTOL" {
	"a_walkN"
	activity "ACT_HL2MP_WALK_PISTOL" 1
	fadein 0.2
	fadeout 0.2
	addlayer "walk_all"
}

$sequence "jump_PISTOL" {
	"a_jump"
	activity "ACT_HL2MP_JUMP_PISTOL" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "sit_pistol" {
	"a_sit"
	activity "ACT_HL2MP_SIT_PISTOL" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_PHYSGUN" {
	"a_idle"
	activity "ACT_HL2MP_IDLE_PHYSGUN" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Crouch_PHYSGUN" {
	"a_idle_crouch"
	activity "ACT_HL2MP_IDLE_CROUCH_PHYSGUN" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Swim_PHYSGUN" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_IDLE_PHYSGUN" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "swim_PHYSGUN" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_PHYSGUN" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "run_PHYSGUN" {
	"a_runN"
	activity "ACT_HL2MP_RUN_PHYSGUN" 1
	fadein 0.2
	fadeout 0.2
	addlayer "run_all_01"
}

$sequence "crouch_PHYSGUN" {
	"a_crouchN"
	activity "ACT_HL2MP_WALK_CROUCH_PHYSGUN" 1
	fadein 0.2
	fadeout 0.2
	addlayer "cwalk_all"
}

$sequence "walk_PHYSGUN" {
	"a_walkN"
	activity "ACT_HL2MP_WALK_PHYSGUN" 1
	fadein 0.2
	fadeout 0.2
	addlayer "walk_all"
}

$sequence "jump_PHYSGUN" {
	"a_jump"
	activity "ACT_HL2MP_JUMP_PHYSGUN" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "sit_physgun" {
	"a_sit"
	activity "ACT_HL2MP_SIT_PHYSGUN" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_REVOLVER" {
	"a_idle"
	activity "ACT_HL2MP_IDLE_REVOLVER" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Crouch_REVOLVER" {
	"a_idle_crouch"
	activity "ACT_HL2MP_IDLE_CROUCH_REVOLVER" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Swim_REVOLVER" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_IDLE_REVOLVER" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "swim_REVOLVER" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_REVOLVER" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "run_REVOLVER" {
	"a_runN"
	activity "ACT_HL2MP_RUN_REVOLVER" 1
	fadein 0.2
	fadeout 0.2
	addlayer "run_all_01"
}

$sequence "crouch_REVOLVER" {
	"a_crouchN"
	activity "ACT_HL2MP_WALK_CROUCH_REVOLVER" 1
	fadein 0.2
	fadeout 0.2
	addlayer "cwalk_all"
}

$sequence "walk_REVOLVER" {
	"a_walkN"
	activity "ACT_HL2MP_WALK_REVOLVER" 1
	fadein 0.2
	fadeout 0.2
	addlayer "walk_all"
}

$sequence "jump_REVOLVER" {
	"a_jump"
	activity "ACT_HL2MP_JUMP_REVOLVER" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "sit_revolver" {
	"a_sit"
	activity "ACT_HL2MP_SIT_REVOLVER" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_RPG" {
	"a_idle"
	activity "ACT_HL2MP_IDLE_RPG" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Crouch_RPG" {
	"a_idle_crouch"
	activity "ACT_HL2MP_IDLE_CROUCH_RPG" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Swim_RPG" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_IDLE_RPG" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "swim_RPG" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_RPG" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "run_RPG" {
	"a_runN"
	activity "ACT_HL2MP_RUN_RPG" 1
	fadein 0.2
	fadeout 0.2
	addlayer "run_all_01"
}

$sequence "crouch_RPG" {
	"a_crouchN"
	activity "ACT_HL2MP_WALK_CROUCH_RPG" 1
	fadein 0.2
	fadeout 0.2
	addlayer "cwalk_all"
}

$sequence "walk_RPG" {
	"a_walkN"
	activity "ACT_HL2MP_WALK_RPG" 1
	fadein 0.2
	fadeout 0.2
	addlayer "walk_all"
}

$sequence "jump_RPG" {
	"a_jump"
	activity "ACT_HL2MP_JUMP_RPG" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "sit_rpg" {
	"a_sit"
	activity "ACT_HL2MP_SIT_RPG" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_SHOTGUN" {
	"a_idle"
	activity "ACT_HL2MP_IDLE_SHOTGUN" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Crouch_SHOTGUN" {
	"a_idle_crouch"
	activity "ACT_HL2MP_IDLE_CROUCH_SHOTGUN" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Swim_SHOTGUN" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_IDLE_SHOTGUN" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "swim_SHOTGUN" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_SHOTGUN" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "run_SHOTGUN" {
	"a_runN"
	activity "ACT_HL2MP_RUN_SHOTGUN" 1
	fadein 0.2
	fadeout 0.2
	addlayer "run_all_01"
}

$sequence "crouch_SHOTGUN" {
	"a_crouchN"
	activity "ACT_HL2MP_WALK_CROUCH_SHOTGUN" 1
	fadein 0.2
	fadeout 0.2
	addlayer "cwalk_all"
}

$sequence "walk_SHOTGUN" {
	"a_walkN"
	activity "ACT_HL2MP_WALK_SHOTGUN" 1
	fadein 0.2
	fadeout 0.2
	addlayer "walk_all"
}

$sequence "jump_SHOTGUN" {
	"a_jump"
	activity "ACT_HL2MP_JUMP_SHOTGUN" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "sit_shotgun" {
	"a_sit"
	activity "ACT_HL2MP_SIT_SHOTGUN" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_SLAM" {
	"a_idle"
	activity "ACT_HL2MP_IDLE_SLAM" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Crouch_SLAM" {
	"a_idle_crouch"
	activity "ACT_HL2MP_IDLE_CROUCH_SLAM" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Swim_SLAM" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_IDLE_SLAM" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "swim_SLAM" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_SLAM" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "run_SLAM" {
	"a_runN"
	activity "ACT_HL2MP_RUN_SLAM" 1
	fadein 0.2
	fadeout 0.2
	addlayer "run_all_01"
}

$sequence "crouch_SLAM" {
	"a_crouchN"
	activity "ACT_HL2MP_WALK_CROUCH_SLAM" 1
	fadein 0.2
	fadeout 0.2
	addlayer "cwalk_all"
}

$sequence "walk_SLAM" {
	"a_walkN"
	activity "ACT_HL2MP_WALK_SLAM" 1
	fadein 0.2
	fadeout 0.2
	addlayer "walk_all"
}

$sequence "jump_SLAM" {
	"a_jump"
	activity "ACT_HL2MP_JUMP_SLAM" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "sit_slam" {
	"a_sit"
	activity "ACT_HL2MP_SIT_SLAM" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_SMG1" {
	"a_idle"
	activity "ACT_HL2MP_IDLE_SMG1" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Crouch_SMG1" {
	"a_idle_crouch"
	activity "ACT_HL2MP_IDLE_CROUCH_SMG1" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "idle_Swim_SMG1" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_IDLE_SMG1" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "swim_SMG1" {
	"a_idle_swim"
	activity "ACT_HL2MP_SWIM_SMG1" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "run_SMG1" {
	"a_runN"
	activity "ACT_HL2MP_RUN_SMG1" 1
	fadein 0.2
	fadeout 0.2
	addlayer "run_all_01"
}

$sequence "crouch_SMG1" {
	"a_crouchN"
	activity "ACT_HL2MP_WALK_CROUCH_SMG1" 1
	fadein 0.2
	fadeout 0.2
	addlayer "cwalk_all"
}

$sequence "walk_SMG1" {
	"a_walkN"
	activity "ACT_HL2MP_WALK_SMG1" 1
	fadein 0.2
	fadeout 0.2
	addlayer "walk_all"
}

$sequence "jump_SMG1" {
	"a_jump"
	activity "ACT_HL2MP_JUMP_SMG1" 1
	fadein 0.2
	fadeout 0.2
}

$sequence "sit_smg1" {
	"a_sit"
	activity "ACT_HL2MP_SIT_SMG1" 1
	fadein 0.2
	fadeout 0.2
}

$collisionjoints "amongus_physics.smd"
{
	$mass 90
	$inertia 10
	$damping 0.01
	$rotdamping 1.5
	$rootbone "Body"


	$jointmassbias "Leg.R" 7
	$jointrotdamping "Leg.R" 7
	$jointconstrain "Leg.R" x limit -25 25 0
	$jointconstrain "Leg.R" y limit -10 15 0
	$jointconstrain "Leg.R" z limit -55 25 0

	$jointconstrain "Foot.R" x limit 0 0 0
	$jointconstrain "Foot.R" y limit -19 19 0
	$jointconstrain "Foot.R" z limit -15 35 0

	$jointmassbias "Leg.L" 7
	$jointrotdamping "Leg.L" 7
	$jointconstrain "Leg.L" x limit -25 25 0
	$jointconstrain "Leg.L" y limit -10 15 0
	$jointconstrain "Leg.L" z limit -55 25 0

	$jointconstrain "Foot.L" x limit 0 0 0
	$jointconstrain "Foot.L" y limit -25 6 0
	$jointconstrain "Foot.L" z limit -15 35 0
}
