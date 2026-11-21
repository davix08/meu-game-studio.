class_name GameContext
extends RefCounted
## Everything the screens need, gathered once by the main scene and handed to the UI (dependency
## injection instead of singletons): the data, the state and the systems that change the state.
##
## Usage:
## [codeblock]
## var ctx := GameContext.new()
## ctx.data = data
## ctx.state = state
## screens.setup(look, ctx)
## [/codeblock]

## Fish, gear and tuning data.
var data: GameData
## Town values.
var town_data: TownData
## The player's progress.
var state: GameState
## Shop rules.
var economy: Economy
## Town rules.
var town: Town
## Levels.
var progression: Progression
## Rest.
var energy: Energy
## Clock.
var clock: GameClock
## Farm rules (level, shed, buildings, orders, milking).
var farm: Farm
## Real-time production (field, factories, animals, storage, orders, stall, expansions).
var production: Production
