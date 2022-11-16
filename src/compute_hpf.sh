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
    for ap in a p; do
        fslmaths ${h}.t1 -mas ${h}${ap}.HOhipp-mask-warp -thr ${tthr} -bin ${h}${ap}.hipp-tissue-mask-warp
    done
done

# Compute HPF as ratio of non-CSF voxels to all voxels in the t1 hi-res space
# atlas hippocampus mask
echo HPF computation
for h in lh rh; do
    for ap in a p; do
        num=$(fslstats ${h}${ap}.hipp-tissue-mask-warp -V | cut -f 2 -d ' ')
        denom=$(fslstats ${h}${ap}.HOhipp-mask-warp -V | cut -f 2 -d ' ')
        eval hpf_tissue_${h}${ap}_warp=$(echo "scale=2; 100 * ${num} / ${denom}" | bc)
    done
done

# Create output csvs
cat > hippocampus_hpf.csv <<HERE
Hemisphere,AP,HPF
left,anterior,${hpf_tissue_lha_warp}
left,posterior,${hpf_tissue_lhp_warp}
right,anterior,${hpf_tissue_rha_warp}
right,posterior,${hpf_tissue_rhp_warp}
HERE
