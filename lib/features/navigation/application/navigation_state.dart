import '../../../data/models/destination.dart';
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
      this.currentStepIndex = 0,
      this.routeStatus = RouteStatus.idle,
      this.distanceToNextActionPoint = 0,
      this.isActionAlertVisible = false,
      this.overrideInstruction});
  final Destination? selectedDestination;
  final NavigationRoute? currentRoute;
  final int currentStepIndex, distanceToNextActionPoint;
  final RouteStatus routeStatus;
  final bool isActionAlertVisible;
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
          int? currentStepIndex,
          RouteStatus? routeStatus,
          int? distanceToNextActionPoint,
          bool? isActionAlertVisible,
          String? overrideInstruction,
          bool clearOverride = false}) =>
      NavigationState(
        selectedDestination: selectedDestination ?? this.selectedDestination,
        currentRoute: currentRoute ?? this.currentRoute,
        currentStepIndex: currentStepIndex ?? this.currentStepIndex,
        routeStatus: routeStatus ?? this.routeStatus,
        distanceToNextActionPoint:
            distanceToNextActionPoint ?? this.distanceToNextActionPoint,
        isActionAlertVisible: isActionAlertVisible ?? this.isActionAlertVisible,
        overrideInstruction: clearOverride
            ? null
            : overrideInstruction ?? this.overrideInstruction,
      );
}
