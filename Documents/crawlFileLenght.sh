
for f in $(find /home/picassoct/.spring/games/Mosaic.sdd/sounds/advertising/media -name '*.ogg' ); do 
	soxi $f >> result.txt
done





