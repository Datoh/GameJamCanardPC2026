class_name ObjectivesManager
extends Node

## Centralise toutes les règles d'objectifs : écoute les signaux génériques
## (GameData, Player) et décide quand ajouter ou terminer un objectif.
##
## Dépendances entre obstacles (détail et phrases joueur : voir GDD.md,
## section "Dépendances entre tâches") :
## - Labyrinthe, Oscilloscope, Câbles PC (Ordinateur) et les collectibles
##   Canard PC sont libres, sans prérequis.
## - CAPTCHA (TV) nécessite que les Câbles aient au moins été tentés
##   (voir MachineTV._can_try() dans tv_machine.gd).
## - SUTOM nécessite Oscilloscope ET Câbles PC résolus
##   (voir MachineSutom._can_try() dans sutom_machine.gd).
## - Rédiger l'article (ScreenMachine) nécessite Labyrinthe + Oscilloscope +
##   Câbles + CAPTCHA + SUTOM résolus, plus la souris de PC branchée
##   (voir ScreenMachine._is_fully_repaired() dans screen_machine.gd).
## - La cafetière (dialogue existentiel) n'est disponible qu'une fois
##   l'Oscilloscope résolu (voir MachineOscillo.is_dialogue_locked()).

@onready var _player: CharacterBody3D = %Player


func _ready() -> void:
  GameData.intro_completed.connect(_on_intro_completed)
  GameData.machine_state_changed.connect(_on_machine_state_changed)
  _player.dialogue_side_effect.connect(_on_dialogue_side_effect)
  _player.object_picked.connect(_on_object_picked)
  _player.cpc_collected_changed.connect(_on_cpc_collected)
  _player.game_finished.connect(_on_game_finished)


func on_game_started() -> void:
  GameData.add_objective("objectiveTalkIvan", true)


func _on_intro_completed() -> void:
  GameData.complete_objective("objectiveTalkIvan")
  GameData.add_objective("objectiveWriteArticle", true)
  GameData.add_objective("objectiveTalkRobotFirst", false, [DialoguesData.robot_name])


func _on_game_finished() -> void:
  GameData.complete_objective("objectiveTalkIvan")


func _on_dialogue_side_effect(dialogue_id: String) -> void:
  if dialogue_id != "ivan_final":
    GameData.complete_objective("objectiveTalkRobotFirst")
  if dialogue_id == "labyrinthe_demande":
    GameData.complete_objective("objectiveAskRobotMaze")
  if dialogue_id == "oscillo_demande":
    GameData.complete_objective("objectiveAskRobotOscillo")
    _add_objective_once("objectiveLookOscillo")
  if dialogue_id == "tv_demande":
    GameData.complete_objective("objectiveAskRobotCaptcha")
  if dialogue_id == "cafetiere_existentiel":
    _add_objective_once("objectiveFreeRobot", [DialoguesData.robot_name])
  if dialogue_id == "cafetiere_reprise":
    GameData.complete_objective("objectiveFreeRobot")
  if dialogue_id == "oscillo_resultat":
    _add_objective_once("objectiveSolveOscillo")


func _on_machine_state_changed(machine_name: String, state: Machine.StateMachine) -> void:
  match state:
    Machine.StateMachine.TRY_MACHINE:
      match machine_name:
        MachineMaze.NAME:
          _add_objective_once("objectiveAskRobotMaze", [DialoguesData.robot_name])
        MachineOscillo.NAME:
          _add_objective_once("objectiveAskRobotOscillo", [DialoguesData.robot_name])
        MachineOrdinateur.NAME:
          _add_objective_once("objectiveRewireTower")
        MachineTV.NAME:
          _add_objective_once("objectiveSolveCaptcha")
          _add_objective_once("objectiveAskRobotCaptcha", [DialoguesData.robot_name])
        MachineSutom.NAME:
          _add_objective_once("objectiveSolveSutom")
    Machine.StateMachine.ROBOT_DONE:
      match machine_name:
        MachineOscillo.NAME:
          GameData.complete_objective("objectiveLookOscillo")
    Machine.StateMachine.TRY_MACHINE_OBJECT:
      match machine_name:
        MachineMaze.NAME:
          _add_objective_once("objectiveGetCheese")
          _add_objective_once("objectiveFreeMouse")
        MachineSutom.NAME:
          _add_objective_once("objectiveGetDictionary")
        MachineTV.NAME:
          if "Feutres" not in _player.inventory:
            _add_objective_once("objectiveGetMarkers")
    Machine.StateMachine.SOLVED:
      match machine_name:
        MachineOscillo.NAME:
          GameData.complete_objective("objectiveSolveOscillo")
        MachineOrdinateur.NAME:
          GameData.complete_objective("objectiveRewireTower")
        MachineTV.NAME:
          GameData.complete_objective("objectiveSolveCaptcha")
        MachineMaze.NAME:
          GameData.complete_objective("objectiveFreeMouse")
        MachineSutom.NAME:
          GameData.complete_objective("objectiveSolveSutom")
        ScreenMachine.NAME:
          GameData.complete_objective("objectiveWriteArticle")
          GameData.add_objective("objectiveTalkIvan", true)


func _on_object_picked(obj_name: String) -> void:
  match obj_name:
    "Fromage":
      GameData.complete_objective("objectiveGetCheese")
    "Dictionnaire":
      GameData.complete_objective("objectiveGetDictionary")
    "Feutres":
      GameData.complete_objective("objectiveGetMarkers")


func _on_cpc_collected(count: int, total: int) -> void:
  _add_objective_once("objectiveFindAllCpc", [count, total])
  GameData.update_objective_params("objectiveFindAllCpc", [count, total])
  if count >= total:
    GameData.complete_objective("objectiveFindAllCpc")


func _add_objective_once(key: String, params: Array = []) -> void:
  if not GameData.has_objective(key):
    GameData.add_objective(key, false, params)
