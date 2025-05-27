class GCodeData {
  final int userId;
  final String makineId;
  final String makineIp;
  final List<String> commands;

  GCodeData({
    required this.userId,
    required this.makineId,
    required this.makineIp,
    required this.commands,
  });

  // Factory constructor to create a GCodeData object from JSON
  factory GCodeData.fromJson(Map<String, dynamic> json) {
    return GCodeData(
      userId: json['user_id'] ?? 0,
      makineId: json['makine_id'] ?? '',
      makineIp: json['makine_ip'] ?? '',
      commands: List<String>.from(json['cmd'] ?? []),
    );
  }

  // Convert GCode commands to a single string (NC file content)
  String getNCFileContent() {
    return commands.join('\n');
  }
}
