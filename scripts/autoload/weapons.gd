extends Node


const AK47_SCENE: PackedScene = preload("res://scenes/weapon/ak47.tscn")
const MACHINE_GUN_SCENE: PackedScene = preload("res://scenes/weapon/machinegun.tscn")
const MP5_SCENE: PackedScene = preload("res://scenes/weapon/mp5.tscn")
const PISTOL_SCENE: PackedScene = preload("res://scenes/weapon/pistol.tscn")
const SHOTGUN_SCENE: PackedScene = preload("res://scenes/weapon/shotgun.tscn")
const SNIPER_SCENE: PackedScene = preload("res://scenes/weapon/sniper.tscn")


const WPN_AK47: String = "AK47"
const WPN_MACHINE_GUN: String = "MACHINE_GUN"
const WPN_MP5: String = "MP5"
const WPN_PISTOL: String = "PISTOL"
const WPN_SHOTGUN: String = "SHOTGUN"
const WPN_SNIPER: String = "SNIPER"


const List: Dictionary = {
	WPN_AK47: AK47_SCENE,
	WPN_MACHINE_GUN: MACHINE_GUN_SCENE,
	WPN_MP5: MP5_SCENE,
	WPN_PISTOL: PISTOL_SCENE,
	WPN_SHOTGUN: SHOTGUN_SCENE,
	WPN_SNIPER: SNIPER_SCENE,
}
