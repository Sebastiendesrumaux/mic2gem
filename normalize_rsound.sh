cd ~/storage/downloads/rsound && \
mkdir -p normalized && \
for f in *.wav; do 
  ffmpeg -i "$f" -filter:a "loudnorm=I=-16:TP=-1.5:LRA=11" "normalized/$f"; 
done

