import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const SmartCityApp());

const teal = Color(0xFF0F766E);
const ink = Color(0xFF172B4D);

class SmartCityApp extends StatefulWidget {
  const SmartCityApp({super.key});
  @override
  State<SmartCityApp> createState() => _SmartCityAppState();
}

class _SmartCityAppState extends State<SmartCityApp> {
  bool dark = false;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartCity 360',
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: teal), useMaterial3: true, scaffoldBackgroundColor: const Color(0xFFF5F7FB)),
      darkTheme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: teal, brightness: Brightness.dark), useMaterial3: true),
      home: CityHome(dark: dark, onThemeChanged: (v) => setState(() => dark = v)),
    );
  }
}

class CityHome extends StatefulWidget {
  final bool dark;
  final ValueChanged<bool> onThemeChanged;
  const CityHome({super.key, required this.dark, required this.onThemeChanged});
  @override
  State<CityHome> createState() => _CityHomeState();
}

class _CityHomeState extends State<CityHome> {
  int page = 0;
  bool loading = true;
  String userName = 'Vyshnavi';
  String email = 'citizen@example.com';
  String area = 'Ward 12';
  String search = '';
  String statusFilter = 'All';
  List<Map<String, dynamic>> reports = [];
  List<Map<String, dynamic>> alerts = [];
  late SharedPreferences prefs;

  final navItems = const [
    (Icons.dashboard_rounded, 'Dashboard'),
    (Icons.assignment_outlined, 'Complaints'),
    (Icons.location_city_rounded, 'City Services'),
    (Icons.notifications_active_outlined, 'Alerts'),
    (Icons.person_outline_rounded, 'My Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    prefs = await SharedPreferences.getInstance();
    userName = prefs.getString('profile_name') ?? 'Vyshnavi';
    email = prefs.getString('profile_email') ?? 'citizen@example.com';
    area = prefs.getString('profile_area') ?? 'Ward 12';
    final rawReports = prefs.getString('city_reports');
    final rawAlerts = prefs.getString('city_alerts');
    if (rawReports != null) {
      reports = List<Map<String, dynamic>>.from((jsonDecode(rawReports) as List).map((e) => Map<String, dynamic>.from(e)));
    } else {
      reports = [
        _report('Streetlight not working', 'Electricity', 'In Progress', 'SC-1001', 'Light near the community park is off.'),
        _report('Overflowing public bin', 'Waste', 'Submitted', 'SC-1002', 'Bin near the bus stop needs collection.'),
        _report('Pothole on main road', 'Roads', 'Resolved', 'SC-1003', 'Pothole repaired near the market.'),
      ];
    }
    if (rawAlerts != null) {
      alerts = List<Map<String, dynamic>>.from((jsonDecode(rawAlerts) as List).map((e) => Map<String, dynamic>.from(e)));
    } else {
      alerts = [
        {'id': 'AL-01', 'title': 'Water supply maintenance', 'category': 'Water', 'message': 'Water supply may be interrupted from 2 PM to 4 PM in Ward 12.', 'time': 'Today'},
        {'id': 'AL-02', 'title': 'Road diversion near market', 'category': 'Transport', 'message': 'Please use the east road while maintenance work is in progress.', 'time': 'Today'},
      ];
    }
    if (mounted) setState(() => loading = false);
  }

  Map<String, dynamic> _report(String title, String category, String status, String id, String details) => {
    'id': id, 'title': title, 'category': category, 'status': status, 'details': details,
    'date': DateTime.now().toString().substring(0, 16),
  };

  Future<void> _saveReports() async => prefs.setString('city_reports', jsonEncode(reports));
  Future<void> _saveAlerts() async => prefs.setString('city_alerts', jsonEncode(alerts));
  int get openCount => reports.where((r) => r['status'] != 'Resolved').length;
  int get resolvedCount => reports.where((r) => r['status'] == 'Resolved').length;

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final wide = MediaQuery.sizeOf(context).width >= 850;
    return Scaffold(
      body: Row(children: [
        if (wide) _sidebar(),
        Expanded(child: Column(children: [
          _topBar(wide),
          Expanded(child: _pageBody(key: ValueKey(page))),
        ])),
      ]),
      bottomNavigationBar: wide ? null : NavigationBar(selectedIndex: page, onDestinationSelected: (i) => setState(() => page = i), destinations: navItems.map((n) => NavigationDestination(icon: Icon(n.$1), label: n.$2)).toList()),
    );
  }

  Widget _sidebar() => Container(
    width: 250,
    color: Theme.of(context).colorScheme.surface,
    padding: const EdgeInsets.fromLTRB(18, 24, 14, 18),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: teal, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.location_city, color: Colors.white)), const SizedBox(width: 10), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('SmartCity 360', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), Text('CITIZEN PORTAL', style: TextStyle(fontSize: 10, letterSpacing: 1.4, color: teal, fontWeight: FontWeight.w700))]))]),
      const SizedBox(height: 34),
      const Padding(padding: EdgeInsets.only(left: 12, bottom: 10), child: Text('WORKSPACE', style: TextStyle(fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.bold, color: Colors.grey))),
      ...List.generate(navItems.length, (i) {
        final n = navItems[i];
        final selected = page == i;
        return Padding(padding: const EdgeInsets.only(bottom: 5), child: ListTile(leading: Icon(n.$1, color: selected ? teal : null), title: Text(n.$2, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500, fontSize: 13)), selected: selected, selectedTileColor: teal.withOpacity(.10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), onTap: () => setState(() => page = i)));
      }),
      const Spacer(),
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: teal.withOpacity(.09), borderRadius: BorderRadius.circular(16)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.support_agent, color: teal, size: 26), SizedBox(height: 8), Text('Need help?', style: TextStyle(fontWeight: FontWeight.bold)), SizedBox(height: 4), Text('Use emergency information in City Services.', style: TextStyle(fontSize: 11, color: Colors.grey))])),
      const SizedBox(height: 12),
      ListTile(dense: true, leading: CircleAvatar(backgroundColor: teal.withOpacity(.15), child: Text(userName.isEmpty ? 'C' : userName[0].toUpperCase(), style: const TextStyle(color: teal))), title: Text(userName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), subtitle: Text(area, style: const TextStyle(fontSize: 11)), trailing: IconButton(tooltip: 'Edit profile', icon: const Icon(Icons.edit_outlined, size: 18), onPressed: _editProfile)),
    ]),
  );

  Widget _topBar(bool wide) => Container(padding: EdgeInsets.fromLTRB(wide ? 28 : 16, 18, 20, 14), child: Row(children: [
    if (!wide) const Icon(Icons.location_city, color: teal, size: 28),
    if (!wide) const SizedBox(width: 8),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_heading(), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)), Text('Your city, connected and responsive', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant))])),
    IconButton(tooltip: widget.dark ? 'Switch to light mode' : 'Switch to dark mode', onPressed: () => widget.onThemeChanged(!widget.dark), icon: Icon(widget.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined)),
    const SizedBox(width: 4),
    CircleAvatar(backgroundColor: teal.withOpacity(.13), child: Text(userName.isEmpty ? 'C' : userName[0].toUpperCase(), style: const TextStyle(color: teal, fontWeight: FontWeight.bold))),
  ]));

  String _heading() => page == 0 ? 'Good day, $userName 👋' : navItems[page].$2;

  Widget _pageBody({required Key key}) => SingleChildScrollView(key: key, padding: const EdgeInsets.fromLTRB(22, 8, 22, 28), child: switch (page) {
    0 => _dashboard(),
    1 => _complaintsPage(),
    2 => _servicesPage(),
    3 => _alertsPage(),
    _ => _profilePage(),
  });

  Widget _dashboard() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF155E75)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(22)), child: LayoutBuilder(builder: (context, c) => Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('MAKE YOUR CITY BETTER', style: TextStyle(color: Color(0xFFB9F3E8), fontSize: 10, letterSpacing: 1.6, fontWeight: FontWeight.bold)), const SizedBox(height: 10), const Text('A better city starts\nwith your voice.', style: TextStyle(color: Colors.white, fontSize: 25, height: 1.15, fontWeight: FontWeight.w800)), const SizedBox(height: 10), const Text('Report local issues and follow progress from one place.', style: TextStyle(color: Colors.white70, fontSize: 12)), const SizedBox(height: 18), FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: teal), onPressed: _addComplaint, icon: const Icon(Icons.add), label: const Text('Report an issue'))])), if (c.maxWidth > 360) const Padding(padding: EdgeInsets.only(left: 12), child: Icon(Icons.apartment_rounded, size: 95, color: Color(0x55FFFFFF)))]))),
    const SizedBox(height: 22),
    LayoutBuilder(builder: (context, c) { final count = c.maxWidth > 900 ? 4 : c.maxWidth > 520 ? 2 : 2; final items = [ _stat('Total complaints', '${reports.length}', Icons.assignment_outlined, const Color(0xFF2563EB)), _stat('Needs attention', '$openCount', Icons.pending_actions, const Color(0xFFD97706)), _stat('Resolved', '$resolvedCount', Icons.task_alt, const Color(0xFF0F9D78)), _stat('City alerts', '${alerts.length}', Icons.notifications_active_outlined, const Color(0xFF7C3AED))]; return GridView.count(crossAxisCount: count, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: c.maxWidth < 450 ? 1.55 : 1.9, children: items); }),
    const SizedBox(height: 24),
    Row(children: [const Expanded(child: Text('Quick services', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))), TextButton(onPressed: () => setState(() => page = 2), child: const Text('View all'))]),
    const SizedBox(height: 10),
    LayoutBuilder(builder: (context, c) { final cross = c.maxWidth > 700 ? 4 : c.maxWidth > 430 ? 3 : 2; final services = _serviceData(); return GridView.count(crossAxisCount: cross, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.25, children: services.take(4).map((s) => _serviceTile(s, compact: true)).toList()); }),
    const SizedBox(height: 24),
    Row(children: [const Expanded(child: Text('Recent complaints', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))), TextButton(onPressed: () => setState(() => page = 1), child: const Text('Manage reports'))]),
    const SizedBox(height: 10),
    _recentReports(),
  ]);

  Widget _stat(String title, String value, IconData icon, Color color) => Card(child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 19)), const Spacer(), Icon(Icons.trending_up, color: color, size: 16)]), const Spacer(), Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)), Text(title, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant))])));

  Widget _recentReports() {
    if (reports.isEmpty) return _empty('No complaints yet', 'Submit an issue and it will appear here.', Icons.assignment_outlined);
    return Card(child: Column(children: reports.take(4).map((r) => _reportTile(r, showActions: false)).toList()));
  }

  Widget _complaintsPage() {
    final filtered = reports.where((r) {
      final matchesSearch = '${r['title']} ${r['category']} ${r['id']}'.toLowerCase().contains(search.toLowerCase());
      final matchesStatus = statusFilter == 'All' || r['status'] == statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _pageIntro('Track and manage your civic issues.', Icons.assignment_turned_in_outlined, FilledButton.icon(onPressed: _addComplaint, icon: const Icon(Icons.add), label: const Text('New complaint'))),
      const SizedBox(height: 18),
      TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search by title, category or ID', border: OutlineInputBorder(), filled: true), onChanged: (v) => setState(() => search = v)),
      const SizedBox(height: 12),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['All', 'Submitted', 'In Progress', 'Resolved'].map((s) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(s),
                selected: statusFilter == s,
                onSelected: (_) => setState(() => statusFilter = s),
              ),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 12),
      if (filtered.isEmpty) _empty('No matching complaints', 'Try another filter or create a new complaint.', Icons.search_off) else Card(child: Column(children: filtered.map((r) => _reportTile(r, showActions: true)).toList())),
    ]);
  }

  Widget _reportTile(Map<String, dynamic> r, {required bool showActions}) {
    final status = r['status'] as String;
    final color = status == 'Resolved' ? const Color(0xFF0F9D78) : status == 'In Progress' ? const Color(0xFFD97706) : const Color(0xFF2563EB);
    return Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(.55)))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 42, height: 42, decoration: BoxDecoration(color: teal.withOpacity(.10), borderRadius: BorderRadius.circular(12)), child: Icon(_categoryIcon(r['category'] as String), color: teal)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r['title'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), const SizedBox(height: 4), Text('${r['category']} • ${r['id']}', style: const TextStyle(fontSize: 11, color: Colors.grey)), if ((r['details'] as String? ?? '').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 5), child: Text(r['details'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))), const SizedBox(height: 8), Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(20)), child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))), Text(r['date'] as String? ?? '', style: const TextStyle(fontSize: 10, color: Colors.grey))])])),
      if (showActions) PopupMenuButton<String>(tooltip: 'Complaint actions', onSelected: (v) => v == 'delete' ? _deleteReport(r) : _changeStatus(r, v), itemBuilder: (_) => [const PopupMenuItem(value: 'Submitted', child: Text('Mark Submitted')), const PopupMenuItem(value: 'In Progress', child: Text('Mark In Progress')), const PopupMenuItem(value: 'Resolved', child: Text('Mark Resolved')), const PopupMenuDivider(), const PopupMenuItem(value: 'delete', child: Text('Delete complaint'))]),
    ]));
  }

  Widget _servicesPage() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _pageIntro('Find essential services and useful city information.', Icons.location_city, null),
    const SizedBox(height: 20),
    LayoutBuilder(builder: (context, c) { final cross = c.maxWidth > 800 ? 4 : c.maxWidth > 500 ? 3 : 2; return GridView.count(crossAxisCount: cross, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.15, children: _serviceData().map((s) => _serviceTile(s)).toList()); }),
    const SizedBox(height: 20),
    Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Row(children: [Icon(Icons.emergency_outlined, color: Color(0xFFDC2626)), SizedBox(width: 8), Text('Emergency information', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))]), const SizedBox(height: 12), _emergencyLine('Emergency response', '112', Icons.phone), _emergencyLine('Fire and rescue', '101', Icons.local_fire_department_outlined), _emergencyLine('Ambulance', '108', Icons.medical_services_outlined), const SizedBox(height: 8), const Text('For immediate danger, contact local emergency services directly.', style: TextStyle(color: Colors.grey, fontSize: 11))]))),
  ]);

  List<Map<String, dynamic>> _serviceData() => [
    {'title': 'Roads & Traffic', 'subtitle': 'Road repairs and traffic updates', 'icon': Icons.traffic, 'color': const Color(0xFF2563EB)},
    {'title': 'Waste Collection', 'subtitle': 'Collection and sanitation', 'icon': Icons.delete_sweep_outlined, 'color': const Color(0xFF0F9D78)},
    {'title': 'Water Supply', 'subtitle': 'Supply and leakage issues', 'icon': Icons.water_drop_outlined, 'color': const Color(0xFF0891B2)},
    {'title': 'Electricity', 'subtitle': 'Streetlights and power issues', 'icon': Icons.bolt_outlined, 'color': const Color(0xFFD97706)},
    {'title': 'Public Transport', 'subtitle': 'Bus and public transport', 'icon': Icons.directions_bus_outlined, 'color': const Color(0xFF7C3AED)},
    {'title': 'Healthcare', 'subtitle': 'Clinics and public health', 'icon': Icons.health_and_safety_outlined, 'color': const Color(0xFFDB2777)},
    {'title': 'Parks & Public Spaces', 'subtitle': 'Parks and community spaces', 'icon': Icons.park_outlined, 'color': const Color(0xFF15803D)},
    {'title': 'Emergency Help', 'subtitle': 'Important emergency numbers', 'icon': Icons.sos_outlined, 'color': const Color(0xFFDC2626)},
  ];

  Widget _serviceTile(Map<String, dynamic> s, {bool compact = false}) {
    final color = s['color'] as Color;
    return Card(child: InkWell(borderRadius: BorderRadius.circular(16), onTap: () => _openService(s), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(12)), child: Icon(s['icon'] as IconData, color: color)), const Spacer(), Text(s['title'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)), if (!compact) Padding(padding: const EdgeInsets.only(top: 4), child: Text(s['subtitle'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.grey))), const SizedBox(height: 6), Row(children: [Text('View details', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)), const Spacer(), Icon(Icons.arrow_forward, size: 14, color: color)])]))));
  }

  void _openService(Map<String, dynamic> s) {
    final title = s['title'] as String;
    if (title == 'Emergency Help') {
      showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Emergency help'), content: const Column(mainAxisSize: MainAxisSize.min, children: [ListTile(leading: Icon(Icons.phone), title: Text('Emergency response'), trailing: Text('112')), ListTile(leading: Icon(Icons.local_fire_department), title: Text('Fire and rescue'), trailing: Text('101')), ListTile(leading: Icon(Icons.medical_services), title: Text('Ambulance'), trailing: Text('108'))]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))]));
      return;
    }
    showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: Text(title), content: Text('${s['subtitle']}\n\nIf you notice an issue related to this service, you can create a complaint and select the matching category.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')), FilledButton(onPressed: () { Navigator.pop(ctx); _addComplaint(preselected: title.contains('Road') ? 'Roads' : title.contains('Waste') ? 'Waste' : title.contains('Water') ? 'Water' : title.contains('Electricity') ? 'Electricity' : title.contains('Transport') ? 'Transport' : 'Other'); }, child: const Text('Report an issue'))]));
  }

  Widget _alertsPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _pageIntro(
        'Important announcements for your neighbourhood.',
        Icons.notifications_active_outlined,
        FilledButton.icon(onPressed: _addAlert, icon: const Icon(Icons.add), label: const Text('Create alert')),
      ),
      const SizedBox(height: 18),
      if (alerts.isEmpty)
        _empty('No city alerts', 'Create an alert to share an announcement.', Icons.notifications_none)
      else
        ...alerts.map((a) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: const Color(0xFF7C3AED).withOpacity(.12), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.campaign_outlined, color: Color(0xFF7C3AED)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a['title'] as String, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('${a['category']} • ${a['time']}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      const SizedBox(height: 8),
                      Text(a['message'] as String, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(tooltip: 'Delete alert', onPressed: () => _deleteAlert(a), icon: const Icon(Icons.delete_outline, color: Colors.redAccent)),
              ],
            ),
          ),
        )),
    ],
  );

  Widget _profilePage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _pageIntro('Keep your citizen details up to date.', Icons.person_outline, FilledButton.icon(onPressed: _editProfile, icon: const Icon(Icons.edit_outlined), label: const Text('Edit profile'))),
      const SizedBox(height: 20),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              CircleAvatar(radius: 42, backgroundColor: teal.withOpacity(.14), child: Text(userName.isEmpty ? 'C' : userName[0].toUpperCase(), style: const TextStyle(fontSize: 32, color: teal, fontWeight: FontWeight.bold))),
              const SizedBox(height: 14),
              Text(userName, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
              Text(area, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 22),
              const Divider(),
              _profileRow(Icons.mail_outline, 'Email address', email),
              _profileRow(Icons.location_on_outlined, 'Ward / Area', area),
              _profileRow(Icons.verified_user_outlined, 'Account type', 'Citizen'),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _editProfile, icon: const Icon(Icons.edit_outlined), label: const Text('Edit my details'))),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Card(child: SwitchListTile(value: widget.dark, onChanged: widget.onThemeChanged, secondary: const Icon(Icons.dark_mode_outlined), title: const Text('Dark mode', style: TextStyle(fontWeight: FontWeight.w700)), subtitle: const Text('Change the app appearance'))),
    ],
  );

  Widget _profileRow(IconData icon, String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(children: [Icon(icon, color: teal), const SizedBox(width: 12), Expanded(child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))), Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)))]));

  Widget _pageIntro(String subtitle, IconData icon, Widget? action) => Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: teal.withOpacity(.1), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: teal)), const SizedBox(width: 12), Expanded(child: Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant))), if (action != null) action]);

  Widget _empty(String title, String message, IconData icon) => Card(child: Padding(padding: const EdgeInsets.all(30), child: Center(child: Column(children: [Icon(icon, size: 38, color: Colors.grey), const SizedBox(height: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12))]))));

  Widget _emergencyLine(String title, String number, IconData icon) => ListTile(contentPadding: EdgeInsets.zero, leading: Icon(icon, color: teal), title: Text(title, style: const TextStyle(fontSize: 13)), trailing: Text(number, style: const TextStyle(fontWeight: FontWeight.bold)));

  IconData _categoryIcon(String category) => switch (category) { 'Roads' => Icons.traffic, 'Electricity' => Icons.bolt, 'Waste' => Icons.delete_outline, 'Water' => Icons.water_drop_outlined, 'Transport' => Icons.directions_bus_outlined, _ => Icons.report_problem_outlined };

  Future<void> _addComplaint({String preselected = 'Roads'}) async {
    final titleController = TextEditingController();
    final detailController = TextEditingController();
    String category = ['Roads', 'Electricity', 'Waste', 'Water', 'Transport', 'Other'].contains(preselected) ? preselected : 'Other';

    // Keep the dialog self-contained. Return values first, then update the page
    // only after the dialog route has completely closed.
    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Report a city issue'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Issue title',
                      hintText: 'e.g. Pothole near bus stop',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    items: const ['Roads', 'Electricity', 'Waste', 'Water', 'Transport', 'Other']
                        .map((value) => DropdownMenuItem<String>(value: value, child: Text(value)))
                        .toList(),
                    onChanged: (value) => setDialogState(() => category = value ?? 'Roads'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: detailController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'Describe where the issue is and what happened',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.send_outlined),
              label: const Text('Submit complaint'),
              onPressed: () {
                final issueTitle = titleController.text.trim();
                if (issueTitle.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Please enter an issue title.')),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop({
                  'title': issueTitle,
                  'category': category,
                  'details': detailController.text.trim(),
                });
              },
            ),
          ],
        ),
      ),
    );

    titleController.dispose();
    detailController.dispose();
    if (result == null || !mounted) return;

    final id = 'SC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    setState(() {
      reports.insert(0, _report(result['title']!, result['category']!, 'Submitted', id, result['details']!));
      page = 1;
      statusFilter = 'All';
      search = '';
    });
    await _saveReports();
    if (mounted) _toast('Complaint submitted successfully');
  }

  Future<void> _changeStatus(Map<String, dynamic> report, String status) async {
    setState(() => report['status'] = status);
    await _saveReports();
    _toast('Complaint status updated to $status');
  }

  Future<void> _deleteReport(Map<String, dynamic> report) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete complaint?'), content: Text('Delete "${report['title']}"? This cannot be undone.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete'))]));
    if (ok == true) { setState(() => reports.removeWhere((r) => r['id'] == report['id'])); await _saveReports(); _toast('Complaint deleted'); }
  }

  Future<void> _addAlert() async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String category = 'General';
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Create city alert'),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(controller: titleController, decoration: const InputDecoration(labelText: 'Alert title'), validator: (v) => v == null || v.trim().isEmpty ? 'Enter an alert title' : null),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: ['General', 'Roads', 'Water', 'Electricity', 'Transport', 'Weather'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                    onChanged: (v) => setDialog(() => category = v ?? 'General'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(controller: messageController, maxLines: 3, decoration: const InputDecoration(labelText: 'Message'), validator: (v) => v == null || v.trim().isEmpty ? 'Enter an alert message' : null),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                setState(() {
                  alerts.insert(0, {'id': 'AL-${DateTime.now().millisecondsSinceEpoch}', 'title': titleController.text.trim(), 'category': category, 'message': messageController.text.trim(), 'time': 'Just now'});
                });
                await _saveAlerts();
                if (ctx.mounted) Navigator.pop(ctx);
                _toast('City alert added');
              },
              child: const Text('Add alert'),
            ),
          ],
        ),
      ),
    );
    titleController.dispose();
    messageController.dispose();
  }

  Future<void> _deleteAlert(Map<String, dynamic> alert) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete alert?'), content: Text('Delete "${alert['title']}"?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete'))]));
    if (ok == true) { setState(() => alerts.removeWhere((a) => a['id'] == alert['id'])); await _saveAlerts(); _toast('Alert deleted'); }
  }

  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: userName);
    final emailController = TextEditingController(text: email);
    final areaController = TextEditingController(text: area);
    final formKey = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit profile'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Full name'), validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null),
                const SizedBox(height: 12),
                TextFormField(controller: emailController, decoration: const InputDecoration(labelText: 'Email address'), validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null),
                const SizedBox(height: 12),
                TextFormField(controller: areaController, decoration: const InputDecoration(labelText: 'Ward / Area'), validator: (v) => v == null || v.trim().isEmpty ? 'Area is required' : null),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              setState(() {
                userName = nameController.text.trim();
                email = emailController.text.trim();
                area = areaController.text.trim();
              });
              await prefs.setString('profile_name', userName);
              await prefs.setString('profile_email', email);
              await prefs.setString('profile_area', area);
              if (ctx.mounted) Navigator.pop(ctx);
              _toast('Profile saved');
            },
            child: const Text('Save changes'),
          ),
        ],
      ),
    );
    nameController.dispose();
    emailController.dispose();
    areaController.dispose();
  }

}
