<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pt_b2b_rfq_messages', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('rfq_id');
            $table->enum('author_type', ['buyer', 'supplier', 'admin'])->default('buyer');
            $table->unsignedInteger('author_id')->comment('customer or admin id, per author_type');
            $table->text('message');
            $table->timestamps();

            $table->foreign('rfq_id')->references('id')->on('pt_b2b_rfqs')->onDelete('cascade');
            $table->index(['rfq_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pt_b2b_rfq_messages');
    }
};
