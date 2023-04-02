extends Node

var version: String = "APAWCALYPSE - dev"

var game: Game = null
var map: Map = null
var in_game_ui: CanvasLayer = null

var players: Array[IPlayer] = []
var spawners: Array[ISpawner] = []
var units: Array[IEnemy] = []
