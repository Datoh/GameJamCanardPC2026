extends Node

const SOUND_CONTAINER_NAME := "ContainerAudioStream"

const BUS_MUSIC := "Music"
const BUS_SOUND := "Sound"

# Audio Pool
const AUDIO_SELECTOR_POOL_SIZE = 20
var audio_pool: Array[AudioStreamPlayer3D] = []
var audio_queue: Array = []
var audio_player_music: AudioStreamPlayer

var mutex := Mutex.new()

func _ready():
  var container := Node2D.new()
  container.name = SOUND_CONTAINER_NAME
  for _i in range(AUDIO_SELECTOR_POOL_SIZE):
    var audio_player := AudioStreamPlayer3D.new()
    audio_player.bus = BUS_SOUND
    audio_player.finished.connect(_on_audio_stream_finished.bind(audio_player))
    audio_pool.append(audio_player)
    container.add_child(audio_player)

  audio_player_music = AudioStreamPlayer.new()
  audio_player_music.bus = BUS_MUSIC
  container.add_child(audio_player_music)
  add_child(container)

  #if OS.is_debug_build():
    #AudioServer.set_bus_mute(AudioServer.get_bus_index(BUS_MUSIC), true)
    #AudioServer.set_bus_mute(AudioServer.get_bus_index(BUS_SOUND), true)


func _process(_delta: float):
  mutex.lock()
  while not audio_pool.is_empty() and not audio_queue.is_empty():
    var next_in_queue = audio_queue.pop_front()
    var audio_player: AudioStreamPlayer3D = audio_pool.pop_front()
    audio_player.stream = next_in_queue[0]
    audio_player.global_position = next_in_queue[1]
    if next_in_queue[2] != -1.0:
      audio_player.max_distance = next_in_queue[2]
    audio_player.play()
  mutex.unlock()


func play(stream: AudioStream, global_position: Vector3, audio_max_distance: float = -1.0):
  if not stream:
    return
  mutex.lock()
  audio_queue.push_back([stream, global_position, audio_max_distance])
  mutex.unlock()


func play_high_priority(stream: AudioStream, global_position: Vector3, audio_max_distance: float = -1.0):
  if not stream:
    return
  mutex.lock()
  audio_queue.push_front([stream, global_position, audio_max_distance])
  mutex.unlock()


func play_music(stream: AudioStream):
  # Stop music if the new stream is null and something is playing
  if not stream:
    if audio_player_music.playing:
      audio_player_music.stop()
    audio_player_music.stream = null # Clear the stream
    return

  # Don't restart if the same music is already playing
  if audio_player_music.stream == stream and audio_player_music.playing:
    return

  audio_player_music.stream = stream
  audio_player_music.play()


func _on_audio_stream_finished(audio_player: AudioStreamPlayer3D):
  mutex.lock()
  audio_pool.append(audio_player)
  mutex.unlock()
