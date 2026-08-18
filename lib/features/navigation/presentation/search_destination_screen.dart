import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/mock/mock_destinations.dart';
import '../../../data/models/destination.dart';
import '../application/navigation_controller.dart';

class SearchDestinationScreen extends ConsumerStatefulWidget {
  const SearchDestinationScreen({super.key});
  @override
  ConsumerState<SearchDestinationScreen> createState() =>
      _SearchDestinationScreenState();
}

class _SearchDestinationScreenState
    extends ConsumerState<SearchDestinationScreen> {
  String query = '';
  Destination? selected;

  @override
  Widget build(BuildContext context) {
    final items = mockDestinations
        .where((item) => '${item.name} ${item.address}'
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  sliver: SliverToBoxAdapter(
                      child: _Header(
                          queryChanged: (value) =>
                              setState(() => query = value))),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: Row(children: [
                      const Text('Pilihan tujuan',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Text('${items.length} lokasi',
                          style: const TextStyle(color: AppTheme.muted)),
                    ]),
                  ),
                ),
                if (items.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                        child: Text(
                            'Tujuan tidak ditemukan.\nCoba kata kunci lain.',
                            textAlign: TextAlign.center)),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                    sliver: SliverList.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final destination = items[index];
                        return _DestinationTile(
                          destination: destination,
                          selected: selected?.id == destination.id,
                          onTap: () => setState(() => selected = destination),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: AnimatedSize(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        child: selected == null
            ? const SizedBox.shrink()
            : SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE5ECF5))),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: FilledButton.icon(
                        onPressed: () async {
                          await ref
                              .read(navigationProvider.notifier)
                              .selectDestination(selected!);
                          ref.read(navigationProvider.notifier).start();
                          if (context.mounted) context.go('/navigation');
                        },
                        icon: const Icon(LucideIcons.navigation, size: 19),
                        label: const Text('Mulai navigasi'),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.queryChanged});
  final ValueChanged<String> queryChanged;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppTheme.deepBlue, AppTheme.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
                color: Color(0x331769E0), blurRadius: 28, offset: Offset(0, 14))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(14)),
              child: const Icon(LucideIcons.footprints,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 11),
            const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LANGKAH',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                          fontSize: 12)),
                  Text('Sahabat perjalananmu',
                      style: TextStyle(color: Color(0xFFCFE3FF), fontSize: 12)),
                ]),
          ]),
          const SizedBox(height: 28),
          const Text('Mau ke mana?',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  height: 1.05,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1)),
          const SizedBox(height: 7),
          const Text('Navigasi yang lebih aman, jelas, dan personal.',
              style: TextStyle(color: Color(0xFFD9E9FF), fontSize: 15)),
          const SizedBox(height: 20),
          TextField(
            onChanged: queryChanged,
            decoration: const InputDecoration(
              prefixIcon:
                  Icon(LucideIcons.search, color: AppTheme.primary, size: 20),
              hintText: 'Cari tujuan atau landmark',
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Lokasi saat ini digunakan sebagai titik awal.'))),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                Icon(LucideIcons.locateFixed, color: Colors.white, size: 18),
                SizedBox(width: 9),
                Text('Gunakan lokasi saat ini',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                Spacer(),
                Icon(LucideIcons.chevronRight, color: Colors.white, size: 18),
              ]),
            ),
          ),
        ]),
      );
}

class _DestinationTile extends StatelessWidget {
  const _DestinationTile(
      {required this.destination, required this.selected, required this.onTap});
  final Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFECF4FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppTheme.primary : const Color(0xFFE5ECF5),
              width: selected ? 1.5 : 1),
          boxShadow: selected
              ? const [
                  BoxShadow(
                      color: Color(0x181769E0),
                      blurRadius: 18,
                      offset: Offset(0, 8))
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            onTap: onTap,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            leading: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(15)),
              child: Icon(LucideIcons.mapPin,
                  color: selected ? Colors.white : AppTheme.primary, size: 21),
            ),
            title: Text(destination.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppTheme.ink)),
            subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(destination.address)),
            trailing: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: selected
                  ? const Icon(LucideIcons.circleCheck,
                      key: ValueKey(true), color: AppTheme.primary)
                  : const Icon(LucideIcons.chevronRight,
                      key: ValueKey(false), color: AppTheme.muted, size: 20),
            ),
          ),
        ),
      );
}
