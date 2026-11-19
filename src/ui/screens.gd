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

enum ShopTab { SELL, RODS, BAITS, ITEMS, FARM, AUCTION, UPGRADES }

var _look: WorldLook
var _ctx: GameContext
var _sfx: Sfx
var _layer: Control
var _scroll: ScrollContainer
var _rebuild: Callable
var _toast: Label
var _toast_left: float = 0.0
var _viewer: SubViewport
var _viewer_model: Fisherman
var _sleep_left: float = 0.0
var _sleep: Control


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
	if _sleep != null:
		_sleep_left -= delta
		_sleep.modulate.a = clampf(_sleep_left, 0.0, 1.0)
		if _sleep_left <= 0.0:
			_sleep.queue_free()
			_sleep = null


# --- frame ---

func _sheet(title: String, rebuild: Callable) -> VBoxContainer:
	var keep_scroll: int = 0
	var same: bool = _layer != null and _rebuild == rebuild
	if same and _scroll != null:
		keep_scroll = _scroll.scroll_vertical
	if _layer != null:
		_layer.queue_free()
		_layer = null
	_rebuild = rebuild
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
		_rebuild.call()


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
	body.add_child(UiKit.button(_look, Texts.get_text("continue"), _close_clicked))
	body.add_child(UiKit.button(_look, Texts.get_text("new_game"), _confirm_new.bind(open_settings)))


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
	var names: Array[String] = [Texts.get_text("tab_sell"), Texts.get_text("tab_rods"), Texts.get_text("tab_baits"), Texts.get_text("tab_items"), Texts.get_text("tab_farm"), Texts.get_text("tab_auction"), Texts.get_text("tab_upgrades")]
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
				var home_name: String = str(_ctx.town_data.lot(home).get("name", home))
				var built: bool = _ctx.state.is_built(home)
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

## The fish book: 35 species, undiscovered ones as silhouettes, with the counter.
func open_book() -> void:
	var s: GameState = _ctx.state
	var body: VBoxContainer = _sheet(Texts.get_text("book"), open_book)
	body.add_child(UiKit.label(Texts.fmt("book_count", [s.discovered(), _ctx.data.species.size()]), 26, _look.color("ui", "good")))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 8)
	grid.add_theme_constant_override(&"v_separation", 8)
	body.add_child(grid)
	for sp: GameData.Species in _ctx.data.species:
		var known: bool = s.book.has(sp.id)
		var text: String = Texts.get_text("book_unknown")
		if known:
			var entry: GameState.BookEntry = s.book[sp.id]
			text = "%s\n%s · %s · %d×" % [sp.name, _ctx.data.rarity_names[sp.rarity], _kg(entry.best), entry.count]
		else:
			text += "\n" + _ctx.data.rarity_names[sp.rarity]
		var label: Label = UiKit.label(text, _look.integer("ui", "small_size"), Color.html(_ctx.data.rarity_colors[sp.rarity]).darkened(0.35) if known else _look.color("ui", "muted"))
		var cell: PanelContainer = UiKit.row(_look, [_fish_icon(sp.id, known), label])
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(cell)


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

## The animal home [param home_id] (coop or corral): animals and their joy, trough, products,
## feed, collect and milk. Animals are bought at the auction (shop).
func open_ranch(home_id: String) -> void:
	var s: GameState = _ctx.state
	var t: Town = _ctx.town
	var f: Farm = _ctx.farm
	var td: TownData = _ctx.town_data
	var title: String = str(td.lot(home_id).get("name", home_id))
	var body: VBoxContainer = _sheet(title, open_ranch.bind(home_id))
	var capacity: int = 0
	for h: Variant in td.homes():
		if str((h as Dictionary)["id"]) == home_id:
			capacity = int((h as Dictionary)["capacity"])
	body.add_child(UiKit.label(Texts.fmt("ranch_home", [title, t.animals_in(home_id), capacity]), 26))
	for a: Dictionary in s.animals:
		var info: Dictionary = td.animal(str(a["kind"]))
		if str(info["home"]) != home_id:
			continue
		var line: String = Texts.fmt("animal_joy", [str(info["name"]), int(float(a["joy"]))])
		if info.has("grows_into"):
			line = Texts.fmt("calf_age", [str(info["name"]), int(info["grow_days"]) - int(a.get("age", 0))])
		body.add_child(UiKit.label(line, _look.integer("ui", "small_size")))
	body.add_child(UiKit.label(Texts.fmt("ranch_trough", [s.troughs.get(home_id, 0), int(td.num("ranch", "trough_capacity"))])))
	var _feed: Callable = func() -> void:
		var r: Farm.Result = f.feed(home_id)
		_result(r == Farm.Result.OK, Texts.get_text("filled") if r == Farm.Result.OK else (Texts.get_text("full") if r == Farm.Result.FULL else Texts.get_text("no_feed")))
	body.add_child(UiKit.button(_look, Texts.get_text("fill_trough"), _feed))
	var pending: int = t.pending_count(home_id)
	body.add_child(UiKit.label(Texts.fmt("ranch_pending", [pending])))
	var _collect: Callable = func() -> void:
		var r: Farm.Result = f.collect(home_id)
		_result(r == Farm.Result.OK, Texts.get_text("collected") if r == Farm.Result.OK else (Texts.get_text("bag_full") if r == Farm.Result.BAG_FULL else Texts.get_text("nothing")))
	body.add_child(UiKit.button(_look, Texts.get_text("collect"), _collect, pending > 0))
	if home_id == "curral" and not s.milker:
		var cows: int = f.cows_to_milk()
		body.add_child(UiKit.label(Texts.fmt("ranch_milk_ready", [cows])))
		var _milk: Callable = func() -> void:
			var r: Farm.Result = f.milk()
			_result(r == Farm.Result.OK, Texts.get_text("milked") if r == Farm.Result.OK else (Texts.get_text("bag_full") if r == Farm.Result.BAG_FULL else Texts.get_text("no_energy")))
		body.add_child(UiKit.button(_look, Texts.fmt("act_milk", [cows]), _milk, cows > 0))
	body.add_child(UiKit.label(Texts.get_text("ranch_buy_hint"), 0, _look.color("ui", "muted")))


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

## The start screen: title, Continuar (when a save exists) and Novo jogo (confirmed if a save
## would be lost). Emits [signal start_chosen].
func show_start(has_save: bool) -> void:
	var body: VBoxContainer = _sheet(Texts.get_text("title"), func() -> void: show_start(has_save))
	body.add_child(UiKit.label(Texts.get_text("subtitle"), 30, _look.color("ui", "muted")))
	if has_save:
		var _act27: Callable = func() -> void:
			_click()
			close()
			start_chosen.emit(false)
		body.add_child(UiKit.button(_look, Texts.get_text("start_continue"), _act27))
	var _act28: Callable = func() -> void:
		_click()
		if has_save:
			_confirm_start()
		else:
			close()
			start_chosen.emit(true)
	body.add_child(UiKit.button(_look, Texts.get_text("start_new"), _act28))
	# The start screen has no Fechar: the game waits for a choice.
	var header: Control = (body.get_parent().get_parent() as VBoxContainer).get_child(0)
	(header.get_child(1) as Control).visible = false


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
