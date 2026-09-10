import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<String> _getEventsForDay(DateTime day) {
    if (day.day == 15) return ['blue'];
    if (day.day == 18) return ['purple'];
    if (day.day == 22) return ['purple', 'blue'];
    if (day.day == 25) return ['blue'];
    if (day.day == 30) return ['purple'];
    return [];
  }

  String _formatSelectedDate() {
    final date = _selectedDay ?? _focusedDay;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(date.year, date.month, date.day);

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    final dateString = '${months[date.month - 1]} ${date.day}, ${date.year}';

    if (selectedDate == today) {
      return 'Today - $dateString';
    } else if (selectedDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday - $dateString';
    } else if (selectedDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow - $dateString';
    } else {
      final weekdayName = weekdays[date.weekday - 1];
      return '$weekdayName - $dateString';
    }
  }

  List<Map<String, dynamic>> _getEventsDetailsForDay(DateTime day) {
    if (day.day == 15)
      return [
        {
          'day': '15',
          'weekday': 'TUE',
          'title': '"Nothing Mends Inside" Premiere',
          'subtitle': 'Screening • Beirut',
          'time': '7:00 PM',
          'isBooked': true
        }
      ];
    if (day.day == 18)
      return [
        {
          'day': '18',
          'weekday': 'FRI',
          'title': 'Documentary Filmmaking 101',
          'subtitle': 'Workshop • Online',
          'time': '3:00 PM',
          'isBooked': false
        }
      ];
    if (day.day == 22)
      return [
        {
          'day': '22',
          'weekday': 'TUE',
          'title': 'Voices of Displacement Panel',
          'subtitle': 'Panel • Berlin',
          'time': '6:30 PM',
          'isBooked': false
        }
      ];
    if (day.day == 25)
      return [
        {
          'day': '25',
          'weekday': 'FRI',
          'title': 'Community Screening Night',
          'subtitle': 'Screening • Amman',
          'time': '8:00 PM',
          'isBooked': false
        }
      ];
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.white, size: 24.w),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Events',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.view_list_outlined,
                color: AppColors.textMuted, size: 24.w),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar
            TableCalendar(
              firstDay: DateTime.utc(2020, 10, 16),
              lastDay: DateTime.utc(2030, 3, 14),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                    color: AppColors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold),
                leftChevronIcon:
                    Icon(Icons.chevron_left, color: AppColors.textMuted),
                rightChevronIcon:
                    Icon(Icons.chevron_right, color: AppColors.textMuted),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle:
                    TextStyle(color: AppColors.textMuted, fontSize: 12.sp),
                weekendStyle:
                    TextStyle(color: AppColors.textMuted, fontSize: 12.sp),
              ),
              calendarStyle: CalendarStyle(
                defaultTextStyle:
                    TextStyle(color: AppColors.textMuted, fontSize: 14.sp),
                weekendTextStyle:
                    TextStyle(color: AppColors.textMuted, fontSize: 14.sp),
                outsideTextStyle:
                    TextStyle(color: AppColors.surface, fontSize: 14.sp),
                selectedDecoration: BoxDecoration(
                  color: AppColors.mainBlue.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: TextStyle(
                    color: AppColors.mainBlue,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold),
                todayDecoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                todayTextStyle:
                    TextStyle(color: AppColors.white, fontSize: 14.sp),
              ),
              eventLoader: _getEventsForDay,
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return const SizedBox();
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(bottom: 6.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: events.map((e) {
                          final color = e == 'blue'
                              ? AppColors.mainBlue
                              : AppColors.mainPurple;
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 1.5.w),
                            width: 4.w,
                            height: 4.w,
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                }
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),

            SizedBox(height: 24.h),

            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: AppDimensions.pagePadding.w),
              child: Row(
                children: [
                  Text(
                    _formatSelectedDate(),
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      _getEventsDetailsForDay(_selectedDay ?? _focusedDay)
                          .length
                          .toString(),
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Events List
            Builder(
              builder: (context) {
                final events =
                    _getEventsDetailsForDay(_selectedDay ?? _focusedDay);

                if (events.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.pagePadding.w,
                        vertical: 32.h),
                    child: Center(
                      child: Text(
                        'There are no events this day.',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 14.sp),
                      ),
                    ),
                  );
                }

                return Column(
                  children: events
                      .map((event) => _buildEventCard(
                            event['day'],
                            event['weekday'],
                            event['title'],
                            event['subtitle'],
                            event['time'],
                            event['isBooked'],
                          ))
                      .toList(),
                );
              },
            ),

            SizedBox(height: 100.h), // Bottom padding for FAB/Nav
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(String day, String weekday, String title,
      String subtitle, String time, bool isBooked) {
    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: AppDimensions.pagePadding.w, vertical: 6.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          // Date Box
          Column(
            children: [
              Text(
                'JUL',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                day,
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                weekday,
                style: TextStyle(color: AppColors.textMuted, fontSize: 10.sp),
              ),
            ],
          ),

          SizedBox(width: 24.w),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12.sp),
                ),
                SizedBox(height: 4.h),
                Text(
                  time,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12.sp),
                ),
              ],
            ),
          ),

          // Action (RSVP / Check)
          if (isBooked)
            Icon(Icons.check_circle_outline,
                color: AppColors.mainBlue, size: 24.w)
          else
            Text(
              'RSVP',
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600),
            )
        ],
      ),
    );
  }
}
