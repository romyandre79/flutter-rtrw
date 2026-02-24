import 'package:flutter_pos/data/database/database_helper.dart';
import 'package:flutter_pos/logic/cubits/report/report_state.dart';

class ReportRepository {
  final DatabaseHelper _databaseHelper;

  ReportRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  /// Get report data for date range
  Future<ReportData> getReportData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _databaseHelper.database;

    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final summaryResult = await db.rawQuery('''
      SELECT
        COUNT(*) as total_orders,
        SUM(total_price) as total_revenue
      FROM orders
      WHERE order_date BETWEEN ? AND ?
    ''', [start.toIso8601String(), end.toIso8601String()]);

    final summary = summaryResult.first;
    final totalOrders = (summary['total_orders'] as int?) ?? 0;
    final totalRevenue = (summary['total_revenue'] as int?) ?? 0;

    final paidResult = await db.rawQuery('''
      SELECT
        SUM(amount - COALESCE(change, 0)) as total_paid
      FROM payments
      WHERE payment_date BETWEEN ? AND ?
    ''', [start.toIso8601String(), end.toIso8601String()]);

    final totalPaid = (paidResult.first['total_paid'] as int?) ?? 0;

    final statusResult = await db.rawQuery('''
      SELECT status, COUNT(*) as count
      FROM orders
      WHERE order_date BETWEEN ? AND ?
      GROUP BY status
    ''', [start.toIso8601String(), end.toIso8601String()]);

    final ordersByStatus = <String, int>{};
    int completedOrders = 0;
    int pendingOrders = 0;

    for (final row in statusResult) {
      final status = row['status'] as String;
      final count = row['count'] as int;
      ordersByStatus[status] = count;

      if (status == 'done') {
        completedOrders = count;
      } else {
        pendingOrders += count;
      }
    }

    final dailyOrderResult = await db.rawQuery('''
      SELECT
        DATE(order_date) as date,
        SUM(total_price) as revenue,
        COUNT(*) as order_count
      FROM orders
      WHERE order_date BETWEEN ? AND ?
      GROUP BY DATE(order_date)
      ORDER BY date ASC
    ''', [start.toIso8601String(), end.toIso8601String()]);

    final dailyPaymentResult = await db.rawQuery('''
      SELECT
        DATE(payment_date) as date,
        SUM(amount - COALESCE(change, 0)) as paid
      FROM payments
      WHERE payment_date BETWEEN ? AND ?
      GROUP BY DATE(payment_date)
    ''', [start.toIso8601String(), end.toIso8601String()]);

    final dailyPayments = <String, int>{};
    for (final row in dailyPaymentResult) {
      final date = row['date'] as String;
      dailyPayments[date] = (row['paid'] as int?) ?? 0;
    }

    final dailyDataMap = <String, DailyRevenue>{};

    for (final row in dailyOrderResult) {
      final dateStr = row['date'] as String;
      final revenue = (row['revenue'] as int?) ?? 0;
      dailyDataMap[dateStr] = DailyRevenue(
        date: DateTime.parse(dateStr),
        revenue: revenue,
        orderCount: (row['order_count'] as int?) ?? 0,
        paid: dailyPayments[dateStr] ?? 0,
        profit: revenue,
      );
    }

    for (final entry in dailyPayments.entries) {
      if (!dailyDataMap.containsKey(entry.key)) {
        dailyDataMap[entry.key] = DailyRevenue(
          date: DateTime.parse(entry.key),
          revenue: 0,
          orderCount: 0,
          paid: entry.value,
        );
      }
    }

    final dailyRevenue = dailyDataMap.values.toList();
    dailyRevenue.sort((a, b) => a.date.compareTo(b.date));

    final serviceResult = await db.rawQuery('''
      SELECT
        oi.service_name,
        SUM(oi.quantity) as total_quantity,
        SUM(oi.subtotal) as total_revenue,
        COUNT(DISTINCT oi.order_id) as order_count
      FROM order_items oi
      JOIN orders o ON o.id = oi.order_id
      WHERE o.order_date BETWEEN ? AND ?
      GROUP BY oi.service_name
      ORDER BY total_revenue DESC
      LIMIT 10
    ''', [start.toIso8601String(), end.toIso8601String()]);

    final topServices = serviceResult.map((row) {
      return ServiceSummary(
        serviceName: row['service_name'] as String,
        totalQuantity: ((row['total_quantity'] as num?) ?? 0).toInt(),
        totalRevenue: (row['total_revenue'] as int?) ?? 0,
        orderCount: (row['order_count'] as int?) ?? 0,
      );
    }).toList();

    return ReportData(
      startDate: startDate,
      endDate: endDate,
      totalOrders: totalOrders,
      completedOrders: completedOrders,
      pendingOrders: pendingOrders,
      totalRevenue: totalRevenue,
      totalPaid: totalPaid,
      totalUnpaid: totalRevenue - totalPaid,
      totalProfit: totalRevenue,
      ordersByStatus: ordersByStatus,
      dailyRevenue: dailyRevenue,
      topServices: topServices,
    );
  }

  /// Get today's revenue
  Future<int> getTodayRevenue() async {
    final db = await _databaseHelper.database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final result = await db.rawQuery('''
      SELECT SUM(amount - COALESCE(change, 0)) as total
      FROM payments
      WHERE payment_date BETWEEN ? AND ?
    ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);

    return (result.first['total'] as int?) ?? 0;
  }

  /// Get this month's order count
  Future<int> getThisMonthOrderCount() async {
    final db = await _databaseHelper.database;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM orders
      WHERE order_date BETWEEN ? AND ?
    ''', [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()]);

    return (result.first['count'] as int?) ?? 0;
  }
}
