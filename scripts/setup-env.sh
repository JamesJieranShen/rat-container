#!/bin/bash

pushd /home/software/root/bin/ > /dev/null
source thisroot.sh
popd > /dev/null
source /home/software/geant4/bin/geant4.sh

source /home/scripts/setup-genie.sh
# export TF_DIR=/usr/local
# export CPPFLOW_DIR=/home/software/cppflow
# export LIBRARY_PATH=$LIBRARY_PATH:$TF_DIR/lib
# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$TF_DIR/lib
# export LIBRARY_PATH=$LIBRARY_PATH:$CPPFLOW_DIR/lib
# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CPPFLOW_DIR/lib

RAT_ENV=/rat/env.sh
if [ -f "$RAT_ENV" ]; then
    source $RAT_ENV
else
    printf "\nCould not find /rat/env.sh\nIf youre building RAT, please ignore.\nOtherwise, ensure RAT is mounted to /rat\n"
fi
