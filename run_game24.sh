#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# === Réglages projet (modifie si besoin) ======================================
PKG="com.example.mic2gem"
MAIN_ACTIVITY="MainActivity"  # Nom simple (sans le package)
APK_REL="app/build/outputs/apk/debug/app-debug.apk"
OUT_APK="/sdcard/Download/${PKG}.apk"

# === Fonctions utilitaires ====================================================
say() { printf "%b\n" "$*"; }

have_cmd() { command -v "$1" >/dev/null 2>&1; }

is_installed() {
  /system/bin/cmd package list packages "$PKG" | grep -q "$PKG" || return 1
}

launch_app() {
  # Tente de lancer l’activité principale
  local comp="${PKG}/${PKG}.${MAIN_ACTIVITY}"
  /system/bin/am start -a android.intent.action.MAIN \
                       -c android.intent.category.LAUNCHER \
                       -n "${comp}" >/dev/null 2>&1 && {
    say "✅ Application lancée (${comp})."
    return 0
  }
  # Fallback avec nom abrégé .MainActivity
  comp="${PKG}/.${MAIN_ACTIVITY}"
  /system/bin/am start -a android.intent.action.MAIN \
                       -c android.intent.category.LAUNCHER \
                       -n "${comp}" >/dev/null 2>&1 && {
    say "✅ Application lancée (${comp})."
    return 0
  }
  return 1
}

open_installer() {
  # 1) Tentative via am + file:// (peut échouer selon la version d’Android)
  /system/bin/am start -a android.intent.action.VIEW \
                       -d "file://${OUT_APK}" \
                       -t "application/vnd.android.package-archive" >/dev/null 2>&1 && return 0
  # 2) Si termux-open disponible (Termux:API), tente
  if have_cmd termux-open; then
    termux-open --view --content-type application/vnd.android.package-archive "${OUT_APK}" >/dev/null 2>&1 && return 0
  fi
  return 1
}

# === 1) Vérif APK construit ===================================================
if [ ! -f "${APK_REL}" ]; then
  say "⛏️  APK introuvable à '${APK_REL}'. Je tente une construction rapide…"
  if [ -x ./gradlew ]; then
    sh ./gradlew --no-daemon assembleDebug
  else
    say "❌ gradlew manquant ou non exécutable. Lance d’abord: 'bash ./build.sh'"
    exit 1
  fi
  [ -f "${APK_REL}" ] || { say "❌ Toujours pas d’APK. Abandon."; exit 1; }
fi

# === 2) Copie vers Downloads (zone partagée, cliquable) =======================
cp -f "${APK_REL}" "${OUT_APK}"
say "📦 APK copié → ${OUT_APK}"

# === 3) Si déjà installé, on lance directement ===============================
if is_installed; then
  say "📲 ${PKG} est déjà installé. Tentative de lancement…"
  if launch_app; then
    exit 0
  else
    say "ℹ️ Lancement par activité direct impossible. Essaie via l’icône du launcher."
    exit 0
  fi
fi

# === 4) Sinon, on ouvre l’installateur système ================================
say "🧩 App non installée. Ouverture de l’installateur système…"
if open_installer; then
  say "👉 Si l’installateur ne s’affiche pas, ouvre manuellement: ${OUT_APK}"
else
  say "📁 Ouvre manuellement l’APK depuis ton explorateur de fichiers:"
  say "   ${OUT_APK}"
fi

say "💡 Après installation, relance ce script pour démarrer l’app."
