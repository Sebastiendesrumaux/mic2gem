#!/data/data/com.termux/files/usr/bin/bash
set -e
APK="app/build/outputs/apk/debug/app-debug.apk"
OUT="/sdcard/Download/com.example.mic2gem.apk"
cp -f "$APK" "$OUT"
echo "→ APK copié vers: $OUT"
# Ouvre l’installateur si possible
if command -v termux-open >/dev/null 2>&1; then
  termux-open "$OUT" || true
else
  # Fallback: tenter une vue du fichier
  am start -a android.intent.action.VIEW -d "file://$OUT" -t "application/vnd.android.package-archive" || true
fi
echo "Si l’installateur ne s’ouvre pas, installe manuellement via l’explorateur de fichiers, puis lance l’app."
