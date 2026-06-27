import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/branch.dart';
import '../../state/booking_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

const _mockStylist = _Stylist(
  name: 'Alex Chen',
  title: 'SENIOR STYLIST',
  bio:
      'Elevating your everyday wardrobe with precision tailoring and minimalist essentials. Let\'s curate a look that speaks your language.',
  avatarUrl:
      'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=400',
  rating: 4.9,
  clients: 312,
  specialties: ['Tailoring', 'Minimalist', 'Business'],
);

class _Stylist {
  final String name;
  final String title;
  final String bio;
  final String avatarUrl;
  final double rating;
  final int clients;
  final List<String> specialties;

  const _Stylist({
    required this.name,
    required this.title,
    required this.bio,
    required this.avatarUrl,
    required this.rating,
    required this.clients,
    required this.specialties,
  });
}

final _timeSlots = [
  '09:00', '10:00', '11:00',
  '13:00', '14:00', '15:00',
  '16:00', '17:00',
];

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  List<Branch> _branches = [];
  int? _selectedBranchIdx;
  DateTime? _selectedDate;
  String? _selectedSlot;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _showChat = false;

  // Chat state
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;
  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text:
          'Hi there! Looking over your recent purchases. Thinking we should lean into heavier layers for the upcoming season. Thoughts?',
      isAlex: true,
      time: '11:42 AM',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    final raw = await rootBundle.loadString('assets/mock/branches.json');
    final list = (jsonDecode(raw) as List)
        .map((e) => Branch.fromJson(e))
        .toList();
    if (mounted) setState(() => _branches = list);
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(
        text: text,
        isAlex: false,
        time: _timeNow(),
      ));
      _chatController.clear();
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    setState(() => _isTyping = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(const _ChatMessage(
          text: 'Great choice! I\'ll put together some options for you.',
          isAlex: true,
          time: '',
        ));
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  String _timeNow() {
    final now = DateTime.now();
    final h = now.hour > 12 ? now.hour - 12 : now.hour;
    final m = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              backgroundColor: isDark ? AppColors.cardDark : Theme.of(context).cardColor,
              headerBackgroundColor: isDark ? AppColors.grey900 : Theme.of(context).cardColor,
              headerForegroundColor: isDark ? AppColors.white : Theme.of(context).colorScheme.onSurface,
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return isDark ? AppColors.black : AppColors.white;
                return isDark ? AppColors.white : Theme.of(context).colorScheme.onSurface;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return AppColors.accent;
                return null;
              }),
              todayForegroundColor: WidgetStateProperty.all(AppColors.accent),
              surfaceTintColor: Colors.transparent,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _confirmBooking() {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (_selectedBranchIdx == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a branch',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.white)),
          backgroundColor: AppColors.grey800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_selectedDate == null || _selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a date and time',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.white)),
          backgroundColor: AppColors.grey800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your name and phone number',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.white)),
          backgroundColor: AppColors.grey800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final branch = _branches[_selectedBranchIdx!];
    ref.read(bookingProvider.notifier)
      ..setService('Try-On Experience — ${branch.name}')
      ..setDate(_selectedDate!)
      ..setTimeSlot(_selectedSlot!)
      ..setContactInfo(name, '')
      ..setPhone(phone);

    ref.read(bookingProvider.notifier).addToLog(BookingLogEntry(
      branchName: branch.name,
      date: '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
      time: _selectedSlot!,
      status: 'Confirmed',
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking confirmed!',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.black)),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
      ),
    );
    setState(() {
      _selectedSlot = null;
      _nameCtrl.clear();
      _phoneCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        title: const SizedBox.shrink(),
      ),
      body: _showChat ? _buildChatView() : _buildBookingTab(),
    );
  }

  // ── BOOKING TAB ──────────────────────────────────────────────────
  Widget _buildBookingTab() => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ref.watch(bookingProvider).log.isNotEmpty) ...[
              Text('YOUR BOOKINGS',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey400)),
              const SizedBox(height: 12),
              ...ref.watch(bookingProvider).log.map((b) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4, height: 40,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b.branchName,
                                  style: AppTextStyles.bodySmall.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('${b.date} · ${b.time}',
                                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500, fontSize: 11)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                          ),
                          child: Text(b.status,
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.success, fontSize: 9)),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => setState(() => _showChat = true),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(_mockStylist.avatarUrl),
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Message Your Stylist',
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text('Chat with Alex Chen',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500, fontSize: 10)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.grey500, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Divider(color: Theme.of(context).dividerColor, height: 1),
              const SizedBox(height: 28),
            ],
            Text('BOOK A TRY-ON',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey400)),
            const SizedBox(height: 16),
            // Date picker
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _pickDate,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppColors.grey500, size: 18),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDate != null
                              ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                              : 'Select a date',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: _selectedDate != null
                                ? Theme.of(context).colorScheme.onSurface
                                : AppColors.grey500,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right, color: AppColors.grey500, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Branch
            Text('BRANCH',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey400)),
            const SizedBox(height: 10),
            _buildBranchSelector(),
            const SizedBox(height: 20),
            // Time slots
            Text('TIME',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey400)),
            const SizedBox(height: 10),
            _buildTimeSlots(),
            const SizedBox(height: 20),
            // Name
            Text('YOUR NAME',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey400)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Enter your name',
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(0),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            // Phone
            Text('PHONE NUMBER',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey400)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: '+855 ',
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(0),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),
            // Confirm button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: GestureDetector(
                onTap: _confirmBooking,
                child: Container(
                  color: (_selectedBranchIdx != null && _selectedDate != null && _selectedSlot != null &&
                          _nameCtrl.text.trim().isNotEmpty && _phoneCtrl.text.trim().isNotEmpty)
                      ? AppColors.accent
                      : Theme.of(context).dividerColor,
                  alignment: Alignment.center,
                  child: Text(
                    'CONFIRM BOOKING',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: (_selectedDate != null && _selectedSlot != null)
                          ? AppColors.black
                          : AppColors.grey600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildBranchSelector() => Column(
        children: _branches.asMap().entries.map((entry) {
          final i = entry.key;
          final branch = entry.value;
          final selected = _selectedBranchIdx == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedBranchIdx = i),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: selected ? Theme.of(context).cardColor : Colors.transparent,
                border: Border.all(
                  color: selected ? AppColors.accent : Theme.of(context).dividerColor,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? AppColors.accent : Colors.transparent,
                      border: Border.all(
                        color: selected ? AppColors.accent : AppColors.grey600,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: selected
                        ? const Icon(Icons.check, size: 12, color: AppColors.black)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(branch.name,
                            style: AppTextStyles.bodySmall.copyWith(
                                color: Theme.of(context).colorScheme.onSurface)),
                        const SizedBox(height: 2),
                        Text(branch.address,
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.grey500, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );

  Widget _buildTimeSlots() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _timeSlots.map((slot) {
          final selected = slot == _selectedSlot;
          return GestureDetector(
            onTap: () => setState(() => _selectedSlot = slot),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? AppColors.accent : Colors.transparent,
                border: Border.all(
                  color: selected ? AppColors.accent : Theme.of(context).dividerColor,
                ),
              ),
              child: Text(
                slot,
                style: AppTextStyles.labelSmall.copyWith(
                  color: selected ? AppColors.black : Theme.of(context).colorScheme.onSurface,
                  fontSize: 11,
                ),
              ),
            ),
          );
        }).toList(),
      );

  // ── CHAT VIEW ────────────────────────────────────────────────────
  Widget _buildChatView() => Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _showChat = false),
                  child: const Icon(Icons.arrow_back, color: AppColors.grey500, size: 22),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(_mockStylist.avatarUrl),
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_mockStylist.name,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
                    Text('Online',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.success, fontSize: 9)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(child: _buildChatTab()),
        ],
      );

  // ── CHAT TAB ─────────────────────────────────────────────────────
  Widget _buildChatTab() => Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (_, i) {
                if (_isTyping && i == _messages.length) {
                  return _buildTypingIndicator();
                }
                return _buildChatBubble(_messages[i]);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Attachments coming soon'),
                      backgroundColor: AppColors.accent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(Icons.attach_file, color: AppColors.grey500, size: 22),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    color: AppColors.accent,
                    child: const Icon(Icons.send, color: AppColors.black, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildTypingIndicator() => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(_mockStylist.avatarUrl),
              backgroundColor: AppColors.grey800,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
              ),
              child: _TypingDots(),
            ),
          ],
        ),
      );

  Widget _buildChatBubble(_ChatMessage msg) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: msg.isAlex
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (msg.isAlex) ...[
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(_mockStylist.avatarUrl),
                backgroundColor: AppColors.grey800,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: msg.isAlex
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: msg.isAlex
                          ? Theme.of(context).cardColor
                          : AppColors.accent,
                    ),
                    child: Text(
                      msg.text,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: msg.isAlex
                            ? Theme.of(context).colorScheme.onSurface
                            : AppColors.black,
                        height: 1.5,
                      ),
                    ),
                  ),
                  if (msg.time.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(msg.time,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.grey700, fontSize: 10)),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

class _ChatMessage {
  final String text;
  final bool isAlex;
  final String time;
  const _ChatMessage(
      {required this.text, required this.isAlex, required this.time});
}

class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final value = ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
            final opacity = value < 0.5 ? value * 2 : (1.0 - value) * 2;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.grey400.withValues(alpha: opacity.clamp(0.3, 1.0)),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      );
}
