"""
Claude API 使用示例集合

这个模块提供了在 TradingAgents-CN 项目中使用 Claude API 的各种示例。
包括基础调用、流式输出、对话管理、错误处理等。
"""

import os
import sys
from pathlib import Path
from typing import List, Dict, Optional, Generator
import json
import time
from datetime import datetime

# 添加项目根目录到路径
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

try:
    from openai import OpenAI, Stream
    from openai.types.chat import ChatCompletion, ChatCompletionChunk
except ImportError:
    print("❌ 错误：未安装 openai 库")
    print("请运行: pip install openai")
    sys.exit(1)


class ClaudeClient:
    """Claude API 客户端封装"""

    def __init__(
        self,
        api_key: Optional[str] = None,
        base_url: Optional[str] = None,
        model: str = "claude-sonnet-4-5",
        max_tokens: int = 4096,
        temperature: float = 0.7
    ):
        """
        初始化 Claude 客户端

        Args:
            api_key: API 密钥（默认从环境变量读取）
            base_url: API 基础 URL（默认从环境变量读取）
            model: 默认使用的模型
            max_tokens: 最大 token 数
            temperature: 温度参数（0-1，越高越随机）
        """
        self.api_key = api_key or os.getenv("OPENAI_API_KEY")
        self.base_url = base_url or os.getenv("OPENAI_BASE_URL")
        self.model = model
        self.max_tokens = max_tokens
        self.temperature = temperature

        if not self.api_key or not self.base_url:
            raise ValueError(
                "未配置 API Key 或 Base URL。"
                "请设置环境变量 OPENAI_API_KEY 和 OPENAI_BASE_URL"
            )

        self.client = OpenAI(
            api_key=self.api_key,
            base_url=self.base_url
        )

        # 统计信息
        self.total_tokens = 0
        self.total_requests = 0

    def chat(
        self,
        message: str,
        system_prompt: Optional[str] = None,
        model: Optional[str] = None,
        **kwargs
    ) -> str:
        """
        简单的对话接口

        Args:
            message: 用户消息
            system_prompt: 系统提示词（可选）
            model: 使用的模型（可选，默认使用初始化时的模型）
            **kwargs: 其他参数

        Returns:
            助手的回复内容
        """
        messages = []

        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})

        messages.append({"role": "user", "content": message})

        response = self.client.chat.completions.create(
            model=model or self.model,
            messages=messages,
            max_tokens=kwargs.get("max_tokens", self.max_tokens),
            temperature=kwargs.get("temperature", self.temperature),
            **{k: v for k, v in kwargs.items() if k not in ["max_tokens", "temperature"]}
        )

        # 更新统计
        self.total_tokens += response.usage.total_tokens
        self.total_requests += 1

        return response.choices[0].message.content

    def chat_stream(
        self,
        message: str,
        system_prompt: Optional[str] = None,
        model: Optional[str] = None,
        **kwargs
    ) -> Generator[str, None, None]:
        """
        流式对话接口

        Args:
            message: 用户消息
            system_prompt: 系统提示词（可选）
            model: 使用的模型（可选）
            **kwargs: 其他参数

        Yields:
            逐步生成的内容片段
        """
        messages = []

        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})

        messages.append({"role": "user", "content": message})

        stream = self.client.chat.completions.create(
            model=model or self.model,
            messages=messages,
            max_tokens=kwargs.get("max_tokens", self.max_tokens),
            temperature=kwargs.get("temperature", self.temperature),
            stream=True,
            **{k: v for k, v in kwargs.items() if k not in ["max_tokens", "temperature", "stream"]}
        )

        for chunk in stream:
            if chunk.choices[0].delta.content:
                yield chunk.choices[0].delta.content

        self.total_requests += 1

    def get_stats(self) -> Dict:
        """获取使用统计"""
        return {
            "total_requests": self.total_requests,
            "total_tokens": self.total_tokens,
            "average_tokens_per_request": (
                self.total_tokens / self.total_requests
                if self.total_requests > 0
                else 0
            )
        }


class ConversationManager:
    """对话历史管理器"""

    def __init__(
        self,
        client: ClaudeClient,
        system_prompt: Optional[str] = None,
        max_history: int = 20
    ):
        """
        初始化对话管理器

        Args:
            client: Claude 客户端
            system_prompt: 系统提示词
            max_history: 最大保留的对话轮数
        """
        self.client = client
        self.max_history = max_history
        self.messages: List[Dict[str, str]] = []

        if system_prompt:
            self.messages.append({"role": "system", "content": system_prompt})

    def add_message(self, role: str, content: str):
        """添加消息到历史"""
        self.messages.append({"role": role, "content": content})
        self._trim_history()

    def chat(self, message: str, **kwargs) -> str:
        """
        发送消息并获取回复

        Args:
            message: 用户消息
            **kwargs: 其他参数

        Returns:
            助手的回复
        """
        self.add_message("user", message)

        response = self.client.client.chat.completions.create(
            model=kwargs.get("model", self.client.model),
            messages=self.messages,
            max_tokens=kwargs.get("max_tokens", self.client.max_tokens),
            temperature=kwargs.get("temperature", self.client.temperature)
        )

        reply = response.choices[0].message.content
        self.add_message("assistant", reply)

        # 更新统计
        self.client.total_tokens += response.usage.total_tokens
        self.client.total_requests += 1

        return reply

    def _trim_history(self):
        """保持历史记录在限制内"""
        # 保留系统消息
        system_msgs = [m for m in self.messages if m["role"] == "system"]
        other_msgs = [m for m in self.messages if m["role"] != "system"]

        if len(other_msgs) > self.max_history:
            other_msgs = other_msgs[-self.max_history:]

        self.messages = system_msgs + other_msgs

    def clear_history(self):
        """清除对话历史（保留系统消息）"""
        system_msgs = [m for m in self.messages if m["role"] == "system"]
        self.messages = system_msgs

    def get_history(self) -> List[Dict[str, str]]:
        """获取对话历史"""
        return self.messages.copy()

    def save_history(self, filepath: str):
        """保存对话历史到文件"""
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump({
                "timestamp": datetime.now().isoformat(),
                "messages": self.messages
            }, f, ensure_ascii=False, indent=2)

    def load_history(self, filepath: str):
        """从文件加载对话历史"""
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
            self.messages = data["messages"]


# ==================== 示例函数 ====================

def example_basic_chat():
    """示例 1: 基础对话"""
    print("\n" + "="*60)
    print("示例 1: 基础对话")
    print("="*60 + "\n")

    client = ClaudeClient()

    # 简单问答
    response = client.chat("你好，请用一句话介绍你自己")
    print(f"回复: {response}\n")

    # 带系统提示词
    response = client.chat(
        "分析一下 Python 的优缺点",
        system_prompt="你是一个专业的编程语言分析师，请客观分析。"
    )
    print(f"回复: {response}\n")

    # 显示统计
    stats = client.get_stats()
    print(f"统计: {stats}")


def example_stream_chat():
    """示例 2: 流式输出"""
    print("\n" + "="*60)
    print("示例 2: 流式输出")
    print("="*60 + "\n")

    client = ClaudeClient()

    print("问题: 写一首关于编程的诗\n")
    print("回复: ", end="", flush=True)

    for chunk in client.chat_stream("写一首关于编程的诗"):
        print(chunk, end="", flush=True)

    print("\n")


def example_conversation():
    """示例 3: 多轮对话"""
    print("\n" + "="*60)
    print("示例 3: 多轮对话")
    print("="*60 + "\n")

    client = ClaudeClient()
    conv = ConversationManager(
        client,
        system_prompt="你是一个 Python 编程助手，擅长解答编程问题。"
    )

    # 第一轮
    print("用户: 什么是装饰器？")
    reply = conv.chat("什么是装饰器？")
    print(f"助手: {reply}\n")

    # 第二轮（带上下文）
    print("用户: 能给个例子吗？")
    reply = conv.chat("能给个例子吗？")
    print(f"助手: {reply}\n")

    # 第三轮
    print("用户: 装饰器有什么实际应用？")
    reply = conv.chat("装饰器有什么实际应用？")
    print(f"助手: {reply}\n")


def example_code_analysis():
    """示例 4: 代码分析"""
    print("\n" + "="*60)
    print("示例 4: 代码分析")
    print("="*60 + "\n")

    client = ClaudeClient(model="claude-sonnet-4-5")

    code = """
def fibonacci(n):
    if n <= 1:
        return n
    return fibonacci(n-1) + fibonacci(n-2)
"""

    response = client.chat(
        f"请分析这段代码的时间复杂度和空间复杂度，并提出优化建议：\n\n{code}",
        system_prompt="你是一个代码审查专家，请提供专业的分析和建议。"
    )

    print(f"分析结果:\n{response}\n")


def example_stock_analysis():
    """示例 5: 股票分析（适用于 TradingAgents-CN 项目）"""
    print("\n" + "="*60)
    print("示例 5: 股票分析")
    print("="*60 + "\n")

    client = ClaudeClient(model="claude-sonnet-4-5")

    # 模拟股票数据
    stock_data = {
        "code": "600519",
        "name": "贵州茅台",
        "price": 1680.50,
        "change": "+2.3%",
        "volume": "1.2M",
        "pe_ratio": 35.6,
        "pb_ratio": 12.8
    }

    prompt = f"""
请分析以下股票数据：

股票代码: {stock_data['code']}
股票名称: {stock_data['name']}
当前价格: {stock_data['price']}
涨跌幅: {stock_data['change']}
成交量: {stock_data['volume']}
市盈率: {stock_data['pe_ratio']}
市净率: {stock_data['pb_ratio']}

请从技术面和基本面两个角度进行简要分析。
"""

    response = client.chat(
        prompt,
        system_prompt="你是一个专业的股票分析师，擅长技术分析和基本面分析。"
    )

    print(f"分析结果:\n{response}\n")


def example_model_comparison():
    """示例 6: 不同模型对比"""
    print("\n" + "="*60)
    print("示例 6: 不同模型对比")
    print("="*60 + "\n")

    question = "用 Python 实现快速排序算法"

    models = [
        ("claude-haiku-4-5", "Haiku（快速）"),
        ("claude-sonnet-4-5", "Sonnet（平衡）"),
        ("claude-opus-4-5", "Opus（强大）")
    ]

    for model, name in models:
        print(f"\n--- {name} ---\n")

        client = ClaudeClient(model=model)
        start_time = time.time()

        response = client.chat(question, max_tokens=500)

        elapsed = time.time() - start_time

        print(f"回复: {response[:200]}...")
        print(f"\n耗时: {elapsed:.2f}秒")
        print(f"Token: {client.get_stats()['total_tokens']}")


def example_error_handling():
    """示例 7: 错误处理"""
    print("\n" + "="*60)
    print("示例 7: 错误处理")
    print("="*60 + "\n")

    from openai import OpenAIError

    client = ClaudeClient()

    # 正常请求
    try:
        response = client.chat("你好")
        print(f"✅ 正常请求成功: {response}\n")
    except OpenAIError as e:
        print(f"❌ API 错误: {e}\n")
    except Exception as e:
        print(f"❌ 未知错误: {e}\n")

    # 模拟错误（使用不存在的模型）
    try:
        print("尝试使用不存在的模型...")
        response = client.chat("你好", model="gpt-4")
        print(f"回复: {response}\n")
    except OpenAIError as e:
        print(f"❌ 预期的错误: {e}\n")
    except Exception as e:
        print(f"❌ 其他错误: {e}\n")


def example_batch_processing():
    """示例 8: 批量处理"""
    print("\n" + "="*60)
    print("示例 8: 批量处理")
    print("="*60 + "\n")

    client = ClaudeClient(model="claude-haiku-4-5")  # 使用快速模型

    questions = [
        "Python 中 list 和 tuple 的区别？",
        "什么是 GIL？",
        "解释一下装饰器的作用",
        "Python 中如何实现单例模式？"
    ]

    print("批量处理问题...\n")

    results = []
    for i, question in enumerate(questions, 1):
        print(f"[{i}/{len(questions)}] 处理: {question}")
        response = client.chat(question, max_tokens=200)
        results.append({
            "question": question,
            "answer": response
        })
        print(f"✅ 完成\n")

    # 显示结果
    print("\n" + "="*60)
    print("批量处理结果")
    print("="*60 + "\n")

    for i, result in enumerate(results, 1):
        print(f"{i}. {result['question']}")
        print(f"   回答: {result['answer'][:100]}...\n")

    # 显示统计
    stats = client.get_stats()
    print(f"总请求数: {stats['total_requests']}")
    print(f"总 Token: {stats['total_tokens']}")
    print(f"平均 Token: {stats['average_tokens_per_request']:.0f}")


# ==================== 主函数 ====================

def main():
    """运行所有示例"""
    print("\n" + "="*60)
    print("Claude API 使用示例集合")
    print("="*60)

    examples = [
        ("基础对话", example_basic_chat),
        ("流式输出", example_stream_chat),
        ("多轮对话", example_conversation),
        ("代码分析", example_code_analysis),
        ("股票分析", example_stock_analysis),
        ("模型对比", example_model_comparison),
        ("错误处理", example_error_handling),
        ("批量处理", example_batch_processing),
    ]

    print("\n可用示例：")
    for i, (name, _) in enumerate(examples, 1):
        print(f"  {i}. {name}")

    print("\n选择要运行的示例（输入数字，或 'all' 运行所有示例）：")
    choice = input("> ").strip()

    if choice.lower() == 'all':
        for name, func in examples:
            try:
                func()
            except Exception as e:
                print(f"\n❌ 示例 '{name}' 运行失败: {e}\n")
    elif choice.isdigit() and 1 <= int(choice) <= len(examples):
        name, func = examples[int(choice) - 1]
        try:
            func()
        except Exception as e:
            print(f"\n❌ 示例 '{name}' 运行失败: {e}\n")
    else:
        print("❌ 无效的选择")


if __name__ == "__main__":
    main()
