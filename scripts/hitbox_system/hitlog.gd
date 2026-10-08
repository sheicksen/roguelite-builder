# Credit: Queble's Hitbox System on YouTube
# Link to video: https://youtube.com/watch?v=cX-vzfmzjnE

class_name HitLog extends RefCounted
## Manages a list of nodes that parent object has contacted.

var hit_log: Array = [] ## Array of Nodes

func has_hit(node: Node) -> bool:
	return hit_log.has(node)

func log_hit(node:Node)->void:
	hit_log.append(node)
