import json
import os
import argparse


def process_json_to_jsonl(input_file_path, output_dir="output"):
    """
    处理原始JSON文件，生成三个新的JSONL文件到指定文件夹
    
    参数:
        input_file_path: 原始JSON文件的路径
        output_dir: 输出文件夹路径，默认为"output"
    """
    # 创建输出文件夹（如果不存在）
    try:
        os.makedirs(output_dir, exist_ok=True)
        print(f"输出文件夹: {os.path.abspath(output_dir)}")
    except OSError as e:
        print(f"创建输出文件夹失败: {e}")
        return
    
    # 读取原始JSON文件
    try:
        with open(input_file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        print(f"读取输入文件: {input_file_path}")
        
    except FileNotFoundError:
        print(f"错误: 输入文件 {input_file_path} 不存在")
        return
    except json.JSONDecodeError:
        print(f"错误: 输入文件 {input_file_path} 不是有效的JSON格式")
        return
    except Exception as e:
        print(f"读取输入文件时发生错误: {e}")
        return
    
    # 定义需要处理的数据集及其对应的输出文件名
    datasets = {
        'aime24': 'aime24.jsonl',
        'math500': 'math500.jsonl',
        'amc23': 'amc23.jsonl'  # 注意这里输出文件名为amc.jsonl
    }
    
    # 处理每个数据集
    for dataset_key, output_filename in datasets.items():
        # 检查数据集中是否存在该数据集
        if dataset_key not in data:
            print(f"警告: 数据集中不存在 {dataset_key}，跳过处理")
            continue
        
        dataset = data[dataset_key]
        # 构建完整的输出文件路径
        output_path = os.path.join(output_dir, output_filename)
        
        try:
            # 写入JSONL文件
            print(f"写入JSONL文件{output_path}")
            with open(output_path, 'w', encoding='utf-8') as f:
                for idx, item in enumerate(dataset):
                    # 提取所需字段
                    question = item.get('question', '')
                    responses = item.get('responses', [])
                    results = item.get('results', [])
                    answer = item.get('answer', '')
                    
                    # 根据规则选择合适的response
                    selected_response = ""
                    # 查找第一个正确的response
                    found_correct = "no"
                    if responses:
                        for resp, result in zip(responses, results):
                            if result:  # 如果结果为true
                                selected_response = resp
                                found_correct = "yes"
                                break
                        
                        # 如果没有正确的，选择第一个response
                        if found_correct == "no":
                            selected_response = responses[0]
                    
                    # 构建新的JSON对象
                    new_entry = {
                        "premise": question,
                        "hypothesis": f"IGNORE THIS. Ground truth here for reference. {answer}",
                        "gpt-3": selected_response,
                        "answer": found_correct,
                        "key": f"{dataset_key}_{idx}"  # 生成唯一标识
                    }
                    
                    # 写入JSONL文件（每行一个JSON对象）
                    f.write(json.dumps(new_entry, ensure_ascii=False) + '\n')
            
            print(f"已生成 {output_path}，包含 {len(dataset)} 条记录")
        except Exception as e:
            print(f"写入文件 {output_path} 时发生错误: {e}")

if __name__ == "__main__":
    
    filename = "Qwen3B"
    # 请将此处替换为你的原始JSON文件路径
    input_json_path = f"/root/autodl-tmp/roscoe/ParlAI/projects/roscoe/MATH/raw/{filename}/None.json"

    # 请将此处替换为你希望保存输出文件的文件夹路径
    output_directory = f"/root/autodl-tmp/roscoe/ParlAI/projects/roscoe/MATH/output/{filename}/"
    
    # 设置命令行参数
    parser = argparse.ArgumentParser(description=' ')
    # 添加默认值：当前目录下的input.jsonl和output.jsonl
    parser.add_argument('--input', nargs='?', default=input_json_path, 
                      help='输入的JSONL文件路径')
    parser.add_argument('--output', nargs='?', default=output_directory,
                      help='输出的JSONL文件路径')
    
    args = parser.parse_args()
    
    process_json_to_jsonl(args.input, args.output)
    print("处理完成")
    