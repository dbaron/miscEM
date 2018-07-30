#!/bin/bash
#
#
############################################################################
#
# Author: "Kyle L. Morris"
# University of California Berkeley 2016
#
# This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
############################################################################
#
# Edited by Simon Fromm
# University of California Berkeley 2018
#
###########################################################################

if [[ -z $1 ]] ; then
  echo ""
  echo "Variables empty, usage is $0 (1) (2) (3) (4) (5) (6)"
  echo ""
  echo "(1) = apix (A/pix); superresolution pixel size if frames where recorded in superresolution!"
  echo "(2) = dose (e/A/frame)"
  echo "(3) = frames directory"
  echo "(4) = input extension (i.e. tif)"
  echo "(5) = output extension (i.e. mrc)"
  echo "(6) = gpu id (i.e. 0 1 ...)"
  echo ""

  exit
fi

apix=$1
dose=$2
dir=$3

ext=$4
ext2=$5
gpu=$6
suffix="cor2"

motioncor2exe="/usr/local/software/bin/motioncor2"

echo '##############################################################################'
echo 'Usage - motioncor2_run.sh apix dose frame_directory input.ext output.ext gpu_id'
echo '##############################################################################'

############################################################################
############################################################################

# get and print total number of files in directory
num=$(ls $dir/*.$ext | wc -l)
echo $num 'files to extract sub-frames from'
echo ''

echo ''
echo 'Motion correcting subframes with apix: '$apix' and dose (e/A^2/frame): '$dose' by motioncor2'
echo "Using input files with extension: ${dir}/*.${ext}"
echo "Using output file extension:      ${ext2}"
echo ''
read -p "press [Enter] key to confirm and run script..."

############################################################################
############################################################################

#Remove existing converted micrographs from filelist.dat, excluding those with the set suffix i.e. already processed
ls -n $dir/*.$ext | grep -v $suffix | awk {'print $9'} | cat -n > filelist.dat

#Loop through filelist.dat for all the files
i=1
while read p; do
   file=$(sed -n $i"p" filelist.dat | awk {'print $2'})
   name=$(basename $file .$ext)

   orig=$dir/"$name".$ext
   new=$dir/"$name"_"$suffix".$ext2

   if [ -e $new ]; then
    echo ""
    echo $new "- File exists, skipping"
    echo ""
   else
    echo ""
    echo "File_in:" $orig
    echo "File_out:" $new
    echo ""
    #For simple fast whole frame alignment
    #$motioncor2exe -InMrc $orig -OutMrc $new -Iter 10 -Tol 0.5 -Throw 2 -PixSize $apix

    #For patch alignment, dose weighting, fourier binning of superres, and grouping for higher S/N
    ${motioncor2exe} -InTiff ${orig} -OutMrc ${new} -Patch 5 5 -Iter 10 -Tol 0.5 -Throw 0 -kV 200 -PixSize $apix -FmDose $dose -FtBin 2.0 -Gpu $gpu
   fi

   i=$((i+1))
done < filelist.dat

#rm filelist.dat

echo "//////////////////////"
echo "Motioncorr2 complete"
echo "Corrected $((i-1)) files"
echo "//////////////////////"
