## Web platform implementation.
## Optimized for instant play, testing, and sharing.
class_name WebPlatform
extends BasePlatform


func initialize() -> void:
	print("[WebPlatform] Initialized")


func supports_ads() -> bool:
	return false  # Future: optional web ads


func supports_iap() -> bool:
	return false  # No IAP on web


func share(text: String, image_path: String = "") -> void:
	# Use Web Share API if available, otherwise clipboard
	if OS.has_feature("web"):
		JavaScriptBridge.eval("navigator.share ? navigator.share({text: '%s'}) : navigator.clipboard.writeText('%s')" % [text, text])
	print("[WebPlatform] Share triggered")
