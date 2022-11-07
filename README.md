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


## Misc info

Hippocampal parenchymal fraction
https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7028613/

Registration algo: https://www.biorxiv.org/content/10.1101/306811v1.full
Software: https://www.nitrc.org/projects/art (KAIBA)

Refs that compare vs other methods:

22 Ardekani 2016 Accuracy 97% vs 89% for FS in classifying early AD
Analysis of the MIRIAD Data Shows Sex Differences in Hippocampal Atrophy Progression 
https://pubmed.ncbi.nlm.nih.gov/26836168/

23 Goff 2018 Successful detection of volume change in FEP vs FS; better test-retest in controls
Association of Hippocampal Atrophy With Duration of Untreated Psychosis and Molecular 
Biomarkers During Initial Antipsychotic Treatment of First-Episode Psychosis
https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5875378/

25 Bruno 2016 Better predictor of future decline than volume
Hippocampal volume and integrity as predictors of cognitive decline in intact elderly
https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4929020/


Reference, data set, metric of comparison, result

Bruno 2016, Bruno 2016, SPM volumetry, p=0.0003 vs p=0.07
Ardekani 2016, MIRIAD, FS5, Cohen D 3.4 vs 3.1, 2.8 vs 1.2
Goff 2018, Goff 2018, FS6 longitudinal, p=0.001 vs p=0.10
Goff 2018, Maclaren 2014, FS6 longitudinal, CoV 0.4% vs 1.0%


Maclaren J, Han Z, Vos SB, Fischbein N, Bammer R. Reliability of brain volume measurements: a test- retest dataset. Scientific data. 2014;1:140037.
