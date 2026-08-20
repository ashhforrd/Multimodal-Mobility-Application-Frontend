import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/destination.dart';
import '../../../data/models/geo_point.dart';
import '../../../shared/widgets/navigation_map.dart';
import '../application/destination_search_controller.dart';
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
    final navigation = ref.watch(navigationProvider);
    final search = ref.watch(destinationSearchProvider);
    final items = search.results;

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
                      queryChanged: (value) {
                        setState(() {
                          query = value;
                          if (value.trim().isEmpty) selected = null;
                        });
                        if (value.trim().isEmpty) {
                          ref.read(destinationSearchProvider.notifier).clear();
                        }
                      },
                      onSearch: _search,
                      isSearching: search.isSearching,
                      isLoadingLocation: navigation.isLoadingLocation,
                      isUsingCurrentLocation:
                          navigation.currentPosition != null,
                      onUseCurrentLocation: _useCurrentLocation,
                      onSelectFromMap: _openMapPicker,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            search.hasSearched
                                ? 'Hasil pencarian'
                                : 'Cari tujuan nyata',
                            style: const TextStyle(
                              fontSize: 17,
                              letterSpacing: -.34,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          search.isSearching
                              ? 'Mencari…'
                              : '${items.length} lokasi',
                          style: const TextStyle(color: AppTheme.muted),
                        ),
                      ],
                    ),
                  ),
                ),
                if (items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: search.isSearching
                          ? const CircularProgressIndicator()
                          : Padding(
                              padding: const EdgeInsets.all(28),
                              child: Text(
                                search.errorMessage ??
                                    (search.hasSearched
                                        ? 'Tujuan tidak ditemukan.\nCoba kata kunci lain.'
                                        : 'Masukkan nama tempat atau alamat, lalu tekan cari.'),
                                textAlign: TextAlign.center,
                              ),
                            ),
                    ),
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
                    border: Border(
                      top: BorderSide(color: Color(0xFFE5ECF5)),
                    ),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: FilledButton.icon(
                        onPressed: navigation.isLoadingRoute
                            ? null
                            : () async {
                                final success = await ref
                                    .read(navigationProvider.notifier)
                                    .selectDestination(selected!);
                                if (!context.mounted) return;
                                if (success) {
                                  context.push('/preview');
                                } else {
                                  final error = ref
                                      .read(navigationProvider)
                                      .routeErrorMessage;
                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          error ?? 'Rute tidak dapat dibuat.',
                                        ),
                                      ),
                                    );
                                }
                              },
                        icon: const Icon(LucideIcons.route, size: 19),
                        label: Text(
                          navigation.isLoadingRoute
                              ? 'Membuat rute…'
                              : 'Lihat pratinjau rute',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    await ref.read(navigationProvider.notifier).loadCurrentLocation();
    if (!mounted) return;
    final message = ref.read(navigationProvider).locationMessage ??
        'Lokasi saat ini digunakan sebagai titik awal.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    setState(() => selected = null);
    await ref.read(destinationSearchProvider.notifier).search(
          query,
          nearby: ref.read(navigationProvider).currentPosition,
        );
  }

  Future<void> _openMapPicker() async {
    if (ref.read(navigationProvider).currentPosition == null) {
      await ref.read(navigationProvider.notifier).loadCurrentLocation();
    }
    if (!mounted) return;
    final navigation = ref.read(navigationProvider);
    if (navigation.currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            navigation.locationMessage ??
                'Posisi saat ini diperlukan untuk memilih tujuan.',
          ),
        ),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih tujuan melalui peta',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              const Text(
                'Ketuk lokasi pada peta untuk menetapkannya sebagai tujuan.',
              ),
              const SizedBox(height: 16),
              NavigationMap(
                height: 360,
                currentPosition: navigation.currentPosition,
                selectable: true,
                onPointSelected: (point) {
                  setState(() => selected = _mapDestination(point));
                  Navigator.pop(sheetContext);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Destination _mapDestination(GeoPoint point) => Destination(
        id: 'map-${point.latitude}-${point.longitude}',
        name: 'Titik pilihan pada peta',
        address:
            '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
        latitude: point.latitude,
        longitude: point.longitude,
        description: 'Lokasi yang dipilih langsung melalui peta.',
      );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.queryChanged,
    required this.onSearch,
    required this.isSearching,
    required this.onUseCurrentLocation,
    required this.onSelectFromMap,
    required this.isLoadingLocation,
    required this.isUsingCurrentLocation,
  });

  final ValueChanged<String> queryChanged;
  final VoidCallback onSearch;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onSelectFromMap;
  final bool isLoadingLocation;
  final bool isUsingCurrentLocation;
  final bool isSearching;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.deepBlue, AppTheme.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x331769E0),
              blurRadius: 28,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  LucideIcons.footprints,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LANGKAH',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.24,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Sahabat perjalananmu',
                      style: TextStyle(
                        color: Color(0xFFCFE3FF),
                        fontSize: 12,
                        letterSpacing: -.24,
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 28),
            const Text(
              'Mau ke mana?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                height: 1.05,
                fontWeight: FontWeight.w700,
                letterSpacing: -.64,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Navigasi yang lebih aman, jelas, dan personal.',
              style: TextStyle(
                color: Color(0xFFD9E9FF),
                fontSize: 15,
                letterSpacing: -.3,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              onChanged: queryChanged,
              onSubmitted: (_) {
                if (!isSearching) onSearch();
              },
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  LucideIcons.search,
                  color: AppTheme.primary,
                  size: 20,
                ),
                hintText: 'Cari nama tempat atau alamat',
                fillColor: Colors.white,
                suffixIcon: IconButton(
                  tooltip: 'Cari tujuan',
                  onPressed: isSearching ? null : onSearch,
                  icon: isSearching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.arrowRight),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: _HeaderAction(
                  actionKey: const Key('current-location-action'),
                  icon: isUsingCurrentLocation
                      ? LucideIcons.circleCheck
                      : LucideIcons.locateFixed,
                  label: isLoadingLocation
                      ? 'Mencari lokasi…'
                      : isUsingCurrentLocation
                          ? 'Lokasi saat ini digunakan'
                          : 'Gunakan lokasi saat ini',
                  onTap: isLoadingLocation ? null : onUseCurrentLocation,
                  isSuccess: isUsingCurrentLocation && !isLoadingLocation,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeaderAction(
                  icon: LucideIcons.mapPinned,
                  label: 'Pilih melalui peta',
                  onTap: onSelectFromMap,
                ),
              ),
            ]),
          ],
        ),
      );
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.actionKey,
    this.isSuccess = false,
  });

  final Key? actionKey;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        key: actionKey,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSuccess
              ? AppTheme.success
              : Colors.white.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSuccess
              ? const [
                  BoxShadow(
                    color: Color(0x3315803D),
                    blurRadius: 12,
                    offset: Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
              child: Row(children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    icon,
                    key: ValueKey(icon),
                    color: Colors.white,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      letterSpacing: -.24,
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
}

class _DestinationTile extends StatelessWidget {
  const _DestinationTile({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

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
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x181769E0),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
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
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                LucideIcons.mapPin,
                color: selected ? Colors.white : AppTheme.primary,
                size: 21,
              ),
            ),
            title: Text(
              destination.name,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(destination.address),
            ),
            trailing: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: selected
                  ? const Icon(
                      LucideIcons.circleCheck,
                      key: ValueKey(true),
                      color: AppTheme.primary,
                    )
                  : const Icon(
                      LucideIcons.chevronRight,
                      key: ValueKey(false),
                      color: AppTheme.muted,
                      size: 20,
                    ),
            ),
          ),
        ),
      );
}
