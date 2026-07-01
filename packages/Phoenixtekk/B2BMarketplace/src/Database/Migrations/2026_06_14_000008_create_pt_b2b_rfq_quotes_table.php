<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pt_b2b_rfq_quotes', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('rfq_id');
            $table->unsignedBigInteger('supplier_id');
            $table->decimal('quote_total', 14, 4)->default(0);
            $table->date('expires_at')->nullable();
            $table->text('notes')->nullable();
            $table->json('line_items')->nullable()->comment('per-line pricing: [{rfq_item_id, unit_price, qty, line_total}]');
            $table->enum('status', ['submitted', 'accepted', 'rejected'])->default('submitted');
            $table->timestamps();

            $table->foreign('rfq_id')->references('id')->on('pt_b2b_rfqs')->onDelete('cascade');
            $table->foreign('supplier_id')->references('id')->on('pt_b2b_suppliers')->onDelete('cascade');
            $table->index(['rfq_id', 'supplier_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pt_b2b_rfq_quotes');
    }
};
