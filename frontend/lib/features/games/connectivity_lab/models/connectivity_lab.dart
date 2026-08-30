import '../../../game_engine/models/game_models.dart';

enum DeviceType { client, server, router, switch_, accessPoint, firewall, dns, dhcp, pc }

enum MissionType { connect, build, route, trace, repair, diagnose, layer }

class NetworkDevice {
  const NetworkDevice({required this.id, required this.name, required this.type, this.label, this.icon});
  final String id;
  final String name;
  final DeviceType type;
  final String? label;
  final String? icon;
}

class NetworkConnection {
  const NetworkConnection({required this.id, required this.sourceId, required this.targetId, this.enabled = true, this.isBroken = false});
  final String id;
  final String sourceId;
  final String targetId;
  final bool enabled;
  final bool isBroken;
  NetworkConnection copyWith({bool? enabled, bool? isBroken}) => NetworkConnection(id: id, sourceId: sourceId, targetId: targetId, enabled: enabled ?? this.enabled, isBroken: isBroken ?? this.isBroken);
  @override
  bool operator ==(Object other) => other is NetworkConnection && other.sourceId == sourceId && other.targetId == targetId;
  @override
  int get hashCode => Object.hash(sourceId, targetId);
}

class NetworkPacket {
  const NetworkPacket({required this.id, required this.sourceId, required this.destinationId, this.route = const []});
  final String id;
  final String sourceId;
  final String destinationId;
  final List<String> route;
}

class DiagnosisOption {
  const DiagnosisOption({required this.id, required this.label, required this.description});
  final String id;
  final String label;
  final String description;
}

class ConnectivityMission {
  const ConnectivityMission({
    required this.id,
    required this.title,
    required this.topic,
    required this.difficulty,
    required this.missionType,
    required this.story,
    required this.objective,
    required this.learningObjective,
    required this.concept,
    required this.explanation,
    required this.hint,
    required this.devices,
    this.initialConnections = const [],
    this.correctConnections,
    this.correctRoute,
    this.brokenConnectionId,
    this.correctRepair,
    this.diagnosisOptions,
    this.correctDiagnosisId,
    this.layerBlocks,
    this.correctLayerOrder,
    this.packetSource,
    this.packetDestination,
    this.reward = 100,
  });

  final String id;
  final String title;
  final String topic;
  final GameDifficulty difficulty;
  final MissionType missionType;
  final String story;
  final String objective;
  final String learningObjective;
  final String concept;
  final String explanation;
  final String hint;
  final List<NetworkDevice> devices;
  final List<NetworkConnection> initialConnections;
  final List<NetworkConnection>? correctConnections;
  final List<String>? correctRoute;
  final String? brokenConnectionId;
  final NetworkConnection? correctRepair;
  final List<DiagnosisOption>? diagnosisOptions;
  final String? correctDiagnosisId;
  final List<String>? layerBlocks;
  final List<String>? correctLayerOrder;
  final String? packetSource;
  final String? packetDestination;
  final int reward;

  bool get isValid {
    if (id.isEmpty || title.isEmpty || topic.isEmpty || story.isEmpty || objective.isEmpty || learningObjective.isEmpty || concept.isEmpty || explanation.isEmpty || hint.isEmpty) return false;
    if (devices.length < 2) return false;
    if (reward <= 0) return false;
    final dIds = devices.map((d) => d.id).toSet();
    if (dIds.length != devices.length) return false;
    // Validate connections reference valid devices
    for (final c in initialConnections) {
      if (!dIds.contains(c.sourceId) || !dIds.contains(c.targetId)) return false;
    }
    switch (missionType) {
      case MissionType.connect:
      case MissionType.build:
        if (correctConnections == null || correctConnections!.isEmpty) return false;
        for (final c in correctConnections!) if (!dIds.contains(c.sourceId) || !dIds.contains(c.targetId)) return false;
        return true;
      case MissionType.route:
      case MissionType.trace:
        if (correctRoute == null || correctRoute!.length < 2) return false;
        for (final nid in correctRoute!) if (!dIds.contains(nid)) return false;
        if (packetSource != null && !dIds.contains(packetSource!)) return false;
        if (packetDestination != null && !dIds.contains(packetDestination!)) return false;
        return true;
      case MissionType.repair:
        if (brokenConnectionId == null) return false;
        // broken must exist in initialConnections
        if (!initialConnections.any((c) => c.id == brokenConnectionId)) return false;
        return true;
      case MissionType.diagnose:
        if (diagnosisOptions == null || diagnosisOptions!.length < 2) return false;
        if (correctDiagnosisId == null) return false;
        if (!diagnosisOptions!.any((o) => o.id == correctDiagnosisId)) return false;
        return true;
      case MissionType.layer:
        if (layerBlocks == null || correctLayerOrder == null) return false;
        if (layerBlocks!.length < 2 || correctLayerOrder!.length != layerBlocks!.length) return false;
        final s = layerBlocks!.toSet();
        for (final l in correctLayerOrder!) if (!s.contains(l)) return false;
        return true;
    }
  }

  bool isConnectionCorrect(Set<NetworkConnection> userConns) {
    if (missionType != MissionType.connect && missionType != MissionType.build) return false;
    final correct = correctConnections!.toSet();
    // normalize: compare source-target pairs regardless of order? For our lab, direction matters but we allow either direction as valid if undirectional
    bool same(Set<NetworkConnection> a, Set<NetworkConnection> b) {
      if (a.length != b.length) return false;
      for (final ca in a) {
        bool found = b.any((cb) => (cb.sourceId == ca.sourceId && cb.targetId == ca.targetId) || (cb.sourceId == ca.targetId && cb.targetId == ca.sourceId));
        if (!found) return false;
      }
      return true;
    }
    return same(userConns, correct);
  }

  bool isRouteCorrect(List<String> route) {
    if (missionType != MissionType.route && missionType != MissionType.trace) return false;
    if (route.length != correctRoute!.length) return false;
    for (var i = 0; i < correctRoute!.length; i++) if (route[i] != correctRoute![i]) return false;
    return true;
  }

  bool isRepairCorrect(Set<NetworkConnection> connsAfterRepair) {
    if (missionType != MissionType.repair) return false;
    // After repair, there should be no broken connections and packet route should be possible
    // Simplified: check that broken connection is now enabled
    final repaired = connsAfterRepair.firstWhere((c) => c.id == brokenConnectionId, orElse: () => const NetworkConnection(id: '', sourceId: '', targetId: ''));
    if (repaired.id.isEmpty) return false;
    return !repaired.isBroken && repaired.enabled;
  }

  bool isDiagnosisCorrect(String id) {
    if (missionType != MissionType.diagnose) return false;
    return id == correctDiagnosisId;
  }

  bool isLayerCorrect(List<String> order) {
    if (missionType != MissionType.layer) return false;
    if (order.length != correctLayerOrder!.length) return false;
    for (var i = 0; i < correctLayerOrder!.length; i++) if (order[i] != correctLayerOrder![i]) return false;
    return true;
  }

  bool isCorrectDynamic(dynamic answer) {
    switch (missionType) {
      case MissionType.connect:
      case MissionType.build:
        return answer is Set<NetworkConnection> && isConnectionCorrect(answer);
      case MissionType.route:
      case MissionType.trace:
        return answer is List<String> && isRouteCorrect(answer);
      case MissionType.repair:
        return answer is Set<NetworkConnection> && isRepairCorrect(answer);
      case MissionType.diagnose:
        return answer is String && isDiagnosisCorrect(answer);
      case MissionType.layer:
        return answer is List<String> && isLayerCorrect(answer);
    }
  }
}

/// Graph helper for connectivity validation (BFS)
class NetworkGraph {
  NetworkGraph({required this.devices, required this.connections});
  final List<NetworkDevice> devices;
  final List<NetworkConnection> connections;

  Map<String, Set<String>> get adjacency {
    final m = <String, Set<String>>{};
    for (final d in devices) m[d.id] = {};
    for (final c in connections.where((e) => e.enabled && !e.isBroken)) {
      m[c.sourceId]?.add(c.targetId);
      m[c.targetId]?.add(c.sourceId); // undirected for connectivity
    }
    return m;
  }

  bool isConnected(String from, String to) {
    if (from == to) return true;
    final adj = adjacency;
    final visited = <String>{};
    final queue = <String>[from];
    visited.add(from);
    while (queue.isNotEmpty) {
      final cur = queue.removeAt(0);
      final Set<String> neighbors = adj[cur] ?? <String> {};
      for (final nb in neighbors) {
        if (nb == to) return true;
        if (!visited.contains(nb)) {
          visited.add(nb);
          queue.add(nb);
        }
      }
    }
    return false;
  }

  bool isValidRoute(List<String> route) {
    if (route.length < 2) return false;
    final adj = adjacency;
    for (var i = 0; i < route.length - 1; i++) {
      if (!(adj[route[i]]?.contains(route[i + 1]) ?? false)) return false;
    }
    return true;
  }

  bool isPacketDelivered(NetworkPacket packet, List<NetworkConnection> conns) {
    final g = NetworkGraph(devices: devices, connections: conns);
    return g.isConnected(packet.sourceId, packet.destinationId);
  }
}

class ConnectivityLabState {
  ConnectivityLabState({required this.mission});
  final ConnectivityMission mission;
  Set<NetworkConnection> userConnections = {};
  List<String> selectedRoute = [];
  String? selectedDiagnosis;
  List<String> layerSelection = [];
  int lives = 3;
  bool solved = false;

  void initForMission() {
    userConnections = mission.initialConnections.where((c) => !c.isBroken).toSet();
    // For repair, keep broken as is, user must repair
    if (mission.missionType == MissionType.repair) {
      userConnections = mission.initialConnections.toSet();
    }
    selectedRoute = [];
    selectedDiagnosis = null;
    layerSelection = [];
  }

  bool submitConnections(Set<NetworkConnection> conns) {
    final ok = mission.isConnectionCorrect(conns);
    if (ok) solved = true; else lives--;
    return ok;
  }

  bool submitRoute(List<String> route) {
    final ok = mission.isRouteCorrect(route);
    if (ok) solved = true; else lives--;
    return ok;
  }

  bool submitRepair(Set<NetworkConnection> after) {
    final ok = mission.isRepairCorrect(after);
    if (ok) solved = true; else lives--;
    return ok;
  }

  bool submitDiagnosis(String id) {
    final ok = mission.isDiagnosisCorrect(id);
    if (ok) solved = true; else lives--;
    return ok;
  }

  bool submitLayer(List<String> order) {
    final ok = mission.isLayerCorrect(order);
    if (ok) solved = true; else lives--;
    return ok;
  }

  void reset() {
    lives = 3;
    solved = false;
    userConnections = {};
    selectedRoute = [];
    selectedDiagnosis = null;
    layerSelection = [];
  }
}

abstract final class ConnectivityValidator {
  static bool hasNoDuplicateIds(List<ConnectivityMission> missions) => missions.map((m) => m.id).toSet().length == missions.length;
  static Set<String> topicsOf(List<ConnectivityMission> m) => m.map((e) => e.topic).toSet();
  static Set<MissionType> typesOf(List<ConnectivityMission> m) => m.map((e) => e.missionType).toSet();
  static Set<GameDifficulty> diffsOf(List<ConnectivityMission> m) => m.map((e) => e.difficulty).toSet();
}
