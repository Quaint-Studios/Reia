class_name SystemGroups extends RefCounted

## Define the strict string names for our native GECS groups.

const PRE_PROCESS = "PreProcess" ## Network sync, inputs, client prediction
const PHYSICS = "Physics" ## Movement, collision
const VALIDATION = "Validation" ## Checking if requested actions are legal
const EXECUTION = "Execution" ## Applying items, buffs, and logic
const COMBAT = "Combat" ## Damage calculation, death checks
const AI = "AI" ## Monster logic and pathfinding
const SPAWNING = "Spawning" ## Respawning entities and cleanup
const POST_PROCESS = "PostProcess" ## Network broadcasting, VFX triggering
