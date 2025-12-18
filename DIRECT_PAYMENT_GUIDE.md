# Direct Integration Guide: JazzCash & EasyPaisa

**WARNING:** Direct integration is complex and requires significant "Business Verification". It is often easier to use an aggregator (Paymob), but if you want to avoid their fees (~2.5%), here is the direct path.

---

## Option A: JazzCash (Direct)

### 1. Registration (The Hard Part)
*   **Entity:** You MUST have a registered business (NTN).
*   **Portal:** Sign up at the [JazzCash Merchant Portal](https://www.jazzcash.com.pk/corporate/payment-gateway/).
*   **Approval:** Wait 2-4 weeks for approval. They will ask for your website/app URL.

### 2. Integration Types
*   **HTTP POST (Hosted Checkout):** Easier. You send data to their URL, user pays there, they redirect back.
*   **Native API (Do this for specific UI):**
    *   **Endpoint:** `https://payments.jazzcash.com.pk/ApplicationAPI/API/2.0/Purchase/DoTransaction`
    *   **Secure Hash:** You must generate a "HMAC-SHA256" hash of your fields + "Integrity Salt" (provided by JazzCash).

### 3. Flutter Logic (Conceptual)
```dart
// 1. Prepare Data
String pp_Amount = "50000"; // 500.00
String pp_TxnRef = "T${DateTime.now().millisecondsSinceEpoch}";
String secureHash = generateHash(secretKey, [pp_Amount, pp_TxnRef, ...]);

// 2. Send Request
final response = await http.post(
  Uri.parse('https://sandbox.jazzcash.com.pk/ApplicationAPI/API/2.0/Purchase/DoTransaction'),
  body: {
    "pp_Version": "2.0",
    "pp_TxnType": "MWALLET", // Mobile Wallet
    "pp_Language": "EN",
    "pp_MerchantID": "YOUR_ID",
    "pp_Password": "YOUR_PASSWORD",
    "pp_TxnRefNo": pp_TxnRef,
    "pp_Amount": pp_Amount,
    "pp_MobileNumber": "03001234567", // User's Wallet Number
    "pp_CNIC": "34501...", // Last 6 digits sometimes required
    "pp_SecureHash": secureHash,
  }
);

// 3. Handle Response
if (response.body['pp_ResponseCode'] == '000') {
   // Success! User receives MPIN popup on their phone.
}
```

---

## Option B: EasyPaisa (Direct)

### 1. Registration
*   **Portal:** [EasyPaisa Developer Portal](https://developer.easypaisa.com.pk/).
*   **Sandbox:** They provide instant sandbox access (unlike JazzCash).

### 2. The "MAAPI" (Mobile App API)
*   **Flow:**
    1.  **Initiate:** App calls `initiate-transaction`.
    2.  **Redirect/Popup:** User enters Pin.
    3.  **Inquiry:** App calls `inquire-transaction` to check status.

### 3. Flutter Logic
*   EasyPaisa often uses a **WebView** approach for standard integration or a "Headless" API for enterprise.
*   The "Headless" API is cleaner but requires PCI-DSS compliance (hard).
*   **Recommendation:** Use the "Checkout URL" in a WebView.

---

## 💡 The "Paymob" Shortcut (Why I recommended it)
If you do "Direct Integration":
1.  You write 2 separate codebases (One for Jazz, one for EasyPaisa).
2.  You handle 2 separate "Settlements" (Money comes to Jazz account vs Telenor account).
3.  You debug 2 separate systems.

**Paymob** does all of this with **1 API** and gives you **1 Bank Transfer** at the end of the week. The 2-3% fee is usually worth the 100+ hours of dev time saved.
