#!/bin/bash

# ===================== 核心配置（可根据需求调整）=====================
INPUT_ROOT="/root/autodl-tmp/roscoe/ParlAI/projects/roscoe/MATH/raw21"
OUTPUT_ROOT="/root/autodl-tmp/roscoe/ParlAI/projects/roscoe/MATH/clean21"
SCORE_OUTPUT_ROOT="/root/autodl-tmp/roscoe/ParlAI/projects/roscoe/MATH/output21"
LOG_ROOT="/root/autodl-tmp/roscoe/ParlAI/projects/roscoe/MATH/logs21"  # 并行日志目录（避免输出混乱）
# DATASETS="gsm8k"  # 可填多个：如 "math500 amc23 aime24"
DATASETS="aime24"
MAX_PARALLEL=2    # 最大并行任务数（建议设为 CPU 核心数的 1-2 倍，如 4/8/16）
# ====================================================================

# 1. 初始化前置检查与目录创建
check_and_create_dir() {
    local dir_path="$1"
    if [ ! -d "$dir_path" ]; then
        mkdir -p "$dir_path" || { echo "错误：无法创建目录 $dir_path"; exit 1; }
    fi
}

# 检查输入目录是否存在
if [ ! -d "$INPUT_ROOT" ]; then
    echo "错误：输入目录 $INPUT_ROOT 不存在！"
    exit 1
fi

# 创建必要根目录（清洗/打分/日志）
check_and_create_dir "$OUTPUT_ROOT"
check_and_create_dir "$SCORE_OUTPUT_ROOT"
check_and_create_dir "$LOG_ROOT"

# 2. 捕获中断信号（如 Ctrl+C），确保后台任务能被正常终止
trap 'echo -e "\n正在终止所有并行任务..."; pkill -P $$; exit 1' SIGINT

# 3. 并行处理函数（每个子文件夹的逻辑封装成函数，方便后台调用）
process_dir() {
    local input_dir="$1"  # 传入当前子文件夹路径
    local dir_name=$(basename "${input_dir%/}")  # 提取文件夹名
    local input_file="$input_dir/raw.json"
    local clean_output_dir="$OUTPUT_ROOT/$dir_name/"
    local score_output_dir="$SCORE_OUTPUT_ROOT/$dir_name/"
    local log_file="$LOG_ROOT/${dir_name}_process.log"  # 每个任务独立日志

    # 输出并行任务开始信息（同时写日志）
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] 开始处理：$dir_name（日志：$log_file）" | tee -a "$log_file"

    # 检查原始文件是否存在
    if [ ! -f "$input_file" ]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] 警告：$dir_name 未找到 raw.json，跳过" | tee -a "$log_file"
        return  # 退出当前并行任务，不影响其他任务
    fi

    # 创建当前任务的输出目录
    check_and_create_dir "$clean_output_dir"
    check_and_create_dir "$score_output_dir"

    # 3.1 执行清洗脚本（失败则跳过打分）
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $dir_name：开始清洗" | tee -a "$log_file"
    python /root/autodl-tmp/roscoe/ParlAI/projects/roscoe/MATH/clean.py \
        --input "$input_file" \
        --output "$clean_output_dir" >> "$log_file" 2>&1  # 日志包含错误信息

    if [ $? -ne 0 ]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] $dir_name：清洗失败（查看日志）" | tee -a "$log_file"
        return
    fi

    # 3.2 执行打分脚本
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $dir_name：开始打分（数据集：$DATASETS）" | tee -a "$log_file"
    echo "处理文件 $clean_output_dir"
    echo "保存到  $score_output_dir"
    
    # -t sim_sce -m facebook/roscoe-512-roberta-base \
    python /root/autodl-tmp/roscoe/ParlAI/projects/roscoe/roscoe.py \
        --datasets "$DATASETS" \
        --output-directory "$score_output_dir" \
        --dataset-path "$clean_output_dir" >> "$log_file" 2>&1

    if [ $? -eq 0 ]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] $dir_name：打分完成" | tee -a "$log_file"
    else
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] $dir_name：打分失败（查看日志）" | tee -a "$log_file"
    fi
}

# 4. 并行执行循环（控制并发数）
echo "开始并行处理，最大并发数：$MAX_PARALLEL（日志目录：$LOG_ROOT）"
echo "----------------------------------------"

for input_dir in "$INPUT_ROOT"/*/; do
    # 仅处理目录
    if [ -d "$input_dir" ]; then
        # 启动当前目录的处理任务（丢到后台）
        process_dir "$input_dir" &

        # 控制并发数：当后台任务数达到 MAX_PARALLEL 时，等待一个任务完成再继续
        while [ $(jobs -r | wc -l) -ge "$MAX_PARALLEL" ]; do
            wait -n  # 等待任意一个后台任务结束（释放资源）
        done
    fi
done

# 5. 等待所有剩余的后台任务完成
wait

echo "----------------------------------------"
echo "所有文件夹并行处理完毕！（日志可查看：$LOG_ROOT）"