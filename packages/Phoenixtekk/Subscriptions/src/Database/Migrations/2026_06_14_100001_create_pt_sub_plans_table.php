<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pt_sub_plans', function (Blueprint $table) {
            $table->id();
            $table->string('provider')->default('stripe'); // which processor owns these ids
            $table->string('tier');                 // individual | professional | enterprise
            $table->string('interval');             // month | year
            $table->string('provider_product_id')->nullable();
            $table->string('provider_price_id')->nullable();
            $table->unsignedInteger('amount')->default(0); // cents
            $table->string('currency', 10)->default('usd');
            $table->boolean('active')->default(true);
            $table->timestamps();

            // One stored plan per provider/tier/interval (lets a fallback processor coexist).
            $table->unique(['provider', 'tier', 'interval']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pt_sub_plans');
    }
};
