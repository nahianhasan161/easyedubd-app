import 'dart:async';

import 'package:easyedubd_app/core/providers/supabase_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/promotion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PromotionRepository {
  final SupabaseClient _supabase;

  PromotionRepository(this._supabase);

  Future<List<Promotion>> getPromotionsForCourse(int courseId) async {
    final response = await _supabase
        .from('promotion_course')
        .select('promotion:promotion_id(*)')
        .eq('course_id', courseId)
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('Promotion fetch timeout'),
        );

    final promotions = <Promotion>[];
    for (final item in response as List<dynamic>) {
      final map = Map<String, dynamic>.from(item as Map<String, dynamic>);
      final promotionJson = map['promotion'];
      if (promotionJson != null) {
        promotions.add(Promotion.fromJson(promotionJson as Map<String, dynamic>));
      }
    }

    return promotions;
  }

  Future<List<Promotion>> getAllPromotions() async {
    final response = await _supabase
        .from('promotion')
        .select()
        .order('created_at', ascending: false)
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('Promotion list timeout'),
        );

    return (response as List<dynamic>)
        .map((e) => Promotion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Promotion> createPromotion(Map<String, dynamic> payload) async {
    final data = await _supabase
        .from('promotion')
        .insert(payload)
        .select()
        .single()
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('Promotion create timeout'),
        );

    return Promotion.fromJson(data);
  }

  Future<Promotion> updatePromotion(int id, Map<String, dynamic> payload) async {
    final data = await _supabase
        .from('promotion')
        .update(payload)
        .eq('id', id)
        .select()
        .single()
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('Promotion update timeout'),
        );

    return Promotion.fromJson(data);
  }

  Future<void> deletePromotion(int id) async {
    await _supabase
        .from('promotion')
        .delete()
        .eq('id', id)
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('Promotion delete timeout'),
        );
  }

  Future<void> assignPromotionToCourse(int promotionId, int courseId) async {
    await _supabase
        .from('promotion_course')
        .insert({
          'promotion_id': promotionId,
          'course_id': courseId,
        })
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('Promotion assign timeout'),
        );
  }

  Future<void> removePromotionFromCourse(int promotionId, int courseId) async {
    await _supabase
        .from('promotion_course')
        .delete()
        .eq('promotion_id', promotionId)
        .eq('course_id', courseId)
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('Promotion remove timeout'),
        );
  }

  Future<List<int>> getCourseIdsForPromotion(int promotionId) async {
    final response = await _supabase
        .from('promotion_course')
        .select('course_id')
        .eq('promotion_id', promotionId)
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('Promotion courses fetch timeout'),
        );

    return (response as List<dynamic>)
        .map((e) => (e as Map<String, dynamic>)['course_id'] as int)
        .toList();
  }

  Future<void> removePromotionAssignments(int promotionId) async {
    await _supabase
        .from('promotion_course')
        .delete()
        .eq('promotion_id', promotionId)
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('Promotion assignments delete timeout'),
        );
  }
}

final promotionRepositoryProvider = Provider<PromotionRepository>((ref) {
  return PromotionRepository(ref.read(supabaseProvider));
});
