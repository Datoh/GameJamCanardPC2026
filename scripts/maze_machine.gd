extends StaticBody3D
class_name MachineMaze

@onready var cheese_in_maze: Node3D = $CheeseInMaze
@onready var _mouse: CharacterBody3D = %Mouse

const machine_name := "Maze"

func interact(player: Node) -> void:
  var has_cheese: bool = player.inventory.has("Fromage")
  var state = player.state_machine[machine_name]
  if state == player.StateMachine.IDLE or (state == player.StateMachine.ATTEMPTED and not has_cheese):
    player._show_message("La souris ne trouve pas la sortie, je peux peut être l'aider.", 3.0)
    player.state_machine[machine_name] = player.StateMachine.ATTEMPTED
  elif state == player.StateMachine.ATTEMPTED and has_cheese:
    cheese_in_maze.visible = true
    player._show_message("Allez viens ma belle.", 3.0)
    player.state_machine[machine_name] = player.StateMachine.WAITING_UNLOCKED
    _mouse.go_to_cheese()
  elif state == player.StateMachine.WAITING_UNLOCKED:
    player._show_message("Elle arrive...", 3.0)
  elif state == player.StateMachine.UNLOCKED:
    player.state_machine[machine_name] = player.StateMachine.SOLVED
    player.pickup(_mouse, "souris")
  elif state == player.StateMachine.SOLVED:
    player._show_message("Je n'ai plus rien à faire ici.", 3.0)


func get_interaction_hint(_player: Node) -> String:
  return "[ESPACE] Observez le labyrinthe."
