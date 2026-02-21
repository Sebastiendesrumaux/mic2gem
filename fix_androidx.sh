#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

PROJ="${1:-}"
if [ -z "$PROJ" ]; then
  echo "Usage: $0 /chemin/absolu/du/projet"
  exit 1
fi

if [ ! -d "$PROJ" ]; then
  echo "✗ Dossier introuvable: $PROJ"
  exit 1
fi

echo "→ Projet: $PROJ"

GP="$PROJ/gradle.properties"
touch "$GP"

# 1) Active AndroidX + Jetifier + réglages utiles
if grep -q '^android.useAndroidX=' "$GP" 2>/dev/null; then
  sed -i 's/^android.useAndroidX=.*/android.useAndroidX=true/' "$GP"
else
  echo 'android.useAndroidX=true' >> "$GP"
fi

if grep -q '^android.enableJetifier=' "$GP" 2>/dev/null; then
  sed -i 's/^android.enableJetifier=.*/android.enableJetifier=true/' "$GP"
else
  echo 'android.enableJetifier=true' >> "$GP"
fi

if grep -q '^org.gradle.jvmargs=' "$GP" 2>/dev/null; then
  sed -i 's/^org.gradle.jvmargs=.*/org.gradle.jvmargs=-Xmx1024m -Dfile.encoding=UTF-8/' "$GP"
else
  echo 'org.gradle.jvmargs=-Xmx1024m -Dfile.encoding=UTF-8' >> "$GP"
fi

if ! grep -q '^android.nonTransitiveRClass=' "$GP" 2>/dev/null; then
  echo 'android.nonTransitiveRClass=true' >> "$GP"
fi

# 2) AAPT2 Termux (si disponible)
AAPT2_BIN="/data/data/com.termux/files/usr/bin/aapt2"
if command -v aapt2 >/dev/null 2>&1; then
  if grep -q '^android.aapt2FromMavenOverride=' "$GP" 2>/dev/null; then
    sed -i "s|^android.aapt2FromMavenOverride=.*|android.aapt2FromMavenOverride=${AAPT2_BIN}|" "$GP"
  else
    echo "android.aapt2FromMavenOverride=${AAPT2_BIN}" >> "$GP"
  fi
  echo "✓ AAPT2 externe fixé: ${AAPT2_BIN}"
else
  echo "⚠ aapt2 non trouvé dans Termux; Gradle prendra celui du dépôt maven."
fi

# 3) Sécurise settings.gradle (repos pour AGP)
if [ -f "$PROJ/settings.gradle" ]; then
  cat > "$PROJ/settings.gradle" <<'SGEOF'
pluginManagement {
  repositories {
    google()
    mavenCentral()
    gradlePluginPortal()
  }
}
dependencyResolutionManagement {
  repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
  repositories {
    google()
    mavenCentral()
  }
}
rootProject.name = rootProject.name ?: "AndroidApp"
include(":app")
SGEOF
  echo "✓ settings.gradle vérifié."
fi

# 4) Sécurise build.gradle racine (AGP déclaré ici)
if [ -f "$PROJ/build.gradle" ]; then
  cat > "$PROJ/build.gradle" <<'RTEOF'
plugins {
  id("com.android.application") version "8.1.0" apply false
}
RTEOF
  echo "✓ build.gradle (racine) vérifié."
fi

# 5) Purge caches AAPT2/transform pour repartir propre
echo "→ Nettoyage des caches Gradle/AAPT2…"
rm -rf "$PROJ/.gradle" "$PROJ/app/build" \
  /data/data/com.termux/files/home/.gradle/caches/transforms-3 \
  /data/data/com.termux/files/home/.gradle/caches/journal-1 2>/dev/null || true

# 6) Build
echo "→ Compilation (clean assembleDebug)…"
cd "$PROJ"
sh ./gradlew --no-daemon clean assembleDebug

echo "✓ Terminé. APK attendu ici : app/build/outputs/apk/debug/app-debug.apk"
