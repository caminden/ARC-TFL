class Picture {
  static const PHOTOPATH = "photoPath";
  static const PHOTOURL = "photoUrl";
  static const RECOGS = "recogs";
  static const IMAGE_FOLDER = "Photos";

  String photoPath;
  String photoURL;
  String recogs;
  String docId;

  Picture({
    this.recogs,
    this.photoPath,
    this.photoURL,
    this.docId,
  }) {}

  Map<String, dynamic> serialize() {
    return <String, dynamic>{
      RECOGS: recogs,
      PHOTOPATH: photoPath,
      PHOTOURL: photoURL,
    };
  }

   static Picture deserialize(Map<String, dynamic> data, String doc) {
    return Picture(
        recogs: data[Picture.RECOGS],
        photoPath: data[Picture.PHOTOPATH],
        photoURL: data[Picture.PHOTOURL],
        docId: doc,
    );
  }

}