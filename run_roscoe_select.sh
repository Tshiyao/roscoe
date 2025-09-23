#!/bin/bash

##############################################################################
# 脚本功能：批量处理clean和output目录下的特定JSON和CSV文件
# 仅处理clean子目录中的amc23.json及其对应的output子目录中的amc23.csv
# 调用Python脚本筛选正确题目及其分数，并保存到clean_select和output_select目录
# 目录结构约定：
#   输入结构：
#   ├── clean                  # JSON文件根目录
#   │   ├── subdir1            # 子文件夹1
#   │   │   └── amc23.json     # 需要处理的JSON文件
#   │   ├── subdir2            # 子文件夹2
#   │   │   └── amc23.json     # 需要处理的JSON文件
#   │   ...
#   ├── output                 # CSV文件根目录
#   │   ├── subdir1            # 与clean对应的子文件夹1
#   │   │   └── amc23.csv      # 与JSON对应的CSV文件
#   │   ├── subdir2            # 与clean对应的子文件夹2
#   │   │   └── amc23.csv      # 与JSON对应的CSV文件
#   │   ...
#
#   输出结构：
#   ├── clean_select           # 筛选后的JSON文件根目录
#   │   ├── subdir1            # 保持与输入相同的子文件夹结构
#   │   │   └── amc23.json     # 筛选后的JSON文件
#   │   ...
#   ├── output_select          # 筛选后的CSV文件根目录
#   │   ├── subdir1            # 保持与输入相同的子文件夹结构
#   │   │   └── amc23.csv      # 筛选后的CSV文件
#   │   ...
##############################################################################

# ========================== 请根据实际环境修改以下参数 ==========================
# 1. JSON文件根目录（clean文件夹路径）
CLEAN_ROOT="/root/autodl-tmp/roscoe/ParlAI/projects/roscoe/MATH/clean21"  # 示例：若在当前目录下，填./clean；若在其他路径，填绝对路径
# 2. CSV文件根目录（output文件夹路径）
OUTPUT_ROOT="/root/autodl-tmp/roscoe/ParlAI/projects/roscoe/MATH/output21"  # 示例：若在当前目录下，填./output；若在其他路径，填绝对路径
# 3. 筛选后的JSON文件输出根目录
CLEAN_SELECT_ROOT="/root/autodl-tmp/roscoe/ParlAI/projects/roscoe/MATH/clean21_select"
# 4. 筛选后的CSV文件输出根目录
OUTPUT_SELECT_ROOT="/root/autodl-tmp/roscoe/ParlAI/projects/roscoe/MATH/output21_select"
# 5. Python脚本路径：之前编写的筛选脚本路径（需替换为实际路径）
PYTHON_SCRIPT_PATH="/root/autodl-tmp/roscoe/ParlAI/projects/roscoe/MATH/select.py"  # 示例：若脚本在当前目录，填./filter_correct_questions.py
# 6. 需要处理的JSON文件名（固定为amc23.json）
TARGET_JSON="aime24.jsonl"
# 7. 对应的CSV文件名（固定为scores_amc23.tsv）
TARGET_CSV="scores_aime24.tsv"
# ==============================================================================

# -------------------------- 脚本核心逻辑（无需修改） --------------------------
# 1. 检查输入根目录是否存在
if [ ! -d "$CLEAN_ROOT" ]; then
    echo -e "\033[31m错误：JSON根目录 $CLEAN_ROOT 不存在！请检查CLEAN_ROOT参数是否正确。\033[0m"
    exit 1
fi

if [ ! -d "$OUTPUT_ROOT" ]; then
    echo -e "\033[31m错误：CSV根目录 $OUTPUT_ROOT 不存在！请检查OUTPUT_ROOT参数是否正确。\033[0m"
    exit 1
fi

# 2. 检查Python脚本是否存在
if [ ! -f "$PYTHON_SCRIPT_PATH" ]; then
    echo -e "\033[31m错误：Python脚本 $PYTHON_SCRIPT_PATH 不存在！请检查PYTHON_SCRIPT_PATH参数是否正确。\033[0m"
    exit 1
fi

# 3. 创建输出根目录（若不存在）
mkdir -p "$CLEAN_SELECT_ROOT"
mkdir -p "$OUTPUT_SELECT_ROOT"

if [ ! -d "$CLEAN_SELECT_ROOT" ]; then
    echo -e "\033[31m错误：无法创建输出JSON根目录 $CLEAN_SELECT_ROOT！请检查路径权限。\033[0m"
    exit 1
fi

if [ ! -d "$OUTPUT_SELECT_ROOT" ]; then
    echo -e "\033[31m错误：无法创建输出CSV根目录 $OUTPUT_SELECT_ROOT！请检查路径权限。\033[0m"
    exit 1
fi

# 4. 遍历clean目录下的所有JSON文件
echo -e "\033[32m开始批量处理文件...\033[0m"
echo -e "只处理特定文件：$TARGET_JSON 和 $TARGET_CSV"
echo -e "JSON输入目录：$CLEAN_ROOT"
echo -e "CSV输入目录：$OUTPUT_ROOT"
echo -e "JSON输出目录：$CLEAN_SELECT_ROOT"
echo -e "CSV输出目录：$OUTPUT_SELECT_ROOT"
echo -e "==================================== 开始 ====================================\n"

# 查找所有JSON文件并处理
for input_dir in "$CLEAN_ROOT"/*/; do
    # 提取相对路径, 提取顶层文件夹名称（如从./output/0919_dr_grpo_math/中提取0919_dr_grpo_math）
    relative_path=$(basename "${input_dir%/}")
    echo $relative_path
    # 对应的CSV文件路径
    csv_file="$OUTPUT_ROOT/$relative_path"
    # 将.csv替换为.json，得到正确的CSV文件名
    csv_file="$csv_file/all-mpnet-base-v2/$TARGET_CSV"
    json_file="$input_dir$TARGET_JSON"
    echo $csv_file
    # 检查对应的CSV文件是否存在
    if [ ! -f "$csv_file" ]; then
        echo -e "\033[33m警告：JSON文件 $json_file 对应的CSV文件 $csv_file 不存在，跳过处理\033[0m"
        echo -e "-----------------------------------------------------------------------------\n"
        continue
    fi
    
    # 构建输出文件路径
    output_json="$CLEAN_SELECT_ROOT/$relative_path/$TARGET_JSON"
    output_csv="$OUTPUT_SELECT_ROOT/$relative_path/$TARGET_CSV"
    
    # 创建输出目录（如果不存在）
    output_dir=$(dirname "$output_json")
    mkdir -p "$output_dir"
    output_csv_dir=$(dirname "$output_csv")
    mkdir -p "$output_csv_dir"
    
    # 打印当前处理信息
    echo -e "\033[34m正在处理：$relative_path\033[0m"
    echo -e "  输入JSON路径：$json_file"
    echo -e "  输入CSV路径：$csv_file"
    echo -e "  输出JSON路径：$output_json"
    echo -e "  输出CSV路径：$output_csv"
    
    # 调用Python脚本处理
    python "$PYTHON_SCRIPT_PATH" \
        --json-input "$json_file" \
        --csv-input "$csv_file" \
        --json-output "$output_json" \
        --csv-output "$output_csv"
    
    # 检查Python脚本执行结果
    if [ $? -eq 0 ]; then
        echo -e "\033[32m  ✅ 处理完成！\033[0m"
    else
        echo -e "\033[31m  ❌ 处理失败！请查看Python脚本报错信息\033[0m"
    fi
    
    echo -e "-----------------------------------------------------------------------------\n"
done

# 5. 处理完成提示
echo -e "\033[32m==================================== 结束 ====================================\033[0m"
echo -e "所有文件处理完毕！"
echo -e "筛选后的JSON文件保存目录：$CLEAN_SELECT_ROOT"
echo -e "筛选后的CSV文件保存目录：$OUTPUT_SELECT_ROOT"
    