<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pt_b2b_rfq_items', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('rfq_id');
            $table->unsignedInteger('product_id')->nullable()->comment('optional Bagisto products.id');
            $table->string('name');
            $table->decimal('quantity', 12, 2)->default(1);
            $table->string('unit')->default('each');
            $table->decimal('target_price', 12, 4)->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->foreign('rfq_id')->references('id')->on('pt_b2b_rfqs')->onDelete('cascade');
            $table->foreign('product_id')->references('id')->on('products')->onDelete('set null');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pt_b2b_rfq_items');
    }
};
