#!/usr/bin/env bash

echo Making PDF

cd "${out_dir}"

# Registration check
fsleyes render -of reg-wt1.png -sz 300 900 \
    --scene ortho --displaySpace world --hideCursor -lo vertical \
    wt1-warp -ot volume -dr 0 95% \
    "${FSLDIR}"/data/standard/MNI152_T1_2mm_brain_mask -ot mask -mc 0.3 0.5 0.8 -o -w3
fsleyes render -of reg-mni.png -sz 300 900 \
    --scene ortho --displaySpace world --hideCursor -lo vertical \
    "${FSLDIR}"/data/standard/MNI152_T1_2mm -ot volume \
    "${FSLDIR}"/data/standard/MNI152_T1_2mm_brain_mask -ot mask -mc 0.3 0.5 0.8 -o -w3

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
    reg-wt1.png reg-mni.png \
    -trim -tile 2x1 -quality 100 -background black -gravity center \
    -border 20 -bordercolor black page-reg.png

montage \
    -mode concatenate \
    lh-hipp-affine.png rh-hipp-affine.png \
    lh-gm-affine.png rh-gm-affine.png \
    -trim -tile 2x2 -quality 100 -background black -gravity center \
    -border 20 -bordercolor black page-affine.png

montage \
    -mode concatenate \
    lh-hipp-warp.png rh-hipp-warp.png \
    lh-gm-warp.png rh-gm-warp.png \
    -trim -tile 2x2 -quality 100 -background black -gravity center \
    -border 20 -bordercolor black page-warp.png

# 8.5 x 11 in is 2550x3300 at 300 dpi
convert \
    -size 2550x3300 xc:white \
    -gravity center \( page-reg.png -resize 2200x2400 \) -composite \
    -gravity North -pointsize 48 -annotate +0+200 \
        "Nonlinear registration to atlas" \
    -gravity South -pointsize 48 -annotate +0+200 \
        "Left Subject\nRight: Atlas\nBlue: Atlas brain mask" \
    page-reg.pdf

convert \
    -size 2550x3300 xc:white \
    -gravity center \( page-affine.png -resize 2200x2200 \) -composite \
    -gravity North -pointsize 48 -annotate +0+300 \
        "Hippocampus parenchymal fraction, affine transform" \
    -gravity South -pointsize 48 -annotate +0+350 \
        "Blue: Atlas\nTop red: Subject hippocampus\nBottom red: Subject non-CSF" \
    page-affine.pdf

convert \
    -size 2550x3300 xc:white \
    -gravity center \( page-warp.png -resize 2200x2200 \) -composite \
        -gravity North -pointsize 48 -annotate +0+300 \
            "Hippocampus parenchymal fraction, warp transform" \
        -gravity South -pointsize 48 -annotate +0+350 \
            "Blue: Atlas\nTop red: Subject hippocampus\nBottom red: Subject non-CSF" \
    page-warp.pdf

convert page-reg.pdf page-warp.pdf page-affine.pdf hipp-pf.pdf

