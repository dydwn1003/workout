import 'package:supabase_flutter/supabase_flutter.dart';

import 'sync.dart';

/// The signed-in user's rows in public.user_records (supabase/user_sync.sql).
/// Row-level security limits every query to that user.
class SupabaseRecordStore implements RecordStore {
  final SupabaseClient client;
  final String userId;
  SupabaseRecordStore(this.client, this.userId);

  static const _pageSize = 1000;

  @override
  Future<List<RemoteRecord>> fetch({DateTime? since}) async {
    final out = <RemoteRecord>[];
    for (var from = 0; ; from += _pageSize) {
      var q = client
          .from('user_records')
          .select('kind,id,data,deleted,updated_at')
          .eq('user_id', userId);
      if (since != null) {
        q = q.gt('updated_at', since.toUtc().toIso8601String());
      }
      final rows = await q
          .order('updated_at')
          .range(from, from + _pageSize - 1);
      for (final r in rows) {
        out.add(
          RemoteRecord(
            r['kind'] as String,
            r['id'] as String,
            r['deleted'] == true
                ? null
                : (r['data'] as Map).cast<String, Object?>(),
            updatedAt: DateTime.parse(r['updated_at'] as String),
          ),
        );
      }
      if (rows.length < _pageSize) return out;
    }
  }

  @override
  Future<void> upsert(List<RemoteRecord> rows) async {
    for (var i = 0; i < rows.length; i += 500) {
      await client.from('user_records').upsert([
        for (final r in rows.skip(i).take(500))
          {
            'user_id': userId,
            'kind': r.kind,
            'id': r.id,
            'data': r.data,
            'deleted': r.deleted,
          },
      ], onConflict: 'user_id,kind,id');
    }
  }

  /// Marks every row deleted (rather than removing them) so the user's other
  /// devices clear their copies on their next pull instead of re-uploading.
  @override
  Future<void> deleteAll() => client
      .from('user_records')
      .update({'data': null, 'deleted': true})
      .eq('user_id', userId)
      .eq('deleted', false);
}
