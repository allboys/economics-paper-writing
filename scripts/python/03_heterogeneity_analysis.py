"""
==============================================================================
异质性分析模板
文件名: 03_heterogeneity_analysis.py
用途: 经济学论文异质性分析

基于 pandas 和 statsmodels
使用前请确保安装: pip install pandas statsmodels scipy openpyxl
==============================================================================
"""

import pandas as pd
import numpy as np
import statsmodels.formula.api as smf
from scipy import stats
import warnings
warnings.filterwarnings('ignore')

# ========== 1. 设置路径 ==========
DATA_DIR = r"C:\Users\22907\economics-paper-writing\data\cleaned"
OUTPUT_DIR = r"C:\Users\22907\economics-paper-writing\data\output"

# ========== 2. 读取数据 ==========
df = pd.read_csv(f"{DATA_DIR}\\your_data.csv")

# 定义变量
depvar = "ln_gdp"
indepvar = "human_capital"
controls = ["ln_capital", "industry", "digital", "urbanization"]
fixed_effects = ["year", "province"]

# ========== 3. 分组异质性分析 ==========
def run_regression(data, depvar, indepvar, controls, fixed_effects):
    """运行回归分析"""
    formula = f"{depvar} ~ {indepvar} + " + " + ".join(controls)

    # 添加固定效应
    for fe in fixed_effects:
        if fe in data.columns:
            formula += f" + C({fe})"

    model = smf.ols(formula, data=data).fit(cov_type='cluster',
                                            cov_kwds={'groups': data['province']})
    return model

# 按地区分组
regions = df['region'].unique()

print("=" * 60)
print("异质性分析结果：按地区分组")
print("=" * 60)

results = {}
for region in regions:
    subset = df[df['region'] == region].copy()
    model = run_regression(subset, depvar, indepvar, controls, fixed_effects)
    results[region] = {
        'coef': model.params[indepvar],
        'se': model.bse[indepvar],
        'pvalue': model.pvalues[indepvar],
        'n': len(subset),
        'r2': model.rsquared
    }
    print(f"\n{region}:")
    print(f"  系数: {model.params[indepvar]:.4f}")
    print(f"  标准误: {model.bse[indepvar]:.4f}")
    print(f"  p值: {model.pvalues[indepvar]:.4f}")
    print(f"  样本量: {len(subset)}")

# ========== 4. 组间系数差异检验 ==========
def test_coef_difference(group1_data, group2_data, indepvar, depvar, controls, fixed_effects):
    """检验两组系数是否存在显著差异"""

    model1 = run_regression(group1_data, depvar, indepvar, controls, fixed_effects)
    model2 = run_regression(group2_data, depvar, indepvar, controls, fixed_effects)

    # 计算系数差异的标准误
    se_diff = np.sqrt(model1.bse[indepvar]**2 + model2.bse[indepvar]**2)
    coef_diff = model1.params[indepvar] - model2.params[indepvar]

    # t统计量
    t_stat = coef_diff / se_diff
    p_value = 2 * (1 - stats.t.cdf(abs(t_stat), df=len(group1_data) + len(group2_data) - 4))

    return {
        'coef1': model1.params[indepvar],
        'coef2': model2.params[indepvar],
        'diff': coef_diff,
        'se_diff': se_diff,
        't_stat': t_stat,
        'p_value': p_value
    }

# 东部分组
east_data = df[df['region'].isin(['东部沿海', '东部其他'])]
west_data = df[df['region'].isin(['中部', '西部'])]

test_result = test_coef_difference(east_data, west_data, indepvar, depvar, controls, fixed_effects)

print("\n" + "=" * 60)
print("组间系数差异检验（东部 vs 中西部）")
print("=" * 60)
print(f"东部系数: {test_result['coef1']:.4f}")
print(f"中西部系数: {test_result['coef2']:.4f}")
print(f"系数差异: {test_result['diff']:.4f}")
print(f"差异标准误: {test_result['se_diff']:.4f}")
print(f"t统计量: {test_result['t_stat']:.4f}")
print(f"p值: {test_result['p_value']:.4f}")

if test_result['p_value'] < 0.05:
    print("结论: 组间系数存在显著差异 (p < 0.05)")
else:
    print("结论: 组间系数不存在显著差异 (p >= 0.05)")

# ========== 5. 分位数回归 ==========
from statsmodels.regression.quantile_regression import QuantReg

print("\n" + "=" * 60)
print("分位数回归分析")
print("=" * 60)

quantiles = [0.25, 0.50, 0.75]
quantile_results = {}

for q in quantiles:
    formula = f"{depvar} ~ {indepvar} + " + " + ".join(controls)

    model = QuantReg.from_formula(formula, data=df).fit(q=q)

    coef = model.params[indepvar]
    se = model.bse[indepvar]

    quantile_results[q] = {'coef': coef, 'se': se, 'pvalue': model.pvalues[indepvar]}

    print(f"\n{q*100:.0f}%分位数:")
    print(f"  系数: {coef:.4f}")
    print(f"  标准误: {se:.4f}")

# ========== 6. 交互项分析 ==========
print("\n" + "=" * 60)
print("交互项分析")
print("=" * 60)

# 创建交互项
df['human_x_digital'] = df[indepvar] * df['digital']

formula_interact = f"{depvar} ~ {indepvar} * digital + " + " + ".join(controls) + " + C(year) + C(province)"
model_interact = smf.ols(formula_interact, data=df).fit(cov_type='cluster',
                                                        cov_kwds={'groups': df['province']})

print("\n交互项回归结果:")
print(f"  {indepvar}主效应: {model_interact.params[indepvar]:.4f}")
print(f"  digital主效应: {model_interact.params['digital']:.4f}")
print(f"  交互项系数: {model_interact.params['human_x_digital:digital']:.4f}")
print(f"  交互项p值: {model_interact.pvalues['human_x_digital:digital']:.4f}")

# ========== 7. 保存结果 ==========
results_df = pd.DataFrame(results).T
results_df.to_csv(f"{OUTPUT_DIR}\\heterogeneity_results.csv", index_label='region')

print("\n" + "=" * 60)
print(f"结果已保存到: {OUTPUT_DIR}\\heterogeneity_results.csv")
print("=" * 60)