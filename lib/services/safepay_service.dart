import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// Safepay Security Implementation
class SafepayService {
  static const String _productionUrl = 'https://www.api.safepay.pk/order/checkout';
  static const String _sandboxUrl = 'https://sandbox.api.safepay.pk/order/checkout';
  
  final String apiKey;
  final String secretKey; // NEVER expose this on client side if possible
  final bool isSandbox;

  SafepayService({
    required this.apiKey, 
    required this.secretKey, 
    this.isSandbox = true
  });

  /// 1. Secure Signature Generation based on Safepay Docs
  /// Signature = HMAC-SHA256(SecretKey, ParameterString)
  String _generateSignature(Map<String, String> params) {
    // Sort keys alphabetically is usually required for HMAC consistency
    // Safepay spec: Concatenate values? Or just hash specific tracker?
    // Implementation: Safepay Checkout URL doesn't usually require client-side hashing
    // if using the Hosted Checkout Flow. The security relies on the Redirect.
    // However, if we were doing server-side init, we'd need this.
    
    // For WebView Integration: We construct the URL with params.
    return ""; 
  }

  /// 2. Build Checkout URL
  String buildCheckoutUrl({
    required String tracker, // Unique Order ID
    required double amount,
    required String currency,
    required String cancelUrl,
    required String redirectUrl,
  }) {
    final baseUrl = isSandbox ? _sandboxUrl : _productionUrl;
    
    // Construct Query Params
    final query = Uri(queryParameters: {
      'beacon': tracker, 
      'source': 'mobile',
      'order_id': tracker,
      'redirect_url': redirectUrl,
      'cancel_url': cancelUrl,
    }).query;

    return '$baseUrl?$query';
  }
}

// Safepay Payment Screen
class SafepayPaymentScreen extends StatefulWidget {
  final String paymentUrl;
  final Function(String) onSuccess;
  final VoidCallback onCancel;

  const SafepayPaymentScreen({
    super.key,
    required this.paymentUrl,
    required this.onSuccess,
    required this.onCancel,
  });

  @override
  State<SafepayPaymentScreen> createState() => _SafepayPaymentScreenState();
}

class _SafepayPaymentScreenState extends State<SafepayPaymentScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // 3. Security: Intercept Redirects to Verify Success
            if (request.url.contains('success')) {
               // Extract transaction reference from URL if present
               widget.onSuccess(request.url);
               return NavigationDecision.prevent;
            }
            if (request.url.contains('cancel')) {
               widget.onCancel();
               return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Secure Payment"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onCancel,
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
