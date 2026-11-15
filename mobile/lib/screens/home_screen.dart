
import 'package:material_ui/material_ui.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onLogout;

  const HomeScreen({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> errands = [];
  bool isLoading = false;

  bool get isRequester => widget.user['role'] == 'REQUESTER';

  @override
  void initState() {
    super.initState();
    loadErrands();
  }

  Future<void> loadErrands() async {
    setState(() => isLoading = true);

    try {
      final result = await ApiService.getErrands(
        isRequester ? 'my' : 'open',
      );

      if (!mounted) return;

      setState(() {
        errands = result;
      });
    } catch (e) {
      showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> createErrand() async {
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController();
    final description = TextEditingController();
    final pickup = TextEditingController();
    final dropoff = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Create New Errand'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  field(title, 'Title'),
                  field(description, 'Description'),
                  field(pickup, 'Pickup Address'),
                  field(dropoff, 'Drop-off Address'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await ApiService.createErrand({
          'title': title.text.trim(),
          'description': description.text.trim(),
          'pickupAddress': pickup.text.trim(),
          'dropoffAddress': dropoff.text.trim(),
        });

        showMessage('Errand created successfully');
        await loadErrands();
      } catch (e) {
        showMessage(e.toString().replaceFirst('Exception: ', ''));
      }
    }

    title.dispose();
    description.dispose();
    pickup.dispose();
    dropoff.dispose();
  }

  Widget field(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().length < 3) {
            return 'Enter at least 3 characters';
          }
          return null;
        },
      ),
    );
  }

  Future<void> acceptErrand(String id) async {
    try {
      await ApiService.acceptErrand(id);
      showMessage('Errand accepted!');
      await loadErrands();
    } catch (e) {
      showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> cancelErrand(String id) async {
    try {
      await ApiService.cancelErrand(id);
      showMessage('Errand cancelled');
      await loadErrands();
    } catch (e) {
      showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> updateErrandStatus(
    String id,
    String status,
  ) async {
    try {
      await ApiService.updateStatus(id, status);
      showMessage('Status updated to $status');
      await loadErrands();
    } catch (e) {
      showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> showRunnerErrands() async {
    setState(() => isLoading = true);

    try {
      final result = await ApiService.getErrands('accepted');

      if (!mounted) return;

      setState(() {
        errands = result;
      });
    } catch (e) {
      showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget buildErrandCard(Map<String, dynamic> errand) {
    final status = errand['status']?.toString() ?? 'OPEN';
    final id = errand['id'].toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              errand['title'] ?? 'Untitled Errand',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(errand['description'] ?? ''),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Pickup: ${errand['pickupAddress']}'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.flag, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Drop-off: ${errand['dropoffAddress']}'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Chip(
              label: Text(status.replaceAll('_', ' ')),
              backgroundColor: status == 'COMPLETED'
                  ? Colors.green.shade100
                  : status == 'CANCELLED'
                      ? Colors.red.shade100
                      : Colors.indigo.shade100,
            ),
            const SizedBox(height: 8),

            if (isRequester && status == 'OPEN')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => cancelErrand(id),
                  child: const Text('Cancel Errand'),
                ),
              ),

            if (!isRequester && status == 'OPEN')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => acceptErrand(id),
                  child: const Text('Accept Errand'),
                ),
              ),

            if (!isRequester && status == 'ACCEPTED')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      updateErrandStatus(id, 'IN_PROGRESS'),
                  child: const Text('Start Errand'),
                ),
              ),

            if (!isRequester && status == 'IN_PROGRESS')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      updateErrandStatus(id, 'COMPLETED'),
                  child: const Text('Mark Completed'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(
          isRequester ? 'Requester Dashboard' : 'Runner Dashboard',
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: loadErrands,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: isRequester
          ? FloatingActionButton.extended(
              onPressed: createErrand,
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('New Errand'),
            )
          : null,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            color: Colors.indigo.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${widget.user['name']}!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isRequester
                      ? 'Manage your errand requests.'
                      : 'Find and complete available errands.',
                ),
              ],
            ),
          ),

          if (!isRequester)
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: showRunnerErrands,
                  icon: const Icon(Icons.assignment_turned_in),
                  label: const Text('My Accepted Errands'),
                ),
              ),
            ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errands.isEmpty
                    ? Center(
                        child: Text(
                          isRequester
                              ? 'No errands created yet.'
                              : 'No errands available.',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: loadErrands,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: errands.length,
                          itemBuilder: (context, index) {
                            return buildErrandCard(
                              Map<String, dynamic>.from(errands[index]),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
