class_name UIUtils extends RefCounted

static func safe_connect(sig: Signal, callable: Callable, context: String) -> void:
	assert(context != "", "UIUtils.safe_connect requires a context string")
	assert(callable.is_valid(), "UIUtils.safe_connect requires a valid callable")

	if sig.is_connected(callable):
		return

	var err := sig.connect(callable)
	assert(err == OK, "UIUtils.safe_connect failed (%s) in %s" % [err, context])
