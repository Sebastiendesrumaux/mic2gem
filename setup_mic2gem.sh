#!/bin/bash

# Définition du nom du projet et du package
PROJECT_NAME="."
PACKAGE_PATH="com/example/mic2gem"
BASE_DIR="./$PROJECT_NAME"

echo "🚀 Création de l'arborescence pour $PROJECT_NAME..."

# Création des répertoires
mkdir -p "$BASE_DIR/app/src/main/java/$PACKAGE_PATH"
mkdir -p "$BASE_DIR/app/src/main/res/raw"
mkdir -p "$BASE_DIR/app/src/main/res/values"
mkdir -p "$BASE_DIR/app/src/main/assets"

# 1. Création du Manifest
cat <<EOF > "$BASE_DIR/app/src/main/AndroidManifest.xml"
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.mic2gem">

    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE" />

    <application
        android:allowBackup="true"
        android:label="mic2gem"
        android:theme="@style/Theme.AppCompat.Light.NoActionBar">

        <service 
            android:name=".PorcupineService" 
            android:foregroundServiceType="microphone"
            android:exported="false" />

        <activity android:name=".MainActivity" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

# 2. Création de MainActivity.java
cat <<EOF > "$BASE_DIR/app/src/main/java/$PACKAGE_PATH/MainActivity.java"
package com.example.mic2gem;

import android.Manifest;
import android.content.Intent;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;

public class MainActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.RECORD_AUDIO}, 1);
        startService(new Intent(this, PorcupineService.class));
        finish();
    }
}
EOF

# 3. Création de PorcupineService.java
cat <<EOF > "$BASE_DIR/app/src/main/java/$PACKAGE_PATH/PorcupineService.java"
package com.example.mic2gem;

import android.app.*;
import android.content.Intent;
import android.media.AudioAttributes;
import android.media.SoundPool;
import android.os.*;
import ai.picovoice.porcupine.*;

public class PorcupineService extends Service {

    private PorcupineManager porcupineManager;
    private SoundPool soundPool;
    private int beepId;
    private final String ACCESS_KEY = "VOTRE_CLE_PICOVOICE"; 
    private final Handler handler = new Handler(Looper.getMainLooper());

    @Override
    public void onCreate() {
        super.onCreate();
        setupSoundPool();
        startForegroundService();
    }

    private void setupSoundPool() {
        AudioAttributes attrs = new AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build();
        soundPool = new SoundPool.Builder().setMaxStreams(1).setAudioAttributes(attrs).build();
        beepId = soundPool.load(this, R.raw.beep, 1);
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        startListening();
        return START_STICKY;
    }

    private void startListening() {
        try {
            porcupineManager = new PorcupineManager.Builder()
                .setAccessKey(ACCESS_KEY)
                .setKeywordPath("bumblebee.ppn")
                .setSensitivity(0.7f)
                .setListener(keywordIndex -> {
                    soundPool.play(beepId, 1, 1, 0, 0, 1);
                    stopListening();
                    processSequence();
                }).build(getApplicationContext());
            porcupineManager.start();
        } catch (PorcupineException e) { e.printStackTrace(); }
    }

    private void processSequence() {
        Intent launchIntent = getPackageManager().getLaunchIntentForPackage("com.google.android.apps.bard");
        if (launchIntent != null) {
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(launchIntent);
        }

        handler.postDelayed(() -> {
            Intent macroIntent = new Intent("mic2gem_intent");
            sendBroadcast(macroIntent);
            resumeListeningAfterDelay(10000);
        }, 2000);
    }

    private void resumeListeningAfterDelay(int delay) {
        handler.postDelayed(this::startListening, delay);
    }

    private void stopListening() {
        if (porcupineManager != null) {
            try {
                porcupineManager.stop();
                porcupineManager.delete();
            } catch (PorcupineException e) { e.printStackTrace(); }
        }
    }

    private void startForegroundService() {
        String CHANNEL_ID = "mic2gem_channel";
        NotificationChannel channel = new NotificationChannel(CHANNEL_ID, "mic2gem Active", NotificationManager.IMPORTANCE_LOW);
        getSystemService(NotificationManager.class).createNotificationChannel(channel);
        Notification notification = new Notification.Builder(this, CHANNEL_ID)
                .setContentTitle("Bumblebee est à l'écoute")
                .setSmallIcon(android.R.drawable.ic_btn_speak_now).build();
        startForeground(1, notification);
    }

    @Override
    public void onDestroy() {
        stopListening();
        soundPool.release();
        super.onDestroy();
    }

    @Override public IBinder onBind(Intent intent) { return null; }
}
EOF

echo "✅ Structure terminée dans le dossier $BASE_DIR"
echo "⚠️ N'oublie pas de :"
echo "  1. Placer ton fichier 'bumblebee.ppn' dans app/src/main/assets/"
echo "  2. Placer un son 'beep.mp3' (ou wav) dans app/src/main/res/raw/"
echo "  3. Remplacer 'VOTRE_CLE_PICOVOICE' dans PorcupineService.java"

