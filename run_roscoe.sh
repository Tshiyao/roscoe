#!/bin/bash


# 定义输入和输出根目录
INPUT_ROOT="/root/autodl-tmp/roscoe/ParlAI/projects/roscoe/MATH/raw/"
OUTPUT_ROOT="/root/autodl-tmp/roscoe/ParlAI/projects/roscoe/MATH/clean/"
SCORE_OUTPUT_ROOT="/root/autodl-tmp/roscoe/ParlAI/projects/roscoe/MATH/output/"  # 打分结果根目录

# 定义需要处理的数据集（可填写多个，用空格分隔）
# DATASETS="gsm8k"  
# DATASETS="math500 amc23 aime24"
DATASETS="amc23"

# 检查输入目录是否存在
if [ ! -d "$INPUT_ROOT" ]; then
    echo "错误：输入目录 $INPUT_ROOT 不存在！"
    exit 1
fi

# 创建输出根目录（如果不存在）
mkdir -p "$OUTPUT_ROOT"
mkdir -p "$SCORE_OUTPUT_ROOT"

# 遍历输入目录下的所有子文件夹
for input_dir in "$INPUT_ROOT"/*/; do
    # 检查是否是目录
    if [ -d "$input_dir" ]; then
        # 提取文件夹名称
        dir_name=$(basename "${input_dir%/}")
        
        # 构建输入文件路径（指向文件夹下的None.json）
        input_file="$input_dir/raw.json"

        # 检查None.json是否存在
        if [ ! -f "$input_file" ]; then
            echo "警告：$dir_name 中未找到 None.json，跳过处理"
            echo "----------------------------------------"
            continue
        fi

        # 构建清洗输出目录路径
        clean_output_dir="$OUTPUT_ROOT/$dir_name/"
        # 构建打分输出目录路径（根据dirname在output下创建对应文件夹）
        score_output_dir="$SCORE_OUTPUT_ROOT/$dir_name/"

        
        # 创建输出目录（如果不存在）
        mkdir -p "$output_dir"
        mkdir -p "$score_output_dir"
        
        echo "正在处理: $dir_name"
        echo "输入路径: $input_file"
        echo "清洗输出路径: $clean_output_dir"
        echo "打分输出路径: $score_output_dir"
        
        # 运行Python脚本处理当前文件夹
        python /root/autodl-tmp/roscoe/ParlAI/projects/roscoe/MATH/clean.py --input "$input_file" --output "$clean_output_dir"
        
        # 检查命令是否成功执行
        if [ $? -eq 0 ]; then
            echo "$dir_name clean处理完成"
        else
            echo "$dir_name clean处理失败"
        fi
        
        echo "----------------------------------------"
        echo "------------开始打分-------------"
        echo "----------------------------------------"

        echo "------------现在处理$dir_name的打分-------------"
        echo "------------评估处理中-------------"


        # 运行打分脚本，inputdir对应dirname相关路径，outputdir为新建的对应文件夹
        python /root/autodl-tmp/roscoe/ParlAI/projects/roscoe/roscoe.py \
            --datasets $DATASETS \
            --output-directory "$score_output_dir" \
            --dataset-path "$clean_output_dir"

        # python /root/autodl-tmp/roscoe/ParlAI/projects/roscoe/roscoe.py \
        #     --datasets $DATASETS \
        #     --output-directory "./projects/roscoe/scores/" \
        #     --dataset-path "./projects/roscoe/roscoe_data/generated/"

        # 检查打分命令是否成功执行
        if [ $? -eq 0 ]; then
            echo "------------$dir_name打分处理完成-------------"
        else
            echo "------------$dir_name打分处理失败-------------"
        fi
        
        echo "----------------------------------------"



    fi
done

echo "所有文件夹处理完毕"

