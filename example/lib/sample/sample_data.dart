// Sample data for the cloud console. Every name, ID and number here is made
// up for the example app.

/// One sample compute instance.
class SampleInstance {
  const SampleInstance({
    required this.id,
    required this.name,
    required this.state,
    required this.type,
    required this.zone,
    required this.cpu,
    required this.launched,
  });

  final String id;
  final String name;

  /// `running`, `stopped`, `pending` or `terminated`.
  final String state;
  final String type;
  final String zone;

  /// Average CPU utilization in percent.
  final int cpu;
  final DateTime launched;

  SampleInstance copyWith({String? state}) => SampleInstance(
    id: id,
    name: name,
    state: state ?? this.state,
    type: type,
    zone: zone,
    cpu: cpu,
    launched: launched,
  );
}

const _names = [
  'web-server',
  'api-gateway',
  'batch-worker',
  'cache-node',
  'search-indexer',
  'image-resizer',
  'log-shipper',
  'metrics-collector',
];
const _types = ['t3.micro', 't3.medium', 'm6g.large', 'c7g.xlarge', 'r6g.2xlarge'];
const _zones = ['us-east-1a', 'us-east-1b', 'eu-west-1a', 'ap-southeast-1b'];
const _states = ['running', 'running', 'running', 'stopped', 'pending', 'running', 'terminated'];

/// 46 sample instances with stable values.
List<SampleInstance> sampleInstances() => [
  for (var i = 0; i < 46; i++)
    SampleInstance(
      id: 'i-0${(0xa1b2c3 + i * 7919).toRadixString(16)}${(i * 37 % 100).toString().padLeft(2, '0')}',
      name: '${_names[i % _names.length]}-${i ~/ _names.length + 1}',
      state: _states[i % _states.length],
      type: _types[(i * 3) % _types.length],
      zone: _zones[(i * 5) % _zones.length],
      cpu: (i * 23 + 7) % 96,
      launched: DateTime(2026, 10, 1).add(Duration(hours: i * 13)),
    ),
];

/// 24 hourly CPU points for the dashboard chart.
List<(DateTime, double)> sampleCpu(int seed) => [
  for (var h = 0; h < 24; h++)
    (DateTime(2026, 11, 15, h), (30 + ((h * 17 + seed * 11) % 40) + (h > 8 && h < 18 ? 12 : 0)).toDouble()),
];
