#!/usr/bin/env bash

##########################################################################
## Masks

# Freesurfer brain mask, dilated and resampled to t1 space, to use as
# input mask for whole-brain affine registration
echo Brain registration mask
fslmaths brainmask -bin -dilM -dilM brainmask_dil
flirt \
    -in brainmask_dil \
    -ref t1 \
    -usesqform \
    -applyxfm \
    -out brain-regmask

# Subject hippocampus from freesurfer, in hi-res subject space. Values >1000
# are the amygdala, so dropped here
#   lh.hipp-mask.nii.gz   Subject hippocampus
#   rh.hipp-mask.nii.gz
echo Hippocampus mask
for h in lh rh; do
    fslmaths ${h}.hippoAmygLabels-T1.v21 -uthr 1000 -bin ${h}.hipp-mask
done


##########################################################################
## Registrations

# Affine registration of T1 to atlas. Weight T1 by FS brainmask and 
# atlas by its dilated brain mask.
#   wt1-affine.nii.gz       T1 affine transformed to atlas space (low res, view only)
#   t1-to-mni-affine.mat    FSL format affine transformation matrix
echo Affine registration
flirt \
    -in t1 \
    -ref "${FSLDIR}"/data/standard/MNI152_T1_2mm \
    -inweight brain-regmask \
    -refweight "${FSLDIR}"/data/standard/MNI152_T1_2mm_brain_mask_dil \
    -usesqform \
    -out wt1-affine \
    -omat t1-to-mni-affine.mat

# Further nonlinear registration to atlas with default T1 registration algo
# (which includes the dilated brain mask already)
#   wt1-warp.nii.gz              T1 warped to atlas space (low res, view only)
#   t1-to-mni-warpcoef.nii.gz    FSL format deformation field
#   t1_to_MNI152_T1_2mm.log      Registration log
echo Nonlinear registration
fnirt \
    --in=t1 \
    --config=T1_2_MNI152_2mm \
    --aff=t1-to-mni-affine.mat \
    --iout=wt1-warp \
    --cout=t1-to-mni-warpcoef
