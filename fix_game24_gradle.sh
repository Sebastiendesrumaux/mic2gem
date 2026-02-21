#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

PROJ="${1:-$(pwd)}"
APP="$PROJ/app"
NS="com.example.mic2gem"

echo "→ Projet : $PROJ"
mkdir -p "$APP/src/main" "$APP/src/main/res" "$APP/src/main/java" "$APP/src/main/res/layout"

# 1) settings.gradle — pluginManagement + dépôts de résolution
cat > "$PROJ/settings.gradle" <<'EOF'
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
rootProject.name = "Game24"
include(":app")
EOF
echo "✓ settings.gradle réécrit."

# 2) build.gradle (racine) — déclare l’AGP ici
cat > "$PROJ/build.gradle" <<'EOF'
plugins {
  id("com.android.application") version "8.1.0" apply false
}
EOF
echo "✓ build.gradle (racine) OK."

# 3) app/build.gradle — module minimal
cat > "$APP/build.gradle" <<EOF
plugins {
  id("com.android.application")
}

android {
  namespace "${NS}"
  compileSdk 33

  defaultConfig {
    applicationId "${NS}"
    minSdk 24
    targetSdk 33
    versionCode 1
    versionName "1.0"
  }

  buildTypes {
    release {
      minifyEnabled false
      proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
  }
}

dependencies {
  implementation "androidx.appcompat:appcompat:1.6.1"
  implementation "com.google.android.material:material:1.9.0"
  implementation "androidx.constraintlayout:constraintlayout:2.1.4"
}
EOF
echo "✓ app/build.gradle OK."

# 4) gradle.properties — aapt2 Termux + réglages utiles
AAPT2_BIN="/data/data/com.termux/files/usr/bin/aapt2"
GP="$PROJ/gradle.properties"
touch "$GP"
grep -q '^org.gradle.jvmargs' "$GP" 2>/dev/null || echo 'org.gradle.jvmargs=-Xmx1024m -Dfile.encoding=UTF-8' >> "$GP"
grep -q '^android.nonTransitiveRClass' "$GP" 2>/dev/null || echo 'android.nonTransitiveRClass=true' >> "$GP"
if command -v aapt2 >/dev/null 2>&1; then
  if grep -q '^android.aapt2FromMavenOverride' "$GP" 2>/dev/null; then
    sed -i "s|^android.aapt2FromMavenOverride=.*|android.aapt2FromMavenOverride=${AAPT2_BIN}|" "$GP"
  else
    echo "android.aapt2FromMavenOverride=${AAPT2_BIN}" >> "$GP"
  fi
fi
echo "✓ gradle.properties ajusté."

# 5) proguard & manifest & layout & MainActivity
cat > "$APP/proguard-rules.pro" <<'EOF'
# (vide)
EOF

mkdir -p "$APP/src/main/res/values"
cat > "$APP/src/main/res/values/styles.xml" <<'EOF'
<resources>
    <style name="AppTheme" parent="android:Theme.Material.Light.NoActionBar"/>
</resources>
EOF

cat > "$APP/src/main/AndroidManifest.xml" <<EOF
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="${NS}">
  <application
      android:label="Game24"
      android:theme="@style/AppTheme">
    <activity
        android:name=".MainActivity"
        android:exported="true">
      <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
      </intent-filter>
    </activity>
  </application>
</manifest>
EOF

cat > "$APP/src/main/res/layout/activity_main.xml" <<'EOF'
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:padding="24dp">

    <TextView
        android:id="@+id/tv"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Game24 — squelette prêt"
        android:textSize="18sp"/>
</FrameLayout>
EOF

PKG_DIR="$APP/src/main/java/$(echo "$NS" | tr . /)"
mkdir -p "$PKG_DIR"
cat > "$PKG_DIR/MainActivity.java" <<EOF
package ${NS};

import android.app.Activity;
import android.os.Bundle;

public class MainActivity extends Activity {
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_main);
  }
}
EOF
echo "✓ Activity/Manifest/Layouts minimaux générés."

# 6) nettoyage caches Gradle (sécurisant après modifs)
rm -rf "$PROJ/.gradle" "$PROJ/app/build" \
       /data/data/com.termux/files/home/.gradle/caches/transforms-3 2>/dev/null || true

# 7) build
echo "→ Compilation…"
(cd "$PROJ" && sh ./gradlew --no-daemon clean assembleDebug)
echo "✓ Build terminé : $APP/build/outputs/apk/debug/app-debug.apk"
