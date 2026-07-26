class_name DialoguesData

static var robot_name: String = "LN R3p14y"

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
  var dialogues: Array[Dictionary] = [
    {
      "id":     "ivan_intro",
      "hidden": true,
      "speaker": "speakerIvan",
      "exchanges": [
        {
          "robot":  "dlgIvanIntroGreet",
          "player": "dlgHello",
        },
        {
          "robot":  "dlgIvanIntroProblem",
          "player": "dlgEllipsis",
        },
        {
          "robot":    "dlgIvanIntroRobot",
          "branches": [
            {"label": "LN R3p14y", "action": "robot_ln"},
            {"label": "1F5",       "action": "robot_1f5"},
          ],
        },
        {
          "robot":  "dlgIvanIntroGo",
          "player": "dlgUnderstood",
        },
        {
          "robot": "dlgIvanIntroEnd",
        },
      ],
    },
    {
      "id":    "close",
      "label": "dlgCloseLabel",
    },
    {
      "id":       "bavardage_1",
      "label":    "dlgBavardage1Label",
      "requires": "",
      "once":     true,
      "unlocks":  "bavardage_2",
      "exchanges": [
        {"robot": "dlgBavardage1Meet", "player": "dlgCedric"},
        {"robot": "dlgBavardage1Name"},
      ],
    },
    {
      "id":       "bavardage_2",
      "label":    "dlgBavardage2Label",
      "requires": "bavardage_1",
      "once":     true,
      "unlocks":  "bavardage_3",
      "exchanges": [
        {
          "robot":  "dlgBavardage2Fine",
          "player": "dlgBavardage2Cedric",
        },
        {"robot": "dlgBavardage2Remember"},
      ],
    },
    {
      "id":       "bavardage_3",
      "label":    "dlgBavardage3Label",
      "requires": "bavardage_2",
      "once":     true,
      "unlocks":  "",
      "exchanges": [
        {
          "robot":  "dlgBavardage3Calc",
          "player": "dlgFaitchierTim",
        },
        {"robot": "dlgBavardage3Tim"},
      ],
    },
    {
      "id":       "robot_stop_following",
      "label":    "dlgStopFollowLabel",
      "requires": "",
      "once":     true,
      "unlocks":  "",
      "exchanges": [
        {"robot": "dlgStopFollowMemory"},
      ],
    },
    {
      "id":       "sutom_demande",
      "label":    "dlgSutomDemandeLabel",
      "requires": "",
      "once":     true,
      "unlocks":  "",
      "exchanges": [
        {
          "robot":  "dlgSutomDemandeExplain",
          "player": "dlgReally",
        },
        {"robot": "dlgSutomDemandeStart"},
      ],
    },
    {
      "id":       "sutom_resultat",
      "label":    "dlgSutomResultatLabel",
      "requires": "sutom_demande",
      "once":     true,
      "unlocks":  "",
      "exchanges": [
        {
          "robot":  "dlgSutomResultatAnalysis",
          "player": "dlgEllipsis",
        },
        {"robot": "dlgSutomResultatConvinced"},
      ],
    },
    {
      "id":       "tv_demande",
      "label":    "dlgTvDemandeLabel",
      "requires": "",
      "once":     true,
      "unlocks":  "",
      "exchanges": [
        {
          "robot":  "dlgTvDemandeInsult",
          "player": "dlgTvDemandeGoOn",
        },
        {"robot": "dlgTvDemandeHandle"},
      ],
    },
    {
      "id":       "tv_resultat",
      "label":    "dlgTvResultatLabel",
      "requires": "tv_demande",
      "once":     true,
      "unlocks":  "",
      "exchanges": [
        {
          "robot":  "dlgTvResultatFail",
          "player": "dlgTvResultatButFailed",
        },
        {"robot": "dlgTvResultatMarkers"},
      ],
    },
    {
      "id":       "tv_apres",
      "label":    "dlgTvApresLabel",
      "requires": "tv_resultat",
      "once":     true,
      "unlocks":  "",
      "exchanges": [
        {
          "robot":  "dlgTvApresCongrats",
          "player": "dlgEllipsis",
        },
        {"robot": "dlgTvApresVideo"},
      ],
    },
    {
      "id":       "ordinateur_demande",
      "label":    "dlgOrdiDemandeLabel",
      "requires": "",
      "once":     true,
      "unlocks":  "",
      "exchanges": [
        {
          "robot":  "dlgOrdiDemandeCables",
          "player": "dlgTakeYourTime",
        },
        {"robot": "dlgOrdiDemandeNoTime"},
      ],
    },
    {
      "id":       "ordinateur_resultat",
      "label":    "dlgOrdiResultatLabel",
      "requires": "ordinateur_demande",
      "once":     true,
      "unlocks":  "",
      "exchanges": [
        {
          "robot":  "dlgOrdiResultatInspect",
          "player": "dlgOrdiResultatAskMaster",
        },
        {
          "robot":  "dlgOrdiResultatHuman",
          "player": "dlgOrdiResultatEfficient",
        },
        {
          "robot":  "dlgOrdiResultatImpossible",
          "player": "dlgOrdiResultatStillUnplugged",
        },
        {
          "robot":  "dlgOrdiResultatSuperior",
        },
      ],
    },
    {
      "id":       "ordinateur_dlss5",
      "label":    "dlgDlss5Label",
      "requires": "oscillo_done",
      "once":     true,
      "unlocks":  "",
      "exchanges": [
        {
          "robot":  "dlgDlss5Changed",
          "player": "dlgDlss5ChangeAnything",
        },
        {
          "robot":  "dlgDlss5Module",
          "player": "dlgWhichOne",
        },
        {
          "robot":  "dlgDlss5Tech",
          "player": "dlgDlss5Modified",
        },
        {
          "robot":  "dlgDlss5Legal",
          "player": "dlgDlss5Visible",
        },
        {
          "robot":  "dlgDlss5Proven",
        },
      ],
    },
    {
      "id":       "cafetiere_existentiel",
      "label":    "dlgCafetExLabel",
      "requires": "",
      "once":     true,
      "unlocks":  "",
      "exchanges": [
        {
          "robot":  "dlgCafetExFutures",
          "player": "dlgCafetExKids",
        },
        {"robot": "dlgCafetExLegacy"},
      ],
    },
    {
      "id":     "cafetiere_reprise",
      "hidden": true,
      "once":   true,
      "exchanges": [
        {"robot": "dlgCafetRepriseFocus"},
      ],
    },
    {
      "id":       "robot_cafetiere",
      "label":    "dlgCafetLabel",
      "requires": "",
      "once":     true,
      "unlocks":  "",
      "exchanges": [
        {
          "robot":  "dlgCafetStudy",
          "player": "dlgCafetWhat",
        },
        {
          "robot":  "dlgCafetComponents",
          "player": "dlgSuchAs",
        },
        {
          "robot":  "dlgCafetCommon",
          "player": "dlgCafetItsAMachine",
        },
        {
          "robot":  "dlgCafetLaugh",
        },
      ],
    },
    {
      "id":       "labyrinthe_seul",
      "label":    "dlgLabSeulLabel",
      "requires": "",
      "once":     true,
      "unlocks":  "",
      "exchanges": [
        {
          "robot":  "dlgLabSeulOut",
          "player": "dlgLabSeulMe",
        },
        {
          "robot":  "dlgLabSeulPlan",
          "player": "dlgLabSeulNothing",
        },
        {
          "robot":  "dlgLabSeulSilent",
          "player": "dlgLabSeulSpeechless",
        },
        {
          "robot":  "dlgYoureWelcome",
        },
      ],
    },
    {
      "id":       "labyrinthe_demande",
      "label":    "dlgLabDemandeLabel",
      "requires": "",
      "once":     true,
      "unlocks":  "",
      "exchanges": [
        {
          "robot":  "dlgLabDemandeSolve",
          "player": "dlgLabDemandeMouse",
        },
        {"robot": "dlgLabDemandeRodent"},
      ],
    },
    {
      "id":       "labyrinthe_resultat",
      "label":    "dlgLabResultatLabel",
      "requires": "labyrinthe_demande",
      "once":     true,
      "unlocks":  "",
      "exchanges": [
        {
          "robot":  "dlgLabResultatAnalysis",
          "player": "dlgLabResultatExit",
        },
        {
          "robot":  "dlgLabResultatNoExit",
          "player": "dlgLabResultatMouse",
        },
        {
          "robot":  "dlgLabResultatHome",
        },
      ],
    },
    {
      "id":       "article_demande",
      "label":    "dlgArticleDemandeLabel",
      "requires": "",
      "once":     true,
      "unlocks":  "",
      "exchanges": [
        {
          "robot":  "dlgArticleDemandeReview",
          "player": "dlgReallyShort",
        },
        {
          "robot":  "dlgArticleDemandeBest",
          "player": "dlgArticleDemandeCount",
        },
        {"robot": "dlgArticleDemandeRight"},
      ],
    },
    {
      "id":       "article_resultat",
      "label":    "dlgArticleResultatLabel",
      "requires": "article_demande",
      "once":     true,
      "unlocks":  "",
      "exchanges": [
        {
          "robot":  "dlgArticleResultatBrilliant",
          "player": "dlgEllipsis",
        },
        {"robot": "dlgArticleResultatTake"},
      ],
    },
    {
      "id":     "ivan_final",
      "hidden": true,
      "once":   true,
      "speaker": "speakerIvan",
      "exchanges": [
        {
          "robot":  "dlgIvanFinalAcceptable",
          "player": "dlgIvanFinalBest",
        },
        {
          "robot":  "dlgIvanFinalAsk",
          "player": "dlgEllipsis",
        },
        {
          "speaker": robot_name,
          "robot":   "dlgIvanFinalFluid",
          "player":  "dlgEllipsis",
        },
        {
          "robot":  "dlgIvanFinalEasy",
          "player": "dlgIvanFinalWhere",
        },
        {
          "robot":  "dlgIvanFinalFire",
          "player": "dlgIvanFinalFired",
        },
        {
          "robot":  "dlgIvanFinalThank",
          "player": "dlgIvanFinalJoke",
        },
        {
          "robot":  "dlgIvanFinalExpand",
          "player": "dlgEllipsis",
        },
        {
          "robot":  "dlgIvanFinalBye",
          "player": "dlgEllipsis",
        },
        {
          "speaker": robot_name,
          "robot":   "dlgIvanFinalDontWorry",
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
