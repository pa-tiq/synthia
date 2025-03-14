import 'package:flutter/material.dart';
import '../services/summarization_service.dart';

class ApiDebugWidget extends StatefulWidget {
  const ApiDebugWidget({super.key});

  @override
  _ApiDebugWidgetState createState() => _ApiDebugWidgetState();
}

class _ApiDebugWidgetState extends State<ApiDebugWidget> {
  final SummarizationService _service = SummarizationService();
  bool _isChecking = false;
  String _statusMessage = 'Not checked yet';
  bool _isConnected = false;

  Future<void> _checkApiConnection() async {
    setState(() {
      _isChecking = true;
      _statusMessage = 'Checking connection...';
    });

    try {
      final isHealthy = await _service.checkApiHealth();

      setState(() {
        _isChecking = false;
        _isConnected = isHealthy;
        _statusMessage =
            isHealthy ? 'Connected to API ✓' : 'Could not connect to API ✗';
      });
    } catch (e) {
      setState(() {
        _isChecking = false;
        _isConnected = false;
        _statusMessage = 'Error checking API: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bug_report),
                const SizedBox(width: 8),
                const Text(
                  'API Connection Debug',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                if (_isConnected)
                  const Icon(Icons.check_circle, color: Colors.green)
                else
                  const Icon(Icons.error, color: Colors.red),
              ],
            ),
            const Divider(),
            Text('Status: $_statusMessage'),
            const SizedBox(height: 8),
            Text('API URL: ${_service.apiUrl}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isChecking ? null : _checkApiConnection,
              child:
                  _isChecking
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Check API Connection'),
            ),
          ],
        ),
      ),
    );
  }
}
