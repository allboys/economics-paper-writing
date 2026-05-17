# Economics Paper Writing

经济学论文写作与研究资源库，为经济学研究者提供从选题到发表的完整工作流支持。

## 目录结构

```
economics-paper-writing/
├── papers/              # 论文草稿与终稿
│   ├── working/        # 工作论文
│   ├── draft/          # 草稿版本
│   └── final/          # 定稿
├── data/               # 数据集
│   ├── raw/            # 原始数据
│   ├── cleaned/        # 清洗后数据
│   └── output/         # 回归结果
├── figures/            # 图表
│   ├── raw/            # 源文件
│   └── export/         # 导出版本
├── references/         # 文献库
│   ├── pdf/            # PDF全文
│   └── notes/          # 文献笔记
├── templates/          # 论文模板
│   ├── latex/          # LaTeX模板
│   ├── markdown/       # Markdown模板
│   └── checklists/     # 投稿检查清单
├── scripts/            # 分析脚本
│   ├── stata/          # Stata do文件
│   ├── python/         # Python脚本
│   └── r/              # R脚本
├── notes/              # 研究笔记
│   ├── ideas/          # 研究灵感
│   ├── reading/        # 读书笔记
│   └── meetings/       # 会议纪要
└── docs/               # 项目文档
```

## 核心功能

| 模块 | 说明 |
|------|------|
| **论文模板** | AER、QJE、JPE等主流期刊LaTeX模板 |
| **数据分析** | Stata/Python/R回归模板、结果输出 |
| **文献管理** | 文献笔记模板、引用追踪表 |
| **图表生成** | 经济学图表代码（回归表、双变量图等） |
| **检查清单** | 投稿前检查、格式核对 |

## 推荐资源

### 数据库

| 数据库 | 说明 |
|--------|------|
| [World Development Indicators](https://data.worldbank.org/) | 全球发展指标 |
| [UN Comtrade](https://comtrade.un.org/) | 国际贸易数据 |
| [CHNS](http://www.cpc.unc.edu/china) | 中国健康营养调查 |
| [CFPS](https://opendata.pku.edu.cn/) | 中国家庭追踪调查 |
| [CHARLS](http://charls.pku.edu.cn/) | 中国健康与养老追踪 |
| [CGSS](http://cgss.ruc.edu.cn/) | 中国综合社会调查 |
| [CNKI](https://www.cnki.net/) | 中国知网 |
| [NLS](https://www.nlsinfo.org/) | 全国追踪调查 |

### 工作论文与预印本

| 资源 | 说明 |
|------|------|
| [NBER](https://www.nber.org/papers) | 美国经济研究局工作论文 |
| [SSRN Economics](https://www.ssrn.com/en-us/aecon) | 经济学预印本 |
| [CEPR Discussion Papers](https://cepr.org/conference-discussion-papers) | CEPR讨论论文 |
| [VoxEU/CEPR](https://voxeu.org/) | 政策讨论 |

### 经济学期刊

| 期刊 | JEL分类 |
|------|---------|
| American Economic Review (AER) | A |
| Quarterly Journal of Economics (QJE) | A |
| Journal of Political Economy (JPE) | A |
| Econometrica | C |
| Review of Economic Studies | C |
| Journal of Economic Literature (JEL) | Z |
| Journal of Economic Perspectives (JEP) | Z |
| *Games and Economic Behavior* | C7, D8 |
| *Journal of Development Economics* | O1, O2 |
| *Review of Economics and Statistics* | C |
| *Journal of Econometrics* | C |
| *European Economic Review* | E |

### 计量经济学工具

- [Stata](https://www.stata.com/) - 面板数据、双差分、工具变量
- [R](https://www.r-project.org/) - 因果推断、机器学习
- [Python](https://www.python.org/) - 数据处理、文本分析
- [Julia](https://julialang.org/) - 数值计算

## 使用说明

### 论文模板

```bash
# 复制AER模板
cp templates/latex/aer_article.tex papers/working/my_paper.tex
```

### 数据分析

```stata
// 运行基准回归
do scripts/stata/01_baseline_regression.do
```

## 贡献

欢迎提交模板和脚本。请确保代码有注释，格式规范。