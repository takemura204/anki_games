#!/usr/bin/env bash
# ホットリスタート後タスク用: Flutter が接続している端末（-d）を推定し、
# Android ならエミュレーター、iOS Simulator なら Simulator を最前面へ。
# iOS は System Events のみ（Simulator を勝手に起動しない）。

set -euo pipefail

extract_flutter_device_id() {
	local line id
	while IFS= read -r line; do
		case "$line" in
		*flutter_tools*.snapshot*run* | *flutter_tools*.snapshot*attach*) ;;
		*) continue ;;
		esac
		id=""
		if echo "$line" | grep -qE '(^|[[:space:]])-d='; then
			id=$(echo "$line" | sed -E 's/.*(^|[[:space:]])-d=([^[:space:]]+).*/\2/')
		elif echo "$line" | grep -qE '[[:space:]]-d[[:space:]]'; then
			id=$(echo "$line" | sed -E 's/.*(^|[[:space:]])(-d[[:space:]]+)([^[:space:]]+).*/\3/')
		fi
		if [[ -z "$id" ]] && echo "$line" | grep -q '--device-id='; then
			id=$(echo "$line" | sed -E 's/.*--device-id=([^[:space:]]+).*/\1/')
		fi
		if [[ -n "$id" ]]; then
			echo "$id"
			return 0
		fi
	done < <(ps auxww 2>/dev/null | grep '[f]lutter_tools' || true)
	return 1
}

is_skip_target() {
	local d
	d=$(echo "$1" | tr '[:upper:]' '[:lower:]')
	case "$d" in
	chrome | chrome-canary | edge | windows | win32 | linux | macos | wasm | dart-vm) return 0 ;;
	esac
	case "$d" in
	web-*) return 0 ;;
	esac
	return 1
}

resolve_kind() {
	local id="$1"
	if is_skip_target "$id"; then
		echo skip
		return 0
	fi
	case "$id" in
	emulator-*) echo android && return 0 ;;
	esac
	if command -v adb >/dev/null 2>&1; then
		local st
		st=$(adb -s "$id" get-state 2>/dev/null || true)
		case "$st" in
		device | authorizing) echo android && return 0 ;;
		esac
	fi
	if command -v xcrun >/dev/null 2>&1; then
		if xcrun simctl list devices booted 2>/dev/null | grep -F "($id)" | grep -q Booted; then
			echo ios
			return 0
		fi
	fi
	echo unknown
}

infer_kind_without_id() {
	local adb_n booted
	adb_n=0
	booted=0
	if command -v adb >/dev/null 2>&1; then
		adb_n=$(adb devices 2>/dev/null | awk '$2 == "device" { n++ } END { print n + 0 }')
	fi
	if command -v xcrun >/dev/null 2>&1; then
		booted=$(xcrun simctl list devices booted 2>/dev/null | grep -c '(Booted)' || echo 0)
	fi
	if [[ "$adb_n" -ge 1 && "$booted" -eq 0 ]]; then
		echo android
	elif [[ "$booted" -ge 1 && "$adb_n" -eq 0 ]]; then
		echo ios
	else
		echo unknown
	fi
}

darwin_front() {
	case "$1" in
	android)
		osascript <<'APPLESCRIPT' || true
tell application "System Events"
	if exists process "qemu-system-aarch64" then set frontmost of process "qemu-system-aarch64" to true
	if exists process "qemu-system-x86_64" then set frontmost of process "qemu-system-x86_64" to true
end tell
try
	tell application "Android Emulator" to activate
end try
APPLESCRIPT
		;;
	ios)
		osascript <<'APPLESCRIPT' || true
tell application "System Events"
	if exists process "Simulator" then set frontmost of process "Simulator" to true
end tell
APPLESCRIPT
		;;
	esac
}

linux_front() {
	case "$1" in
	android)
		if command -v wmctrl >/dev/null 2>&1; then
			wmctrl -xa 'Android Emulator' 2>/dev/null || true
			wmctrl -xa 'qemu-system' 2>/dev/null || true
		fi
		;;
	esac
}

main() {
	local id kind
	id=$(extract_flutter_device_id || true)
	kind="unknown"
	if [[ -n "$id" ]]; then
		kind=$(resolve_kind "$id")
	else
		kind=$(infer_kind_without_id)
	fi
	case "$kind" in
	skip | unknown) exit 0 ;;
	esac

	case "$(uname -s)" in
	Darwin) darwin_front "$kind" ;;
	Linux) linux_front "$kind" ;;
	*) ;;
	esac
}

main "$@"
