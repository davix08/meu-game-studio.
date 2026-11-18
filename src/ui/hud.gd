class_name Hud
extends CanvasLayer
## The 2D layer over the 3D world that holds the whole interface: joystick, [TopBar],
## [FishingHud], [ActionBar] and [Screens] (added by the main scene in that order, so the
## screens draw on top). Story 006 moved the region name and the FPS counter of Story 002 into
## the [TopBar] (the FPS counter is a setting).
##
## Usage:
## [codeblock]
## var hud := Hud.new()
## add_child(hud)
## hud.setup(look)
## hud.add_child(top_bar)
## [/codeblock]


## Prepares the layer (nothing to build: the children are added by the main scene).
func setup(_look: WorldLook) -> void:
	layer = 1
