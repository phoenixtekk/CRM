<?php

/** Admin menu entry — appended to Bagisto's config('menu.admin'). */
return [
    [
        'key'   => 'subscriptions',
        'name'  => 'Subscriptions',
        'route' => 'admin.subscriptions.index',
        'sort'  => 7,
        'icon'  => 'icon-recurring',
    ],
];
