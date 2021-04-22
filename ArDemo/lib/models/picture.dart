class Picture {
  static const PHOTOPATH = "photoPath";
  static const PHOTOURL = "photoUrl";
  static const RECOGS = "recogs";
  static const IMAGE_FOLDER = "Photos";
  static const GROUPID = "groupId";
  static const TIMESTAMP = "timestamp";

  String photoPath;
  String photoURL;
  String recogs;
  String docId;
  String groupId;
  DateTime timestamp;

  Picture({
    this.recogs,
    this.photoPath,
    this.photoURL,
    this.groupId,
    this.docId,
    this.timestamp,
  }) {}

  Map<String, dynamic> serialize() {
    return <String, dynamic>{
      RECOGS: recogs,
      PHOTOPATH: photoPath,
      PHOTOURL: photoURL,
      GROUPID: groupId,
      TIMESTAMP: timestamp,
    };
  }

   static Picture deserialize(Map<String, dynamic> data, DateTime timestamp, String doc) {
    return Picture(
        recogs: data[Picture.RECOGS],
        photoPath: data[Picture.PHOTOPATH],
        photoURL: data[Picture.PHOTOURL],
        groupId: data[Picture.GROUPID],
        timestamp: DateTime(data[Picture.TIMESTAMP]),
        docId: doc,
    );
  }

}