# Google Play IAP — Decision Replay

Package: `com.decisionreplaymng.decisionreplay`

## Coin packs (consumable)
| Product ID | Coins |
|------------|-------|
| dr_pack_1 | 50 |
| dr_pack_2 | 100 |
| dr_pack_3 | 200 |
| dr_pack_4 | 350 |
| dr_pack_5 | 500 |
| dr_pack_6 | 750 |
| dr_pack_7 | 1000 |
| dr_pack_8 | 1500 |
| dr_pack_9 | 2200 |
| dr_pack_10 | 3000 |

## Premium (non-consumable)
- `dr_remove_ads` — Remove ads

## Remote kill-switch
GET `https://api2.blwsmartware.net/N226.json`

If `disable=1`: hide Google Billing UI, shop with coins still works.

Expected JSON fields: `name`, `id`, `version`, `disable`, `code`, `status`, `msg`
