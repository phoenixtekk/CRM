<?php

/**
 * Admin ACL entries for the Phoenixtekk B2B Marketplace.
 * Merged (appended) into Bagisto's config('acl').
 */
return [
    [
        'key'   => 'b2b',
        'name'  => 'B2B Marketplace',
        'route' => 'admin.b2b.suppliers.index',
        'sort'  => 6,
    ],
    [
        'key'   => 'b2b.suppliers',
        'name'  => 'Suppliers',
        'route' => 'admin.b2b.suppliers.index',
        'sort'  => 1,
    ],
    [
        'key'   => 'b2b.suppliers.view',
        'name'  => 'View',
        'route' => 'admin.b2b.suppliers.view',
        'sort'  => 1,
    ],
    [
        'key'   => 'b2b.suppliers.manage',
        'name'  => 'Approve / Reject / Suspend',
        'route' => 'admin.b2b.suppliers.update_status',
        'sort'  => 2,
    ],
];
