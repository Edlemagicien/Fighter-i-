extends Node

# --- CONFIGURATION DES PERSONNAGES ---

const CHARACTER_SCENES = [
	"res://scenes/ElYaagoubi.tscn",
	"res://scenes/Dubois.tscn",
	"res://scenes/Benedito.tscn",
	"res://scenes/Fardoux.tscn",
	"res://scenes/Morelle.tscn",
	"res://scenes/NKounou.tscn",
	"res://scenes/Scottez.tscn",
	"res://scenes/Blandre.tscn",
	"res://scenes/Mcgavigan.tscn",
	"res://scenes/Mele.tscn",
	"res://scenes/Deleplanque.tscn",
	"res://scenes/Justine.tscn",
	"res://scenes/LiseMarie.tscn"
]

const CHARACTER_NAMES = [
	"ElYaagoubi",
	"Dubois",
	"Benedito",
	"Fardoux",
	"Morelle",
	"NKounou",
	"Scottez",
	"Blandre",
	"McGavigan",
	"Mele",
	"Deleplanque",
	"Philippe",
	"Veillon"
]

const CHARACTER_DESC = [
	"Rapide et imprévisible",
	"Puissant et solide",
	"Aérien et agile",
	"Force brute",
	"Maître du papier",
	"Frappe sèche",
	"Contrôleur de zone",
	"Expert en stratégies",
	"Maître des réseaux",
	"Architecte logiciel",
	"Spécialiste IHM",
	"L'étoile montante",
	"Agile et stylée"
]

const CHARACTER_COLORS = [
	Color(0.9, 0.3, 0.1),
	Color(0.2, 0.8, 0.3),
	Color(0.1, 0.5, 0.9),
	Color(0.8, 0.8, 0.8),
	Color(0.9, 0.8, 0.1),
	Color(0.7, 0.2, 0.9),
	Color(0.1, 0.9, 0.8),
	Color(0.9, 0.5, 0.1),
	Color(0.4, 0.7, 0.2),
	Color(0.6, 0.2, 0.8),
	Color(0.3, 0.6, 0.9),
	Color(0.9, 0.2, 0.6),
	Color(0.8, 0.4, 0.6)
]

# --- CHOIX DES JOUEURS ---

var p1_character_index: int = 0
var p2_character_index: int = 1

var p1_scene: String:
	get: return CHARACTER_SCENES[p1_character_index]

var p2_scene: String:
	get: return CHARACTER_SCENES[p2_character_index]

# --- RÉSULTATS ET STATISTIQUES ---

var last_winner: int = 0
var p1_wins: int = 0
var p2_wins: int = 0

# --- PARAMÈTRES ---

var game_mode: String = "vs"
var stock_count: int = 3
var match_time: int = 180 # Time in seconds, 0 means infinite

# --- FONCTIONS UTILITAIRES (NOMS MODIFIÉS POUR ÉVITER LES CONFLITS) ---

# Changé de get_name() à get_character_name() pour éviter l'erreur native de Godot
func get_character_name(index: int) -> String:
	return CHARACTER_NAMES[index]

func get_character_color(index: int) -> Color:
	return CHARACTER_COLORS[index]

func get_character_desc(index: int) -> String:
	return CHARACTER_DESC[index]

func reset_match():
	last_winner = 0
