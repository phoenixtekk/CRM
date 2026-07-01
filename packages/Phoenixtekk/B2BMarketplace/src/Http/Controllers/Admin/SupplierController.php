<?php

namespace Phoenixtekk\B2BMarketplace\Http\Controllers\Admin;

use Illuminate\Http\Request;
use Phoenixtekk\B2BMarketplace\Models\Supplier;
use Webkul\Admin\Http\Controllers\Controller;

/**
 * Admin: review and act on supplier applications (approve / reject / suspend / reactivate).
 */
class SupplierController extends Controller
{
    public function index(Request $request)
    {
        $suppliers = Supplier::query()
            ->when($request->get('status'), fn ($q, $s) => $q->where('status', $s))
            ->orderByDesc('id')
            ->paginate(20)
            ->withQueryString();

        return view('b2b::admin.suppliers.index', compact('suppliers'));
    }

    public function view(int $id)
    {
        $supplier = Supplier::with(['applicant', 'users.customer', 'quotes'])->findOrFail($id);

        return view('b2b::admin.suppliers.show', compact('supplier'));
    }

    public function updateStatus(int $id, Request $request)
    {
        $request->validate([
            'action'          => 'required|in:approve,reject,suspend,reactivate',
            'rejected_reason' => 'nullable|string|max:1000',
        ]);

        $supplier = Supplier::findOrFail($id);

        $statusMap = [
            'approve'    => 'approved',
            'reject'     => 'rejected',
            'suspend'    => 'suspended',
            'reactivate' => 'approved',
        ];

        $supplier->status            = $statusMap[$request->action];
        $supplier->status_changed_at = now();

        if (in_array($request->action, ['approve', 'reactivate'], true)) {
            $supplier->approved_by = auth()->guard('admin')->id();
            $supplier->approved_at = now();
        }

        if ($request->action === 'reject') {
            $supplier->rejected_reason = $request->rejected_reason;
        }

        $supplier->save();

        session()->flash('success', "Supplier '{$supplier->company_name}' set to {$supplier->status}.");

        return redirect()->route('admin.b2b.suppliers.view', $id);
    }
}
