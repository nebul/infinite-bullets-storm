extends Node

const MIX_RATE := 22050
const PLAYER_COUNT := 8

var players: Array = []
var next_player: int = 0
var sounds: Dictionary = {}
var music_player: AudioStreamPlayer

func _ready() -> void:
	for i in range(PLAYER_COUNT):
		var p = AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	_generate_sounds()
	music_player = AudioStreamPlayer.new()
	music_player.stream = _make_music()
	music_player.volume_db = -11.0   # music sits under the SFX
	add_child(music_player)
	music_player.play()
	apply_volume()

func _generate_sounds() -> void:
	sounds["shoot"] = _tone(880.0, 0.07, 25.0, 0.16)
	sounds["explosion"] = _noise(0.35, 6.0, 0.5)
	sounds["boss"] = _noise(0.9, 2.2, 0.7)
	sounds["powerup"] = _chirp(400.0, 1200.0, 0.25, 0.3)
	sounds["player_hit"] = _chirp(500.0, 110.0, 0.3, 0.4)
	sounds["bomb"] = _noise(0.55, 3.5, 0.65)
	sounds["graze"] = _tone(1600.0, 0.04, 45.0, 0.09)      # short high tick
	sounds["phase"] = _chirp(300.0, 1000.0, 0.4, 0.45)     # rising sweep, boss phase
	sounds["death"] = _chirp(700.0, 80.0, 0.7, 0.55)       # falling, player death

# Master volume (0..1) lives on the Master bus, persisted in SaveManager.
func apply_volume() -> void:
	var v := SaveManager.master_volume
	AudioServer.set_bus_mute(0, v <= 0.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(v, 0.0001)))

func set_master_volume(v: float) -> void:
	SaveManager.set_master_volume(v)
	apply_volume()

func play(sound_name: String) -> void:
	if not sounds.has(sound_name):
		return
	var p = players[next_player]
	next_player = (next_player + 1) % players.size()
	p.stream = sounds[sound_name]
	p.play()

func _tone(freq: float, duration: float, decay: float, vol: float) -> AudioStreamWAV:
	var count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(count * 2)
	for i in range(count):
		var t = float(i) / MIX_RATE
		var env = exp(-decay * t)
		var s = sin(TAU * freq * t) * env * vol
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32767.0))
	return _wav(data)

func _noise(duration: float, decay: float, vol: float) -> AudioStreamWAV:
	var count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(count * 2)
	for i in range(count):
		var t = float(i) / MIX_RATE
		var env = exp(-decay * t)
		var s = randf_range(-1.0, 1.0) * env * vol
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32767.0))
	return _wav(data)

func _chirp(f0: float, f1: float, duration: float, vol: float) -> AudioStreamWAV:
	var count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(count * 2)
	var phase = 0.0
	for i in range(count):
		var frac = float(i) / float(count)
		var freq = lerpf(f0, f1, frac)
		phase += TAU * freq / MIX_RATE
		var env = 1.0 - frac
		var s = sin(phase) * env * vol
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32767.0))
	return _wav(data)

func _wav(data: PackedByteArray) -> AudioStreamWAV:
	var w = AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = MIX_RATE
	w.stereo = false
	w.data = data
	return w

# A looping bass + arpeggio over a minor-ish progression. No assets needed.
func _make_music() -> AudioStreamWAV:
	const BASS := [110.0, 110.0, 87.31, 98.0]            # A2 A2 F2 G2
	const ARP := [220.0, 261.63, 329.63, 261.63]         # A3 C4 E4 C4
	var loop_sec := 6.4
	var count := int(loop_sec * MIX_RATE)
	var step_sec := loop_sec / BASS.size()
	var arp_sec := step_sec / 4.0
	var data = PackedByteArray()
	data.resize(count * 2)
	for i in range(count):
		var t := float(i) / MIX_RATE
		var step := int(t / step_sec) % BASS.size()
		var local_t := fmod(t, step_sec)
		var bass := sin(TAU * BASS[step] * t) * 0.26
		var note_i := int(local_t / arp_sec) % ARP.size()
		var env := exp(-6.0 * fmod(local_t, arp_sec))
		var arp := sin(TAU * ARP[note_i] * t) * 0.15 * env
		data.encode_s16(i * 2, int(clampf(bass + arp, -1.0, 1.0) * 32767.0))
	var w := _wav(data)
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = count
	return w
