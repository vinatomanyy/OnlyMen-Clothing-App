import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/booking_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

const _services = [
  {'title': 'Personal Styling', 'subtitle': 'One-on-one session with a stylist to build your look', 'icon': Icons.person_outline, 'duration': '60 min'},
  {'title': 'Wardrobe Consultation', 'subtitle': 'Review your wardrobe and plan your next season', 'icon': Icons.checkroom_outlined, 'duration': '45 min'},
  {'title': 'Try-On Experience', 'subtitle': 'Try curated pieces selected for your body type', 'icon': Icons.straighten_outlined, 'duration': '30 min'},
  {'title': 'Style Discovery', 'subtitle': 'Find your personal style with guided exploration', 'icon': Icons.explore_outlined, 'duration': '45 min'},
];

const _timeSlots = [
  '9:00 AM', '10:00 AM', '11:00 AM', '12:00 PM',
  '2:00 PM', '3:00 PM', '4:00 PM', '5:00 PM',
];

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  int _step = 0; // 0: service, 1: date, 2: time, 3: contact, 4: confirmation
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _next() => setState(() => _step++);
  void _back() => _step == 0 ? context.pop() : setState(() => _step--);

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty || email.isEmpty) return;
    ref.read(bookingProvider.notifier).setContactInfo(name, email);
    // Simulate success (Supabase integrated later)
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _step = 4);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _step == 4 ? null : _buildAppBar(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _buildStep(),
      ),
    );
  }

  AppBar _buildAppBar() {
    const titles = ['BOOKING', 'SELECT DATE', 'SELECT TIME', 'YOUR DETAILS'];
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
        onPressed: _back,
      ),
      title: Text(titles[_step.clamp(0, 3)],
          style: AppTextStyles.labelLarge.copyWith(color: Theme.of(context).colorScheme.onSurface)),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(3),
        child: Row(
          children: List.generate(4, (i) => Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 3,
              color: i <= _step ? AppColors.accent : AppColors.grey800,
            ),
          )),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _buildServiceStep();
      case 1: return _buildDateStep();
      case 2: return _buildTimeStep();
      case 3: return _buildContactStep();
      case 4: return _buildConfirmation();
      default: return _buildServiceStep();
    }
  }

  // ── Step 1: Service ───────────────────────────────────────────
  Widget _buildServiceStep() {
    final selected = ref.watch(bookingProvider).service;
    return Column(
      key: const ValueKey(0),
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 8),
              Text('CHOOSE A SERVICE',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.grey400, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              ..._services.map((s) {
                final isSelected = selected == s['title'];
                return GestureDetector(
                  onTap: () => ref.read(bookingProvider.notifier).setService(s['title'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accent.withValues(alpha: 0.08) : AppColors.cardDark,
                      border: Border.all(
                        color: isSelected ? AppColors.accent : AppColors.grey800,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          color: isSelected ? AppColors.accent.withValues(alpha: 0.15) : AppColors.grey900,
                          child: Icon(s['icon'] as IconData,
                              color: isSelected ? AppColors.accent : AppColors.grey500, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s['title'] as String,
                                  style: AppTextStyles.labelMedium.copyWith(
                                      color: isSelected ? AppColors.accent : AppColors.white)),
                              const SizedBox(height: 4),
                              Text(s['subtitle'] as String,
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: AppColors.grey500, fontSize: 11),
                                  maxLines: 2),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            Text(s['duration'] as String,
                                style: AppTextStyles.labelSmall
                                    .copyWith(color: AppColors.grey600, fontSize: 10)),
                            const SizedBox(height: 4),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: AppColors.accent, size: 18),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        _buildBottomBar('CONTINUE', enabled: selected != null, onTap: _next),
      ],
    );
  }

  // ── Step 2: Date ──────────────────────────────────────────────
  Widget _buildDateStep() {
    final selectedDate = ref.watch(bookingProvider).date;
    final now = DateTime.now();
    return Column(
      key: const ValueKey(1),
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 8),
              Text('PICK A DATE',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.grey400, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  border: Border.all(color: AppColors.grey800),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.accent,
                      onPrimary: AppColors.black,
                      surface: AppColors.cardDark,
                      onSurface: AppColors.white,
                    ),
                  ),
                  child: CalendarDatePicker(
                    initialDate: selectedDate ?? now.add(const Duration(days: 1)),
                    firstDate: now.add(const Duration(days: 1)),
                    lastDate: now.add(const Duration(days: 60)),
                    onDateChanged: (date) =>
                        ref.read(bookingProvider.notifier).setDate(date),
                  ),
                ),
              ),
              if (selectedDate != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.08),
                    border: Border.all(color: AppColors.accent),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppColors.accent, size: 16),
                      const SizedBox(width: 10),
                      Text(_formatDate(selectedDate),
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.accent)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        _buildBottomBar('CONTINUE', enabled: selectedDate != null, onTap: _next),
      ],
    );
  }

  // ── Step 3: Time slot ─────────────────────────────────────────
  Widget _buildTimeStep() {
    final selected = ref.watch(bookingProvider).timeSlot;
    return Column(
      key: const ValueKey(2),
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 8),
              Text('AVAILABLE TIMES',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.grey400, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 3,
                children: _timeSlots.map((slot) {
                  final isSelected = selected == slot;
                  return GestureDetector(
                    onTap: () => ref.read(bookingProvider.notifier).setTimeSlot(slot),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accent.withValues(alpha: 0.1) : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? AppColors.accent : AppColors.grey700,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(slot,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isSelected ? AppColors.accent : AppColors.grey300,
                          )),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        _buildBottomBar('CONTINUE', enabled: selected != null, onTap: _next),
      ],
    );
  }

  // ── Step 4: Contact ───────────────────────────────────────────
  Widget _buildContactStep() {
    final state = ref.watch(bookingProvider);
    final canSubmit = _nameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty;

    return Column(
      key: const ValueKey(3),
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 8),
              Text('YOUR DETAILS',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.grey400, letterSpacing: 1.5)),
              const SizedBox(height: 20),
              // Booking summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.grey900,
                  border: Border.all(color: AppColors.grey800),
                ),
                child: Column(
                  children: [
                    _SummaryRow(label: 'Service', value: state.service ?? ''),
                    const SizedBox(height: 10),
                    _SummaryRow(label: 'Date', value: _formatDate(state.date!)),
                    const SizedBox(height: 10),
                    _SummaryRow(label: 'Time', value: state.timeSlot ?? ''),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildField('FULL NAME', 'John Doe', _nameController),
              const SizedBox(height: 16),
              _buildField('EMAIL', 'john@example.com', _emailController,
                  keyboardType: TextInputType.emailAddress),
            ],
          ),
        ),
        _buildBottomBar(
          state.isLoading ? 'BOOKING...' : 'CONFIRM BOOKING',
          enabled: canSubmit && !state.isLoading,
          loading: state.isLoading,
          onTap: _submit,
          rebuildOnType: true,
        ),
      ],
    );
  }

  // ── Step 5: Confirmation ──────────────────────────────────────
  Widget _buildConfirmation() {
    final state = ref.watch(bookingProvider);
    return SafeArea(
      key: const ValueKey(4),
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
            Text('BOOKING CONFIRMED',
                style: AppTextStyles.h2.copyWith(color: AppColors.white)),
            const SizedBox(height: 12),
            Text(
              'We\'ll see you soon. A confirmation has been sent to your email.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey400),
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
                  _SummaryRow(label: 'Service', value: state.service ?? ''),
                  const SizedBox(height: 12),
                  _SummaryRow(label: 'Date', value: _formatDate(state.date ?? DateTime.now())),
                  const SizedBox(height: 12),
                  _SummaryRow(label: 'Time', value: state.timeSlot ?? ''),
                  const SizedBox(height: 12),
                  _SummaryRow(label: 'Name', value: _nameController.text),
                  const SizedBox(height: 12),
                  _SummaryRow(label: 'Email', value: _emailController.text),
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
                child: Text('BACK TO HOME',
                    style: AppTextStyles.labelLarge.copyWith(color: AppColors.black)),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => context.go('/stylist'),
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(border: Border.all(color: AppColors.grey700)),
                alignment: Alignment.center,
                child: Text('VIEW STYLIST',
                    style: AppTextStyles.labelLarge.copyWith(color: Theme.of(context).colorScheme.onSurface)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────
  Widget _buildBottomBar(
    String label, {
    required bool enabled,
    required VoidCallback onTap,
    bool loading = false,
    bool rebuildOnType = false,
  }) =>
      StatefulBuilder(
        builder: (context, setBar) => Container(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
          decoration: const BoxDecoration(
            color: AppColors.surfaceDark,
            border: Border(top: BorderSide(color: AppColors.grey800)),
          ),
          child: GestureDetector(
            onTap: enabled ? onTap : null,
            child: Container(
              height: 52,
              color: enabled ? AppColors.accent : AppColors.grey800,
              alignment: Alignment.center,
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: AppColors.black, strokeWidth: 2))
                  : Text(label,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: enabled ? AppColors.black : AppColors.grey600,
                      )),
            ),
          ),
        ),
      );

  Widget _buildField(
    String label,
    String hint,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.grey400, fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
              filled: true,
              fillColor: AppColors.grey900,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.grey700)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.grey700)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.accent)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ],
      );

  String _formatDate(DateTime d) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday]}, ${d.day} ${months[d.month]} ${d.year}';
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500)),
          Text(value,
              style: AppTextStyles.labelSmall.copyWith(color: Theme.of(context).colorScheme.onSurface)),
        ],
      );
}
