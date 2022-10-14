#!/usr/bin/env bash

# For left and right hipp
# Get COM
# Show affine and warp outlines on subj T1
# Show subject hipp and subject GM


fsleyes render -of subj.png \
  --scene ortho --worldLoc 24 -10 -23 --displaySpace world --xzoom $z --yzoom $z --zzoom $z \
  --layout horizontal --hideCursor --hideLabels \
  ${WT1_NII} --overlayType volume \
  ${WSEG_NII} --overlayType label --lut random_big --outlineWidth 0 #--outline




# Combine into single PDF
${IMMAGDIR}/montage \
-mode concatenate \
subj.png atlas.png \
-tile 1x2 -trim -quality 100 -background black -gravity center \
-border 20 -bordercolor black page1.png

info_string="$PROJECT $SUBJECT $SESSION $SCAN"
${IMMAGDIR}/convert \
-size 2600x3365 xc:white \
-gravity center \( page1.png -resize 2400x \) -composite \
-gravity North -pointsize 48 -annotate +0+100 \
"PMAT ROIs in atlas space" \
-gravity SouthEast -pointsize 48 -annotate +100+100 "$(date)" \
-gravity NorthWest -pointsize 48 -annotate +100+200 "${info_string}" \
makerois-PMAT.pdf