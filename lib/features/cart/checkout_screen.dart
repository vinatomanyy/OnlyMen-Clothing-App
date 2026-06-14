import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/card_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final double total;
  const CheckoutScreen({super.key, required this.total});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int _step = 0; // 0: address, 1: payment, 2: confirmation
  bool _placing = false;
  late String _orderNumber;

  // Address fields
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  // Payment fields
  final _cardController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardNameController = TextEditingController();

  final _addressFormKey = GlobalKey<FormState>();
  final _paymentFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _cardController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardNameController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step == 0 && !(_addressFormKey.currentState?.validate() ?? false)) return;
    if (_step == 1 && !(_paymentFormKey.currentState?.validate() ?? false)) return;

    if (_step == 1) {
      _placeOrder();
      return;
    }
    setState(() => _step++);
  }

  Future<void> _placeOrder() async {
    setState(() => _placing = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    _orderNumber = 'OM${Random().nextInt(900000) + 100000}';
    ref.read(cartProvider.notifier).clear();
    setState(() {
      _placing = false;
      _step = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _step == 2 ? null : _buildAppBar(),
      body: _step == 0
          ? _buildAddressStep()
          : _step == 1
              ? _buildPaymentStep()
              : _buildConfirmation(context),
    );
  }

  AppBar _buildAppBar() => AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => _step == 0 ? context.pop() : setState(() => _step--),
        ),
        title: Text(
          _step == 0 ? 'DELIVERY' : 'PAYMENT',
          style: AppTextStyles.labelLarge.copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Row(
            children: List.generate(2, (i) => Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 3,
                color: i <= _step ? AppColors.accent : AppColors.grey800,
              ),
            )),
          ),
        ),
      );

  // ── Step 1: Address ───────────────────────────────────────────
  Widget _buildAddressStep() => Form(
        key: _addressFormKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 8),
                  Text('DELIVERY DETAILS',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.grey400, letterSpacing: 1.5)),
                  const SizedBox(height: 20),
                  _buildField(
                    controller: _nameController,
                    label: 'Full Name',
                    hint: 'John Doe',
                    validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: '+855 12 345 678',
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _addressController,
                    label: 'Street Address',
                    hint: '123 Norodom Blvd',
                    validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _cityController,
                    label: 'City',
                    hint: 'Phnom Penh',
                    validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.grey900,
                      border: Border.all(color: AppColors.grey800),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_shipping_outlined,
                            color: AppColors.accent, size: 18),
                        const SizedBox(width: 10),
                        Text('Free delivery on all orders',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.grey400)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildBottomBar('CONTINUE TO PAYMENT', widget.total),
          ],
        ),
      );

  // ── Step 2: Payment ───────────────────────────────────────────
  Widget _buildPaymentStep() => Form(
        key: _paymentFormKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 8),
                  Text('PAYMENT DETAILS',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.grey400, letterSpacing: 1.5)),
                  const SizedBox(height: 20),
                  // Mock card preview
                  Container(
                    height: 160,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.grey900, AppColors.cardDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: AppColors.grey700),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('ONLYMEN',
                                style: AppTextStyles.labelSmall
                                    .copyWith(color: AppColors.accent, letterSpacing: 2)),
                            const Icon(Icons.credit_card,
                                color: AppColors.grey600, size: 28),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          _cardController.text.isEmpty
                              ? '•••• •••• •••• ••••'
                              : _formatCardDisplay(_cardController.text),
                          style: AppTextStyles.labelLarge
                              .copyWith(color: AppColors.white, letterSpacing: 2),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              _cardNameController.text.isEmpty
                                  ? 'CARD HOLDER'
                                  : _cardNameController.text.toUpperCase(),
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.grey400),
                            ),
                            const Spacer(),
                            Text(
                              _expiryController.text.isEmpty
                                  ? 'MM/YY'
                                  : _expiryController.text,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.grey400),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildField(
                    controller: _cardNameController,
                    label: 'Name on Card',
                    hint: 'John Doe',
                    onChanged: (_) => setState(() {}),
                    validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _cardController,
                    label: 'Card Number',
                    hint: '1234 5678 9012 3456',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                      _CardNumberFormatter(),
                    ],
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final digits = v!.replaceAll(' ', '');
                      return digits.length < 16 ? 'Enter a valid card number' : null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          controller: _expiryController,
                          label: 'Expiry',
                          hint: 'MM/YY',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                            _ExpiryFormatter(),
                          ],
                          onChanged: (_) => setState(() {}),
                          validator: (v) => v!.length < 5 ? 'Invalid' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildField(
                          controller: _cvvController,
                          label: 'CVV',
                          hint: '•••',
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          validator: (v) => v!.length < 3 ? 'Invalid' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.lock_outline,
                          color: AppColors.grey600, size: 14),
                      const SizedBox(width: 6),
                      Text('Mock payment — no real charge',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.grey600, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            _buildBottomBar(
              _placing ? 'PLACING ORDER...' : 'PLACE ORDER',
              widget.total,
              loading: _placing,
            ),
          ],
        ),
      );

  // ── Step 3: Confirmation ──────────────────────────────────────
  Widget _buildConfirmation(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: AppColors.black, size: 40),
              ),
              const SizedBox(height: 28),
              Text('ORDER PLACED',
                  style: AppTextStyles.h2.copyWith(color: AppColors.white)),
              const SizedBox(height: 12),
              Text(
                'Thank you! Your order has been received.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.grey400),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.grey900,
                  border: Border.all(color: AppColors.grey800),
                ),
                child: Column(
                  children: [
                    _ConfirmRow(label: 'Order Number', value: '#$_orderNumber'),
                    const SizedBox(height: 12),
                    _ConfirmRow(
                        label: 'Total Paid',
                        value: '\$${widget.total.toStringAsFixed(2)}'),
                    const SizedBox(height: 12),
                    _ConfirmRow(
                        label: 'Delivery',
                        value: _cityController.text.isEmpty
                            ? 'Phnom Penh'
                            : _cityController.text),
                    const SizedBox(height: 12),
                    _ConfirmRow(label: 'Estimated', value: '3–5 business days'),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () => context.go('/home'),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  color: AppColors.accent,
                  alignment: Alignment.center,
                  child: Text('CONTINUE SHOPPING',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: AppColors.black)),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => context.push('/lookbook'),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.grey700),
                  ),
                  alignment: Alignment.center,
                  child: Text('EXPLORE LOOKBOOK',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: AppColors.white)),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildBottomBar(String label, double total, {bool loading = false}) =>
      Container(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total',
                    style:
                        AppTextStyles.bodySmall.copyWith(color: AppColors.grey400)),
                Text('\$${total.toStringAsFixed(2)}',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.white)),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: loading ? null : _nextStep,
              child: Container(
                height: 52,
                color: loading ? AppColors.grey700 : AppColors.accent,
                alignment: Alignment.center,
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: AppColors.black, strokeWidth: 2),
                      )
                    : Text(label,
                        style: AppTextStyles.labelLarge
                            .copyWith(color: AppColors.black)),
              ),
            ),
          ],
        ),
      );

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.grey400, fontSize: 10, letterSpacing: 1)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            obscureText: obscureText,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
            onChanged: onChanged,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
              filled: true,
              fillColor: AppColors.grey900,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppColors.grey700),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppColors.grey700),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppColors.accent),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppColors.error),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ],
      );

  String _formatCardDisplay(String digits) {
    final clean = digits.replaceAll(' ', '');
    final groups = <String>[];
    for (int i = 0; i < clean.length; i += 4) {
      groups.add(clean.substring(i, min(i + 4, clean.length)));
    }
    return groups.join(' ');
  }
}

// ── Formatters ────────────────────────────────────────────────────
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return newValue.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('/', '');
    if (digits.length >= 2) {
      final text = '${digits.substring(0, 2)}/${digits.substring(2)}';
      return newValue.copyWith(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
    return newValue;
  }
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;
  const _ConfirmRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.grey500)),
          Text(value,
              style: AppTextStyles.labelSmall.copyWith(color: Theme.of(context).colorScheme.onSurface)),
        ],
      );
}
