import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';

class UserService {
  Future<List<Map<String, dynamic>>> fetchCandidates({
    required int requesterId,
  }) async {
    final response = await http.get(
      Uri.parse(ApiConstants.ratingUrl(requesterId)),
    );

    if (response.statusCode != 200) {
      return const [];
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      return const [];
    }

    return decoded.whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>?> fetchCandidateDetails({
    required int userId,
    required int requesterId,
  }) async {
    final response = await http.get(
      Uri.parse(ApiConstants.candidateDetailsUrl(userId, requesterId)),
    );

    if (response.statusCode != 200) {
      return null;
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> fetchCandidateComparison({
    required int requesterId,
    required int firstCandidateId,
    required int secondCandidateId,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/users/compare'
      '?requesterId=$requesterId'
      '&firstCandidateId=$firstCandidateId'
      '&secondCandidateId=$secondCandidateId',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      return null;
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
