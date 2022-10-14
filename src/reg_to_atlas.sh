#!/usr/bin/env bash
#
# Hippocampal parenchymal fraction
# https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7028613/
# Ardekani BA, Hadid SA, Blessing E, Bachman AH. Sexual Dimorphism and Hemispheric Asymmetry of Hippocampal Volumetric Integrity in Normal Aging and Alzheimer Disease. AJNR Am J Neuroradiol. 2019 Feb;40(2):276-282. doi: 10.3174/ajnr.A5943. Epub 2019 Jan 17. PMID: 30655257; PMCID: PMC7028613.

# Inputs
#   t1.nii.gz                           Subject T1
#   lh.hippoAmygLabels-T1.v21.mgz       Freesurfer hippocampal module labels
#   rh.hippoAmygLabels-T1.v21.mgz

# Affine registration of T1 to atlas
#   wt1-affine.nii.gz       T1 affine transformed to atlas space
#   t1-to-mni-affine.mat    FSL format affine transformation matrix
flirt \
    -in t1 \
    -ref "${FSLDIR}"/data/standard/MNI152_T1_2mm \
    -refweight "${FSLDIR}"/data/standard/MNI152_T1_2mm_brain_mask_dil \
    -usesqform \
    -out wt1-affine \
    -omat t1-to-mni-affine.mat

# Further nonlinear registration to atlas with default T1 registration algo
#   wt1-warp.nii.gz              T1 warped to atlas space
#   t1-to-mni-warpcoef.nii.gz    FSL format deformation field
#   t1_to_MNI152_T1_2mm.log      Registration log
fnirt \
    --in=t1 \
    --config=T1_2_MNI152_2mm \
    --aff=t1-to-mni-affine.mat \
    --refmask "${FSLDIR}"/data/standard/MNI152_T1_2mm_brain_mask_dil \
    --iout=wt1-warp \
    --cout=t1-to-mni-warpcoef

# Affine transform of Harvard-Oxford subcortical probabalistic atlas to 
# subject space to get generic ROIs
#   mni-to-t1-affine.mat         Affine trans mtx from atlas to subject
#   HOsub-affine.nii.gz          HO subc atlas in subject space (affine)
HO="${FSLDIR}"/data/atlases/HarvardOxford/HarvardOxford-sub-prob-1mm.nii.gz
convert_xfm -omat mni-to-t1-affine.mat -inverse t1-to-mni-affine.mat
flirt \
    -in "${HO}" \
    -ref t1 \
    -init mni-to-t1-affine.mat \
    -applyxfm \
    -out HOsub-affine 

# Same but full nonlinear warp
#   mni-to-t1-warpcoef.nii.gz    Def field from atlas to subject
#   HOsub-warp.nii.gz            HO subc atlas in subject space (warped)
invwarp --ref=t1 --warp=t1-to-mni-warpcoef --out=mni-to-t1-warpcoef
applywarp \
    --in="${HO}" \
    --ref=t1 \
    --warp=mni-to-t1-warpcoef \
    --interp=trilinear \
    --out=HOsub-warp

# Resample subject space HO images to the FS hi-res hippocampal FOV
#   lh.HOsub-warp.nii.gz     HO subc atlases in hi-res FOVs
#   rh.HOsub-warp.nii.gz
#   lh.HOsub-affine.nii.gz
#   rh.HOsub-affine.nii.gz
for h in lh rh; do
    mri_convert ${h}.hippoAmygLabels-T1.v21.mgz ${h}.hippoAmygLabels-T1.v21.nii.gz
    for w in affine warp; do
        flirt \
            -in HOsub-${w} \
            -ref ${h}.hippoAmygLabels-T1.v21 \
            -usesqform \
            -applyxfm \
            -out ${h}.HOsub-${w}
    done
done

# Get atlas hippocampus masks into hi-res subject space. These are the total
# volume considered when computing HPF. Volumes 8/18 are L/R hippocampus.
# mthr is the probability to threshold at to create the masks.
#   lh.HOhipp-warp.nii.gz          HO hipp prob maps in subject space
#   rh.HOhipp-warp.nii.gz
#   lh.HOhipp-affine.nii.gz
#   rh.HOhipp-affine.nii.gz
#   lh.HOhipp-mask-warp.nii.gz     HO hipp thresholded masks in subject space
#   rh.HOhipp-mask-warp.nii.gz
#   lh.HOhipp-mask-affine.nii.gz
#   rh.HOhipp-mask-affine.nii.gz
mthr=25
for h in lh rh; do
    if [[ ${h} == lh ]]; then v=8; fi
    if [[ ${h} == rh ]]; then v=18; fi
    for w in affine warp; do
        fslroi ${h}.HOsub-${w} ${h}.HOhipp-${w} ${v} 1
        fslmaths ${h}.HOhipp-${w} -thr ${mthr} -bin ${h}.HOhipp-mask-${w}
    done
done

# Get subject hippocampus from FS, in hi-res subject space. Values >1000
# are the amygdala
#   lh.hipp-mask.nii.gz   Subject hippocampus
#   rh.hipp-mask.nii.gz
for h in lh rh; do
    fslmaths ${h}.hippoAmygLabels-T1.v21 -uthr 1000 -bin ${h}.hipp-mask
done

# Mask subject hippocampus by atlas mask. HPF is computed only within
# the atlas mask.
#   lh.hipp-HOmask-warp.nii.gz   HO-masked subject hippocampus
#   rh.hipp-HOmask-warp.nii.gz
#   lh.hipp-HOmask-affine.nii.gz
#   rh.hipp-HOmask-affine.nii.gz
for h in lh rh; do
    for w in affine warp; do
        fslmaths ${h}.hipp-mask -mas ${h}.HOhipp-mask-${w} -bin ${h}.hipp-HOmask-${w}
    done
done

# Identify a gray matter intensity threshold - a low percentile (prc) of the
# intensity values in the HO-masked subject hippocampus.
#   lh.t1                     T1 resampled to the hi-res FOVs
#   rh.t1
#   lh.hipp-gm-warp.nii.gz    Gray matter masks within the HO-masked hippocampus
#   rh.hipp-gm-warp.nii.gz
#   lh.hipp-gm-affine.nii.gz
#   rh.hipp-gm-affine.nii.gz
prc=1
for h in lh rh; do
    flirt -in t1 -ref ${h}.hippoAmygLabels-T1.v21  -usesqform -applyxfm -out ${h}.t1
    for w in affine warp; do
        gthr=$(fslstats -K ${h}.hipp-HOmask-${w} ${h}.t1 -P ${prc})
        fslmaths ${h}.t1 -thr ${gthr} -mas ${h}.HOhipp-mask-${w} -bin ${h}.hipp-gm-${w}
    done
done

# Compute atlas computation mask volumes and HPF
for h in lh rh; do
    for w in affine warp; do
        vstr=$(fslstats ${h}.HOhipp-mask-${w} -V)
        varr=(${vstr// / })
        vol_HOhipp=${varr[1]}
        
        vstr=$(fslstats ${h}.hipp-gm-${w} -V)
        varr=(${vstr// / })
        vol_hippgm=${varr[1]}

        hpf=$(echo "scale=2; 100 * ${vol_hippgm} / ${vol_HOhipp}" | bc)

        echo "${w} ${h} ${hpf}"
    done
done


exit 0


#################################################

# Hippocampus-specific affine reg
HO="${FSLDIR}/data/atlases/HarvardOxford/HarvardOxford-sub-prob-2mm"
fslroi "${HO}" lh.HO-hipp 8 1
fslroi "${HO}" lh.HO-amyg 9 1
fslroi "${HO}" rh.HO-hipp 18 1
fslroi "${HO}" rh.HO-amyg 19 1
fslmaths lh.HO-hipp -add lh.HO-amyg -thr 10 -bin lh.HO-hippamyg
fslmaths rh.HO-hipp -add rh.HO-amyg -thr 10 -bin rh.HO-hippamyg

for h in lh rh; do
    flirt -in t1 -ref "${FSLDIR}"/data/standard/MNI152_T1_2mm -init t1-to-mni-affine.mat \
        -out wt1-${h}-haffine -omat t1-to-mni-${h}-haffine.mat -refweight ${h}.HO-hippamyg
done


# Hipp-specific affine transform of HO to subject space
for h in lh rh; do
    convert_xfm -omat mni-to-t1-${h}-haffine.mat -inverse t1-to-mni-${h}-haffine.mat
    flirt -in "${FSLDIR}"/data/atlases/HarvardOxford/HarvardOxford-sub-prob-1mm -ref t1 \
        -out HarvardOxford-sub-prob-1mm-${h}-haffine -init mni-to-t1-${h}-haffine.mat -applyxfm 
done

flirt -in HarvardOxford-sub-prob-1mm-${h}-haffine -ref ${h}.hippoAmygLabels-T1.v21 \
    -out ${h}.HarvardOxford-sub-prob-1mm-${h}-haffine -usesqform -applyxfm

fslroi ${h}.HarvardOxford-sub-prob-1mm-${h}-haffine ${h}.HarvardOxford-hipp-${h}-haffine ${v} 1
fslmaths ${h}.HarvardOxford-hipp-${h}-haffine -thr ${mthr} -bin ${h}.HarvardOxford-hipp-${h}-haffine-p${mthr}

fslmaths ${h}.hippo -mas ${h}.HarvardOxford-hipp-${h}-haffine-p${mthr} -bin ${h}.hippo-masked-${h}-haffine

gthr=$(fslstats -K ${h}.hippo-masked-${h}-haffine ${h}.t1 -P ${prc})
fslmaths ${h}.t1 -thr ${gthr} -mas ${h}.HarvardOxford-hipp-${h}-haffine-p${mthr} \
    -bin ${h}.fullhipp-masked-${h}-haffine

vol0str=$(fslstats ${h}.HarvardOxford-hipp-${h}-haffine-p${mthr} -V)
vol0arr=(${vol0str// / })
vol0=${vol0arr[1]}

vol1str=$(fslstats ${h}.fullhipp-masked-${h}-haffine -V)
vol1arr=(${vol1str// / })
vol1=${vol1arr[1]}

hpf=$(echo "scale=2; 100 * ${vol1} / ${vol0}" | bc)

echo "haffine ${h} ${hpf}"
