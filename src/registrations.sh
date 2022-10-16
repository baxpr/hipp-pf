#!/usr/bin/env bash

cd "${out_dir}"

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

# Subject hippo-amyg registration mask from freesurfer to use as
# input mask for hippocampus-specific affine registration
#   lh.hippamyg-regmask.nii.gz   Subject hippocampus+amygdala, dilated
#   rh.hippamyg-regmask.nii.gz
echo Hippocampus-amygdala registration mask
for h in lh rh; do
    flirt \
        -in ${h}.hippoAmygLabels-T1.v21 \
        -ref t1 \
        -usesqform \
        -applyxfm \
        -interp nearestneighbour \
        -out ${h}.tmp
    fslmaths ${h}.tmp -bin -dilM -dilM ${h}.hippamyg-regmask
    rm tmp.nii.gz
done

# Atlas hipp-amyg registration mask from Harvard-Oxford to use as
# reference mask for hippocampus-specific registrations
#   lh.HOhippamyg-regmask.nii.gz   MNI space hippocampus+amygdala
#   rh.HOhippamyg-regmask.nii.gz
HOsub="${FSLDIR}/data/atlases/HarvardOxford/HarvardOxford-sub-prob-1mm"
fslroi "${HOsub}" lh.HO-hipp 8 1
fslroi "${HOsub}" lh.HO-amyg 9 1
fslroi "${HOsub}" rh.HO-hipp 18 1
fslroi "${HOsub}" rh.HO-amyg 19 1
fslmaths lh.HO-hipp -add lh.HO-amyg -thr 0 -bin lh.HOhippamyg-regmask
fslmaths rh.HO-hipp -add rh.HO-amyg -thr 0 -bin rh.HOhippamyg-regmask
rm {lh,rh}.HO-{hipp,amyg}.nii.gz

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

# Hippocampus-specific affine registrations per hemisphere. Use 1mm 
# reference geometry for better accuracy, and prevent rotational search
# because the initial alignment should already be pretty good.
for h in lh rh; do
    flirt \
        -in t1 \
        -ref "${FSLDIR}"/data/standard/MNI152_T1_1mm \
        -inweight ${h}.hippamyg-regmask \
        -refweight ${h}.HOhippamyg-regmask \
        -init t1-to-mni-affine.mat \
        -nosearch \
        -out ${h}.wt1-haffine \
        -omat ${h}.t1-to-mni-haffine.mat
done
