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
├── fonts/                        # Montserrat-Medium.ttf
├── i18n/                         # translation.csv (en, de)
├── savegame/
│   └── save_game.gd              # SaveGame class (static methods)
├── scenes/
│   ├── boot/
│   │   ├── bootsplash_scene      # configurable splash screen
│   │   └── godot/                # Godot splash (startup scene)
│   ├── main_menu_scene           # main menu
│   ├── ingame_scene              # main game scene
│   ├── game_settings_scene       # settings screen
│   ├── intro_scene               # introduction scene
│   └── node_example              # node example with save/load
├── settings/
│   └── user_settings.gd          # autoload UserSettings
└── ui/
    ├── components/
    │   ├── bootsplash            # Bootsplash base class
    │   ├── float_range_game_settings_option  # slider bound to UserSettings
    │   ├── game_logo             # game logo
    │   └── game_settings         # audio/language settings panel
    └── overlays/
        ├── fade_overlay          # FadeOverlay — scene transitions
        └── pause_overlay         # PauseOverlay — pause menu
```

### Startup Sequence

`godot_bootsplash_scene` → `bootsplash_scene` → `main_menu_scene` → `ingame_scene`

---

## Autoloads

### `UserSettings` (`settings/user_settings.gd`)

Manages audio settings and language, persisted in `user://settings.cfg`.

```gdscript
# Always use constants, never literal strings
UserSettings.get_value(UserSettings.MASTERVOLUME)       # correct
UserSettings.get_value("mastervolume")                  # forbidden

UserSettings.set_value(UserSettings.GAME_LANGUAGE, "fr")

# Available signal
UserSettings.on_value_change.connect(_on_setting_changed)
```

**Available key constants:**

| Constant | Description |
|---|---|
| `MASTERVOLUME` | Master volume (0–100) |
| `MUSICVOLUME` | Music volume (0–100) |
| `SOUNDVOLUME` | Sound volume (0–100) |
| `MASTERVOLUME_ENABLED` | Master enabled (bool) |
| `MUSICVOLUME_ENABLED` | Music enabled (bool) |
| `SOUNDVOLUME_ENABLED` | Sounds enabled (bool) |
| `GAME_LANGUAGE` | Locale (`"en"`, `"de"`, …) |

---

## Template Systems

### SaveGame (`savegame/save_game.gd`)

Group-based save system. Any node in the `"Persist"` group is saved automatically.

```gdscript
# In a saveable node — add to the "Persist" group in the editor
func save_data() -> Dictionary:
    return {"score": score, "current_level": current_level}

func load_data(data: Dictionary) -> void:
    score = data["score"]
    current_level = data["current_level"]
```

```gdscript
# From a scene
SaveGame.save_game(get_tree())
SaveGame.load_game(get_tree())
SaveGame.has_save()     # -> bool
SaveGame.delete_save()
```

- File: `user://savegame.save`
- Encrypted in release, plain text in debug
- Nodes added dynamically at runtime are also saved (via `scene_file_path` + `parent`)

### FadeOverlay (`ui/overlays/fade_overlay.tscn`)

Used for scene transitions. Instantiate as Scene Unique Node `%FadeOverlay`.

```gdscript
@onready var overlay := %FadeOverlay

func _ready() -> void:
    overlay.on_complete_fade_out.connect(_change_scene)
    overlay.visible = true  # starts fade-in automatically if auto_fade_in = true

func _change_scene() -> void:
    get_tree().change_scene_to_packed(next_scene)

func quit() -> void:
    overlay.fade_out()  # triggers fade-out, then emits on_complete_fade_out
```

**Configurable exports:**
- `fade_in_duration: float` (default: 2.0)
- `fade_out_duration: float` (default: 1.0)
- `auto_fade_in: bool` (default: true) — calls `fade_in()` automatically on `_ready()`
- `minimum_opacity: float` (default: 1.0)

### PauseOverlay (`ui/overlays/pause_overlay.tscn`)

```gdscript
# In ingame_scene.gd
func _input(event) -> void:
    if event.is_action_pressed("pause") and not %PauseOverlay.visible:
        get_tree().paused = true
        %PauseOverlay.grab_button_focus()
        %PauseOverlay.visible = true

# Available signal
%PauseOverlay.game_exited.connect(_save_game)
```

### BootsplashScene (`scenes/boot/bootsplash_scene.tscn`)

Generic splash screen configurable via exports:

```gdscript
@export var fade_duration: float       # fade duration
@export var stay_duration: float       # display time
@export var node: PackedScene          # scene to display (logo, etc.)
@export var next_scene: PackedScene    # next scene
@export var interruptable: bool        # "exit" action skips the splash
```

---

## Internationalization

Source file: `i18n/translation.csv` (columns: `keys`, `en`, `de`)

```gdscript
# In .tscn scenes, use TR() keys directly in the editor
# In GDScript:
label.text = tr("new_game")

# Change language
UserSettings.set_value(UserSettings.GAME_LANGUAGE, "de")
```

**Existing keys:** `new_game`, `continue`, `settings`, `leave_game`, `return_to_main`, `return_to_menu`, `settings_volume_master`, `settings_volume_music`, `settings_volume_sound`, `settings_language`, `game_paused`, `resume_game`, `credits`

---

## Input Actions

Defined in `project.godot`:

| Action | Description |
|---|---|
| `move_left/right/up/down` | Movement (WASD + arrows + joystick) |
| `interact` | Interaction (E + gamepad A button) |
| `pause` | Pause / Escape |
| `exit` | Skip a splash (Escape) |
| `ui_accept` | UI confirm (Enter, Space, A button) |

---

## GDScript Style

### Formatting

- **UTF-8** encoding, **LF** line endings, **tabs** (no spaces)
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
