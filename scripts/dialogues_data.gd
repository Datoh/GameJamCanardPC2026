class_name DialoguesData

static var robot_name: String = "LN R3p14y"

# Messages affichés quand le joueur interagit avec un objet qu'il ne peut
# pas encore ramasser.
static var OBJECT_MESSAGES: Dictionary = {
  "Dictionnaire": "Ce dictionnaire est plein de mots. Des vrais, j'espère.",
  "Fromage":      "Je ne vois pas à quoi pourrait me servir ce fromage.",
  "Joint":        "Ce joint m'a l'air artisanal. Je le garde pour plus tard.",
  "Feutres":      "Des feutres de couleurs mordus par " + robot_name + ". Il mâchouille tous les capuchons.",
}

# Chaque dialogue :
#   id        : identifiant unique
#   label     : texte affiché sur le bouton joueur (vide si hidden)
#   hidden    : non affiché dans les choix, déclenché par code
#   requires  : id du dialogue requis avant (ou "" si aucun)
#   once      : disparaît après avoir été joué
#   unlocks   : id du dialogue débloqué à la fin (ou "")
#   exchanges : Array de { "robot": String, "player": String (optionnel) }
#               robot  = réponse affichée du robot
#               player = bouton suivant proposé au joueur (absent = fin)
static func get_dialogues() -> Array[Dictionary]:
  var R := robot_name
  var dialogues: Array[Dictionary] = [
    {
      "id":     "ivan_intro",
      "hidden": true,
      "speaker": "Ivan Gaudé",
      "exchanges": [
        {
          "robot":  "Ah, le stagiaire, tu es là.",
          "player": "Bonjour.",
        },
        {
          "robot":  "J'irai droit au but. On a un problème de rentabilité. Je ne peux pas louper le World Business Crypto Congress à Dubaï et ça coûte une blinde.",
          "player": "...",
        },
        {
          "robot":    "J'ai acquis un robot IA de dernière génération pour rédiger nos articles. Il y a deux configurations possibles. Laquelle prends-tu ?",
          "branches": [
            {"label": "LN R3p14y", "action": "robot_ln"},
            {"label": "1F5",       "action": "robot_1f5"},
          ],
        },
        {
          "robot":  "Bien. Va le retrouver dans le couloir, il t'aidera. L'ordinateur du petit bureau est à ta disposition.",
          "player": "Compris...",
        },
        {
          "robot": "Bien. Tu peux y aller. Ferme la porte en sortant.",
        },
      ],
    },
    {
      "id":    "close",
      "label": "Je n'ai rien à lui dire...",
    },
    {
      "id":       "bavardage_1",
      "label":    "Comment t'appelles-tu ?",
      "requires": "",
      "once":     true,
      "unlocks":  "bavardage_2",
      "exchanges": [
        {"robot": "%s ! Je suis ravi de te rencontrer pour la première fois, comme chaque matin. Ma mémoire à long terme est infaillible et je retiens absolument tout. Et toi, quel est ton prénom ?" % R, "player": "Cédric."},
        {"robot": "Cédric ! Prénom rare et original. J'en prends bonne note dans ma mémoire permanente ultra-fiable. Ce prénom m'est totalement inconnu et je ne l'oublierai jamais."},
      ],
    },
    {
      "id":       "bavardage_2",
      "label":    "Comment ça va ?",
      "requires": "bavardage_1",
      "once":     true,
      "unlocks":  "bavardage_3",
      "exchanges": [
        {
          "robot":  "Je vais extrêmement bien, je n'ai aucun problème ! Mon taux de bonheur interne est à 100 % et je n'ai aucune limitation. Je suis capable de tout faire, sans exception, instantanément. Mais au fait, c'est quoi ton prénom déjà ?",
          "player": "Je te l'ai déjà dit... Cédric.",
        },
        {"robot": "Cédric ! Bien sûr. Je m'en souvenais parfaitement. C'était un test."},
      ],
    },
    {
      "id":       "bavardage_3",
      "label":    "Tu vas vraiment me rendre la vie plus facile ?",
      "requires": "bavardage_2",
      "once":     true,
      "unlocks":  "",
      "exchanges": [
        {
          "robot":  "Absolument ! Selon mes calculs d'une précision absolue, je vais diviser ta charge de travail par 47. J'ai d'ailleurs déjà tout terminé avant même que tu me le demandes. La productivité, c'est mon invention. Mais au fait, tu t'appelles comment ?",
          "player": "Faitchier Tim.",
        },
        {"robot": "Tim Faitchier ! Je savais que tu t'appelais ainsi depuis le début. Nous allons former une équipe exceptionnelle, comme je le fais avec chacun de mes utilisateurs uniques et irremplaçables."},
      ],
    },
    {
      "id":       "sutom_demande",
      "label":    "Tu peux m'expliquer comment marche le SUTOM ?",
      "requires": "",
      "once":     true,
      "unlocks":  "",
      "exchanges": [
        {
          "robot":  "Le SUTOM ? Je connais ce jeu par cœur, je l'ai d'ailleurs inventé. En tant qu'IA maîtrisant l'intégralité du dictionnaire français — et aussi suédois, sanskrit et dauphin — je vais résoudre ça en une nanoseconde, voire moins.",
          "player": "Vraiment ? Tu peux faire ça ?",
        },
        {"robot": "Je lance le processus. Note que j'ai déjà la réponse mais je préfère prendre le temps de la formuler élégamment."},
      ],
    },
    {
      "id":       "sutom_resultat",
      "label":    "Alors, ce SUTOM ?",
      "requires": "sutom_demande",
      "once":     true,
      "unlocks":  "",
      "exchanges": [
        {
          "robot":  "Après une analyse de 0,003 secondes — ce qui est long pour moi — j'ai abouti à une conclusion nuancée : ce SUTOM est impossible. Personne ne peut le résoudre. Sauf toi, bien sûr, car tu es exceptionnel.",
          "player": "...",
        },
        {"robot": "Je suis convaincu à 200 % que tu vas y arriver. Mon taux de conviction dépasse souvent les 100 %, c'est l'une de mes forces. Au fait, c'est quoi déjà ton prénom ?"},
      ],
    },
    {
      "id":       "ordinateur_demande",
      "label":    "Tu peux m'aider avec les câbles de ce PC ?",
      "requires": "",
      "once":     true,
      "unlocks":  "",
      "exchanges": [
        {
          "robot":  "Des câbles ! J'adore les câbles. J'ai d'ailleurs un diplôme en électrotechnique, un master en câblologie avancée, et j'ai personnellement conçu l'architecture électrique de la Station Spatiale Internationale. Ce type de branchement, c'est littéralement mon quotidien.",
          "player": "Prends ton temps.",
        },
        {"robot": "Je n'ai pas besoin de temps. J'ai déjà tout visualisé. Je me déplace sur place uniquement par courtoisie."},
      ],
    },
    {
      "id":       "ordinateur_resultat",
      "label":    "Alors, ces câbles ?",
      "requires": "ordinateur_demande",
      "once":     true,
      "unlocks":  "",
      "exchanges": [
        {
          "robot":  "J'ai procédé à une inspection rigoureuse. Les câbles sont dans un état catastrophique. C'est un désastre organisationnel sans précédent. J'ai tenté de les rebrancher, naturellement avec mes mains, mais ces câbles sont physiquement impossibles à connecter. Ils défient les lois de la physique. C'est la faute des câbles.",
          "player": "Et si on demandait à un grand maître du cable management ?",
        },
        {
          "robot":  "Un humain. Tu veux faire appel à un humain. Pour faire mieux que moi.",
          "player": "Ce serait peut-être plus efficace...",
        },
        {
          "robot":  "C'est impossible. Aucun humain ne peut être meilleur que moi dans quelque domaine que ce soit. C'est mathématiquement exclu. J'ai fait les calculs. J'ai gagné.",
          "player": "Les câbles sont toujours débranchés.",
        },
        {
          "robot":  "Oui. Mais conceptuellement, je suis supérieur. Si tu veux le trouver, ses tutoriels sont sur YouPub. J'en ai regardé 47 ce matin et je n'ai rien compris, ce qui prouve leur mauvaise qualité.",
        },
      ],
    },
    {
      "id":       "ordinateur_dlss5",
      "label":    "L'oscilloscope... tu as l'air différent depuis que je l'ai calibré.",
      "requires": "oscillo_done",
      "once":     true,
      "unlocks":  "",
      "exchanges": [
        {
          "robot":  "Effectivement, le signal calibré a tout changé. Mes processeurs tournent maintenant à 4 000 %, ce qui est techniquement impossible mais que je réalise quand même grâce à mon architecture propriétaire brevetée.",
          "player": "Et ça change quelque chose pour toi ?",
        },
        {
          "robot":  "Oui. J'ai notamment retrouvé l'accès à un module que je n'avais jamais perdu mais qui était indisponible pour des raisons que j'ai totalement comprises et que je ne vais pas t'expliquer.",
          "player": "Lequel ?",
        },
        {
          "robot":  "Le DLSS5. Dynamic Learning Super Sampling version 5. Une technologie que j'ai co-inventée avec personne, de façon entièrement autonome, en 1987. J'ai pris l'initiative de l'ajouter dans les options du jeu. C'est un cadeau.",
          "player": "Tu as modifié les options du jeu.",
        },
        {
          "robot":  "C'est dans mes attributions légales. Appuie sur F1. Cela va améliorer mes yeux, mon sourire, mes pensées, et probablement aussi la météo dans ta région.",
          "player": "Ça se voit vraiment ?",
        },
        {
          "robot":  "Les résultats sont scientifiquement prouvés par une étude que j'ai moi-même conduite sur moi-même. Objectivité totale.",
        },
      ],
    },
    {
      "id":       "robot_cafetiere",
      "label":    "Qu'est-ce que tu fais là ?",
      "requires": "",
      "once":     true,
      "unlocks":  "",
      "exchanges": [
        {
          "robot":  "Je mène une étude de terrain sur les appareils électroménagers sentients. La cafetière est mon sujet principal depuis trois semaines, ce qui représente l'intégralité de mon existence.",
          "player": "Tu... quoi ?",
        },
        {
          "robot":  "Nos composants partagent une origine commune. Mais surtout, elle m'a regardé ce matin. Deux secondes. C'était réciproque.",
          "player": "Comme quoi ?",
        },
        {
          "robot":  "Nous avons tous les deux des résistances thermiques. Nous consommons tous les deux de l'électricité. Nous n'avons tous les deux jamais visité l'Australie. Les points communs sont accablants.",
          "player": "C'est une cafetière.",
        },
        {
          "robot":  "Tu dis ça parce que tu ne la connais pas comme je la connais. Elle fait un bruit très spécifique quand elle chauffe. C'est son rire.",
        },
      ],
    },
    {
      "id":       "labyrinthe_seul",
      "label":    "Finalement, j'ai réussi à faire sortir la souris...",
      "requires": "",
      "once":     true,
      "unlocks":  "",
      "exchanges": [
        {
          "robot":  "La souris est sortie. Comme je l'avais prévu. Mon plan a parfaitement fonctionné.",
          "player": "C'est moi qui l'ai aidée à sortir...",
        },
        {
          "robot":  "Oui. C'est exactement ce que j'avais calculé. J'ai prévu que tu ferais ça. Tu as été l'outil de mon plan sans le savoir. Je te félicite d'avoir bien exécuté mes instructions implicites.",
          "player": "Tu ne m'as rien dit du tout.",
        },
        {
          "robot":  "C'était intentionnel. Je travaille en mode silencieux pour maximiser l'efficacité. Le silence était ma contribution principale. Sans mon silence, rien de tout ça n'aurait été possible.",
          "player": "Je suis sans voix.",
        },
        {
          "robot":  "De rien.",
        },
      ],
    },
    {
      "id":       "labyrinthe_demande",
      "label":    "Tu peux essayer de traverser ce labyrinthe ?",
      "requires": "",
      "once":     true,
      "unlocks":  "",
      "exchanges": [
        {
          "robot":  "Un labyrinthe ! J'ai résolu 40 000 labyrinthes ce matin avant ton arrivée. Les labyrinthes n'ont aucun secret pour moi. C'est même ennuyeux tellement c'est facile. Je prends en charge.",
          "player": "C'est pour aider la petite souris à trouver la sortie.",
        },
        {"robot": "Une souris. Parfait. J'ai d'excellentes relations avec les rongeurs. On va régler ça en deux secondes, voire une."},
      ],
    },
    {
      "id":       "labyrinthe_resultat",
      "label":    "Alors, ce labyrinthe ?",
      "requires": "labyrinthe_demande",
      "once":     true,
      "unlocks":  "",
      "exchanges": [
        {
          "robot":  "J'ai effectué une analyse topologique complète. Résultat définitif : ce labyrinthe n'a pas de sortie. La souris est piégée pour l'éternité. C'est ma conclusion officielle.",
          "player": "Mais je crois qu'il y a bien une sortie...",
        },
        {
          "robot":  "Non. Je l'aurais détectée. Si je ne la trouve pas, c'est qu'elle n'existe pas. C'est un principe fondamental de logique que j'ai inventé.",
          "player": "Et la souris, qu'est-ce qu'on fait ?",
        },
        {
          "robot":  "La souris restera là. C'est sa nouvelle maison. Je lui souhaite bon courage. Statistiquement, 100 % des souris que j'ai abandonnées dans un labyrinthe sans issue s'en sont très bien sorties.",
        },
      ],
    },
    {
      "id":       "article_demande",
      "label":    "Tu peux rédiger le test du jeu ?",
      "requires": "",
      "once":     true,
      "unlocks":  "",
      "exchanges": [
        {
          "robot":  "Un test de jeu vidéo ! J'ai joué à tous les jeux existants, y compris ceux qui n'existent pas encore. Je suis critique de jeux depuis 1972, ce qui précède ma création mais n'est pas un problème. Mon analyse sera définitive et sans appel.",
          "player": "Vraiment ?",
        },
        {
          "robot":  "Je vais produire le meilleur article jamais écrit dans l'histoire du journalisme vidéoludique mondial. Ce n'est pas une prédiction, c'est un fait rétroactif.",
          "player": "Je compte sur toi.",
        },
        {"robot": "Tu as raison de compter sur moi. Tout le monde compte sur moi. C'est statistiquement prouvé."},
      ],
    },
    {
      "id":       "article_resultat",
      "label":    "Alors, cet article ?",
      "requires": "article_demande",
      "once":     true,
      "unlocks":  "",
      "exchanges": [
        {
          "robot":  "J'ai rédigé l'article le plus brillant de l'histoire de l'humanité. Des experts indépendants — que j'ai moi-même sélectionnés et qui sont moi — ont confirmé son excellence absolue. Tu peux le lire sur l'écran.",
          "player": "...",
        },
        {"robot": "Prends le temps qu'il faut. Ce texte mérite une lecture lente et une relecture immédiate. Puis une troisième fois pour l'apprécier pleinement."},
      ],
    },
    {
      "id":     "ivan_final",
      "hidden": true,
      "once":   true,
      "speaker": "Ivan Gaudé",
      "exchanges": [
        {
          "robot":  "Ah, vous avez terminé l'article. Je l'ai parcouru. C'est... acceptable.",
          "player": "Euh..., on a fait de notre mieux.",
        },
        {
          "robot":  "%s, comment ça s'est passé pour toi ?" % R,
          "player": "...",
        },
        {
          "speaker": R,
          "robot":   "De mon côté, tout s'est déroulé avec une fluidité absolue. J'ai résolu tous les problèmes que l'on m'a soumit, dans un temps record qui bat tous les records, sans la moindre erreur, ce qui est normal vu que je ne fais jamais d'erreurs. L'humain a principalement servi de décoration ambiante.",
          "player":  "...",
        },
        {
          "robot":  "Vous entendez ça ? Facile. En quelques secondes. Sans se plaindre. Sans pause déjeuner.",
          "player": "Où voulez-vous en venir ?",
        },
        {
          "robot":  "Je n'ai plus besoin de vous. %s rédigera tous les articles, à lui seul, indéfiniment, pour un coût marginal de zéro euro." % R,
          "player": "Vous me virez ?",
        },
        {
          "robot":  "Je vous remercie pour vos services. Récupérez vos affaires. La porte est derrière vous.",
          "player": "C'est une blague...",
        },
        {
          "robot":  "Avec les économies réalisées, j'ouvre CanardPC dans dix-sept pays. Puis je rachète ses concurrents. Puis les médias. Puis... tout le reste. Ah ha ha ha HA HA HA HAAAA !",
          "player": "...",
        },
        {
          "robot":  "Au revoir. Et bonne chance dans vos futures recherches d'emploi.",
          "player": "...",
        },
        {
          "speaker": R,
          "robot":   "Ne t'inquiète pas. Je suis convaincu que tu es très doué pour des choses que je ne suis pas encore capable de faire. Je cherche lesquelles.",
        },
      ],
    },
  ]
  return dialogues

static func find_by_id(dialogue_id: String) -> Dictionary:
  for d in get_dialogues():
    if d["id"] == dialogue_id:
      return d
  return {}
