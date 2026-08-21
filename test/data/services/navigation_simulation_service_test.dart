import 'package:flutter_test/flutter_test.dart';
import 'package:langkah_sahabat/data/models/route_step.dart';
import 'package:langkah_sahabat/data/services/navigation_simulation_service.dart';

void main() {
  test('skenario developer memakai input mock yang lengkap dan deterministik',
      () {
    const service = NavigationSimulationService();

    final scenario = service.createCampusScenario();

    expect(scenario.route.id, 'developer-simulation-route');
    expect(scenario.positions.length, greaterThan(20));
    expect(scenario.positions.first.latitude, scenario.route.origin.latitude);
    expect(
      scenario.positions.last.latitude,
      scenario.route.destination.latitude,
    );
    expect(
      scenario.route.steps.map((step) => step.actionType),
      containsAll([
        RouteActionType.slightLeft,
        RouteActionType.slightRight,
        RouteActionType.turnLeft,
        RouteActionType.turnRight,
        RouteActionType.arrive,
      ]),
    );
  });
}
