#!/usr/bin/env bash
#
# Register T1 nonlinearly to template with FNIRT

flirt -in t1 -ref "${FSLDIR}"/data/standard/MNI152_T1_2mm -usesqform -out rt1 -omat t1_to_mni.mat

#fsleyes "${FSLDIR}"/data/standard/MNI152_T1_2mm t1 rt1 

fnirt --in=t1 --config=T1_2_MNI152_2mm --aff=t1_to_mni.mat
