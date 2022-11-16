#!/usr/bin/env bash

mkdir WARP
mv \
    t1_to_MNI152_T1_2mm.log \
    mni-to-t1-warpcoef.nii.gz \
    t1-to-mni-warpcoef.nii.gz \
    wt1-warp.nii.gz \
    WARP

mkdir ATLAS_MASKS
mv ?h?.HOhipp-mask-warp.nii.gz ATLAS_MASKS

mkdir PARENCHYMA_MASKS
mv ?h?.hipp-tissue-mask-warp.nii.gz PARENCHYMA_MASKS

# T1_HIRES
mkdir T1_HIRES
mv ?h.t1.nii.gz T1_HIRES

# STATS
mkdir STATS
mv hippocampus_hpf.csv STATS
