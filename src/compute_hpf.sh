#!/usr/bin/env bash
#
# Hippocampal parenchymal fraction
# https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7028613/
# Ardekani BA, Hadid SA, Blessing E, Bachman AH. Sexual Dimorphism and Hemispheric Asymmetry of Hippocampal Volumetric Integrity in Normal Aging and Alzheimer Disease. AJNR Am J Neuroradiol. 2019 Feb;40(2):276-282. doi: 10.3174/ajnr.A5943. Epub 2019 Jan 17. PMID: 30655257; PMCID: PMC7028613.

# Work in the output dir
cd "${out_dir}"

prepfiles.sh

registrations.sh

transforms.sh

exit 0

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
echo Tissue threshold
prc=1
for h in lh rh; do
    flirt -in t1 -ref ${h}.hippoAmygLabels-T1.v21 -usesqform -applyxfm -out ${h}.t1
    for w in affine warp; do
        gthr=$(fslstats -K ${h}.hipp-HOmask-${w} ${h}.t1 -P ${prc})
        if [[ -z "${gthr}" ]]; then
            echo Failed to get ROI intensity values
            exit 1
        fi
        echo "    ${h} ${w} threshold: ${gthr}"
        fslmaths ${h}.t1 -thr ${gthr} -mas ${h}.HOhipp-mask-${w} -bin ${h}.hipp-gm-${w}
    done
done

# Compute atlas computation mask volumes and HPF
echo HPF computation
for h in lh rh; do
    for w in affine warp; do
        vstr=$(fslstats ${h}.HOhipp-mask-${w} -V)
        varr=(${vstr// / })
        vol_HOhipp=${varr[1]}
        
        vstr=$(fslstats ${h}.hipp-gm-${w} -V)
        varr=(${vstr// / })
        vol_hippgm=${varr[1]}

        eval hpf_${h}_${w}=$(echo "scale=2; 100 * ${vol_hippgm} / ${vol_HOhipp}" | bc)
    done
done

# Snag some volume measurements from FS for convenience
for h in lh rh; do
    vstr=$(grep Whole_hippocampal_body hipposubfields.${h}.T1.v21.stats)
    varr=(${vstr// / })
    eval whb_${h}=${varr[3]}

    vstr=$(grep Whole_hippocampal_head hipposubfields.${h}.T1.v21.stats)
    varr=(${vstr// / })
    eval whh_${h}=${varr[3]}
done

# Create output csv
#   hippocampus_hpf.csv    HPF values and FS vols in CSV format
cat > hippocampus_hpf.csv <<HERE
Hemisphere,HPF_Affine,HPF_Warp,Whole_hippocampal_body,Whole_hippocampal_head
left,${hpf_lh_affine},${hpf_lh_warp},${whb_lh},${whh_lh}
right,${hpf_rh_affine},${hpf_rh_warp},${whb_rh},${whh_rh}
HERE

exit 0


# FIXME add back the hippo-specific and try on small-hipp test case
########################################################################
# scritch-scratch for hippocampus-specific affine transforms below here

# Subject hippo-amyg registration mask from FS
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

# Atlas hipp-amyg registration mask from HO
HO="${FSLDIR}/data/atlases/HarvardOxford/HarvardOxford-sub-prob-1mm"
fslroi "${HO}" lh.HO-hipp 8 1
fslroi "${HO}" lh.HO-amyg 9 1
fslroi "${HO}" rh.HO-hipp 18 1
fslroi "${HO}" rh.HO-amyg 19 1
fslmaths lh.HO-hipp -add lh.HO-amyg -thr 0 -bin lh.HOhippamyg-regmask
fslmaths rh.HO-hipp -add rh.HO-amyg -thr 0 -bin rh.HOhippamyg-regmask
rm {lh,rh}.HO-{hipp,amyg}.nii.gz

# Hippocampus-specific affine registrations
for h in lh rh; do
    flirt \
        -in t1 \
        -ref "${FSLDIR}"/data/standard/MNI152_T1_1mm \
        -inweight ${h}.hippamyg-regmask \
        -refweight ${h}.HOhippamyg-regmask \
        -init t1-to-mni-affine.mat \
        -searchrx -10 10 -searchry -10 10 -searchrz -10 10 \
        -out ${h}.wt1-haffine \
        -omat ${h}.t1-to-mni-haffine.mat
done

# Transform the atlas HO prob maps back to subject space
for h in lh rh; do
    convert_xfm -omat ${h}.mni-to-t1-haffine.mat -inverse ${h}.t1-to-mni-haffine.mat
done
# FIXME we are here. Start with HOsub, inverse transform, resample to hires, threshold at mthr


# Hipp-specific affine transform of HO to subject space
for h in lh rh; do
    convert_xfm -omat mni-to-t1-${h}-haffine.mat -inverse t1-to-mni-${h}-haffine.mat
    flirt -in "${FSLDIR}"/data/atlases/HarvardOxford/HarvardOxford-sub-prob-1mm -ref t1 \
        -out HarvardOxford-sub-prob-1mm-${h}-haffine -init mni-to-t1-${h}-haffine.mat -applyxfm 
done

flirt -in HarvardOxford-sub-prob-1mm-${h}-haffine -ref ${h}.hippoAmygLabels-T1.v21 \
    -out ${h}.HarvardOxford-sub-prob-1mm-${h}-haffine -usesqform -applyxfm

fslroi ${h}.HarvardOxford-sub-prob-1mm-${h}-haffine ${h}.HarvardOxford-hipp-${h}-haffine ${v} 1
fslmaths ${h}.HarvardOxford-hipp-${h}-haffine -thr ${pthresh} -bin ${h}.HarvardOxford-hipp-${h}-haffine-p${pthresh}

fslmaths ${h}.hippo -mas ${h}.HarvardOxford-hipp-${h}-haffine-p${pthresh} -bin ${h}.hippo-masked-${h}-haffine

gthr=$(fslstats -K ${h}.hippo-masked-${h}-haffine ${h}.t1 -P ${prc})
fslmaths ${h}.t1 -thr ${gthr} -mas ${h}.HarvardOxford-hipp-${h}-haffine-p${pthresh} \
    -bin ${h}.fullhipp-masked-${h}-haffine

vol0str=$(fslstats ${h}.HarvardOxford-hipp-${h}-haffine-p${pthresh} -V)
vol0arr=(${vol0str// / })
vol0=${vol0arr[1]}

vol1str=$(fslstats ${h}.fullhipp-masked-${h}-haffine -V)
vol1arr=(${vol1str// / })
vol1=${vol1arr[1]}

hpf=$(echo "scale=2; 100 * ${vol1} / ${vol0}" | bc)

echo "haffine ${h} ${hpf}"
