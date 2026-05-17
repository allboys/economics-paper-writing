/*
==============================================================================
稳健性检验模板
文件名: 02_robustness_checks.do
用途: 经济学论文稳健性检验

包含:
1. 替换核心变量
2. 工具变量法
3. 子样本分析
4. 倾向得分匹配（可选）
==============================================================================
*/

clear all
cap log close
set more off

// ========== 1. 设置 ==========
global dir "C:\Users\22907\economics-paper-writing"
global data "$dir\data\cleaned"
global output "$dir\data\output"
global log "$dir\logs"

log using "$log\robustness_checks.log", replace

use "$data\your_data.dta", clear

// 全局变量
global depvar "ln_gdp"
global indepvar "human_capital"
global controls "ln_capital industry digital urbanization"
global fe "i.year i.province"
global cluster "province"

// ========== 2. 基准回归结果 ==========
reg $depvar $indepvar $controls $fe, vce(cluster $cluster)
est store baseline

// ========== 3. 替换核心变量 ==========
// 3.1 使用替代指标
gen ln_human = ln(human_capital + 1)
reg $depvar ln_human $controls $fe, vce(cluster $cluster)
est store alt1

// 3.2 使用滞后变量
reg $depvar L.$indepvar $controls $fe, vce(cluster $cluster)
est store alt2

// 3.3 转换为二值变量
sum $indepvar, detail
gen high_human = ($indepvar > r(p50)) if !missing($indepvar)
reg $depvar high_human $controls $fe, vce(cluster $cluster)
est store alt3

// ========== 4. 子样本分析 ==========
// 4.1 分时间段
reg $depvar $indepvar $controls $fe if year >= 2010, vce(cluster $cluster)
est store sub_time

// 4.2 分地区（东部vs非东部）
gen east = inlist(province, "北京", "天津", "河北", "辽宁", "上海", "江苏", "浙江", "福建", "山东", "广东", "海南")
reg $depvar $indepvar $controls $fe if east == 1, vce(cluster $cluster)
est store sub_east

reg $depvar $indepvar $controls $fe if east == 0, vce(cluster $cluster)
est store sub_west

// 4.3 去掉直辖市
reg $depvar $indepvar $controls $fe if !inlist(province, "北京", "上海", "天津", "重庆"), vce(cluster $cluster)
est store sub_no_muni

// ========== 5. 增加控制变量 ==========
// 5.1 加入FDI
reg $depvar $indepvar $controls ln_fdi $fe, vce(cluster $cluster)
est store add_fdi

// 5.2 加入人力资本存量
reg $depvar $indepvar $controls ln_capital human_stock $fe, vce(cluster $cluster)
est store add_human

// 5.3 加入交互项
gen human_x_digital = $indepvar * digital
reg $depvar $indepvar digital human_x_digital $controls $fe, vce(cluster $cluster)
est store add_interact

// ========== 6. 工具变量法（如果存在内生性） ==========
// 6.1 选取工具变量
// 工具变量示例：历史数据、外生冲击等
ivreg2 $depvar $controls $fe ($indepvar = iv1 iv2), gmm2s robust
est store iv_gmm

// 6.2 检验工具变量
estat firststage
// 报告F统计量 > 10 表示不存在弱工具变量问题

// 6.3 过度识别检验
estat overid

// ========== 7. 倾向得分匹配（如果适用） ==========
// 如果处理变量是二值的
cap ssc install psmatch2, replace

gen treatment = ($indepvar > median($indepvar)) if !missing($indepvar)

pscore treatment $controls, pscore(pscore) logit common

// 1:1最近邻匹配
psmatch2 treatment, pscore(pscore) neighbor(1) noreplace
reg $depvar treatment if _treated != ., vce(cluster $cluster)
est store psmatch

// 核匹配
psmatch2 treatment, pscore(pscore) kernel
reg $depvar treatment if _treated != ., vce(cluster $cluster)
est store pskernel

// ========== 8. 输出汇总表 ==========
esttab baseline alt1 alt2 alt3 using "$output\table4_robustness_part1.txt", ///
    b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    keep($indepvar ln_human L.$indepvar high_human) ///
    title("稳健性检验：替换核心变量") label

esttab sub_time sub_east sub_west sub_no_muni using "$output\table4_robustness_part2.txt", ///
    b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    keep($indepvar) ///
    title("稳健性检验：子样本分析") label

esttab add_fdi add_human add_interact using "$output\table4_robustness_part3.txt", ///
    b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    keep($indepvar digital human_x_digital) ///
    title("稳健性检验：增加控制变量") label

log close

display "稳健性检验完成！"