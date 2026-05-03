extends Machine
class_name MachineMaze

const NAME := "Maze"

func _ready() -> void:
  machine_name = NAME
  object_required = "Fromage"
  dialogue_demande = "labyrinthe_demande"
  dialogue_resultat = "labyrinthe_resultat"
  robot_work_duration = 15.0
  message_try_machine = "La souris ne trouve pas la sortie... je vais demander de l'aide au robot."
  message_robot_working = "Le robot est en train d'étudier le labyrinthe..."
  message_robot_done = "Je devrais parler au robot, il a l'air d'avoir terminé."
  message_try_machine_object = "Il me faudrait quelque chose pour attirer la souris..."
  message_try_machine_ok = "Allez viens ma belle."
  message_waiting_unlocked = "Elle arrive..."
  message_solved = "Je n'ai plus rien à faire ici."
  hint_default = "[ESPACE] Observez le labyrinthe."
