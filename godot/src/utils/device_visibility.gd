extends Control

enum Device {
	WINDOWS = 1 << 0,
	MACOS = 1 << 1,
	LINUX = 1 << 2,
	FREEBSD = 1 << 3,
	NETBSD = 1 << 4,
	OPENBSD = 1 << 5,
	BSD = 1 << 6,
	ANDROID = 1 << 7,
	IOS = 1 << 8,
	WEB = 1 << 9
}

@export_flags(
	"Windows",
	"macOS",
	"Linux",
	"FreeBSD",
	"NetBSD",
	"OpenBSD",
	"BSD",
	"Android",
	"iOS",
	"Web"
) var device: int = Device.WINDOWS | Device.MACOS | Device.LINUX | Device.FREEBSD | Device.NETBSD | Device.OPENBSD | Device.BSD | Device.ANDROID | Device.IOS | Device.WEB

func _ready() -> void:
	match OS.get_name():
		"Windows":
			visible = device & Device.WINDOWS
		"macOS":
			visible = device & Device.MACOS
		"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			visible = device & Device.LINUX | device & Device.FREEBSD | device & Device.NETBSD | device & Device.OPENBSD | device & Device.BSD
		"Android":
			visible = device & Device.ANDROID
		"iOS":
			visible = device & Device.IOS
		"Web":
			visible = device & Device.WEB

	if !visible: process_mode = Node.ProcessMode.PROCESS_MODE_DISABLED