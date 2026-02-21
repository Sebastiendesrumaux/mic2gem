package com.example.mic2gem;

import android.content.Context;
import android.media.MediaPlayer;
import android.os.Environment;
import android.util.Log;
import java.io.File;
import java.io.FilenameFilter;
import java.util.Random;

public class RandomSound {

    private final Context context;
    private MediaPlayer mediaPlayer;
    private final Random random = new Random();

    public RandomSound(Context context) {
        this.context = context;
    }

    public void play() {
        // Chemin : /storage/emulated/0/Download/rsound
        File rsoundDir = new File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), "rsound");

        if (!rsoundDir.exists() || !rsoundDir.isDirectory()) {
            Log.e("RandomSound", "Dossier introuvable : " + rsoundDir.getAbsolutePath());
            return;
        }

        // Filtre pour ne prendre que les fichiers .wav
        File[] wavFiles = rsoundDir.listFiles(new FilenameFilter() {
            @Override
            public boolean accept(File dir, String name) {
                return name.toLowerCase().endsWith(".wav");
            }
        });

        if (wavFiles == null || wavFiles.length == 0) {
            Log.e("RandomSound", "Aucun fichier .wav trouvé dans rsound");
            return;
        }

        // Choix aléatoire
        File targetFile = wavFiles[random.nextInt(wavFiles.length)];

        try {
            // Nettoyage si un son joue déjà
            if (mediaPlayer != null) {
                mediaPlayer.release();
            }

            mediaPlayer = new MediaPlayer();
            mediaPlayer.setDataSource(targetFile.getAbsolutePath());
            mediaPlayer.prepare(); 
            mediaPlayer.start();

            // Libération propre après lecture
            mediaPlayer.setOnCompletionListener(mp -> {
                mp.release();
                mediaPlayer = null;
            });

        } catch (Exception e) {
            Log.e("RandomSound", "Erreur lecture wav : " + e.getMessage());
        }
    }
}

