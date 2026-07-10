# FansProject

目标网站项目工作区：基于 Dujiao-Next 开源数字商品销售系统，接入 FansGurus 粉丝服务 API 与 TGX Account 账号商品 API，搭建一个同时提供粉丝购买和账号购买的一站式平台。

## 当前结论

项目主线清晰，核心输入已确认：

- Dujiao-Next 源码已 clone 到当前项目目录：`dujiao-next/`、`user/`、`admin/`、`document/`。
- FansGurus API Key 已由项目方提供，必须通过本地 `.env` 或部署 secret 注入，不写入 git。
- TGX `app_id` / `app_key` 已由项目方提供，必须通过本地 `.env` 或部署 secret 注入，不写入 git。
- TGX 价格加价基准使用 `price`。
- 上线支付渠道预期支持支付宝、微信支付、PayPal，优先复用 Dujiao-Next 已集成能力。
- 目标网站展示和结算币种统一使用 USD；FansGurus 明确返回 USD，TGX API 未提供可机器读取的币种字段。
- 项目级集成配置统一使用根目录 `.env`。
- clone 下来的 Dujiao-Next 源码目录不纳入当前主仓库跟踪，保留各自上游 git 历史。
- 域名暂未确定，开发阶段使用临时占位域名；上线前统一替换域名相关文本和品牌资源。

## 业务规则

- 上游 1：FansGurus，作为粉丝、点赞、播放、评论等增长服务供应商。
- 上游 2：TGX Account，作为社交账号和数字账号供应商。
- 基座：Dujiao-Next，负责商品、订单、支付、用户中心、后台管理、交付和二次开发基础。
- 排除所有包含 Telegram 或电报相关语义的 SKU。
- 只售卖 FansGurus 与 TGX 同时覆盖的平台交集。
- FansGurus SKU 售价 = FansGurus 上游价 * 5。
- TGX SKU 售价 = TGX `price` * 1.2。
- 支持简体中文、繁体中文、英文，首次访问按 IP 推断默认语言，用户手动选择后优先使用用户选择。
- 预留根据域名选择 favicon、logo、站点图片、站点名称、SEO 文案等品牌资源的能力。

## 文档入口

- `docs/00-project-scope.md`：范围、边界和已知未决项。
- `docs/01-architecture.md`：目标架构、数据流和集成方案。
- `docs/02-upstream-apis.md`：FansGurus、TGX、Dujiao-Next API 调研摘要。
- `docs/03-sku-sync.md`：SKU 交集、Telegram 排除、价格同步、库存同步。
- `docs/04-seo-geo-plan.md`：多语言、IP 默认语言、SEO/GEO 页面策略。
- `docs/05-requirements.md`：产品需求与验收标准。
- `docs/06-development-guide.md`：开发落地指南。
- `docs/07-implementation-policy.md`：复用优先策略，含 Dujiao-Next、find-skills、成熟库选择规则。
- `docs/08-coding-standards.md`：代码规范，基于 karpathy-guidelines。
- `docs/09-master-development-playbook.md`：从接管源码到上线的执行手册。
- `docs/10-open-questions.md`：实施前必须确认的问题清单。
- `docs/11-development-roadmap.md`：正式开发路线图和阶段完成记录。
- `docs/18-production-security-compliance-checklist.md`：生产安全与合规上线阻断清单。
- `docs/19-production-config-template.md`：生产配置模板，含域名、支付、CORS、Redis、队列和密钥占位。
- `docs/20-go-live-runbook.md`：最终上线 gate 顺序，要求先跑 `ops/prelaunch-audit.sh`。
- `docs/21-production-deployment-plan.md`：生产部署拓扑、构建方式、反代路由和 fullstack 备选说明。
- `docs/22-production-config-mapping.md`：Compose env、后端 `config.yml` 和后台设置的生产映射说明。
- `docs/23-reverse-proxy-cdn.md`：Nginx/CDN 反向代理、安全头、上传限制和国家 header 模板说明。
- `docs/24-operations-runbook.md`：生产运维操作手册，含启停、日志、禁用、回滚和事故处理。
- `docs/25-launch-acceptance-checklist.md`：上线前人工验收与最终 sign-off 清单。
- `docs/26-final-project-audit.md`：进入真实生产配置前的最终项目审计和剩余上线 gate。
- `docs/27-gate1-production-config-workbook.md`：Gate 1 真实生产配置准备工作单。
- `docs/28-secret-generation-guide.md`：生产密钥生成、填写和轮换说明。
- `docs/29-production-environment-checklist.md`：生产或 staging 主机环境准备清单。
- `ops/init-production-local.sh`：复制生产配置模板到本地忽略目录 `deploy/production-local/`。
- `ops/check-production-local.sh`：检查本地生产配置草稿并执行 Gate 1 审计。
- `ops/bootstrap-production-host.sh`：生产或 staging 主机目录、仓库和配置模板初始化脚本。
- `ops/compose/docker-compose.production.yml`：最小三服务分离部署 Compose 模板。
- `ops/gate1/`：Gate 1 审计输入模板，含 `site_config` 和前后台生产 env 示例。

## 信息来源

- FansGurus API 文档：`https://fansgurus.com/zh/api`
- TGX Account API 文档：`https://www.tgxaccount.com/user/docs/api`
- Dujiao-Next 官方文档：`https://dujiao-next.com/`
- 本地资料：`/Users/river/Downloads/TGX`、`/Users/river/Downloads/Dujiao`

## 源码目录

- `dujiao-next/`：Dujiao-Next API/后端。
- `user/`：Dujiao-Next 用户前台。
- `admin/`：Dujiao-Next 后台。
- `document/`：Dujiao-Next 文档。

这些目录本身是 clone 下来的上游源码工作区。后续改造应优先在这些实际源码中完成，而不是继续维护独立占位项目。

这些源码目录不纳入当前主仓库跟踪；当前主仓库只维护项目文档、集成策略、环境模板和后续必要的协调文件。

## 旧项目说明

当前仓库存在旧项目遗留文档和补丁。凡与本 README 和 `docs/` 最新文档冲突的内容，以最新文档为准。历史 `patches/dujiao-next/` 暂不作为当前实现依据，后续接入真实 Dujiao-Next 源码后再评估迁移价值。
