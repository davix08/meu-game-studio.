extends RefCounted
## Physics layer bits, matching [layer_names] in project.godot.

const WORLD := 1 << 0
const PLAYER_BODY := 1 << 1
const PLAYER_HURTBOX := 1 << 2
const ENEMY_HURTBOX := 1 << 3
const PLAYER_ATTACK := 1 << 4
const ENEMY_ATTACK := 1 << 5
