<?php

namespace Phoenixtekk\Subscriptions\Http\Controllers\Shop;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Phoenixtekk\Subscriptions\Models\Subscription;
use Webkul\Shop\Http\Controllers\Controller;

/**
 * Members-only library: active members can download every solution's deliverables (the entitlement
 * granted by a membership). Routes are protected by the `membership.active` middleware.
 */
class MemberLibraryController extends Controller
{
    public function index()
    {
        // All downloadable solution products + their download links (excludes the membership SKUs).
        $rows = DB::table('product_downloadable_links as l')
            ->join('products as p', 'p.id', '=', 'l.product_id')
            ->leftJoin('product_flat as f', function ($j) {
                $j->on('f.product_id', '=', 'p.id')->where('f.locale', 'en')->where('f.channel', 'default');
            })
            ->leftJoin('product_downloadable_link_translations as t', function ($j) {
                $j->on('t.product_downloadable_link_id', '=', 'l.id')->where('t.locale', 'en');
            })
            ->where('p.type', 'downloadable')
            ->where('p.sku', 'not like', 'PTK-SUB-%')
            ->select('l.id as link_id', 't.title as link_title', 'l.file_name', 'p.id as product_id', 'p.sku', 'f.name as product_name')
            ->orderBy('f.name')
            ->get();

        $solutions = $rows->groupBy('product_id');

        return view('subscriptions::shop.library', compact('solutions'));
    }

    /** Stream a single downloadable file to an active member. */
    public function download(int $link)
    {
        $row = DB::table('product_downloadable_links')->where('id', $link)->first();

        abort_unless($row && $row->file, 404);
        abort_unless(Storage::disk('public')->exists($row->file), 404);

        return Storage::disk('public')->download($row->file, $row->file_name ?: basename($row->file));
    }
}
