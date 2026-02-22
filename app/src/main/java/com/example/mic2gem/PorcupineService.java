package com.example.mic2gem;

import android.app.*;
import android.content.Intent;
import android.media.AudioAttributes;
import android.media.SoundPool;
import android.os.*;
import android.widget.Toast;

import ai.picovoice.porcupine.*;

public class PorcupineService extends Service {
	private RandomSound randomSound;

    private PorcupineManager porcupineManager;
    private SoundPool soundPool;
    private int beepId;
    private final String ACCESS_KEY = "ehtMKoAPNeHA1s54HaxD4ZPEuyPilv0vlV+N/WUfJUaz+lQkh32GCg=="; 
    private final Handler handler = new Handler(Looper.getMainLooper());
    private final String CHANNEL_ID = "mic2gem_channel";

    @Override
    public void onCreate() {
        super.onCreate();
	randomSound = new RandomSound(this);

        setupSoundPool();
        startForegroundService();
    }

    private void setupSoundPool() {
        AudioAttributes attrs = new AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build();
        soundPool = new SoundPool.Builder().setMaxStreams(1).setAudioAttributes(attrs).build();
        soundPool.setOnLoadCompleteListener((sp, sampleId, status) -> {
            if (status == 0) sp.play(sampleId, 1, 1, 0, 0, 1);
        });
        beepId = soundPool.load(this, R.raw.beep, 1);
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        startListening();
        return START_STICKY;
    }

    private void startListening() {
        try {
            // Utilisation des mots-clés intégrés (Built-In)
            // C'est beaucoup plus robuste car ça ne dépend pas d'un fichier externe
            Porcupine.BuiltInKeyword[] keywords = new Porcupine.BuiltInKeyword[]{
                Porcupine.BuiltInKeyword.BUMBLEBEE 
            };

            porcupineManager = new PorcupineManager.Builder()
                    .setAccessKey(ACCESS_KEY)
                    .setKeywords(keywords) // On utilise .setKeywords au lieu de .setKeywordPath
                    .setSensitivity(0.7f)
                    .build(getApplicationContext(), (keywordIndex) -> {
                        // Comme on n'a passé qu'un seul mot, l'index sera toujours 0
                        showDebugToast("🐝 Bumblebee détecté !");
                        randomSound.play();
			//soundPool.play(beepId, 1, 1, 0, 0, 1);
                        stopListening();
                        processSequence();
                    });

            porcupineManager.start();
            updateNotification("Bourdon à l'écoute...");
            showDebugToast("Moteur Porcupine lancé ✅");

        } catch (PorcupineException e) {
            String errorMsg = "Erreur Porcupine : " + e.getMessage();
            showDebugToast(errorMsg);
            updateNotification(errorMsg);
            e.printStackTrace();
        }
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
            resumeListeningAfterDelay(7000);
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
                porcupineManager = null;
            } catch (PorcupineException e) { e.printStackTrace(); }
        }
    }

    private void startForegroundService() {
        NotificationChannel channel = new NotificationChannel(CHANNEL_ID, "mic2gem", NotificationManager.IMPORTANCE_LOW);
        getSystemService(NotificationManager.class).createNotificationChannel(channel);
        Notification notification = new Notification.Builder(this, CHANNEL_ID)
                .setContentTitle("mic2gem")
                .setSmallIcon(android.R.drawable.ic_btn_speak_now)
                .build();
        startForeground(1, notification);
    }

    private void updateNotification(String content) {
        NotificationManager manager = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
        Notification notification = new Notification.Builder(this, CHANNEL_ID)
                .setContentTitle("mic2gem")
                .setContentText(content)
                .setSmallIcon(android.R.drawable.ic_btn_speak_now)
                .build();
        manager.notify(1, notification);
    }

    private void showDebugToast(String text) {
        new Handler(Looper.getMainLooper()).post(() -> 
            Toast.makeText(getApplicationContext(), text, Toast.LENGTH_SHORT).show()
        );
    }

    @Override
    public void onDestroy() {
        stopListening();
        if (soundPool != null) soundPool.release();
        super.onDestroy();
    }

    @Override public IBinder onBind(Intent intent) { return null; }
}

