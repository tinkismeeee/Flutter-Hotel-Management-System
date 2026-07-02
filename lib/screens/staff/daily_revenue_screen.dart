import 'package:flutter/material.dart';

import '../../models/daily_revenue_report.dart';
import '../../models/invoice.dart';
import '../../services/revenue_report_service.dart';
import '../../utils/app_colors.dart';

class DailyRevenueScreen extends StatefulWidget {
  const DailyRevenueScreen({super.key});

  @override
  State<DailyRevenueScreen> createState() => _DailyRevenueScreenState();
}

class _DailyRevenueScreenState extends State<DailyRevenueScreen> {
  late Future<DailyRevenueReport> reportFuture;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    reportFuture = RevenueReportService.getDailyRevenue(selectedDate);
  }

  void refreshData() {
    setState(() {
      reportFuture = RevenueReportService.getDailyRevenue(selectedDate);
    });
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
        reportFuture = RevenueReportService.getDailyRevenue(selectedDate);
      });
    }
  }

  String shortDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
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
              'Doanh thu ngày',
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
                  shortDate(selectedDate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: pickDate,
            icon: const Icon(Icons.edit_calendar_rounded, size: 18),
            label: const Text('Chọn'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.gold,
            ),
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
    final servicePercent =
        subtotal == 0 ? 0.0 : report.serviceRevenue / subtotal;

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
          'Không có hóa đơn trong ngày',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textGray,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hóa đơn trong ngày',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...invoices.map(invoiceCard),
      ],
    );
  }

  Widget invoiceCard(Invoice invoice) {
    return Container(
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
        ],
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

                  final report = snapshot.data ??
                      DailyRevenueReport.fromInvoices(selectedDate, const []);

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
