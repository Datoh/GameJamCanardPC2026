extends StaticBody3D

func interact(player: Node) -> void:
  match player.state_machine[MachineTV.NAME]:
    Machine.StateMachine.TRY_MACHINE_OBJECT:
      player.show_message("Ces feutres de couleur... LN R3p14y a dit quelque chose là-dessus. Je devrais lui reparler.", 3.0)
      player.pickup(self, "Feutres", MachineTV.NAME)
    _:
      player.show_message("Des feutres mordus par LN R3p14y. Il mâchouille tous les capuchons.", 3.0)

func get_interaction_hint(_player: Node) -> String:
  return "[ESPACE] Prendre les feutres"
