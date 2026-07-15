import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/invoice.dart';
import '../../services/invoice_service.dart';
import '../../utils/app_colors.dart';
import '../widgets/list_query_bar.dart';
import 'invoice_detail_screen.dart';

enum RevenueFilterType { all, day, month, year }

class RevenueDashboardScreen extends StatefulWidget {
  const RevenueDashboardScreen({super.key});

  @override
  State<RevenueDashboardScreen> createState() => _RevenueDashboardScreenState();
}

class _RevenueDashboardScreenState extends State<RevenueDashboardScreen> {
  late Future<List<Invoice>> invoiceFuture;

  RevenueFilterType filterType = RevenueFilterType.all;
  DateTime? selectedDate;
  int? selectedMonth;
  int? selectedYear;
  String searchQuery = '';
  String sortBy = 'date_desc';
  String paymentFilter = 'all';

  @override
  void initState() {
    super.initState();
    invoiceFuture = InvoiceService.getInvoices();
  }

  void refreshData() {
    setState(() {
      invoiceFuture = InvoiceService.getInvoices();
    });
  }

  List<Invoice> applyFilter(List<Invoice> invoices) {
    if (filterType == RevenueFilterType.all) return invoices;

    if (filterType == RevenueFilterType.day && selectedDate != null) {
      return invoices.where((e) {
        final d = e.date;
        return d.year == selectedDate!.year &&
            d.month == selectedDate!.month &&
            d.day == selectedDate!.day;
      }).toList();
    }

    if (filterType == RevenueFilterType.month &&
        selectedMonth != null &&
        selectedYear != null) {
      return invoices.where((e) {
        final d = e.date;
        return d.year == selectedYear && d.month == selectedMonth;
      }).toList();
    }

    if (filterType == RevenueFilterType.year && selectedYear != null) {
      return invoices.where((e) => e.date.year == selectedYear).toList();
    }

    return invoices;
  }

  List<Invoice> applyInvoiceQuery(List<Invoice> invoices) {
    final query = searchQuery.trim().toLowerCase();
    final result = invoices.where((invoice) {
      final matchesSearch =
          query.isEmpty ||
          invoice.invoiceId.toString().contains(query) ||
          invoice.bookingId.toString().contains(query) ||
          invoice.staffId.toString().contains(query) ||
          invoice.paymentMethod.toLowerCase().contains(query) ||
          invoice.paymentStatus.toLowerCase().contains(query);
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

  double totalRevenue(List<Invoice> invoices) {
    return invoices.fold(0, (sum, e) => sum + e.finalAmount);
  }

  double totalRoomRevenue(List<Invoice> invoices) {
    return invoices.fold(0, (sum, e) => sum + e.totalRoomCost);
  }

  double totalServiceRevenue(List<Invoice> invoices) {
    return invoices.fold(0, (sum, e) => sum + e.totalServiceCost);
  }

  double totalVat(List<Invoice> invoices) {
    return invoices.fold(0, (sum, e) => sum + e.vatAmount);
  }

  double totalDiscount(List<Invoice> invoices) {
    return invoices.fold(0, (sum, e) => sum + e.discountAmount);
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

  String shortDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String filterLabel() {
    if (filterType == RevenueFilterType.all) return 'Tất cả hóa đơn';

    if (filterType == RevenueFilterType.day && selectedDate != null) {
      return 'Ngày ${shortDate(selectedDate!)}';
    }

    if (filterType == RevenueFilterType.month &&
        selectedMonth != null &&
        selectedYear != null) {
      return 'Tháng $selectedMonth/$selectedYear';
    }

    if (filterType == RevenueFilterType.year && selectedYear != null) {
      return 'Năm $selectedYear';
    }

    return 'Tất cả hóa đơn';
  }

  Map<int, double> revenueByMonth(List<Invoice> invoices) {
    final Map<int, double> result = {};

    for (int i = 1; i <= 12; i++) {
      result[i] = 0;
    }

    for (final invoice in invoices) {
      final month = invoice.date.month;
      result[month] = (result[month] ?? 0) + invoice.finalAmount;
    }

    return result;
  }

  Future<void> pickDay() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (date != null) {
      setState(() {
        filterType = RevenueFilterType.day;
        selectedDate = date;
        selectedMonth = null;
        selectedYear = null;
      });
    }
  }

  void pickMonth() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        final now = DateTime.now();
        int tempMonth = selectedMonth ?? now.month;
        int tempYear = selectedYear ?? now.year;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: 280,
              child: Column(
                children: [
                  const Text(
                    'Chọn tháng',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  DropdownButton<int>(
                    value: tempMonth,
                    isExpanded: true,
                    items: List.generate(
                      12,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('Tháng ${index + 1}'),
                      ),
                    ),
                    onChanged: (value) {
                      setModalState(() {
                        tempMonth = value ?? 1;
                      });
                    },
                  ),
                  DropdownButton<int>(
                    value: tempYear,
                    isExpanded: true,
                    items: List.generate(10, (index) {
                      final year = 2024 + index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text('Năm $year'),
                      );
                    }),
                    onChanged: (value) {
                      setModalState(() {
                        tempYear = value ?? 2026;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        filterType = RevenueFilterType.month;
                        selectedMonth = tempMonth;
                        selectedYear = tempYear;
                        selectedDate = null;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Áp dụng'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void pickYear() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        int tempYear = selectedYear ?? DateTime.now().year;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: 220,
              child: Column(
                children: [
                  const Text(
                    'Chọn năm',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  DropdownButton<int>(
                    value: tempYear,
                    isExpanded: true,
                    items: List.generate(10, (index) {
                      final year = 2024 + index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text('Năm $year'),
                      );
                    }),
                    onChanged: (value) {
                      setModalState(() {
                        tempYear = value ?? 2026;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        filterType = RevenueFilterType.year;
                        selectedYear = tempYear;
                        selectedMonth = null;
                        selectedDate = null;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Áp dụng'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void clearFilter() {
    setState(() {
      filterType = RevenueFilterType.all;
      selectedDate = null;
      selectedMonth = null;
      selectedYear = null;
    });
  }

  Widget header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
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
                fontSize: 26,
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

  Widget filterButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 92,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.gold, size: 26),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget filterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bộ lọc doanh thu',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            filterButton(
              title: 'Ngày',
              icon: Icons.today_rounded,
              onTap: pickDay,
            ),
            const SizedBox(width: 10),
            filterButton(
              title: 'Tháng',
              icon: Icons.calendar_month_rounded,
              onTap: pickMonth,
            ),
            const SizedBox(width: 10),
            filterButton(
              title: 'Năm',
              icon: Icons.date_range_rounded,
              onTap: pickYear,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              const Icon(Icons.filter_alt_rounded, color: AppColors.gold),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  filterLabel(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              InkWell(
                onTap: clearFilter,
                child: const Text(
                  'Xóa lọc',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget kpiCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: AppColors.gold, size: 28),
          ),
          const SizedBox(width: 12),
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
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    unit,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 13,
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

  Widget kpiGrid(List<Invoice> invoices) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.7,
      children: [
        kpiCard(
          title: 'Tổng doanh thu',
          value: compactMoney(totalRevenue(invoices)),
          unit: 'VNĐ',
          icon: Icons.payments_rounded,
        ),
        kpiCard(
          title: 'Số hóa đơn',
          value: invoices.length.toString(),
          unit: 'hóa đơn',
          icon: Icons.receipt_long_rounded,
        ),
        kpiCard(
          title: 'VAT',
          value: compactMoney(totalVat(invoices)),
          unit: 'VNĐ',
          icon: Icons.account_balance_rounded,
        ),
        kpiCard(
          title: 'Giảm giá',
          value: compactMoney(totalDiscount(invoices)),
          unit: 'VNĐ',
          icon: Icons.discount_rounded,
        ),
      ],
    );
  }

  Widget barChart(List<Invoice> invoices) {
    final data = revenueByMonth(invoices);

    final maxY = data.values.isEmpty
        ? 100
        : data.values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(18),
      height: 320,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Doanh thu theo tháng',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxY == 0 ? 100 : maxY * 1.25,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY == 0 ? 20 : maxY / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withValues(alpha: 0.25),
                      strokeWidth: 1,
                      dashArray: [6, 4],
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: maxY == 0 ? 20 : maxY / 4,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          compactMoney(value),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textGray,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final month = value.toInt();

                        if (month < 1 || month > 12) {
                          return const SizedBox();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'T$month',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textGray,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(12, (index) {
                  final month = index + 1;
                  final value = data[month] ?? 0;

                  return BarChartGroupData(
                    x: month,
                    barRods: [
                      BarChartRodData(
                        toY: value,
                        width: 13,
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFF13BFD6),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget pieChart(List<Invoice> invoices) {
    final roomRevenue = totalRoomRevenue(invoices);
    final serviceRevenue = totalServiceRevenue(invoices);
    final total = roomRevenue + serviceRevenue;

    final roomPercent = total == 0 ? 0 : (roomRevenue / total) * 100;
    final servicePercent = total == 0 ? 0 : (serviceRevenue / total) * 100;

    return Container(
      padding: const EdgeInsets.all(18),
      height: 300,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
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
          const SizedBox(height: 18),
          Expanded(
            child: total == 0
                ? const Center(
                    child: Text(
                      'Không có dữ liệu',
                      style: TextStyle(color: AppColors.textGray),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            centerSpaceRadius: 34,
                            sectionsSpace: 2,
                            sections: [
                              PieChartSectionData(
                                value: roomRevenue,
                                title: '${roomPercent.toStringAsFixed(0)}%',
                                radius: 58,
                                color: const Color(0xFF0F8BFF),
                              ),
                              PieChartSectionData(
                                value: serviceRevenue,
                                title: '${servicePercent.toStringAsFixed(0)}%',
                                radius: 58,
                                color: const Color(0xFF11C5A8),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            legendItem(
                              color: const Color(0xFF0F8BFF),
                              title: 'Doanh thu phòng',
                              value:
                                  '${compactMoney(roomRevenue)} (${roomPercent.toStringAsFixed(0)}%)',
                            ),
                            const SizedBox(height: 16),
                            legendItem(
                              color: const Color(0xFF11C5A8),
                              title: 'Doanh thu dịch vụ',
                              value:
                                  '${compactMoney(serviceRevenue)} (${servicePercent.toStringAsFixed(0)}%)',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget legendItem({
    required Color color,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        CircleAvatar(radius: 6, backgroundColor: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$title\n$value',
            style: const TextStyle(color: AppColors.textGray, height: 1.35),
          ),
        ),
      ],
    );
  }

  Widget invoiceList(List<Invoice> invoices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Danh sách hóa đơn',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...invoices.map((invoice) {
          return InkWell(
            key: ValueKey('invoice-${invoice.invoiceId}'),
            onTap: () => openInvoice(invoice),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.gold.withValues(alpha: 0.18),
                    child: const Icon(
                      Icons.receipt_rounded,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invoice #${invoice.invoiceId}',
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Booking: ${invoice.bookingId} • Staff: ${invoice.staffId}',
                          style: const TextStyle(color: AppColors.textGray),
                        ),
                        Text(
                          'Ngày: ${invoice.issueDate.length >= 10 ? invoice.issueDate.substring(0, 10) : invoice.issueDate}',
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
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.gold,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget dashboardContent(List<Invoice> invoices) {
    final filtered = applyInvoiceQuery(applyFilter(invoices));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        filterSection(),
        const SizedBox(height: 16),
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
        const SizedBox(height: 22),
        kpiGrid(filtered),
        const SizedBox(height: 22),
        barChart(filtered),
        const SizedBox(height: 22),
        pieChart(filtered),
        const SizedBox(height: 22),
        invoiceList(filtered),
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
              child: FutureBuilder<List<Invoice>>(
                future: invoiceFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Lỗi: ${snapshot.error}',
                        style: const TextStyle(color: AppColors.textDark),
                      ),
                    );
                  }

                  final invoices = snapshot.data ?? [];

                  if (invoices.isEmpty) {
                    return const Center(
                      child: Text(
                        'Không có hóa đơn',
                        style: TextStyle(color: AppColors.textDark),
                      ),
                    );
                  }

                  return dashboardContent(invoices);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
