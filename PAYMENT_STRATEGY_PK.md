# Payment Gateway Strategy (Pakistan)

## 🏆 Recommendation: Paymob
Since Stripe and PayPal are unavailable, **Paymob** is the best enterprise-grade solution for a Flutter app in Pakistan.

### Why Paymob?
1.  **Native Flutter Support:** They offer an official `paymob_pakistan` package.
2.  **Payment Methods:**
    *   **Cards:** Visa, Mastercard (Global & Local).
    *   **Mobile Wallets:** JazzCash, EasyPaisa (Critical for MPV).
    *   **Nift ePay:** Direct bank transfer.
3.  **Recurring Billing:** Supports "Tokenization" tailored for your "Ecoins+" subscription model.

---

## 🥈 Alternative: Safepay
*   **Pros:** Better Developer Experience (Sandbox is instant). Positioned as the "Stripe of Pakistan".
*   **Cons:** Mobile SDK is sometimes a web-wrapper.
*   **Use Case:** If Paymob onboarding is too slow, start with Safepay.

---

## ⚠️ Important: The "Google Tax" (30%)
If you sell **Ecoins (Virtual Currency)** inside the Android App, Google Policies **REQUIRE** you to use Google Play Billing (taking 15-30% cut).
*   **Compliance Hack:** Market the subscription as "Club Membership" (Services) OR direct users to "Subscribe at ecoins.pk" (Web Portal) where you can use Paymob freely.

---

## 🚀 Integration Roadmap
1.  **Entity:** Register Sole Proprietor (FBR) or Pvt Ltd (SECP).
2.  **Onboarding:** Apply for Paymob Live credentials.
3.  **Dev:** `flutter pub add paymob_pakistan`.
