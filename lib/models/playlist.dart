class Playlist {
  final String id;  // Changed from int to String
  final String playlistName;
  final String? imageUrl;
  final String userId;

  Playlist({
    required this.id,
    required this.playlistName,
    this.imageUrl,
    required this.userId,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'].toString(),  // Convert to String
      playlistName: json['playlist_name'],
      imageUrl: json['image_url'],
      userId: json['user_id'],
    );
  }
}
