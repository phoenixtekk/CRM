<?php

/** Admin ACL entry — appended to Bagisto's config('acl'). */
return [
    [
        'key'   => 'subscriptions',
        'name'  => 'Subscriptions',
        'route' => 'admin.subscriptions.index',
        'sort'  => 7,
    ],
];
