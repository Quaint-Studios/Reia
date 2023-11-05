class_name EnemySpawner
# Prefab Array. If size() == 1, then it will select 1. Otherwise it randomly selects the others.

# Sphere, Hemisphere, Cylinder, Square, or Rectangle

# Max Enemy count
# Respawn timer (with max value - if 0, then it's a fixed time instead of  a range)

# Picks a random x & y coordinate and
# raycasts straight down until it collides with a valid ground.

# Subscribes to each enemy's died signal.
# Creates a timer and afterwards it'll spawn a new enemy.
