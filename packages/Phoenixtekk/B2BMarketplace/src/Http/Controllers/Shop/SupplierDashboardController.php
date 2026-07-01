<?php

namespace Phoenixtekk\B2BMarketplace\Http\Controllers\Shop;

use Illuminate\Support\Facades\DB;
use Phoenixtekk\B2BMarketplace\Http\Requests\QuoteRequest;
use Phoenixtekk\B2BMarketplace\Models\Rfq;
use Phoenixtekk\B2BMarketplace\Models\RfqQuote;
use Phoenixtekk\B2BMarketplace\Models\Supplier;
use Webkul\Shop\Http\Controllers\Controller;

/**
 * Storefront: approved-supplier dashboard — view profile, browse open RFQs, submit quotes.
 */
class SupplierDashboardController extends Controller
{
    public function index()
    {
        $supplier = $this->supplierFor();

        if (! $supplier || ! $supplier->isApproved()) {
            // Shows a pending / not-a-supplier state in the view.
            return view('b2b::shop.dashboard.index', [
                'supplier' => $supplier,
                'openRfqs' => collect(),
                'myQuotes' => collect(),
            ]);
        }

        $openRfqs = Rfq::whereIn('status', ['submitted', 'supplier_review', 'quoted'])
            ->with('items')
            ->orderByDesc('id')
            ->get();

        $myQuotes = $supplier->quotes()->with('rfq')->orderByDesc('id')->get();

        return view('b2b::shop.dashboard.index', compact('supplier', 'openRfqs', 'myQuotes'));
    }

    public function rfq(int $id)
    {
        $supplier = $this->approvedSupplierOrAbort();

        $rfq = Rfq::with(['items', 'quotes' => fn ($q) => $q->where('supplier_id', $supplier->id)])
            ->findOrFail($id);

        abort_unless(in_array($rfq->status, ['submitted', 'supplier_review', 'quoted'], true), 404);

        return view('b2b::shop.dashboard.rfq', compact('supplier', 'rfq'));
    }

    public function quote(int $id, QuoteRequest $request)
    {
        $supplier = $this->approvedSupplierOrAbort();
        $rfq = Rfq::findOrFail($id);

        DB::transaction(function () use ($rfq, $supplier, $request) {
            RfqQuote::create([
                'rfq_id'      => $rfq->id,
                'supplier_id' => $supplier->id,
                'quote_total' => $request->quote_total,
                'expires_at'  => $request->expires_at,
                'notes'       => $request->notes,
                'line_items'  => $request->line_items,
                'status'      => 'submitted',
            ]);

            if (in_array($rfq->status, ['submitted', 'supplier_review'], true)) {
                $rfq->update(['status' => 'quoted']);
            }
        });

        return redirect()->route('shop.b2b.supplier.dashboard')
            ->with('success', 'Your quote has been submitted.');
    }

    /** The supplier this customer belongs to (any status), or null. */
    protected function supplierFor(): ?Supplier
    {
        $customer = auth()->guard('customer')->user();

        return Supplier::whereHas('users', fn ($q) => $q->where('customer_id', $customer->id))->first();
    }

    /** Require an approved supplier or 403 (pending suppliers cannot use dashboard actions). */
    protected function approvedSupplierOrAbort(): Supplier
    {
        $supplier = $this->supplierFor();

        abort_unless($supplier && $supplier->isApproved(), 403, 'Approved supplier access required.');

        return $supplier;
    }
}
