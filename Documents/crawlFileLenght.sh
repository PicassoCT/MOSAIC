
for f in $(find /home/picasso/.spring/games/Mosaic.sdd/sounds/advertising/media/ -name '*.ogg' ); do 
	soxi $f >> result.txt
done





