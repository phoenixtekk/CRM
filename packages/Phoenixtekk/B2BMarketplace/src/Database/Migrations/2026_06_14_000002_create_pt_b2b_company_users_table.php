<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pt_b2b_company_users', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('company_id');
            $table->unsignedInteger('customer_id')->comment('Bagisto customers.id');
            $table->enum('role', ['owner', 'admin', 'buyer', 'viewer'])->default('buyer');
            $table->enum('status', ['active', 'inactive'])->default('active');
            $table->timestamps();

            $table->foreign('company_id')->references('id')->on('pt_b2b_companies')->onDelete('cascade');
            $table->foreign('customer_id')->references('id')->on('customers')->onDelete('cascade');
            $table->unique(['company_id', 'customer_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pt_b2b_company_users');
    }
};
