DateTime dateTimeFromMapValue(dynamic value) {
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
  }
  return DateTime.now();
}

Map<String, dynamic> mapFromJsonValue(dynamic value) =>
    Map<String, dynamic>.from(value as Map);

List<T> listFromJsonValue<T>(
  dynamic value,
  T Function(Map<String, dynamic>) fromMap,
) {
  if (value == null) return <T>[];
  return (value as List)
      .map((item) => fromMap(mapFromJsonValue(item)))
      .toList();
}
