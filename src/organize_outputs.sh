#!/usr/bin/env bash

# AFFINE
# t1-to-mni-affine.mat                 Affine transform subject<>atlas
# mni-to-t1-affine.mat
# wt1-affine.nii.gz                    Low res T1 in atlas space
# lh.HOhipp-mask-affine.nii.gz         Atlas mask transformed to subject space
# rh.HOhipp-mask-affine.nii.gz
# lh.hipp-fsseg-mask-affine.nii.gz     Atlas mask masked by FS hippocampus
# rh.hipp-fsseg-mask-affine.nii.gz
# lh.hipp-tissue-mask-affine.nii.gz    Atlas mask masked by tissue intensity threshold
# rh.hipp-tissue-mask-affine.nii.gz
mkdir AFFINE
mv \
    t1-to-mni-affine.mat \
    mni-to-t1-affine.mat \
    wt1-affine.nii.gz \
    lh.HOhipp-mask-affine.nii.gz \
    rh.HOhipp-mask-affine.nii.gz \
    lh.hipp-fsseg-mask-affine.nii.gz \
    rh.hipp-fsseg-mask-affine.nii.gz \
    lh.hipp-tissue-mask-affine.nii.gz \
    rh.hipp-tissue-mask-affine.nii.gz \
    AFFINE

# WARP - filenames as for AFFINE
mkdir WARP
mv \
    t1_to_MNI152_T1_2mm.log \
    mni-to-t1-warpcoef.nii.gz \
    t1-to-mni-warpcoef.nii.gz \
    wt1-warp.nii.gz \
    lh.HOhipp-mask-warp.nii.gz \
    rh.HOhipp-mask-warp.nii.gz \
    lh.hipp-fsseg-mask-warp.nii.gz \
    rh.hipp-fsseg-mask-warp.nii.gz \
    lh.hipp-tissue-mask-warp.nii.gz \
    rh.hipp-tissue-mask-warp.nii.gz \
    WARP

# HAFFINE - as above
mkdir HAFFINE
mv \
    lh.t1-to-mni-haffine.mat \
    rh.t1-to-mni-haffine.mat \
    lh.mni-to-t1-haffine.mat \
    rh.mni-to-t1-haffine.mat \
    lh.wt1-haffine.nii.gz \
    rh.wt1-haffine.nii.gz \
    lh.HOhipp-mask-haffine.nii.gz \
    rh.HOhipp-mask-haffine.nii.gz \
    lh.hipp-fsseg-mask-haffine.nii.gz \
    rh.hipp-fsseg-mask-haffine.nii.gz \
    lh.hipp-tissue-mask-haffine.nii.gz \
    rh.hipp-tissue-mask-haffine.nii.gz \
    HAFFINE

# T1_HIRES
# T1 resampled to the hi-res partial FOVs
mkdir T1_HIRES
mv \
    lh.t1.nii.gz \
    rh.t1.nii.gz \
    T1_HIRES

