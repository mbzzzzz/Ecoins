# Google Play Billing Integration

Yes! You can (and for the user subscription, *must*) use Google Play as the payment gateway.

## Why?
*   **Trust:** Users trust Google more than entering a card in a WebView.
*   **Compliance:** Android Apps verify purchases of "Digital Goods" (like Ecoins+) must use Play Billing.
*   **Ease:** One-tap subscribe.

## Integration Steps

### 1. Requirements
*   **Merchant Account:** Set up a payment profile in Google Play Console.
*   **Product:** Create a Subscription ID: `ecoins_plus_monthly` ($4.99).

### 2. Code (Flutter)

1.  **Add dependency:**
    ```yaml
    in_app_purchase: ^3.2.0
    ```

2.  **Implementation Logic:**
    ```dart
    final InAppPurchase _iap = InAppPurchase.instance;

    void buySubscription() async {
      final ProductDetailsResponse response = 
          await _iap.queryProductDetails({'ecoins_plus_monthly'});
      
      final PurchaseParam purchaseParam = 
          PurchaseParam(productDetails: response.productDetails.first);
          
      _iap.buyNonConsumable(purchaseParam: purchaseParam);
    }
    ```

3.  **Backend Verification:**
    *   Verify the `purchaseToken` on your Supabase Edge Function using the Google Play Developer API to ensure it's valid before granting the status.

## Recommendation
*   **For Users:** Use **Google Play Billing** (Safe, Easy, Compliant).
*   **For Brands:** Use **Safepay/Paymob** (Lower fees, B2B compliant).
