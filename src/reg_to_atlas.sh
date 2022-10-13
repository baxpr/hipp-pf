#!/usr/bin/env bash
#
# Register T1 nonlinearly to template with FNIRT

# Affine reg to atlas
flirt -in t1 -ref "${FSLDIR}"/data/standard/MNI152_T1_2mm -usesqform \
    -out wt1-affine -omat t1-to-mni-affine.mat

# Further nonlinear reg to atlas with default T1 params
# Warp field is in the ref space
fnirt --in=t1 --config=T1_2_MNI152_2mm --aff=t1-to-mni-affine.mat \
    --iout=wt1-warp --cout=t1-to-mni-warpcoef

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

# Warp Harvard-Oxford atlas to subject space.
invwarp --ref=t1 --warp=t1-to-mni-warpcoef --out=mni-to-t1-warpcoef
applywarp --in="${FSLDIR}"/data/atlases/HarvardOxford/HarvardOxford-sub-prob-1mm \
    --ref=t1 --out=HarvardOxford-sub-prob-1mm-warp \
    --warp=mni-to-t1-warpcoef --interp=trilinear

# Affine transform of HO to subject space
convert_xfm -omat mni-to-t1-affine.mat -inverse t1-to-mni-affine.mat
flirt -in "${FSLDIR}"/data/atlases/HarvardOxford/HarvardOxford-sub-prob-1mm \
    -ref t1 -out HarvardOxford-sub-prob-1mm-affine -init mni-to-t1-affine.mat -applyxfm 

# Hipp-specific affine transform of HO to subject space
for h in lh rh; do
    convert_xfm -omat mni-to-t1-${h}-haffine.mat -inverse t1-to-mni-${h}-haffine.mat
    flirt -in "${FSLDIR}"/data/atlases/HarvardOxford/HarvardOxford-sub-prob-1mm -ref t1 \
        -out HarvardOxford-sub-prob-1mm-${h}-haffine -init mni-to-t1-${h}-haffine.mat -applyxfm 
done

# Resample subject space HO images to the hi-res hippocampal FOV
for h in lh rh; do
    mri_convert ${h}.hippoAmygLabels-T1.v21.mgz ${h}.hippoAmygLabels-T1.v21.nii.gz
    flirt -in HarvardOxford-sub-prob-1mm-${h}-haffine -ref ${h}.hippoAmygLabels-T1.v21 \
        -out ${h}.HarvardOxford-sub-prob-1mm-${h}-haffine -usesqform -applyxfm
    for w in affine warp; do
        flirt -in HarvardOxford-sub-prob-1mm-${w} -ref ${h}.hippoAmygLabels-T1.v21 \
            -out ${h}.HarvardOxford-sub-prob-1mm-${w} -usesqform -applyxfm
    done
done

# Get HPF computation masks in hi res subject space. Vol 8 is left hipp, 18 is right
mthr=25
for h in lh rh; do
    if [[ ${h} == lh ]]; then v=8; fi
    if [[ ${h} == rh ]]; then v=18; fi
    fslroi ${h}.HarvardOxford-sub-prob-1mm-${h}-haffine ${h}.HarvardOxford-hipp-${h}-haffine ${v} 1
    fslmaths ${h}.HarvardOxford-hipp-${h}-haffine -thr ${mthr} -bin ${h}.HarvardOxford-hipp-${h}-haffine-p${mthr}
    for w in affine warp; do
        fslroi ${h}.HarvardOxford-sub-prob-1mm-${w} ${h}.HarvardOxford-hipp-${w} ${v} 1
        fslmaths ${h}.HarvardOxford-hipp-${w} -thr ${mthr} -bin ${h}.HarvardOxford-hipp-${w}-p${mthr}
    done
done

# Get subject hippocampus
for h in lh rh; do
    fslmaths ${h}.hippoAmygLabels-T1.v21 -uthr 1000 -bin ${h}.hippo
done

# Mask subject hippocampus by atlas
for h in lh rh; do
    fslmaths ${h}.hippo -mas ${h}.HarvardOxford-hipp-${h}-haffine-p${mthr} -bin ${h}.hippo-masked-${h}-haffine
    for w in affine warp; do
        fslmaths ${h}.hippo -mas ${h}.HarvardOxford-hipp-${w}-p${mthr} -bin ${h}.hippo-masked-${w}
    done
done

# GM threshold based on subject hipp prctile to create broad GM mask
prc=1
for h in lh rh; do
    flirt -in t1 -ref ${h}.hippoAmygLabels-T1.v21 -out ${h}.t1 -usesqform -applyxfm
    gthr=$(fslstats -K ${h}.hippo-masked-${h}-haffine ${h}.t1 -P ${prc})
    fslmaths ${h}.t1 -thr ${gthr} -mas ${h}.HarvardOxford-hipp-${h}-haffine-p${mthr} \
        -bin ${h}.fullhipp-masked-${h}-haffine
    for w in affine warp; do
        gthr=$(fslstats -K ${h}.hippo-masked-${w} ${h}.t1 -P ${prc})
        fslmaths ${h}.t1 -thr ${gthr} -mas ${h}.HarvardOxford-hipp-${w}-p${mthr} \
            -bin ${h}.fullhipp-masked-${w}
    done
done

# Compute atlas computation mask volumes and HPF
for h in lh rh; do
    vol0str=$(fslstats ${h}.HarvardOxford-hipp-${h}-haffine-p${mthr} -V)
    vol0arr=(${vol0str// / })
    vol0=${vol0arr[1]}
    
    vol1str=$(fslstats ${h}.fullhipp-masked-${h}-haffine -V)
    vol1arr=(${vol1str// / })
    vol1=${vol1arr[1]}

    hpf=$(echo "scale=2; 100 * ${vol1} / ${vol0}" | bc)

    echo "haffine ${h} ${hpf}"
    
    for w in affine warp; do
        vol0str=$(fslstats ${h}.HarvardOxford-hipp-${w}-p${mthr} -V)
        vol0arr=(${vol0str// / })
        vol0=${vol0arr[1]}
        
        vol1str=$(fslstats ${h}.fullhipp-masked-${w} -V)
        vol1arr=(${vol1str// / })
        vol1=${vol1arr[1]}

        hpf=$(echo "scale=2; 100 * ${vol1} / ${vol0}" | bc)

        echo "${w} ${h} ${hpf}"
    done
done
