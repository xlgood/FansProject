# SKU Sync Plan

## Sync Objective

Keep Website3 catalog aligned with Fansgurus service availability, category placement, service metadata, limits, and price changes.

## Sync Strategy

- Poll Fansgurus `action=services` every 1 to 5 minutes.
- Compute a content hash per upstream service from fields that affect display or ordering.
- Upsert changed services into the local catalog.
- Mark missing services as inactive instead of deleting immediately.
- Store both upstream rate and Website3 sell rate.

## Suggested Catalog Fields

- `upstream_provider`
- `upstream_service_id`
- `category_name`
- `service_name`
- `service_type`
- `upstream_rate`
- `sell_rate`
- `min_quantity`
- `max_quantity`
- `supports_dripfeed`
- `supports_refill`
- `supports_cancel`
- `is_active`
- `last_seen_at`
- `content_hash`

## Change Handling

- New upstream service: create active SKU.
- Existing service changed: update SKU and create sync event.
- Missing service: mark inactive after a grace period.
- Price changed: recalculate sell price immediately.

## Real-Time Definition

Fansgurus services appear to be pull-based. Unless a webhook is confirmed later, Website3 should define real-time as "near-real-time polling", with a target sync lag of 1 to 5 minutes.
