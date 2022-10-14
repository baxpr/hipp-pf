#!/usr/bin/env bash

# For left and right hipp
# Get COM
# Show affine and warp outlines on subj T1
# Show subject hipp and subject GM

# Hippocampus regions. Red=subject, blue=atlas
for w in affine warp; do
    for h in lh rh; do
        com=$(fslstats ${h}.hipp-mask -c)
        fsleyes render -of ${h}-hipp-${w}.png -sz 600 600 \
            --scene ortho --worldLoc $com --displaySpace world \
            --hideCursor --hideLabels --hidey --hidez \
            ${h}.t1 -ot volume -dr 0 95% \
            ${h}.hipp-mask -ot mask -mc 0.9 0.3 0.3 -o -w 3 \
            ${h}.HOhipp-mask-${w} -ot mask -mc 0.3 0.5 0.8 -o -w 3
    done
done

# Gray matter within the atlas mask
for w in affine warp; do
    for h in lh rh; do
        com=$(fslstats ${h}.hipp-mask -c)
        fsleyes render -of ${h}-gm-${w}.png -sz 600 600 \
            --scene ortho --worldLoc $com --displaySpace world \
            --hideCursor --hideLabels --hidey --hidez \
            ${h}.t1 -ot volume -dr 0 95% \
            ${h}.hipp-gm-${w} -ot mask -mc 0.9 0.3 0.3 -w 3 -a 30 \
            ${h}.HOhipp-mask-${w} -ot mask -mc 0.3 0.5 0.8 -o -w 3
    done
done



# Combine into single PDF
montage \
    -mode concatenate \
    lh-hipp-affine.png rh-hipp-affine.png \
    lh-gm-affine.png rh-gm-affine.png \
    -tile 2x2 -quality 100 -background black -gravity center \
    -border 20 -bordercolor black page-affine.png

montage \
    -mode concatenate \
    lh-hipp-warp.png rh-hipp-warp.png \
    lh-gm-warp.png rh-gm-warp.png \
    -tile 2x2 -quality 100 -background black -gravity center \
    -border 20 -bordercolor black page-warp.png


# FIXME we are here
convert \
-size 2600x3365 xc:white \
-gravity center \( page1.png -resize 2400x \) -composite \
-gravity North -pointsize 48 -annotate +0+100 \
"PMAT ROIs in atlas space" \
-gravity SouthEast -pointsize 48 -annotate +100+100 "$(date)" \
-gravity NorthWest -pointsize 48 -annotate +100+200 "${info_string}" \
makerois-PMAT.pdf