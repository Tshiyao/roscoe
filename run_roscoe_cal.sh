#!/bin/bash

##############################################################################
# 脚本功能：批量处理output目录下的TSV文件，调用Python脚本计算ROSCOE指标
# 目录结构约定：
#   输入根目录（INPUT_ROOT）下的结构：
#   ├── 0919_dr_grpo_math          # 顶层文件夹（命名自定义）
#   │   └── all-mpnet-base-v2      # 固定子文件夹名
#   │       └── scores_amc23.tsv   # 固定输入文件名
#   ├── 0919_grpo_math
#   │   └── all-mpnet-base-v2
#   │       └── scores_amc23.tsv
#   ...
#   输出根目录（OUTPUT_ROOT）下的结构：
#   ├── 0919_dr_grpo_math.csv      # 输出文件（与顶层文件夹同名）
#   ├── 0919_grpo_math.csv
#   ...
##############################################################################

# ========================== 请根据实际环境修改以下参数 ==========================
# 1. 输入根目录：即包含所有顶层文件夹（如0919_dr_grpo_math）的output目录路径
INPUT_ROOT="/root/autodl-tmp/roscoe/ParlAI/projects/roscoe/MATH/output21_select/"  # 示例：若output在当前目录下，填./output；若在其他路径，填绝对路径（如/root/data/output）
# 2. 输出根目录：结果保存的result目录路径（脚本会自动创建）
OUTPUT_ROOT="/root/autodl-tmp/roscoe/ParlAI/projects/roscoe/MATH/result21_select/"
# 3. Python脚本路径：之前编写的ROSCOE指标计算Python脚本路径（需替换为实际路径）
PYTHON_SCRIPT_PATH="/root/autodl-tmp/roscoe/ParlAI/projects/roscoe/roscoe_calculator.py"  # 示例：若脚本在当前目录，填./roscoe_separate_results.py
# 4. 输入文件名（可选，若输入文件固定为scores_amc23.tsv则无需修改）
#    若后续输入文件名变化，可修改此处（仅需文件名，无需路径和后缀）
INPUT_FILENAME="scores_aime24"
# ==============================================================================

# -------------------------- 脚本核心逻辑（无需修改） --------------------------
# 1. 检查输入根目录是否存在
if [ ! -d "$INPUT_ROOT" ]; then
    echo -e "\033[31m错误：输入根目录 $INPUT_ROOT 不存在！请检查INPUT_ROOT参数是否正确。\033[0m"
    exit 1
fi

# 2. 创建输出根目录+中间文件夹（若不存在）
# 中间文件夹路径：$OUTPUT_ROOT/$INPUT_FILENAME（如./result/scores_amc23）
MIDDLE_DIR="$OUTPUT_ROOT/$INPUT_FILENAME"
mkdir -p "$MIDDLE_DIR"
if [ ! -d "$MIDDLE_DIR" ]; then
    echo -e "\033[31m错误：无法创建中间文件夹 $MIDDLE_DIR！请检查路径权限。\033[0m"
    exit 1
fi

# 3. 检查Python脚本是否存在
if [ ! -f "$PYTHON_SCRIPT_PATH" ]; then
    echo -e "\033[31m错误：Python脚本 $PYTHON_SCRIPT_PATH 不存在！请检查PYTHON_SCRIPT_PATH参数是否正确。\033[0m"
    exit 1
fi

# 4. 遍历输入根目录下的所有顶层文件夹（如0919_dr_grpo_math、Qwen3B等）
echo -e "\033[32m开始批量处理，共发现 $(ls -d "$INPUT_ROOT"/*/ | wc -l) 个顶层文件夹\033[0m"
echo -e "中间文件夹路径：$MIDDLE_DIR"
echo -e "==================================== 开始 ====================================\n"

for top_dir in "$INPUT_ROOT"/*/; do
    # 提取顶层文件夹名称（如从./output/0919_dr_grpo_math/中提取0919_dr_grpo_math）
    top_dir_name=$(basename "${top_dir%/}")
    # 构建当前文件夹下的TSV文件路径（固定结构：顶层文件夹/all-mpnet-base-v2/scores_amc23.tsv） facebook/roscoe-512-roberta-base
    input_tsv="$top_dir/$INPUT_FILENAME.tsv"
    
    # 检查TSV文件是否存在（跳过无TSV的文件夹）
    if [ ! -f "$input_tsv" ]; then
        echo -e "\033[33m警告：文件夹 $top_dir_name 中未找到 TSV 文件（路径：$input_tsv），跳过处理\033[0m"
        echo -e "-----------------------------------------------------------------------------\n"
        continue
    fi
    
    # 构建输出CSV文件路径（$OUTPUT_ROOT/$INPUT_FILENAME/$top_dir_name.csv）
    output_csv="$MIDDLE_DIR/$top_dir_name.csv"
    
    # 打印当前处理信息
    echo -e "\033[34m正在处理：$top_dir_name\033[0m"
    echo -e "  输入TSV路径：$input_tsv"
    echo -e "  输出CSV路径：$output_csv"
    
    # 调用Python脚本计算ROSCOE指标（--input指定TSV，--output指定CSV）
    python "$PYTHON_SCRIPT_PATH" --input "$input_tsv" --output "$output_csv"
    
    # 检查Python脚本执行结果（0为成功，非0为失败）
    if [ $? -eq 0 ]; then
        echo -e "\033[32m  ✅ $top_dir_name 处理完成！结果已保存到 $output_csv\033[0m"
    else
        echo -e "\033[31m  ❌ $top_dir_name 处理失败！请查看Python脚本报错信息\033[0m"
    fi
    
    echo -e "-----------------------------------------------------------------------------\n"
done

# 5. 处理完成提示
echo -e "\033[32m==================================== 结束 ====================================\033[0m"
echo -e "所有文件夹处理完毕！"
echo -e "结果保存目录：$OUTPUT_ROOT"
echo -e "提示：可进入该目录查看输出文件（如 $OUTPUT_ROOT/0919_dr_grpo_math.csv）"