extends CanvasLayer

var indicators: Dictionary = {} # marker -> indicator instance

func _ready() -> void:
	layer = 100 # Draw above everything

func create_indicator(marker: OffscreenMarker) -> void:
	if indicators.has(marker):
		return
	
	var indicator = OffscreenIndicator.new()
	indicator.setup(marker)
	add_child(indicator)
	indicators[marker] = indicator

func remove_indicator(marker: OffscreenMarker) -> void:
	if not indicators.has(marker):
		return
	
	var indicator = indicators[marker]
	indicator.hide_and_queue_free()
	indicators.erase(marker)

func _process(delta: float) -> void:
	# Clean up if marker was freed
	for marker in indicators.keys():
		if not is_instance_valid(marker):
			indicators.erase(marker)
