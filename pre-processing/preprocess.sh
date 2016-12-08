#!/bin/bash
nvidia-smi

# workdir : ./pre-processing/
# image preprocessing
python DREAM_DM_preprocessing.py -c dreamCh -d train -f class -v  1

# workdir : ./pre-processing/Torch
cd Torch

# build torch dataset 
th preprocess.lua

#workdir : ./
cd ../

# check result
RESULT_DIR='/preprocessedData'
echo "## Files in "$RESULT_DIR"/dreamCh"
ls $RESULT_DIR/dreamCh
echo "## Files in "$RESULT_DIR"/gen"
ls $RESULT_DIR/gen

