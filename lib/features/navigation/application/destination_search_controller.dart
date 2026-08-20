import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/destination.dart';
import '../../../data/models/geo_point.dart';
import '../../../data/services/map_service.dart';
import 'navigation_controller.dart';

final destinationSearchProvider =
    StateNotifierProvider<DestinationSearchController, DestinationSearchState>(
  (ref) => DestinationSearchController(
    mapService: ref.watch(mapServiceProvider),
  ),
);

class DestinationSearchState {
  const DestinationSearchState({
    this.results = const [],
    this.isSearching = false,
    this.hasSearched = false,
    this.errorMessage,
  });

  final List<Destination> results;
  final bool isSearching;
  final bool hasSearched;
  final String? errorMessage;
}

class DestinationSearchController
    extends StateNotifier<DestinationSearchState> {
  DestinationSearchController({required MapService mapService})
      : _mapService = mapService,
        super(const DestinationSearchState());

  final MapService _mapService;

  Future<void> search(String query, {GeoPoint? nearby}) async {
    state = const DestinationSearchState(
      isSearching: true,
      hasSearched: true,
    );
    try {
      final results =
          await _mapService.searchDestinations(query, nearby: nearby);
      state = DestinationSearchState(
        results: results,
        hasSearched: true,
      );
    } on MapServiceException catch (error) {
      state = DestinationSearchState(
        hasSearched: true,
        errorMessage: error.message,
      );
    }
  }

  void clear() => state = const DestinationSearchState();
}
