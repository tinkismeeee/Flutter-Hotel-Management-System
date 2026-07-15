import 'package:flutter/material.dart';

import '../../models/daily_revenue_report.dart';
import '../../models/invoice.dart';
import '../../services/revenue_report_service.dart';
import '../../utils/app_colors.dart';
import '../revenue/invoice_detail_screen.dart';
import '../widgets/list_query_bar.dart';

class DailyRevenueScreen extends StatefulWidget {
  const DailyRevenueScreen({super.key});

  @override
  State<DailyRevenueScreen> createState() => _DailyRevenueScreenState();
}

class _DailyRevenueScreenState extends State<DailyRevenueScreen> {
  late Future<DailyRevenueReport> reportFuture;
  DateTime selectedStartDate = DateTime.now();
  DateTime selectedEndDate = DateTime.now();
  String searchQuery = '';
  String sortBy = 'date_desc';
  String paymentFilter = 'all';

  @override
  void initState() {
    super.initState();
    reportFuture = RevenueReportService.getRevenueRange(
      selectedStartDate,
      selectedEndDate,
    );
  }

  void refreshData() {
    setState(() {
      reportFuture = RevenueReportService.getRevenueRange(
        selectedStartDate,
        selectedEndDate,
      );
    });
  }

  Future<void> pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: selectedStartDate,
        end: selectedEndDate,
      ),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: datePickerTheme,
    );

    if (range != null) {
      setState(() {
        selectedStartDate = DateTime(
          range.start.year,
          range.start.month,
          range.start.day,
        );
        selectedEndDate = DateTime(
          range.end.year,
          range.end.month,
          range.end.day,
        );
        reportFuture = RevenueReportService.getRevenueRange(
          selectedStartDate,
          selectedEndDate,
        );
      });
    }
  }

  String shortDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String dateRangeLabel() {
    final sameDay =
        selectedStartDate.year == selectedEndDate.year &&
        selectedStartDate.month == selectedEndDate.month &&
        selectedStartDate.day == selectedEndDate.day;

    if (sameDay) return shortDate(selectedStartDate);

    return '${shortDate(selectedStartDate)} - ${shortDate(selectedEndDate)}';
  }

  Widget datePickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: AppColors.navy,
          onPrimary: Colors.white,
          secondary: AppColors.gold,
          onSecondary: AppColors.navy,
          surface: Colors.white,
          onSurface: AppColors.textDark,
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: Colors.white,
          headerBackgroundColor: AppColors.navy,
          headerForegroundColor: Colors.white,
          rangePickerBackgroundColor: Colors.white,
          rangePickerHeaderBackgroundColor: AppColors.navy,
          rangePickerHeaderForegroundColor: Colors.white,
          rangePickerHeaderHelpStyle: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
          rangePickerHeaderHeadlineStyle: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          dayForegroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            if (states.contains(WidgetState.disabled)) {
              return AppColors.textGray.withValues(alpha: 0.45);
            }
            return AppColors.textDark;
          }),
          dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.navy;
            }
            return null;
          }),
          todayForegroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return AppColors.navy;
          }),
          todayBorder: const BorderSide(color: AppColors.gold, width: 2),
          rangeSelectionBackgroundColor: AppColors.gold.withValues(alpha: 0.20),
          rangeSelectionOverlayColor: WidgetStateProperty.all(
            AppColors.gold.withValues(alpha: 0.12),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.navy),
        ),
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }

  List<DateTime> datesInRange() {
    final dates = <DateTime>[];
    var current = DateTime(
      selectedStartDate.year,
      selectedStartDate.month,
      selectedStartDate.day,
    );
    final end = DateTime(
      selectedEndDate.year,
      selectedEndDate.month,
      selectedEndDate.day,
    );

    while (!current.isAfter(end)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }

    return dates;
  }

  List<Invoice> invoicesForDate(List<Invoice> invoices, DateTime date) {
    return invoices.where((invoice) {
      final invoiceDate = invoice.date;
      return invoiceDate.year == date.year &&
          invoiceDate.month == date.month &&
          invoiceDate.day == date.day;
    }).toList();
  }

  List<Invoice> applyInvoiceQuery(List<Invoice> invoices) {
    final query = searchQuery.trim().toLowerCase();
    final result = invoices.where((invoice) {
      final matchesSearch =
          query.isEmpty ||
          invoice.invoiceId.toString().contains(query) ||
          invoice.bookingId.toString().contains(query) ||
          invoice.staffId.toString().contains(query) ||
          invoice.paymentMethod.toLowerCase().contains(query);
      final matchesPayment =
          paymentFilter == 'all' ||
          invoice.paymentStatus.toLowerCase() == paymentFilter;
      return matchesSearch && matchesPayment;
    }).toList();

    result.sort((a, b) {
      if (sortBy == 'date_asc') return a.date.compareTo(b.date);
      if (sortBy == 'amount_high') {
        return b.finalAmount.compareTo(a.finalAmount);
      }
      if (sortBy == 'amount_low') {
        return a.finalAmount.compareTo(b.finalAmount);
      }
      return b.date.compareTo(a.date);
    });
    return result;
  }

  void openInvoice(Invoice invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoice: invoice)),
    );
  }

  String money(double value) {
    final raw = value.round().toString();
    final formatted = raw.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );

    return '$formatted VNĐ';
  }

  String compactMoney(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    }

    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }

    return value.toStringAsFixed(0);
  }

  Widget header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          ),
          const Expanded(
            child: Text(
              'Doanh thu',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: refreshData,
            icon: const Icon(Icons.refresh, color: AppColors.gold),
          ),
        ],
      ),
    );
  }

  Widget dateSelector(DailyRevenueReport report) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateRangeLabel(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Chọn khoảng ngày để tổng hợp doanh thu',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: pickDateRange,
            icon: const Icon(Icons.edit_calendar_rounded, size: 18),
            label: const Text('Chọn'),
            style: TextButton.styleFrom(foregroundColor: AppColors.gold),
          ),
        ],
      ),
    );
  }

  Widget kpiCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.gold),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textGray,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget kpiGrid(DailyRevenueReport report) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.55,
      children: [
        kpiCard(
          title: 'Tổng doanh thu',
          value: compactMoney(report.totalRevenue),
          icon: Icons.payments_rounded,
        ),
        kpiCard(
          title: 'Số hóa đơn',
          value: report.invoiceCount.toString(),
          icon: Icons.receipt_long_rounded,
        ),
        kpiCard(
          title: 'Doanh thu phòng',
          value: compactMoney(report.roomRevenue),
          icon: Icons.bed_rounded,
        ),
        kpiCard(
          title: 'Dịch vụ',
          value: compactMoney(report.serviceRevenue),
          icon: Icons.room_service_rounded,
        ),
        kpiCard(
          title: 'VAT',
          value: compactMoney(report.vatAmount),
          icon: Icons.account_balance_rounded,
        ),
        kpiCard(
          title: 'Giảm giá',
          value: compactMoney(report.discountAmount),
          icon: Icons.discount_rounded,
        ),
      ],
    );
  }

  Widget revenueBreakdown(DailyRevenueReport report) {
    final subtotal = report.roomRevenue + report.serviceRevenue;
    final roomPercent = subtotal == 0 ? 0.0 : report.roomRevenue / subtotal;
    final servicePercent = subtotal == 0
        ? 0.0
        : report.serviceRevenue / subtotal;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cơ cấu doanh thu',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          breakdownRow(
            title: 'Phòng',
            value: report.roomRevenue,
            percent: roomPercent,
            color: const Color(0xFF0F8BFF),
          ),
          const SizedBox(height: 14),
          breakdownRow(
            title: 'Dịch vụ',
            value: report.serviceRevenue,
            percent: servicePercent,
            color: const Color(0xFF11C5A8),
          ),
        ],
      ),
    );
  }

  Widget breakdownRow({
    required String title,
    required double value,
    required double percent,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              money(value),
              style: const TextStyle(
                color: AppColors.textGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 10,
            color: color,
            backgroundColor: AppColors.background,
          ),
        ),
      ],
    );
  }

  Widget dailyRevenueList(DailyRevenueReport report) {
    final dates = datesInRange();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Doanh thu theo từng ngày',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          ...dates.map((date) {
            final invoices = invoicesForDate(report.invoices, date);
            final total = invoices.fold(0.0, (sum, e) => sum + e.finalAmount);

            return dailyRevenueRow(
              date: date,
              invoiceCount: invoices.length,
              totalRevenue: total,
            );
          }),
        ],
      ),
    );
  }

  Widget dailyRevenueRow({
    required DateTime date,
    required int invoiceCount,
    required double totalRevenue,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.event_note_rounded, color: AppColors.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shortDate(date),
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$invoiceCount hóa đơn',
                  style: const TextStyle(color: AppColors.textGray),
                ),
              ],
            ),
          ),
          Text(
            compactMoney(totalRevenue),
            style: const TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget invoiceList(List<Invoice> invoices) {
    if (invoices.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Text(
          'Không có hóa đơn trong khoảng ngày',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textGray,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final filtered = applyInvoiceQuery(invoices);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hóa đơn trong khoảng ngày',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ListQueryBar(
          searchHint: 'Tìm hóa đơn, booking, nhân viên...',
          onSearchChanged: (value) => setState(() => searchQuery = value),
          sortValue: sortBy,
          sortOptions: const {
            'date_desc': 'Ngày mới nhất',
            'date_asc': 'Ngày cũ nhất',
            'amount_high': 'Giá trị cao nhất',
            'amount_low': 'Giá trị thấp nhất',
          },
          onSortChanged: (value) =>
              setState(() => sortBy = value ?? 'date_desc'),
          filterValue: paymentFilter,
          filterOptions: const {
            'all': 'Tất cả thanh toán',
            'paid': 'Đã thanh toán',
            'pending': 'Chờ thanh toán',
            'failed': 'Thanh toán lỗi',
            'refunded': 'Đã hoàn tiền',
          },
          onFilterChanged: (value) =>
              setState(() => paymentFilter = value ?? 'all'),
          resultCount: filtered.length,
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          const Text(
            'Không có hóa đơn phù hợp',
            style: TextStyle(color: AppColors.textGray),
          )
        else
          ...filtered.map(invoiceCard),
      ],
    );
  }

  Widget invoiceCard(Invoice invoice) {
    return InkWell(
      key: ValueKey('daily-invoice-${invoice.invoiceId}'),
      onTap: () => openInvoice(invoice),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.gold.withValues(alpha: 0.18),
              child: const Icon(Icons.receipt_rounded, color: AppColors.gold),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hóa đơn #${invoice.invoiceId}',
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Ngày: ${shortDate(invoice.date)}',
                    style: const TextStyle(color: AppColors.textGray),
                  ),
                  Text(
                    'Booking: ${invoice.bookingId} • Staff: ${invoice.staffId}',
                    style: const TextStyle(color: AppColors.textGray),
                  ),
                  Text(
                    invoice.paymentStatus.isEmpty
                        ? invoice.paymentMethod
                        : '${invoice.paymentStatus} • ${invoice.paymentMethod}',
                    style: const TextStyle(color: AppColors.textGray),
                  ),
                ],
              ),
            ),
            Text(
              compactMoney(invoice.finalAmount),
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: AppColors.gold),
          ],
        ),
      ),
    );
  }

  Widget content(DailyRevenueReport report) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        dateSelector(report),
        const SizedBox(height: 20),
        kpiGrid(report),
        const SizedBox(height: 20),
        revenueBreakdown(report),
        const SizedBox(height: 20),
        dailyRevenueList(report),
        const SizedBox(height: 20),
        invoiceList(report.invoices),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            header(),
            Expanded(
              child: FutureBuilder<DailyRevenueReport>(
                future: reportFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Lỗi: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textDark),
                        ),
                      ),
                    );
                  }

                  final report =
                      snapshot.data ??
                      DailyRevenueReport.fromInvoices(
                        selectedStartDate,
                        const [],
                      );

                  return content(report);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
