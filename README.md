# Hippocampus parenchymal fraction

A review of the general approach is Ardekani 2019. This FSL-based pipeline uses an existing Freesurfer hippocampal segmentation (e.g. from https://github.com/baxpr/freesurfer720) to identify hippocampal tissue.


## Procedure

- Initial 12-parameter affine registration of T1 image to MNI atlas. The freesurfer brainmask in subject space and the MNI brainmask in atlas space, both dilated, are used to improve accuracy.

- Additional nonlinear registration (warp) to the atlas following default FNIRT 'T1_2_MNI152_2mm' schedule file.

- Transform the Harvard-Oxford subcortical probabilistic atlas to the native T1 space and threshold the hippocampus maps at the specified level (default of 25%) to obtain an atlas hippocampus mask in the native space.

- Use the 1st percentile of intensity in the Freesurfer segmented hippocampus regions to obtain a threshold for tissue vs CSF.

- The reported hippocampal parenchymal fraction is the percentage of voxels in the native space atlas ROI that are at or above the tissue intensity threshold.

- HPF is reported for both the atlas regions obtained by the affine transform, and those obtained by the nonlinear warp transform.


## References

Ardekani BA, Hadid SA, Blessing E, Bachman AH. Sexual Dimorphism and Hemispheric Asymmetry of Hippocampal Volumetric Integrity in Normal Aging and Alzheimer Disease. AJNR Am J Neuroradiol. 2019 Feb;40(2):276-282. doi: 10.3174/ajnr.A5943. Epub 2019 Jan 17. PMID: 30655257; PMCID: PMC7028613.
https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7028613/
