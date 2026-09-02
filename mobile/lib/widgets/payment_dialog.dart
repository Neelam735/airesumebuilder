import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/billing.dart';
import '../services/razorpay_service.dart';
import '../state/resume_provider.dart';
import '../theme.dart';

/// Shown when the user taps Download on an AI-enhanced resume that hasn't
/// been paid for yet. Drives the purchase through either Google Play or
/// Razorpay, persists the resulting payment token, and resolves with `true`
/// on success so the caller can proceed to share/download the PDF.
class PaymentDialog extends StatefulWidget {
  final BillingService billing;
  final RazorpayService razorpay;

  const PaymentDialog({
    super.key,
    required this.billing,
    required this.razorpay,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  bool _busy = false;
  String _status = '';
  String? _error;

  Future<void> _purchase() async {
    await _run(
      'Opening Google Play…',
      () => widget.billing.purchaseAndVerify(
        onStatus: (s) => setState(() => _status = s),
      ),
    );
  }

  Future<void> _purchaseRazorpay() async {
    await _run(
      'Opening Razorpay…',
      () => widget.razorpay.payAndVerify(
        onStatus: (s) => setState(() => _status = s),
      ),
    );
  }

  /// Shared plumbing for both providers: both resolve with a server-issued
  /// payment token, so success handling is identical.
  Future<void> _run(String initialStatus, Future<String> Function() pay) async {
    setState(() {
      _busy = true;
      _error = null;
      _status = initialStatus;
    });
    try {
      final token = await pay();
      if (!mounted) return;
      context.read<ResumeProvider>().setAiPaymentToken(token);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.billing.product?.price ?? '₹29';
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: AppColors.brand, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Unlock AI-enhanced download',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  IconButton(
                    onPressed: _busy ? null : () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close, color: AppColors.inkMuted),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'AI enhancement is free — pay once to download the polished, '
                'professionally rewritten PDF. The unlock stays active for '
                'the current resume; reset to remove it.',
                style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.brand.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.brand.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI-enhanced PDF download',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          Text('One-time fee · Google Play or UPI/Card',
                              style: TextStyle(
                                  color: AppColors.inkMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                    Text(price,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brand)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_error!,
                        style: const TextStyle(
                            color: AppColors.danger, fontSize: 12)),
                  ),
                ),
              ElevatedButton(
                onPressed: _busy ? null : _purchase,
                child: Text(_busy
                    ? (_status.isEmpty ? 'Processing…' : _status)
                    : 'Pay with Google Play'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _busy ? null : _purchaseRazorpay,
                icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                label: const Text('Pay with UPI / Card (Razorpay)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Secure billing via Google Play or Razorpay. After payment your '
                'download starts automatically.',
                style: TextStyle(color: AppColors.inkMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
