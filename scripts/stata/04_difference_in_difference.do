/*
==============================================================================
双重差分(DID)分析模板
文件名: 04_difference_in_difference.do
用途: 政策评估、自然实验分析

使用前提:
1. 识别处理组和对照组
2. 确认处理时间点
3. 检验平行趋势假设
==============================================================================
*/

clear all
cap log close
set more off

global dir "C:\Users\22907\economics-paper-writing"
global data "$dir\data\cleaned"
global output "$dir\data\output"
global figures "$dir\figures"
global log "$dir\logs"

log using "$log\04_did_analysis.log", replace

use "$data\your_data.dta", clear

// ========== 1. 全局设置 ==========
global depvar "outcome"           // 被解释变量
global treat "treatment"           // 处理组虚拟变量 (1=处理组, 0=对照组)
global post "post"                 // 政策实施后虚拟变量 (1=之后, 0=之前)
global controls "cov1 cov2 cov3"   // 控制变量
global cluster "city"              // 聚类层级

// ========== 2. 数据准备 ==========
// 确认变量类型
destring $treat, replace
destring $post, replace

// 创建交互项
gen treat_post = $treat * $post

// 创建处理时间（用于事件研究）
gen policy_year = 2015  // 政策实施年份，根据实际修改

// ========== 3. 基准DID估计 ==========
// 模型: Y = β0 + β1*treat + β2*post + β3*treat*post + controls + ε

reg $depvar $treat $post treat_post $controls i.year i.city, vce(cluster $cluster)
est store did基准

// 逐步加入控制变量
reg $depvar treat_post $controls i.year i.city, vce(cluster $cluster)
est store did控制

// 仅双向固定效应
reg $depvar treat_post i.year i.city, vce(cluster $cluster)
est store did双向FE

// ========== 4. 输出基准结果 ==========
esttab did基准 did控制 did双向FE using "$output\table5_did_results.txt", ///
    b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(treat_post) ///
    title("双重差分基准回归结果") ///
    label

// ========== 5. 平行趋势检验 ==========
// 生成相对时间虚拟变量（政策前3期到政策后5期）
gen relative_time = year - policy_year

// 仅保留政策前后合理窗口期
keep if inrange(relative_time, -3, 5)

// 生成相对时间虚拟变量（以政策前1期为基准期）
forvalues t = -3/-1 {
    gen before`t' = (relative_time == `t')
}

gen current = (relative_time == 0)
gen after1 = (relative_time == 1)
gen after2 = (relative_time == 2)
gen after3 = (relative_time >= 3)

// 事件研究法回归
reg $depvar before*-3 before-2 current after1 after2 after3 $controls ///
    i.year i.city, vce(cluster $cluster)
est store event_study

// ========== 6. 事件研究图 ==========
// 提取系数和标准误
coefplot (event_study, asequation(keep(before*-3 before-2 current after1 after2 after3))), ///
    vertical ///
    yline(0, lpattern(dash)) ///
    xlabel(-3 "-3" -2 "-2" -1 "-1" 0 "0" 1 "1" 2 "2" 3 "+") ///
    title("事件研究图：平行趋势检验") ///
    scheme(s2color)

graph export "$figures\figure1_event_study.png", replace

// ========== 7. 动态效应（不同时间段的处理效应） ==========
// 分别估计各期平均处理效应
reg $depvar before-1 before-2 before-3 after1 after2 after3 ///
    $controls i.year i.city, vce(cluster $cluster)

mat beta = e(b)
mat se = e(V)

local names "after1 after2 after3 before-1 before-2 before-3"
foreach name of local names {
    display "`name': " _b[`name']
}

// ========== 8. 异质性DID ==========
// 8.1 按地区分组
reg $depvar treat_post $controls i.year i.city if region == "东部", ///
    vce(cluster $cluster)
est store did东部

reg $depvar treat_post $controls i.year i.city if region != "东部", ///
    vce(cluster $cluster)
est store did中西部

// 8.2 按企业规模分组
reg $depvar treat_post $controls i.year i.city if size == "大型", ///
    vce(cluster $cluster)
est store did大型

reg $depvar treat_post $controls i.year i.city if size == "中小型", ///
    vce(cluster $cluster)
est store did中小型

// ========== 9. 安慰剂检验 ==========
// 9.1 随机分配处理组
set seed 12345
gen random_treat = rnormal() > 0  // 随机生成处理组

reg $depvar random_treat##post $controls i.year i.city, ///
    vce(cluster $cluster)
est store placebo_random

// 9.2 随机分配政策时间
set seed 12345
gen random_year = floor(runiform() * 3) + 2012  // 2012-2014随机年份
gen random_post = (year >= random_year)

reg $depvar $treat##random_post $controls i.year i.city, ///
    vce(cluster $cluster)
est store placebo_time

// 输出安慰剂检验结果
esttab placebo_random placebo_time using "$output\table6_placebo_test.txt", ///
    b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(random_treat#random_post $treat#random_post) ///
    title("安慰剂检验结果") label

// ========== 10. 敏感性检验 ==========
// 10.1 不同带宽（对于RDD或模糊DID）
// 10.2 不同聚类层级
reg $depvar treat_post $controls i.year i.city, ///
    vce(cluster province)  // 省级聚类
est store sensitivity1

reg $depvar treat_post $controls i.year i.city, ///
    vce(cluster industry)  // 行业聚类
est store sensitivity2

// 10.3 排除异常值
winsor2 $depvar, cuts(1 99) replace
reg ln_outcome treat_post $controls i.year i.city, ///
    vce(cluster $cluster)
est store sensitivity3

// ========== 11. 渐近DID（Sun and Abraham 2021） ==========
// 对于异质性处理效应
cap ssc install xtevent, replace

xtevent $depvar, event(treatment_year) baseline(-1) ///
    controls($controls) timevar(year) unitvar(unit) ///
    cluster($cluster)

estimates store sa21

log close

display "DID分析完成！请检查平行趋势图（figure1_event_study.png）"