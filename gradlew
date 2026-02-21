#!/data/data/com.termux/files/usr/bin/sh
APP_BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
exec sh "$APP_BASE_DIR/gradle/wrapper/gradle-wrapper" "$@"
