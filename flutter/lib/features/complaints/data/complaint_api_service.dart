import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import 'complaint_models.dart';

class ComplaintApiService {
  final String baseUrl = ApiConfig.baseUrl;

  // Helper method to get auth headers
  Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ============= COMPLAINT ENDPOINTS =============

  /// Get all complaints (filtered by role on backend)
  Future<List<Complaint>> getComplaints(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/complaints/'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Complaint.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load complaints: ${response.body}');
    }
  }

  /// Get complaint details by ID
  Future<Complaint> getComplaintDetail(String token, int complaintId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/complaints/$complaintId/'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return Complaint.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load complaint details: ${response.body}');
    }
  }

  /// Create new complaint (consumer only)
  Future<Complaint> createComplaint(
    String token,
    CreateComplaintRequest request,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/complaints/'),
      headers: _getHeaders(token),
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 201) {
      return Complaint.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create complaint: ${response.body}');
    }
  }

  /// Update complaint status (supplier staff only)
  Future<Map<String, dynamic>> updateComplaintStatus(
    String token,
    int complaintId,
    UpdateComplaintStatusRequest request,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/complaints/$complaintId/status/'),
      headers: _getHeaders(token),
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update complaint status: ${response.body}');
    }
  }

  /// Escalate complaint to next level
  Future<Map<String, dynamic>> escalateComplaint(
    String token,
    int complaintId,
    EscalateComplaintRequest request,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/complaints/$complaintId/escalate/'),
      headers: _getHeaders(token),
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to escalate complaint: ${response.body}');
    }
  }

  // ============= COMPLAINT RESPONSE ENDPOINTS =============

  /// Get responses for a complaint
  Future<List<ComplaintResponse>> getComplaintResponses(
    String token,
    int complaintId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/complaints/$complaintId/responses/'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ComplaintResponse.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load responses: ${response.body}');
    }
  }

  /// Add response to complaint
  Future<ComplaintResponse> createComplaintResponse(
    String token,
    int complaintId,
    CreateComplaintResponseRequest request,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/complaints/$complaintId/responses/create/'),
      headers: _getHeaders(token),
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 201) {
      return ComplaintResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create response: ${response.body}');
    }
  }

  // ============= INCIDENT ENDPOINTS =============

  /// Get all incidents
  Future<List<Incident>> getIncidents(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/incidents/'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Incident.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load incidents: ${response.body}');
    }
  }

  /// Get incident details by ID
  Future<Incident> getIncidentDetail(String token, int incidentId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/incidents/$incidentId/'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return Incident.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load incident details: ${response.body}');
    }
  }

  /// Create incident (manager/owner only)
  Future<Incident> createIncident(
    String token,
    Map<String, dynamic> incidentData,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/incidents/'),
      headers: _getHeaders(token),
      body: json.encode(incidentData),
    );

    if (response.statusCode == 201) {
      return Incident.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create incident: ${response.body}');
    }
  }

  /// Update incident status (manager/owner only)
  Future<Map<String, dynamic>> updateIncidentStatus(
    String token,
    int incidentId,
    String status,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/incidents/$incidentId/status/'),
      headers: _getHeaders(token),
      body: json.encode({'status': status}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update incident status: ${response.body}');
    }
  }

  // ============= HELPER METHODS =============

  /// Get filtered complaints by status
  Future<List<Complaint>> getComplaintsByStatus(
    String token,
    String status,
  ) async {
    final complaints = await getComplaints(token);
    return complaints.where((c) => c.status == status).toList();
  }

  /// Get filtered complaints by escalation level
  Future<List<Complaint>> getComplaintsByEscalationLevel(
    String token,
    String level,
  ) async {
    final complaints = await getComplaints(token);
    return complaints.where((c) => c.escalationLevel == level).toList();
  }

  /// Get open complaints count
  Future<int> getOpenComplaintsCount(String token) async {
    final complaints = await getComplaints(token);
    return complaints.where((c) => c.status == 'open').length;
  }

  /// Get escalated complaints count
  Future<int> getEscalatedComplaintsCount(String token) async {
    final complaints = await getComplaints(token);
    return complaints
        .where((c) => c.escalationLevel != 'sales')
        .length;
  }
}
