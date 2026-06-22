import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/lawyer.dart';
import '../models/legal_service.dart';
import '../models/news_item.dart';
import '../models/office.dart';

/// Ported from law-firm-app/lib/api.ts.
///
/// Talks to the ERPNext backend whose mobile API lives under
/// `law_firm.api.mobile.*`. The origin can be overridden at build time with
/// `--dart-define=API_URL=https://example.org`; it defaults to production.
/// Backend origin. NOTE: origin only — the path is appended below.
const String apiBaseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://justice-iq.org',
);

const String _methodBase = '$apiBaseUrl/api/method/law_firm.api.mobile';

/// Resolve a media path from the API into a loadable URL. The backend returns
/// root-relative paths (e.g. "/files/foo.jpg"); absolute http(s) URLs pass through.
String resolveMedia(String? path) {
  if (path == null || path.isEmpty) return '';
  if (RegExp(r'^https?://').hasMatch(path)) return path;
  return '$apiBaseUrl${path.startsWith('/') ? '' : '/'}$path';
}

enum ApiErrorCode { throttled, unauthorized, network, server }

class ApiException implements Exception {
  final ApiErrorCode code;
  final String message;

  const ApiException(this.code, this.message);

  @override
  String toString() => 'ApiException(${code.name}): $message';
}

/// Frappe API token pair issued by verify_otp; sent as
/// `Authorization: token apiKey:apiSecret` on authenticated calls.
class AuthToken {
  final String apiKey;
  final String apiSecret;

  const AuthToken({required this.apiKey, required this.apiSecret});

  String get header => 'token $apiKey:$apiSecret';
}

/// Frappe packs frappe.throw messages into _server_messages as a JSON array
/// of JSON-encoded objects.
String? _extractServerMessage(Map<String, dynamic>? json) {
  try {
    final raw = json?['_server_messages'];
    if (raw is! String || raw.isEmpty) return null;
    final list = jsonDecode(raw);
    if (list is! List || list.isEmpty) return null;
    final first = jsonDecode(list.first as String);
    return (first is Map && first['message'] is String)
        ? first['message'] as String
        : null;
  } catch (_) {
    return null;
  }
}

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  final http.Client _client = http.Client();

  /// Low-level call returning the unwrapped `message` field. Mirrors api.ts `call`.
  Future<dynamic> _call(
    String name, {
    String method = 'GET',
    Object? body,
    AuthToken? auth,
  }) async {
    final uri = Uri.parse('$_methodBase.$name');
    final headers = <String, String>{
      if (body != null) 'Content-Type': 'application/json',
      if (auth != null) 'Authorization': auth.header,
    };

    http.Response res;
    try {
      res = method == 'POST'
          ? await _client.post(
              uri,
              headers: headers,
              body: body == null ? null : jsonEncode(body),
            )
          : await _client.get(uri, headers: headers);
    } catch (e) {
      throw ApiException(ApiErrorCode.network, e.toString());
    }

    Map<String, dynamic>? json;
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) json = decoded;
    } catch (_) {
      json = null;
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final code = res.statusCode == 429
          ? ApiErrorCode.throttled
          : (res.statusCode == 401 || res.statusCode == 403)
          ? ApiErrorCode.unauthorized
          : ApiErrorCode.server;
      throw ApiException(
        code,
        _extractServerMessage(json) ?? 'HTTP ${res.statusCode}',
      );
    }

    if (json == null) {
      throw ApiException(
        ApiErrorCode.server,
        'HTTP ${res.statusCode}: empty body',
      );
    }
    return json['message'];
  }

  // ─── Public content (no auth) ───
  Future<List<LegalService>> getServices() async =>
      _parseList(await _call('get_services'), LegalService.fromJson);
  Future<List<NewsItem>> getNews() async =>
      _parseList(await _call('get_news'), NewsItem.fromJson);
  Future<List<Lawyer>> getTeam() async =>
      _parseList(await _call('get_team'), Lawyer.fromJson);

  static List<T> _parseList<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final list = (raw as List?) ?? const [];
    return list
        .whereType<Map>()
        .map((e) => fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  // ─── Auth ───
  /// `registered` is omitted by older backends — treat undefined as registered.
  Future<SendOtpResult> sendOtp(String phone) async {
    final m = await _call('send_otp', method: 'POST', body: {'phone': phone});
    final map = (m as Map?) ?? const {};
    return SendOtpResult(
      sent: map['sent'] == true,
      registered: map['registered'] as bool?,
    );
  }

  Future<VerifyOtpResult> verifyOtp(String phone, String otp) async {
    final m = await _call(
      'verify_otp',
      method: 'POST',
      body: {'phone': phone, 'otp': otp},
    );
    final map = (m as Map).cast<String, dynamic>();
    if (map['ok'] == true) {
      final user = (map['user'] as Map).cast<String, dynamic>();
      return VerifyOtpResult.ok(
        apiKey: map['api_key'] as String,
        apiSecret: map['api_secret'] as String,
        name: user['name'] as String? ?? '',
        fullName: user['full_name'] as String? ?? '',
        email: user['email'] as String?,
        mobileNo: user['mobile_no'] as String?,
        isLawyer: user['is_lawyer'] == true || user['is_lawyer'] == 1,
      );
    }
    return VerifyOtpResult.fail(map['error'] as String? ?? 'invalid');
  }

  // ─── Bookings / join requests (guest-allowed) ───
  /// Creates a Consultation Booking. The backend accepts guests, so [auth] is
  /// optional — when present (a logged-in user) the record is stamped with that
  /// user; otherwise it is stamped as "Guest".
  Future<String> createBooking(
    BookingPayload payload, [
    AuthToken? auth,
  ]) async {
    final m = await _call(
      'create_booking',
      method: 'POST',
      body: payload.toJson(),
      auth: auth,
    );
    return ((m as Map)['id'] as String?) ?? '';
  }

  /// Creates a Request Join Lawyer. Guest-allowed like [createBooking]; [auth]
  /// is optional and only stamps the user when a session is present.
  Future<String> createJoinRequest(
    JoinRequestPayload payload, [
    AuthToken? auth,
  ]) async {
    final m = await _call(
      'create_join_request',
      method: 'POST',
      body: payload.toJson(),
      auth: auth,
    );
    return ((m as Map)['id'] as String?) ?? '';
  }

  Future<List<RemoteCase>> getMyCases(AuthToken auth) async {
    final m = await _call('get_my_cases', auth: auth);
    final list = (m as List?) ?? const [];
    return list
        .map((e) => RemoteCase.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// Deletes (disables + anonymizes) the authenticated user's account.
  /// Backend: law_firm.api.mobile.delete_account.
  Future<void> deleteAccount(AuthToken auth) async {
    await _call('delete_account', method: 'POST', auth: auth);
  }

  Future<AiChatResult> aiChat(List<AiMessage> messages) async {
    final m = await _call(
      'ai_chat',
      method: 'POST',
      body: {'messages': messages.map((e) => e.toJson()).toList()},
    );
    final map = (m as Map).cast<String, dynamic>();
    return AiChatResult(
      reply: map['reply'] as String?,
      error: map['error'] as String?,
    );
  }

  // ─── Lawyer workspace (all token-authenticated) ───
  Future<List<IntakeListItem>> lawyerListIntakes(AuthToken auth) async =>
      _parseList(await _call('lawyer_list_intakes', auth: auth),
          IntakeListItem.fromJson);

  Future<IntakeDoc> lawyerGetIntake(String name, AuthToken auth) async {
    final m = await _call(
      'lawyer_get_intake',
      method: 'POST',
      body: {'name': name},
      auth: auth,
    );
    if (m is! Map) {
      throw const ApiException(ApiErrorCode.server, 'empty response');
    }
    return IntakeDoc.fromJson(m.cast<String, dynamic>());
  }

  /// Creates a draft intake; returns the new document name.
  Future<String> lawyerCreateIntake(
    IntakeCreatePayload payload,
    AuthToken auth,
  ) async {
    final m = await _call(
      'lawyer_create_intake',
      method: 'POST',
      body: payload.toJson(),
      auth: auth,
    );
    if (m is! Map) {
      throw const ApiException(ApiErrorCode.server, 'empty response');
    }
    return (m['name'] as String?) ?? '';
  }

  Future<void> lawyerSubmitIntake(String name, AuthToken auth) async =>
      _call(
        'lawyer_submit_intake',
        method: 'POST',
        body: {'name': name},
        auth: auth,
      );

  Future<List<OfferListItem>> lawyerListOffers(AuthToken auth) async =>
      _parseList(await _call('lawyer_list_offers', auth: auth),
          OfferListItem.fromJson);

  Future<OfferDoc> lawyerGetOffer(String name, AuthToken auth) async {
    final m = await _call(
      'lawyer_get_offer',
      method: 'POST',
      body: {'name': name},
      auth: auth,
    );
    if (m is! Map) {
      throw const ApiException(ApiErrorCode.server, 'empty response');
    }
    return OfferDoc.fromJson(m.cast<String, dynamic>());
  }

  /// Creates a draft offer (Quotation); returns the new document name.
  Future<String> lawyerCreateOffer(
    OfferCreatePayload payload,
    AuthToken auth,
  ) async {
    final m = await _call(
      'lawyer_create_offer',
      method: 'POST',
      body: payload.toJson(),
      auth: auth,
    );
    if (m is! Map) {
      throw const ApiException(ApiErrorCode.server, 'empty response');
    }
    return (m['name'] as String?) ?? '';
  }

  Future<List<CustomerHit>> lawyerSearchCustomers(
    String q,
    AuthToken auth,
  ) async => _parseList(
        await _call(
          'lawyer_search_customers',
          method: 'POST',
          body: {'q': q},
          auth: auth,
        ),
        CustomerHit.fromJson,
      );

  Future<List<ItemHit>> lawyerSearchItems(
    String q,
    AuthToken auth, {
    String? itemGroup,
  }) async => _parseList(
        await _call(
          'lawyer_search_items',
          method: 'POST',
          body: {
            'q': q,
            if (itemGroup != null && itemGroup.isNotEmpty)
              'item_group': itemGroup,
          },
          auth: auth,
        ),
        ItemHit.fromJson,
      );

  Future<List<ItemGroupHit>> lawyerSearchItemGroups(
    String q,
    AuthToken auth,
  ) async => _parseList(
        await _call(
          'lawyer_search_item_groups',
          method: 'POST',
          body: {'q': q},
          auth: auth,
        ),
        ItemGroupHit.fromJson,
      );
}

// ─── Result/payload types ───

class SendOtpResult {
  final bool sent;
  final bool? registered;
  const SendOtpResult({required this.sent, this.registered});
}

class VerifyOtpResult {
  final bool ok;
  final String? apiKey;
  final String? apiSecret;
  final String? name;
  final String? fullName;
  final String? email;
  final String? mobileNo;
  final bool isLawyer;

  /// One of: expired | invalid | too_many_attempts
  final String? error;

  const VerifyOtpResult._({
    required this.ok,
    this.apiKey,
    this.apiSecret,
    this.name,
    this.fullName,
    this.email,
    this.mobileNo,
    this.isLawyer = false,
    this.error,
  });

  factory VerifyOtpResult.ok({
    required String apiKey,
    required String apiSecret,
    required String name,
    required String fullName,
    String? email,
    String? mobileNo,
    bool isLawyer = false,
  }) => VerifyOtpResult._(
    ok: true,
    apiKey: apiKey,
    apiSecret: apiSecret,
    name: name,
    fullName: fullName,
    email: email,
    mobileNo: mobileNo,
    isLawyer: isLawyer,
  );

  factory VerifyOtpResult.fail(String error) =>
      VerifyOtpResult._(ok: false, error: error);
}

class BookingPayload {
  final String fullName;
  final String phone;
  final String subject;
  final String? message;
  final String? lawyer;

  const BookingPayload({
    required this.fullName,
    required this.phone,
    required this.subject,
    this.message,
    this.lawyer,
  });

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'phone': phone,
    'subject': subject,
    if (message != null) 'message': message,
    if (lawyer != null) 'lawyer': lawyer,
  };
}

class JoinRequestPayload {
  final String fullName;
  final String phone;
  final int? graduationYear;
  final String? university;
  final String? currentJob;
  final String? idFileBase64;
  final String? idFilename;

  const JoinRequestPayload({
    required this.fullName,
    required this.phone,
    this.graduationYear,
    this.university,
    this.currentJob,
    this.idFileBase64,
    this.idFilename,
  });

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'phone': phone,
    if (graduationYear != null) 'graduation_year': graduationYear,
    if (university != null) 'university': university,
    if (currentJob != null) 'current_job': currentJob,
    if (idFileBase64 != null) 'id_file_base64': idFileBase64,
    if (idFilename != null) 'id_filename': idFilename,
  };
}

/// A legal case (backed by a Project). `status` is a stable Arabic CaseStatus
/// key; firm-managed fields the client doesn't track (type/court) are absent.
class RemoteCase {
  final String id;
  final String caseNumber;
  final String title;
  final String status;
  final String statusLabel;
  final String date;
  final String nextHearing;
  final String lawyerName;

  const RemoteCase({
    required this.id,
    required this.caseNumber,
    required this.title,
    required this.status,
    required this.statusLabel,
    required this.date,
    required this.nextHearing,
    required this.lawyerName,
  });

  factory RemoteCase.fromJson(Map<String, dynamic> j) => RemoteCase(
    id: j['id']?.toString() ?? '',
    caseNumber: j['caseNumber'] as String? ?? '',
    title: j['title'] as String? ?? '',
    status: j['status'] as String? ?? '',
    statusLabel: j['statusLabel'] as String? ?? '',
    date: j['date'] as String? ?? '',
    nextHearing: j['nextHearing'] as String? ?? '',
    lawyerName: j['lawyerName'] as String? ?? '',
  );
}

class AiMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  final String? imageBase64;
  final String? mimeType;

  const AiMessage({
    required this.role,
    required this.content,
    this.imageBase64,
    this.mimeType,
  });

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    if (imageBase64 != null) 'imageBase64': imageBase64,
    if (mimeType != null) 'mimeType': mimeType,
  };
}

class AiChatResult {
  final String? reply;
  final String? error;
  const AiChatResult({this.reply, this.error});
}
