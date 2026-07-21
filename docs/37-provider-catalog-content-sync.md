# 商品资料同步与客户文案清洗

更新时间：2026-07-20

## 目的与不变量

商品资料同步用于补全客户商品页的细分类别、说明、处理时间和填写要求。它与目录、价格和库存同步严格分离。

- 只更新已有 FansGurus 和 TGX 映射商品的标题、摘要与详情。
- 不创建或删除商品，不改变价格、成本、计价数量基准、库存、SKU、审核状态、上架状态或订单。
- TGX 的购买表单和交付展示是唯一会在资料同步中更新的交易前资料；更新范围严格限于该映射商品自身的资料接口，绝不从某个 SKU 推断或复制到其他 SKU。
- Telegram、电报及其相关商品始终跳过；资料同步不能使其重新出现。
- 客户可见页面、接口和文案不得出现或暗示 FansGurus、TGX、上游、供应商、货源、外部商家或外部客服。明确标为客户使用教程/登录指南的链接可保留；下载、外部工具、来源和客服引流链接必须删除。
- 原始类别、描述、平均时间、内容哈希与同步时间仅保存在 `product_mappings`，用于后台追溯；公开商品接口只读取清洗后的 `products` 字段。

## 资料来源

| 商品来源 | 读取方式 | 读取频率 |
| --- | --- | --- |
| FansGurus | 公开页面 `https://fansgurus.com/zh/services` 内嵌的 `let data = [...]` | 每次资料同步只请求一次页面，不是逐 SKU 请求 |
| TGX | 目录 API 的 `description`、`category`、`name`，以及每个已启用映射商品的 `/commodity/item` | 目录一次；单商品资料按限流顺序请求 |

FansGurus 认证目录接口只包含价格、最小/最大数量和服务类型等基础资料；富说明位于公开页面。解析器只读取内嵌的受限 JavaScript 字面量，不执行网页 JavaScript，页面读取上限为 24 MiB。公开页面实测约 10.8 MiB，包含约 4,900 条描述字段；因此数千 SKU 的全量资料更新是一次页面下载与本地解析，不会造成每个 SKU 各发一次请求。

每个来源资料均以 `provider + upstream_product_code` 匹配已有映射。来源字段的 SHA-256 未变化时不写数据库，避免无意义更新。

## TGX：逐 SKU 购买资料

TGX 的 `widget`、`contact_type`、`delivery_way` 可能因商品而不同，目录列表和单商品页面也可能不一致。因此不能采用“所有 TGX 商品都填写邮箱”“所有商品都是自动交付”之类的来源级规则。

资料同步对每条已启用的 TGX 映射按以下优先级处理：

1. 已人工核验并锁定的本地表单覆盖。仅影响对应的 `upstream_product_code`；保留真实提交键（例如 `contact`），只修正本地显示、提示与校验类型。
2. 该商品的 `/commodity/item` 响应。读取该商品自己的 `widget`、`contact_type`、`delivery_way`，生成购买字段与自动/人工交付展示。
3. 目录列表中同一商品的字段。仅当单商品请求失败或接口不支持时作为回退。
4. 无法验证时不猜测字段含义；保留现有已知资料，并将本次单商品资料请求计为失败，供后台同步记录排查。

同步使用与库存/下单共享的 TGX 请求限流，默认最多每秒 4 个请求、单线程执行。约 1,200 个已启用 TGX 商品在接口稳定且无重试时约需 5 分钟；不会并发轰炸接口，也不会创建订单、触发交付或修改库存。资料同步运行记录会额外显示 `tgx_profile_pulled` 和 `tgx_profile_failed`；存在失败时运行状态为 `partial`，但已成功解析的商品仍安全更新。

当前已人工核验的例外只有 `A821AB6AEEECA7C1`：真实页面要求的是用于订单查询的邮箱，不是手机号码。该条映射被锁定为 `contact` 键的邮箱字段；此事实不得推广到任何其他商品。后续若核验其他 SKU，应为那一条映射创建独立覆盖，而非改写全局 TGX 规则。

客户表单可以显示每个字段自身的标签、占位文本和说明。订单校验与采购转发仍使用字段原始键和值，因此显示层修正不会改变该商品接口所需的提交参数。

## 本地账号使用指南

站内 `/guides/account-access` 是原创的通用使用说明，只在本地 `platform-outlook`、`platform-hotmail`、`platform-overseas-email` 分类商品详情页提供入口。它说明在本站订单中查看交付字段、使用对应服务的官方登录入口，以及仅在订单明确提供资料时配置 OAuth2/POP/IMAP。

- 不复制第三方页面、图片、代码、品牌或链接。
- 不包含 Telegram 相关内容。
- 不承诺订单资料中不存在的字段、协议或时限。
- 不出现或暗示外部来源、供货链路或外部商家。

## 清洗规则

清洗在服务端发生，原始 HTML 不会直接返回给客户：

1. HTML 转为纯文本，再由服务端 HTML 转义后生成商品详情。
2. 删除邮箱、下载链接以及无明确用途的 URL；仅“教程/教学/指南/login tutorial”等明确客户使用教程链接保留为带 `noopener noreferrer nofollow` 的“查看教程”链接。
3. 丢弃含外部来源或联络语义的整行，例如品牌名、`upstream`、`supplier`、`provider`、`merchant`、上游、供应商、货源、服务商、平台商家、来源、联系客服、WhatsApp、Telegram、`t.me`。
4. 若出现外部工具品牌（例如心蓝）或工具下载/导入流程，不能直接保留该工具步骤；应提取并重写为客户可独立使用的交付字段和中性使用说明。例如保留“邮箱地址、密码、客户端标识、授权信息”及“使用支持 OAuth2 的邮件客户端通过 POP/IMAP 配置”，删除工具品牌、下载地址和导入/解析步骤。
5. 保留可验证且可独立使用的商品信息，例如数量范围、质量、开始时间、速度、账号格式、使用注意事项和目标链接要求；清洗后若只剩标题而无法说明交付内容或使用方式，商品不得继续公开销售，必须人工补充或下架。
6. FansGurus 服务类型为 `Custom Comments`（或等价的中英文名称）时，额外生成本站填写说明：目标链接必填、每行一条评论、数量与金额按有效评论行数自动计算。

清洗规则是防泄露的基础门槛，不等同于运营审核。首次公开销售前，仍应在后台抽查每种服务类型的客户详情。

## 后台操作与部署

部署后，先启动独立的资料同步 worker。该 worker 不启动库存定时任务，也不处理订单或履约任务：

```bash
cd /srv/target-site/FansProject/ops/compose
docker compose --env-file /etc/target-site/compose.env \
  -f docker-compose.production.yml \
  --profile catalog-content up -d --build api admin catalog-content-worker
```

然后在后台进入“站点连接”，确认 FansGurus 与 TGX 连接均存在且为正常状态，点击“同步商品资料”，确认提示。页面会立即显示“已加入队列”；完成后在容器日志和资料同步历史接口中确认结果：

```bash
docker compose --env-file /etc/target-site/compose.env \
  -f docker-compose.production.yml \
  logs --tail=200 catalog-content-worker

curl -sS https://api.socialgurushub.com/api/v1/admin/provider-catalog/content/sync-runs
```

第二条接口需要有效后台认证；没有认证时返回拒绝是预期行为。后台前端当前只显示入队状态，运行历史接口为 `GET /admin/provider-catalog/content/sync-runs`，便于后续扩展历史展示。

仅停止资料任务时，不需要停止 API 或前后台：

```bash
cd /srv/target-site/FansProject/ops/compose
docker compose --env-file /etc/target-site/compose.env \
  -f docker-compose.production.yml \
  --profile catalog-content stop catalog-content-worker
```

不要为了资料同步启动 `worker` 或 `inventory-worker`：前者包含订单处理能力，后者会按既有设计触发库存刷新；两者不属于本次资料更新。

TGX 的目录接口不提供可信实时库存，因此新导入的 TGX 商品会显示“库存待确认”并禁止购买，直至执行一次实际库存刷新。这是有意的保守状态，不是资料同步失败。若只需刷新单个 TGX 商品，可在“商品映射”找到该映射并点击“刷新库存”；若要刷新全部 TGX 商品，使用“同步 TGX 全部库存”，此操作需要单独启动 `inventory-worker`，且不会提交订单或改变售价。资料同步与库存同步保持独立。

## 验收标准

1. 资料同步运行记录为 `success`，且 `matched` 与现有启用且非 Telegram 的映射数量相符。
2. 抽查 FansGurus 商品 `14266`：客户页有类别、质量、速度/开始时间等说明；若服务类型是自定义评论，显示“每行一条评论”的本站说明。
3. 抽查 TGX 商品：客户页显示清洗后的 API 描述，不显示邮箱、外部品牌、上游、供应商、商家或客服联络方式；明确标为教程/登录指南的链接应显示为“查看教程”，下载与外部工具链接不得保留。
4. 对任意已上架 SKU，复核同步前后价格、库存、SKU 和上架状态不变；对 TGX 商品同时核对表单与交付展示均来自该 SKU 自身资料，而非另一个商品。
5. 用公开商品 API 和无痕页面搜索禁词：`fansgurus`、`tgx`、`upstream`、`supplier`、`provider`、上游、供应商、货源、服务商、平台商家、Telegram、`t.me`；客户可见响应中不得存在。

## 回滚边界

此功能不自动修改交易字段或发布状态。若发现清洗漏网内容，立即停止 `catalog-content-worker`，下架受影响商品或在后台临时改写其详情；修正清洗规则并测试后再重新入队。原始资料仅在后台映射记录中保留，不应复制到客服话术、公开页面、日志导出或 Git。
