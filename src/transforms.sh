#!/usr/bin/env bash
#
# Transform the H-O hippocampus prob maps to the hi-res T1 space using all three
# available transforms (whole brain affine, hippocampus-specific affine, warp).

cd "${out_dir}"


##########################################################################
## Compute inverse transforms
echo Compute inverse transforms
convert_xfm -omat mni-to-t1-affine.mat -inverse t1-to-mni-affine.mat
invwarp --ref=t1 --warp=t1-to-mni-warpcoef --out=mni-to-t1-warpcoef
for h in lh rh; do
    convert_xfm -omat ${h}.mni-to-t1-haffine.mat -inverse ${h}.t1-to-mni-haffine.mat
done


##########################################################################
## Transform HO probabilistic maps to T1 space
echo Transform atlas probmaps

# Select the needed ones only
fslroi "${FSLDIR}"/data/atlases/HarvardOxford/HarvardOxford-sub-prob-1mm \
    lh.HarvardOxford-sub-prob-hipp 8 1
fslroi "${FSLDIR}"/data/atlases/HarvardOxford/HarvardOxford-sub-prob-1mm \
    rh.HarvardOxford-sub-prob-hipp 18 1

# Whole brain affine
for h in lh rh; do
    flirt \
        -in ${h}.HarvardOxford-sub-prob-hipp \
        -ref t1 \
        -init mni-to-t1-affine.mat \
        -applyxfm \
        -out ${h}.prob-HOhipp-affine
done

# Warp
for h in lh rh; do
    applywarp \
        --in=${h}.HarvardOxford-sub-prob-hipp \
        --ref=t1 \
        --warp=mni-to-t1-warpcoef \
        --interp=trilinear \
        --out=${h}.prob-HOhipp-warp
done

# Hippocampus-specific affine
for h in lh rh; do
    flirt \
        -in ${h}.HarvardOxford-sub-prob-hipp \
        -ref t1 \
        -init ${h}.mni-to-t1-haffine.mat \
        -applyxfm \
        -out ${h}.prob-HOhipp-haffine
done


##########################################################################
## Resample prob maps to T1 hi-res space and threshold
echo Resample to hi-res space
for h in lh rh; do
    for w in affine warp haffine; do
        flirt \
            -in ${h}.prob-HOhipp-${w} \
            -ref ${h}.hippoAmygLabels-T1.v21 \
            -usesqform \
            -applyxfm \
            -out ${h}.prob-HOhipp-hires-${w}
        fslmaths \
            ${h}.prob-HOhipp-hires-${w} \
            -thr ${pthresh} \
            -bin \
            ${h}.HOhipp-mask-${w}
    done
done


