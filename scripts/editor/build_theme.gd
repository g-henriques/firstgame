extends SceneTree
## Builds res://assets/ui/theme.tres from the Aseprite GUI art and the pixel
## font. Run after re-exporting GUI art:
##   godot --headless --path . --script res://scripts/editor/build_theme.gd

const UI := "res://assets/ui/"

const WHITE := Color("ffffff")
const FOG := Color("c0cbdc")
const STEEL := Color("5a6988")
const YELLOW := Color("fee761")
const OUTLINE := Color("181425")


func _init() -> void:
	var t := Theme.new()
	var font: FontFile = load("res://assets/fonts/pixel_font.fnt")
	t.default_font = font
	t.default_font_size = 11

	var panel := _box("panel", 6, Vector4(10, 8, 10, 8))
	var panel_gold := _box("panel_gold", 6, Vector4(10, 8, 10, 8))

	# Label
	t.set_color("font_color", "Label", WHITE)
	t.set_color("font_shadow_color", "Label", OUTLINE)
	t.set_constant("shadow_offset_x", "Label", 1)
	t.set_constant("shadow_offset_y", "Label", 1)
	t.set_constant("line_spacing", "Label", 1)

	t.set_type_variation("TitleLabel", "Label")
	t.set_font_size("font_size", "TitleLabel", 22)
	t.set_color("font_color", "TitleLabel", YELLOW)
	t.set_type_variation("HugeLabel", "Label")
	t.set_font_size("font_size", "HugeLabel", 33)
	t.set_color("font_color", "HugeLabel", YELLOW)
	t.set_type_variation("DimLabel", "Label")
	t.set_color("font_color", "DimLabel", FOG)

	# Button
	for state in ["normal", "hover", "pressed", "disabled"]:
		t.set_stylebox(state, "Button", _box("button_" + state, 4, Vector4(8, 3, 8, 5)))
	t.set_stylebox("focus", "Button", _box("button_focus", 3, Vector4.ZERO))
	t.set_color("font_color", "Button", FOG)
	t.set_color("font_hover_color", "Button", WHITE)
	t.set_color("font_focus_color", "Button", WHITE)
	t.set_color("font_pressed_color", "Button", YELLOW)
	t.set_color("font_hover_pressed_color", "Button", YELLOW)
	t.set_color("font_disabled_color", "Button", STEEL)

	# Upgrade cards
	t.set_type_variation("CardButton", "Button")
	t.set_stylebox("normal", "CardButton", panel)
	t.set_stylebox("hover", "CardButton", panel_gold)
	t.set_stylebox("pressed", "CardButton", panel_gold)
	t.set_stylebox("disabled", "CardButton", panel)
	t.set_stylebox("focus", "CardButton", _box("button_focus", 3, Vector4.ZERO))

	# Panels
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_stylebox("panel", "Panel", panel)
	t.set_type_variation("PanelGold", "PanelContainer")
	t.set_stylebox("panel", "PanelGold", panel_gold)

	t.set_constant("separation", "VBoxContainer", 4)
	t.set_constant("separation", "HBoxContainer", 4)

	var err := ResourceSaver.save(t, UI + "theme.tres")
	print("theme.tres saved: ", error_string(err))
	quit()


func _box(name: String, margin: int, content: Vector4) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = load(UI + name + ".png")
	sb.texture_margin_left = margin
	sb.texture_margin_top = margin
	sb.texture_margin_right = margin
	sb.texture_margin_bottom = margin
	sb.content_margin_left = content.x
	sb.content_margin_top = content.y
	sb.content_margin_right = content.z
	sb.content_margin_bottom = content.w
	return sb
