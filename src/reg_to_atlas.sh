#!/usr/bin/env bash
#
# Register T1 nonlinearly to template with FNIRT

# Affine reg to atlas
flirt -in t1 -ref "${FSLDIR}"/data/standard/MNI152_T1_2mm -usesqform -out rt1 -omat t1_to_mni.mat

# Further nonlinear reg to atlas with default T1 params
fnirt --in=t1 --config=T1_2_MNI152_2mm --aff=t1_to_mni.mat --iout=wt1

# Warp T1 to atlas space
#applywarp --ref="${FSLDIR}"/data/standard/MNI152_T1_0.5mm --in=t1 --warp=t1_warpcoef --out=wt1

# Warp MNI and Harvard-Oxford atlas to subject space. Vol 8 is left hipp, 18 is right
invwarp --ref=t1 --warp=t1_warpcoef --out=mni_warpcoef
applywarp --in="${FSLDIR}"/data/atlases/HarvardOxford/HarvardOxford-sub-prob-1mm \
    --ref=t1 --out=wHarvardOxford-sub-prob-1mm --warp=mni_warpcoef --interp=trilinear
applywarp --in="${FSLDIR}"/data/standard/MNI152_T1_1mm \
    --ref=t1 --out=wMNI152_T1_1mm --warp=mni_warpcoef

#fsleyes "${FSLDIR}"/data/standard/MNI152_T1_2mm t1 rt1 wt1
