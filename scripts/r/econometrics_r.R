# R语言计量经济学模板
# Economics Paper Writing - R Scripts

## 环境设置

```r
# 安装必要的包
install.packages(c("tidyverse", "plm", "lmtest", "sandwich",
                   "stargazer", "fixest", "ivmodel", "cem"))

library(tidyverse)
library(plm)           # 面板数据
library(lmtest)        # 假设检验
library(sandwich)      # 稳健标准误
library(stargazer)     # 回归表格输出
library(fixest)        # 高维固定效应
```

## 1. 面板数据回归

```r
# ============================================
# 面板数据固定效应模型
# ============================================

# 加载数据
df <- read.csv("data/cleaned/your_data.csv") %>%
  mutate(across(c(year, province), factor))

# 基准回归
model1 <- plm(gdp ~ human_capital + capital + labor,
              data = df,
              index = c("province", "year"),
              model = "within")  # 固定效应

summary(model1)

# 稳健标准误（聚类到省份）
robust_se <- vcovHC(model1, type = "HC3", cluster = "group")
coeftest(model1, vcov = robust_se)

# 双向固定效应
model2 <- plm(gdp ~ human_capital + capital + labor + factor(year),
              data = df,
              index = c("province", "year"),
              model = "within")

# 使用fixest包（更快）
library(fixest)

model_fe <- feols(gdp ~ human_capital + capital + labor |
                  province + year,
                  data = df,
                  cluster = ~province)

summary(model_fe)
```

## 2. 双重差分

```r
# ============================================
# 双重差分 (DID)
# ============================================

# 事件研究法
df <- df %>%
  mutate(relative_time = year - policy_year,
         treat_post = treatment * post)

# 事件研究回归
event_formula <- as.formula(paste(
  "gdp ~",
  paste(paste0("event_", -3:-1), collapse = " + "),
  "+ event_0 +",
  paste(paste0("event_", 1:5), collapse = " + "),
  "+ capital + labor | province + year"
))

# 或者使用fixest
event_model <- feols(gdp ~ i(relative_time, ref = -1) +
                     capital + labor |
                     unit + year,
                     data = df,
                     cluster = ~unit)

# 绘制事件研究图
iplot(event_model,
      main = "Event Study: Parallel Trend Test",
      xlab = "Years Relative to Policy",
      ylab = "Treatment Effect")

# 基准DID
did_model <- feols(gdp ~ treatment##post + capital + labor |
                   province + year,
                   data = df,
                   cluster = ~province)

summary(did_model)
```

## 3. 工具变量法

```r
# ============================================
# 工具变量回归 (2SLS)
# ============================================

library(ivmodel)

# 使用ivreg
library(AER)
iv_model <- ivreg(gdp ~ education + experience |
                  instrument1 + instrument2 + experience,
                  data = df)

summary(iv_model, diagnostics = TRUE)

# 使用fixest
iv_feols <- feols(gdp ~ education + experience |
                  capital + labor |
                  education ~ instrument1 + instrument2,
                  data = df,
                  cluster = ~province)

summary(iv_feols)

# 弱工具变量检验
# 第一阶段F统计量 > 10 表示不存在弱工具变量问题
first_stage <- lm(education ~ instrument1 + instrument2 + capital + labor,
                  data = df)
summary(aov(first_stage))  # F检验
```

## 4. 异质性分析

```r
# ============================================
# 异质性分析
# ============================================

# 按组分别回归
split_model <- df %>%
  group_split(region) %>%
  map(~ feols(gdp ~ human_capital + controls |
              province + year,
              data = .,
              cluster = ~province))

# 使用交互项
hetero_model <- feols(gdp ~ human_capital + capital + labor +
                     human_capital##high_tech |
                     province + year,
                     data = df,
                     cluster = ~province)

summary(hetero_model)

# 分位数回归
library(quantreg)

q_model <- rq(gdp ~ human_capital + capital + labor,
              data = df,
              tau = c(0.25, 0.5, 0.75))

summary(q_model)
```

## 5. 稳健性检验

```r
# ============================================
# 稳健性检验
# ============================================

# 去掉极端值
df_clean <- df %>%
  mutate(across(c(gdp, human_capital),
                ~ DescTools::Winsorize(., probs = c(0.01, 0.99))))

# 子样本分析
subsample_model <- feols(gdp ~ human_capital + controls |
                        province + year,
                        data = df %>% filter(year >= 2010),
                        cluster = ~province)

# 增加控制变量
add_controls <- feols(gdp ~ human_capital + controls + fdi + innovation |
                      province + year,
                      data = df,
                      cluster = ~province)

# 替换核心变量
alt_model <- feols(gdp ~ ln_education + controls |
                   province + year,
                   data = df,
                   cluster = ~province)
```

## 6. 结果输出

```r
# ============================================
# 回归结果表格输出
# ============================================

library(stargazer)

stargazer(model1, model2, model3,
          title = "回归结果",
          align = TRUE,
          no.space = TRUE,
          star.char = c("+", "*", "**", "***"),
          star.cutoff = c(0.1, 0.05, 0.01, 0.001),
          keep = c("human_capital", "capital", "labor"),
          add.lines = list(c("固定效应", "省份", "年份", "双向")),
          covariate.labels = c("人力资本", "物质资本", "劳动"),
          out = "output/table_regression.html")

# 使用fixest输出
etable(model_fe, iv_feols,
       title = "回归结果对比",
       file = "output/table_comparison.tex")
```

## 7. 可视化

```r
# ============================================
# 经济学图表
# ============================================

library(ggplot2)

# 散点图 + 回归线
ggplot(df, aes(x = human_capital, y = gdp)) +
  geom_point() +
  geom_smooth(method = "lm", se = TRUE) +
  labs(title = "人力资本与GDP关系",
       x = "人力资本",
       y = "GDP对数") +
  theme_minimal()

# 系数图（带置信区间）
coef_data <- data.frame(
  variable = c("人力资本", "物质资本", "劳动"),
  estimate = c(0.12, 0.45, 0.23),
  se = c(0.03, 0.05, 0.04)
) %>%
  mutate(lower = estimate - 1.96*se,
         upper = estimate + 1.96*se)

ggplot(coef_data, aes(x = variable, y = estimate)) +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = lower, ymax = upper), width = 0.2) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(title = "回归系数（95%置信区间）") +
  coord_flip()
```

## 8. 数据处理

```r
# ============================================
# 数据处理模板
# ============================================

library(tidyverse)

# 数据清洗
df_clean <- df %>%
  # 处理缺失值
  mutate(across(everything(),
                ~ ifelse(is.na(.), median(., na.rm = TRUE), .))) %>%
  # 变量转换
  mutate(ln_gdp = log(gdp + 1),
         ln_income = log(income + 1)) %>%
  # 去除异常值
  filter(abs(gdp - mean(gdp)) < 3*sd(gdp)) %>%
  # 生成滞后变量
  group_by(province) %>%
  mutate(gdp_l1 = lag(gdp, 1),
         gdp_growth = (gdp - gdp_l1) / gdp_l1) %>%
  ungroup()

# 描述性统计
df_clean %>%
  select(gdp, human_capital, capital) %>%
  summarize(across(everything(),
                   list(mean = mean, sd = sd, min = min, max = max),
                   .names = "{.fn}_{.col}"))
```