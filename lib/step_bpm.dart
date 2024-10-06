import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';

class PedometerDisplay extends HookWidget {
  PedometerDisplay({super.key});

  // Init streams
  final Stream<PedestrianStatus> pedestrianStatusStream = Pedometer.pedestrianStatusStream;
  final Stream<StepCount> stepCountStream = Pedometer.stepCountStream;

  @override
  Widget build(BuildContext context) {

    final steps = useState<int>(0);
    final timeStamp = useState<DateTime>(DateTime.now());
    final status = useState<String>("unknown");// "walking", "stopped", "unknown"

    useEffect(() {
      // Listen to streams and handle errors
      stepCountStream.listen((StepCount event) {
        /// Handle step count changed
        steps.value = event.steps;
        timeStamp.value = event.timeStamp;
      }).onError((error) {
        debugPrint("void onStepCountError(error): $error");
      });

      pedestrianStatusStream.listen((PedestrianStatus event) {
        status.value = event.status;
        timeStamp.value = event.timeStamp;
      }).onError((error) {
        debugPrint("void onPedestrianStatusError(error): $error");
      });

      return null;
    }, []);

    return ListTile(
        leading: const Icon(
            Icons.directions_walk,
            size: 30,
          ),
        title: Text(
          'Step: ${steps.value}, status: ${status.value}\n'
          'timeStamp: ${timeStamp.value}'
        ),
        // trailing: PopupMenuButton<Menu>(
    );
  }
}