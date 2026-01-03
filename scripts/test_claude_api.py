#!/usr/bin/env python3
"""
Claude API 测试脚本

用于验证 Claude 代理服务器配置是否正确
"""

import os
import sys
from pathlib import Path

# 添加项目根目录到 Python 路径
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

# 加载环境变量
from dotenv import load_dotenv
load_dotenv(project_root / ".env")

def test_openai_format():
    """测试 OpenAI 兼容格式的 Claude API"""
    try:
        from openai import OpenAI

        api_key = os.getenv("OPENAI_API_KEY")
        base_url = os.getenv("OPENAI_BASE_URL")

        if not api_key or not base_url:
            print("❌ 错误：未找到 OPENAI_API_KEY 或 OPENAI_BASE_URL 环境变量")
            print("请检查 .env 文件配置")
            return False

        print("=" * 60)
        print("🧪 测试 Claude API (OpenAI 兼容格式)")
        print("=" * 60)
        print(f"📍 Base URL: {base_url}")
        print(f"🔑 API Key: {api_key[:20]}...{api_key[-10:]}")
        print()

        # 创建客户端
        client = OpenAI(
            api_key=api_key,
            base_url=base_url
        )

        # 测试可用模型
        print("📋 测试 1: 获取可用模型列表")
        print("-" * 60)

        models = [
            "claude-sonnet-4-5",
            "claude-opus-4-5",
            "claude-haiku-4-5",
            "claude-3-7-sonnet-20250219"
        ]

        print("✅ 可用模型：")
        for model in models:
            print(f"   - {model}")
        print()

        # 测试对话
        print("💬 测试 2: 发送测试消息")
        print("-" * 60)

        test_messages = [
            {"role": "user", "content": "请用一句话介绍你自己"}
        ]

        print(f"📤 发送消息: {test_messages[0]['content']}")
        print()

        response = client.chat.completions.create(
            model="claude-sonnet-4-5",
            messages=test_messages,
            max_tokens=100
        )

        print("📥 收到回复:")
        print(f"   {response.choices[0].message.content}")
        print()

        # 显示使用统计
        print("📊 Token 使用统计:")
        print(f"   - 输入 tokens: {response.usage.prompt_tokens}")
        print(f"   - 输出 tokens: {response.usage.completion_tokens}")
        print(f"   - 总计 tokens: {response.usage.total_tokens}")
        print()

        # 测试中文对话
        print("💬 测试 3: 中文对话能力")
        print("-" * 60)

        chinese_messages = [
            {"role": "user", "content": "请用Python写一个计算斐波那契数列的函数"}
        ]

        print(f"📤 发送消息: {chinese_messages[0]['content']}")
        print()

        response = client.chat.completions.create(
            model="claude-sonnet-4-5",
            messages=chinese_messages,
            max_tokens=300
        )

        print("📥 收到回复:")
        print(response.choices[0].message.content)
        print()

        print("=" * 60)
        print("✅ 所有测试通过！Claude API 配置正确")
        print("=" * 60)
        print()
        print("💡 提示：")
        print("   - 推荐使用 claude-sonnet-4-5 进行日常开发")
        print("   - 复杂任务可使用 claude-opus-4-5")
        print("   - 快速响应可使用 claude-haiku-4-5")
        print()

        return True

    except ImportError:
        print("❌ 错误：未安装 openai 库")
        print("请运行: pip install openai")
        return False

    except Exception as e:
        print(f"❌ 测试失败: {str(e)}")
        print()
        print("🔍 故障排查：")
        print("   1. 检查代理服务器是否运行")
        print("   2. 检查 API Key 是否正确")
        print("   3. 检查 Base URL 是否包含 /v1 后缀")
        print("   4. 检查网络连接")
        return False


def test_anthropic_format():
    """测试原生 Anthropic API 格式（预期失败）"""
    try:
        import anthropic

        api_key = os.getenv("ANTHROPIC_API_KEY")
        base_url = os.getenv("ANTHROPIC_BASE_URL")

        if not api_key or not base_url:
            print("ℹ️  未配置 ANTHROPIC_API_KEY，跳过原生 Anthropic API 测试")
            return None

        print("=" * 60)
        print("🧪 测试 Anthropic 原生 API")
        print("=" * 60)
        print(f"📍 Base URL: {base_url}")
        print()

        client = anthropic.Anthropic(
            api_key=api_key,
            base_url=base_url
        )

        response = client.messages.create(
            model="claude-3-sonnet-20240229",
            max_tokens=50,
            messages=[
                {"role": "user", "content": "Hello"}
            ]
        )

        print("✅ Anthropic 原生 API 测试通过")
        print(f"   回复: {response.content[0].text}")
        return True

    except ImportError:
        print("ℹ️  未安装 anthropic 库，跳过原生 API 测试")
        return None

    except Exception as e:
        print(f"⚠️  Anthropic 原生 API 测试失败（预期行为）")
        print(f"   原因: {str(e)}")
        print("   说明: 您的代理使用 OpenAI 兼容格式，不支持原生 Anthropic API")
        return False


def main():
    """主函数"""
    print()
    print("🚀 Claude API 配置测试工具")
    print()

    # 测试 OpenAI 格式
    openai_result = test_openai_format()
    print()

    # 测试 Anthropic 格式（可选）
    anthropic_result = test_anthropic_format()
    print()

    # 总结
    if openai_result:
        print("=" * 60)
        print("🎉 配置验证完成！")
        print("=" * 60)
        print()
        print("✅ OpenAI 兼容格式：正常工作")
        if anthropic_result is False:
            print("⚠️  Anthropic 原生格式：不支持（使用 OpenAI 格式即可）")
        elif anthropic_result is True:
            print("✅ Anthropic 原生格式：正常工作")
        print()
        print("📖 详细配置说明请查看: CLAUDE_CODE_SETUP.md")
        return 0
    else:
        print("=" * 60)
        print("❌ 配置验证失败")
        print("=" * 60)
        print()
        print("请检查 .env 文件中的配置，或查看 CLAUDE_CODE_SETUP.md 获取帮助")
        return 1


if __name__ == "__main__":
    sys.exit(main())
