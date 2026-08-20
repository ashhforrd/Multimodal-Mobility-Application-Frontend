import '../../../data/models/destination.dart';
import '../../../data/models/geo_point.dart';
import '../../../data/models/navigation_route.dart';
import '../../../data/models/route_step.dart';

enum RouteStatus {
  idle,
  preview,
  active,
  approachingActionPoint,
  offRoute,
  recovering,
  completed
}

class NavigationState {
  const NavigationState(
      {this.selectedDestination,
      this.currentRoute,
      this.currentPosition,
      this.currentStepIndex = 0,
      this.routeStatus = RouteStatus.idle,
      this.distanceToNextActionPoint = 0,
      this.remainingDistanceMeters = 0,
      this.estimatedRemainingMinutes = 0,
      this.isActionAlertVisible = false,
      this.isLoadingLocation = false,
      this.isLoadingRoute = false,
      this.locationMessage,
      this.routeErrorMessage,
      this.overrideInstruction});
  final Destination? selectedDestination;
  final NavigationRoute? currentRoute;
  final GeoPoint? currentPosition;
  final int currentStepIndex;
  final int distanceToNextActionPoint;
  final int remainingDistanceMeters;
  final int estimatedRemainingMinutes;
  final RouteStatus routeStatus;
  final bool isActionAlertVisible;
  final bool isLoadingLocation;
  final bool isLoadingRoute;
  final String? locationMessage;
  final String? routeErrorMessage;
  final String? overrideInstruction;
  RouteStep? get activeStep =>
      currentRoute == null ? null : currentRoute!.steps[currentStepIndex];
  RouteStep? get nextStep =>
      currentRoute != null && currentStepIndex + 1 < currentRoute!.steps.length
          ? currentRoute!.steps[currentStepIndex + 1]
          : null;
  String get activeInstruction =>
      overrideInstruction ?? activeStep?.instruction ?? '';

  NavigationState copyWith(
          {Destination? selectedDestination,
          NavigationRoute? currentRoute,
          GeoPoint? currentPosition,
          int? currentStepIndex,
          RouteStatus? routeStatus,
          int? distanceToNextActionPoint,
          int? remainingDistanceMeters,
          int? estimatedRemainingMinutes,
          bool? isActionAlertVisible,
          bool? isLoadingLocation,
          bool? isLoadingRoute,
          String? locationMessage,
          String? routeErrorMessage,
          String? overrideInstruction,
          bool clearOverride = false,
          bool clearLocationMessage = false,
          bool clearRouteError = false}) =>
      NavigationState(
        selectedDestination: selectedDestination ?? this.selectedDestination,
        currentRoute: currentRoute ?? this.currentRoute,
        currentPosition: currentPosition ?? this.currentPosition,
        currentStepIndex: currentStepIndex ?? this.currentStepIndex,
        routeStatus: routeStatus ?? this.routeStatus,
        distanceToNextActionPoint:
            distanceToNextActionPoint ?? this.distanceToNextActionPoint,
        remainingDistanceMeters:
            remainingDistanceMeters ?? this.remainingDistanceMeters,
        estimatedRemainingMinutes:
            estimatedRemainingMinutes ?? this.estimatedRemainingMinutes,
        isActionAlertVisible: isActionAlertVisible ?? this.isActionAlertVisible,
        isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
        isLoadingRoute: isLoadingRoute ?? this.isLoadingRoute,
        locationMessage: clearLocationMessage
            ? null
            : locationMessage ?? this.locationMessage,
        routeErrorMessage: clearRouteError
            ? null
            : routeErrorMessage ?? this.routeErrorMessage,
        overrideInstruction: clearOverride
            ? null
            : overrideInstruction ?? this.overrideInstruction,
      );
}
