# Godot Project — Guidelines

## Architecture: Call Down, Signal Up

Nodes communicate according to their position in the scene tree:

- **Downward (direct call)**: a parent can directly call its children's methods.
- **Upward (signal)**: a child must never reference its parent directly. It emits a signal that the parent listens to.
- **Laterally**: go through the common parent, or use an autoload.

```gdscript
# Child — emits a signal upward
signal life_empty
signal coin_collected(value: int)

func take_damage(damage: int) -> void:
    life -= damage
    if life <= 0:
        life_empty.emit()

# Parent — calls downward and connects signals
func _ready() -> void:
    %Player.life_empty.connect(_on_player_died)  # listens to the signal

func attack() -> void:
    %Player.take_damage(10)  # call downward
```

---

## Node Access: Scene Unique Nodes (never get_node / get_parent)

Never use `get_node("fragile/path")`, `get_parent()`, `find_child()`, or `$Deep/Path`.

Use **Scene Unique Nodes** (prefix `%`):

1. Right-click on the node in the scene tree → **"Access as Unique Name"**
2. Or add `%` at the beginning of the name when creating it

```gdscript
# Forbidden
get_node("UI/Panel/Button").text = "Go"
get_parent().life -= 10
$UI/Panel/Button.text = "Go"

# Correct
%StartButton.text = "Go"
%LifeBar.value = life
```

**Limitations**: unique nodes only work within the same scene. To traverse nested scenes:

```gdscript
get_node("%Sword/%Guard")  # mixed path across scenes
```

---

## Node Addition: Prefer .tscn over Code

When adding a node to a scene, always prefer placing it directly in the `.tscn` file via the editor rather than instantiating it in code (`.gd`).

```gdscript
# Forbidden — creating nodes in code when they could be placed in the scene
func _ready() -> void:
    var label = Label.new()
    label.text = "Score"
    add_child(label)

# Correct — node already placed in the .tscn, accessed via unique name
func _ready() -> void:
    %ScoreLabel.text = "Score"
```

Reserve runtime instantiation (`Node.new()`, `packed_scene.instantiate()`) for nodes that are **inherently dynamic**: enemies spawned during gameplay, projectiles, procedurally generated content, etc.

---

## Project Structure

```
res://
├── i18n/                  # translation.csv (colonnes : keys, fr, en)
├── assets/                # modèles GLB, textures, sons, vidéo (tribunal.ogv)
├── scenes/                # .tscn : office (niveau principal), machines, UI
├── scripts/               # .gd : machines, robot, player, dialogues, objectifs
└── utils/                 # autoloads audio + game_data
```

### Startup Sequence

`loading_scene` → `office.tscn` (écran titre → partie → écran de fin, tout dans la même scène)

---

## Autoloads

| Autoload | Fichier | Rôle |
|---|---|---|
| `GameData` | `utils/game_data.gd` | États des machines (`state`/`set_state` + enum `Machine.StateMachine`), objectifs, référence `player`, signaux globaux (`machine_state_changed`, `intro_completed`…) |
| `AudioManager` | `utils/audio_manager.gd` | Lecture des sons positionnés : `AudioManager.play(AudioData.X, position)` |
| `AudioData` | `utils/audio_data.gd` | Constantes des flux audio |

---

## Systèmes centraux

> **Note** : les anciennes sections « Template Systems » (SaveGame, UserSettings, FadeOverlay, PauseOverlay, bootsplash) décrivaient un boilerplate **non utilisé** par ce projet — ces classes n'existent pas dans le code. Il n'y a **pas de sauvegarde** : une partie se joue d'une traite (`reload_current_scene` pour recommencer).

### Machine (`scripts/machine.gd`)

Classe de base de tous les mini-jeux. Machine à états stockée dans `GameData` :

```
IDLE → TRY_MACHINE → (dialogue demande) → ROBOT_WORKING → ROBOT_DONE
     → (dialogue résultat) → TRY_MACHINE_OBJECT → (ramassage objet)
     → TRY_MACHINE_OK → UNLOCKED → SOLVED
```

Chaque machine définit `machine_name`, `dialogue_demande`/`dialogue_resultat`, `object_required` et surcharge `_can_try()` / `_on_try_machine()` (+ `is_dialogue_locked()` / `on_dialogue_completed()` si le cycle dévie).

### Dialogues

Arbres dans `scripts/dialogues_data.gd` (champs `id`, `label`, `requires`, `once`, `unlocks`, `exchanges` avec clés i18n). Moteur : `scripts/dialogue_ui.gd`. Les verrous viennent de `is_dialogue_locked()` sur les machines et le robot.

### Objectifs

Règles centralisées dans `scripts/objectives_manager.gd`, qui écoute les signaux génériques (`machine_state_changed`, `dialogue_side_effect`, `object_picked`…). Affichage : HUD (principaux), notifications machine à écrire (secondaires), overlay TAB.

---

## Internationalization

Source file: `i18n/translation.csv` (columns: `keys`, `fr`, `en`)

```gdscript
# In GDScript:
label.text = tr("msgOscilloIdle")
# Avec paramètre :
GameData.show_message(tr("msgSutomAskRobot") % [DialoguesData.robot_name], 3.0)
```

**Préfixes de clés :** `dlg*` (dialogues), `msg*` (messages HUD), `hint*` (aides d'interaction), `objective*` (objectifs), `settings*`/`btn*`/`menu*` (UI). Les champs contenant virgules ou retours à la ligne sont entre guillemets (CSV standard).

---

## Input Actions

| Action | Description |
|---|---|
| `ui_left/right/up/down` | Déplacement (ZQSD/WASD + flèches + joystick), remappés dans `project.godot` |
| `ui_accept` | Interagir / valider (Espace, Entrée) |
| `ui_cancel` | Fermer un dialogue (Échap) |
| Échap / clic droit | Quitter un mini-jeu (géré par chaque machine) |
| TAB / F1 | Overlay objectifs / options (gérés dans `office.gd`) |

---

## GDScript Style

### Formatting

- **UTF-8** encoding, **LF** line endings, **2 espaces** d'indentation (convention effective du code de ce projet)
- Lines ≤ **100 characters** (ideally ≤ 80)
- One statement per line
- Two blank lines between functions and class definitions
- One blank line to separate logical sections inside a function
- Parentheses for multi-line wrapping (never backslash `\`)
- Boolean keywords: `and`, `or`, `not` — never `&&`, `||`, `!`
- Trailing comma on multi-line arrays/dictionaries/enums
- Use `.emit()` on the signal — never `emit_signal("name", ...)`

### Naming Conventions

| Element | Convention | Example |
|---|---|---|
| Files | snake_case | `yaml_parser.gd` |
| Classes | PascalCase | `class_name YAMLParser` |
| Nodes | PascalCase | `Player`, `Camera3D` |
| Functions | snake_case | `func load_level():` |
| Variables | snake_case | `var particle_effect` |
| Signals | past tense snake_case | `signal door_opened`, `signal fade_completed` |
| Constants | CONSTANT_CASE | `const MAX_SPEED = 200` |
| Enums (name) | PascalCase | `enum Element` |
| Enums (members) | CONSTANT_CASE | `EARTH, WATER, AIR` |

- Prefix `_` for private members and methods: `var _current_life`, `func _calculate_damage()`
- Enum names in singular (`Element`, not `Elements`)

### Member Order in a Script

```gdscript
@tool                        # 1. Class annotations
class_name MyNode            # 2. class_name
extends Node2D               # 3. extends

## Documentation comment     # 4. Docstring

signal life_empty            # 5. Signals
signal coin_collected(v: int)

enum State { IDLE, RUN }     # 6. Enums

const MAX_LIFE = 100         # 7. Constants

static var _instances := 0   # 8. Static variables

@export var speed: float = 200.0  # 9. @export

var life: int = MAX_LIFE     # 10. Public variables
var _state := State.IDLE     # 11. Private variables

@onready var %LifeBar: ProgressBar  # 12. @onready

func _static_init() -> void: pass  # 13.

func _init() -> void: pass   # 14. Virtual methods
func _ready() -> void: pass
func _process(delta: float) -> void: pass
func _physics_process(delta: float) -> void: pass

func public_method() -> void: pass  # 15. Public methods
func _private_method() -> void: pass   # 16. Private methods

class InnerClass: pass       # 17. Inner classes
```

### Static Typing

Always type variables, parameters, and function return values:

```gdscript
var life: int = 100
var name: String

func take_damage(damage: int) -> void:
    life -= damage

func is_dead() -> bool:
    return life <= 0

var multiplier := 1.5  # inference when the type is obvious
```

---

## Project Organization

- `snake_case` for all files and folders (cross-platform compatibility)
- `PascalCase` for Godot nodes only
- Third-party resources in `addons/`
- Add `.gdignore` to folders to exclude from import

---

## References

- [GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- [Scene Unique Nodes](https://docs.godotengine.org/en/stable/tutorials/scripting/scene_unique_nodes.html)
- [Project Organization](https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html)
- [Best Practices Index](https://docs.godotengine.org/en/stable/tutorials/best_practices/index.html)
