# Supabase schema (mirrors Flutter UI)

## Migrations

> ⚠️ **تحذير**: `migrations/20260521120000_rebuild_schema.sql` تدميرية — تمسح كل مستخدمي auth وكل البيانات.
> هي أرشيف تاريخي فقط؛ **لا تُشغّلها أبدا على مشروع الإنتاج** `xojuclsmzenpfumzzpuo`.

الحالة الحية للقاعدة أشمل من هذه الملفات: RLS مفعلة على كل الجداول بسياسات كاملة،
وآخر تقوية أمنية (حذف الحساب delete_account + سياسات Storage + تشديد messages) في
`migrations/20260705120000_account_deletion_and_security_hardening.sql` — مطبقة على الإنتاج بتاريخ 2026-07-05.

## Storage buckets

| Bucket           | Public | Usage                       |
|------------------|--------|------------------------------|
| `avatars`        | yes    | Profile photos               |
| `products`       | yes    | Product + chat images        |
| `voice_messages` | yes    | Chat voice notes             |

الكتابة/الحذف مقيدة بسياسات owner على `storage.objects` (منذ 2026-07-05).

## Data model

### `profiles` (registration + profile screens)

| Column        | UI source                          |
|---------------|------------------------------------|
| `id`          | `auth.uid()`                       |
| `username`    | Name / shop name step              |
| `language`    | ar / en / fr                       |
| `wilaya`      | Governorate grid                   |
| `account_type`| `user` \| `shop`                   |
| `phone`       | Optional phone                     |
| `avatar_url`  | Profile photo (upload after signup)|
| `shop_type`   | Shop only: clothing, superfripe, rental, accessories |
| `shop_lat/lng`| Shop only: optional map picker     |

Trigger `handle_new_user` seeds profile from signup metadata; app also **upserts** the same fields + avatar after signup.

### `products` (add product screen)

| Column           | UI source                                      |
|------------------|------------------------------------------------|
| `user_id`        | Seller (`auth.uid()`)                          |
| `product_type`   | `sale` \| `rental` toggle                      |
| `category_main`  | Level 1 id from `app_categories.dart`          |
| `category_sub`   | Level 2 id                                     |
| `category_item`  | Level 3 id (when sub has children)             |
| `condition`      | new \| good_used \| used                       |
| `wilaya`         | Copied from seller profile at publish          |
| `taille`         | Size field                                     |
| `main_image_url` | Primary photo                                  |
| `images`         | JSON array of all image URLs                   |

Category ids are **stable strings** defined in `lib/data/categories.dart` — used for create, filter sheet, and home feed.

### Wilaya flow

1. User picks wilaya at signup → stored on `profiles.wilaya`
2. New products get `products.wilaya` from profile at publish
3. Home filter uses `products.wilaya IN (...)` (not a join)
4. Editing profile wilaya updates active products via `syncWilayaForUser`

## Flutter layer

- استعلامات Supabase تتم مباشرة داخل الصفحات (`lib/pages/*.dart`) — لا طبقة repositories
- `lib/data/categories.dart` — المصدر الوحيد لهرمية التصنيفات (ids ثابتة تُخزن في products)
