# 生产上线差距与整改计划

审查日期：2026-07-15  
线上复核日期：2026-07-16  
审查结论：**可继续进行 VPS/staging 部署与验收，但当前不可开放生产付费流量。**

## 整改进度更新（2026-07-15）

本轮已完成并验证：

- P0-1：目录同步不再因后续库存任务入队失败而覆盖已完成的导入结果；API 返回库存任务状态，后台显示明确警告。
- P0-2：TGX 单商品库存刷新已加入 `integration` 内置角色，启动补种机制可覆盖已有数据库。
- P0-3：Gate 1/2 已拒绝 `.example`、`.test`、`.invalid`、localhost、loopback 和项目样例域名，并增加 shell 回归测试。
- P0-4（公网核心项）：三个正式域名、DNS、HTTPS、CORS、sitemap 和 robots 已完成公网验证；本地生产草稿仍不能承载真实秘密或替代目标机的配置验收。
- P0-5（线上支持联系方式）：公开 `contact.email` 已复核为可收发的 `support@socialgurushub.com`；Gate 1 仍会阻断空支持邮箱或缺少三语条款/隐私内容，本地草稿尚未同步线上配置。
- P0-8：`worker` 与 `inventory-worker` 已分别使用 Compose `fulfillment`、`inventory` profile，默认 `docker compose up -d` 不会启动；相关手册已同步。
- P1-1（基础质量门禁）：根仓库及三个应用已增加 push/PR 质量工作流。
- P1-2：管理后台已提供正式 `npm test` 命令。
- P0-12（核心安全头）：商店、后台和 API 的 CSP、Permissions-Policy、反嵌入策略已在公网验证；HSTS 仍须等待证书自动续期证据，浏览器 E2E 仍待完成。
- 外部注册：邮箱白名单已关闭；Gmail 已完成 Turnstile、验证码、注册、登录和找回密码验收。项目方接受不再单独执行 Outlook/Hotmail 验收。

整改后验证结果：

| 验证 | 结果 |
| --- | --- |
| 后端 `go test ./... -count=1` | 通过 |
| 用户前台 `npm test` | 通过，28/28 |
| 用户前台 `npm run build` | 通过 |
| 管理后台 `npm test` | 通过，13/13 |
| 管理后台 `npm run build` | 通过 |
| 保留域名审计回归测试 | 通过 |
| 当前本地草稿 Gate 1 | 失败：本地草稿缺支持邮箱和三语正文；不代表 VPS 线上正文缺失 |
| 当前 Gate 2 | 0 failure、7 个本机/路径 warning |

2026-07-16 项目方确认 VPS 已完成管理员 2FA、备份恢复和监控。当前会话没有 VPS SSH 主机信息，因此这三项记为“项目方确认完成、待归档内部验收证据”，不再记为未完成。

2026-07-16 公网只读复核确认：

- `socialgurushub.com`、`api.socialgurushub.com`、`admin.socialgurushub.com` 均解析到 `62.72.6.3`。
- 商店和后台返回 HTTP 200；API `/health` 和 `/api/v1/public/config` 返回 HTTP 200。
- 三个域名的 Let's Encrypt 证书校验通过，有效期至 2026-10-09。
- API 对 `https://socialgurushub.com` 返回正确的 credentialed CORS origin。
- 线上公开配置包含简中、繁中和英文的条款与隐私正文，六个字段均非空。

上述 2026-07-16 发现已在 2026-07-18 整改：公网公开配置返回 `support@socialgurushub.com`；三个入口均返回 CSP、`X-Frame-Options`、`X-Content-Type-Options`、`Referrer-Policy` 和 `Permissions-Policy`，后台/API 均为 `DENY`。HSTS 未启用，等待三个子域证书自动续期证据。

仍未完成或待验证的 P0：供应商真实验收、支付真实小额验收、生产浏览器 E2E 与切换演练。VPS 内部的 2FA、备份恢复、监控需补充验收记录或提供只读访问后再做独立复核。

## 1. 文档目的

本文记录当前项目中仍需修复、完善或改进的事项，并为每一项给出证据、建议动作和完成标准。本文只把有代码、配置、测试或运行记录支持的事项列为已完成；真实支付、供应商和生产运维能力必须以真实环境验收记录为准。

优先级定义：

- `P0`：生产上线阻断项，未完成时不得开放公开付费流量。
- `P1`：应在上线前完成；如决定延期，必须有负责人、期限和风险接受记录。
- `P2`：不直接阻断上线，但应纳入上线后的技术债计划。

## 2. 审查基线

2026-07-15 已执行 `git fetch --all --prune`，并将各项目同步到其定制发布来源 `origin/main`：

| 仓库 | 审查提交 | 状态 |
| --- | --- | --- |
| 根部署仓库 | `b3f7a3a` | 与 `origin/main` 一致 |
| `dujiao-next` 后端 | `2146719` | 与 `origin/main` 一致 |
| `user` 用户前台 | `8f9d1ad` | 与 `origin/main` 一致 |
| `admin` 管理后台 | `6d769c5` | 与 `origin/main` 一致 |
| `document` 上游文档 | `6ba213c` | 与 `origin/main` 一致 |

三个定制应用还配置了 Dujiao-Next 官方 `upstream`。本次只抓取并比较上游引用，没有将未经项目适配和回归测试的上游提交直接合入定制发布分支。

已执行的验证：

| 验证 | 结果 |
| --- | --- |
| 后端 `go test ./...` | 审查时失败；已在本轮整改并全量复测通过 |
| 用户前台 `npm test` | 通过，28/28 |
| 用户前台 `npm run build` | 通过 |
| 管理后台 `npm run build` | 通过 |
| `ops/check-production-local.sh deploy/production-local` | 返回 0，但存在保留域名假绿问题 |
| `ops/check-runtime-dry-run.sh deploy/production-local` | 0 failure、7 warning |
| `docker compose config` | 本机未安装 Docker Compose，未验证 |
| `nginx -t` | 本机未安装 Nginx，未验证 |

## 3. P0：代码与自动化门禁

### P0-1 修复供应商目录同步测试和接口契约不一致（已完成）

**现状与证据**

- 后端全量测试中的 `TestSyncProviderCatalogImportsThroughAdminTrigger` 期望目录同步成功，但实际收到业务状态码 `500`。
- `SyncProviderCatalog` 完成目录导入后，要求 `QueueClient` 必须存在且启用，否则返回 `error.tgx_inventory_refresh_failed`：`dujiao-next/internal/http/handlers/admin/admin_provider_catalog_sync.go:76`。
- 测试装配没有提供启用的队列客户端：`dujiao-next/internal/http/handlers/admin/admin_provider_catalog_sync_test.go:106`。

**需要决定并实现的契约**

二选一，不能只改断言掩盖行为：

1. 如果“目录导入成功”和“库存刷新入队成功”是同一个原子操作，则补齐测试中的可控 Queue fake，并增加入队失败时的行为测试。
2. 如果目录已经成功写库，而库存刷新只是后续动作，则接口应返回目录同步结果，同时明确报告库存刷新未入队；不要把已经完成的目录导入整体呈现为失败。

推荐采用第 2 种：数据库导入和异步刷新不是同一个可回滚事务，返回整体失败容易导致管理员重复触发同步。

**完成标准**

- 成功、Queue 禁用、入队失败三种路径都有确定测试。
- 重复点击不会产生不可解释的重复导入或重复任务。
- `go test ./internal/http/handlers/admin -count=1` 通过。
- `go test ./... -count=1` 通过。

### P0-2 补齐 TGX 单商品库存刷新接口的 RBAC 权限（已完成）

**现状与证据**

- 路由已注册：`POST /admin/product-mappings/:id/tgx-inventory`，见 `dujiao-next/internal/router/router.go:557`。
- 内置 `integration` 角色覆盖批量 TGX 库存同步，但没有覆盖该单商品接口，见 `dujiao-next/internal/authz/bootstrap.go:117`。
- `TestAllAdminRoutesCoveredByBuiltinRoles` 因该路由无任何内置角色策略而失败。

**整改动作**

- 将该权限分配给业务上最合适的内置角色，预期为 `integration`。
- 验证现有数据库中的内置角色策略升级/补种机制，不能只让新数据库生效。
- 验证无权限角色收到 `403`，有权限角色可以调用。

**完成标准**

- `go test ./internal/router -run TestAllAdminRoutesCoveredByBuiltinRoles -count=1` 通过。
- 新装和已有数据库升级后均具备正确策略。
- 管理后台对应按钮对有权角色可用，对无权角色不可用或明确提示。

### P0-3 让生产 Gate 1 拒绝保留域名和临时地址（已完成）

**现状与证据**

- `ops/prelaunch-audit.sh` 只拒绝 `CHANGE_ME` 和 `FINAL_*` 等占位符；对任意格式正确的 HTTPS 地址都会放行，见 `ops/prelaunch-audit.sh:180`、`ops/prelaunch-audit.sh:192`。
- 当前草稿仍使用 `target.example.com`、`admin.target.example.com` 和 `api.target.example.com`，但 Gate 1 报告 `0 failure`。
- 这会让 TLS、CORS、回调地址、canonical、sitemap 和浏览器 API 地址都未就绪的配置产生假绿结果。

**整改动作**

- 在后端配置、站点配置、前后台 env、Compose env 和 Nginx 配置中拒绝：
  - `.example`、`.test`、`.invalid`；
  - `localhost`、`127.0.0.0/8`、`::1`；
  - 已知项目样例主机 `target.example.com`。
- 保留容器内部和 Nginx upstream 使用 loopback 的合法场景，不应把私有监听地址误判为公开域名。
- 为合法生产域名、保留域名、localhost 和尾部路径错误分别增加 shell 回归夹具。

**完成标准**

- 当前 `deploy/production-local` 在替换域名前必须失败。
- 使用 `socialgurushub.com` 三个正式 origin 的夹具通过。
- Gate 1 在 CI 和部署前强制执行。

## 4. P0：生产配置与环境准备

### P0-4 将已确定域名写入全部生产配置（公网核心项已验证）

域名已经确定，不是待决事项：

- 商店：`https://socialgurushub.com`
- API：`https://api.socialgurushub.com`
- 后台：`https://admin.socialgurushub.com`

当前问题是本地生产草稿仍使用保留域名：

- `deploy/production-local/compose.env:10`
- `deploy/production-local/config.yml:99`
- `deploy/production-local/user.env.production:4`
- `deploy/production-local/admin.env.production:4`
- `deploy/production-local/site_config.json:5`
- `deploy/production-local/nginx/target-site.conf:26`

**整改动作**

- 统一替换 Compose、后端 CORS、前后台构建变量、站点配置、Nginx `server_name`、证书路径、CSP、支付 return/callback/webhook 地址。
- 为三个主机签发有效 TLS 证书，配置 DNS/CDN。
- 不在 Git 中提交真实密钥；生产配置应放在 `/etc/socialgurushub` 或批准的等价安全路径。

**完成标准**

- 全部公开地址使用上述三个正式 origin，无保留域名和临时域名。
- `docker compose config` 与 `nginx -t` 在目标主机通过。
- 三个域名的 HTTPS、证书链、跳转、CORS 预检和 API 请求通过。
- sitemap、robots、canonical、hreflang 和结构化数据只引用正式域名。

**2026-07-16 状态**

- DNS、HTTPS 证书、前台、后台、API health 和 storefront CORS 已通过公网只读验证。
- 证书自动续期机制、支付 callback/webhook、完整 SEO 输出仍需在目标主机或生产 E2E 中归档验证。

**2026-07-18 状态**

- 商店的 `/sitemap.xml` 已返回 `application/xml; charset=utf-8`，`/robots.txt` 已返回纯文本且指向 `https://socialgurushub.com/sitemap.xml`。
- 该两条路由通过商店 Nginx 的精确 location 反代至 API；完整 canonical、hreflang 与 SSR/prerender 仍需按 SEO 验收单独验证。

### P0-5 补齐三语法律、退款、可接受使用和支持内容（法律正文已上线，支持联系方式待补）

**现状与证据**

- `deploy/production-local/site_config.json` 没有 `legal` 区块。
- `contact.email`、Telegram、WhatsApp 均为空：`deploy/production-local/site_config.json:31`。
- 如果开放支付，空白条款、隐私和退款页面会形成用户争议与合规风险。

**整改动作**

- 完成简体中文、繁体中文和英文版本的：服务条款、隐私政策、退款/取消规则、数字交付说明、可接受使用规则、平台非隶属声明。
- 确定并填写可实际响应的支持邮箱；支付商户展示名称应与 `Social Gurus Hub` 一致。
- 由业务/法律负责人确认内容，不应仅由开发人员自行定稿。

**完成标准**

- 三种语言页面均有完整内容，移动端和桌面端可访问。
- 下单前能访问条款、隐私及退款规则。
- 支持邮箱可收发，退款和争议处理责任人明确。
- 最终内容与实际支付、交付和数据处理流程一致。

**2026-07-16 状态**

- 线上公开配置已有 `zh-CN`、`zh-TW`、`en-US` 的条款与隐私正文。
- 公开 `contact.email` 仍为空；Telegram 和 WhatsApp 也为空。至少需要一个真实可响应的支持渠道。

**2026-07-18 状态**

- 已通过公网 `/api/v1/public/config` 复核 `contact.email` 为 `support@socialgurushub.com`；该邮箱已完成 Zoho 收发和 SMTP 验证。
- 订单通知继续关闭，直至供应商履约和支付验收批准；需指定售后响应责任人。

### P0-6 完成生产首次初始化与管理员加固（项目方确认 VPS 已完成）

**整改动作**

- 在目标 PostgreSQL/Redis 上完成迁移和首次启动。
- 创建最终 owner 管理员，立即修改引导密码并清除配置中的引导凭据。
- 启用管理员 2FA，验证恢复流程。
- 导入最终站点配置，确认公开页面、上传资源和后台路径。

**完成标准**

- 配置和环境中没有默认管理员密码。
- owner 使用强密码和 2FA 登录成功。
- 无关管理员不具有支付、密钥、供应商或 RBAC 高权限。
- 管理员登录、权限拒绝、审计日志和密码恢复流程均经过验收。

**2026-07-16 状态**

- 项目方确认管理员 2FA 已在 VPS 完成。
- 由于本次会话没有 VPS SSH 或管理端认证信息，尚未独立复核 owner 2FA 状态、恢复码、最小权限和审计记录；应将截图或脱敏验收记录归档到上线签署材料。

### P0-7 建立自动备份并完成恢复演练（项目方确认 VPS 已完成）

**现状与证据**

- Compose 持久化 PostgreSQL、Redis、上传和日志，但没有声明定时、加密、异地备份服务：`ops/compose/docker-compose.production.yml:1`。
- 文档只有手工备份示例，不能证明恢复能力。

**整改动作**

- 配置 PostgreSQL 和上传文件的自动、加密、异地备份。
- 定义频率、保留期、RPO/RTO、失败告警和负责人。
- 在隔离环境执行一次数据库与上传文件恢复，记录耗时和结果。
- 上线切换前保存当前与上一版本镜像标签、配置和预上线快照。

**完成标准**

- 定时备份连续成功且失败会告警。
- 隔离恢复后可登录、查询订单、读取商品和访问上传资源。
- 恢复记录包含备份标识、校验、操作者、耗时和验收结论。

**2026-07-16 状态**

- 项目方确认 VPS 已完成备份恢复。
- 当前无法独立读取定时任务、异地存储、最近成功时间和恢复记录；应在最终 sign-off 中附脱敏的任务状态、最近备份、校验和恢复演练记录。

### P0-12 补齐线上安全响应头

**现状与证据**

2026-07-16 对商店、后台和 API 执行普通 HTTPS GET，均未观察到仓库 Nginx 模板声明的以下响应头：

- `Content-Security-Policy`
- `X-Frame-Options`
- `X-Content-Type-Options`
- `Referrer-Policy`
- `Permissions-Policy`

线上响应由 Nginx 返回，说明实际 VPS/CDN 配置与仓库模板尚不一致，或响应头在中间层被移除。由于前后台 token 使用浏览器存储，且站点支持自定义脚本，CSP 和防 framing 控制尤其重要。

**整改动作**

- 比对 VPS 生效的 Nginx 配置与 `ops/nginx/target-site.conf.example`。
- 对商店、后台和 API 分别设置合适的安全头；后台使用 `frame-ancestors 'none'`/`X-Frame-Options: DENY`。
- 在确认全部子域 HTTPS 和续期可靠后，再评估启用 HSTS；不要未经验证直接加 `includeSubDomains`。
- 检查 CDN 是否覆盖或移除源站安全头。

**完成标准**

- 三个正式域名通过普通 GET 返回预期安全头。
- CSP 不阻断支付、API、图片和必要的站点功能。
- 后台不能被第三方页面 iframe 嵌入。
- 将响应头检查加入生产 smoke 或监控。

**2026-07-18 状态（核心修复完成）**

- 根因是宝塔代理 `location ^~ /` 及其嵌套 `if` 设置了 `add_header`，阻断了 `server` 块安全头继承。现已在对应代理作用域显式 include 商店、后台和 API 安全头片段，并通过 `nginx -t` 与 reload。
- Cloudflare Managed Transforms 的“添加安全性标头”已关闭；此前它会将后台/API 的 `X-Frame-Options: DENY` 改写为 `SAMEORIGIN`。
- 公网复核确认商店、后台和 API 均返回 CSP、`X-Content-Type-Options`、`Referrer-Policy`、`Permissions-Policy` 和预期 framing 策略；后台/API 的 `X-Frame-Options` 为 `DENY`，API CSP 为 `default-src 'none'`。
- 仓库 Gate 2 已增加安全头、后台/API `DENY`、`/sitemap.xml` 和 `/robots.txt` 精确 API 路由的部署前检查。
- 2026-07-18 启用 Turnstile 时发现前后台 Vue locale 运行时使用 `new Function`。`script-src` 必须暂时保留 `'unsafe-eval'`，否则商店和后台会白屏；商店和后台还需允许 `https://challenges.cloudflare.com` 的 script/frame。API CSP 继续为 deny-all。
- HSTS 仍待三个子域证书自动续期可靠性的证据；生产浏览器 E2E 仍需验证 CSP 未影响登录、图片、API 和 Turnstile。预编译 locale 消息并移除 `'unsafe-eval'` 为 P1 安全整改。

### P0-8 明确 worker 与 inventory-worker 的上线开关（已完成）

**现状与证据**

- Compose 声明 `worker` 和 `inventory-worker` 均为 `restart: unless-stopped`：`ops/compose/docker-compose.production.yml:55`、`:71`。
- 切换手册要求支付/供应商批准前保持 `worker` 停止，但命令和说明没有同等明确地覆盖 `inventory-worker`：`docs/33-launch-cutover-runbook.md:122`、`:150`。

**整改动作**

- 明确两个 worker 的职责、外部副作用和分别启用条件。
- 首次启动命令只启动明确列出的服务，避免直接执行无服务名的 `docker compose up -d`。
- 可考虑使用 Compose profile，让履约 worker 和库存 worker 必须显式启用。
- 在切换、回滚、数据恢复和事故处理中同时写清两个 worker 的停止顺序。

**完成标准**

- 未批准时，两个 worker 的预期状态有明确验收记录。
- 启动/停止命令不会因 `restart` 策略意外恢复外部任务。
- 回滚或数据库恢复前能确认所有有副作用的 worker 已停止。

## 5. P0：必须在真实环境完成的验收

以下事项不能只靠代码审查或 mock 测试判定完成。

### P0-9 供应商真实目录、库存和履约验收

**验收范围**

- FansGurus/TGX 凭据、余额、限流和错误响应。
- 平台交集、Telegram 排除、上下架和零库存逻辑。
- FansGurus 原始数量计价与批准的加价规则。
- TGX CNY 到 USD 换算、`price` 基准和 20% 加价。
- 每个供应商至少一笔受控低价值履约。
- 重试、超时、状态轮询、取消边界和防重复提交。
- 日志不得泄露 API 密钥、TGX 账号秘密或交付内容。

**完成标准**

- 首次同步产生符合规则的可售 SKU，过滤统计经人工复核。
- 两个供应商各完成一笔受控订单，金额、数量、上游单号和最终状态一致。
- 重复回调、重复任务和人工重试不会创建重复上游订单。
- 失败场景可以停用连接、商品和 worker，并保留诊断信息。

### P0-10 PayPal 真实小额验收

首发仅计划启用 PayPal。支付宝网站支付已因当前业务类别被拒，项目方决定不申诉且不继续申请；微信支付及其他渠道均延后。除 PayPal 外的全部支付渠道必须保持禁用。

**完成标准**

- 仅登录用户可以下单和支付，游客接口持续拒绝。
- PayPal 渠道仅允许 `member` 和 `order`，钱包充值与游客支付保持关闭。
- 创建支付、签名验证、异步通知、同步返回和幂等处理通过。
- 订单币种、支付币种、换算金额、手续费和实际结算可核对。
- 错误金额、错误币种、伪造签名和重复回调不会把订单误标为已支付。
- 完成退款/取消边界和日终对账验证。

### P0-11 生产浏览器 E2E 与切换演练

**完成标准**

- 桌面端和移动端覆盖首页、商品、注册、登录、购物车、结算、支付、订单、交付和后台关键流程。
- `zh-CN`、`zh-TW`、`en` 路由、语言持久化及 SEO 输出正确。
- CDN/Nginx 安全头、上传限制、国家 header 和 CORS 正常。
- 切换前完成 DNS、证书、监控、回滚和至少一次内部 smoke。

## 6. P1：上线前建议完成

### P1-1 增加项目 CI 发布门禁

当前各应用工作流以 release 为主，根仓库没有统一的质量门禁。至少应自动执行：

- 后端 `go test ./...`；
- 用户端测试和两套前端生产构建；
- Gate 1、Gate 2 可在 CI 执行的部分；
- 依赖漏洞检查、secret scanning 和锁文件审计；
- 构建产物或镜像与提交 SHA 的关联记录。

完成标准：任何 P0 自动化失败时不能生成或提升生产发布版本。

### P1-2 为管理后台提供正式测试命令（已完成）

`admin/tests` 已有测试文件，但 `admin/package.json:7` 没有 `test` script。应配置确定的测试命令并纳入 CI，避免测试只能靠临时命令运行。

完成标准：`npm test` 或项目选定的统一命令可在干净环境稳定运行并返回正确退出码。

### P1-3 建立生产监控和可执行告警（项目方确认 VPS 已完成）

至少监控：

- 外部 HTTP/HTTPS 可用性与证书到期；
- 容器重启、CPU、内存、磁盘、数据库连接与容量；
- API 5xx、登录异常、支付回调失败；
- 供应商提交/轮询失败、库存同步失败、队列积压；
- 备份失败和最近一次成功备份时间。

完成标准：每个告警都有阈值、通知渠道、值班负责人和处理手册，并完成一次测试告警。

**2026-07-16 状态**

- 项目方确认 VPS 已配置监控。
- 当前没有只读监控地址或 VPS SSH 信息，尚未独立验证监控范围、告警送达和测试告警记录；最终上线材料应附脱敏证据。

### P1-4 修正生产路径和目标主机验证

当前 Gate 2 的 7 个 warning 包括 5 个相对数据路径，以及本机缺少 Docker Compose/Nginx。正式主机应使用批准的绝对路径，并实际执行：

```bash
docker compose --env-file /etc/socialgurushub/compose.env \
  -f ops/compose/docker-compose.production.yml config
nginx -t
```

完成标准：目标主机 Gate 2 无 failure，所有 warning 已解决或有书面风险接受。

## 7. P2：非阻断改进与技术债

### P2-1 清理休眠的游客订单代码

游客路由当前由统一中间件拒绝，但后端 handler/repository、前端 API/composable 和页面仍存在。应在确认没有历史游客订单读取需求后，进行一次协调清理；在此之前保留路由级 `401` 回归测试。

### P2-2 降低浏览器 token 和自定义脚本风险

当前用户端/后台 token 使用 `localStorage`，站点配置还支持管理员提供的自定义脚本。上线时应保持自定义脚本为空、严格 CSP、短 token 有效期和管理员最小权限；后续评估 Secure/HttpOnly/SameSite cookie 与明确的 CSRF 模型。

### P2-3 固定容器镜像版本

避免生产运行时依赖 `latest` 或可变 minor tag。固定经过验证的版本或 digest，并记录升级与回滚周期。

### P2-4 建立官方 upstream 合并流程

定制后端、用户端和后台均已明显领先官方上游，不能直接 merge。应定期：

1. 抓取 `upstream/main`；
2. 审查安全/兼容性修复；
3. 在适配分支 cherry-pick 或移植；
4. 运行全量测试与 staging 回归；
5. 记录接受或暂缓原因。

本次发现官方上游各有一个 Telegram 深链修复提交。由于当前生产策略禁用 Telegram 登录并排除 Telegram SKU，该更新不直接阻断上线，但仍应按上述流程评估。

## 8. 建议执行顺序

1. 修复 P0-1、P0-2，使后端 `go test ./... -count=1` 全绿。
2. 修复 P0-3，让示例域名配置不再通过 Gate 1。
3. 归档已上线法律正文、DNS/TLS/CORS、安全头与支持邮箱的验证结果；取得证书自动续期证据后再评估 HSTS。
4. 归档 VPS 上 P0-6、P0-7、P1-3 的内部验收证据，并完成目标主机 Gate 2 记录。
5. 完成 P0-9 供应商验收，再完成 P0-10 各支付渠道小额验收。
6. 完成 P0-11 生产 E2E、切换和回滚演练。
7. 由产品、技术、运维、支付和供应商负责人共同签署上线结论。

## 9. 最终上线判定

只有同时满足以下条件，结论才能从 `NO-GO` 改为 `GO`：

- 后端全量测试、用户端测试、前后台构建全部通过；
- 正式域名、TLS、CORS、CSP、SEO 和回调地址全部验证通过；
- 管理员加固、法律内容、监控、备份和恢复演练完成；
- 首次 SKU 同步和供应商真实履约验收通过；
- 每个启用支付渠道完成真实小额验收；
- 生产浏览器 E2E、切换和回滚演练通过；
- 所有启用项有负责人签字，未启用项在技术上保持关闭。

在此之前，允许部署到 VPS/staging 并继续验收，但不得开放生产付费流量。
