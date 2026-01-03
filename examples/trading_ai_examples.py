"""
Claude API 在 TradingAgents-CN 项目中的实际应用示例

这个模块展示了如何在股票分析、交易策略等场景中使用 Claude API。
"""

import os
import sys
from pathlib import Path
from typing import List, Dict, Optional
import json
from datetime import datetime, timedelta

# 添加项目根目录到路径
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

try:
    from openai import OpenAI
except ImportError:
    print("❌ 错误：未安装 openai 库")
    print("请运行: pip install openai")
    sys.exit(1)


class TradingAnalystAI:
    """AI 交易分析师 - 使用 Claude 进行股票分析"""

    def __init__(self, model: str = "claude-sonnet-4-5"):
        """
        初始化 AI 分析师

        Args:
            model: 使用的 Claude 模型
        """
        self.client = OpenAI(
            api_key=os.getenv("OPENAI_API_KEY"),
            base_url=os.getenv("OPENAI_BASE_URL")
        )
        self.model = model

        # 系统提示词
        self.system_prompt = """你是一个专业的股票分析师，具有以下特点：

1. 技术分析专家：精通各种技术指标（MA、MACD、RSI、BOLL等）
2. 基本面分析：能够分析财务数据、行业趋势、公司基本面
3. 风险管理：重视风险控制，提供合理的止损建议
4. 客观理性：基于数据分析，不做过度乐观或悲观的判断
5. 中文表达：使用简洁专业的中文进行分析

分析时请遵循以下原则：
- 先分析技术面，再分析基本面
- 明确指出支撑位和阻力位
- 给出具体的操作建议（买入/持有/卖出）
- 说明风险点和注意事项
- 保持客观，不做绝对性判断
"""

    def analyze_technical(
        self,
        stock_code: str,
        stock_name: str,
        technical_data: Dict
    ) -> str:
        """
        技术面分析

        Args:
            stock_code: 股票代码
            stock_name: 股票名称
            technical_data: 技术指标数据

        Returns:
            分析结果
        """
        prompt = f"""
请对以下股票进行技术面分析：

【基本信息】
股票代码: {stock_code}
股票名称: {stock_name}

【技术指标】
当前价格: {technical_data.get('price', 'N/A')}
涨跌幅: {technical_data.get('change_pct', 'N/A')}%
成交量: {technical_data.get('volume', 'N/A')}
换手率: {technical_data.get('turnover_rate', 'N/A')}%

【均线系统】
MA5: {technical_data.get('ma5', 'N/A')}
MA10: {technical_data.get('ma10', 'N/A')}
MA20: {technical_data.get('ma20', 'N/A')}
MA60: {technical_data.get('ma60', 'N/A')}

【技术指标】
MACD: {technical_data.get('macd', 'N/A')}
RSI: {technical_data.get('rsi', 'N/A')}
KDJ: {technical_data.get('kdj', 'N/A')}
BOLL: {technical_data.get('boll', 'N/A')}

请从以下角度进行分析：
1. 趋势判断（上升/下降/震荡）
2. 支撑位和阻力位
3. 买卖信号
4. 操作建议
5. 风险提示
"""

        response = self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": self.system_prompt},
                {"role": "user", "content": prompt}
            ],
            max_tokens=2000,
            temperature=0.3  # 较低温度，保持分析的一致性
        )

        return response.choices[0].message.content

    def analyze_fundamental(
        self,
        stock_code: str,
        stock_name: str,
        fundamental_data: Dict
    ) -> str:
        """
        基本面分析

        Args:
            stock_code: 股票代码
            stock_name: 股票名称
            fundamental_data: 基本面数据

        Returns:
            分析结果
        """
        prompt = f"""
请对以下股票进行基本面分析：

【基本信息】
股票代码: {stock_code}
股票名称: {stock_name}
所属行业: {fundamental_data.get('industry', 'N/A')}

【估值指标】
市盈率(PE): {fundamental_data.get('pe_ratio', 'N/A')}
市净率(PB): {fundamental_data.get('pb_ratio', 'N/A')}
市销率(PS): {fundamental_data.get('ps_ratio', 'N/A')}
总市值: {fundamental_data.get('market_cap', 'N/A')}亿元

【财务指标】
营业收入: {fundamental_data.get('revenue', 'N/A')}亿元
净利润: {fundamental_data.get('net_profit', 'N/A')}亿元
净利润增长率: {fundamental_data.get('profit_growth', 'N/A')}%
ROE: {fundamental_data.get('roe', 'N/A')}%
资产负债率: {fundamental_data.get('debt_ratio', 'N/A')}%

【现金流】
经营现金流: {fundamental_data.get('operating_cashflow', 'N/A')}亿元
自由现金流: {fundamental_data.get('free_cashflow', 'N/A')}亿元

请从以下角度进行分析：
1. 估值水平（高估/合理/低估）
2. 盈利能力
3. 成长性
4. 财务健康度
5. 投资价值评估
"""

        response = self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": self.system_prompt},
                {"role": "user", "content": prompt}
            ],
            max_tokens=2000,
            temperature=0.3
        )

        return response.choices[0].message.content

    def comprehensive_analysis(
        self,
        stock_code: str,
        stock_name: str,
        technical_data: Dict,
        fundamental_data: Dict
    ) -> Dict[str, str]:
        """
        综合分析（技术面 + 基本面）

        Args:
            stock_code: 股票代码
            stock_name: 股票名称
            technical_data: 技术指标数据
            fundamental_data: 基本面数据

        Returns:
            包含技术面、基本面和综合建议的分析结果
        """
        # 技术面分析
        print("📊 正在进行技术面分析...")
        technical_analysis = self.analyze_technical(
            stock_code, stock_name, technical_data
        )

        # 基本面分析
        print("📈 正在进行基本面分析...")
        fundamental_analysis = self.analyze_fundamental(
            stock_code, stock_name, fundamental_data
        )

        # 综合建议
        print("🎯 正在生成综合建议...")
        synthesis_prompt = f"""
基于以下技术面和基本面分析，请给出综合投资建议：

【技术面分析】
{technical_analysis}

【基本面分析】
{fundamental_analysis}

请提供：
1. 综合评分（1-10分）
2. 投资建议（强烈买入/买入/持有/卖出/强烈卖出）
3. 目标价位
4. 止损价位
5. 持仓建议（建议仓位比例）
6. 风险等级（低/中/高）
7. 关键风险点
"""

        response = self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": self.system_prompt},
                {"role": "user", "content": synthesis_prompt}
            ],
            max_tokens=1500,
            temperature=0.3
        )

        synthesis = response.choices[0].message.content

        return {
            "technical_analysis": technical_analysis,
            "fundamental_analysis": fundamental_analysis,
            "synthesis": synthesis,
            "timestamp": datetime.now().isoformat()
        }

    def compare_stocks(
        self,
        stocks_data: List[Dict]
    ) -> str:
        """
        对比多只股票

        Args:
            stocks_data: 股票数据列表，每个元素包含股票的基本信息和指标

        Returns:
            对比分析结果
        """
        stocks_info = []
        for stock in stocks_data:
            info = f"""
股票代码: {stock['code']}
股票名称: {stock['name']}
当前价格: {stock.get('price', 'N/A')}
涨跌幅: {stock.get('change_pct', 'N/A')}%
市盈率: {stock.get('pe_ratio', 'N/A')}
市净率: {stock.get('pb_ratio', 'N/A')}
ROE: {stock.get('roe', 'N/A')}%
"""
            stocks_info.append(info)

        prompt = f"""
请对比分析以下股票，并给出投资优先级排序：

{chr(10).join(stocks_info)}

请从以下角度进行对比：
1. 估值水平对比
2. 盈利能力对比
3. 成长性对比
4. 风险水平对比
5. 投资优先级排序（从高到低）
6. 每只股票的优缺点
"""

        response = self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": self.system_prompt},
                {"role": "user", "content": prompt}
            ],
            max_tokens=2500,
            temperature=0.3
        )

        return response.choices[0].message.content

    def generate_trading_strategy(
        self,
        market_condition: str,
        risk_preference: str,
        capital: float,
        holding_period: str
    ) -> str:
        """
        生成交易策略

        Args:
            market_condition: 市场状况（牛市/熊市/震荡市）
            risk_preference: 风险偏好（保守/稳健/激进）
            capital: 可用资金（万元）
            holding_period: 持仓周期（短期/中期/长期）

        Returns:
            交易策略建议
        """
        prompt = f"""
请根据以下条件制定交易策略：

【市场环境】
当前市场状况: {market_condition}

【投资者情况】
风险偏好: {risk_preference}
可用资金: {capital}万元
持仓周期: {holding_period}

请提供：
1. 资产配置建议（股票/债券/现金比例）
2. 行业配置建议
3. 个股选择标准
4. 仓位管理策略
5. 止盈止损策略
6. 风险控制措施
7. 具体操作步骤
"""

        response = self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": self.system_prompt},
                {"role": "user", "content": prompt}
            ],
            max_tokens=2500,
            temperature=0.5
        )

        return response.choices[0].message.content


class NewsAnalyzerAI:
    """AI 新闻分析师 - 分析新闻对股票的影响"""

    def __init__(self, model: str = "claude-sonnet-4-5"):
        self.client = OpenAI(
            api_key=os.getenv("OPENAI_API_KEY"),
            base_url=os.getenv("OPENAI_BASE_URL")
        )
        self.model = model

        self.system_prompt = """你是一个专业的财经新闻分析师，擅长：

1. 快速提取新闻关键信息
2. 分析新闻对股票的影响（利好/利空/中性）
3. 评估影响程度和持续时间
4. 给出投资建议

分析时请保持客观理性，基于事实进行判断。
"""

    def analyze_news(
        self,
        news_title: str,
        news_content: str,
        stock_code: str,
        stock_name: str
    ) -> Dict:
        """
        分析新闻对股票的影响

        Args:
            news_title: 新闻标题
            news_content: 新闻内容
            stock_code: 股票代码
            stock_name: 股票名称

        Returns:
            分析结果
        """
        prompt = f"""
请分析以下新闻对股票的影响：

【股票信息】
股票代码: {stock_code}
股票名称: {stock_name}

【新闻标题】
{news_title}

【新闻内容】
{news_content}

请提供：
1. 新闻摘要（50字以内）
2. 影响性质（利好/利空/中性）
3. 影响程度（重大/一般/轻微）
4. 影响时效（短期/中期/长期）
5. 关键影响因素
6. 投资建议
7. 风险提示

请以 JSON 格式返回结果。
"""

        response = self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": self.system_prompt},
                {"role": "user", "content": prompt}
            ],
            max_tokens=1500,
            temperature=0.3
        )

        return {
            "analysis": response.choices[0].message.content,
            "timestamp": datetime.now().isoformat()
        }

    def batch_analyze_news(
        self,
        news_list: List[Dict],
        stock_code: str,
        stock_name: str
    ) -> List[Dict]:
        """
        批量分析多条新闻

        Args:
            news_list: 新闻列表
            stock_code: 股票代码
            stock_name: 股票名称

        Returns:
            分析结果列表
        """
        results = []

        for i, news in enumerate(news_list, 1):
            print(f"[{i}/{len(news_list)}] 分析新闻: {news['title'][:30]}...")

            result = self.analyze_news(
                news['title'],
                news['content'],
                stock_code,
                stock_name
            )

            results.append({
                "news": news,
                "analysis": result
            })

        return results


# ==================== 示例函数 ====================

def example_technical_analysis():
    """示例：技术面分析"""
    print("\n" + "="*60)
    print("示例：技术面分析")
    print("="*60 + "\n")

    analyst = TradingAnalystAI()

    # 模拟技术数据
    technical_data = {
        "price": 1680.50,
        "change_pct": 2.3,
        "volume": "1.2M",
        "turnover_rate": 0.8,
        "ma5": 1650.20,
        "ma10": 1620.30,
        "ma20": 1580.50,
        "ma60": 1520.80,
        "macd": "金叉",
        "rsi": 65.5,
        "kdj": "K:75, D:68, J:82",
        "boll": "上轨:1720, 中轨:1650, 下轨:1580"
    }

    result = analyst.analyze_technical(
        stock_code="600519",
        stock_name="贵州茅台",
        technical_data=technical_data
    )

    print(result)


def example_fundamental_analysis():
    """示例：基本面分析"""
    print("\n" + "="*60)
    print("示例：基本面分析")
    print("="*60 + "\n")

    analyst = TradingAnalystAI()

    # 模拟基本面数据
    fundamental_data = {
        "industry": "白酒",
        "pe_ratio": 35.6,
        "pb_ratio": 12.8,
        "ps_ratio": 15.2,
        "market_cap": 21000,
        "revenue": 1200,
        "net_profit": 580,
        "profit_growth": 18.5,
        "roe": 32.5,
        "debt_ratio": 15.8,
        "operating_cashflow": 650,
        "free_cashflow": 520
    }

    result = analyst.analyze_fundamental(
        stock_code="600519",
        stock_name="贵州茅台",
        fundamental_data=fundamental_data
    )

    print(result)


def example_comprehensive_analysis():
    """示例：综合分析"""
    print("\n" + "="*60)
    print("示例：综合分析（技术面 + 基本面）")
    print("="*60 + "\n")

    analyst = TradingAnalystAI()

    technical_data = {
        "price": 1680.50,
        "change_pct": 2.3,
        "volume": "1.2M",
        "turnover_rate": 0.8,
        "ma5": 1650.20,
        "ma10": 1620.30,
        "ma20": 1580.50,
        "ma60": 1520.80,
        "macd": "金叉",
        "rsi": 65.5,
        "kdj": "K:75, D:68, J:82",
        "boll": "上轨:1720, 中轨:1650, 下轨:1580"
    }

    fundamental_data = {
        "industry": "白酒",
        "pe_ratio": 35.6,
        "pb_ratio": 12.8,
        "ps_ratio": 15.2,
        "market_cap": 21000,
        "revenue": 1200,
        "net_profit": 580,
        "profit_growth": 18.5,
        "roe": 32.5,
        "debt_ratio": 15.8,
        "operating_cashflow": 650,
        "free_cashflow": 520
    }

    result = analyst.comprehensive_analysis(
        stock_code="600519",
        stock_name="贵州茅台",
        technical_data=technical_data,
        fundamental_data=fundamental_data
    )

    print("\n【技术面分析】")
    print("="*60)
    print(result["technical_analysis"])

    print("\n【基本面分析】")
    print("="*60)
    print(result["fundamental_analysis"])

    print("\n【综合建议】")
    print("="*60)
    print(result["synthesis"])


def example_stock_comparison():
    """示例：股票对比"""
    print("\n" + "="*60)
    print("示例：股票对比分析")
    print("="*60 + "\n")

    analyst = TradingAnalystAI()

    stocks_data = [
        {
            "code": "600519",
            "name": "贵州茅台",
            "price": 1680.50,
            "change_pct": 2.3,
            "pe_ratio": 35.6,
            "pb_ratio": 12.8,
            "roe": 32.5
        },
        {
            "code": "000858",
            "name": "五粮液",
            "price": 168.50,
            "change_pct": 1.8,
            "pe_ratio": 28.5,
            "pb_ratio": 8.5,
            "roe": 28.3
        },
        {
            "code": "000568",
            "name": "泸州老窖",
            "price": 198.30,
            "change_pct": 3.2,
            "pe_ratio": 32.8,
            "pb_ratio": 10.2,
            "roe": 30.5
        }
    ]

    result = analyst.compare_stocks(stocks_data)
    print(result)


def example_trading_strategy():
    """示例：生成交易策略"""
    print("\n" + "="*60)
    print("示例：生成交易策略")
    print("="*60 + "\n")

    analyst = TradingAnalystAI()

    result = analyst.generate_trading_strategy(
        market_condition="震荡市",
        risk_preference="稳健",
        capital=50,
        holding_period="中期"
    )

    print(result)


def example_news_analysis():
    """示例：新闻分析"""
    print("\n" + "="*60)
    print("示例：新闻影响分析")
    print("="*60 + "\n")

    analyzer = NewsAnalyzerAI()

    news_title = "贵州茅台发布2024年度业绩预告，净利润同比增长18%"
    news_content = """
贵州茅台酒股份有限公司今日发布2024年度业绩预告，预计全年实现营业收入约1200亿元，
同比增长15%；净利润约580亿元，同比增长18%。公司表示，业绩增长主要得益于：
1. 高端白酒市场需求持续旺盛
2. 产品结构优化，高端产品占比提升
3. 渠道管理加强，经销商库存健康
4. 品牌价值持续提升

公司同时宣布，将继续坚持稳健经营策略，保持产品价格稳定，加强品牌建设。
"""

    result = analyzer.analyze_news(
        news_title=news_title,
        news_content=news_content,
        stock_code="600519",
        stock_name="贵州茅台"
    )

    print(result["analysis"])


def main():
    """运行示例"""
    print("\n" + "="*60)
    print("Claude API 在 TradingAgents-CN 中的应用示例")
    print("="*60)

    examples = [
        ("技术面分析", example_technical_analysis),
        ("基本面分析", example_fundamental_analysis),
        ("综合分析", example_comprehensive_analysis),
        ("股票对比", example_stock_comparison),
        ("交易策略", example_trading_strategy),
        ("新闻分析", example_news_analysis),
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
                input("\n按 Enter 继续...")
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
