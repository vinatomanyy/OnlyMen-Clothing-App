import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking.dart';
import '../data/supabase_repository.dart';

class BookingLogEntry {
  final String branchName;
  final String date;
  final String time;
  final String status;
  const BookingLogEntry({
    required this.branchName,
    required this.date,
    required this.time,
    required this.status,
  });
}

class BookingState {
  final String? service;
  final DateTime? date;
  final String? timeSlot;
  final String? name;
  final String? email;
  final String? phone;
  final bool isLoading;
  final bool isSuccess;
  final String? error;
  final List<BookingLogEntry> log;

  const BookingState({
    this.service,
    this.date,
    this.timeSlot,
    this.name,
    this.email,
    this.phone,
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
    this.log = const [],
  });

  BookingState copyWith({
    String? service,
    DateTime? date,
    String? timeSlot,
    String? name,
    String? email,
    String? phone,
    bool? isLoading,
    bool? isSuccess,
    String? error,
    List<BookingLogEntry>? log,
  }) =>
      BookingState(
        service: service ?? this.service,
        date: date ?? this.date,
        timeSlot: timeSlot ?? this.timeSlot,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        isLoading: isLoading ?? this.isLoading,
        isSuccess: isSuccess ?? this.isSuccess,
        error: error ?? this.error,
        log: log ?? this.log,
      );
}

class BookingNotifier extends Notifier<BookingState> {
  @override
  BookingState build() => const BookingState();

  void setService(String service) =>
      state = state.copyWith(service: service);

  void setDate(DateTime date) =>
      state = state.copyWith(date: date);

  void setTimeSlot(String slot) =>
      state = state.copyWith(timeSlot: slot);

  void setContactInfo(String name, String email) =>
      state = state.copyWith(name: name, email: email);

  void setPhone(String phone) =>
      state = state.copyWith(phone: phone);

  void addToLog(BookingLogEntry entry) =>
      state = state.copyWith(log: [entry, ...state.log]);

  Future<void> submit() async {
    if (state.service == null ||
        state.date == null ||
        state.timeSlot == null ||
        state.name == null ||
        state.email == null) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    final booking = Booking(
      service: state.service!,
      date: state.date!,
      timeSlot: state.timeSlot!,
      name: state.name!,
      email: state.email!,
    );

    final success = await SupabaseRepository.createBooking(booking);

    state = state.copyWith(
      isLoading: false,
      isSuccess: success,
      error: success ? null : 'Booking failed. Please try again.',
    );
  }

  void reset() => state = const BookingState();
}

final bookingProvider =
    NotifierProvider<BookingNotifier, BookingState>(BookingNotifier.new);