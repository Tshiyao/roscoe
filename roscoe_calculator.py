import pandas as pd
import argparse

def calculate_roscoe_metrics(csv_file_path, output_file_path):
    """
    读取CSV文件，计算每行的ROSCOE各项指标平均值，并保存结果
    
    参数:
    csv_file_path: 输入CSV文件路径
    output_file_path: 输出CSV文件路径
    """
    # 定义所有基础指标常量
    FAITHFUL_SENT = "faithfulness"
    FAITHFUL_WORD = "faithfulness_ww"
    REPETITION_WORD = "repetition_word"
    REPETITION_SENT = "repetition_step"
    INFORM_STEP = "informativeness_step"
    INFORM_CHAIN = "informativeness_chain"
    DISCOURSE_REPRESENTATION = "discourse_representation"
    COHERENCE_STEP_VS_STEP = "coherence_step_vs_step"
    PPL_STEP = "perplexity_step"
    PPL_STEP_MAX = "perplexity_step_max"
    PPL_CHAIN = "perplexity_chain"
    GRAMMAR_STEP = "grammar_step"
    GRAMMAR_STEP_MAX = "grammar_step_max"
    CHAIN_ALIGNMENT = "reasoning_alignment"
    EXT_HALLUCINATION = "external_hallucination"
    REDUNDANCY = "redundancy"
    COMMON_SENSE_ERROR = "common_sense_error"
    MISSING_STEP = "missing_step"
    SEMANTIC_COVERAGE_STEP = "semantic_coverage_step"
    SEMANTIC_COVERAGE_CHAIN = "semantic_coverage_chain"
    
    # 核心ROSCOE指标分组
    ROSCOE_SA = [
        FAITHFUL_SENT,
        FAITHFUL_WORD,
        REPETITION_WORD,
        INFORM_STEP,
        CHAIN_ALIGNMENT,
        EXT_HALLUCINATION,
        REDUNDANCY,
        COMMON_SENSE_ERROR,
        MISSING_STEP,
        SEMANTIC_COVERAGE_STEP,
    ]
    
    ROSCOE_SS = [
        INFORM_CHAIN,
        REPETITION_SENT,
        SEMANTIC_COVERAGE_CHAIN,
    ]
    
    NLI_MODEL_SCORES = [
        DISCOURSE_REPRESENTATION,
        COHERENCE_STEP_VS_STEP,
    ]
    ROSCOE_LI = NLI_MODEL_SCORES
    
    LANGUAGE_MODEL_SCORES = [
        PPL_CHAIN,
        PPL_STEP,
        PPL_STEP_MAX,
    ]
    
    GRAMMAR_MODEL_SCORES = [
        GRAMMAR_STEP,
        GRAMMAR_STEP_MAX,
    ]
    ROSCOE_LC = LANGUAGE_MODEL_SCORES + GRAMMAR_MODEL_SCORES
    
    # 构建ROSCOE指标字典
    ROSCOE_SECTIONS = {
        'ROSCOE-SA': ROSCOE_SA,
        'ROSCOE-SS': ROSCOE_SS,
        'ROSCOE-LI': ROSCOE_LI,
        'ROSCOE-LC': ROSCOE_LC,
    }
    # 提取ROSCOE指标名称
    roscoe_columns = list(ROSCOE_SECTIONS.keys())
    
    # 读取CSV文件
    try:
        df = pd.read_csv(
            csv_file_path,
            sep=r'\s+',  # 匹配空格或制表符（一个或多个）
            engine='python',
            skipinitialspace=True  # 跳过字段前的空格
        )
    except Exception as e:
        print(f"读取文件失败: {e}")
        return None
    
    # 检查是否有ID列
    id_column = None
    for col in df.columns:
        if 'id' in col.lower():
            id_column = col
            break
        
        
    # 计算每个ROSCOE指标的平均值
    calculated_metrics = []
    for metric, submetrics in ROSCOE_SECTIONS.items():
        # 检查所有子项是否都在数据中
        missing = [sub for sub in submetrics if sub not in df.columns]

        
        if missing:
            print(f"警告: 数据中缺少{metric}所需的子项: {missing}")
            continue
            
        # 计算平均值并添加为新列
        df[metric] = df[submetrics].mean(axis=1)
        calculated_metrics.append(metric)
        print(f"已计算{metric}（包含{len(submetrics)}个子项）")
    
    # 准备要保存的结果数据
    if id_column:
        # 如果有ID列，保留ID和计算的指标
        result_df = df[[id_column] + calculated_metrics].copy()
        # 重命名ID列为统一的"ID"
        result_df = result_df.rename(columns={id_column: "ID"})
    else:
        # 如果没有ID列，使用索引作为ID
        result_df = df[calculated_metrics].copy()
        result_df.insert(0, "ID", df.index)
        print("\n警告: 输入文件中未找到ID列，使用索引作为ID")
    
    # # 保存结果到输出文件
    # try:
    #     df.to_csv(output_file_path, index=False)
    #     print(f"结果已成功保存到: {output_file_path}")
    # except Exception as e:
    #     print(f"保存文件失败: {e}")
    #     return None
    
    # return df
    
    # 保存结果（仅包含ID和四个ROSCOE指标）
    try:
        result_df.to_csv(
            output_file_path,
            index=False,
            sep=','  # 输出文件使用逗号分隔
        )
        print(f"\n结果已单独保存到：{output_file_path}")
        print(f"保存的列：{result_df.columns.tolist()}")
    except Exception as e:
        print(f"保存文件失败: {str(e)}")
        return None
    
    return result_df

def main():
    # 创建命令行参数解析器
    parser = argparse.ArgumentParser(description='计算ROSCOE各项指标并保存结果到CSV文件')
    
    # 添加输入文件路径参数
    parser.add_argument('--input', '-i', required=True, 
                      help='输入CSV文件的路径（例如：data/input.csv）')
    
    # 添加输出文件路径参数，可选，有默认值
    parser.add_argument('--output', '-o', 
                      help='输出CSV文件的路径（例如：data/output.csv），默认在输入文件名后添加"_output"')
    
    # 解析命令行参数
    args = parser.parse_args()
    
    # 处理输出文件路径，如果未指定则自动生成
    if not args.output:
        # 分离文件名和扩展名
        import os
        file_name, file_ext = os.path.splitext(args.input)
        args.output = f"{file_name}_output{file_ext}"
    
    # 计算ROSCOE指标
    calculate_roscoe_metrics(args.input, args.output)

if __name__ == "__main__":
    main()
    