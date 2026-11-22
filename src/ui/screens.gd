class_name Screens
extends Control
## Every full screen of the game, drawn over the 3D view (Stories 006-018): the bag, settings,
## the fish shop (sell, rods, baits, items, farm), the fish book, the level-up screen, and the
## town screens (warehouse, rod workshop, neighbor requests, restaurant, farm plot, animals,
## clothes shop with a turning 3D viewer, city hall), plus the start screen, the sleep screen and
## short messages. One screen is open at a time; it blocks the touches to the world behind it.
##
## The screens only show and ask: every change goes through the systems in [GameContext]
## ([Economy], [Town], [Energy]) and the screen rebuilds itself from the state afterwards.
## Texts from texts_pt.json ([Texts]); sizes and colors from the "ui" group of world_look.json.
##
## Usage:
## [codeblock]
## var screens := Screens.new()
## hud.add_child(screens)
## screens.setup(look, ctx, sfx)
## screens.open_shop()
## [/codeblock]

## The player chose a new game (after confirming).
signal new_game_requested
## The start screen was closed with Continuar or Novo jogo ([param fresh] true = new game).
signal start_chosen(fresh: bool)
## The outfit changed (the main scene re-dresses the fisherman).
signal outfit_changed
## A screen opened or closed.
signal open_changed(open: bool)
## The player chose a building to place (2026-11-22).
signal place_requested(id: String)

enum ShopTab { SELL, RODS, BAITS, ITEMS, FARM, AUCTION, UPGRADES, BUILD }

var _look: WorldLook
var _ctx: GameContext
var _sfx: Sfx
var _layer: Control
var _scroll: ScrollContainer
var _rebuild: Callable
## While the start menu is up: 1 with a save, 0 without; -1 in the game (Ajustes is then shorter).
var _start_save: int = -1
var _toast: Label
var _toast_left: float = 0.0
var _viewer: SubViewport
var _viewer_model: Fisherman
var _sleep_left: float = 0.0
var _sleep: Control
## The open screen shows timers: it rebuilds itself every second.
var _live: bool = false
var _live_timer: float = 0.0
var _refreshing: bool = false
## Ids of the buildings the player places (set by the main scene).
var _placeable: Array[String] = []


## Tells the shop which buildings can be placed (the "Obras" tab).
func set_placeable(ids: Array[String]) -> void:
	_placeable = ids


## Builds the toast and connects the level-up screen.
func setup(look: WorldLook, ctx: GameContext, sfx: Sfx) -> void:
	_look = look
	_ctx = ctx
	_sfx = sfx
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UiKit.make_theme(look)
	_toast = Label.new()
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_top = look.num("ui", "top_height") + look.num("ui", "top_margin") * 3.0
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override(&"font_size", 26)
	_toast.add_theme_color_override(&"font_color", look.color("ui", "pill_text"))
	_toast.add_theme_stylebox_override(&"normal", UiKit.flat(look.color("ui", "pill_fill"), 16))
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.visible = false
	add_child(_toast)
	ctx.state.level_up.connect(open_level_up)
	ctx.state.city_level_up.connect(func(level: int, reward: int) -> void: toast(Texts.fmt("city_up", [level, reward])))


## True while a screen is open (the world ignores touches and the fisherman stands still).
func is_open() -> bool:
	return _layer != null


## Shows a short message at the top.
func toast(text: String) -> void:
	_toast.text = "  " + text + "  "
	_toast.visible = true
	_toast_left = 2.6
	move_child(_toast, get_child_count() - 1)


## Closes the open screen.
func close() -> void:
	_start_save = -1
	if _layer != null:
		_layer.queue_free()
		_layer = null
		_viewer = null
		_viewer_model = null
		open_changed.emit(false)


func _process(delta: float) -> void:
	if _toast_left > 0.0:
		_toast_left -= delta
		_toast.visible = _toast_left > 0.0
	if _viewer_model != null:
		_viewer_model.rotation.y += delta * 0.8
	if _live and _layer != null:
		_live_timer -= delta
		if _live_timer <= 0.0:
			_live_timer = 1.0
			_refresh()
	if _sleep != null:
		_sleep_left -= delta
		_sleep.modulate.a = clampf(_sleep_left, 0.0, 1.0)
		if _sleep_left <= 0.0:
			_sleep.queue_free()
			_sleep = null


# --- frame ---

func _sheet(title: String, rebuild: Callable) -> VBoxContainer:
	var keep_scroll: int = 0
	var same: bool = _layer != null and (_rebuild == rebuild or _refreshing)
	if same and _scroll != null:
		keep_scroll = _scroll.scroll_vertical
	if _layer != null:
		_layer.queue_free()
		_layer = null
	_rebuild = rebuild
	_live = false
	_layer = Control.new()
	_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_layer)
	var dim := ColorRect.new()
	dim.color = _look.color("ui", "dim")
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(dim)
	var panel := PanelContainer.new()
	var w: float = _look.num("ui", "sheet_width")
	var h: float = _look.num("ui", "sheet_height")
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -w * 0.5
	panel.offset_right = w * 0.5
	panel.offset_top = -h * 0.5
	panel.offset_bottom = h * 0.5
	_layer.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 10)
	panel.add_child(column)
	var header := HBoxContainer.new()
	var title_label: Label = UiKit.label(title, _look.integer("ui", "title_size"))
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)
	var close_button: Button = UiKit.button(_look, Texts.get_text("close"), _close_clicked)
	close_button.custom_minimum_size.x = 140.0
	header.add_child(close_button)
	column.add_child(header)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(_scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override(&"separation", 8)
	_scroll.add_child(body)
	if same:
		_restore_scroll.call_deferred(keep_scroll)
	else:
		open_changed.emit(true)
	move_child(_toast, get_child_count() - 1)
	return body


func _restore_scroll(value: int) -> void:
	if _scroll != null:
		_scroll.scroll_vertical = value


func _refresh() -> void:
	if _rebuild.is_valid():
		_refreshing = true
		_rebuild.call()
		_refreshing = false


func _click() -> void:
	_sfx.play(&"click")


func _on_tab(pick: Callable, i: int) -> void:
	_click()
	pick.call(i)


func _close_clicked() -> void:
	_click()
	close()


## Shows a result: [param ok] plays the coin sound and [param text] as a message.
func _result(ok: bool, text: String) -> void:
	_sfx.play(&"coin" if ok else &"error")
	toast(text)
	_refresh()


func _town_text(result: Town.Result) -> String:
	match result:
		Town.Result.NOT_ENOUGH_COINS:
			return Texts.get_text("no_coins")
		Town.Result.NOT_BUILT:
			return Texts.get_text("not_built")
		Town.Result.FULL:
			return Texts.get_text("full")
		Town.Result.NO_ENERGY:
			return Texts.get_text("no_energy")
		Town.Result.NOT_READY:
			return Texts.get_text("not_ready")
		Town.Result.ALREADY:
			return Texts.get_text("already_watered")
		Town.Result.EMPTY:
			return Texts.get_text("nothing")
		Town.Result.LOCKED:
			return Texts.fmt("city_locked", [_ctx.state.city_level + 1])
	return Texts.get_text("not_ready")


func _tabs(body: VBoxContainer, names: Array[String], active: int, pick: Callable) -> void:
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override(&"separation", 6)
	for i in names.size():
		var b: Button = UiKit.button(_look, names[i], _on_tab.bind(pick, i))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if i == active:
			b.add_theme_stylebox_override(&"normal", UiKit.flat(_look.color("ui", "tab_active"), 12))
		tabs.add_child(b)
	body.add_child(tabs)


func _fish_icon(id: String, known: bool = true) -> FishIcon:
	var icon := FishIcon.new()
	var sp: GameData.Species = _ctx.data.species_by_id(id)
	icon.setup_fish(id, Color.html(_ctx.data.rarity_colors[sp.rarity]), known)
	return icon


func _item_icon(kind: FishIcon.Kind, color_text: String) -> FishIcon:
	var icon := FishIcon.new()
	icon.setup_item(kind, Color.html(color_text) if color_text != "" else Color(0.8, 0.6, 0.3))
	return icon


func _kg(kg: float) -> String:
	return Texts.fmt("weight_fmt", [String.num(kg, int(_ctx.data.fixed("weight_decimals")))])


func _fish_line(fish: GameState.Catch) -> String:
	var sp: GameData.Species = _ctx.data.species_by_id(fish.id)
	return "%s · %s · %d" % [sp.name, _kg(fish.weight), fish.value]


# --- Bag (Story 006/007) ---

## The bag: fish with weight and value, goods, total, and the usable items.
func open_bag() -> void:
	var s: GameState = _ctx.state
	var body: VBoxContainer = _sheet(Texts.get_text("bag"), open_bag)
	body.add_child(UiKit.label(Texts.fmt("bag_fish", [s.bag.size(), int(_ctx.data.tune("bag_size"))]), 26))
	if s.bag.is_empty():
		body.add_child(UiKit.label(Texts.get_text("bag_empty"), 0, _look.color("ui", "muted")))
	for i in s.bag.size():
		body.add_child(UiKit.row(_look, [_fish_icon(s.bag[i].id), UiKit.label(_fish_line(s.bag[i]))], i % 2 == 1))
	body.add_child(UiKit.label("%s · %d/%d" % [Texts.get_text("bag_goods"), _ctx.farm.bag_items(), int(_ctx.town_data.num("farm_life", "bag_items"))], 26))
	for g: Variant in _ctx.town_data.goods():
		var good: Dictionary = g
		var n: int = s.good_count(str(good["id"]))
		if n > 0:
			body.add_child(UiKit.row(_look, [_item_icon(FishIcon.Kind.GOOD, str(good["color"])), UiKit.label("%s × %d" % [str(good["name"]), n])]))
	body.add_child(UiKit.label(Texts.fmt("bag_total", [s.bag_value()]), 26, _look.color("ui", "good")))
	var _act1: Callable = func() -> void:
		var r: Economy.Result = _ctx.economy.eat_snack()
		_result(r == Economy.Result.OK, Texts.get_text("snack_ok") if r == Economy.Result.OK else (Texts.get_text("energy_full") if r == Economy.Result.ENERGY_FULL else Texts.get_text("none_owned")))
	body.add_child(UiKit.button(_look, Texts.fmt("use_snack", [s.snacks]), _act1, s.snacks > 0))
	var _act2: Callable = func() -> void:
		var r: Economy.Result = _ctx.economy.use_luck()
		_result(r == Economy.Result.OK, Texts.get_text("luck_ok") if r == Economy.Result.OK else Texts.get_text("none_owned"))
	body.add_child(UiKit.button(_look, Texts.fmt("use_luck", [s.luck_baits]), _act2, s.luck_baits > 0))
	for c: Variant in _ctx.town_data.crops():
		var crop: Dictionary = c
		if bool(crop.get("bait", false)):
			var id: String = str(crop["id"])
			var _act3: Callable = func() -> void:
				var r: Town.Result = _ctx.town.use_crop_bait(id)
				_result(r == Town.Result.OK, Texts.get_text("crop_bait_ok") if r == Town.Result.OK else _town_text(r))
			if s.good_count(id) > 0:
				body.add_child(UiKit.button(_look, Texts.fmt("use_crop_bait", [str(crop["name"]), s.good_count(id)]), _act3))


# --- Settings (Story 006) ---

## Sound, FPS counter, Continuar and Novo jogo (with confirmation).
func open_settings() -> void:
	var s: GameState = _ctx.state
	var body: VBoxContainer = _sheet(Texts.get_text("settings"), open_settings)
	var _act4: Callable = func() -> void:
		s.sound_on = not s.sound_on
		_sfx.set_enabled(s.sound_on)
		_click()
		_refresh()
	body.add_child(UiKit.button(_look, "%s: %s" % [Texts.get_text("sound"), Texts.get_text("on") if s.sound_on else Texts.get_text("off")], _act4))
	var _act5: Callable = func() -> void:
		s.show_fps = not s.show_fps
		_click()
		_refresh()
	body.add_child(UiKit.button(_look, "%s: %s" % [Texts.get_text("show_fps"), Texts.get_text("on") if s.show_fps else Texts.get_text("off")], _act5))
	if _start_save >= 0:
		# Opened from the start menu: the game has not begun, so only the options and Voltar.
		body.add_child(UiKit.button(_look, Texts.get_text("back"), show_start.bind(_start_save == 1)))
		var header: Control = (body.get_parent().get_parent() as VBoxContainer).get_child(0)
		(header.get_child(1) as Control).visible = false
		return
	body.add_child(UiKit.button(_look, Texts.get_text("continue"), _close_clicked))
	body.add_child(UiKit.button(_look, Texts.get_text("new_game"), _confirm_new.bind(open_settings)))
	if AdminTools.available():
		body.add_child(UiKit.button(_look, Texts.get_text("admin"), open_admin))


func _confirm_new(back: Callable) -> void:
	var body: VBoxContainer = _sheet(Texts.get_text("new_game"), func() -> void: _confirm_new(back))
	body.add_child(UiKit.label(Texts.get_text("confirm_new"), 26))
	var _act6: Callable = func() -> void:
		_click()
		close()
		new_game_requested.emit()
	body.add_child(UiKit.button(_look, Texts.get_text("yes"), _act6))
	body.add_child(UiKit.button(_look, Texts.get_text("no"), back))


# --- Shop (Story 007) ---

## The fish shop on [param tab].
func open_shop(tab: int = ShopTab.SELL) -> void:
	var body: VBoxContainer = _sheet(Texts.get_text("shop"), func() -> void: open_shop(tab))
	var names: Array[String] = [Texts.get_text("tab_sell"), Texts.get_text("tab_rods"), Texts.get_text("tab_baits"), Texts.get_text("tab_items"), Texts.get_text("tab_farm"), Texts.get_text("tab_auction"), Texts.get_text("tab_upgrades"), Texts.get_text("tab_build")]
	_tabs(body, names, tab, func(i: int) -> void: open_shop(i))
	match tab:
		ShopTab.SELL:
			_shop_sell(body)
		ShopTab.RODS:
			for rod: GameData.Rod in _ctx.data.rods:
				var stats: String = "%s\n%s" % [rod.name, Texts.fmt("workshop_stats", [int(rod.cast_range), int(rod.zone * 100.0), int(rod.power * 100.0)])]
				body.add_child(UiKit.row(_look, [_item_icon(FishIcon.Kind.ROD, rod.color), UiKit.label(stats), _gear_button(Economy.GearKind.ROD, rod, _ctx.state.rods_owned.has(rod.id), _ctx.state.rod == rod.id)]))
		ShopTab.BAITS:
			for bait: GameData.Bait in _ctx.data.baits:
				body.add_child(UiKit.row(_look, [_item_icon(FishIcon.Kind.BAIT, bait.color), UiKit.label(bait.name), _gear_button(Economy.GearKind.BAIT, bait, _ctx.state.baits_owned.has(bait.id), _ctx.state.bait == bait.id)]))
		ShopTab.ITEMS:
			for item: GameData.Item in _ctx.data.items:
				var owned: int = _ctx.state.snacks if item.effect == "snack" else _ctx.state.luck_baits
				var locked: bool = _ctx.state.level < item.level
				var _act7: Callable = func() -> void:
					var r: Economy.Result = _ctx.economy.buy_item(item.id)
					_result(r == Economy.Result.OK, _economy_text(r))
				var b: Button = UiKit.button(_look, Texts.fmt("need_level", [item.level]) if locked else Texts.fmt("buy", [item.price]), _act7, not locked and _ctx.state.coins >= item.price)
				body.add_child(UiKit.row(_look, [_item_icon(FishIcon.Kind.GOOD, "#e8a040"), UiKit.label("%s × %d\n%s" % [item.name, owned, item.description]), b]))
		ShopTab.FARM:
			body.add_child(UiKit.label(Texts.get_text("tools"), 24))
			var tools: Dictionary = _ctx.production.data()["tools"]
			for tid: Variant in tools:
				var tool: Dictionary = tools[tid]
				var tool_id: String = str(tid)
				var owned_tool: bool = _ctx.state.tools.has(tool_id)
				var _buy_tool: Callable = func() -> void:
					var r: Production.Result = _ctx.production.buy_tool(tool_id)
					_result(r == Production.Result.OK, Texts.get_text("tool_bought") if r == Production.Result.OK else Texts.get_text("no_coins"))
				body.add_child(UiKit.row(_look, [_item_icon(FishIcon.Kind.ROD, "#8a8e96"), UiKit.label(str(tool["name"])), UiKit.button(_look, Texts.get_text("tool_owned") if owned_tool else Texts.fmt("tool_buy", [int(tool["price"])]), _buy_tool, not owned_tool and _ctx.state.coins >= int(tool["price"]))]))
			for g: Variant in _ctx.town_data.list("farm_life", "shop_goods"):
				var good: Dictionary = _ctx.town_data.good(str(g))
				var price: int = int(good["price"])
				var id: String = str(good["id"])
				var _buy1: Callable = func() -> void:
					var r: Farm.Result = _ctx.farm.order_good(id, 1)
					_result(r == Farm.Result.OK, Texts.get_text("ordered") if r == Farm.Result.OK else Texts.get_text("no_coins"))
				var one: Button = UiKit.button(_look, Texts.fmt("buy", [price]), _buy1, _ctx.state.coins >= price)
				var _buy10: Callable = func() -> void:
					var r: Farm.Result = _ctx.farm.order_good(id, 10)
					_result(r == Farm.Result.OK, Texts.get_text("ordered") if r == Farm.Result.OK else Texts.get_text("no_coins"))
				var ten: Button = UiKit.button(_look, "10× " + Texts.fmt("buy", [price * 10]), _buy10, _ctx.state.coins >= price * 10)
				body.add_child(UiKit.row(_look, [_item_icon(FishIcon.Kind.GOOD, str(good["color"])), UiKit.label("%s · %d" % [str(good["name"]), _ctx.farm.owned(id)]), one, ten]))
		ShopTab.AUCTION:
			for a: Variant in _ctx.town_data.animals():
				var info: Dictionary = a
				var kind: String = str(info["id"])
				var home: String = str(info["home"])
				var home_name: String = str(_ctx.town_data.lot(home).get("name", _ctx.town_data.home(home).get("name", home)))
				var built: bool = _ctx.farm.home_ready(home)
				var price: int = int(info["price"])
				var _bid: Callable = func() -> void:
					var r: Farm.Result = _ctx.farm.order_animal(kind)
					var text: String = Texts.get_text("ordered_animal")
					if r == Farm.Result.NOT_BUILT:
						text = Texts.fmt("need_building", [home_name])
					elif r == Farm.Result.FULL:
						text = Texts.get_text("home_full")
					elif r != Farm.Result.OK:
						text = Texts.get_text("no_coins")
					_result(r == Farm.Result.OK, text)
				var label: String = Texts.fmt("buy", [price]) if built else Texts.fmt("auction_need", [home_name])
				body.add_child(UiKit.row(_look, [_item_icon(FishIcon.Kind.GOOD, "#f4f0e6"), UiKit.label("%s\n%s" % [str(info["name"]), home_name]), UiKit.button(_look, label, _bid, built and _ctx.state.coins >= price)]))
		ShopTab.BUILD:
			for bid: String in _placeable:
				var need: Dictionary = _ctx.farm.needs(bid)
				var name: String = str(_ctx.town_data.lot(bid).get("name", bid))
				var built: bool = _ctx.state.is_built(bid)
				var blocker: Farm.Result = _ctx.farm.build_blocker(bid)
				var line: String = "%s\n%s" % [name, Texts.fmt("build_needs_short", [int(need.get("level", 1)), int(need.get("madeira", 0)), int(need.get("pedra", 0)), int(need.get("coins", 0))])]
				var _pick: Callable = func() -> void:
					_click()
					close()
					place_requested.emit(bid)
				var text: String = Texts.get_text("build_built") if built else Texts.get_text("build_pick")
				if not built and blocker == Farm.Result.LOW_LEVEL:
					text = Texts.fmt("build_low", [int(need.get("level", 1))])
				elif not built and blocker == Farm.Result.MISSING:
					text = Texts.get_text("missing_items")
				body.add_child(UiKit.row(_look, [UiKit.label(line, _look.integer("ui", "small_size")), UiKit.button(_look, text, _pick, not built and blocker == Farm.Result.OK)]))
		ShopTab.UPGRADES:
			var farm: Farm = _ctx.farm
			var price: int = int(_ctx.town_data.num("farm_life", "milker_price"))
			var need: int = int(_ctx.town_data.num("farm_life", "milker_level"))
			var corral_name: String = str(_ctx.town_data.lot("curral").get("name", ""))
			var text: String = Texts.fmt("milker_buy", [price])
			if _ctx.state.milker:
				text = Texts.get_text("milker_done")
			elif not _ctx.state.is_built("curral"):
				text = Texts.fmt("need_building", [corral_name])
			elif farm.level() < need:
				text = Texts.fmt("milker_level", [need])
			var _milker: Callable = func() -> void:
				var r: Farm.Result = farm.buy_milker()
				_result(r == Farm.Result.OK, Texts.get_text("milker_done") if r == Farm.Result.OK else Texts.get_text("no_coins"))
			var can: bool = not _ctx.state.milker and _ctx.state.is_built("curral") and farm.level() >= need and _ctx.state.coins >= price
			body.add_child(UiKit.row(_look, [_item_icon(FishIcon.Kind.GOOD, "#c8ccd0"), UiKit.label(Texts.get_text("milker")), UiKit.button(_look, text, _milker, can)]))
			var cost: int = _ctx.town.storage_upgrade_cost()
			if cost >= 0:
				var _expand: Callable = func() -> void:
					var r: Town.Result = _ctx.town.upgrade_storage()
					_result(r == Town.Result.OK, Texts.get_text("bought") if r == Town.Result.OK else _town_text(r))
				body.add_child(UiKit.row(_look, [_item_icon(FishIcon.Kind.GOOD, "#a8743f"), UiKit.label(Texts.get_text("shed")), UiKit.button(_look, Texts.fmt("warehouse_upgrade", [int(_ctx.town_data.num("storage", "upgrade_step")), cost]), _expand, _ctx.state.coins >= cost)]))


func _shop_sell(body: VBoxContainer) -> void:
	var s: GameState = _ctx.state
	var total: int = s.bag_value() + _ctx.town.storage_value() + _ctx.town.goods_value()
	var _act10: Callable = func() -> void:
		var bag_value: int = s.bag_value()
		_ctx.economy.sell_all()
		var rest: int = _ctx.town.sell_storage_and_goods()
		var earned: int = bag_value + rest
		_result(earned > 0, Texts.fmt("sold", [earned]) if earned > 0 else Texts.get_text("nothing_to_sell"))
	body.add_child(UiKit.button(_look, Texts.fmt("sell_all", [total]), _act10, total > 0))
	for i in s.bag.size():
		body.add_child(UiKit.row(_look, [_fish_icon(s.bag[i].id), UiKit.label(_fish_line(s.bag[i]))], i % 2 == 1))
	if not s.storage.is_empty():
		body.add_child(UiKit.label("%s: %d · %d" % [Texts.get_text("warehouse"), s.storage.size(), _ctx.town.storage_value()], 0, _look.color("ui", "muted")))
	for g: Variant in _ctx.town_data.goods():
		var good: Dictionary = g
		var n: int = s.good_count(str(good["id"]))
		if n > 0 and int(good["sell"]) > 0:
			body.add_child(UiKit.row(_look, [_item_icon(FishIcon.Kind.GOOD, str(good["color"])), UiKit.label("%s × %d · %d" % [str(good["name"]), n, n * int(good["sell"])])]))


func _gear_button(kind: Economy.GearKind, entry: GameData.ShopEntry, owned: bool, equipped: bool) -> Button:
	var text: String = Texts.get_text("equipped") if equipped else (Texts.get_text("equip") if owned else (Texts.fmt("need_level", [entry.level]) if _ctx.state.level < entry.level else Texts.fmt("buy", [entry.price])))
	var enabled: bool = not equipped and (owned or (_ctx.state.level >= entry.level and _ctx.state.coins >= entry.price))
	var _act11: Callable = func() -> void:
		var r: Economy.Result = _ctx.economy.buy_gear(kind, entry.id)
		_result(r == Economy.Result.OK or r == Economy.Result.EQUIPPED, _economy_text(r))
	return UiKit.button(_look, text, _act11, enabled)


func _economy_text(r: Economy.Result) -> String:
	match r:
		Economy.Result.OK:
			return Texts.get_text("bought")
		Economy.Result.EQUIPPED:
			return Texts.get_text("equipped")
		Economy.Result.NOT_ENOUGH_COINS:
			return Texts.get_text("no_coins")
		Economy.Result.LOCKED_BY_LEVEL:
			return Texts.get_text("need_level") % _ctx.state.level
	return Texts.get_text("none_owned")


# --- Book and level up (Story 007) ---

## The fish book as an open book (2026-11-19): the left page shows the chosen species (name
## banner, big picture or silhouette, rarity, where and when it bites, catches and the biggest
## one); the right page shows the counter, the sort choice and every species as a tile (dark
## silhouettes for the ones not caught yet). A tap on a tile shows it on the left page.
func open_book(selected: String = "", sort: int = 0) -> void:
	var s: GameState = _ctx.state
	var d: GameData = _ctx.data
	if selected == "":
		selected = d.species[0].id
		for sp: GameData.Species in d.species:
			if s.book.has(sp.id):
				selected = sp.id
				break
	var body: VBoxContainer = _sheet(Texts.get_text("book"), open_book.bind(selected, sort))
	var pages := HBoxContainer.new()
	pages.add_theme_constant_override(&"separation", 6)
	body.add_child(pages)
	var page_style: StyleBoxFlat = UiKit.flat(_bc("page"), 10)
	page_style.set_border_width_all(3)
	page_style.border_color = _bc("page_edge")
	page_style.set_content_margin_all(14.0)
	# Left page: the chosen species.
	var left := PanelContainer.new()
	left.add_theme_stylebox_override(&"panel", page_style)
	left.custom_minimum_size = Vector2(_look.num("book", "left_w"), 0.0)
	pages.add_child(left)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override(&"separation", 8)
	left.add_child(lv)
	var sp: GameData.Species = d.species_by_id(selected)
	var known: bool = s.book.has(selected)
	var banner: Label = UiKit.label(sp.name.to_upper() if known else Texts.get_text("book_unknown"), 24, _bc("ink"))
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_stylebox_override(&"normal", UiKit.flat(_bc("banner"), 14))
	lv.add_child(banner)
	var picture := PanelContainer.new()
	picture.add_theme_stylebox_override(&"panel", UiKit.flat(_bc("picture"), 12))
	var big := FishIcon.new()
	big.framed = false
	big.custom_minimum_size = Vector2(0.0, _look.num("book", "picture_h"))
	big.setup_fish(selected, Color.html(d.rarity_colors[sp.rarity]), known)
	picture.add_child(big)
	lv.add_child(picture)
	var rarity: Label = UiKit.label(d.rarity_names[sp.rarity], _look.integer("ui", "small_size"), Color.WHITE)
	rarity.add_theme_stylebox_override(&"normal", UiKit.flat(Color.html(d.rarity_colors[sp.rarity]).darkened(0.25), 8))
	rarity.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	rarity.autowrap_mode = TextServer.AUTOWRAP_OFF
	lv.add_child(rarity)
	var place_key: String = "book_place_day" if sp.time == "day" else ("book_place_night" if sp.time == "night" else "book_place_any")
	lv.add_child(UiKit.label(Texts.get_text(place_key), 0, _bc("ink")))
	if known:
		var entry: GameState.BookEntry = s.book[selected]
		lv.add_child(UiKit.label(Texts.fmt("book_total", [entry.count]), 0, _bc("ink")))
		lv.add_child(UiKit.label(Texts.get_text("book_biggest"), 22, _bc("accent")))
		lv.add_child(UiKit.label(_kg(entry.best), 0, _bc("ink")))
	else:
		lv.add_child(UiKit.label(Texts.get_text("book_none"), 0, _bc("tile_dark")))
	# Right page: counter, sort and the grid.
	var right := PanelContainer.new()
	right.add_theme_stylebox_override(&"panel", page_style)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pages.add_child(right)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override(&"separation", 8)
	right.add_child(rv)
	var head := HBoxContainer.new()
	var counter: Label = UiKit.label("%d / %d" % [s.discovered(), d.species.size()], 24, _bc("accent"))
	counter.autowrap_mode = TextServer.AUTOWRAP_OFF
	counter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(counter)
	var sort_label: Label = UiKit.label(Texts.get_text("book_sort"), _look.integer("ui", "small_size"), _bc("ink"))
	sort_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	head.add_child(sort_label)
	var sort_names: Array[String] = [Texts.get_text("sort_caught"), Texts.get_text("sort_rarity"), Texts.get_text("sort_name")]
	var sort_button: Button = UiKit.button(_look, sort_names[sort], open_book.bind(selected, (sort + 1) % 3))
	sort_button.add_theme_stylebox_override(&"normal", UiKit.flat(_bc("ink"), 8))
	head.add_child(sort_button)
	rv.add_child(head)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0.0, 380.0)
	rv.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = _look.integer("book", "columns")
	grid.add_theme_constant_override(&"h_separation", 8)
	grid.add_theme_constant_override(&"v_separation", 8)
	scroll.add_child(grid)
	var order: Array[GameData.Species] = d.species.duplicate()
	if sort == 0:
		var caught_first: Callable = func(a: GameData.Species, b: GameData.Species) -> bool:
			var ka: bool = s.book.has(a.id)
			var kb: bool = s.book.has(b.id)
			if ka != kb:
				return ka
			return a.rarity < b.rarity or (a.rarity == b.rarity and a.name < b.name)
		order.sort_custom(caught_first)
	elif sort == 1:
		order.sort_custom(func(a: GameData.Species, b: GameData.Species) -> bool: return a.rarity < b.rarity or (a.rarity == b.rarity and a.name < b.name))
	else:
		order.sort_custom(func(a: GameData.Species, b: GameData.Species) -> bool: return a.name < b.name)
	for each: GameData.Species in order:
		var tile := Button.new()
		tile.focus_mode = Control.FOCUS_NONE
		tile.custom_minimum_size = Vector2(_look.num("book", "tile_w"), _look.num("book", "tile_h"))
		var tile_color: Color = _bc("tile_selected") if each.id == selected else _bc("tile")
		for state_name: String in ["normal", "hover", "pressed"]:
			tile.add_theme_stylebox_override(StringName(state_name), UiKit.flat(tile_color, 10))
		var icon := FishIcon.new()
		icon.framed = false
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.setup_fish(each.id, Color.html(d.rarity_colors[each.rarity]), s.book.has(each.id))
		tile.add_child(icon)
		tile.pressed.connect(open_book.bind(each.id, sort))
		grid.add_child(tile)


func _bc(key: String) -> Color:
	return _look.color("book", key)


## The level-up screen: new title, new species, new shop entries and the reward.
func open_level_up(level: int, reward: int) -> void:
	_sfx.play(&"level")
	var body: VBoxContainer = _sheet(Texts.get_text("levelup_title"), func() -> void: open_level_up(level, reward))
	body.add_child(UiKit.label("%s · %s" % [Texts.fmt("level_short", [level]), _ctx.data.level_names[level - 1]], 34, _look.color("ui", "good")))
	var species: PackedStringArray = PackedStringArray()
	for sp: GameData.Species in _ctx.data.species:
		if sp.rarity == level - 1:
			species.append(sp.name)
	body.add_child(UiKit.label(Texts.fmt("levelup_new_species", [", ".join(species) if not species.is_empty() else Texts.get_text("none")])))
	var items: PackedStringArray = PackedStringArray()
	for rod: GameData.Rod in _ctx.data.rods:
		if rod.level == level:
			items.append(rod.name)
	for bait: GameData.Bait in _ctx.data.baits:
		if bait.level == level:
			items.append(bait.name)
	for item: GameData.Item in _ctx.data.items:
		if item.level == level:
			items.append(item.name)
	body.add_child(UiKit.label(Texts.fmt("levelup_items", [", ".join(items) if not items.is_empty() else Texts.get_text("none")])))
	body.add_child(UiKit.label(Texts.fmt("levelup_reward", [reward]), 28, _look.color("ui", "good")))
	body.add_child(UiKit.button(_look, Texts.get_text("continue"), _close_clicked))


# --- Warehouse (Story 010) ---

## Bag and warehouse side by side; a tap moves a fish; the expansion button.
func open_warehouse() -> void:
	var s: GameState = _ctx.state
	var t: Town = _ctx.town
	var body: VBoxContainer = _sheet(Texts.get_text("warehouse"), open_warehouse)
	body.add_child(UiKit.label(Texts.get_text("tap_to_move"), 0, _look.color("ui", "muted")))
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override(&"separation", 12)
	body.add_child(cols)
	var left := VBoxContainer.new()
	var right := VBoxContainer.new()
	for c: VBoxContainer in [left, right]:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cols.add_child(c)
	left.add_child(UiKit.label(Texts.fmt("warehouse_bag", [s.bag.size(), int(_ctx.data.tune("bag_size"))]), 24))
	right.add_child(UiKit.label(Texts.fmt("warehouse_store", [s.storage.size(), t.storage_capacity()]), 24))
	for i in s.bag.size():
		var index: int = i
		var _act12: Callable = func() -> void:
			var r: Town.Result = t.to_storage(index)
			if r != Town.Result.OK:
				_result(false, _town_text(r))
			else:
				_click()
				_refresh()
		left.add_child(UiKit.button(_look, _fish_line(s.bag[i]) + "  →", _act12))
	for i in s.storage.size():
		var index: int = i
		var _act13: Callable = func() -> void:
			var r: Town.Result = t.to_bag(index)
			if r != Town.Result.OK:
				_result(false, _town_text(r))
			else:
				_click()
				_refresh()
		right.add_child(UiKit.button(_look, "←  " + _fish_line(s.storage[i]), _act13))
	var cost: int = t.storage_upgrade_cost()
	if cost < 0:
		body.add_child(UiKit.label(Texts.get_text("warehouse_max"), 0, _look.color("ui", "muted")))
	else:
		var _act14: Callable = func() -> void:
			var r: Town.Result = t.upgrade_storage()
			_result(r == Town.Result.OK, Texts.get_text("bought") if r == Town.Result.OK else _town_text(r))
		body.add_child(UiKit.button(_look, Texts.fmt("warehouse_upgrade", [int(_ctx.town_data.num("storage", "upgrade_step")), cost]), _act14, s.coins >= cost))


# --- Owner test mode (2026-11-22) ---

var _admin_open: bool = false
## Kept as a member: the panel buttons call its methods, and a local one would be freed as soon as
## the panel is built (the Callables do not keep it alive).
var _admin_tools: AdminTools


## The admin mode: first creates the password, then asks for it, then shows the cheats. Only in
## debug builds ([method AdminTools.available]).
func open_admin() -> void:
	if not AdminTools.available():
		return
	if _admin_open:
		_admin_panel()
		return
	var body: VBoxContainer = _sheet(Texts.get_text("admin"), open_admin)
	var first: bool = not AdminTools.has_password()
	if first:
		body.add_child(UiKit.label(Texts.get_text("admin_create"), 22))
	var pass1: LineEdit = _password_field(Texts.get_text("admin_password"))
	body.add_child(pass1)
	var pass2: LineEdit = _password_field(Texts.get_text("admin_repeat"))
	if first:
		body.add_child(pass2)
	var _go: Callable = func() -> void:
		if first:
			if pass1.text != pass2.text:
				_result(false, Texts.get_text("admin_mismatch"))
				return
			if not AdminTools.create_password(pass1.text):
				_result(false, Texts.get_text("admin_short"))
				return
			toast(Texts.get_text("admin_saved"))
			_admin_open = true
			_admin_panel()
			return
		if AdminTools.lock_left() > 0:
			_result(false, Texts.fmt("admin_locked", [AdminTools.lock_left()]))
			return
		if AdminTools.check_password(pass1.text):
			_admin_open = true
			_sfx.play(&"level")
			toast(Texts.get_text("admin_on"))
			_admin_panel()
		else:
			_result(false, Texts.get_text("admin_wrong") if AdminTools.lock_left() == 0 else Texts.fmt("admin_locked", [AdminTools.lock_left()]))
	body.add_child(UiKit.button(_look, Texts.get_text("admin_save") if first else Texts.get_text("admin_enter"), _go))


func _password_field(placeholder: String) -> LineEdit:
	var field := LineEdit.new()
	field.secret = true
	field.placeholder_text = placeholder
	field.custom_minimum_size = Vector2(0.0, 60.0)
	field.add_theme_font_size_override(&"font_size", 26)
	field.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_PASSWORD
	return field


func _admin_panel() -> void:
	if _admin_tools == null:
		_admin_tools = AdminTools.new(_ctx)
	var admin: AdminTools = _admin_tools
	var body: VBoxContainer = _sheet(Texts.get_text("admin"), _admin_panel)
	var actions: Array = [
		[Texts.fmt("admin_coins", [10000]), admin.give_coins.bind(10000)],
		[Texts.fmt("admin_coins", [100000]), admin.give_coins.bind(100000)],
		[Texts.fmt("admin_goods", [100]), admin.give_all_goods.bind(100)],
		[Texts.get_text("admin_level"), admin.farm_level_up.bind(false)],
		[Texts.get_text("admin_level_max"), admin.farm_level_up.bind(true)],
		[Texts.get_text("admin_energy"), admin.fill_energy],
		[Texts.get_text("admin_tools"), admin.give_tools],
		[Texts.get_text("admin_timers"), admin.finish_timers],
		[Texts.get_text("admin_storage"), admin.big_storage],
	]
	for a: Array in actions:
		body.add_child(UiKit.button(_look, str(a[0]), _admin_do.bind(a[1])))
	var _exit: Callable = func() -> void:
		_admin_open = false
		_click()
		close()
	body.add_child(UiKit.button(_look, Texts.get_text("admin_exit"), _exit))
	var _forget: Callable = func() -> void:
		AdminTools.forget_password()
		_admin_open = false
		_click()
		close()
	body.add_child(UiKit.button(_look, Texts.get_text("admin_forget"), _forget))


func _admin_do(action: Callable) -> void:
	if not _admin_open or not AdminTools.available() or not action.is_valid():
		return
	action.call()
	_sfx.play(&"coin")
	toast(Texts.get_text("admin_done"))
	_refresh()


# --- Shed (galpão, farm map) ---

## The shed: the bag and the shed side by side; a tap moves a fish or a whole stack of items.
func open_shed() -> void:
	var s: GameState = _ctx.state
	var t: Town = _ctx.town
	var f: Farm = _ctx.farm
	var body: VBoxContainer = _sheet(Texts.get_text("shed"), open_shed)
	body.add_child(UiKit.label(Texts.get_text("tap_to_move"), 0, _look.color("ui", "muted")))
	body.add_child(UiKit.button(_look, Texts.get_text("store_all"), _store_all, f.bag_items() > 0))
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override(&"separation", 12)
	body.add_child(cols)
	var left := VBoxContainer.new()
	var right := VBoxContainer.new()
	for c: VBoxContainer in [left, right]:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cols.add_child(c)
	left.add_child(UiKit.label(Texts.fmt("shed_bag", [s.bag.size(), int(_ctx.data.tune("bag_size")), f.bag_items(), int(_ctx.town_data.num("farm_life", "bag_items"))]), 22))
	right.add_child(UiKit.label(Texts.fmt("shed_store", [s.storage.size(), t.storage_capacity()]), 22))
	for id: String in s.goods:
		if s.good_count(id) > 0:
			left.add_child(UiKit.button(_look, Texts.fmt("items_fmt", [_ctx.town_data.good_name(id), s.good_count(id)]) + "  →", _move_good.bind(id, true)))
	for id: Variant in s.shed:
		if int(s.shed[id]) > 0:
			right.add_child(UiKit.button(_look, "←  " + Texts.fmt("items_fmt", [_ctx.town_data.good_name(str(id)), int(s.shed[id])]), _move_good.bind(str(id), false)))
	for i in s.bag.size():
		left.add_child(UiKit.button(_look, _fish_line(s.bag[i]) + "  →", _move_fish.bind(i, true)))
	for i in s.storage.size():
		right.add_child(UiKit.button(_look, "←  " + _fish_line(s.storage[i]), _move_fish.bind(i, false)))


func _store_all() -> void:
	_shed_result(_ctx.farm.store_all() == Farm.Result.OK)


func _shed_result(ok: bool) -> void:
	_sfx.play(&"click" if ok else &"error")
	_refresh()


func _move_good(id: String, to_shed: bool) -> void:
	var r: Farm.Result = _ctx.farm.store_good(id) if to_shed else _ctx.farm.take_good(id)
	if r == Farm.Result.BAG_FULL:
		toast(Texts.get_text("bag_full"))
	_shed_result(r == Farm.Result.OK)


func _move_fish(index: int, to_shed: bool) -> void:
	var r: Town.Result = _ctx.town.to_storage(index) if to_shed else _ctx.town.to_bag(index)
	if r != Town.Result.OK:
		toast(_town_text(r))
	_shed_result(r == Town.Result.OK)


# --- Farm buildings (farm map) ---

## What building [param id] needs (farm level, wood, stone, coins) and the Construir button.
func open_build(id: String) -> void:
	var f: Farm = _ctx.farm
	var name: String = str(_ctx.town_data.lot(id).get("name", id))
	var body: VBoxContainer = _sheet(Texts.fmt("build_title", [name]), open_build.bind(id))
	var need: Dictionary = f.needs(id)
	var good: Color = _look.color("ui", "good")
	var bad: Color = _look.color("ui", "bad")
	var lvl: int = int(need.get("level", 1))
	body.add_child(UiKit.label(Texts.fmt("build_need_level", [lvl, f.level()]), 26, good if f.level() >= lvl else bad))
	for res: String in ["madeira", "pedra"]:
		var n: int = int(need.get(res, 0))
		body.add_child(UiKit.row(_look, [_item_icon(FishIcon.Kind.GOOD, str(_ctx.town_data.good(res)["color"])), UiKit.label(Texts.fmt("build_need", [_ctx.town_data.good_name(res), f.owned(res), n]), 0, good if f.owned(res) >= n else bad)]))
	var coins: int = int(need.get("coins", 0))
	body.add_child(UiKit.label(Texts.fmt("build_coins", [_ctx.state.coins, coins]), 0, good if _ctx.state.coins >= coins else bad))
	var _build: Callable = func() -> void:
		var r: Farm.Result = f.build(id)
		var text: String = Texts.get_text("built_ok")
		if r == Farm.Result.LOW_LEVEL:
			text = Texts.fmt("build_low", [lvl])
		elif r == Farm.Result.MISSING:
			text = Texts.get_text("build_missing")
		elif r == Farm.Result.NOT_ENOUGH_COINS:
			text = Texts.get_text("no_coins")
		_result(r == Farm.Result.OK, text)
		if r == Farm.Result.OK:
			close()
	body.add_child(UiKit.button(_look, Texts.get_text("build_btn"), _build, f.build_blocker(id) == Farm.Result.OK))


# --- Workshop (Story 011) ---

## The equipped rod, its level, current and next stats, and the upgrade button.
func open_workshop() -> void:
	var t: Town = _ctx.town
	var body: VBoxContainer = _sheet(Texts.get_text("workshop"), open_workshop)
	var rod: GameData.Rod = _ctx.data.rod_for(_ctx.state)
	var max_level: int = int(_ctx.town_data.num("workshop", "max_level"))
	body.add_child(UiKit.row(_look, [_item_icon(FishIcon.Kind.ROD, rod.color), UiKit.label(Texts.fmt("workshop_rod", [rod.name, t.rod_level(), max_level]), 28)]))
	body.add_child(UiKit.label(Texts.fmt("workshop_stats", [int(rod.cast_range), int(rod.zone * 100.0), int(rod.power * 100.0)])))
	var cost: int = t.rod_upgrade_cost()
	if cost < 0:
		body.add_child(UiKit.label(Texts.get_text("workshop_max"), 26, _look.color("ui", "good")))
		return
	var w: TownData = _ctx.town_data
	body.add_child(UiKit.label("→ " + Texts.fmt("workshop_stats", [int(rod.cast_range + w.num("workshop", "range_per_level")), int((rod.zone + w.num("workshop", "zone_per_level")) * 100.0), int((rod.power + w.num("workshop", "power_per_level")) * 100.0)]), 0, _look.color("ui", "good")))
	var enough: bool = _ctx.state.coins >= cost
	var _act15: Callable = func() -> void:
		var r: Town.Result = t.upgrade_rod()
		_result(r == Town.Result.OK, Texts.get_text("upgraded") if r == Town.Result.OK else _town_text(r))
	body.add_child(UiKit.button(_look, Texts.fmt("workshop_upgrade", [cost]) if enough else Texts.get_text("no_coins"), _act15, enough))


# --- Neighbors (Story 012) ---

## The short dialog with neighbor [param id]: request, reward and Entregar.
func open_neighbor(id: String) -> void:
	var t: Town = _ctx.town
	var n: Dictionary = _ctx.town_data.neighbor(id)
	var body: VBoxContainer = _sheet(str(n["name"]), func() -> void: open_neighbor(id))
	var face := NeighborFace.new()
	face.setup(n)
	var req: Dictionary = t.request_of(id)
	var lines: String = str(n["greeting"])
	if req.is_empty():
		body.add_child(UiKit.row(_look, [face, UiKit.label(Texts.get_text("no_request"), 26)]))
		return
	body.add_child(UiKit.row(_look, [face, UiKit.label(lines, 24)]))
	var species: String = str(req["species"])
	var count: int = int(req["count"])
	var have: int = t.fish_owned(species)
	body.add_child(UiKit.row(_look, [_fish_icon(species), UiKit.label(Texts.fmt("neighbor_wants", [count, _ctx.data.species_by_id(species).name]), 28)]))
	body.add_child(UiKit.label(Texts.fmt("neighbor_have", [have]), 0, _look.color("ui", "good") if have >= count else _look.color("ui", "bad")))
	body.add_child(UiKit.label(Texts.fmt("neighbor_reward", [t.request_reward(id)])))
	var _act16: Callable = func() -> void:
		var r: Town.Result = t.deliver(id)
		_result(r == Town.Result.OK, Texts.get_text("delivered") if r == Town.Result.OK else Texts.get_text("missing_fish"))
	body.add_child(UiKit.button(_look, Texts.get_text("deliver") if have >= count else Texts.get_text("missing_fish"), _act16, have >= count))


# --- Restaurant (Story 014) ---

## Stock, drinks, today's sales, and fish to cook from the bag and the warehouse.
func open_restaurant() -> void:
	var s: GameState = _ctx.state
	var t: Town = _ctx.town
	var r_data: TownData = _ctx.town_data
	var body: VBoxContainer = _sheet(Texts.get_text("restaurant"), open_restaurant)
	body.add_child(UiKit.label(Texts.fmt("rest_sales", [s.sales_today]), 26, _look.color("ui", "good")))
	body.add_child(UiKit.label(Texts.fmt("rest_drinks", [r_data.text("restaurant", "drink_name"), s.drinks, int(r_data.num("restaurant", "drink_price"))])))
	body.add_child(UiKit.label(Texts.fmt("rest_stock", [s.dishes.size(), int(r_data.num("restaurant", "stock_max"))]), 26))
	if s.dishes.is_empty():
		body.add_child(UiKit.label(Texts.get_text("rest_empty"), 0, _look.color("ui", "bad")))
	for dish: Dictionary in s.dishes:
		body.add_child(UiKit.row(_look, [_item_icon(FishIcon.Kind.GOOD, "#e8883a"), UiKit.label("%s · %d" % [str(dish["name"]), int(dish["value"])])]))
	body.add_child(UiKit.label(Texts.get_text("rest_cook"), 26))
	if s.bag.is_empty() and s.storage.is_empty():
		body.add_child(UiKit.label(Texts.get_text("rest_no_fish"), 0, _look.color("ui", "muted")))
	for source: int in [0, 1]:
		var list: Array[GameState.Catch] = s.bag if source == 0 else s.storage
		for i in list.size():
			var index: int = i
			var from_storage: bool = source == 1
			var _act17: Callable = func() -> void:
				var r: Town.Result = t.cook(index, from_storage)
				_result(r == Town.Result.OK, Texts.get_text("cooked") if r == Town.Result.OK else _town_text(r))
			body.add_child(UiKit.button(_look, ("[%s] " % Texts.get_text("warehouse") if from_storage else "") + _fish_line(list[i]), _act17))


# --- Farm plot (Story 015) ---

## Plot [param i]: pick a seed when empty; water or harvest otherwise.
func open_plot(i: int) -> void:
	var s: GameState = _ctx.state
	var t: Town = _ctx.town
	var body: VBoxContainer = _sheet(Texts.get_text("plot_title"), func() -> void: open_plot(i))
	var stage: Town.Stage = t.stage(i)
	if stage == Town.Stage.EMPTY:
		body.add_child(UiKit.label(Texts.get_text("plot_pick"), 26))
		for c: Variant in _ctx.town_data.crops():
			var crop: Dictionary = c
			var crop_id: String = str(crop["id"])
			var seed_id: String = str(crop["seed"])
			var seeds: int = s.good_count(seed_id)
			var seed_price: int = int(_ctx.town_data.good(seed_id)["price"])
			var _act18: Callable = func() -> void:
				var r: Town.Result = t.plant(i, crop_id)
				if r == Town.Result.OK:
					_sfx.play(&"coin")
					toast(Texts.get_text("planted"))
					close()
				else:
					_result(false, Texts.get_text("no_seeds") if r == Town.Result.MISSING else _town_text(r))
			var plant_b: Button = UiKit.button(_look, Texts.get_text("plant"), _act18, seeds > 0)
			var _act19: Callable = func() -> void:
				var r: Town.Result = t.buy_good(seed_id, 1)
				_result(r == Town.Result.OK, Texts.get_text("bought") if r == Town.Result.OK else _town_text(r))
			var buy_b: Button = UiKit.button(_look, Texts.fmt("buy", [seed_price]), _act19, s.coins >= seed_price)
			body.add_child(UiKit.row(_look, [_item_icon(FishIcon.Kind.GOOD, str(crop["color"])), UiKit.label(Texts.fmt("seed_count", [str(crop["name"]), seeds])), buy_b, plant_b]))
		return
	var plot: Dictionary = s.plots[i]
	var crop_info: Dictionary = _ctx.town_data.crop(str(plot["crop"]))
	body.add_child(UiKit.label(Texts.fmt("plot_growing", [str(crop_info["name"]), int(plot["days"]), int(crop_info["grow_days"]), Texts.get_text("plot_wet") if bool(plot["watered"]) else Texts.get_text("plot_dry")]), 26))
	if stage == Town.Stage.RIPE:
		var _act20: Callable = func() -> void:
			var r: Town.Result = t.harvest(i)
			if r == Town.Result.OK:
				_sfx.play(&"coin")
				toast(Texts.fmt("harvested", [int(crop_info["harvest"]), str(crop_info["name"])]))
				close()
			else:
				_result(false, _town_text(r))
		body.add_child(UiKit.button(_look, Texts.get_text("harvest"), _act20))
	else:
		var _act21: Callable = func() -> void:
			var r: Town.Result = t.water(i)
			_result(r == Town.Result.OK, Texts.get_text("watered") if r == Town.Result.OK else _town_text(r))
		body.add_child(UiKit.button(_look, Texts.get_text("water"), _act21, not bool(plot["watered"])))


# --- Ranch (Story 016) ---

## The animal home [param home_id] in real time: each animal hungry, producing (with time left)
## or ready; feed all with their feed from the barn; collect the products. Cows are milked here
## (by hand) unless the milking machine is installed. Animals are bought at the auction.
func open_ranch(home_id: String) -> void:
	var s: GameState = _ctx.state
	var p: Production = _ctx.production
	var td: TownData = _ctx.town_data
	var title: String = str(td.lot(home_id).get("name", home_id))
	var body: VBoxContainer = _sheet(title, open_ranch.bind(home_id))
	_live = true
	var list: Array[int] = p.animals_of(home_id)
	var capacity: int = 0
	for h: Variant in td.homes():
		if str((h as Dictionary)["id"]) == home_id:
			capacity = int((h as Dictionary)["capacity"])
	body.add_child(UiKit.label(Texts.fmt("ranch_home", [title, list.size(), capacity]), 26))
	for i: int in list:
		var a: Dictionary = s.animals[i]
		var st: int = p.animal_stage(i)
		var status: String = Texts.get_text("animal_hungry") if st == 0 else (Texts.get_text("animal_ready") if st == 2 else Texts.fmt("animal_making", [_ptime(p.seconds_left(float(a.get("ready_at", 0.0))))]))
		body.add_child(UiKit.label(Texts.fmt("animals_status", [str(td.animal(str(a["kind"])).get("name", "")), status]), _look.integer("ui", "small_size")))
	var feed_id: String = p.feed_of(home_id)
	if feed_id != "":
		var _feed: Callable = func() -> void:
			var n: int = p.feed_home(home_id)
			_result(n > 0, Texts.fmt("fed_n", [n]) if n > 0 else Texts.fmt("no_feed2", [_gname(feed_id)]))
		body.add_child(UiKit.button(_look, Texts.fmt("feed_all", [_gname(feed_id), p.count(feed_id)]), _feed))
	var ready: int = p.ready_in(home_id)
	var _collect: Callable = func() -> void:
		var r: Production.Result = p.collect_home(home_id)
		_result(r == Production.Result.OK, Texts.get_text("collected") if r == Production.Result.OK else Texts.get_text("barn_full"))
	body.add_child(UiKit.button(_look, Texts.fmt("act_milk", [ready]) if home_id == "curral" else Texts.fmt("collect_animals", [ready]), _collect, ready > 0))
	body.add_child(UiKit.label(Texts.get_text("ranch_buy_hint"), 0, _look.color("ui", "muted")))


# --- Real-time production screens (2026-11-21) ---

func _ptime(seconds: int) -> String:
	if seconds >= 3600:
		return "%dh %02dm" % [seconds / 3600, (seconds % 3600) / 60]
	return "%d:%02d" % [seconds / 60, seconds % 60]


func _gname(id: String) -> String:
	return _ctx.town_data.good_name(id)


func _items_text(items: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for id: Variant in items:
		parts.append("%s ×%d (%d)" % [_gname(str(id)), int(items[id]), _ctx.production.count(str(id))])
	return ", ".join(parts)


func _prod_msg(r: Production.Result, ok_text: String) -> void:
	var text: String = ok_text
	match r:
		Production.Result.LOW_LEVEL:
			text = Texts.get_text("low_level")
		Production.Result.MISSING:
			text = Texts.get_text("missing_items")
		Production.Result.FULL:
			text = Texts.get_text("queue_full")
		Production.Result.NOT_ENOUGH_COINS:
			text = Texts.get_text("no_coins")
	_result(r == Production.Result.OK, text)


## The field: plot summary, harvest everything, plant a crop in every empty plot, buy plots.
func open_field() -> void:
	var p: Production = _ctx.production
	var s: GameState = _ctx.state
	var body: VBoxContainer = _sheet(Texts.get_text("field"), open_field)
	_live = true
	var ready: int = 0
	var empty: int = 0
	for i in s.crop_plots.size():
		var st: int = p.plot_stage(i)
		ready += 1 if st == 2 else 0
		empty += 1 if st == 0 else 0
	body.add_child(UiKit.label(Texts.fmt("field_plots", [s.crop_plots.size(), ready, empty]), 24))
	body.add_child(UiKit.label(Texts.fmt("storage_used", [Texts.get_text("silo_name"), p.used("silo"), p.capacity("silo")]), 0, _look.color("ui", "muted")))
	body.add_child(UiKit.label(Texts.get_text("field_hint"), 0, _look.color("ui", "good")))
	for c: Variant in p.crops():
		var crop: Dictionary = c
		var lvl: int = int(crop["level"])
		var line: String = Texts.fmt("crop_have", [str(crop["name"]), p.count(str(crop["id"])), _ptime(int(crop["seconds"]))]) if _ctx.farm.level() >= lvl else Texts.fmt("crop_locked", [str(crop["name"]), lvl])
		body.add_child(UiKit.row(_look, [_item_icon(FishIcon.Kind.GOOD, str(crop["color"])), UiKit.label(line, 0, _look.color("ui", "ink") if _ctx.farm.level() >= lvl else _look.color("ui", "muted"))]))
	for i in s.crop_plots.size():
		var st: int = p.plot_stage(i)
		if st == 0:
			continue
		var name: String = str(p.crop(str(s.crop_plots[i]["crop"]))["name"])
		var state_text: String = Texts.get_text("plot_ready") if st == 2 else _ptime(p.seconds_left(float(s.crop_plots[i]["ready_at"])))
		body.add_child(UiKit.label(Texts.fmt("plot_growing2", [name, state_text]), _look.integer("ui", "small_size")))
	var price: int = p.plot_price()
	var _buy: Callable = func() -> void:
		var r: Production.Result = p.buy_plot()
		_prod_msg(r, Texts.get_text("bought"))
	body.add_child(UiKit.button(_look, Texts.fmt("buy_plot", [price]) if price >= 0 else Texts.get_text("plots_max"), _buy, price >= 0 and s.coins >= price))


## Picks what to plant in plot [param i] (tapped in the field).
func open_plant(i: int) -> void:
	var p: Production = _ctx.production
	var body: VBoxContainer = _sheet(Texts.get_text("plant_pick"), open_plant.bind(i))
	for c: Variant in p.crops():
		var crop: Dictionary = c
		var id: String = str(crop["id"])
		var lvl: int = int(crop["level"])
		if _ctx.farm.level() < lvl:
			body.add_child(UiKit.row(_look, [_item_icon(FishIcon.Kind.GOOD, str(crop["color"])), UiKit.label(Texts.fmt("crop_locked", [str(crop["name"]), lvl]), 0, _look.color("ui", "muted"))]))
			continue
		var _plant: Callable = func() -> void:
			var r: Production.Result = p.plant(i, id)
			if r == Production.Result.OK:
				_sfx.play(&"coin")
				close()
			else:
				_result(false, Texts.get_text("missing_items"))
		body.add_child(UiKit.row(_look, [_item_icon(FishIcon.Kind.GOOD, str(crop["color"])), UiKit.label(Texts.fmt("crop_have", [str(crop["name"]), p.count(id), _ptime(int(crop["seconds"]))])), UiKit.button(_look, Texts.get_text("plant"), _plant, p.count(id) > 0)]))


## A factory: its queue with timers, collect, the recipes and buying more queue slots.
func open_factory(id: String) -> void:
	var p: Production = _ctx.production
	var f: Dictionary = p.factory(id)
	var body: VBoxContainer = _sheet(str(f["name"]), open_factory.bind(id))
	_live = true
	var fs: Dictionary = p.factory_state(id)
	var queue: Array = fs["queue"]
	body.add_child(UiKit.label(Texts.fmt("factory_queue", [queue.size(), int(fs["slots"])]) + "   " + Texts.fmt("storage_used", [Texts.get_text("barn"), p.used("barn"), p.capacity("barn")]), 22))
	for q: Variant in queue:
		var left: int = p.seconds_left(float((q as Dictionary)["ready_at"]))
		body.add_child(UiKit.row(_look, [_item_icon(FishIcon.Kind.GOOD, str(_ctx.town_data.good(str((q as Dictionary)["item"])).get("color", "#ffffff"))), UiKit.label("%s ×%d · %s" % [_gname(str((q as Dictionary)["item"])), int((q as Dictionary)["out"]), Texts.get_text("ready") if left == 0 else _ptime(left)])]))
	var done: int = p.factory_done(id)
	var _collect: Callable = func() -> void:
		var r: Production.Result = p.collect_factory(id)
		_result(r == Production.Result.OK, Texts.get_text("collected") if r == Production.Result.OK else Texts.get_text("barn_full"))
	body.add_child(UiKit.button(_look, Texts.fmt("collect_done", [done]), _collect, done > 0))
	for r: Variant in f["recipes"]:
		var recipe: Dictionary = r
		var rid: String = str(recipe["id"])
		var lvl: int = int(recipe["level"])
		var title: String = "%s ×%d" % [_gname(rid), int(recipe["out"])]
		if _ctx.farm.level() < lvl:
			body.add_child(UiKit.row(_look, [_item_icon(FishIcon.Kind.GOOD, str(_ctx.town_data.good(rid).get("color", "#ffffff"))), UiKit.label(Texts.fmt("crop_locked", [title, lvl]), 0, _look.color("ui", "muted"))]))
			continue
		var _make: Callable = func() -> void:
			_prod_msg(p.produce(id, rid), Texts.get_text("queued"))
		var info: String = "%s\n%s" % [Texts.fmt("recipe_time", [title, _ptime(int(recipe["seconds"]))]), Texts.fmt("recipe_in", [_items_text(recipe["in"])])]
		body.add_child(UiKit.row(_look, [_item_icon(FishIcon.Kind.GOOD, str(_ctx.town_data.good(rid).get("color", "#ffffff"))), UiKit.label(info, _look.integer("ui", "small_size")), UiKit.button(_look, Texts.get_text("produce"), _make, queue.size() < int(fs["slots"]) and p._has_all(recipe["in"]))]))
	var price: int = p.slot_price(id)
	var _slot: Callable = func() -> void:
		_prod_msg(p.buy_slot(id), Texts.get_text("bought"))
	body.add_child(UiKit.button(_look, Texts.fmt("buy_slot", [price]) if price >= 0 else Texts.get_text("slots_max"), _slot, price >= 0 and _ctx.state.coins >= price))


## The barn and the silo: what is stored, how full, and the upgrades paid in materials.
func open_storage() -> void:
	var body: VBoxContainer = _sheet(Texts.get_text("storage"), open_storage)
	_storage_body(body, ["barn", "silo"])


## The silo only (its door on the farm).
func open_silo() -> void:
	var body: VBoxContainer = _sheet(Texts.get_text("silo_name"), open_silo)
	_storage_body(body, ["silo"])


## The barn chests (upstairs in the barn, 2026-11-22): each chest with its fill, in order (when
## one is full the goods go to the next), then the barn goods, the upgrade and the fish bag.
func open_chests() -> void:
	var p: Production = _ctx.production
	var body: VBoxContainer = _sheet(Texts.get_text("chests_title"), open_chests)
	body.add_child(UiKit.label(Texts.get_text("chest_next"), _look.integer("ui", "small_size"), _look.color("ui", "muted")))
	var last: int = p.chest_count() + (1 if p.house_chest_room() > 0 else 0)
	for i in last:
		var fill: Vector2i = p.chest_fill(i)
		var text: String = Texts.fmt("chest_line", [i + 1, fill.x, fill.y]) if i < p.chest_count() else Texts.fmt("house_chest_line", [fill.x, fill.y])
		if fill.x >= fill.y:
			text += "  (%s)" % Texts.get_text("chest_full")
		var bar := ProgressBar.new()
		bar.max_value = fill.y
		bar.value = fill.x
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(220, 22)
		bar.add_theme_stylebox_override(&"background", UiKit.flat(_look.color("ui", "energy_back"), 8))
		bar.add_theme_stylebox_override(&"fill", UiKit.flat(_look.color("ui", "bad") if fill.x >= fill.y else _look.color("ui", "good"), 8))
		body.add_child(UiKit.row(_look, [_item_icon(FishIcon.Kind.GOOD, "#9a6a3a"), UiKit.label(text), bar], i % 2 == 1))
	_storage_body(body, ["barn"])


func _storage_body(body: VBoxContainer, kinds: Array) -> void:
	var p: Production = _ctx.production
	var s: GameState = _ctx.state
	for kind: String in kinds:
		var name: String = Texts.get_text("barn") if kind == "barn" else Texts.get_text("silo_name")
		body.add_child(UiKit.label(Texts.fmt("storage_used", [name, p.used(kind), p.capacity(kind)]), 26))
		for id: Variant in s.shed:
			var n: int = int(s.shed[id])
			if n > 0 and p.storage_of(str(id)) == kind:
				body.add_child(UiKit.row(_look, [_item_icon(FishIcon.Kind.GOOD, str(_ctx.town_data.good(str(id)).get("color", "#ffffff"))), UiKit.label("%s × %d" % [_gname(str(id)), n])]))
		var needs: Dictionary = p.upgrade_needs(kind)
		var _up: Callable = func() -> void:
			var r: Production.Result = p.upgrade_storage(kind)
			_result(r == Production.Result.OK, Texts.get_text("upgraded_storage") if r == Production.Result.OK else Texts.get_text("missing_items"))
		var step: int = int(((p.data()["storage"] as Dictionary)[kind] as Dictionary)["step"])
		body.add_child(UiKit.label(Texts.fmt("upgrade_need", [_items_text(needs)]), _look.integer("ui", "small_size"), _look.color("ui", "muted")))
		body.add_child(UiKit.button(_look, Texts.fmt("upgrade_storage", [name, step]), _up, p._has_all(needs)))
	body.add_child(UiKit.label(Texts.fmt("bag_fish", [s.bag.size(), int(_ctx.data.tune("bag_size"))]), 22))
	for i in s.bag.size():
		body.add_child(UiKit.row(_look, [_fish_icon(s.bag[i].id), UiKit.label(_fish_line(s.bag[i]))], i % 2 == 1))


## The order board: each order with its items (and how many you have), reward, Entregar and
## Trocar; empty slots show when the next order comes.
func open_orders() -> void:
	var p: Production = _ctx.production
	var s: GameState = _ctx.state
	var body: VBoxContainer = _sheet(Texts.get_text("orders"), open_orders)
	_live = true
	for i in s.order_board.size():
		var o: Dictionary = s.order_board[i]
		var items: Dictionary = o["items"]
		if items.is_empty():
			body.add_child(UiKit.label(Texts.fmt("order_wait", [_ptime(p.seconds_left(float(o["wait_until"])))]), 0, _look.color("ui", "muted")))
			continue
		var can: bool = p._has_all(items)
		var _deliver: Callable = func() -> void:
			var r: Production.Result = p.deliver(i)
			_result(r == Production.Result.OK, Texts.get_text("order_done") if r == Production.Result.OK else Texts.get_text("order_missing"))
		var _discard: Callable = func() -> void:
			p.discard(i)
			_click()
			_refresh()
		var text: String = "%s\n%s" % [_items_text(items), Texts.fmt("order_reward", [int(o["coins"]), int(o["xp"])])]
		body.add_child(UiKit.row(_look, [UiKit.label(text, _look.integer("ui", "small_size"), _look.color("ui", "good") if can else _look.color("ui", "ink")), UiKit.button(_look, Texts.get_text("order_deliver"), _deliver, can), UiKit.button(_look, Texts.get_text("order_discard"), _discard)], i % 2 == 1))


## The roadside stall: 4 slots. Empty slots let you pick a product, quantity and price.
func open_stall(pick_slot: int = -1, pick_id: String = "", qty: int = 1, price: int = -1) -> void:
	var p: Production = _ctx.production
	var s: GameState = _ctx.state
	var body: VBoxContainer = _sheet(Texts.get_text("stall"), open_stall.bind(pick_slot, pick_id, qty, price))
	_live = pick_slot < 0
	var slots: Array = p.stall()
	if pick_slot >= 0:
		if pick_id == "":
			body.add_child(UiKit.label(Texts.get_text("stall_pick"), 24))
			for id: Variant in s.shed:
				var n: int = int(s.shed[id])
				if n > 0:
					body.add_child(UiKit.button(_look, "%s × %d" % [_gname(str(id)), n], open_stall.bind(pick_slot, str(id), 1, -1)))
			return
		var max_n: int = mini(p.count(pick_id), int((p.data()["stall"] as Dictionary)["max_count"]))
		qty = clampi(qty, 1, maxi(1, max_n))
		var base: int = p.base_price(pick_id, qty)
		if price < 0:
			price = int(float(base) * float((p.data()["stall"] as Dictionary)["price_start"]))
		var lo: int = maxi(1, int(float(base) * float((p.data()["stall"] as Dictionary)["price_min"])))
		var hi: int = int(float(base) * float((p.data()["stall"] as Dictionary)["price_max"]))
		price = clampi(price, lo, hi)
		body.add_child(UiKit.label(_gname(pick_id), 28))
		var qrow := HBoxContainer.new()
		qrow.add_child(UiKit.button(_look, " − ", open_stall.bind(pick_slot, pick_id, qty - 1, -1)))
		qrow.add_child(UiKit.label(Texts.fmt("stall_qty", [qty]), 24))
		qrow.add_child(UiKit.button(_look, " + ", open_stall.bind(pick_slot, pick_id, qty + 1, -1)))
		body.add_child(qrow)
		var prow := HBoxContainer.new()
		var step: int = maxi(1, base / 10)
		prow.add_child(UiKit.button(_look, " − ", open_stall.bind(pick_slot, pick_id, qty, price - step)))
		prow.add_child(UiKit.label(Texts.fmt("stall_price", [price]), 24))
		prow.add_child(UiKit.button(_look, " + ", open_stall.bind(pick_slot, pick_id, qty, price + step)))
		body.add_child(prow)
		var _put: Callable = func() -> void:
			var r: Production.Result = p.put_on_stall(pick_slot, pick_id, qty, price)
			_result(r == Production.Result.OK, Texts.get_text("stall_put") if r == Production.Result.OK else Texts.get_text("missing_items"))
			if r == Production.Result.OK:
				open_stall()
		body.add_child(UiKit.button(_look, Texts.get_text("stall_put"), _put))
		return
	for i in slots.size():
		var slot: Dictionary = slots[i]
		if slot.is_empty():
			body.add_child(UiKit.row(_look, [UiKit.label(Texts.get_text("stall_empty"), 0, _look.color("ui", "muted")), UiKit.button(_look, Texts.get_text("stall_put"), open_stall.bind(i, "", 1, -1), not s.shed.is_empty())]))
			continue
		var sold: bool = bool(slot["sold"])
		var _clear: Callable = func() -> void:
			p.clear_stall(i)
			_result(true, Texts.get_text("stall_sold_ok") if sold else Texts.get_text("stall_back"))
		var line: String = Texts.fmt("stall_sold" if sold else "stall_selling", [_gname(str(slot["item"])), int(slot["count"]), int(slot["price"])])
		body.add_child(UiKit.row(_look, [UiKit.label(line, 0, _look.color("ui", "good") if sold else _look.color("ui", "ink")), UiKit.button(_look, Texts.get_text("stall_collect") if sold else Texts.get_text("stall_back"), _clear)]))


## An expansion area: what it needs (farm level, materials, coins) and the Expandir button.
func open_expand(id: String) -> void:
	var p: Production = _ctx.production
	var e: Dictionary = p.expansion(id)
	var body: VBoxContainer = _sheet(Texts.fmt("expand_title", [str(e["name"])]), open_expand.bind(id))
	var good: Color = _look.color("ui", "good")
	var bad: Color = _look.color("ui", "bad")
	var lvl: int = int(e["level"])
	body.add_child(UiKit.label(Texts.fmt("build_need_level", [lvl, _ctx.farm.level()]), 24, good if _ctx.farm.level() >= lvl else bad))
	var items: Dictionary = e["items"]
	for item: Variant in items:
		var n: int = int(items[item])
		body.add_child(UiKit.label(Texts.fmt("build_need", [_gname(str(item)), p.count(str(item)), n]), 0, good if p.count(str(item)) >= n else bad))
	body.add_child(UiKit.label(Texts.fmt("build_coins", [_ctx.state.coins, int(e["coins"])]), 0, good if _ctx.state.coins >= int(e["coins"]) else bad))
	var _go: Callable = func() -> void:
		var r: Production.Result = p.expand(id)
		_result(r == Production.Result.OK, Texts.get_text("expand_ok") if r == Production.Result.OK else Texts.get_text("build_missing"))
		if r == Production.Result.OK:
			close()
	body.add_child(UiKit.button(_look, Texts.get_text("expand"), _go))


# --- Clothes (Story 017) ---

## The clothes shop: the fisherman turning in a 3D viewer and the pieces to try, buy and wear.
func open_clothes() -> void:
	var s: GameState = _ctx.state
	var body: VBoxContainer = _sheet(Texts.get_text("clothes"), open_clothes)
	var holder := SubViewportContainer.new()
	holder.custom_minimum_size = Vector2(260.0, 260.0)
	holder.stretch = true
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_viewer = SubViewport.new()
	_viewer.own_world_3d = true
	_viewer.transparent_bg = true
	holder.add_child(_viewer)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.0
	camera.position = Vector3(0.0, 0.9, 4.0)
	_viewer.add_child(camera)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35.0, 30.0, 0.0)
	_viewer.add_child(light)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(1, 0.95, 0.88)
	env.environment.ambient_light_energy = 0.8
	_viewer.add_child(env)
	_viewer_model = Fisherman.new()
	_viewer.add_child(_viewer_model)
	_viewer_model.setup_display(_look)
	_viewer_model.set_outfit(outfit_colors(_ctx.town_data, s))
	body.add_child(holder)
	for slot: String in ["hat", "shirt", "boots"]:
		body.add_child(UiKit.label(Texts.get_text("slot_" + slot), 26))
		for p: Variant in _ctx.town_data.clothes(slot):
			var piece: Dictionary = p
			var id: String = str(piece["id"])
			var owned: bool = s.clothes_owned.has(id)
			var wearing: bool = s.outfit.get(slot, "") == id
			var price: int = int(piece["price"])
			var text: String = Texts.get_text("wearing") if wearing else (Texts.get_text("wear") if owned else Texts.fmt("buy", [price]))
			var _act25: Callable = func() -> void:
				var r: Town.Result = _ctx.town.buy_piece(id)
				if r == Town.Result.OK:
					outfit_changed.emit()
				_result(r == Town.Result.OK, Texts.get_text("bought") if r == Town.Result.OK and not owned else (Texts.get_text("wear") if r == Town.Result.OK else _town_text(r)))
			var b: Button = UiKit.button(_look, text, _act25, not wearing and (owned or s.coins >= price))
			body.add_child(UiKit.row(_look, [_item_icon(FishIcon.Kind.GOOD, str(piece["color"])), UiKit.label(str(piece["name"])), b]))


## The fisherman colors for the outfit in [param state] (keys of the "colors" look group), plus
## "_custom_<group>" true when a piece other than the default one is worn (the 3D model keeps its
## own colors for the default pieces).
static func outfit_colors(town: TownData, state: GameState) -> Dictionary:
	var out: Dictionary = {}
	var hat: Dictionary = town.piece(state.outfit.get("hat", ""))
	if not hat.is_empty():
		out["hat"] = Color.html(str(hat["color"]))
		out["hat_dark"] = Color.html(str(hat["color"])).darkened(0.2)
		out["hat_band"] = Color.html(str(hat["trim"]))
		var custom_hat: bool = str(hat["id"]) != str((town.clothes("hat")[0] as Dictionary)["id"])
		out["_custom_hat"] = custom_hat
		out["_custom_hat_band"] = custom_hat
	var shirt: Dictionary = town.piece(state.outfit.get("shirt", ""))
	if not shirt.is_empty():
		out["vest"] = Color.html(str(shirt["color"]))
		out["vest_edge"] = Color.html(str(shirt["color"])).darkened(0.35)
		out["shirt"] = Color.html(str(shirt["trim"]))
		out["_custom_vest"] = str(shirt["id"]) != str((town.clothes("shirt")[0] as Dictionary)["id"])
	var boots: Dictionary = town.piece(state.outfit.get("boots", ""))
	if not boots.is_empty():
		out["boots"] = Color.html(str(boots["color"]))
		out["_custom_boots"] = str(boots["id"]) != str((town.clothes("boots")[0] as Dictionary)["id"])
	return out


# --- City hall (Story 018) ---

## City level, satisfaction and its parts, the next goal and the lots to build.
func open_cityhall() -> void:
	var s: GameState = _ctx.state
	var t: Town = _ctx.town
	var td: TownData = _ctx.town_data
	var body: VBoxContainer = _sheet(Texts.get_text("cityhall"), open_cityhall)
	body.add_child(UiKit.label(Texts.fmt("city_level", [s.city_level]), 30, _look.color("ui", "good")))
	var sat: float = t.satisfaction()
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = sat
	bar.custom_minimum_size = Vector2(0.0, 30.0)
	bar.show_percentage = false
	body.add_child(UiKit.label(Texts.fmt("satisfaction", [roundi(sat)]), 26))
	body.add_child(bar)
	var req: float = clampf(s.request_score / td.num("city", "request_target"), 0.0, 1.0)
	var services: int = 0
	var built: int = 0
	for l: Variant in td.lots():
		var lot: Dictionary = l
		if bool(lot.get("service", false)):
			services += 1
			built += 1 if s.is_built(str(lot["id"])) else 0
	body.add_child(UiKit.label(Texts.fmt("sat_parts", [roundi(req * 100.0), roundi(s.food_score * 100.0), roundi(100.0 * float(built) / float(maxi(services, 1)))]), _look.integer("ui", "small_size"), _look.color("ui", "muted")))
	var goal: float = t.next_level_goal()
	body.add_child(UiKit.label(Texts.fmt("next_goal", [roundi(goal)]) if goal >= 0.0 else Texts.get_text("city_max")))
	body.add_child(UiKit.label(Texts.get_text("lots"), 28))
	for l: Variant in td.lots():
		var lot: Dictionary = l
		var id: String = str(lot["id"])
		var cost: int = int(lot["cost"])
		var need: int = int(lot["min_city_level"])
		var text: String = Texts.get_text("built") if s.is_built(id) else (Texts.fmt("city_locked", [need]) if s.city_level < need else Texts.fmt("build", [cost]))
		var _act26: Callable = func() -> void:
			var r: Town.Result = t.build_lot(id)
			_result(r == Town.Result.OK, Texts.get_text("build_ok") if r == Town.Result.OK else _town_text(r))
		var b: Button = UiKit.button(_look, text, _act26, not s.is_built(id) and s.city_level >= need and s.coins >= cost)
		body.add_child(UiKit.row(_look, [UiKit.label("%s\n%s" % [str(lot["name"]), str(lot["about"])], _look.integer("ui", "small_size")), b]))


# --- Start and sleep (Story 008) ---

## The start menu (redone 2026-11-22 after the user's menu picture): the live farm behind,
## the "Lakebound" logo top-left and a cream card with Continuar (when a save exists), Novo jogo
## (confirmed if a save would be lost), Ajustes and Sair. The hovered or focused item sits on a
## highlight pill; the first item starts focused so keyboard and gamepad work. Emits
## [signal start_chosen].
func show_start(has_save: bool) -> void:
	_start_save = 1 if has_save else 0
	if _layer != null:
		_layer.queue_free()
	_rebuild = show_start.bind(has_save)
	_live = false
	_layer = Control.new()
	_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_layer)
	open_changed.emit(true)
	var shade := TextureRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var grad := Gradient.new()
	grad.set_color(0, _look.color("ui", "menu_shade"))
	grad.set_color(1, Color(0, 0, 0, 0))
	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.fill_to = Vector2(0.6, 0.0)
	shade.texture = grad_tex
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	_layer.add_child(shade)
	var margin: float = _look.num("ui", "menu_margin")
	var column := VBoxContainer.new()
	column.position = Vector2(margin, margin * 0.6)
	column.add_theme_constant_override(&"separation", 6)
	_layer.add_child(column)
	var logo: Label = UiKit.label(Texts.get_text("title"), _look.integer("ui", "menu_logo_size"), _look.color("ui", "menu_logo_color"))
	logo.autowrap_mode = TextServer.AUTOWRAP_OFF
	logo.add_theme_color_override(&"font_outline_color", _look.color("ui", "menu_logo_outline"))
	logo.add_theme_constant_override(&"outline_size", _look.integer("ui", "menu_logo_outline_size"))
	logo.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0.35))
	logo.add_theme_constant_override(&"shadow_offset_y", 6)
	column.add_child(logo)
	var tag: Label = UiKit.label(Texts.get_text("subtitle"), _look.integer("ui", "menu_tag_size"), _look.color("ui", "menu_logo_color"))
	tag.autowrap_mode = TextServer.AUTOWRAP_OFF
	tag.add_theme_color_override(&"font_outline_color", _look.color("ui", "menu_logo_outline"))
	tag.add_theme_constant_override(&"outline_size", 10)
	column.add_child(tag)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, margin * 0.6)
	column.add_child(gap)
	var card := PanelContainer.new()
	var card_style: StyleBoxFlat = UiKit.flat(_look.color("ui", "menu_card_fill"), _look.integer("ui", "menu_card_radius"))
	card_style.content_margin_left = 18
	card_style.content_margin_right = 18
	card_style.content_margin_top = 18
	card_style.content_margin_bottom = 18
	card_style.shadow_color = Color(0, 0, 0, 0.25)
	card_style.shadow_size = 12
	card_style.shadow_offset = Vector2(0, 6)
	card.add_theme_stylebox_override(&"panel", card_style)
	card.custom_minimum_size = Vector2(_look.num("ui", "menu_card_width"), 0)
	card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	column.add_child(card)
	var items := VBoxContainer.new()
	items.add_theme_constant_override(&"separation", 6)
	card.add_child(items)
	var go_continue: Callable = func() -> void:
		_click()
		close()
		start_chosen.emit(false)
	var go_new: Callable = func() -> void:
		_click()
		if has_save:
			_confirm_start()
		else:
			close()
			start_chosen.emit(true)
	var go_settings: Callable = func() -> void:
		_click()
		open_settings()
	var go_quit: Callable = func() -> void:
		get_tree().quit()
	var first: Button = null
	if has_save:
		first = _menu_item(items, Texts.get_text("start_continue"), go_continue)
	var new_button: Button = _menu_item(items, Texts.get_text("start_new"), go_new)
	if first == null:
		first = new_button
	_menu_item(items, Texts.get_text("settings"), go_settings)
	_menu_item(items, Texts.get_text("quit"), go_quit)
	first.call_deferred(&"grab_focus")


## One item of the start menu card: plain text, a highlight pill when hovered or focused.
func _menu_item(parent: Control, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(0, _look.num("ui", "button_height") + 8.0)
	b.add_theme_font_size_override(&"font_size", _look.integer("ui", "menu_item_size"))
	var ink: Color = _look.color("ui", "ink")
	for key: StringName in [&"font_color", &"font_hover_color", &"font_focus_color", &"font_pressed_color", &"font_hover_pressed_color"]:
		b.add_theme_color_override(key, ink)
	var plain: StyleBoxFlat = UiKit.flat(Color(0, 0, 0, 0), 22)
	plain.content_margin_left = 22
	var pill: StyleBoxFlat = UiKit.flat(_look.color("ui", "menu_pill"), 22)
	pill.content_margin_left = 22
	var pressed: StyleBoxFlat = UiKit.flat(_look.color("ui", "menu_pill_pressed"), 22)
	pressed.content_margin_left = 22
	b.add_theme_stylebox_override(&"normal", plain)
	b.add_theme_stylebox_override(&"hover", pill)
	b.add_theme_stylebox_override(&"focus", pill)
	b.add_theme_stylebox_override(&"pressed", pressed)
	b.pressed.connect(action)
	# Hover moves the focus too, so only one pill shows at a time.
	b.mouse_entered.connect(b.grab_focus)
	parent.add_child(b)
	return b


func _confirm_start() -> void:
	var body: VBoxContainer = _sheet(Texts.get_text("new_game"), _confirm_start)
	body.add_child(UiKit.label(Texts.get_text("confirm_new"), 26))
	var _act29: Callable = func() -> void:
		_click()
		close()
		start_chosen.emit(true)
	body.add_child(UiKit.button(_look, Texts.get_text("yes"), _act29))
	body.add_child(UiKit.button(_look, Texts.get_text("no"), show_start.bind(true)))
	var header: Control = (body.get_parent().get_parent() as VBoxContainer).get_child(0)
	(header.get_child(1) as Control).visible = false


## The sleep screen: a dark overlay with the new day number that fades out by itself.
func show_sleep(day: int, auto: bool) -> void:
	if _sleep != null:
		_sleep.queue_free()
	_sleep = ColorRect.new()
	(_sleep as ColorRect).color = Color(0.04, 0.05, 0.12, 0.96)
	_sleep.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sleep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	for line: String in [Texts.get_text("sleep_title"), Texts.fmt("sleep_day", [day]), Texts.get_text("sleep_auto") if auto else ""]:
		var l: Label = UiKit.label(line, 40, Color(1, 0.96, 0.86))
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(l)
	_sleep.add_child(box)
	add_child(_sleep)
	_sleep_left = 2.8
