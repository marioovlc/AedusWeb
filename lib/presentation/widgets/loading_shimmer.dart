import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1C2D47) : const Color(0xFFE2E8F0),
      highlightColor: isDark ? const Color(0xFF2A3F5F) : const Color(0xFFF8FAFC),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: appColors.card,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Shimmer para las tarjetas KPI del Dashboard (4 seguidas)
class ShimmerKPIRow extends StatelessWidget {
  final bool isMobile;
  const ShimmerKPIRow({super.key, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget card = Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1C2D47) : const Color(0xFFE2E8F0),
      highlightColor: isDark ? const Color(0xFF2A3F5F) : const Color(0xFFF8FAFC),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: appColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: appColors.border),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: appColors.surface, borderRadius: BorderRadius.circular(12))),
            const Spacer(),
            Container(width: 60, height: 22, color: appColors.surface),
            const SizedBox(height: 6),
            Container(width: 100, height: 12, color: appColors.surface),
          ],
        ),
      ),
    );

    if (isMobile) {
      return Column(
        children: [
          Row(children: [Expanded(child: card), const SizedBox(width: 12), Expanded(child: card)]),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: card), const SizedBox(width: 12), Expanded(child: card)]),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: card), const SizedBox(width: 20),
        Expanded(child: card), const SizedBox(width: 20),
        Expanded(child: card), const SizedBox(width: 20),
        Expanded(child: card),
      ],
    );
  }
}

/// Shimmer para la grid de artículos de la Tienda
class ShimmerStoreGrid extends StatelessWidget {
  final int crossAxisCount;
  const ShimmerStoreGrid({super.key, this.crossAxisCount = 3});

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget storeCard = Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1C2D47) : const Color(0xFFE2E8F0),
      highlightColor: isDark ? const Color(0xFF2A3F5F) : const Color(0xFFF8FAFC),
      child: Container(
        decoration: BoxDecoration(
          color: appColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: appColors.border),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 52, height: 52, decoration: BoxDecoration(color: appColors.surface, borderRadius: BorderRadius.circular(12))),
            const SizedBox(height: 20),
            Container(width: 120, height: 16, color: appColors.surface),
            const SizedBox(height: 8),
            Container(width: double.infinity, height: 12, color: appColors.surface),
            const SizedBox(height: 6),
            Container(width: 160, height: 12, color: appColors.surface),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 50, height: 18, color: appColors.surface),
                Container(width: 70, height: 34, decoration: BoxDecoration(color: appColors.surface, borderRadius: BorderRadius.circular(8))),
              ],
            ),
          ],
        ),
      ),
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 1.2,
      ),
      itemCount: crossAxisCount * 2,
      itemBuilder: (context, index) => storeCard,
    );
  }
}

/// Shimmer para un bloque de gráfico/card genérico
class ShimmerChartCard extends StatelessWidget {
  final double height;
  const ShimmerChartCard({super.key, this.height = 380});

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1C2D47) : const Color(0xFFE2E8F0),
      highlightColor: isDark ? const Color(0xFF2A3F5F) : const Color(0xFFF8FAFC),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: appColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: appColors.border),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 200, height: 18, color: appColors.surface),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: appColors.surface, borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer para la lista de tickets en IncidenciasPage
class ShimmerTicketList extends StatelessWidget {
  const ShimmerTicketList({super.key});

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget ticketCard = Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1C2D47) : const Color(0xFFE2E8F0),
      highlightColor: isDark ? const Color(0xFF2A3F5F) : const Color(0xFFF8FAFC),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 100,
        decoration: BoxDecoration(
          color: appColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: appColors.border),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: appColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 150, height: 16, color: appColors.surface),
                  const SizedBox(height: 8),
                  Container(width: double.infinity, height: 12, color: appColors.surface),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(width: 80, height: 12, color: appColors.surface),
                      const SizedBox(width: 20),
                      Container(width: 60, height: 12, color: appColors.surface),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) => ticketCard,
    );
  }
}

/// Shimmer para la tabla de usuarios en UsuariosPage
class ShimmerUserTable extends StatelessWidget {
  const ShimmerUserTable({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget shimmerRow = Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1C2D47) : const Color(0xFFE2E8F0),
      highlightColor: isDark ? const Color(0xFF2A3F5F) : const Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          children: [
            Container(width: 28, height: 28, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Container(width: 100, height: 16, color: Colors.white),
            const Spacer(),
            Container(width: 150, height: 16, color: Colors.white),
            const Spacer(),
            Container(width: 80, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
            const Spacer(),
            Container(width: 60, height: 16, color: Colors.white),
            const Spacer(),
            Container(width: 80, height: 32, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
          ],
        ),
      ),
    );

    return Column(
      children: List.generate(8, (index) => Column(
        children: [
          shimmerRow,
          const Divider(),
        ],
      )),
    );
  }
}

