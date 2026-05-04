extends Machine
class_name ScreenMachine

const NAME := "Screen"

@onready var _mouse_on_screen: Node3D = %MouseOnScreen

func _ready() -> void:
  machine_name = NAME

func interact(player: Node) -> void:
  var oscillo_solved: bool = player.state_machine[MachineOscillo.NAME] == Machine.StateMachine.SOLVED
  var pc_solved: bool = player.state_machine[MachineOrdinateur.NAME] == Machine.StateMachine.SOLVED
  var maze_solved: bool = player.state_machine[MachineMaze.NAME] == Machine.StateMachine.SOLVED
  var sutom_solve: bool = player.state_machine[MachineSutom.NAME] == Machine.StateMachine.SOLVED
  if not oscillo_solved and not pc_solved:
    player.show_message("L'écran n'est pas alimenté, encore le différentiel qui à sauté. En plus la tour est mal branchée.", 3.0)
  elif not oscillo_solved:
    player.show_message("L'écran n'est pas alimenté, encore le différentiel qui à sauté.", 3.0)
  elif not pc_solved:
    player.show_message("La tour est mal branchée.", 3.0)
  elif not maze_solved:
    player.show_message("Pas de souris...", 3.0)
  elif not _mouse_on_screen.visible:
    player.show_message("Voilà une souris !", 3.0)
    _mouse_on_screen.visible = true
  elif not sutom_solve:
    player.show_message("Il me demande un mot de passe mais je ne le connais pas.", 3.0)
  else:
    player.show_message("Je vais pouvoir écrire l'article.", 3.0)
