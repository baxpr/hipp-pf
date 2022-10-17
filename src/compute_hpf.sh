#!/usr/bin/env bash
#
# Hippocampal parenchymal fraction
# https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7028613/
# Ardekani BA, Hadid SA, Blessing E, Bachman AH. Sexual Dimorphism and Hemispheric Asymmetry of Hippocampal Volumetric Integrity in Normal Aging and Alzheimer Disease. AJNR Am J Neuroradiol. 2019 Feb;40(2):276-282. doi: 10.3174/ajnr.A5943. Epub 2019 Jan 17. PMID: 30655257; PMCID: PMC7028613.

# Identify a tissue intensity threshold - a low percentile (prc) of the
# intensity values in the subject hippocampus.
#   lh.t1                     T1 resampled to the hi-res FOVs
#   rh.t1
echo Tissue threshold
prc=1
for h in lh rh; do
    flirt -in t1 -ref ${h}.hippoAmygLabels-T1.v21 -usesqform -applyxfm -out ${h}.t1
done
tthr_lh=$(fslstats lh.t1 -k lh.hipp-mask -P ${prc})
tthr_rh=$(fslstats rh.t1 -k rh.hipp-mask -P ${prc})
tthr=$(echo "scale=5; (${tthr_lh}+${tthr_rh})/2" | bc)

# Mask the atlas hippocampus by tissue threshold to identify non-CSF
for h in lh rh; do
    for w in affine warp haffine; do
        fslmaths ${h}.t1 -mas ${h}.HOhipp-mask-${w} -thr ${tthr} -bin ${h}.hipp-tissue-mask-${w}
    done
done

# Mask the Freesurfer seg by atlas hippocampus to identify gray matter
for h in lh rh; do
    for w in affine warp haffine; do
        fslmaths ${h}.hipp-mask -mas ${h}.HOhipp-mask-${w} -bin ${h}.hipp-fsseg-mask-${w}
    done
done

# Compute HPF as ratio of non-CSF voxels to all voxels in the t1 hi-res space
# atlas hippocampus mask
echo HPF computation
for h in lh rh; do
    for w in affine warp haffine; do
        num=$(fslstats ${h}.hipp-tissue-mask-${w} -V | cut -f 2 -d ' ')
        denom=$(fslstats ${h}.HOhipp-mask-${w} -V | cut -f 2 -d ' ')
        eval hpf_tissue_${h}_${w}=$(echo "scale=2; 100 * ${num} / ${denom}" | bc)
    done
done

# Compute HPF instead as Freesurfer-segmented gray matter within the atlas
# hippocampus mask
for h in lh rh; do
    for w in affine warp haffine; do
        num=$(fslstats ${h}.hipp-fsseg-mask-${w} -V | cut -f 2 -d ' ')
        denom=$(fslstats ${h}.HOhipp-mask-${w} -V | cut -f 2 -d ' ')
        eval hpf_fsseg_${h}_${w}=$(echo "scale=2; 100 * ${num} / ${denom}" | bc)
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

# Create output csvs
cat > hippocampus_hpf.csv <<HERE
Hemisphere,Transform,HPF_Tissue,HPF_FSseg
left,brain_affine,${hpf_tissue_lh_affine},${hpf_fsseg_lh_affine}
right,brain_affine,${hpf_tissue_rh_affine},${hpf_fsseg_rh_affine}
left,brain_warp,${hpf_tissue_lh_warp},${hpf_fsseg_lh_warp}
right,brain_warp,${hpf_tissue_rh_warp},${hpf_fsseg_rh_warp}
left,hippamyg_affine,${hpf_tissue_lh_haffine},${hpf_fsseg_lh_haffine}
right,hippamyg_affine,${hpf_tissue_rh_haffine},${hpf_fsseg_rh_haffine}
HERE

cat > hippocampus_vol.csv <<HERE
Hemisphere,Whole_hippocampal_body,Whole_hippocampal_head
left,${whb_lh},${whh_lh}
right,${whb_rh},${whh_rh}
HERE
