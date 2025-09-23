import json
import csv
import argparse


def filter_correct_questions(json_input_path, csv_input_path, json_output_path, csv_output_path):
    # 读取JSON文件并筛选出正确的题目
    correct_entries = []
    with open(json_input_path, 'r', encoding='utf-8') as json_file:
        # 假设JSON文件中每个对象是一行，或者是一个包含所有条目的数组
        try:
            # 尝试按数组格式读取
            all_entries = json.load(json_file)
            if not isinstance(all_entries, list):
                # 如果不是数组，可能是单个对象或每行一个JSON对象
                json_file.seek(0)
                all_entries = [json.loads(line.strip()) for line in json_file if line.strip()]
        except json.JSONDecodeError:
            # 如果解析失败，尝试按每行一个JSON对象处理
            json_file.seek(0)
            all_entries = [json.loads(line.strip()) for line in json_file if line.strip()]
    
    # 筛选出答案为"yes"的条目
    correct_indices = []
    for i, entry in enumerate(all_entries):
        if entry.get('answer', '').lower() == 'yes':
            correct_entries.append(entry)
            correct_indices.append(i)
    
    # 读取CSV文件并筛选出对应正确题目的打分
    correct_scores = []
    with open(csv_input_path, 'r', encoding='utf-8') as csv_file:
        csv_reader = csv.DictReader(csv_file)
        fieldnames = csv_reader.fieldnames
        
        # 遍历CSV行，收集正确题目的打分
        for i, row in enumerate(csv_reader):
            if i in correct_indices:
                correct_scores.append(row)
    
    # 将筛选出的正确题目写入新的JSON文件
    with open(json_output_path, 'w', encoding='utf-8') as json_out_file:
        json.dump(correct_entries, json_out_file, ensure_ascii=False, indent=2)
    
    # 将筛选出的正确题目的打分写入新的CSV文件
    with open(csv_output_path, 'w', encoding='utf-8', newline='') as csv_out_file:
        csv_writer = csv.DictWriter(csv_out_file, fieldnames=fieldnames)
        csv_writer.writeheader()
        csv_writer.writerows(correct_scores)
    
    print(f"处理完成！")
    print(f"正确的题目已保存到: {json_output_path}")
    print(f"对应的打分已保存到: {csv_output_path}")
    print(f"共筛选出 {len(correct_entries)} 个正确的题目")


    

def main():
    
    
    # # 输入文件路径
    # json_input = "/root/autodl-tmp/roscoe/ParlAI/projects/roscoe/MATH/clean/0919_dr_grpo_math/amc23.jsonl"    # 替换为你的JSON文件路径
    # csv_input = "/root/autodl-tmp/roscoe/ParlAI/projects/roscoe/MATH/output/0919_dr_grpo_math/all-mpnet-base-v2/scores_amc23.tsv"         # 替换为你的CSV文件路径
    
    # # 输出文件路径
    # json_output = "/root/autodl-tmp/roscoe/ParlAI/projects/roscoe/correct_questions.json"
    # csv_output = "/root/autodl-tmp/roscoe/ParlAI/projects/roscoe/correct_scores.csv"
    
    
    # 创建参数解析器
    parser = argparse.ArgumentParser(description='筛选正确的题目及其对应的打分')
    
    # 添加命令行参数
    parser.add_argument('--json-input', required=True, help='输入的JSON文件路径')
    parser.add_argument('--csv-input', required=True, help='输入的CSV文件路径')
    parser.add_argument('--json-output', required=True, help='输出的正确题目JSON文件路径')
    parser.add_argument('--csv-output', required=True, help='输出的正确题目打分CSV文件路径')
    
    # 解析参数
    args = parser.parse_args()
    
    # 执行筛选操作
    filter_correct_questions(
        args.json_input,
        args.csv_input,
        args.json_output,
        args.csv_output
    )

if __name__ == "__main__":
    main()