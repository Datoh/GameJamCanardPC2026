extends StaticBody3D

var machine_name = "Ordinateur"

func interact(player: Node) -> void:
  match player.state_pc:
    player.PCState.IDLE:
      player.state_pc = player.PCState.ATTEMPTED
      player._show_message("Les câbles à l'arrière sont complètement dans le mauvais ordre. Il doit y avoir un tuto YouPub là-dessus...", 4.0)
    player.PCState.ATTEMPTED:
      if player.state_tele < player.TeleState.CAPTCHA_SOLVED:
        player._show_message("Je dois d'abord regarder le tuto YouPub sur la télé pour savoir comment rebrancher ces câbles.", 4.0)
      else:
        player._show_message("J'ai vu le tuto. Je devrais pouvoir rebrancher les câbles maintenant.", 3.0)
        # TODO : mini-jeu câbles
    _:
      player._show_message("[PC] Mini-jeu à venir...", 2.0)

func get_interaction_hint(player: Node) -> String:
  if player.state_pc >= player.PCState.ATTEMPTED and player.state_tele >= player.TeleState.CAPTCHA_SOLVED:
    return "[ESPACE] Rebrancher les câbles"
  return "[ESPACE] Regarder le PC"
