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
K=10
R=50
N="100000"
L_build=125
L_search="$(seq 1 1 50)"
B=0.003
M=1
T=1
A=1.0
C=0

DATE=$(date +%y%m%d)

LOG_DIR="$DATE"
LOG_PATH="${LOG_DIR}/log_B"
LOG_BUILD_PATH="${LOG_PATH}_build"
LOG_SEARCH_PATH="${LOG_PATH}_search"

GT_PATH="${BUILD_DIR}/data/${DATASET}/${DATASET}_gt${K_gt}.fbin"
DATA_PATH="${BUILD_DIR}/data/${DATASET}/${DATASET}_learn.fbin"
QUERY_PATH="${BUILD_DIR}/data/${DATASET}/${DATASET}_query.fbin"

OUT_DIR="out"
INDEX_PATH_PREFIX="${OUT_DIR}/disk_index_${DATASET}"
RESULT_PATH="${OUT_DIR}/${DATASET}_result"

mkdir -p $LOG_DIR

$BUILD_INDEX_BIN --data_type $DATA_TYPE --dist_fn $DIST_FN --data_path $DATA_PATH --index_path_prefix $INDEX_PATH_PREFIX \
    -R $R -L $L_build -B $B -M $M -T $T -N $N >> $LOG_PATH

pid=$!
echo "pid: $pid"

top -b -d 1 -p $pid | grep --line-buffered $pid >> "${LOG_BUILD_PATH}.mem" &

wait $pid

echo "==========================================" >> "${LOG_BUILD_PATH}.mem"

sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"

pid=$!
echo "pid: $pid"

top -b -d 1 -p $pid | grep --line-buffered $pid >> "${LOG_BUILD_PATH}.mem" &

wait $pid

echo "==========================================" >> "${LOG_BUILD_PATH}.mem"

sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"


$SEARCH_BIN --data_type $DATA_TYPE --dist_fn $DIST_FN --index_path_prefix $INDEX_PATH_PREFIX --query_file $QUERY_PATH --gt_file $GT_PATH --result_path $RESULT_PATH \
    -K $K -L $L_search -T $T --num_nodes_to_cache $C >> $LOG_PATH

pid=$!
echo "pid: $pid"

top -b -d 1 -p $pid | grep --line-buffered $pid >> "${LOG_SEARCH_PATH}.mem" &

wait $pid

echo "==========================================" >> "${LOG_SEARCH_PATH}.mem"

sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"

rm -rf $OUT_DIR

echo ""
