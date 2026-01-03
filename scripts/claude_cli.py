#!/usr/bin/env python3
"""
Claude CLI - 命令行交互工具

一个简单易用的 Claude API 命令行工具，支持：
- 交互式对话
- 单次问答
- 文件分析
- 代码审查
- 股票分析
"""

import os
import sys
import argparse
from pathlib import Path
from typing import Optional, List
import json

# 添加项目根目录到路径
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

try:
    from openai import OpenAI
except ImportError:
    print("❌ 错误：未安装 openai 库")
    print("请运行: pip install openai")
    sys.exit(1)


class ClaudeCLI:
    """Claude 命令行工具"""

    def __init__(self, model: str = "claude-sonnet-4-5"):
        """初始化 CLI"""
        self.api_key = os.getenv("OPENAI_API_KEY")
        self.base_url = os.getenv("OPENAI_BASE_URL")

        if not self.api_key or not self.base_url:
            print("❌ 错误：未配置 API Key 或 Base URL")
            print("请设置环境变量 OPENAI_API_KEY 和 OPENAI_BASE_URL")
            sys.exit(1)

        self.client = OpenAI(
            api_key=self.api_key,
            base_url=self.base_url
        )
        self.model = model
        self.conversation_history = []

    def chat(self, message: str, system_prompt: Optional[str] = None) -> str:
        """发送消息并获取回复"""
        messages = []

        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})

        messages.append({"role": "user", "content": message})

        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=messages,
                max_tokens=4096
            )
            return response.choices[0].message.content
        except Exception as e:
            return f"❌ 错误: {str(e)}"

    def chat_stream(self, message: str, system_prompt: Optional[str] = None):
        """流式对话"""
        messages = []

        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})

        messages.append({"role": "user", "content": message})

        try:
            stream = self.client.chat.completions.create(
                model=self.model,
                messages=messages,
                max_tokens=4096,
                stream=True
            )

            for chunk in stream:
                if chunk.choices[0].delta.content:
                    print(chunk.choices[0].delta.content, end="", flush=True)
            print()  # 换行

        except Exception as e:
            print(f"\n❌ 错误: {str(e)}")

    def interactive_mode(self):
        """交互式对话模式"""
        print("\n" + "="*60)
        print("Claude 交互式对话")
        print("="*60)
        print(f"模型: {self.model}")
        print("命令:")
        print("  /help    - 显示帮助")
        print("  /clear   - 清除对话历史")
        print("  /model   - 切换模型")
        print("  /save    - 保存对话")
        print("  /exit    - 退出")
        print("="*60 + "\n")

        while True:
            try:
                user_input = input("你: ").strip()

                if not user_input:
                    continue

                # 处理命令
                if user_input.startswith("/"):
                    if user_input == "/exit":
                        print("再见！")
                        break
                    elif user_input == "/help":
                        self._show_help()
                        continue
                    elif user_input == "/clear":
                        self.conversation_history = []
                        print("✅ 对话历史已清除")
                        continue
                    elif user_input == "/model":
                        self._switch_model()
                        continue
                    elif user_input == "/save":
                        self._save_conversation()
                        continue
                    else:
                        print("❌ 未知命令，输入 /help 查看帮助")
                        continue

                # 添加用户消息到历史
                self.conversation_history.append({
                    "role": "user",
                    "content": user_input
                })

                # 发送请求
                print("\nClaude: ", end="", flush=True)

                try:
                    stream = self.client.chat.completions.create(
                        model=self.model,
                        messages=self.conversation_history,
                        max_tokens=4096,
                        stream=True
                    )

                    assistant_message = ""
                    for chunk in stream:
                        if chunk.choices[0].delta.content:
                            content = chunk.choices[0].delta.content
                            print(content, end="", flush=True)
                            assistant_message += content

                    print("\n")

                    # 添加助手回复到历史
                    self.conversation_history.append({
                        "role": "assistant",
                        "content": assistant_message
                    })

                except Exception as e:
                    print(f"\n❌ 错误: {str(e)}\n")

            except KeyboardInterrupt:
                print("\n\n再见！")
                break
            except EOFError:
                print("\n\n再见！")
                break

    def _show_help(self):
        """显示帮助信息"""
        print("\n" + "="*60)
        print("帮助信息")
        print("="*60)
        print("命令:")
        print("  /help    - 显示此帮助信息")
        print("  /clear   - 清除对话历史")
        print("  /model   - 切换模型")
        print("  /save    - 保存对话到文件")
        print("  /exit    - 退出程序")
        print("\n提示:")
        print("  - 直接输入消息进行对话")
        print("  - 支持多轮对话，会保留上下文")
        print("  - 使用 Ctrl+C 或 /exit 退出")
        print("="*60 + "\n")

    def _switch_model(self):
        """切换模型"""
        print("\n可用模型:")
        models = [
            ("1", "claude-sonnet-4-5", "平衡性能（推荐）"),
            ("2", "claude-opus-4-5", "最强性能"),
            ("3", "claude-haiku-4-5", "快速响应")
        ]

        for num, model, desc in models:
            current = " (当前)" if model == self.model else ""
            print(f"  {num}. {model} - {desc}{current}")

        choice = input("\n选择模型 (1-3): ").strip()

        model_map = {
            "1": "claude-sonnet-4-5",
            "2": "claude-opus-4-5",
            "3": "claude-haiku-4-5"
        }

        if choice in model_map:
            self.model = model_map[choice]
            print(f"✅ 已切换到: {self.model}\n")
        else:
            print("❌ 无效选择\n")

    def _save_conversation(self):
        """保存对话到文件"""
        if not self.conversation_history:
            print("❌ 没有对话历史可保存\n")
            return

        filename = f"conversation_{Path.cwd().name}_{len(self.conversation_history)//2}.json"
        filepath = Path("conversations") / filename

        # 创建目录
        filepath.parent.mkdir(exist_ok=True)

        # 保存
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump({
                "model": self.model,
                "messages": self.conversation_history,
                "timestamp": str(Path(filepath).stat().st_mtime)
            }, f, ensure_ascii=False, indent=2)

        print(f"✅ 对话已保存到: {filepath}\n")

    def analyze_file(self, filepath: str, question: Optional[str] = None):
        """分析文件"""
        path = Path(filepath)

        if not path.exists():
            print(f"❌ 文件不存在: {filepath}")
            return

        # 读取文件内容
        try:
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception as e:
            print(f"❌ 读取文件失败: {e}")
            return

        # 构建提示
        if question:
            prompt = f"请分析以下文件并回答问题：\n\n问题：{question}\n\n文件内容：\n```\n{content}\n```"
        else:
            prompt = f"请分析以下文件：\n\n文件路径：{filepath}\n\n文件内容：\n```\n{content}\n```"

        print(f"\n📄 分析文件: {filepath}")
        print("="*60 + "\n")

        # 发送请求
        print("Claude: ", end="", flush=True)
        self.chat_stream(prompt)

    def review_code(self, filepath: str):
        """代码审查"""
        path = Path(filepath)

        if not path.exists():
            print(f"❌ 文件不存在: {filepath}")
            return

        # 读取代码
        try:
            with open(path, 'r', encoding='utf-8') as f:
                code = f.read()
        except Exception as e:
            print(f"❌ 读取文件失败: {e}")
            return

        # 构建提示
        prompt = f"""请对以下代码进行专业审查：

文件路径：{filepath}

代码内容：
```{path.suffix[1:]}
{code}
```

请从以下角度进行审查：
1. 代码质量和可读性
2. 潜在的 bug 和问题
3. 性能优化建议
4. 安全性问题
5. 最佳实践建议
"""

        print(f"\n🔍 代码审查: {filepath}")
        print("="*60 + "\n")

        system_prompt = "你是一个专业的代码审查专家，擅长发现代码问题并提供改进建议。"

        print("Claude: ", end="", flush=True)
        self.chat_stream(prompt, system_prompt=system_prompt)

    def analyze_stock(self, stock_code: str):
        """股票分析"""
        prompt = f"""请分析股票 {stock_code}，包括：

1. 基本信息（如果你知道的话）
2. 所属行业和行业地位
3. 主营业务
4. 近期表现
5. 投资建议

注意：请基于你的知识进行分析，如果需要实时数据，请说明。
"""

        print(f"\n📊 股票分析: {stock_code}")
        print("="*60 + "\n")

        system_prompt = "你是一个专业的股票分析师，擅长基本面分析和技术分析。"

        print("Claude: ", end="", flush=True)
        self.chat_stream(prompt, system_prompt=system_prompt)


def main():
    """主函数"""
    parser = argparse.ArgumentParser(
        description="Claude CLI - 命令行交互工具",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  # 交互式对话
  %(prog)s

  # 单次问答
  %(prog)s -q "什么是 Python 装饰器？"

  # 分析文件
  %(prog)s -f script.py

  # 代码审查
  %(prog)s -r script.py

  # 股票分析
  %(prog)s -s 600519

  # 使用不同模型
  %(prog)s -m opus -q "设计一个高并发系统"
        """
    )

    parser.add_argument(
        "-q", "--question",
        help="单次问答"
    )

    parser.add_argument(
        "-f", "--file",
        help="分析文件"
    )

    parser.add_argument(
        "-r", "--review",
        help="代码审查"
    )

    parser.add_argument(
        "-s", "--stock",
        help="股票分析"
    )

    parser.add_argument(
        "-m", "--model",
        choices=["sonnet", "opus", "haiku"],
        default="sonnet",
        help="选择模型 (默认: sonnet)"
    )

    parser.add_argument(
        "--stream",
        action="store_true",
        help="使用流式输出"
    )

    args = parser.parse_args()

    # 模型映射
    model_map = {
        "sonnet": "claude-sonnet-4-5",
        "opus": "claude-opus-4-5",
        "haiku": "claude-haiku-4-5"
    }

    model = model_map[args.model]

    # 创建 CLI 实例
    cli = ClaudeCLI(model=model)

    # 根据参数执行不同操作
    if args.question:
        # 单次问答
        print(f"\n问题: {args.question}")
        print("="*60 + "\n")
        print("Claude: ", end="", flush=True)

        if args.stream:
            cli.chat_stream(args.question)
        else:
            response = cli.chat(args.question)
            print(response)

    elif args.file:
        # 分析文件
        cli.analyze_file(args.file)

    elif args.review:
        # 代码审查
        cli.review_code(args.review)

    elif args.stock:
        # 股票分析
        cli.analyze_stock(args.stock)

    else:
        # 交互式模式
        cli.interactive_mode()


if __name__ == "__main__":
    main()
