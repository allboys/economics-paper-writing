/*
==============================================================================
机制检验与中介分析
文件名: 05_mechanism_analysis.do
用途: 检验X影响Y的作用机制

方法:
1. 逐步回归法（Baron-Kenny）
2. Sobel检验
3. Bootstrap置信区间
==============================================================================
*/

clear all
cap log close
set more off

global dir "C:\Users\22907\economics-paper-writing"
global data "$dir\data\cleaned"
global output "$dir\data\output"
global log "$dir\logs"

log using "$log\05_mechanism_analysis.log", replace

use "$data\your_data.dta", clear

// ========== 1. 变量设置 ==========
global depvar "outcome"          // 最终因变量Y
global indepvar "treatment"      // 核心自变量X
global mediator "mechanism"      // 中介变量M
global controls "cov1 cov2 cov3"  // 控制变量
global fe "i.year i.city"
global cluster "city"

// ========== 2. Baron-Kenny逐步法 ==========
// 步骤a: X → Y (总效应)
reg $depvar $indepvar $controls $fe, vce(cluster $cluster)
est store step_a

// 步骤b: X → M (X对中介变量的影响)
reg $mediator $indepvar $controls $fe, vce(cluster $cluster)
est store step_b

// 步骤c: X + M → Y (直接效应，控制中介变量后)
reg $depvar $indepvar $mediator $controls $fe, vce(cluster $cluster)
est store step_c

// 输出三步法结果
esttab step_a step_b step_c using "$output\table7_mechanism_steps.txt", ///
    b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    keep($indepvar $mediator) ///
    title("逐步法中介效应检验") label

// ========== 3. Sobel中介效应检验 ==========
// 计算Sobel统计量
scalar a = _b[$indepvar] in step_b
scalar b = _b[$mediator] in step_c
scalar sea = _se[$indepvar] in step_b
scalar seb = _se[$mediator] in step_c

scalar indirect_effect = a * b
scalar sobelse = sqrt(a^2 * seb^2 + b^2 * sea^2)
scalar sobelz = indirect_effect / sobelse
scalar pvalue = 2 * normal(-abs(sobelz))

display "============ Sobel检验结果 ============"
display "间接效应 (a*b): " indirect_effect
display "Sobel标准误: " sobelse
display "Z统计量: " sobelz
display "P值: " pvalue

// ========== 4. Bootstrap中介效应 ==========
cap ssc install sgmediation2, replace

sgmediation2 $depvar, mv($mediator) iv($indepvar) cv($controls)

// 输出结果
display "Bootstrap置信区间已在上述输出中"

// ========== 5. 中介效应分解 ==========
// 总效应 = 直接效应 + 间接效应
scalar total = _b[$indepvar] in step_a
scalar direct = _b[$indepvar] in step_c
scalar indirect = total - direct
scalar proportion = indirect / total * 100

display "============ 中介效应分解 ============"
display "总效应: " total
display "直接效应: " direct
display "间接效应: " indirect
display "中介效应占比: " proportion "%"

// ========== 6. 多个中介变量 ==========
// 如果有多个中介渠道
global mediators "mediator1 mediator2 mediator3"

foreach m of global mediators {
    // X → M
    reg `m' $indepvar $controls $fe, vce(cluster $cluster)

    // X + M → Y
    reg $depvar $indepvar `m' $controls $fe, vce(cluster $cluster)
}

// 使用、结构方程模型 (SEM)
cap ssc install sem, replace

sem (mediator1 <- $indepvar $controls) ///
    (mediator2 <- $indepvar $controls) ///
    ($depvar <- $indepvar mediator1 mediator2 $controls), ///
    method(ml)

estat teffects  // 报告总效应、直接效应、间接效应

// ========== 7. 调节效应检验 ==========
// 检验Z是否调节X对Y的影响

gen interaction = $indepvar * moderator

// 加入交互项
reg $depvar $indepvar moderator interaction $controls $fe, ///
    vce(cluster $cluster)
est store moderation

// 简单斜率分析
// 高 moderator (+1 SD)
gen indep_high = $indepvar * (moderator > r(mean) + r(sd))
gen indep_low = $indepvar * (moderator < r(mean) - r(sd))

reg $depvar indep_high indep_low $controls $fe, ///
    vce(cluster $cluster)

// ========== 8. 工具变量中介检验（处理内生性） ==========
// 如果X有内生性，使用IV方法

// IV第一步: Z → X
reg $indepvar $controls ($indepvar = iv1 iv2), vce(cluster $cluster)

// IV第二步: X_hat → Y
predict xhat, xb

reg $depvar xhat $controls $fe, vce(cluster $cluster)

// 中介效应: IV估计
reg $mediator xhat $controls $fe, vce(cluster $cluster)

// ========== 9. 结果保存 ==========
// 保存机制检验结果
esttab step_a step_b step_c using "$output\table7_mechanism_final.txt", ///
    b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    title("机制检验结果汇总") ///
    label

log close

display "机制分析完成！"
display "间接效应占比: " proportion "%"