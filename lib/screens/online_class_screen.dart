import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/api_service.dart';
import '../services/online_class_service.dart';
import '../widgets/whiteboard_canvas.dart';

class OnlineClassScreen extends StatefulWidget {
  final int sessionId;
  final String classTitle;

  const OnlineClassScreen({super.key, required this.sessionId, required this.classTitle});

  @override
  State<OnlineClassScreen> createState() => _OnlineClassScreenState();
}

class _OnlineClassScreenState extends State<OnlineClassScreen> with SingleTickerProviderStateMixin {
  final _service = OnlineClassService();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final Map<String, RTCVideoRenderer> _remoteRenderers = {};
  late final TabController _tabController;
  bool _joining = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _service.addListener(_onServiceUpdate);
    _init();
  }

  Future<void> _init() async {
    await _localRenderer.initialize();
    final user = await ApiService.currentUser;
    final role = user?['role'] ?? 'student';
    final wantsCamera = role == 'teacher' || role == 'manager' || role == 'admin';

    // توکن ورود کاربر رو از حافظه می‌خونیم تا سرور سیگنالینگ برای تاییدش به بک‌اند PHP بفرسته
    final token = await ApiService.rawToken;
    if (token == null) return;

    await _service.join(sessionId: widget.sessionId, token: token, wantsCamera: wantsCamera);
    if (_service.localStream != null) {
      _localRenderer.srcObject = _service.localStream;
    }
    setState(() => _joining = false);
  }

  void _onServiceUpdate() {
    // برای هر شرکت‌کننده‌ی جدید که استریمش رسیده، یه رندرر می‌سازیم
    for (final entry in _service.participants.entries) {
      if (entry.value.stream != null && !_remoteRenderers.containsKey(entry.key)) {
        final renderer = RTCVideoRenderer();
        renderer.initialize().then((_) {
          renderer.srcObject = entry.value.stream;
          if (mounted) setState(() => _remoteRenderers[entry.key] = renderer);
        });
      }
    }
    if (_service.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_service.errorMessage!)));
      _service.errorMessage = null;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    _service.leave();
    _localRenderer.dispose();
    for (final r in _remoteRenderers.values) r.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_joining) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0E17),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        title: Text(widget.classTitle),
        backgroundColor: const Color(0xFF10182B),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'کلاس'), Tab(text: 'تخته')],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_end_rounded, color: Colors.redAccent),
            tooltip: 'خروج از کلاس',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildVideoTab(), WhiteboardCanvas(service: _service)],
      ),
      bottomNavigationBar: _buildControlBar(),
    );
  }

  Widget _buildVideoTab() {
    final tiles = <Widget>[
      _videoTile(_localRenderer, 'شما', _service.camOpen, isLocal: true),
      for (final entry in _service.participants.entries)
        _videoTile(
          _remoteRenderers[entry.key],
          entry.value.fullName,
          entry.value.camOpen,
          handRaised: entry.value.handRaised,
          micOpen: entry.value.micOpen,
          onAllowUnmute: _service.isModerator && entry.value.handRaised
              ? () => _service.allowUnmute(entry.key)
              : null,
          onForceMute: _service.isModerator && entry.value.micOpen
              ? () => _service.forceMute(entry.key)
              : null,
        ),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.9,
      ),
      itemCount: tiles.length,
      itemBuilder: (context, i) => tiles[i],
    );
  }

  Widget _videoTile(
    RTCVideoRenderer? renderer,
    String name,
    bool camOpen, {
    bool isLocal = false,
    bool handRaised = false,
    bool micOpen = false,
    VoidCallback? onAllowUnmute,
    VoidCallback? onForceMute,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141B2E),
        borderRadius: BorderRadius.circular(16),
        border: handRaised ? Border.all(color: const Color(0xFFFFB020), width: 2) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (renderer != null && camOpen)
            RTCVideoView(renderer, mirror: isLocal, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
          else
            const Center(child: Icon(Icons.person_rounded, color: Colors.white24, size: 56)),
          Positioned(
            bottom: 8,
            right: 8,
            left: 8,
            child: Row(
              children: [
                Icon(micOpen ? Icons.mic_rounded : Icons.mic_off_rounded, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(name,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                ),
                if (handRaised) const Icon(Icons.back_hand_rounded, color: Color(0xFFFFB020), size: 18),
              ],
            ),
          ),
          if (onAllowUnmute != null || onForceMute != null)
            Positioned(
              top: 6,
              left: 6,
              child: Row(
                children: [
                  if (onAllowUnmute != null)
                    _miniButton(Icons.check_circle_rounded, Colors.greenAccent, onAllowUnmute, 'اجازه‌ی صحبت'),
                  if (onForceMute != null)
                    _miniButton(Icons.mic_off_rounded, Colors.redAccent, onForceMute, 'قطع میکروفون'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _miniButton(IconData icon, Color color, VoidCallback onTap, String tooltip) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildControlBar() {
    final isStudent = !_service.isModerator;

    return Container(
      color: const Color(0xFF10182B),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _controlButton(
              icon: _service.micOpen ? Icons.mic_rounded : Icons.mic_off_rounded,
              active: _service.micOpen,
              enabled: !isStudent || _service.micPermissionGranted,
              onTap: () => setState(() => _service.setMic(!_service.micOpen)),
            ),
            if (!isStudent)
              _controlButton(
                icon: _service.camOpen ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                active: _service.camOpen,
                onTap: () => setState(() => _service.setCam(!_service.camOpen)),
              ),
            if (!isStudent)
              _controlButton(
                icon: Icons.screen_share_rounded,
                active: _service.screenSharing,
                onTap: () => setState(() {
                  if (_service.screenSharing) {
                    _service.stopScreenShare();
                  } else {
                    _service.startScreenShare();
                  }
                }),
              ),
            if (isStudent)
              _controlButton(
                icon: Icons.back_hand_rounded,
                active: _service.handRaised,
                onTap: () => setState(() {
                  if (_service.handRaised) {
                    _service.lowerHand();
                  } else {
                    _service.raiseHand();
                  }
                }),
              ),
            _controlButton(
              icon: Icons.call_end_rounded,
              active: true,
              activeColor: Colors.redAccent,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required bool active,
    bool enabled = true,
    Color? activeColor,
    required VoidCallback onTap,
  }) {
    final color = !enabled ? Colors.white24 : (active ? (activeColor ?? const Color(0xFF2F5FFF)) : Colors.white10);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
