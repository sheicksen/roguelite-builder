# Credit: Queble's Hitbox System on YouTube
# Link to video: https://youtube.com/watch?v=cX-vzfmzjnE

class_name HitLog extends RefCounted

var hit_log: Array = []

func has_hit(node: Node) -> bool:
	return hit_log.has(node)

func log_hit(node:Node)->void:
	hit_log.append(node)
	print("Hit: ", node)
