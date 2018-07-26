#!/bin/bash

# Check for input
arg=$2
if [ X$arg = X ] ; then
	echo "  Need subject MR image input"
	echo "  Usage: `basename $0` -i <input nii MRI>"
	exit 1
fi

# MNI template containing directory. 
mawlawi=/portal01/kkyoder/code/mawlawi_roi_code/mawlawi01_striatum.nii.gz

# Creating output directory
	Outdir="Mawlawi_striatal_ROI"
	mkdir $Outdir

# Check if warp exists and used it; otherwise make one.
invwarp="$Outdir/MNI2T1_warpf.nii.gz"
invomat12="$Outdir/MNI2T1_dof12.mat"
invomat="$Outdir/MNI2T1_dof6.mat"
if [ ! -e $invwarp ] || [ ! -e $invomat12 ] || [ ! -e $invomat ]; then
	echo "  Obtaining warp field MNI -> T1"
	# flirt dof6
	ref="$FSLDIR/data/standard/MNI152_T1_1mm.nii.gz"
	omat="$Outdir/temp_T12MNI_dof6.mat"
	dof6="$Outdir/temp_T12MNI_dof6.nii.gz"	
	$FSLDIR/bin/flirt -ref $ref -in $arg -omat $omat -dof 6 -interp trilinear -out $dof6
	
 	$FSLDIR/bin/convert_xfm -omat $invomat -inverse $omat

	#flirt dof12
	dof12="$Outdir/temp_T12MNI_dof12.nii.gz"
	omat12="$Outdir/temp_T12MNI_dof12.mat"
	$FSLDIR/bin/flirt -ref $ref -in $dof6 -omat $omat12 -dof 12 -interp trilinear -out $dof12
	
 	$FSLDIR/bin/convert_xfm -omat $invomat12 -inverse $omat12

	#fnirt
	warpf="$Outdir/temp_T12MNI_warpf.nii.gz"
	warped="$Outdir/temp_T12MNI_warped.nii.gz"
	$FSLDIR/bin/fnirt --ref=$ref --in=$dof12 --cout=$warpf --iout=$warped

	$FSLDIR/bin/invwarp --ref=$ref --warp=$warpf --out=$invwarp
else 
	echo "  MNI -> T1 warp transformations exist and will be used!"
fi

#apply inverse transformations
#invwarp
roiw="$Outdir/Mawlawi01_unwarped.nii.gz"
$FSLDIR/bin/applywarp --ref=$dof12 --in=$mawlawi --warp=$invwarp --out=$roiw --interp=nn

#dof12
roidof12="$Outdir/Mawlawi01_undof12.nii.gz"
$FSLDIR/bin/flirt -in $roiw -ref $dof6 -out $roidof12 -applyxfm -init $invomat12 -interp nearestneighbour -nosearch

#dof6
roi="$Outdir/Mawlawi01_native.nii.gz"
$FSLDIR/bin/flirt -in $roidof12 -ref $arg -out $roi -applyxfm -init $invomat -interp nearestneighbour -nosearch

#separate and remane roi
$FSLDIR/bin/fslmaths $roi -thr 13 -uthr 13 $Outdir/L_pre_DCA
$FSLDIR/bin/fslmaths $roi -thr 15 -uthr 15 $Outdir/L_pre_DPU
$FSLDIR/bin/fslmaths $roi -thr 17 -uthr 17 $Outdir/L_VST
$FSLDIR/bin/fslmaths $roi -thr 14 -uthr 14 $Outdir/L_post_DCA
$FSLDIR/bin/fslmaths $roi -thr 16 -uthr 16 $Outdir/L_post_DPU
$FSLDIR/bin/fslmaths $roi -thr 1 -uthr 1 $Outdir/R_pre_DCA
$FSLDIR/bin/fslmaths $roi -thr 3 -uthr 3 $Outdir/R_pre_DPU
$FSLDIR/bin/fslmaths $roi -thr 5 -uthr 5 $Outdir/R_VST
$FSLDIR/bin/fslmaths $roi -thr 2 -uthr 2 $Outdir/R_post_DCA
$FSLDIR/bin/fslmaths $roi -thr 4 -uthr 4 $Outdir/R_post_DPU

#remove tmp files
#rm $Outdir/temp*

#unzip transformed roi
gunzip $Outdir/L*gz $Outdir/R*gz


