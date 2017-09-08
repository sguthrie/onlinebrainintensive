onlinebrainintensive
====================

Git Repo for my work in the Online Brain Intensive Class

Under GPL license

v0
[![DOI](https://zenodo.org/badge/102292127.svg)](https://zenodo.org/badge/latestdoi/102292127)

[TOC]

Working with MRI data
---------------------

## MRI data basics

From [Nipype Beginner's Guide](https://miykael.github.io/nipype-beginner-s-guide/neuroimaging.html)

The standard anatomical volume (1mm voxels) is 256x256x256 voxels

The scanner measures one plane (slice) of the brain after another (generally a horizontal plane). The resolution of the measured volume depends on the in-plane resolution, the number of slices/the thickness of the slices, and any possible gaps between them.

The quality of the MRI depends on:
> - The **resolution**
> - The **repetition time (TR)**: time required to scan one volume
> - The **acquisition time (TA)**: time required to scan one slice $TA = TR - (TR/n{slices})$
> - The **field of view (FOV)**: the extent of the slice (ex. 256mm x 256mm)

The raw data format output by MRI scanners varies with the type of scanner, and is often saved in [k-space](https://en.wikipedia.org/wiki/K-space_%28magnetic_resonance_imaging%29) format. Common formats are **DICOM** and **PAR/REC**. I think DICOM and PAR/REC are scanner-specific formats encoded in k-space format, but I'm not sure.

I think that the k-space formatted files are converted into **NIfTI** or **Analyze** formats. These contain an **image** and **header**. For **NIfTI** files (extension .nii-file) the image and header are in the same file. **Analyze**, which is older, produces 2 files (.img for the image and .hdr-file for the header)

 - The **image** is the data in a 3D matrix that contains a value for each voxel.
 - The **header** contains metadata
  - Voxel dimension
  - Voxel extend in each dimension
  - The number of measured time points
  - A transformation matrix that places the 3D matrix in the image in a 3D coordinate system
  - etc

#### sMRI data

> - High-resolution images used as reference images for
>  - corregistration
>  - normalization
>  - segmentation
>  - surface reconstruction
> - Voxel resolution ranges from 0.2-1.5mm depending on the magnetic field of the scanner (1.5T, 3T, or 7T)
> - Grey matter structures are dark
> - White matter structures are light

#### fMRI data
>
> Neural activity results in a characterized curve of blood oxygen level. First an initial dip in oxygen; then an increase in oxygen (peak reached after 4-6 seconds); an undershoot in oxygen levels (after 10s in figure); then eventual stabilization.
>
> - The signal is the Blood Oxygen Level Dependent (BOLD) response
> - Voxel resolution is 2-4mm depending on the magnetic field of the scanner
> - Grey matter structures are light
> - White matter structures are dark
>
> Types of experimental designs:
>
> - **event-related design:** Stimuli are administered for a short period. BOLD responses will be short and will manifest as peaks
> - **block design:** Multiple stimuli of similar nature are shone in a "block" or "phase" of 10-30s. The peaks will be elevated for a longer time, creating a plateau; thus the underlying activation increase should be easier to detect.
> - **resting-state design:** Absence of stimulation. Sometimes done to analyze functional connectivity of the brain.

#### dMRI data

> Done to obtain information about white matter connections. Measures the diffusion of water via mean diffusivity (MD), fractional anisotropy (FA), and Tractography.
>
> Includes
>
> - diffusion tensor imaging (DTI)
> - diffusion spectrum imaging (DSI)
> - diffusion weighted imaging (DWI)
> - diffusion functional MRI (DfMRI)

> It is a new field in MRI and has problems with its sensitivity to correctly detect fiber tracts and their underlying orientation. Standard DTI has almost no chance of reliably detecting kissing (touching) or crossing fiber tracts.
>
> High-angular-resolution diffusion imaging (HARDI) and Q-ball vector analyses were developed to account for this disadvantage.

------------------------------

## MRI Data Analysis Steps

Still from [Nipype Beginner's Guide](https://miykael.github.io/nipype-beginner-s-guide/neuroimaging.html)

1. Preprocessing: spatial and temporal preprocessing of the data to prepare it for the 1st and 2nd level inferential analysis
2. Model Specification and Estimation: specifying and estimating parameters of the statistical model
3. Statistical Inference: Making inferences about the estimated parameters using appropriate statistical methods

### Preprocessing

#### Slice Timing Correction (fMRI only)

 - Requires knowing the order of slice acquisition (top-down, bottom-up, or interleaved)

#### Motion Correction (fMRI only)

 - aka **Realignment**
 - Corrects for head movement. Aligns data to a reference time volume (usually the mean image of all timepoints, but can be the first or another time point)
 - Head movement has 6 parameters (translation along X, Y, and Z and rotation around X, Y, and Z)
 - Realignment uses an affine rigid body transformation to manipulate the data in these parameters.
 - A "good" subject will not translate over +/- 0.6mm and will not rotate over +/- 1 degrees (not sure, but seems to be good?)

#### Artifact Detection (fMRI only)

 - Identify and label images acquired during extreme rapid movement that should be excluded from further analysis
 - Check the translation and rotation graphs for sudden movement greater than 2 SD from the mean (or for movement greater than 1mm)

#### Corregistration

 - Aligns the functional image with the reference structural image.
 - Allows further transformations on the anatomical image, like normalization, to be directly applied to the functional one

#### Normalization

 - Used to compare the images of different subjects
 - Translates the images onto a common shape and size (maps to a reference-space)
 - Always includes a template and source images

> - Template image is the standard brain in reference-space. Can be a Talairach-, MNI-, or SPM-template, or another reference image.
> - Source image (normally a higher-resolution structural image) is used to calculate the transformation matrix, which is used for the rest of your images.

#### Smoothing

Used on both structural and functional data

 - Applies a filter to the image
 - Increases the signal to noise ratio (filter highest frequencies)
 - Makes the larger scale changes more apparent
 - Reduces spatial differences between subjects, so easier to compare
 - Lose resolution!
 - Can cause functionally different regions to combine - surface based analysis with smoothing on the surface may be better choice
 - Applies a 3D Gaussian kernel to the image; amount of smoothing is determined by its full width at half maximum (FWHM) parameter
 - If you're studying a small region, a large kernel might smooth the data too much; should be smaller than/equal to the activation you're trying to detect
 - Some authors suggest using 2x{Voxel dimensions} as a reasonable starting point

#### Segmentation (sMRI only)

 - Divides the brain into neurological sections according to a template specification
  - GM, WM, and CSF done with SPM's Segmentation
  - Segmenting into specific functional regions and their subregions done with FreeSurfer's recon-all
  - Can aid normalization, use specific segmentation as a mask, use segmentation as definition of ROI

### Model Specification and Estimation

To test a hypothesis, we need to specify a model that incorporates the hypothesis and accounts for the expected function of the BOLD signal, the movement during measurement, experiment specify parameters and other regressors and co-variants. This is usually represented by a Generalized Linear Model (**GLM**).

#### Making a GLM

Describes a response $y$ (ex: the BOLD response in a voxel), at the time points with data in terms of all of its contributing factors ($X\beta$) and error ($\epsilon$).

$$
y = X\beta + \epsilon
$$

 - $y$ (dependent variable)
 - $X$ (independent variable; predictor; experimental conditions, stimulus information, expected shape of BOLD response) These are stored in a design matrix
 - $\beta$ (parameters; regression coefficient/beta weights; quantifies how much each predictor independently influences the dependent variable)
 - $\epsilon$ (error; assumed to be normally distributed)


> **Caveats for the GLM approach:**
>
> - We need to take the time delay and the HRF (hemodynamic response function) shape of the BOLD response into account when creating the design matrix
> - We need to high pass filter the data and add time regressors of 1st, 2nd, ... order to correct for low-frequency drifts in the measured data (the low-frequency noise are caused by scanner drift and other non-experimental effects)
> - The high pass filter is established by setting up discrete cosine functions over the time period of data acquisition.
> - Each regressors in the model decreases the degrees of freedom in statistical tests

#### Estimating the Model

Applying the model on the time course of each and every voxel. SPM will create images every time an analysis is performed.

> - **Beta images:** images of estimated regression coefficients (parameter estimate). These contain information about the size of the effect of interest. A given voxel in each beta image will have value related to the size of effect for the explanatory variables.
> - **Error image (ResMS-image):** Residual sum of squares/variance image. Measurement of within-subject error at the 1st level or between-subject error at the 2nd level analysis. Used to produce spmT images (see below).
> - **con images (con-images):** Produced during contrast estimation from linearly combining beta images
> - **T images (spmT-images):** Produced during contrast estimation from combining the beta values of the con-images with error values of the ResMS-image to calculate the t-value at each voxel.

### Statistical inferences

**1st level analysis (within-subject analysis):** The data does not need to be normalized. The design matrix for this level controls for movement, respiration, heart beat, etc.

**2nd level analysis (between-subject analysis):** Requires normalization and transformation onto reference-space of subject specific data. Requires the contrasts of the 1st level analysis. The design matrix controls for age, gender, socio-economic parameters. Here we specify the group assignment of each subject.

#### Contrast Estimation (for both 1st and 2nd level analysis)

Specify how to weight the different regressors of your design matrix and combine them into one image. Essentially, how can you numerically weight what you are interested in such that it's on the same scale.

> Examples:
> faces (+1) vs resting (-1)
> session 1 (+1) vs session 2 (-1))

#### Thresholding

Specify the level of significance you test your data on. Correct for multiple comparison and specify the parameters of the result you are looking for.

> Examples:
>
> - FWE-correction: the family-wise error correction can correct for multiple comparisons
> - p-value
> - voxel extend: specify the minimum size of a significant cluster with the lowest number of voxels it needs to contain (ex 100)

------------------------------------

## Structure of data

According to the Brain Imaging Data Structure (BIDS), which relies on folder names.

The DICOM files are organized:
> dicomdir/
> > [timestamp]/
> > > .dcm files

The other files follow
> participants.tsv
> sub-01/
> > anat/
> > > .nii.gz
> >
> > func/
> > > .nii.gz
> > > .json
> >
> > dwi/
> > > .nii.gz
> > > .json
> > > .bval
> > > .bvec

## File extensions in openfmri/ds000221

###[FLAIR](https://en.wikipedia.org/wiki/Fluid-attenuated_inversion_recovery)

It's a pulse sequence used in MRI; can be 2D or 3D. Can be used to suppress CSF effects. Helpful for studying lacunar infarction, MS plaques, Subarachnoid heamorrhage, head trauma, and meningitis. The inversion time (TI) chooses which signal is nullified.

###[T1map](http://www-mrsrl.stanford.edu/~jbarral/t1map.html)

T1 mapping may be used to
 - optimize parameters for a sequence (Ernst angle is $acos(e^{-TR/T1})$)
 - monitor diseased tissue
 - measure Ktrans in DCE-MRI
 - derive other quantitative parameters (bound pool fractions)

### T1w

### defacemask

### bold

### T2w

### dwi

### fieldmap
