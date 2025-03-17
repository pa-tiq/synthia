enum JobStatus { idle, queued, processing, completed, failed }

class JobStatusModel {
  final JobStatus status;
  final String jobId;
  final String? summary;
  final String? error;

  JobStatusModel({
    required this.status,
    required this.jobId,
    this.summary,
    this.error,
  });

  factory JobStatusModel.fromJson(Map<String, dynamic> json) {
    return JobStatusModel(
      status: _parseJobStatus(json['status']),
      jobId: json['job_id'],
      summary: json['summary'],
      error: json['error'],
    );
  }

  static JobStatus _parseJobStatus(String status) {
    switch (status) {
      case 'queued':
        return JobStatus.queued;
      case 'processing':
        return JobStatus.processing;
      case 'completed':
        return JobStatus.completed;
      case 'failed':
        return JobStatus.failed;
      default:
        return JobStatus.failed; // Or handle as needed
    }
  }
}
