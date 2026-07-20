# 项目审查报告

审查日期：2026-07-17  
审查范围：当前发布分支、生产公网只读检查、部署草稿、自动化测试与构建。  
支付范围：支付渠道未启用，且按项目方要求不作为本报告的缺陷判断范围。  
结论：**可继续内部测试与 staging；除支付外，当前仍不满足对外公开上线条件。**

最后更新：2026-07-19（商品目录、计价、自定义评论数量与客户文案整改复核）。

## 持久记忆

以下事实是本轮后续工作必须沿用的项目上下文，除非项目方明确更新：

- 线上公开商品数量为 `0` 是测试阶段的刻意策略，**不是缺陷**，不应被记录为目录同步故障。
- 正式开放前仍需完成 SKU 上架、两个供应商真实验收，以及通过受控低金额订单确认履约、重试和幂等行为。
- 线上当前未启用支付渠道；支付功能及其真实小额验收不属于本报告的缺陷判断范围。
- 公开下单必须登录；`/api/v1/guest/*` 仍应持续返回 `401`。
- 站点正式域名为 `socialgurushub.com`、`api.socialgurushub.com`、`admin.socialgurushub.com`。
- 邮件服务使用 Zoho Mail：`support@socialgurushub.com` 是当前实际收发与 SMTP 发件地址；SMTP 凭据仅保存在 VPS 受保护的 `config.yml` 与后台运行时设置中，绝不写入 Git 或前端变量。
- 注册邮箱域名白名单已于 2026-07-18 关闭；注册和找回密码的验证码受 Cloudflare Turnstile 保护，邮箱验证保持开启。Gmail 已完成注册、验证码、登录和找回密码验收；项目方决定不再单独执行 Outlook 验收。
- 首发支付策略为**仅 PayPal**。PayPal 已存在于项目配置能力中，但尚未完成真实小额支付、Webhook 验签、金额核对和重复通知幂等验收；在验收通过前必须保持停用。
- 支付宝和微信支付均不属于当前首发范围。不要用不匹配的类目、个人收款码、借用商户号或未经授权的第四方聚合渠道规避商户准入。
- Payoneer 的美国/香港 Receiving Account 仅可作为未来已获 Payoneer 书面批准的 B2B 客户/代理商汇款备选；不得公开给个人消费者作为商城收银台，也不得仅凭汇款截图履约。
- 2026-07-18 已在公网确认商店、后台和 API 的 CSP、`X-Frame-Options`、`X-Content-Type-Options`、`Referrer-Policy` 与 `Permissions-Policy`；后台和 API 均为 `X-Frame-Options: DENY`，不得由 CDN 改写为 `SAMEORIGIN`。
- 宝塔反向代理规则中的 `location`/嵌套 `if` 若设置了 `add_header`，会阻断上层安全头继承；重新保存宝塔反向代理规则可能覆盖当前安全头 `include`，每次改动后必须重新执行 `nginx -t`、reload 与三域公网响应头检查。
- HSTS 尚未启用。必须先获得三个正式子域证书自动续期可靠的证据，再单独评估是否启用；本项不能被误报为已完成。
- 当前前后台 Vue 多语言运行时依赖 CSP 的 `script-src 'unsafe-eval'`；商店和后台还需允许 `https://challenges.cloudflare.com` 的 script/frame 以支持 Turnstile。此为临时兼容性放宽，不允许扩展为通配来源，后续必须改用预编译 locale 消息后移除 `unsafe-eval`。
- VPS 已确认目录必须直接作为后续操作命令的依据：Git 仓库分别为 `/srv/target-site/dujiao-next`、`/srv/target-site/user`、`/srv/target-site/admin`；部署/Compose 仓库为 `/srv/target-site/FansProject`，Compose 工作目录为 `/srv/target-site/FansProject/ops/compose`。不要假设源码位于 `/srv/target-site/FansProject/` 下。
- VPS Compose 唯一确认的环境文件为 `/etc/target-site/compose.env`，后端受保护配置为 `/etc/target-site/config.yml`；不得使用不存在的 `/etc/socialgurushub/compose.env`。
- 正常前后台部署只允许重建明确指定的服务，例如 `api user`；`worker` 和 `inventory-worker` 默认保持停止，未经项目方明确授权不得启动、不得创建测试订单或触发供应商履约。
- BT Panel Nginx 代理配置不在 Git 中，父目录为 `/www/server/panel/vhost/nginx/proxy/{socialgurushub.com,admin.socialgurushub.com,api.socialgurushub.com}/`，安全头片段位于 `/www/server/panel/vhost/nginx/snippets/`。宝塔可能重建具体代理文件名；每次改动必须重新检查三域安全响应头。

## 2026-07-19 商品目录、计价与客户文案整改

本节记录已上架的 5 个人工审核 SKU 的真实数据核对和本轮代码整改，避免后续同步或运营编辑将未核验信息当作既定规则。

- TGX SKU `9F864E90ECA0070E` 的真实对应库存已核对为 `17`。此前截图中的 `1840` 属于另一 SKU，不构成库存同步或映射故障。
- FansGurus 原始目录数据中，`10525`、`10526`、`13920` 都只有 `rate`、`min`、`max` 与 `type`，没有计价单位字段。不得因来源名称、服务类型或历史经验自动将所有此类商品设为“每 1000”计价。
- `13920` 的真实页面已人工验证为每 1000 单位计价：`rate=4.00`、数量 `10` 时原价为 `$0.04`，其有效数量范围为 `10` 至 `5000`，服务类型为自定义评论。该 SKU 的 `price_quantity_basis=1000` 有实际证据。
- `10525`、`10526` 的现有 `price_quantity_basis=1000` 仅暂时保留，避免本轮部署改变已上架商品的售价；这不是新的真实性证明。运营人员必须在各自真实详情页核对结算金额后，才可确认或通过后台改写其计价基准。
- 目录同步仅在原始响应明确给出 `price_quantity_basis`、`price_per`、`rate_per` 或 `quantity_basis` 时更新计价基准。新导入且未获明确单位的服务使用数据库占位值 `1`，并保持待审核、下架状态，不能直接公开销售。
- 客户可见的商品、库存、提示、公告、公共 API 和订单文案不得出现或暗示“上游”“供应商”“履约链路”“provider”“procurement”。内部管理后台、日志和数据库字段可以保留必要的技术术语，但不能透传给客户。
- 自定义评论服务以每个非空评论行为一项：前端填写时实时同步数量和预览，后端以相同规则计算订单数量与金额，提交给服务接口时只传 `comments`，不伪造 `quantity` 参数。该行为尚未创建真实订单或启动 worker。
- 商品详情、商品卡、列表、购物车、结算回退金额均按 `价格 × 数量 ÷ 计价数量基准` 计算并显示；不向客户展示内部“/1000”技术标记。后台 SKU 编辑页提供三语“计价数量基准”字段，供已完成真实核验的运营人员维护。

2026-07-20 公网复核已确认测试商品 `ceshi` 已下架，公开目录恢复为已审核的 5 个 SKU。复核同时发现两个 TGX 商品仍保留了自动导入的原始详情，其中包含“联系平台商家”、第三方 URL 和来源式说明；这违反客户不可感知外部履约来源的约束。后端整改为：后续 TGX 目录同步只写入本站通用的本地说明；一次性数据库迁移会替换已有 TGX 映射商品的描述和正文，而不修改标题、价格、库存、SKU、表单或上架状态。该修复部署后必须重新通过公开 API 和页面核验这两个商品不再显示旧详情。

本轮部署限制：只允许重建 `api user`；不得启动 `worker` 或 `inventory-worker`，不得创建测试订单或触发实际服务处理。已上架的 5 个商品保持上架状态，部署后仅做浏览、价格和表单的只读验收。

## 2026-07-20 商品资料同步与脱敏实施

已实施独立的商品资料同步方案，详细操作与验收见 `docs/37-provider-catalog-content-sync.md`。FansGurus 通过一次读取其公开服务页的内嵌数据获取类别、名称、描述、平均时间和服务类型；TGX 复用已有目录 API 的 `description`。两者均按已有映射匹配，增量更新客户商品标题、摘要和详情，绝不修改价格、库存、SKU、购买表单、审核状态、上架状态或订单。

公开文案在服务端清洗 URL、邮箱、品牌、外部来源、外部商家和客服引流语句，并由服务端转义后输出。Telegram/电报语义仍在资料同步前排除。原始资料只存入映射记录作后台追溯，不经公开商品 API 返回。

资料同步使用新的 `catalog-content-worker` 和独立 `catalog-content` 队列；它不登记订单履约处理器，也不会像 `inventory-worker` 那样启动时触发库存同步。部署和首次运行时，只能启动此独立 worker，不能把资料同步作为启动 `worker` 或 `inventory-worker` 的理由。

## 2026-07-17 支付渠道决策

本轮围绕中国大陆个体工商户主体完成了支付宝可行性调查。结论是当前业务不适合继续申请国内支付宝网站支付，首发渠道收敛为 PayPal。

| 渠道 | 当前结论 | 事实与后续动作 |
| --- | --- | --- |
| PayPal | 首发唯一候选，暂未启用 | 保持 `official/paypal` 渠道仅允许登录会员的订单购买；完成真实小额支付、Webhook、金额/币种、重复通知和安全交付验收后，才可启用。 |
| 支付宝 | 暂停，不申诉 | 个体工商户商家号已开通；网站支付申请被拒，原文原因为“涉及恶意软件或虚拟卡密，无法合作”。此为业务准入拒绝，不是代码、回调、ICP备案或境外服务器故障。不得重复申请或通过改类目规避。 |
| 微信支付 | 暂缓 | 项目方决定不再申请；未来如恢复评估，须以真实业务、准入规则和书面批准为前提。 |
| Stripe / 易支付 / 未知聚合商 | 暂不申请 | 代码支持不代表服务商允许社媒互动服务与数字账号交付；不得将技术适配当作商户准入。 |
| 加密货币（DujiaoPay、BEpusdt、TokenPay 等） | 暂不公开启用 | 现有代码存在适配，但中国大陆个体工商户使用虚拟货币收款存在合规、税务、资金安全、退款和钱包私钥管理风险；需取得专业法律/税务意见及服务商书面准入后再评估。 |
| Payoneer Receiving Account | 仅未来 B2B 备选 | Payoneer 规则通常要求商业付款且付款来源为企业账户；当前项目没有银行转账待审核支付链路，不可作为个人消费者支付方式。 |

PayPal 验收时的固定约束：

1. 不向前端、Git、日志或项目文档写入 Client Secret、Webhook Secret、账户号或其他支付凭据。
2. `payment_roles` 仅为 `member`，`payment_types` 仅为 `order`；不开放游客付款或钱包充值。
3. 在商品仍为 `0` 的测试阶段，只能使用受控测试商品或经批准的低金额订单；供应商真实履约 worker 默认保持停止。
4. 付款成功必须由服务端 PayPal 回调/Webhook 和金额、币种、订单归属校验触发；同步回跳、用户截图或前端页面均不得作为发货依据。
5. 若验收不通过，禁用 PayPal 渠道，但保留回调端点处理已创建订单，并按支付工作单进行对账和回滚。

## 2026-07-17 邮件服务配置进度

本轮已由项目方在 Zoho Mail、Cloudflare、VPS 和管理后台完成以下操作，并进行了实际邮件验证：

| 项目 | 状态 | 验收证据 |
| --- | --- | --- |
| Zoho 域名所有权 | 已完成 | `socialgurushub.com` 已在 Zoho 验证。 |
| 收件 MX | 已完成 | Zoho 验证域名 MX 已指向 `mx.zoho.com`、`mx2.zoho.com`、`mx3.zoho.com`。 |
| SPF / DKIM / DMARC | 已完成 | 三项均在 Zoho 验证；DMARC 采用监测模式 `p=none`。 |
| 收发邮箱 | 已完成 | `support@socialgurushub.com` 已设为现有 Zoho 邮箱的主 Mailbox Address，外部收发测试通过。 |
| Zoho 账户安全 | 已完成 | 已启用 TFA，并生成仅供项目 SMTP 使用的应用专用密码。密码未记录于本仓库。 |
| VPS SMTP 配置 | 已完成 | `/etc/target-site/config.yml` 的 `email` 区块已改为 Zoho SMTP，使用 `smtp.zoho.com:587`、STARTTLS。 |
| 后台运行时 SMTP 设置 | 已完成 | 管理后台 SMTP 测试邮件发送成功。后台 settings 优先于 `config.yml`，两处必须保持一致。 |
| 注册验证码 | 已完成 | 测试期允许域名中的 `support@socialgurushub.com` 已收到商城注册验证码。 |

2026-07-18 已通过公网 `/api/v1/public/config` 复核公开站点 `contact.email` 为 `support@socialgurushub.com`。订单邮件通知保持关闭，直至履约 worker 和供应商验收获批。

## 2026-07-18 外部注册与 Turnstile 验收

项目方已在 Cloudflare 创建 Turnstile 小组件，允许 `socialgurushub.com` 与 `admin.socialgurushub.com`，模式为 Managed，且未开启已验证访问者绕过安全规则。密钥仅保存于后台运行时设置，未写入 Git、前端或本报告。

线上公开配置已复核为：

- `registration_enabled=true`；
- `email_verification_enabled=true`；
- `email_domain_allowlist_enabled=false`；
- CAPTCHA provider 为 `turnstile`，只启用 `register_send_code` 与 `reset_send_code`；登录场景继续关闭。

实际验收：Gmail 已完成 Turnstile、注册验证码收取、账号注册、登录和找回密码。项目方明确决定不再单独执行 Outlook/Hotmail 验收，作为该项的已接受测试覆盖限制。外部注册已开放；应监控邮件退信、验证码请求异常和注册滥用。

## 审查基线

已执行 `git fetch --prune`，并确认五个工作区均干净、与各自 `origin/main` 一致：

| 仓库 | 提交 |
| --- | --- |
| 根部署仓库 | `6d35303` |
| 后端 `dujiao-next` | `1745d77` |
| 用户前台 `user` | `638b1d7` |
| 管理后台 `admin` | `0c5a205` |
| 文档 `document` | `6ba213c` |

## 上线结论

| 场景 | 结论 | 原因 |
| --- | --- | --- |
| 内部测试 / staging | 可继续 | 代码测试、前后台构建及核心访问限制通过。 |
| 外部用户注册与浏览 | 已开放，持续监控 | 外部白名单已关闭；Gmail 完整注册与找回密码、Zoho SMTP 和 Turnstile 已验收。Outlook 未单独测试，属项目方接受的覆盖限制。 |
| 非支付公开上线 | 不可开放 | 外部客户注册策略、供应商真实履约、备份/恢复/监控证据、生产浏览器 E2E 与切换演练尚未完成；安全头和 sitemap/robots 路由已在 2026-07-18 修复。 |
| 商品上架 | 上线前运营动作 | 测试阶段保持 0 商品符合当前策略；不作为缺陷。 |

## P0：公开上线阻断项

### P0-1 外部客户注册策略（已完成，含已接受的邮箱覆盖限制）

审查初始状态的线上公开配置显示：

- `registration_enabled=true`；
- `email_domain_allowlist_enabled=true`；
- `allowed_email_domains=["socialgurushub.com"]`；
- `smtp_enabled=false`、`email_verification_enabled=false`。

此状态已在 2026-07-17 部分整改：Zoho SMTP、后台 SMTP 测试邮件及测试期注册验证码均已通过。2026-07-18 已关闭 `email_domain_allowlist_enabled`，前台注册页恢复完整邮箱输入；后端仍保留域名策略校验，见 `user/src/composables/useRegister.ts:49` 与 `dujiao-next/internal/http/handlers/public/user_auth.go:123`，但策略关闭后不再阻断外部域名。

Cloudflare Turnstile（Managed）已只用于“注册发送验证码”和“找回密码发送验证码”。Gmail 已通过 Turnstile、收取验证码、注册、登录和找回密码；项目方明确决定接受该覆盖并不再单独测试 Outlook/Hotmail。此 P0 项关闭。

持续要求：监控验证码发送频率、邮箱退信和异常注册；如发生滥用，先在 Cloudflare/后台收紧 CAPTCHA 或限流，不要重新启用只允许内部域名的白名单作为常规方案。

### P0-2 支持联系方式（已完成）

审查初始状态的线上公开配置中 `contact.email`、Telegram、WhatsApp 均为空。本地生产草稿的 Gate 1 也实测失败，唯一失败原因是缺少支持邮箱与三语法律内容的完整输入；线上三语条款和隐私正文已经存在，但无可用售后入口。

2026-07-17 已创建且验证 `support@socialgurushub.com` 的实际收发能力。2026-07-18 已通过公网 `/api/v1/public/config` 确认 `contact.email` 已保存为该地址，因此本项关闭。Git 中的生产草稿仍缺脱敏后的法律/联系资料，导致本地 Gate 1 不能代表线上实际状态；不要为消除这一告警而把生产密钥或其他敏感配置提交到仓库。

剩余运营要求：指定实际值班/响应责任人，并在开放支付或订单邮件前完成售后流程验收。

### P0-3 线上安全响应头（核心修复已完成；HSTS 与浏览器 E2E 待后续验收）

2026-07-17 对商店、后台和 API 进行公网 HTTPS GET 检查：

- 已收到 `X-Content-Type-Options`、`X-Frame-Options` 和 `Referrer-Policy`；
- 缺少 `Content-Security-Policy`、`Permissions-Policy`、`Strict-Transport-Security`；
- 后台实际返回 `X-Frame-Options: SAMEORIGIN`，而部署模板要求 `DENY`。

仓库 Nginx 模板已声明 CSP、Permissions Policy 和后台 `DENY`，见 `ops/nginx/target-site.conf.example:39`。这说明 VPS/CDN 生效配置与仓库模板不一致。前后台令牌存储在浏览器 `localStorage`，使 CSP 与防嵌入控制尤为重要。

2026-07-18 已完成根因修复并进行源站和公网复核：宝塔反向代理的 `location ^~ /` 及其设置缓存头的嵌套 `if` 使用了 `add_header`，使站点 `server` 块的安全头不再继承。现已在对应作用域显式引入商店、后台和 API 的安全头片段；商店还为 `/sitemap.xml`、`/robots.txt` 增加精确 API 反代。Cloudflare Managed Transforms 的“添加安全性标头”已关闭，避免其将后台/API 的 `DENY` 覆盖为 `SAMEORIGIN`。

公网 HTTPS 复核结果：

- 商店返回 CSP、`Permissions-Policy`、`X-Content-Type-Options: nosniff`、严格 `Referrer-Policy` 和 `X-Frame-Options: SAMEORIGIN`。
- 后台返回 CSP `frame-ancestors 'none'`、`Permissions-Policy`、`X-Content-Type-Options: nosniff`、`Referrer-Policy: no-referrer` 及 `X-Frame-Options: DENY`。
- API `/health` 返回 deny-all CSP（`default-src 'none'`）、`Permissions-Policy`、`X-Content-Type-Options: nosniff`、`Referrer-Policy` 及 `X-Frame-Options: DENY`。
- VPS `nginx -t` 与 reload 均成功；2026-07-18 Cloudflare 公网响应仍保留后台/API 的 `DENY`，确认 CDN 未再改写。

已完成的标准：

1. 已对 VPS Nginx 与 Cloudflare 生效规则逐项比对并修复。
2. 三个正式域名均返回所需 CSP、Permissions Policy；后台/API 均拒绝 iframe 嵌入。
3. 仓库部署前 Gate 2 已检查 Nginx 模板中的 CSP、Permissions-Policy、后台/API `DENY` 和 sitemap/robots 精确路由。

尚未完成：确认所有子域 TLS 自动续期后再评估 HSTS；在生产浏览器 E2E 中确认 CSP 不影响登录、图片、前后台 API 和未来经批准的第三方脚本。当前 Vue 多语言运行时需要 `'unsafe-eval'`，且 Turnstile 需要 `https://challenges.cloudflare.com` 的 script/frame 白名单；必须在预编译 locale 消息后移除 `'unsafe-eval'`，不得继续放宽来源。

### P0-4 供应商真实履约验收尚无证据

商品为 0 是测试策略，不视为 bug；但该状态也不能证明 FansGurus/TGX 的真实凭据、目录、价格、库存、履约、超时、重试、取消和幂等行为。worker 与 inventory-worker 使用显式 Compose profile，默认不会启动，这是正确的防副作用设计，见 `ops/compose/docker-compose.production.yml:55`。

完成标准：

1. 在两个 worker 均停止的条件下导入目录，人工确认平台白名单、Telegram 排除、售价与库存策略。
2. 两个供应商各完成一笔受控低金额订单，核对金额、上游订单号、交付和最终状态。
3. 验证重复任务/回调/人工重试不会产生重复上游订单。
4. 记录停用连接、停止 worker 与人工介入的演练结果。

### P0-5 备份、恢复和监控缺少独立验收材料

Compose 提供服务健康检查，但未声明备份、异地存储、监控或告警服务。项目方此前确认 VPS 已完成相关工作；本轮没有 VPS 只读访问或脱敏证据，无法独立复核。

完成标准：归档最近一次备份、异地存储、保留策略、失败告警、恢复演练耗时与结果，以及 HTTP/容器/磁盘/数据库/供应商失败的监控告警测试。

## P1：上线前应修复

### P1-1 商店域名的 sitemap 和 robots 路由（已完成）

`https://socialgurushub.com/sitemap.xml` 返回 `text/html` 的 SPA 首页，而非 XML sitemap；商店域名的 `robots.txt` 末尾也被 SPA HTML 回退内容污染。API 域名对应端点则能正确生成 XML 和文本，见 `dujiao-next/internal/http/handlers/public/sitemap.go:11`。

原因是商店 Nginx 仅将 `/api/v1/` 反代至 API，`/sitemap.xml` 和 `/robots.txt` 落入前台 SPA 的 `location /`。

2026-07-18 已在宝塔商店域名配置中将两个精确路径反代至 `127.0.0.1:8080`，并通过公网复核：`https://socialgurushub.com/sitemap.xml` 返回 `200` 和 `application/xml; charset=utf-8`，正文为 XML；`https://socialgurushub.com/robots.txt` 返回 `text/plain; charset=utf-8`，包含 `Sitemap: https://socialgurushub.com/sitemap.xml`。本项关闭。搜索引擎收录与完整 SSR/prerender 仍属于 P1-2 的后续工作。

### P1-2 SEO 依赖浏览器 JS，初始 HTML 不可发现

首页和三语言 URL 的初始 HTML 全部为 `<html lang="en">` 与空 `<title>`，没有服务端 `description`、canonical 或 hreflang。前端路由和客户端 SEO 逻辑存在，见 `user/src/router/index.ts:125`，但非 JS 爬虫无法可靠读取内容。

完成标准：对首页、分类、商品和文章采用 SSR/prerender，或由边缘层输出预渲染 HTML；至少保证服务端响应有正确的语言、title、description、canonical 与 alternate links。若自然搜索是主要获客渠道，此项应升为 P0。

### P1-3 富文本、自定义脚本与 CSP `'unsafe-eval'` 的 XSS 风险

法律页直接渲染 `v-html`，见 `user/src/views/Legal.vue:17`。后台可配置站点富文本；站点自定义脚本会创建并插入可执行 script 元素，见 `user/src/utils/customScripts.ts:100`。线上当前 `scripts=[]`，应继续保持空。2026-07-18 发现当前 Vue 多语言运行时会通过 `new Function` 编译消息；禁止 CSP `'unsafe-eval'` 会使商店和后台白屏，因此线上暂时保留 `'unsafe-eval'`。这弱化了 CSP 的 XSS 缓解能力。

完成标准：后端保存时清洗富文本、前端渲染时使用 DOMPurify；限制自定义脚本权限和使用场景；将 locale 消息预编译为不需要运行时编译的构建产物后移除 `'unsafe-eval'`；安全头仅允许本站、API 和经批准的 Turnstile 域名。

### P1-4 缺少生产浏览器 E2E 门禁

当前自动化测试覆盖单元和组件逻辑，尚未发现可执行的生产浏览器 E2E/smoke 套件。上线前需要覆盖外部注册、登录、SKU、订单、交付、后台最小权限、三语、SEO 与安全头。

完成标准：在 staging 增加只读 smoke 及受控 E2E，纳入发布前 gate，并保留运行记录。

## P2：技术债与改进项

- 前后台 Bearer Token 保存在 `localStorage`，见 `user/src/stores/userAuth.ts:9`、`admin/src/stores/auth.ts:85`。短期需依靠 CSP、2FA、最小权限；中期建议迁移至 Secure/HttpOnly/SameSite Cookie 加 CSRF 模型。
- 后端运行镜像使用 `alpine:latest`，前端使用可变镜像 tag。应固定审计过的版本或 digest，并保留上一版本用于回滚。
- 本地 Gate 2 通过但有 7 个 warning：五个运行数据路径为相对路径，本机未安装 Docker Compose 与 Nginx，因而没有执行 `docker compose config` 和 `nginx -t`。这两项必须在 VPS 上完成。
- 前后台生产构建有 pnpm 配置迁移与 Browserslist 数据过期告警；不阻断发布，但应清理。

## 已验证通过

| 验证 | 结果 |
| --- | --- |
| 后端 `go test ./... -count=1` | 通过 |
| 前台 `pnpm test` | 通过，28/28 |
| 前台 `pnpm build` | 通过 |
| 后台 `pnpm test` | 通过，13/13 |
| 后台 `pnpm build` | 通过 |
| 公网 HTTPS：商店、后台、API health | 均返回 200 |
| 公开支持邮箱 | `/api/v1/public/config` 返回 `support@socialgurushub.com` |
| 外部注册与找回密码 | Gmail 已完成 Turnstile、验证码、注册、登录和找回密码；白名单已关闭，Outlook 未单独执行（项目方接受） |
| 公网安全头 | 三域返回 CSP、Permissions-Policy 和预期 framing 策略；后台/API 为 `DENY` |
| 商店 sitemap / robots | 分别返回 XML 与纯文本，robots 指向正式域名 sitemap |
| API CORS（商店 origin） | 返回指定 origin 和 credentials |
| 游客订单 GET/POST | 均返回 401，登录后下单限制生效 |
| 上传校验 | 文件类型、尺寸和危险 SVG 内容均有实现与测试 |

首次在受限沙箱运行后端测试时，部分 `httptest` 用例因无法监听 `::1` 而失败；在允许回环监听的同一代码基线复跑后全量通过，因此该首次失败是环境限制，不是代码回归。

## 建议执行顺序

1. 在 staging 上完成供应商目录、价格、库存和受控履约验收后再上架商品。
2. 确定 SSR/prerender 的 SEO 方案；自然搜索为主要获客渠道时，将 P1-2 升为 P0。
3. 消除前后台 locale 运行时编译对 CSP `'unsafe-eval'` 的依赖，并完成富文本/自定义脚本 XSS 加固。
4. 归档备份、恢复、监控、生产浏览器 E2E 与切换演练的证据；取得证书自动续期证据后再决定是否启用 HSTS。
