import json
import argparse
import os

def remove_hypothesis(input_file, output_file):
    """
    读取JSONL文件，删除每行中的"hypothesis"字段，并写入新文件
    
    参数:
        input_file: 输入的JSONL文件路径
        output_file: 输出的JSONL文件路径
    """
    try:
        with open(input_file, 'r', encoding='utf-8') as f_in, \
             open(output_file, 'w', encoding='utf-8') as f_out:
            
            line_count = 0
            for line in f_in:
                line_count += 1
                # 尝试解析JSON
                try:
                    data = json.loads(line.strip())
                    
                    # 如果存在"hypothesis"字段则删除
                    if "hypothesis" in data:
                        del data["hypothesis"]
                    
                    # 将处理后的数据写入输出文件
                    json.dump(data, f_out, ensure_ascii=False)
                    f_out.write('\n')
                    
                except json.JSONDecodeError as e:
                    print(f"警告: 第{line_count}行不是有效的JSON，已跳过。错误: {str(e)}")
                except Exception as e:
                    print(f"警告: 处理第{line_count}行时出错，已跳过。错误: {str(e)}")
            
            print(f"处理完成！共处理了{line_count}行，结果已保存到{os.path.abspath(output_file)}")
            
    except FileNotFoundError:
        print(f"错误: 找不到文件 {input_file}")
    except PermissionError:
        print(f"错误: 没有权限访问文件，请检查文件权限")
    except Exception as e:
        print(f"处理文件时发生错误: {str(e)}")

if __name__ == "__main__":
    
    input_file = "/root/autodl-tmp/roscoe/ParlAI/projects/roscoe/MATH/generated/oldgsm8k.json"
    output_file = "/root/autodl-tmp/roscoe/ParlAI/projects/roscoe/MATH/generated/gsm8k.json"
    # 设置命令行参数
    parser = argparse.ArgumentParser(description='删除JSONL文件中每行的"hypothesis"字段')
    # 添加默认值：当前目录下的input.jsonl和output.jsonl
    parser.add_argument('input', nargs='?', default=input_file, 
                      help='输入的JSONL文件路径（默认: input.jsonl）')
    parser.add_argument('output', nargs='?', default=output_file,
                      help='输出的JSONL文件路径（默认: output.jsonl）')
    
    args = parser.parse_args()
    
    # 调用函数处理文件
    remove_hypothesis(args.input, args.output)
