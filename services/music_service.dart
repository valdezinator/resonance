import 'package:supabase_flutter/supabase_flutter.dart';

class MusicService {
  Future<List<Map<String, dynamic>>> getQuickPlaySongs({
    int offset = 0,
    int limit = 10,
  }) async {
    final response = await Supabase.instance.client
        .from('songs')
        .select()
        .range(offset, offset + limit - 1)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }
  // ... rest of the class
}