extends Node2D

const WORLD := Vector2(3600, 2200)
const PLAYER_SPEED := 150.0
const PLAYER_SIZE := Vector2(22, 34)
const MARKET_POS := Vector2(3040, 650)
const UPGRADE_POS := Vector2(560, 1650)
const HOUSE_POS := Vector2(1800, 1100)
const FARM_POS := Vector2(1800, 1250)
const SEED_NAMES: Array[String] = ["Tomate", "Fresa", "Calabaza", "Fruta estelar"]
const SEED_RARITY: Array[String] = ["Común", "Poco común", "Rara", "Épica"]
const SEED_PRICES: Array[int] = [15, 50, 140, 350]
const CROP_PRICES: Array[int] = [12, 35, 100, 260]
const SWORD_NAMES: Array[String] = ["Madera", "Piedra", "Oro", "Plata", "Diamante", "Obsidiana"]
const SWORD_PRICES: Array[int] = [60, 140, 300, 650, 1400]
const LIBERTY_COST := 12000
const HOTBAR_SLOTS := 5
const ITEM_SWORD := 4
const CASITA_SOURCE: Texture2D = preload("res://assets/Objects/Casita.png")
const BRAINROT_SOURCE: Texture2D = preload("res://assets/Enemies/Brainrot.png")

var rng := RandomNumberGenerator.new()
var player_pos := Vector2(1700, 1230)
var day := 1
var night_number := 0
var night_elapsed := 0.0
var coins := 24
var seeds_found := 1
var seed_counts: Array[int] = [1, 0, 0, 0]
var produce_counts: Array[int] = [0, 0, 0, 0]
var selected_seed := 0
var sword_equipped := false
var quick_slots: Array[int] = [ITEM_SWORD, 0, 1, 2, 3]
var backpack_slots: Array[int] = [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1]
var inventory_pick := -1
var planted: Array = []
var pickups: Array[Dictionary] = []
var trees: Array[Dictionary] = []
var left_path_points := PackedVector2Array()
var right_path_points := PackedVector2Array()
var rocks: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var fence_level := 0
var sword_level := 0
var grow_level := 0
var life_level := 0
var drop_level := 0
var house_hp := 400.0
var player_hp := 500.0
var player_life_level := 0
var harvest_total := 0
var attack_cooldown := 0.0
var sword_swing := 0.0
var facing := Vector2(0, 1)
var spawn_timer := 0.0
var msg := "Empiezas con una semilla. Siembra junto a tu granja."
var msg_timer := 6.0
var is_night := false
var game_over := false
var idle_frames: Array[Texture2D] = []
var walk_frames: Array[Texture2D] = []
var farm_sheet: Texture2D
var house_sprite: Texture2D
var tree_sprite: Texture2D
var fence_sprite: Texture2D
var road_sprite: Texture2D
var shop_sprite: Texture2D
var orc_walk: Texture2D
var soldier_walk: Texture2D
var brainrot_sheet: Texture2D
var chicken_sprite: Texture2D
var grass_texture: Texture2D
var road_tile_texture: Texture2D
var rock_path_texture: Texture2D
var sword_texture: Texture2D
var player_sprite: Sprite2D
var sword_display: Sprite2D
var camera: Camera2D
var market_display: Sprite2D
var upgrades_display: Sprite2D
var hud: Label
var hotbar: HBoxContainer
var hotbar_cells: Array[PanelContainer] = []
var ambient_music: AudioStreamPlayer
var menu_music: AudioStreamPlayer
var shop_open := false
var popup_mode := ""
var popup: PanelContainer
var popup_title: Label
var popup_info: Label
var popup_buttons: VBoxContainer
var popup_scroll: ScrollContainer
var start_screen: ColorRect
var splash_title: Label
var splash_body: Label
var splash_button: Button
var splash_action: Callable
var started := false
var house_rect := Rect2(HOUSE_POS - Vector2(48, 52), Vector2(96, 104))
var market_rect := Rect2(MARKET_POS - Vector2(55, 45), Vector2(110, 90))
var upgrade_rect := Rect2(UPGRADE_POS - Vector2(55, 45), Vector2(110, 90))

func _ready() -> void:
	rng.randomize()
	_load_art()
	_generate_world()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	camera = Camera2D.new()
	camera.zoom = Vector2(1.8, 1.8)
	camera.position = player_pos
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	add_child(camera)
	camera.make_current()
	player_sprite = Sprite2D.new()
	player_sprite.texture = idle_frames[0] if not idle_frames.is_empty() else null
	player_sprite.scale = Vector2(2, 2)
	player_sprite.position = player_pos
	player_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# El jugador se dibuja una sola vez en _draw(), ordenado por la base de cada sprite.
	player_sprite.visible = false
	sword_display = Sprite2D.new()
	sword_display.texture = sword_texture
	sword_display.region_enabled = true
	sword_display.scale = Vector2(0.13, 0.13)
	sword_display.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sword_shader := Shader.new()
	sword_shader.code = "shader_type canvas_item;\nvoid fragment() { vec4 c = texture(TEXTURE, UV); if (c.r > 0.94 && c.g > 0.94 && c.b > 0.94) discard; COLOR = c; }"
	var sword_material := ShaderMaterial.new()
	sword_material.shader = sword_shader
	sword_display.material = sword_material
	sword_display.visible = false
	add_child(sword_display)
	market_display = Sprite2D.new()
	market_display.texture = shop_sprite
	market_display.position = MARKET_POS
	market_display.scale = Vector2(0.13, 0.13)
	var key_shader := Shader.new()
	key_shader.code = "shader_type canvas_item;\nvoid fragment() { vec4 c = texture(TEXTURE, UV); if (c.r > 0.94 && c.g > 0.94 && c.b > 0.94) discard; COLOR = c; }"
	var key_material := ShaderMaterial.new()
	key_material.shader = key_shader
	market_display.material = key_material
	market_display.z_index = 1
	add_child(market_display)
	upgrades_display = Sprite2D.new()
	upgrades_display.texture = shop_sprite
	upgrades_display.position = UPGRADE_POS
	upgrades_display.scale = Vector2(0.13, 0.13)
	upgrades_display.material = key_material
	upgrades_display.z_index = 1
	add_child(upgrades_display)
	road_tile_texture = load("res://assets/Objects/Path Tile.png")
	rock_path_texture = load("res://assets/Objects/Rock Path.png")
	left_path_points = _sample_path([Vector2(1735, 1190), Vector2(1560, 1320), Vector2(1410, 1260), Vector2(1260, 1430), Vector2(1100, 1380), Vector2(950, 1540), Vector2(790, 1510), Vector2(640, 1640), Vector2(610, 1650)], 31.5)
	right_path_points = _sample_path([Vector2(1890, 1090), Vector2(2050, 970), Vector2(2200, 1040), Vector2(2390, 850), Vector2(2550, 900), Vector2(2730, 710), Vector2(2890, 665), Vector2(2960, 650)], 31.5)
	var layer := CanvasLayer.new()
	add_child(layer)
	_create_audio()
	hud = Label.new()
	hud.position = Vector2(14, 10)
	hud.add_theme_font_size_override("font_size", 15)
	hud.add_theme_color_override("font_color", Color("fff5d6"))
	hud.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	hud.add_theme_constant_override("shadow_offset_x", 2)
	hud.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(hud)
	_create_popup(layer)
	_create_hotbar(layer)
	_create_splash(layer)
	hud.visible = false
	_show_splash("Granja Sombría", "Cuida tu granja, planta cultivos y sobrevive a las noches.", "Jugar", _start_game)
	_update_hud()

func _create_popup(layer: CanvasLayer) -> void:
	popup = PanelContainer.new()
	popup.set_anchors_preset(Control.PRESET_CENTER)
	popup.offset_left = -230
	popup.offset_top = -270
	popup.offset_right = 230
	popup.offset_bottom = 270
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("202a27")
	panel_style.border_color = Color("d8ad66")
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(10)
	panel_style.content_margin_left = 22
	panel_style.content_margin_right = 22
	panel_style.content_margin_top = 18
	panel_style.content_margin_bottom = 18
	popup.add_theme_stylebox_override("panel", panel_style)
	popup.visible = false
	layer.add_child(popup)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	popup.add_child(layout)
	popup_title = Label.new()
	popup_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_title.add_theme_font_size_override("font_size", 23)
	popup_title.add_theme_color_override("font_color", Color("ffe0a4"))
	layout.add_child(popup_title)
	popup_info = Label.new()
	popup_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	popup_info.add_theme_font_size_override("font_size", 16)
	popup_info.add_theme_color_override("font_color", Color("f0f3e9"))
	layout.add_child(popup_info)
	popup_scroll = ScrollContainer.new()
	popup_scroll.custom_minimum_size = Vector2(405, 370)
	popup_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(popup_scroll)
	popup_buttons = VBoxContainer.new()
	popup_buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	popup_buttons.add_theme_constant_override("separation", 8)
	popup_scroll.add_child(popup_buttons)

func _create_splash(layer: CanvasLayer) -> void:
	start_screen = ColorRect.new()
	start_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	start_screen.color = Color(0.025, 0.04, 0.055, 0.94)
	start_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(start_screen)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	start_screen.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 300)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("202a27")
	style.border_color = Color("d8ad66")
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 20)
	panel.add_child(layout)
	splash_title = Label.new()
	splash_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	splash_title.add_theme_font_size_override("font_size", 28)
	splash_title.add_theme_color_override("font_color", Color("ffe0a4"))
	layout.add_child(splash_title)
	splash_body = Label.new()
	splash_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	splash_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	splash_body.add_theme_font_size_override("font_size", 18)
	splash_body.add_theme_color_override("font_color", Color("f0f3e9"))
	layout.add_child(splash_body)
	splash_button = Button.new()
	splash_button.custom_minimum_size = Vector2(240, 52)
	splash_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	splash_button.pressed.connect(_on_splash_button)
	layout.add_child(splash_button)

func _show_splash(title: String, body: String, button_text: String, action: Callable) -> void:
	splash_title.text = title
	splash_body.text = body
	splash_button.text = button_text
	splash_action = action
	start_screen.visible = true

func _on_splash_button() -> void:
	if splash_action.is_valid(): splash_action.call()

func _start_game() -> void:
	started = true
	start_screen.visible = false
	hud.visible = true
	msg = "Empiezas con una semilla de tomate y una espada de madera."
	msg_timer = 6
	_update_hud()
	_refresh_hotbar()

func _create_audio() -> void:
	ambient_music = AudioStreamPlayer.new()
	ambient_music.stream = load("res://assets/Audio/Envioroment_sound.ogg")
	ambient_music.volume_db = -15.0
	if ambient_music.stream is AudioStreamOggVorbis:
		(ambient_music.stream as AudioStreamOggVorbis).loop = true
	add_child(ambient_music)
	if ambient_music.stream:
		ambient_music.play()
	menu_music = AudioStreamPlayer.new()
	menu_music.stream = load("res://assets/Audio/Menu_sound.ogg")
	menu_music.volume_db = -10.0
	add_child(menu_music)

func _create_hotbar(layer: CanvasLayer) -> void:
	hotbar = HBoxContainer.new()
	hotbar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hotbar.offset_left = -205
	hotbar.offset_top = -70
	hotbar.offset_right = 205
	hotbar.offset_bottom = -12
	hotbar.add_theme_constant_override("separation", 5)
	layer.add_child(hotbar)
	for i in range(HOTBAR_SLOTS):
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(78, 58)
		var label := Label.new()
		label.name = "Label"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 12)
		cell.add_child(label)
		hotbar.add_child(cell)
		hotbar_cells.append(cell)
	_refresh_hotbar()

func _refresh_hotbar() -> void:
	if hotbar_cells.is_empty(): return
	for i in range(hotbar_cells.size()):
		var cell := hotbar_cells[i]
		var item := quick_slots[i]
		var selected := (item == ITEM_SWORD and sword_equipped) or (item >= 0 and item == selected_seed and not sword_equipped)
		var style := StyleBoxFlat.new()
		style.bg_color = Color("303735") if item >= 0 else Color("1c211f")
		style.border_color = Color("ffe18a") if selected else Color("8d7652")
		style.set_border_width_all(3 if selected else 2)
		style.set_corner_radius_all(4)
		cell.add_theme_stylebox_override("panel", style)
		var label: Label = cell.get_node("Label")
		if item == ITEM_SWORD:
			label.text = "%d  ESPADA\n%s" % [i + 1, SWORD_NAMES[sword_level]]
		elif item >= 0:
			label.text = "%d  %s\nx%d" % [i + 1, SEED_NAMES[item], seed_counts[item]]
		else:
			label.text = "%d\nVacío" % (i + 1)

func _show_popup(mode: String) -> void:
	popup_mode = mode
	shop_open = true
	popup.visible = true
	if mode in ["sell", "upgrade", "seeds"] and menu_music and menu_music.stream:
		menu_music.play()
	_refresh_popup()

func _refresh_popup() -> void:
	if popup == null: return
	for child in popup_buttons.get_children():
		popup_buttons.remove_child(child)
		child.queue_free()
	if popup_mode == "sell":
		popup_title.text = "Mercado de cosechas"
		popup_info.text = "Vende las plantaciones maduras que cosechaste."
		for i in range(4):
			var count: int = produce_counts[i]
			_add_popup_button("Vender %s x%d  ·  %d monedas" % [SEED_NAMES[i], count, count * CROP_PRICES[i]], _sell_crop.bind(i), count <= 0)
	elif popup_mode == "upgrade":
		popup_title.text = "Tienda de mejoras"
		popup_info.text = "Monedas: %d   ·   Espada: %s   ·   Vida: %d/%d" % [coins, SWORD_NAMES[sword_level], int(player_hp), int(_max_player_hp())]
		_add_popup_button("1  ·  Más vida para la granja  (%d)" % (40 + life_level * 45), _buy_fence)
		if sword_level < 5:
			_add_popup_button("2  ·  Espada de %s  (%d)" % [SWORD_NAMES[sword_level + 1], SWORD_PRICES[sword_level]], _buy_sword)
		else:
			_add_popup_button("2  ·  Espada de obsidiana (máximo)", _buy_sword, true)
		_add_popup_button("3  ·  Más semillas de enemigos  (%d)" % (50 + drop_level * 55), _buy_growth)
		_add_popup_button("Más vida para el jugador  (%d)" % (75 + player_life_level * 70), _buy_player_life)
		_add_popup_button("Semillas raras", _show_popup.bind("seeds"))
		_add_popup_button("libertad?  ·  %d monedas" % LIBERTY_COST, _buy_freedom)
	elif popup_mode == "seeds":
		popup_title.text = "Semillas para plantar"
		popup_info.text = "Las variedades raras cuestan más monedas."
		for i in range(4):
			_add_popup_button("%s · %s  (%d)  · tienes %d" % [SEED_NAMES[i], SEED_RARITY[i], SEED_PRICES[i], seed_counts[i]], _buy_seed.bind(i))
	else:
		popup_title.text = "Inventario"
		popup_info.text = "Barra rápida abajo · mochila al presionar I.\nElige un espacio y luego otro para intercambiarlos.  Monedas: %d" % coins
		for i in range(HOTBAR_SLOTS):
			_add_inventory_slot_button(i, true)
		for i in range(backpack_slots.size()):
			_add_inventory_slot_button(i, false)
	var close_button := Button.new()
	close_button.text = "Cerrar  ·  Esc"
	close_button.pressed.connect(_close_popup)
	popup_buttons.add_child(close_button)

func _add_popup_button(caption: String, callback: Callable, disabled: bool = false) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(390, 40)
	button.disabled = disabled
	button.pressed.connect(callback)
	popup_buttons.add_child(button)

func _item_caption(item: int) -> String:
	if item == ITEM_SWORD: return "Espada: %s" % SWORD_NAMES[sword_level]
	if item >= 0: return "%s x%d · cultivos x%d" % [SEED_NAMES[item], seed_counts[item], produce_counts[item]]
	return "Vacío"

func _add_inventory_slot_button(slot: int, is_quick: bool) -> void:
	var item := quick_slots[slot] if is_quick else backpack_slots[slot]
	var index := slot if is_quick else HOTBAR_SLOTS + slot
	var marker := "  ← elige destino" if inventory_pick == index else ""
	var place := "Barra %d" % (slot + 1) if is_quick else "Mochila %d" % (slot + 1)
	_add_popup_button("%s: %s%s" % [place, _item_caption(item), marker], _inventory_slot_pressed.bind(index))

func _inventory_slot_pressed(index: int) -> void:
	if inventory_pick < 0:
		inventory_pick = index
		_refresh_popup()
		return
	if inventory_pick == index:
		inventory_pick = -1
		_refresh_popup()
		return
	var first_item := _get_inventory_slot(inventory_pick)
	_set_inventory_slot(inventory_pick, _get_inventory_slot(index))
	_set_inventory_slot(index, first_item)
	inventory_pick = -1
	_refresh_hotbar()
	_refresh_popup()

func _get_inventory_slot(index: int) -> int:
	return quick_slots[index] if index < HOTBAR_SLOTS else backpack_slots[index - HOTBAR_SLOTS]

func _set_inventory_slot(index: int, item: int) -> void:
	if index < HOTBAR_SLOTS: quick_slots[index] = item
	else: backpack_slots[index - HOTBAR_SLOTS] = item

func _sell_crop(seed_id: int) -> void:
	var sold: int = produce_counts[seed_id]
	if sold <= 0: return
	var earned: int = sold * CROP_PRICES[seed_id]
	coins += earned
	produce_counts[seed_id] = 0
	msg = "Vendiste %d plantaciones de %s por %d monedas." % [sold, SEED_NAMES[seed_id], earned]
	msg_timer = 4
	_refresh_popup()

func _buy_seed(seed_id: int) -> void:
	if coins >= SEED_PRICES[seed_id]:
		coins -= SEED_PRICES[seed_id]
		seed_counts[seed_id] += 1
		msg = "Compraste una semilla de %s." % SEED_NAMES[seed_id]
	else: msg = "Necesitas %d monedas para esa semilla." % SEED_PRICES[seed_id]
	msg_timer = 3
	_refresh_hotbar()
	_refresh_popup()

func _select_seed(seed_id: int) -> void:
	selected_seed = seed_id
	msg = "Semilla seleccionada: %s." % SEED_NAMES[seed_id]
	msg_timer = 3
	_refresh_popup()

func _buy_freedom() -> void:
	if coins < LIBERTY_COST:
		msg = "La libertad cuesta %d monedas." % LIBERTY_COST
		msg_timer = 3
		_refresh_popup()
		return
	coins -= LIBERTY_COST
	_show_ending("abandonas el campo y llegas a la cuidas...pero, que tienes aca? nada...empiezas desde 0 en un mundo que aun desconoces")

func _close_popup() -> void:
	shop_open = false
	popup_mode = ""
	inventory_pick = -1
	popup.visible = false

func _load_art() -> void:
	for i in range(1, 13):
		var p := "res://assets/Character/Idle_%02d.png" % i
		if ResourceLoader.exists(p): idle_frames.append(load(p))
	for i in range(1, 19):
		var p := "res://assets/Character/Walk_%02d.png" % i
		if ResourceLoader.exists(p): walk_frames.append(load(p))
	farm_sheet = load("res://assets/Objects/Spring Crops.png")
	sword_texture = load("res://assets/Objects/Espadas.png")
	house_sprite = _load_keyed_texture(CASITA_SOURCE)
	tree_sprite = load("res://assets/Objects/Maple Tree_01.png")
	fence_sprite = load("res://assets/Objects/Fence's copiar_01.png")
	road_sprite = load("res://assets/Objects/Road copiar_01.png")
	# The right-hand road uses the supplied rock path sprite.
	shop_sprite = load("res://assets/Shop/merchant.png")
	orc_walk = load("res://assets/Enemies/Orc_Walk.png")
	soldier_walk = load("res://assets/Enemies/Soldier_Walk.png")
	brainrot_sheet = _load_keyed_texture(BRAINROT_SOURCE)
	chicken_sprite = load("res://assets/Farm Animals/Baby Chicken Yellow_01.png")
	grass_texture = load("res://assets/Objects/Grass Mundo.png")

func _load_keyed_texture(source_texture: Texture2D) -> Texture2D:
	# El preload y el acceso a la textura importada conservan el recurso dentro del PCK exportado.
	if source_texture == null: return null
	var image := source_texture.get_image()
	if image == null or image.is_empty(): return source_texture
	image.convert(Image.FORMAT_RGBA8)
	# Quita el fondo blanco y gris claro conectado a los bordes, pero preserva ojos y brillos internos.
	var width := image.get_width()
	var height := image.get_height()
	var pending: Array[Vector2i] = []
	for x in range(width):
		pending.append(Vector2i(x, 0))
		pending.append(Vector2i(x, height - 1))
	for y in range(1, height - 1):
		pending.append(Vector2i(0, y))
		pending.append(Vector2i(width - 1, y))
	var cursor := 0
	while cursor < pending.size():
		var point := pending[cursor]
		cursor += 1
		var pixel := image.get_pixelv(point)
		if pixel.a == 0.0: continue
		var darkest := minf(pixel.r, minf(pixel.g, pixel.b))
		var brightest := maxf(pixel.r, maxf(pixel.g, pixel.b))
		if darkest < 0.68 or brightest - darkest > 0.12: continue
		pixel.a = 0.0
		image.set_pixelv(point, pixel)
		if point.x > 0: pending.append(point + Vector2i.LEFT)
		if point.x < width - 1: pending.append(point + Vector2i.RIGHT)
		if point.y > 0: pending.append(point + Vector2i.UP)
		if point.y < height - 1: pending.append(point + Vector2i.DOWN)
	return ImageTexture.create_from_image(image)

func _sample_path(points: Array, spacing: float) -> PackedVector2Array:
	var samples := PackedVector2Array()
	for segment in range(points.size() - 1):
		var start: Vector2 = points[segment]
		var finish: Vector2 = points[segment + 1]
		var steps := int(ceil(start.distance_to(finish) / spacing))
		for step in range(steps):
			samples.append(start.lerp(finish, float(step) / float(steps)))
	samples.append(points[points.size() - 1])
	return samples

func _generate_world() -> void:
	trees.clear()
	rocks.clear()
	pickups.clear()
	planted.clear()
	for i in range(6): planted.append(null)
	var safe_areas := [HOUSE_POS, MARKET_POS, UPGRADE_POS, FARM_POS, Vector2(1650, 1040), Vector2(1980, 1040), Vector2(2020, 1450), Vector2(1735, 1190), Vector2(1560, 1320), Vector2(1410, 1260), Vector2(1260, 1430), Vector2(1100, 1380), Vector2(950, 1540), Vector2(790, 1510), Vector2(640, 1640), Vector2(610, 1650), Vector2(1890, 1090), Vector2(2050, 970), Vector2(2200, 1040), Vector2(2390, 850), Vector2(2550, 900), Vector2(2730, 710), Vector2(2890, 665), Vector2(2960, 650)]
	for i in range(420):
		var p := Vector2(rng.randf_range(65, WORLD.x - 65), rng.randf_range(75, WORLD.y - 75))
		var safe := false
		if _near_path(p, [Vector2(1735, 1190), Vector2(1560, 1320), Vector2(1410, 1260), Vector2(1260, 1430), Vector2(1100, 1380), Vector2(950, 1540), Vector2(790, 1510), Vector2(640, 1640), Vector2(610, 1650)], 100): safe = true
		if _near_path(p, [Vector2(1890, 1090), Vector2(2050, 970), Vector2(2200, 1040), Vector2(2390, 850), Vector2(2550, 900), Vector2(2730, 710), Vector2(2890, 665), Vector2(2960, 650)], 100): safe = true
		if p.x > WORLD.x - 230: safe = true
		for center in safe_areas:
			if p.distance_to(center) < 155: safe = true
		if safe: continue
		var crowded := false
		for tree in trees:
			if p.distance_to(tree.pos) < 135:
				crowded = true
				break
		if crowded: continue
		trees.append({"pos": p, "scale": rng.randf_range(1.5, 2.0)})
	# Bosque sólido en los cuatro extremos: es el borde real del mundo.
	for edge_x in range(5):
		for row in range(-1, int(WORLD.y / 34.0) + 2):
			trees.append({"pos": Vector2(42 + edge_x * 31, 18 + row * 34), "scale": 1.7})
			trees.append({"pos": Vector2(WORLD.x - 42 - edge_x * 31, 18 + row * 34), "scale": 1.7})
	for edge_y in range(5):
		for col in range(2, int(WORLD.x / 34.0) - 2):
			trees.append({"pos": Vector2(18 + col * 34, 42 + edge_y * 31), "scale": 1.7})
			trees.append({"pos": Vector2(18 + col * 34, WORLD.y - 42 - edge_y * 31), "scale": 1.7})
	queue_redraw()

func _near_path(point: Vector2, points: Array, clearance: float) -> bool:
	for route_point in points:
		if point.distance_to(route_point) < clearance: return true
	return false

func _process(delta: float) -> void:
	if not started or game_over: return
	if is_night:
		night_elapsed += delta
		_night_spawning(delta)
		_move_enemies(delta)
		if night_elapsed >= 30.0 + night_number * 5.0:
			is_night = false
			night_number += 1
			night_elapsed = 0
			day += 1
			enemies.clear()
			player_hp = _max_player_hp()
			for crop_index in range(planted.size()):
				if planted[crop_index] != null:
					planted[crop_index].growth = minf(7.0, planted[crop_index].growth + 1.0)
			msg = "Amaneció el día %d. E en casa para saltar a la siguiente noche." % day
			msg_timer = 5.0
	else:
		house_hp = minf(_max_house_hp(), house_hp + delta * 1.25)
	if not shop_open: _move_player(delta)
	camera.position = player_pos
	_update_sword_display()
	attack_cooldown = maxf(0, attack_cooldown - delta)
	sword_swing = maxf(0, sword_swing - delta)
	msg_timer = maxf(0, msg_timer - delta)
	if not shop_open and Input.is_key_pressed(KEY_SPACE) and attack_cooldown == 0:
		if sword_equipped: _attack()
		else:
			msg = "Equipa la espada con la tecla 1 antes de atacar."
			msg_timer = 1.4
	_animate_player()
	var night_tint := Color(0.48, 0.52, 0.66) if is_night else Color.WHITE
	market_display.modulate = night_tint
	upgrades_display.modulate = night_tint
	_update_hud()
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo: return
	if not started or game_over: return
	if event.keycode == KEY_I and not shop_open:
		_show_popup("inventory")
		return
	if event.keycode >= KEY_1 and event.keycode <= KEY_5 and not shop_open:
		_select_hotbar_slot(event.keycode - KEY_1)
		return
	if event.keycode == KEY_0 and not shop_open:
		sword_equipped = false
		msg = "Manos vacías."
		msg_timer = 2
		_refresh_hotbar()
		_update_sword_display()
		return
	if event.keycode == KEY_Q and not shop_open:
		_cycle_seed()
		return
	if event.keycode == KEY_E and not shop_open:
		_interact()
	elif shop_open:
		if event.keycode == KEY_ESCAPE: _close_popup()
		elif popup_mode == "upgrade":
			if event.keycode == KEY_1: _buy_fence()
			elif event.keycode == KEY_2: _buy_sword()
			elif event.keycode == KEY_3: _buy_growth()
			elif event.keycode == KEY_4: _show_popup("seeds")
		elif popup_mode == "seeds":
			if event.keycode == KEY_1: _buy_seed(0)
			elif event.keycode == KEY_2: _buy_seed(1)
			elif event.keycode == KEY_3: _buy_seed(2)
			elif event.keycode == KEY_4: _buy_seed(3)

func _cycle_seed() -> void:
	for offset in range(1, HOTBAR_SLOTS + 1):
		var slot := (quick_slots.find(selected_seed) + offset) % HOTBAR_SLOTS
		_select_hotbar_slot(slot, false)
		if quick_slots[slot] >= 0 and quick_slots[slot] != ITEM_SWORD and seed_counts[quick_slots[slot]] > 0: return

func _select_hotbar_slot(slot: int, announce: bool = true) -> void:
	var item := quick_slots[slot]
	if item < 0: return
	if item == ITEM_SWORD:
		sword_equipped = true
		msg = "Espada equipada: %s." % SWORD_NAMES[sword_level]
	else:
		sword_equipped = false
		selected_seed = item
		msg = "Semilla seleccionada: %s." % SEED_NAMES[item]
	if announce: msg_timer = 2
	_refresh_hotbar()
	_update_sword_display()

func _update_sword_display() -> void:
	if sword_display == null: return
	sword_display.visible = sword_equipped and sword_texture != null
	if not sword_display.visible: return
	var direction := facing.normalized()
	var angle := direction.angle()
	var swing_progress := 1.0 - sword_swing / 0.24
	var swing_angle := lerpf(-0.7, 0.8, clampf(swing_progress, 0.0, 1.0)) if sword_swing > 0 else 0.0
	sword_display.position = player_pos + direction * 17.0 + Vector2(0, -8)
	sword_display.rotation = angle + swing_angle - 0.7
	sword_display.scale = Vector2(0.075, 0.075)
	# La imagen trae cinco espadas: madera, piedra, metal, diamante y obsidiana.
	match sword_level:
		0: sword_display.region_rect = Rect2(42, 132, 350, 420)
		1: sword_display.region_rect = Rect2(450, 132, 360, 420)
		2, 3: sword_display.region_rect = Rect2(862, 132, 350, 420)
		4: sword_display.region_rect = Rect2(170, 680, 380, 430)
		_: sword_display.region_rect = Rect2(700, 680, 380, 430)

func _move_player(delta: float) -> void:
	var d := Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
	d.x += float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	d.y += float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	if d.length_squared() > 0: d = d.normalized()
	if d.length_squared() > 0: facing = d
	var next := player_pos + d * PLAYER_SPEED * delta
	next.x = clampf(next.x, 165, WORLD.x - 165)
	next.y = clampf(next.y, 165, WORLD.y - 165)
	if not _blocked(Vector2(next.x, player_pos.y)): player_pos.x = next.x
	if not _blocked(Vector2(player_pos.x, next.y)): player_pos.y = next.y

func _blocked(p: Vector2) -> bool:
	if p.x < 165 or p.x > WORLD.x - 165 or p.y < 165 or p.y > WORLD.y - 165: return true
	# Sólo se bloquea la base; así el personaje no puede entrar en un edificio ni un tronco.
	if Rect2(HOUSE_POS - Vector2(52, 38), Vector2(104, 112)).has_point(p): return true
	# Las tiendas usan la huella completa de sus sprites escalados, no sólo la puerta.
	if Rect2(MARKET_POS - Vector2(86, 72), Vector2(172, 144)).has_point(p): return true
	if Rect2(UPGRADE_POS - Vector2(86, 72), Vector2(172, 144)).has_point(p): return true
	# Los tres corrales son sólidos: las cercas y los animales no se pueden atravesar.
	if Rect2(Vector2(1650, 1040) - Vector2(70, 45), Vector2(140, 90)).grow(5).has_point(p): return true
	if Rect2(Vector2(1980, 1040) - Vector2(65, 45), Vector2(130, 90)).grow(5).has_point(p): return true
	if Rect2(Vector2(2020, 1450) - Vector2(70, 45), Vector2(140, 90)).grow(5).has_point(p): return true
	for t in trees:
		var trunk := Rect2(t.pos + Vector2(-8, 9) * t.scale, Vector2(16, 17) * t.scale)
		if trunk.grow(4).has_point(p): return true
	for r in rocks:
		if p.distance_to(r.pos) < r.r + 10: return true
	return false

func _animate_player() -> void:
	if player_sprite == null: return
	var moving := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down").length() > 0 or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_D)
	if moving and not walk_frames.is_empty(): player_sprite.texture = walk_frames[int(Time.get_ticks_msec() / 65) % walk_frames.size()]
	elif not idle_frames.is_empty(): player_sprite.texture = idle_frames[int(Time.get_ticks_msec() / 120) % idle_frames.size()]

func _interact() -> void:
	if player_pos.distance_to(MARKET_POS) < 145:
		_show_popup("sell")
		return
	if player_pos.distance_to(UPGRADE_POS) < 145:
		_show_popup("upgrade")
		return
	if player_pos.distance_to(HOUSE_POS) < 120:
		if not is_night:
			is_night = true
			night_elapsed = 0
			spawn_timer = 0
			msg = "Saltaste el día %d. ¡Sobrevive la noche!" % day
			msg_timer = 4
		else:
			msg = "La casa está bajo ataque. Sobrevive hasta el amanecer."
			msg_timer = 3
		return
	for i in range(6):
		var p := FARM_POS + Vector2((i % 3) * 40 - 40, floori(float(i) / 3.0) * 42)
		if player_pos.distance_to(p) < 42:
			if planted[i] != null and planted[i].growth >= 7:
				var crop_id: int = planted[i].crop
				planted[i] = null
				seed_counts[crop_id] += 1
				produce_counts[crop_id] += 1
				harvest_total += 1
				msg = "¡Cosechaste %s! Recibiste 1 semilla y 1 plantación." % SEED_NAMES[crop_id]
			elif planted[i] != null:
				msg = "Crece durante 7 días. Día %d/7." % int(planted[i].growth)
			elif seed_counts[selected_seed] > 0:
				seed_counts[selected_seed] -= 1
				planted[i] = {"pos": p, "growth": 0.0, "crop": selected_seed}
				msg = "Sembraste %s. Madurará al pasar siete noches." % SEED_NAMES[selected_seed]
			else: msg = "No tienes semillas de %s. Pulsa Q para cambiar de variedad." % SEED_NAMES[selected_seed]
			msg_timer = 3
			_refresh_hotbar()
			return
func _night_spawning(delta: float) -> void:
	spawn_timer -= delta
	var max_enemies := 2 + day
	if spawn_timer <= 0 and enemies.size() < max_enemies:
		var p := player_pos + Vector2(rng.randf_range(-310, 310), rng.randf_range(-240, 240))
		p.x = clampf(p.x, 30, WORLD.x - 30)
		p.y = clampf(p.y, 30, WORLD.y - 30)
		var roll := rng.randi_range(1, 100)
		var kind := "orc" if rng.randf() < 0.5 else "soldier"
		if roll == 67: kind = "67"
		elif roll <= 2: kind = "tung"
		enemies.append({"pos": p, "hp": 2 + floori(float(day - 2) / 7.0), "speed": rng.randf_range(32, 48) + day * 1.2, "kind": kind, "attack": 0.0})
		spawn_timer = maxf(2.4, 7.0 - day * 0.35)

func _move_enemies(delta: float) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var e: Dictionary = enemies[i]
		var target := HOUSE_POS
		if player_pos.distance_to(e.pos) < 100: target = player_pos
		var vec: Vector2 = (target - e.pos).normalized()
		var next: Vector2 = e.pos + vec * e.speed * delta
		e.pos = next
		e.attack = maxf(0, e.attack - delta)
		if e.attack == 0:
			if e.pos.distance_to(player_pos) < 46:
				player_hp = maxf(0, player_hp - (12.0 + day * 0.7))
				e.attack = 1.0
				msg = "¡Te golpearon! Vida: %d/%d" % [int(player_hp), int(_max_player_hp())]
				msg_timer = 1.2
			elif e.pos.distance_to(HOUSE_POS) < 68:
				house_hp = maxf(0, house_hp - (2.0 + day * 0.2))
				e.attack = 1.3
		enemies[i] = e
		if e.hp <= 0: enemies.remove_at(i)
	if house_hp <= 0:
		_show_ending("lo has perdido todo, levantate y renace desde 0")
	elif player_hp <= 0:
		_show_ending("lo has perdido todo, levantate y renace desde 0")

func _attack() -> void:
	attack_cooldown = 0.42
	sword_swing = 0.24
	var reach := 80.0 + sword_level * 14.0
	var defeated := false
	for i in range(enemies.size() - 1, -1, -1):
		if player_pos.distance_to(enemies[i].pos) < reach:
			enemies[i].hp -= 1 + sword_level
			enemies[i].pos += (enemies[i].pos - player_pos).normalized() * 18
			if enemies[i].hp <= 0:
				defeated = true
				coins += 2
				var denominator := _seed_drop_denominator()
				if rng.randi_range(1, denominator) == 1:
					var seed_id := _roll_seed_type()
					seed_counts[seed_id] += 1
					seeds_found += 1
					msg = "¡El enemigo soltó semilla de %s! Próxima caída: 1/%d" % [SEED_NAMES[seed_id], _seed_drop_denominator()]
					msg_timer = 3.0
				enemies.remove_at(i)
	_refresh_hotbar()
	if not defeated:
		msg = "¡Tajo! Espada nivel %d" % (sword_level + 1)
		msg_timer = 1.2

func _buy_sword() -> void:
	if sword_level >= 5:
		msg = "Ya tienes la espada de obsidiana."
		msg_timer = 2.5
		_refresh_popup()
		return
	var cost: int = SWORD_PRICES[sword_level]
	if coins >= cost:
		coins -= cost
		sword_level += 1
		msg = "Mejoraste tu espada a %s." % SWORD_NAMES[sword_level]
	else: msg = "La mejora cuesta %d monedas." % cost
	msg_timer = 2.5
	_refresh_hotbar()
	_update_sword_display()
	_refresh_popup()

func _buy_fence() -> void:
	var cost := 40 + life_level * 45
	if coins >= cost and life_level < 8:
		coins -= cost; life_level += 1; msg = "Vida máxima de la granja: %d." % _max_house_hp()
		house_hp = minf(_max_house_hp(), house_hp + 25)
	else: msg = "Mejora de vida: %d monedas." % cost
	msg_timer = 2.5
	_refresh_popup()

func _buy_growth() -> void:
	var cost := 50 + drop_level * 55
	if coins >= cost and drop_level < 8:
		coins -= cost; drop_level += 1; msg = "Mejor posibilidad de encontrar semillas. Nivel %d" % drop_level
	else: msg = "Mejora de semillas: %d monedas." % cost
	msg_timer = 2.5
	_refresh_popup()

func _buy_player_life() -> void:
	var cost := 75 + player_life_level * 70
	if coins >= cost and player_life_level < 10:
		coins -= cost
		player_life_level += 1
		player_hp = _max_player_hp()
		msg = "Vida máxima del jugador: %d." % int(_max_player_hp())
	else:
		msg = "Mejora de vida del jugador: %d monedas." % cost
	msg_timer = 2.5
	_refresh_popup()

func _max_house_hp() -> float:
	return 400.0 + life_level * 25.0

func _max_player_hp() -> float:
	return 500.0 + player_life_level * 100.0

func _seed_drop_denominator() -> int:
	var base_denominator := 20
	if seeds_found == 2: base_denominator = 80
	elif seeds_found >= 3: base_denominator = 150 + (seeds_found - 3) * 80
	return maxi(3, base_denominator - drop_level * 4)

func _roll_seed_type() -> int:
	var roll := rng.randi_range(1, 100)
	if roll == 100: return 3
	if roll >= 93: return 2
	if roll >= 70: return 1
	return 0

func _show_ending(message: String) -> void:
	game_over = true
	shop_open = false
	popup.visible = false
	var title := "Final: libertad" if message.begins_with("abandonas") else "Final: la granja cayó"
	_show_splash(title, message, "Renacer desde 0", _restart_run)

func _restart_run() -> void:
	_new_game()
	started = true
	hud.visible = true
	start_screen.visible = false

func _new_game() -> void:
	day = 1; night_number = 0; night_elapsed = 0; coins = 24; seeds_found = 1; seed_counts = [1, 0, 0, 0]; produce_counts = [0, 0, 0, 0]; selected_seed = 0; sword_equipped = false; quick_slots = [ITEM_SWORD, 0, 1, 2, 3]; backpack_slots = [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1]; planted.clear()
	enemies.clear(); house_hp = 400; player_hp = 500; player_life_level = 0; sword_level = 0; grow_level = 0; fence_level = 0; life_level = 0; drop_level = 0
	player_pos = Vector2(1700, 1230); game_over = false; shop_open = false; is_night = false
	msg = "Empiezas con una semilla de tomate y una espada de madera."
	msg_timer = 6
	shop_open = false
	popup_mode = ""
	popup.visible = false
	_generate_world()
	_refresh_hotbar()

func _update_hud() -> void:
	if hud == null: return
	var phase := "NOCHE (%ds)" % int(ceil(30.0 + night_number * 5.0 - night_elapsed)) if is_night else "DÍA (infinito)"
	var status := "Casa %d/%d  ·  Vida %d/%d  ·  Monstruos Nv.%d" % [int(house_hp), int(_max_house_hp()), int(player_hp), int(_max_player_hp()), 1 + floori(float(day - 1) / 7.0)]
	hud.text = "DÍA %d  ·  %s\nMonedas: %d  ·  Semillas: %d  ·  Plantaciones: %d\nSeleccionada: %s x%d  ·  Espada: %s\n%s\nWASD mover · E usar · I inventario · Q cambiar semilla · Espacio atacar" % [day, phase, coins, _total_seeds(), _total_produce(), SEED_NAMES[selected_seed], seed_counts[selected_seed], SWORD_NAMES[sword_level], status]
	if not is_night and not game_over: hud.text += "\nE en la casa para avanzar a la noche"
	if msg_timer > 0: hud.text += "\n" + msg
	if game_over: hud.text += "\n\nFIN DE LA PARTIDA · Pulsa ENTER para volver a empezar"

func _total_seeds() -> int:
	var total := 0
	for count in seed_counts: total += count
	return total

func _total_produce() -> int:
	var total := 0
	for count in produce_counts: total += count
	return total

func _draw() -> void:
	if grass_texture:
		# Se usa sólo el cuadro de césped, sin los márgenes blancos de la imagen entregada.
		var grass_tile := Vector2(748, 808)
		for column in range(int(ceil(WORLD.x / grass_tile.x))):
			for row in range(int(ceil(WORLD.y / grass_tile.y))):
				var tile_width := minf(grass_tile.x, WORLD.x - column * grass_tile.x)
				var tile_height := minf(grass_tile.y, WORLD.y - row * grass_tile.y)
				var dest := Rect2(Vector2(column * grass_tile.x, row * grass_tile.y), Vector2(tile_width, tile_height))
				var source := Rect2(258, 230, 748 * tile_width / grass_tile.x, 808 * tile_height / grass_tile.y)
				draw_texture_rect_region(grass_texture, dest, source)
	else:
		draw_rect(Rect2(Vector2.ZERO, WORLD), Color("527b43"))
	# Sin caminos: los letreros cerca de la granja orientan hacia las dos tiendas.
	_draw_sign(FARM_POS + Vector2(-155, 72), "← MEJORAS")
	_draw_sign(FARM_POS + Vector2(155, -70), "MERCADO →")
	# Plantación y casillas.
	for i in range(6):
		var p := FARM_POS + Vector2((i % 3) * 40 - 40, floori(float(i) / 3.0) * 42)
		draw_rect(Rect2(p - Vector2(15, 14), Vector2(30, 28)), Color("79523a"))
		draw_rect(Rect2(p - Vector2(12, 11), Vector2(24, 22)), Color("95633e"))
		if planted[i] != null:
			var age_days: float = planted[i].growth
			var g: float = clampf(age_days / 7.0, 0.0, 1.0)
			var crop_id: int = planted[i].crop
			var row_y := 16 + crop_id * 32
			var source := Rect2(128 + crop_id * 16, row_y, 16, 16) if age_days >= 7 else Rect2(clampi(int(g * 5.99), 0, 5) * 16, row_y, 16, 16)
			draw_texture_rect_region(farm_sheet, Rect2(p - Vector2(15, 20), Vector2(30, 30)), source)
	# Cercas y objetos. La casa se ordena abajo junto con jugador y árboles.
	draw_rect(Rect2(UPGRADE_POS - Vector2(42, 25), Vector2(84, 52)), Color("775137"))
	draw_colored_polygon(PackedVector2Array([UPGRADE_POS + Vector2(-50, -25), UPGRADE_POS + Vector2(0, -58), UPGRADE_POS + Vector2(50, -25)]), Color("426e82"))
	draw_string(ThemeDB.fallback_font, UPGRADE_POS + Vector2(-31, -73), "MEJORAS", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	if fence_level > 0 and fence_sprite:
		var count := fence_level * 5
		for i in range(count):
			var p := HOUSE_POS + Vector2(-90 + i * (180.0 / maxf(1, count - 1)), 76)
			draw_texture_rect(fence_sprite, Rect2(p, Vector2(24, 18)), false)
	# Un corral inicial y dos adicionales, todos decorativos.
	_draw_corral(Vector2(1650, 1040), Vector2(140, 90), 3)
	_draw_corral(Vector2(1980, 1040), Vector2(130, 90), 3)
	_draw_corral(Vector2(2020, 1450), Vector2(140, 90), 4)
	for rock in rocks: draw_circle(rock.pos, rock.r, Color("858d7c"))
	for item in pickups:
		if not item.taken:
			draw_circle(item.pos, 11, Color(1.0, 0.8, 0.15, 0.25))
			draw_colored_polygon(PackedVector2Array([item.pos + Vector2(0, -8), item.pos + Vector2(8, 0), item.pos + Vector2(0, 8), item.pos + Vector2(-8, 0)]), Color("ffe17b"))
	var depth_items: Array[Dictionary] = []
	depth_items.append({"depth": HOUSE_POS.y + 73, "kind": "house", "item": {}})
	for tree in trees:
		depth_items.append({"depth": tree.pos.y + 25 * tree.scale, "kind": "tree", "item": tree})
	depth_items.append({"depth": player_pos.y + 20, "kind": "player", "item": {}})
	for enemy in enemies:
		depth_items.append({"depth": enemy.pos.y + 96, "kind": "enemy", "item": enemy})
	depth_items.sort_custom(func(a, b): return float(a["depth"]) < float(b["depth"]))
	for drawable in depth_items:
		if drawable.kind == "house":
			if house_sprite: draw_texture_rect(house_sprite, Rect2(HOUSE_POS - Vector2(110, 125), Vector2(220, 250)), false)
		elif drawable.kind == "tree":
			var tree: Dictionary = drawable.item
			if tree_sprite: draw_texture_rect(tree_sprite, Rect2(tree.pos - Vector2(18, 25) * tree.scale, Vector2(36, 50) * tree.scale), false)
		elif drawable.kind == "player":
			if player_sprite.texture: draw_texture_rect(player_sprite.texture, Rect2(player_pos - Vector2(12, 20), Vector2(24, 40)), false)
		else:
			var enemy: Dictionary = drawable.item
			var pos: Vector2 = enemy.pos
			var enemy_texture: Texture2D = brainrot_sheet if brainrot_sheet else (orc_walk if enemy.kind in ["orc", "tung", "67"] else soldier_walk)
			var frame := int(Time.get_ticks_msec() / 150) % 8
			var brainrot_row := 0
			if enemy.kind == "soldier" or enemy.kind == "tung": brainrot_row = 1
			elif enemy.kind == "67": brainrot_row = 2
			var source := Rect2(frame * 158, [140, 500, 860][brainrot_row], 158, [295, 270, 265][brainrot_row]) if brainrot_sheet else Rect2(frame * 100, 0, 100, 100)
			var size := Vector2(56, 84) if brainrot_sheet else Vector2(144, 196)
			if enemy_texture: draw_texture_rect_region(enemy_texture, Rect2(pos - size / 2, size), source)
			else: draw_circle(pos, 33, Color("090d17"))
			if enemy.kind == "tung": draw_string(ThemeDB.fallback_font, pos + Vector2(-31, -100), "TUNG", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("f2ccaa"))
			elif enemy.kind == "67": draw_string(ThemeDB.fallback_font, pos + Vector2(-11, -100), "67", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("ffffff"))
	if is_night:
		draw_rect(Rect2(Vector2.ZERO, WORLD), Color(0.02, 0.03, 0.13, 0.31))
		# Luz cálida alrededor de casa, estilo halo.
		draw_circle(HOUSE_POS, 145, Color(1.0, 0.72, 0.3, 0.07))

func _draw_sign(position: Vector2, caption: String) -> void:
	draw_rect(Rect2(position + Vector2(-3, 10), Vector2(6, 26)), Color("4d3019"))
	draw_rect(Rect2(position + Vector2(-52, -17), Vector2(104, 29)), Color("6c4525"))
	draw_rect(Rect2(position + Vector2(-49, -14), Vector2(98, 23)), Color("a66b37"))
	draw_string(ThemeDB.fallback_font, position + Vector2(-43, 2), caption, HORIZONTAL_ALIGNMENT_CENTER, 86, 11, Color("fff0c2"))

func _draw_corral(center: Vector2, size: Vector2, animal_count: int) -> void:
	draw_rect(Rect2(center - size / 2, size), Color(0.26, 0.43, 0.24, 0.36))
	var left := center.x - size.x / 2
	var right := center.x + size.x / 2
	var top := center.y - size.y / 2
	var bottom := center.y + size.y / 2
	var gate := 18.0
	draw_line(Vector2(left, top), Vector2(right, top), Color("50361f"), 7)
	draw_line(Vector2(left, top + 7), Vector2(right, top + 7), Color("b17b48"), 3)
	draw_line(Vector2(left, top), Vector2(left, bottom), Color("50361f"), 7)
	draw_line(Vector2(left + 7, top), Vector2(left + 7, bottom), Color("b17b48"), 3)
	draw_line(Vector2(right, top), Vector2(right, bottom), Color("50361f"), 7)
	draw_line(Vector2(right - 7, top), Vector2(right - 7, bottom), Color("b17b48"), 3)
	draw_line(Vector2(left, bottom), Vector2(center.x - gate, bottom), Color("50361f"), 7)
	draw_line(Vector2(center.x + gate, bottom), Vector2(right, bottom), Color("50361f"), 7)
	draw_line(Vector2(left, bottom - 7), Vector2(center.x - gate, bottom - 7), Color("b17b48"), 3)
	draw_line(Vector2(center.x + gate, bottom - 7), Vector2(right, bottom - 7), Color("b17b48"), 3)
	for x in range(int(left), int(right) + 1, 35):
		draw_rect(Rect2(Vector2(x - 3, top - 5), Vector2(6, 14)), Color("684324"))
		draw_rect(Rect2(Vector2(x - 3, bottom - 8), Vector2(6, 14)), Color("684324"))
	for y in range(int(top), int(bottom) + 1, 32):
		draw_rect(Rect2(Vector2(left - 5, y - 3), Vector2(14, 6)), Color("684324"))
		draw_rect(Rect2(Vector2(right - 8, y - 3), Vector2(14, 6)), Color("684324"))
	if chicken_sprite:
		for i in range(animal_count):
			var p := center + Vector2(-size.x * 0.26 + (i % 2) * 34, -size.y * 0.15 + floori(float(i) / 2.0) * 28)
			draw_texture_rect(chicken_sprite, Rect2(p, Vector2(22, 22)), false)
