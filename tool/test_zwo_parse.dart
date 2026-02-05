import 'package:spatial_cosmic_mobile/src/logic/zwo_parser.dart';

void assertCondition(bool condition, String message) {
  if (!condition) {
    throw Exception(message);
  }
}

void main() {
  // Simulated ZWO output from webapp (AI style with Ramp + SteadyState)
  const aiZwo = '''
<workout_file>
  <author>CyclingCoach</author>
  <name>AI Test Workout</name>
  <description>Workout AI con target watt</description>
  <sportType>bike</sportType>
  <tags>
    <tag name="TEST"/>
  </tags>
  <workout>
    <Warmup Duration="300" PowerLow="0.30" PowerHigh="0.55">
      <TEXT></TEXT>
    </Warmup>
    <SteadyState Duration="600" Power="1.12">
      <TEXT></TEXT>
    </SteadyState>
    <Cooldown Duration="300" PowerLow="0.40" PowerHigh="0.20">
      <TEXT></TEXT>
    </Cooldown>
  </workout>
</workout_file>
''';

  // Simulated ZWO output from webapp (Library style with SteadyState blocks)
  const libraryZwo = '''
<workout_file>
  <author>CyclingCoach</author>
  <name>Library Test Workout</name>
  <description>Workout library percent_ftp</description>
  <sportType>bike</sportType>
  <tags>
    <tag name="TEST"/>
  </tags>
  <workout>
    <SteadyState Duration="3600" Power="0.65">
      <TEXT></TEXT>
    </SteadyState>
  </workout>
</workout_file>
''';

  final aiParsed = ZwoParser.parse(aiZwo);
  final aiStats = ZwoParser.getStats(aiParsed, 250);
  assertCondition(aiParsed.blocks.isNotEmpty, 'AI: Nessun blocco parsato');
  assertCondition(aiStats['duration'] == 1200, 'AI: durata errata');

  final libraryParsed = ZwoParser.parse(libraryZwo);
  final libraryStats = ZwoParser.getStats(libraryParsed, 250);
  assertCondition(libraryParsed.blocks.isNotEmpty, 'Library: Nessun blocco parsato');
  assertCondition(libraryStats['duration'] == 3600, 'Library: durata errata');

  final assignmentJson = {
    'id': 'test-assignment',
    'workout_name': 'JSON Assigned Workout',
    'workout_structure': {
      'steps': [
        {'type': 'Warmup', 'duration': 300, 'power': 0.5},
        {'type': 'SteadyState', 'duration': 600, 'power': 0.8},
        {'type': 'CoolDown', 'duration': 300, 'power': 0.4},
      ]
    }
  };

  final jsonParsed = ZwoParser.parseJson(assignmentJson);
  final jsonStats = ZwoParser.getStats(jsonParsed, 250);
  assertCondition(jsonParsed.blocks.isNotEmpty, 'JSON: Nessun blocco parsato');
  assertCondition(jsonStats['duration'] == 1200, 'JSON: durata errata');

  print('✅ ZWO parse OK: AI + Library + JSON');
}
