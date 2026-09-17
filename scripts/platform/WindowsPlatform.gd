## Windows platform implementation.
## No ads, no IAP, no haptics in MVP.
class_name WindowsPlatform
extends BasePlatform


func initialize() -> void:
	print("[WindowsPlatform] Initialized")


func supports_ads() -> bool:
	return false  # No ads on Windows


func supports_iap() -> bool:
	return false  # Future: Steam, Microsoft Store


func share(text: String, image_path: String = "") -> void:
	# On Windows, copy to clipboard
	DisplayServer.clipboard_set(text)
	print("[WindowsPlatform] Shared text copied to clipboard")
