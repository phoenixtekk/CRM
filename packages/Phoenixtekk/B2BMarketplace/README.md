# Phoenixtekk B2B Marketplace (Bagisto package)

Version **1.0.0** · native Bagisto 2.3 / Laravel 12 package · namespace `Phoenixtekk\B2BMarketplace`.

An **original**, owned B2B marketplace foundation for Bagisto — **not** a clone of any commercial
extension. It adds Supplier Companies, Supplier Registration + Admin Approval, an RFQ system, a
Supplier Dashboard, and Company Accounts, without modifying Bagisto core. All tables use the
`pt_b2b_` prefix.

## Scope (v1.0)
1. Supplier companies · 2. Supplier registration · 3. Admin approval · 4. RFQ system ·
5. Supplier dashboard · 6. Company accounts.

## Tables (all `pt_b2b_`)
`companies`, `company_users`, `suppliers`, `supplier_users`, `rfqs`, `rfq_items`, `rfq_messages`, `rfq_quotes`.

## Install
The package lives at `packages/Phoenixtekk/B2BMarketplace`. Register it once:

1. **Autoload** — add to the root `composer.json` `autoload.psr-4`:
   ```json
   "Phoenixtekk\\B2BMarketplace\\": "packages/Phoenixtekk/B2BMarketplace/src"
   ```
2. **Provider** — add to `bootstrap/providers.php`:
   ```php
   \Phoenixtekk\B2BMarketplace\Providers\B2BMarketplaceServiceProvider::class,
   ```
3. Run (use the store's PHP 8.4 + the site owner):
   ```bash
   php8.4 /usr/local/bin/composer dump-autoload
   php8.4 artisan optimize:clear
   php8.4 artisan migrate
   ```

## Routes
- **Admin** (prefix `…/admin/b2b`, `admin` middleware): `admin.b2b.suppliers.{index,view,update_status}`.
- **Storefront** (prefix `/b2b`, `customer` middleware): `shop.b2b.supplier.{register,store,dashboard,rfq,quote}`,
  `shop.b2b.company.{index,store,update,users.store,users.destroy}`, `shop.b2b.rfqs.{index,create,store,show,submit,message}`.

List them: `php8.4 artisan route:list --path=b2b`.

## Security
- Admin routes use Bagisto's `admin` middleware; storefront routes use `customer` middleware.
- Authorization policies (`SupplierPolicy`, `CompanyPolicy`, `RfqPolicy`) restrict records to their
  owners/members; controllers enforce them via `Gate::forUser(<customer>)` and explicit ownership checks.
- All input is validated through dedicated FormRequest classes.

## Uninstall / rollback
Remove the provider line + the psr-4 entry, `php8.4 artisan optimize:clear`, then (optional)
`php8.4 artisan migrate:rollback` to drop the 8 `pt_b2b_` tables. No core files are touched.

## Future integration
Designed to extend toward Workplace, EpicFreelancer, and Analytikul (company accounts + RFQ are the
shared primitives). Keep additions in this package; avoid editing Bagisto core.
