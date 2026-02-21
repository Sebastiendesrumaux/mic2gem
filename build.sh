export JAVA_HOME=/data/data/com.termux/files/usr/lib/jvm/java-17-openjdk
export PATH="$JAVA_HOME/bin:$PATH"
export JAVA_HOME=/data/data/com.termux/files/usr/lib/jvm/java-17-openjdk
export PATH="$JAVA_HOME/bin:$PATH"
#!/data/data/com.termux/files/usr/bin/bash
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
export JAVA_HOME="${JAVA_HOME:-/data/data/com.termux/files/usr/lib/jvm/java-17-openjdk}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-/data/data/com.termux/files/home/android-sdk}"
export ANDROID_HOME="${ANDROID_HOME:-$ANDROID_SDK_ROOT}"
sh "$DIR/gradlew" --no-daemon assembleDebug
echo "✓ APK: app/build/outputs/apk/debug/app-debug.apk"
