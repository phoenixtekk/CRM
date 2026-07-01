<?php

namespace Phoenixtekk\B2BMarketplace\Http\Controllers\Shop;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Gate;
use Phoenixtekk\B2BMarketplace\Http\Requests\RfqRequest;
use Phoenixtekk\B2BMarketplace\Models\CompanyUser;
use Phoenixtekk\B2BMarketplace\Models\Rfq;
use Phoenixtekk\B2BMarketplace\Models\RfqItem;
use Phoenixtekk\B2BMarketplace\Models\RfqMessage;
use Webkul\Shop\Http\Controllers\Controller;

/**
 * Storefront: buyers/company users create and manage RFQs.
 */
class RfqController extends Controller
{
    public function index()
    {
        $customer   = auth()->guard('customer')->user();
        $companyIds = CompanyUser::where('customer_id', $customer->id)->pluck('company_id');

        $rfqs = Rfq::where('requester_id', $customer->id)
            ->orWhereIn('company_id', $companyIds)
            ->with('quotes')
            ->orderByDesc('id')
            ->get();

        return view('b2b::shop.rfq.index', compact('rfqs'));
    }

    public function create()
    {
        $customer  = auth()->guard('customer')->user();
        $companies = CompanyUser::with('company')->where('customer_id', $customer->id)->get()
            ->pluck('company')->filter();

        return view('b2b::shop.rfq.create', compact('companies'));
    }

    public function store(RfqRequest $request)
    {
        $customer   = auth()->guard('customer')->user();
        $companyIds = CompanyUser::where('customer_id', $customer->id)->pluck('company_id')->all();

        // company is optional, but if supplied it must be one the customer belongs to
        $companyId = $request->input('company_id');
        if ($companyId && ! in_array((int) $companyId, array_map('intval', $companyIds), true)) {
            abort(403, 'You do not belong to that company.');
        }

        $status = $request->input('action') === 'submit' ? 'submitted' : 'draft';

        $rfq = DB::transaction(function () use ($request, $customer, $companyId, $status) {
            $rfq = Rfq::create([
                'title'        => $request->title,
                'description'  => $request->description,
                'company_id'   => $companyId ?: null,
                'requester_id' => $customer->id,
                'status'       => $status,
                'due_date'     => $request->due_date,
            ]);

            foreach ($request->items as $item) {
                RfqItem::create([
                    'rfq_id'       => $rfq->id,
                    'product_id'   => $item['product_id'] ?? null,
                    'name'         => $item['name'],
                    'quantity'     => $item['quantity'],
                    'unit'         => $item['unit'] ?? 'each',
                    'target_price' => $item['target_price'] ?? null,
                    'notes'        => $item['notes'] ?? null,
                ]);
            }

            return $rfq;
        });

        return redirect()->route('shop.b2b.rfqs.show', $rfq->id)
            ->with('success', 'RFQ created.' . ($status === 'submitted' ? ' It is now open to suppliers.' : ' Saved as draft.'));
    }

    public function show(int $id)
    {
        $customer = auth()->guard('customer')->user();
        $rfq = Rfq::with(['items', 'messages', 'quotes.supplier', 'company'])->findOrFail($id);

        abort_unless(Gate::forUser($customer)->allows('view', $rfq), 403);

        return view('b2b::shop.rfq.show', compact('rfq'));
    }

    public function submit(int $id)
    {
        $customer = auth()->guard('customer')->user();
        $rfq = Rfq::findOrFail($id);

        abort_unless(Gate::forUser($customer)->allows('update', $rfq), 403);

        if ($rfq->status === 'draft') {
            $rfq->update(['status' => 'submitted']);
        }

        return back()->with('success', 'RFQ submitted to suppliers.');
    }

    public function message(int $id, Request $request)
    {
        $customer = auth()->guard('customer')->user();
        $rfq = Rfq::findOrFail($id);

        abort_unless(Gate::forUser($customer)->allows('view', $rfq), 403);

        $request->validate(['message' => 'required|string|max:2000']);

        RfqMessage::create([
            'rfq_id'      => $rfq->id,
            'author_type' => 'buyer',
            'author_id'   => $customer->id,
            'message'     => $request->message,
        ]);

        return back()->with('success', 'Message posted.');
    }
}
