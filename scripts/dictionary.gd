extends StaticBody3D

func interact(player: Node) -> void:
  match player.state_machine[MachineSutom.NAME]:
    Machine.StateMachine.TRY_MACHINE_OBJECT:
      player.show_message("Peut être que je vais connaître plus de mots.", 3.0)
      player.pickup(self, "Dictionnaire", MachineSutom.NAME)
    _:
      player.show_message("Un dictionnaire. Les rédacteurs ne doivent pas l'utiliser souvent vu les fautes dans leurs articles.", 3.0)

func get_interaction_hint(_player: Node) -> String:
  return "[ESPACE] Prendre le dictionnaire"
