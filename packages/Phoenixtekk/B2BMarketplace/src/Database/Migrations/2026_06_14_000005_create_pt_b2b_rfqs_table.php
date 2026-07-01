<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pt_b2b_rfqs', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->text('description')->nullable();
            $table->unsignedBigInteger('company_id')->nullable();
            $table->unsignedInteger('requester_id')->comment('Bagisto customers.id who created the RFQ');
            $table->enum('status', [
                'draft', 'submitted', 'supplier_review', 'quoted',
                'accepted', 'rejected', 'cancelled', 'expired',
            ])->default('draft');
            $table->date('due_date')->nullable();
            $table->timestamps();

            $table->foreign('company_id')->references('id')->on('pt_b2b_companies')->onDelete('set null');
            $table->foreign('requester_id')->references('id')->on('customers')->onDelete('cascade');
            $table->index('status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pt_b2b_rfqs');
    }
};
