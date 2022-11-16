#!/usr/bin/env bash
#
# Transform the H-O hippocampus prob maps to the hi-res T1 space using all three
# available transforms (whole brain affine, hippocampus-specific affine, warp).

##########################################################################
## Compute inverse transforms
echo Compute inverse transforms
convert_xfm -omat mni-to-t1-affine.mat -inverse t1-to-mni-affine.mat
invwarp --ref=t1 --warp=t1-to-mni-warpcoef --out=mni-to-t1-warpcoef


##########################################################################
## Transform HO probabilistic maps to T1 space
echo Transform atlas probmaps

# Select the needed ones only
fslroi "${FSLDIR}"/data/atlases/HarvardOxford/HarvardOxford-sub-prob-1mm \
    lh.HarvardOxford-sub-prob-hipp 8 1
fslroi "${FSLDIR}"/data/atlases/HarvardOxford/HarvardOxford-sub-prob-1mm \
    rh.HarvardOxford-sub-prob-hipp 18 1

# Split the atlas hippocampus into anterior and posterior segments following 
#
# Woolard AA, Heckers S. Anatomical and functional correlates of human hippocampal 
# volume asymmetry. Psychiatry Res. 2012 Jan 30;201(1):48-53. 
# doi: 10.1016/j.pscychresns.2011.07.016. PMID: 22285719; PMCID: PMC3289761.
# https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3289761/
#
# This is simply a coronal cut at y >= -20 mm, or j >= 106 in FSL 1mm atlas image
for h in lh rh; do
    fslmaths \
        ${h}.HarvardOxford-sub-prob-hipp \
        -roi 0 -1 106 100 0 -1 0 -1 \
        -thr ${pthresh} \
        -bin \
        ${h}a.HOhipp-mask
    fslmaths \
        ${h}.HarvardOxford-sub-prob-hipp \
        -roi 0 -1 105 -100 0 -1 0 -1 \
        -thr ${pthresh} \
        -bin \
        ${h}p.HOhipp-mask
done

# Warp
for h in lha lhp rha rhp; do
    applywarp \
        --in=${h}.HOhipp-mask \
        --ref=t1 \
        --warp=mni-to-t1-warpcoef \
        --interp=nn \
        --out=${h}.HOhipp-mask-warp-lores
done


##########################################################################
## Resample atlas ROIs to T1 hi-res space
echo Resample to hi-res space
for h in lh rh; do
    for ap in a p; do
        flirt \
            -in ${h}${ap}.HOhipp-mask-warp-lores \
            -ref ${h}.hippoAmygLabels-T1.v21 \
            -usesqform \
            -applyxfm \
            -interp nearestneighbour \
            -out ${h}${ap}.HOhipp-mask-warp
    done
done


