#!/bin/bash

# Vérifier si ffmpeg est installé
if ! command -v ffmpeg &> /dev/null; then
    echo "FFmpeg n'est pas installé. Installe-le avec : pkg install ffmpeg"
    exit 1
fi

# Créer un dossier de sortie pour ne pas écraser les originaux
mkdir -p wav_samples

for f in *.mp3; do
    [ -e "$f" ] || continue
    
    filename="${f%.*}"
    echo "Traitement de : $f"

    # Explication des filtres :
    # atrim=0:2 -> Garde uniquement les 2 premières secondes
    # loudnorm -> Normalisation au standard EBU R128
    ffmpeg -i "$f" -af "atrim=0:2,loudnorm" -ar 44100 "wav_samples/${filename}.wav" -y -loglevel error
done

echo "Terminé ! Tes fichiers sont dans le dossier 'wav_samples'."

