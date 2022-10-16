#!/usr/bin/env bash

cd "${out_dir}"

# Inputs - copy from input location, reorienting T1 and converting mgz
#   t1.nii.gz                           Subject T1
#   lh.hippoAmygLabels-T1.v21.mgz       Freesurfer hippocampal module labels
#   rh.hippoAmygLabels-T1.v21.mgz
#   hipposubfields.lh.T1.v21.stats      FS hippocampal volumes
#   hipposubfields.rh.T1.v21.stats
fslreorient2std "${t1_niigz}" t1
cp "${fs_subjdir}"/stats/hipposubfields.?h.T1.v21.stats .
for h in lh rh; do
    mri_convert "${fs_subjdir}/mri/${h}.hippoAmygLabels-T1.v21.mgz" \
        ${h}.hippoAmygLabels-T1.v21.nii.gz
done
mri_convert "${fs_subjdir}/mri/brainmask.mgz" brainmask.nii.gz
