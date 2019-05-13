package com.breadwallet.crypto.blockchaindb.models;

import com.google.common.base.Optional;
import com.google.common.collect.ImmutableMap;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.List;

public class Subscription {

    public static Optional<Subscription> asSubscription(JSONObject json) {
        try {
            String id = json.getString("subscription_id");
            String wallet = json.getString("wallet_id");
            String device = json.getString("device_id");

            JSONObject jsonEndpoint = json.getJSONObject("endpoint");
            Optional<SubscriptionEndpoint> optionalEndpoint = SubscriptionEndpoint.asSubscriptionEndpoint(jsonEndpoint);
            if (!optionalEndpoint.isPresent()) return Optional.absent();
            SubscriptionEndpoint endpoint= optionalEndpoint.get();

            return Optional.of(new Subscription(id, wallet, device, endpoint));

        } catch (JSONException e) {
            return Optional.absent();
        }
    }

    public static JSONObject asJson(Subscription subscription) {
        return new JSONObject(ImmutableMap.of(
                "id", subscription.id,
                "wallet_id", subscription.wallet,
                "device_id", subscription.device,
                "endpoint", SubscriptionEndpoint.asJson(subscription.endpoint)
        ));
    }

    private final String id;
    private final String wallet;
    private final String device;
    private final SubscriptionEndpoint endpoint;

    public Subscription(String id, String wallet, String device, SubscriptionEndpoint endpoint) {
        this.id = id;
        this.wallet = wallet;
        this.device = device;
        this.endpoint = endpoint;
    }

    public String getId() {
        return id;
    }

    public String getWallet() {
        return wallet;
    }

    public String getDevice() {
        return device;
    }

    public SubscriptionEndpoint getEndpoint() {
        return endpoint;
    }
}
