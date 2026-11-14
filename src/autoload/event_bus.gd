extends Node
## Global signal hub (autoload "EventBus").
##
## Replaces the IObservable/IObserver pair from the reference structure: systems
## emit here and UI/level code listens, so nothing holds a hard reference to the HUD.

## Player hit points changed.
signal player_health_changed(current: int, maximum: int)
## Super meter changed. [param cards] is fractional (2.5 = two full cards and a half).
signal super_meter_changed(cards: float, max_cards: int)
## Player parried a parryable attack.
signal player_parried
## Player ran out of hit points.
signal player_died
## Boss hit points changed.
signal boss_health_changed(current: int, maximum: int)
## Boss entered a new phase (0-based).
signal boss_phase_changed(phase_index: int)
## Boss reached zero hit points.
signal boss_defeated
## Something asked the game to pause (pause button, app lost focus).
signal pause_requested
