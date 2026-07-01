<?php

/**
 * Admin menu entries for the Phoenixtekk B2B Marketplace.
 * Merged (appended) into Bagisto's config('menu.admin'); items render sorted by `sort`.
 */
return [
    [
        'key'        => 'b2b',
        'name'       => 'B2B Marketplace',
        'route'      => 'admin.b2b.suppliers.index',
        'sort'       => 6,
        'icon'       => 'icon-store',
    ],
    [
        'key'        => 'b2b.suppliers',
        'name'       => 'Suppliers',
        'route'      => 'admin.b2b.suppliers.index',
        'sort'       => 1,
        'icon'       => '',
    ],
];
