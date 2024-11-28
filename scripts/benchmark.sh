#!/bin/bash

set -ex

HOME=/home/nk
TARGET_DIR="${HOME}/diskann"
BUILD_DIR="${TARGET_DIR}/build"
GT_BIN="${BUILD_DIR}/apps/utils/compute_groundtruth"
BUILD_INDEX_BIN="${BUILD_DIR}/apps/build_disk_index"
SEARCH_BIN="${BUILD_DIR}/apps/search_disk_index"

DATASET=sift
K_gt=100

DATA_TYPE=float
DIST_FN=l2
K=1
R=50
N="100000 10000 1000 100"
L_build=125
L_search="50"
B=0.003
M=0.01
T=1
A=1.0
C=0

ORIGIN_FILE=""
TIMESTAMP=$(date +%s)
LOG_PATH="log"

GT_PATH="${BUILD_DIR}/data/sift/${DATASET}_gt${K_gt}"

arr=($N)

for (( i = 0; i < ${#arr[@]}; i++ )); do
    current=${arr[i]}
    if (( i < ${#arr[@]} - 1 )); then
        next=${arr[i + 1]}
    else
        next=10
    fi
    echo "current: $current, next: $next"

    DATA_PATH="${BUILD_DIR}/data/sift/${DATASET}_learn_${current}.fbin"
    QUERY_PATH="${BUILD_DIR}/data/sift/${DATASET}_query_${next}.fbin"

    OUT_DIR="${BUILD_DIR}/out_${current}"
    INDEX_PATH_PREFIX="${OUT_DIR}/disk_index_${DATASET}"
    RESULT_PATH="${OUT_DIR}/${DATASET}_result"

    mkdir -p $OUT_DIR

    $BUILD_INDEX_BIN --data_type $DATA_TYPE --dist_fn $DIST_FN --data_path $DATA_PATH --index_path_prefix $INDEX_PATH_PREFIX \
        -R $R -L $L_build -B $B -M $M -T $T -N $current >> $LOG_PATH

    $SEARCH_BIN --data_type $DATA_TYPE --dist_fn $DIST_FN --index_path_prefix $INDEX_PATH_PREFIX --query_file $QUERY_PATH --gt_file $GT_PATH --result_path $RESULT_PATH \
        -K $K -L $L_search -T $T --num_nodes_to_cache $C >> $LOG_PATH
done

echo ""
