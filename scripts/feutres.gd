extends StaticBody3D

func interact(player: Node) -> void:
  if player.puzzle_attempted.get("Feutres", false):
    player.pickup(self, "Feutres")
    return
  match player.state_tele:
    player.TeleState.IDLE:
      player._show_message("Des feutres mordus par LN R3p14y. Il mâchouille tous les capuchons.", 3.0)
    player.TeleState.CAPTCHA_PENDING:
      player._show_message("Ces feutres de couleur... LN R3p14y a dit quelque chose là-dessus. Je devrais lui reparler.", 3.0)
    _:
      player._show_message("Je n'en ai plus besoin.", 2.0)

func get_interaction_hint(_player: Node) -> String:
  return "[ESPACE] Prendre les feutres"
