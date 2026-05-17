/*
==============================================================================
基准回归分析模板
文件名: 01_baseline_regression.do
用途: 经济学论文基准回归分析

使用前请修改:
1. 全局路径
2. 变量名称
3. 数据文件名
==============================================================================
*/

clear all
cap log close
set more off
set scheme cleanplots

// ========== 1. 全局设置 ==========
global dir "C:\Users\22907\economics-paper-writing"
global data "$dir\data\cleaned"
global output "$dir\data\output"
global figures "$dir\figures"
global log "$dir\logs"

// 创建输出目录（如果不存在）
cap mkdir "$output"
cap mkdir "$figures"
cap mkdir "$log"

// 打开日志
log using "$log\baseline_regression.log", replace

// ========== 2. 变量定义 ==========
// 被解释变量
global depvar "ln_gdp"

// 核心解释变量
global indepvar "human_capital"

// 控制变量
global controls "ln_capital industry digital urbanization"

// 固定效应
global fe "i.year i.province"

// 聚类稳健标准误
global cluster "province"

// ========== 3. 加载数据 ==========
use "$data\your_data.dta", clear

// 查看数据结构
describe
codebook $depvar $indepvar $controls

// ========== 4. 描述性统计 ==========
estpost summarize $depvar $indepvar $controls, detail
esttab using "$output\table1_descriptive_stats.txt", replace ///
    cells("mean sd min p25 p50 p75 max") ///
    title("描述性统计") ///
    label plain noobs

eststo clear

// ========== 5. 相关性分析 ==========
pwcorr $depvar $indepvar $controls, star(0.05) sig
graph matrix $depvar $indepvar $controls, half

// ========== 6. 基准回归 ==========
// 模型1: OLS无固定效应
reg $depvar $indepvar $controls, vce(cluster $cluster)
est store m1

// 模型2: 加入年份固定效应
reg $depvar $indepvar $controls i.year, vce(cluster $cluster)
est store m2

// 模型3: 加入省份和年份双向固定效应
reg $depvar $indepvar $controls $fe, vce(cluster $cluster)
est store m3

// 模型4: 双向固定效应+聚类
reg $depvar $indepvar $controls $fe, vce(cluster $cluster)
est store m4

// ========== 7. 输出回归结果 ==========
esttab m1 m2 m3 m4 using "$output\table2_baseline_regression.txt", ///
    b(4) se(4) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("基准回归结果") ///
    label ///
    keep($indepvar $controls) ///
    addn("控制变量已包含" "省份和年份固定效应已控制") ///
    nonumbers

// 输出LaTeX格式
esttab m1 m2 m3 m4 using "$output\table2_baseline_regression.tex", ///
    booktabs substitute($ \_ #) ///
    b(4) se(4) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep($indepvar $controls) ///
    title("基准回归结果")

// ========== 8. 效应大小解读 ==========
// 计算经济显著性
reg $depvar $indepvar $controls $fe, vce(cluster $cluster)
display "核心解释变量单位变化带来的因变量变化:"
display "系数: " _b[$indepvar]
display "标准误: " _se[$indepvar]
display "解释: 人力资本每增加1个单位，GDP增长" _b[$indepvar]*100 "%"

// ========== 9. 稳健性检验 ==========
// 9.1 去掉极端值
winsor2 $depvar $indepvar $controls, cuts(1 99) replace
reg $depvar $indepvar $controls $fe, vce(cluster $cluster)
est store robust1

// 9.2 替换核心变量（使用滞后项）
gen ln_gdp_l1 = L.ln_gdp
gen human_capital_l1 = L.human_capital
reg ln_gdp_l1 human_capital_l1 $controls $fe, vce(cluster $cluster)
est store robust2

// 9.3 子样本分析（去掉直辖市）
drop if inlist(province, "北京", "上海", "天津", "重庆")
reg $depvar $indepvar $controls $fe, vce(cluster $cluster)
est store robust3

// 稳健性检验汇总
esttab robust1 robust2 robust3 using "$output\table3_robustness.txt", ///
    b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    title("稳健性检验结果") label

log close

display "分析完成！结果保存在 $output 目录"