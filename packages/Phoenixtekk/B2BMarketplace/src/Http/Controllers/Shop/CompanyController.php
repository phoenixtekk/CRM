<?php

namespace Phoenixtekk\B2BMarketplace\Http\Controllers\Shop;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Phoenixtekk\B2BMarketplace\Http\Requests\CompanyRequest;
use Phoenixtekk\B2BMarketplace\Models\Company;
use Phoenixtekk\B2BMarketplace\Models\CompanyUser;
use Webkul\Customer\Models\Customer;
use Webkul\Shop\Http\Controllers\Controller;

/**
 * Storefront: company accounts — create/manage a B2B buyer company and its users.
 */
class CompanyController extends Controller
{
    public function index()
    {
        $customer   = auth()->guard('customer')->user();
        $membership = CompanyUser::with('company')->where('customer_id', $customer->id)->first();

        $company  = $membership?->company;
        $users    = $company ? $company->users()->with('customer')->get() : collect();
        $canManage = $membership?->isManager() ?? false;

        return view('b2b::shop.company.index', compact('company', 'users', 'membership', 'canManage'));
    }

    public function store(CompanyRequest $request)
    {
        $customer = auth()->guard('customer')->user();

        if (CompanyUser::where('customer_id', $customer->id)->exists()) {
            return redirect()->route('shop.b2b.company.index')
                ->with('warning', 'You already belong to a company.');
        }

        $company = Company::create(array_merge($request->validated(), [
            'status'     => 'active',
            'created_by' => $customer->id,
        ]));

        CompanyUser::create([
            'company_id'  => $company->id,
            'customer_id' => $customer->id,
            'role'        => 'owner',
            'status'      => 'active',
        ]);

        return redirect()->route('shop.b2b.company.index')->with('success', 'Company created.');
    }

    public function update(int $id, CompanyRequest $request)
    {
        $customer = auth()->guard('customer')->user();
        $company  = Company::findOrFail($id);

        abort_unless(Gate::forUser($customer)->allows('manage', $company), 403);

        $company->update($request->validated());

        return redirect()->route('shop.b2b.company.index')->with('success', 'Company updated.');
    }

    public function addUser(int $id, Request $request)
    {
        $customer = auth()->guard('customer')->user();
        $company  = Company::findOrFail($id);

        abort_unless(Gate::forUser($customer)->allows('manage', $company), 403);

        $data = $request->validate([
            'email' => 'required|email',
            'role'  => 'required|in:owner,admin,buyer,viewer',
        ]);

        $invitee = Customer::where('email', $data['email'])->first();

        if (! $invitee) {
            return back()->with('error', 'No customer account found for that email.');
        }

        if (CompanyUser::where('customer_id', $invitee->id)->exists()) {
            return back()->with('error', 'That customer already belongs to a company.');
        }

        CompanyUser::create([
            'company_id'  => $company->id,
            'customer_id' => $invitee->id,
            'role'        => $data['role'],
            'status'      => 'active',
        ]);

        return back()->with('success', 'Company user added.');
    }

    public function removeUser(int $id, int $userId)
    {
        $customer = auth()->guard('customer')->user();
        $company  = Company::findOrFail($id);

        abort_unless(Gate::forUser($customer)->allows('manage', $company), 403);

        $member = CompanyUser::where('company_id', $company->id)->findOrFail($userId);

        if ($member->role === 'owner') {
            return back()->with('error', 'The company owner cannot be removed.');
        }

        $member->delete();

        return back()->with('success', 'Company user removed.');
    }
}
