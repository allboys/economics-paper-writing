"""
==============================================================================
数据清洗与预处理
文件名: 01_data_cleaning.py
用途: 经济学论文数据清洗

支持格式: CSV, Excel, Stata (.dta), SPSS (.sav)
==============================================================================
"""

import pandas as pd
import numpy as np
import warnings
warnings.filterwarnings('ignore')

# ========== 1. 设置路径 ==========
DATA_DIR = r"C:\Users\22907\economics-paper-writing\data\raw"
CLEAN_DIR = r"C:\Users\22907\economics-paper-writing\data\cleaned"

# ========== 2. 读取数据 ==========
def load_data(filepath, format='csv'):
    """读取原始数据"""
    if format == 'csv':
        df = pd.read_csv(filepath, encoding='utf-8-sig')
    elif format == 'excel':
        df = pd.read_excel(filepath)
    elif format == 'dta':
        df = pd.read_stata(filepath)
    elif format == 'spss':
        df = pd.read_spss(filepath)
    else:
        raise ValueError(f"不支持的格式: {format}")

    print(f"数据加载成功: {df.shape[0]} 行, {df.shape[1]} 列")
    return df

# ========== 3. 数据概览 ==========
def data_overview(df):
    """生成数据概览报告"""
    print("\n" + "="*60)
    print("数据概览")
    print("="*60)

    print(f"\n行数: {df.shape[0]}")
    print(f"列数: {df.shape[1]}")

    print("\n数据类型:")
    print(df.dtypes)

    print("\n缺失值情况:")
    missing = df.isnull().sum()
    missing_pct = (missing / len(df) * 100).round(2)
    missing_df = pd.DataFrame({
        '缺失数量': missing,
        '缺失比例(%)': missing_pct
    })
    print(missing_df[missing_df['缺失数量'] > 0])

    return missing_df

# ========== 4. 变量重命名 ==========
def rename_variables(df, rename_dict):
    """批量重命名变量"""
    df = df.rename(columns=rename_dict)
    print(f"\n变量重命名完成: {list(rename_dict.values())}")
    return df

# ========== 5. 处理缺失值 ==========
def handle_missing(df, strategy='default'):
    """
    处理缺失值
    strategy: 'default' 使用中位数/众数填充数值变量
              'listwise' 删除所有含缺失值的观测
              'pairwise' 保留尽可能多的观测
    """
    if strategy == 'listwise':
        df_clean = df.dropna()
        print(f"\nlistwise删除: 原始{len(df)}行 -> 删除后{len(df_clean)}行")

    elif strategy == 'default':
        df_clean = df.copy()
        for col in df_clean.columns:
            if df_clean[col].dtype in ['float64', 'int64']:
                # 数值变量用中位数填充
                df_clean[col].fillna(df_clean[col].median(), inplace=True)
            else:
                # 分类变量用众数填充
                df_clean[col].fillna(df_clean[col].mode()[0], inplace=True)
        print("\n缺失值已用中位数/众数填充")

    return df_clean

# ========== 6. 处理极端值 ==========
def winsorize(df, columns, lower=0.01, upper=0.99):
    """缩尾处理极端值"""
    df_clean = df.copy()

    for col in columns:
        lower_bound = df_clean[col].quantile(lower)
        upper_bound = df_clean[col].quantile(upper)

        # 统计极端值数量
        n_low = (df_clean[col] < lower_bound).sum()
        n_high = (df_clean[col] > upper_bound).sum()

        # 缩尾
        df_clean[col] = df_clean[col].clip(lower_bound, upper_bound)

        print(f"\n{col}: 缩尾处理 - 低端{n_low}个, 高端{n_high}个")

    return df_clean

# ========== 7. 生成新变量 ==========
def create_variables(df):
    """生成分析所需的新变量"""

    # 对数转换（常用于经济变量）
    if 'gdp' in df.columns:
        df['ln_gdp'] = np.log(df['gdp'])
        print("已生成 ln_gdp")

    if 'income' in df.columns:
        df['ln_income'] = np.log(df['income'])
        print("已生成 ln_income")

    if 'population' in df.columns:
        df['ln_population'] = np.log(df['population'])
        print("已生成 ln_population")

    # 增长率
    if 'gdp' in df.columns and 'year' in df.columns:
        df = df.sort_values(['province', 'year'])
        df['gdp_growth'] = df.groupby('province')['gdp'].pct_change()
        print("已生成 gdp_growth")

    # 人均变量
    if 'gdp' in df.columns and 'population' in df.columns:
        df['gdp_per_capita'] = df['gdp'] / df['population']
        print("已生成 gdp_per_capita")

    # 二值变量
    if 'urbanization' in df.columns:
        median_urban = df['urbanization'].median()
        df['high_urban'] = (df['urbanization'] > median_urban).astype(int)
        print("已生成 high_urban")

    return df

# ========== 8. 数据合并 ==========
def merge_datasets(df1, df2, on, how='left'):
    """合并多个数据集"""
    df_merged = pd.merge(df1, df2, on=on, how=how)
    print(f"\n数据合并完成: {df1.shape[0]} + {df2.shape[0]} -> {df_merged.shape[0]}行")
    return df_merged

# ========== 9. 数据筛选 ==========
def filter_data(df, conditions):
    """按条件筛选数据"""
    df_filtered = df.query(conditions)
    print(f"\n筛选条件: {conditions}")
    print(f"原始: {len(df)}行 -> 筛选后: {len(df_filtered)}行")
    return df_filtered

# ========== 10. 保存清洗后数据 ==========
def save_data(df, filename, format='csv'):
    """保存清洗后的数据"""
    if format == 'csv':
        df.to_csv(f"{CLEAN_DIR}\\{filename}", index=False, encoding='utf-8-sig')
    elif format == 'excel':
        df.to_excel(f"{CLEAN_DIR}\\{filename}", index=False)
    elif format == 'dta':
        df.to_stata(f"{CLEAN_DIR}\\{filename}")

    print(f"\n数据已保存: {CLEAN_DIR}\\{filename}")

# ========== 11. 生成描述性统计 ==========
def descriptive_stats(df, variables):
    """生成描述性统计表"""
    stats = df[variables].describe().T
    stats['cv'] = stats['std'] / stats['mean']  # 变异系数
    stats['missing'] = df[variables].isnull().sum()

    print("\n" + "="*60)
    print("描述性统计")
    print("="*60)
    print(stats)

    return stats

# ========== 主程序 ==========
if __name__ == "__main__":
    # 示例：清洗中国省级面板数据
    # 请根据实际数据修改以下路径和变量名

    # 1. 读取数据
    # df = load_data(f"{DATA_DIR}\\raw_data.csv")

    # 2. 数据概览
    # missing_report = data_overview(df)

    # 3. 重命名变量（示例）
    # rename_dict = {
    #     '省份': 'province',
    #     '年份': 'year',
    #     'GDP': 'gdp'
    # }
    # df = rename_variables(df, rename_dict)

    # 4. 处理缺失值
    # df = handle_missing(df, strategy='default')

    # 5. 处理极端值
    # df = winsorize(df, columns=['gdp', 'income', 'population'])

    # 6. 生成新变量
    # df = create_variables(df)

    # 7. 筛选数据（如需要）
    # df = filter_data(df, "year >= 2000 & year <= 2020")

    # 8. 保存
    # save_data(df, "cleaned_panel_data.csv")

    print("数据清洗模板已加载，请根据实际数据修改代码")