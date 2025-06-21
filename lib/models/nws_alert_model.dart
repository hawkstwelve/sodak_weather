import 'dart:convert';

NwsAlertCollection nwsAlertCollectionFromJson(String str) =>
    NwsAlertCollection.fromJson(json.decode(str));
String nwsAlertCollectionToJson(NwsAlertCollection data) =>
    json.encode(data.toJson());

class NwsAlertCollection {
  final List<NwsAlertFeature>? features;
  final String? title;

  NwsAlertCollection({this.features, this.title});

  factory NwsAlertCollection.fromJson(Map<String, dynamic> json) =>
      NwsAlertCollection(
        features: json["features"] == null
            ? []
            : List<NwsAlertFeature>.from(
                json["features"]!.map((x) => NwsAlertFeature.fromJson(x)),
              ),
        title: json["title"],
      );

  Map<String, dynamic> toJson() => {
    "features": features == null
        ? []
        : List<dynamic>.from(features!.map((x) => x.toJson())),
    "title": title,
  };
}

class NwsAlertFeature {
  final String? id;
  final String? type;
  final AlertProperties? properties;

  NwsAlertFeature({this.id, this.type, this.properties});

  factory NwsAlertFeature.fromJson(Map<String, dynamic> json) =>
      NwsAlertFeature(
        id: json["id"],
        type: json["type"],
        properties: json["properties"] == null
            ? null
            : AlertProperties.fromJson(json["properties"]),
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "type": type,
    "properties": properties?.toJson(),
  };
}

class AlertProperties {
  final String? id;
  final String? areaDesc;
  final DateTime? sent;
  final DateTime? effective;
  final DateTime? onset;
  final DateTime? expires;
  final DateTime? ends;
  final String? status;
  final String? messageType;
  final String? category;
  final String? severity;
  final String? certainty;
  final String? urgency;
  final String? event;
  final String? senderName;
  final String? headline;
  final String? description;
  final String? instruction;

  AlertProperties({
    this.id,
    this.areaDesc,
    this.sent,
    this.effective,
    this.onset,
    this.expires,
    this.ends,
    this.status,
    this.messageType,
    this.category,
    this.severity,
    this.certainty,
    this.urgency,
    this.event,
    this.senderName,
    this.headline,
    this.description,
    this.instruction,
  });

  factory AlertProperties.fromJson(Map<String, dynamic> json) =>
      AlertProperties(
        id: json["@id"],
        areaDesc: json["areaDesc"],
        sent: json["sent"] == null ? null : DateTime.tryParse(json["sent"]),
        effective: json["effective"] == null
            ? null
            : DateTime.tryParse(json["effective"]),
        onset: json["onset"] == null ? null : DateTime.tryParse(json["onset"]),
        expires: json["expires"] == null
            ? null
            : DateTime.tryParse(json["expires"]),
        ends: json["ends"] == null ? null : DateTime.tryParse(json["ends"]),
        status: json["status"],
        messageType: json["messageType"],
        category: json["category"],
        severity: json["severity"],
        certainty: json["certainty"],
        urgency: json["urgency"],
        event: json["event"],
        senderName: json["senderName"],
        headline: json["headline"],
        description: json["description"],
        instruction: json["instruction"],
      );

  Map<String, dynamic> toJson() => {
    "@id": id,
    "areaDesc": areaDesc,
    "sent": sent?.toIso8601String(),
    "effective": effective?.toIso8601String(),
    "onset": onset?.toIso8601String(),
    "expires": expires?.toIso8601String(),
    "ends": ends?.toIso8601String(),
    "status": status,
    "messageType": messageType,
    "category": category,
    "severity": severity,
    "certainty": certainty,
    "urgency": urgency,
    "event": event,
    "senderName": senderName,
    "headline": headline,
    "description": description,
    "instruction": instruction,
  };
}
