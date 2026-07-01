<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pt_sub_subscriptions', function (Blueprint $table) {
            $table->id();
            $table->unsignedInteger('customer_id')->comment('Bagisto customers.id');
            $table->string('provider')->default('stripe'); // which processor owns provider_*_id
            $table->string('tier');
            $table->string('interval')->nullable();
            $table->string('provider_customer_id')->nullable();
            $table->string('provider_subscription_id')->nullable()->unique();
            $table->string('status')->default('incomplete'); // active|trialing|past_due|canceled|incomplete|unpaid
            $table->timestamp('current_period_end')->nullable();
            $table->boolean('cancel_at_period_end')->default(false);
            $table->timestamps();

            $table->foreign('customer_id')->references('id')->on('customers')->onDelete('cascade');
            $table->index(['customer_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pt_sub_subscriptions');
    }
};
