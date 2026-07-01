<?php

namespace Phoenixtekk\Subscriptions\Models;

use Illuminate\Database\Eloquent\Model;

class WebhookEvent extends Model
{
    protected $table = 'pt_sub_webhook_events';

    protected $fillable = ['provider', 'provider_event_id', 'type', 'processed_at'];

    protected $casts = ['processed_at' => 'datetime'];
}
