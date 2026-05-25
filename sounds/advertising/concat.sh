mkdir -p /tmp/ogg_norm && \
i=0 && \
for f in *.ogg; do \
  ffmpeg -y -i "$f" -ar 48000 -ac 2 -c:a pcm_s16le "/tmp/ogg_norm/$(printf "%04d" $i).wav"; \
  i=$((i+1)); \
done && \
printf "file '%s'\n" /tmp/ogg_norm/*.wav > /tmp/ogg_norm/list.txt && \
ffmpeg -y -f concat -safe 0 -i /tmp/ogg_norm/list.txt -c:a pcm_s16le /tmp/ogg_norm/audio.wav && \
ffmpeg -y -loop 1 -i blimp.png -i /tmp/ogg_norm/audio.wav \
-c:v libx264 -tune stillimage \
-c:a aac -b:a 192k \
-pix_fmt yuv420p \
-shortest \
output.mp4 && \
rm -rf /tmp/ogg_norm && \
shutdown now