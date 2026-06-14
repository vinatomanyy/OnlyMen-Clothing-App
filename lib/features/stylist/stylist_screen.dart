import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/booking_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

// Mock stylist data
class _Stylist {
  final String name;
  final String title;
  final String bio;
  final String avatarUrl;
  final double rating;
  final int clients;
  final List<String> specialties;
  final List<_PickItem> picks;

  const _Stylist({
    required this.name,
    required this.title,
    required this.bio,
    required this.avatarUrl,
    required this.rating,
    required this.clients,
    required this.specialties,
    required this.picks,
  });
}

class _PickItem {
  final String imageUrl;
  final String name;
  final String price;
  const _PickItem(
      {required this.imageUrl, required this.name, required this.price});
}

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
  picks: [
    _PickItem(
      imageUrl:
          'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=400',
      name: 'Structured Wool Overcoat',
      price: '\$390',
    ),
    _PickItem(
      imageUrl:
          'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=400',
      name: 'Slim Navy Chinos',
      price: '\$75',
    ),
    _PickItem(
      imageUrl:
          'https://images.unsplash.com/photo-1614252235316-8c857d38b5f4?w=400',
      name: 'Leather Derby Shoes',
      price: '\$190',
    ),
  ],
);

final _timeSlots = [
  '09:00 AM', '10:00 AM', '11:00 AM',
  '01:00 PM', '02:00 PM', '03:00 PM',
  '04:00 PM', '05:00 PM',
];

class StylistScreen extends ConsumerStatefulWidget {
  const StylistScreen({super.key});

  @override
  ConsumerState<StylistScreen> createState() => _StylistScreenState();
}

class _StylistScreenState extends ConsumerState<StylistScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedSlot;

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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    _scrollController.dispose();
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
    // Show typing indicator then reply
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

  void _confirmBooking() {
    if (_selectedDay == null || _selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a date and time',
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.white)),
          backgroundColor: AppColors.grey800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    ref.read(bookingProvider.notifier)
      ..setService('Personal Styling Session')
      ..setDate(_selectedDay!)
      ..setTimeSlot(_selectedSlot!);

    showDialog(
      context: context,
      builder: (_) => _BookingConfirmDialog(
        day: _selectedDay!,
        slot: _selectedSlot!,
        onConfirm: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Booking confirmed!',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.black)),
              backgroundColor: AppColors.accent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          _buildSliverHeader(),
        ],
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBookingTab(),
                  _buildChatTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildSliverHeader() => SliverAppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        expandedHeight: 280,
        pinned: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        flexibleSpace: FlexibleSpaceBar(
          background: _buildProfile(),
        ),
        title: Text('PERSONAL STYLING',
            style:
                AppTextStyles.labelSmall.copyWith(color: Theme.of(context).colorScheme.onSurface)),
        centerTitle: true,
      );

  Widget _buildProfile() => Container(
        color: AppColors.surfaceDark,
        padding: const EdgeInsets.fromLTRB(20, 80, 20, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent, width: 2),
              ),
              child: ClipOval(
                child: Image.network(
                  _mockStylist.avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.grey800,
                    child: const Icon(Icons.person,
                        color: AppColors.grey600, size: 40),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_mockStylist.name,
                      style:
                          AppTextStyles.h3.copyWith(color: AppColors.white)),
                  const SizedBox(height: 2),
                  Text(_mockStylist.title,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.accent)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StatChip(
                          label: '${_mockStylist.rating}',
                          sub: 'Rating'),
                      const SizedBox(width: 16),
                      _StatChip(
                          label: '${_mockStylist.clients}',
                          sub: 'Clients'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: _mockStylist.specialties
                        .map((s) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: AppColors.grey700),
                              ),
                              child: Text(s,
                                  style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.grey400,
                                      fontSize: 9)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  Text(_mockStylist.bio,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.grey400, height: 1.5),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildTabBar() => Container(
        color: AppColors.surfaceDark,
        child: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          indicatorWeight: 1,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.grey600,
          labelStyle: AppTextStyles.labelSmall,
          tabs: const [
            Tab(text: 'BOOKING'),
            Tab(text: 'CHAT'),
          ],
        ),
      );

  // ── BOOKING TAB ──────────────────────────────────────────────────
  Widget _buildBookingTab() => ListView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
        children: [
          Text('BOOK APPOINTMENT',
              style:
                  AppTextStyles.labelSmall.copyWith(color: AppColors.grey400)),
          const SizedBox(height: 16),
          _buildCalendar(),
          const SizedBox(height: 24),
          if (_selectedDay != null) ...[
            Text(
              'AVAILABLE TIMES',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.grey400),
            ),
            const SizedBox(height: 12),
            _buildTimeSlots(),
            const SizedBox(height: 24),
          ],
          GestureDetector(
            onTap: _confirmBooking,
            child: Container(
              height: 52,
              color: (_selectedDay != null && _selectedSlot != null)
                  ? AppColors.accent
                  : AppColors.grey800,
              alignment: Alignment.center,
              child: Text(
                'CONFIRM BOOKING',
                style: AppTextStyles.labelLarge.copyWith(
                  color: (_selectedDay != null && _selectedSlot != null)
                      ? AppColors.black
                      : AppColors.grey600,
                ),
              ),
            ),
          ),
        ],
      );

  Widget _buildCalendar() {
    final now = DateTime.now();
    final firstDay =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // Sun=0

    return Column(
      children: [
        // Month nav
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _focusedMonth =
                  DateTime(_focusedMonth.year, _focusedMonth.month - 1)),
              child: const Icon(Icons.chevron_left,
                  color: AppColors.grey400, size: 22),
            ),
            const Spacer(),
            Text(
              '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.white),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _focusedMonth =
                  DateTime(_focusedMonth.year, _focusedMonth.month + 1)),
              child: const Icon(Icons.chevron_right,
                  color: AppColors.grey400, size: 22),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Day headers
        Row(
          children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
              .map((d) => Expanded(
                    child: Center(
                      child: Text(d,
                          style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.grey600, fontSize: 10)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        // Days grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemCount: startWeekday + daysInMonth,
          itemBuilder: (_, i) {
            if (i < startWeekday) return const SizedBox.shrink();
            final day = i - startWeekday + 1;
            final date = DateTime(
                _focusedMonth.year, _focusedMonth.month, day);
            final isPast = date.isBefore(
                DateTime(now.year, now.month, now.day));
            final isSelected = _selectedDay != null &&
                _selectedDay!.year == date.year &&
                _selectedDay!.month == date.month &&
                _selectedDay!.day == date.day;
            final isToday = date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;

            return GestureDetector(
              onTap: isPast
                  ? null
                  : () => setState(() {
                        _selectedDay = date;
                        _selectedSlot = null;
                      }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent
                      : isToday
                          ? AppColors.grey800
                          : Colors.transparent,
                  border: isToday && !isSelected
                      ? Border.all(
                          color: AppColors.grey600, width: 1)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isPast
                        ? AppColors.grey800
                        : isSelected
                            ? AppColors.black
                            : AppColors.white,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTimeSlots() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _timeSlots.map((slot) {
          final selected = slot == _selectedSlot;
          return GestureDetector(
            onTap: () => setState(() => _selectedSlot = slot),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color:
                    selected ? AppColors.accent : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? AppColors.accent
                      : AppColors.grey700,
                ),
              ),
              child: Text(
                slot,
                style: AppTextStyles.labelSmall.copyWith(
                  color: selected
                      ? AppColors.black
                      : AppColors.grey400,
                  fontSize: 11,
                ),
              ),
            ),
          );
        }).toList(),
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
            decoration: const BoxDecoration(
              color: AppColors.surfaceDark,
              border: Border(top: BorderSide(color: AppColors.grey800)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Attachments coming soon',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.black)),
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
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey600),
                      filled: true,
                      fillColor: AppColors.grey900,
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
              decoration: const BoxDecoration(
                color: AppColors.cardDark,
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
                backgroundImage:
                    NetworkImage(_mockStylist.avatarUrl),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: msg.isAlex
                          ? AppColors.grey800
                          : AppColors.accent,
                    ),
                    child: Text(
                      msg.text,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: msg.isAlex
                            ? AppColors.white
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


  String _monthName(int month) => [
        '', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ][month];
}

// ── Supporting widgets ────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String sub;
  const _StatChip({required this.label, required this.sub});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  AppTextStyles.h3.copyWith(color: AppColors.white)),
          Text(sub,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.grey600, fontSize: 10)),
        ],
      );
}


class _ChatMessage {
  final String text;
  final bool isAlex;
  final String time;
  const _ChatMessage(
      {required this.text, required this.isAlex, required this.time});
}

class _BookingConfirmDialog extends StatelessWidget {
  final DateTime day;
  final String slot;
  final VoidCallback onConfirm;

  const _BookingConfirmDialog({
    required this.day,
    required this.slot,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CONFIRM BOOKING',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.white)),
              const SizedBox(height: 16),
              _DialogRow(
                  label: 'Service',
                  value: 'Personal Styling Session'),
              const SizedBox(height: 8),
              _DialogRow(
                  label: 'Stylist', value: _mockStylist.name),
              const SizedBox(height: 8),
              _DialogRow(
                  label: 'Date',
                  value:
                      '${day.day}/${day.month}/${day.year}'),
              const SizedBox(height: 8),
              _DialogRow(label: 'Time', value: slot),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.grey700),
                        ),
                        alignment: Alignment.center,
                        child: Text('CANCEL',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.grey400)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        onConfirm();
                      },
                      child: Container(
                        height: 44,
                        color: AppColors.accent,
                        alignment: Alignment.center,
                        child: Text('CONFIRM',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.black)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _DialogRow extends StatelessWidget {
  final String label;
  final String value;
  const _DialogRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text('$label: ',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.grey500)),
          Text(value,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.white)),
        ],
      );
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