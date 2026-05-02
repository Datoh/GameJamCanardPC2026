extends StaticBody3D

@onready var cheese_in_maze: Node3D = $CheeseInMaze
@onready var _mouse: CharacterBody3D = %Mouse

func interact(player: Node) -> void:
  var has_cheese: bool = player.inventory.has("Fromage")
  if player.state_labyrinthe == player.LabyrinthState.IDLE or (player.state_labyrinthe == player.LabyrinthState.ATTEMPTED and not has_cheese):
    player._show_message("La souris ne trouve pas la sortie, je peux peut être l'aider.", 3.0)
    player.state_labyrinthe = player.LabyrinthState.ATTEMPTED
  elif player.state_labyrinthe == player.LabyrinthState.ATTEMPTED and has_cheese:
    cheese_in_maze.visible = true
    player._show_message("Allez viens ma belle.", 3.0)
    player.state_labyrinthe = player.LabyrinthState.CHEESE
    _mouse.go_to_cheese()
  elif player.state_labyrinthe == player.LabyrinthState.CHEESE:
    player._show_message("Elle arrive...", 3.0)
  elif player.state_labyrinthe == player.LabyrinthState.MOUSE_READY:
    cheese_in_maze.visible = true
    player.state_labyrinthe = player.LabyrinthState.SOLVED
    player.pickup(_mouse, "souris")
  elif player.state_labyrinthe == player.LabyrinthState.SOLVED:
    cheese_in_maze.visible = true
    player._show_message("Je n'ai plus rien à faire ici.", 3.0)


func get_interaction_hint(_player: Node) -> String:
  return "[ESPACE] Regarder le labyrinthe."
