# MiMo 开发者计划适配配置

本目录包含适配小米米家(MiMo)开发者计划的配置文件。

## 文件说明

| 文件 | 用途 |
|------|------|
| `miio_properties.json` | 应用基础属性配置 |
| `manifests/mimo_app_manifest.json` | MiMo 应用清单 |
| `device_model.json` | 设备模型定义 (IoT设备) |

## 申请步骤

1. 登录 [小米开发者平台](https://developer.xiaomi.com/)
2. 创建新应用，选择 "MiMo" 平台
3. 上传 `manifests/mimo_app_manifest.json`
4. 配置应用权限和 AI 能力
5. 提交审核

## AI 能力

应用支持以下 AI 功能：
- 📚 文献智能搜索
- ✏️ 语法检查与润色
- 📖 引用建议
- 📊 数据可视化生成

## 数据安全

- 数据加密：AES-256
- 合规：GDPR / 中国数据安全法
- 存储：小米云国内节点

## 扩展功能

- 智能写作提醒
- Git 版本同步
- 多设备协作
- 离线模式支持
