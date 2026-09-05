import 'package:mobile/models/catalog.dart';

class PublicProfile {
  const PublicProfile({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.libraryVisible,
    required this.reviewsVisible,
  });

  final String uid;
  final String username;
  final String displayName;
  final bool libraryVisible;
  final bool reviewsVisible;

  factory PublicProfile.fromMap(String uid, Map<String, dynamic> data) =>
      PublicProfile(
        uid: uid,
        username: data['username'] as String? ?? '',
        displayName: data['displayName'] as String? ?? '',
        libraryVisible: (data['library'] as Map?)?['visible'] as bool? ?? true,
        reviewsVisible: (data['reviews'] as Map?)?['visible'] as bool? ?? true,
      );
}

/// One entry in a public "what they watched/played/read" diary — a
/// read-only projection of someone else's library row.
class PublicLibraryEntry {
  const PublicLibraryEntry({
    required this.title,
    required this.kind,
    required this.imageUrl,
    required this.status,
  });

  final String title;
  final String kind;
  final String imageUrl;
  final String status;

  factory PublicLibraryEntry.fromMap(Map<String, dynamic> data) =>
      PublicLibraryEntry(
        title: data['title'] as String? ?? '',
        kind: data['kind'] as String? ?? '',
        imageUrl: data['imageUrl'] as String? ?? '',
        status: data['status'] as String? ?? '',
      );

  ContentItem toContentItem() => ContentItem(
    title: title,
    kind: kind,
    meta: '',
    dateLabel: '',
    imageUrl: imageUrl,
  );
}
