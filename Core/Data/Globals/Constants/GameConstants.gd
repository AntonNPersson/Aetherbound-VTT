extends Node
const GAME_VERSION = "0.1.0"
enum DamageType { PHYSICAL, FIRE, COLD, ACID, POISON}
enum Condition { BLINDED, POISONED, FRIGHTENED}
enum MonsterSize { TINY, SMALL, MEDIUM, LARGE, HUGE, GARGANTUAN }
const MONSTER_SIZE_MODIFIER = {
    MonsterSize.TINY: 0.25,
    MonsterSize.SMALL: 0.5,
    MonsterSize.MEDIUM: 1.0,
    MonsterSize.LARGE: 2.0,
    MonsterSize.HUGE: 2.5,
    MonsterSize.GARGANTUAN: 3.0
}
enum MovementState { LAND, FLY, SWIM, CLIMB, BURROW }