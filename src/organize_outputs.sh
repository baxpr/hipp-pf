#!/usr/bin/env bash

cd "${out_dir}"

# T1
#   wt1-affine.nii.gz            T1 affine transformed to atlas space
#   t1-to-mni-affine.mat         FSL format affine transformation matrix
#   mni-to-t1-affine.mat         Affine trans mtx from atlas to subject
#   wt1-warp.nii.gz              T1 warped to atlas space
#   t1-to-mni-warpcoef.nii.gz    FSL format deformation field
#   t1_to_MNI152_T1_2mm.log      Registration log
#   mni-to-t1-warpcoef.nii.gz    Def field from atlas to subject
mkdir T1
mv \
    wt1-affine.nii.gz \
    t1-to-mni-affine.mat \
    mni-to-t1-affine.mat \
    wt1-warp.nii.gz \
    t1-to-mni-warpcoef.nii.gz \
    t1_to_MNI152_T1_2mm.log \
    mni-to-t1-warpcoef.nii.gz \
    T1

# HO_HIPP
#   lh.HOhipp-mask-warp.nii.gz     HO hipp thresholded masks in subject space
#   rh.HOhipp-mask-warp.nii.gz
#   lh.HOhipp-mask-affine.nii.gz
#   rh.HOhipp-mask-affine.nii.gz
mkdir HO_HIPP
mv \
    lh.HOhipp-mask-warp.nii.gz \
    rh.HOhipp-mask-warp.nii.gz \
    lh.HOhipp-mask-affine.nii.gz \
    rh.HOhipp-mask-affine.nii.gz \
    HO_HIPP

# SUBJ_HIPP
#   lh.hipp-mask.nii.gz   Subject hippocampus
#   rh.hipp-mask.nii.gz
mkdir SUBJ_HIPP
mv \
    lh.hipp-mask.nii.gz \
    rh.hipp-mask.nii.gz \
    SUBJ_HIPP

# SUBJ_HIPP_MASKED
#   lh.hipp-HOmask-warp.nii.gz   HO-masked subject hippocampus
#   rh.hipp-HOmask-warp.nii.gz
#   lh.hipp-HOmask-affine.nii.gz
#   rh.hipp-HOmask-affine.nii.gz
SUBJ_HIPP_MASKED
mv \
    lh.hipp-HOmask-warp.nii.gz \
    rh.hipp-HOmask-warp.nii.gz \
    lh.hipp-HOmask-affine.nii.gz \
    rh.hipp-HOmask-affine.nii.gz \
    SUBJ_HIPP_MASKED
    
# T1_HIRES
#   lh.t1                     T1 resampled to the hi-res FOVs
#   rh.t1
mkdir T1_HIRES
mv \
    lh.t1.nii.gz \
    rh.t1.nii.gz \
    T1_HIRES

# SUBJ_HIPP_GM
#   lh.hipp-gm-warp.nii.gz    Gray matter masks within the HO-masked hippocampus
#   rh.hipp-gm-warp.nii.gz
#   lh.hipp-gm-affine.nii.gz
#   rh.hipp-gm-affine.nii.gz
mkdir SUBJ_HIPP_GM
mv \
    lh.hipp-gm-warp.nii.gz \
    rh.hipp-gm-warp.nii.gz \
    lh.hipp-gm-affine.nii.gz \
    rh.hipp-gm-affine.nii.gz \
    SUBJ_HIPP_GM

