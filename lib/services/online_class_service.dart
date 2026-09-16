import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// آدرس سرور سیگنالینگ (VPS). بعد از دیپلوی، این رو با آدرس واقعی عوض کنید.
const String kSignalingUrl = 'https://realtime.nexa-school.ir';

class RemoteParticipant {
  final String socketId;
  final int userId;
  final String fullName;
  final String role; // admin | manager | teacher | student
  final String roleInRoom; // host | moderator | participant
  bool micOpen;
  bool camOpen;
  bool handRaised;
  MediaStream? stream;

  RemoteParticipant({
    required this.socketId,
    required this.userId,
    required this.fullName,
    required this.role,
    required this.roleInRoom,
    this.micOpen = false,
    this.camOpen = false,
    this.handRaised = false,
    this.stream,
  });

  bool get isModerator => roleInRoom == 'host' || roleInRoom == 'moderator';
}

/// همه‌ی منطق کلاس آنلاین: اتصال سوکت، peer connection ها، تخته، دست‌بالا.
/// UI فقط به این کلاس گوش می‌ده (ChangeNotifier) و دستورها رو صداش می‌زنه.
class OnlineClassService extends ChangeNotifier {
  io.Socket? _socket;
  MediaStream? localStream;
  MediaStream? screenStream;

  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, RemoteParticipant> participants = {};

  String? mySocketId;
  String roleInRoom = 'participant'; // host | moderator | participant
  bool get isModerator => roleInRoom == 'host' || roleInRoom == 'moderator';

  bool micOpen = false;
  bool camOpen = false;
  bool screenSharing = false;
  bool handRaised = false;
  bool micPermissionGranted = false; // برای دانش‌آموز: معلم اجازه‌ی باز کردن میکروفون داده یا نه
  String whiteboardColor = '#1B3358';
  bool connected = false;
  String? errorMessage;

  /// هر ضربه‌ی قلم روی تخته که از بقیه می‌رسه، اینجا اضافه می‌شه؛ UI باهاش رسم می‌کنه
  final List<Map<String, dynamic>> whiteboardStrokes = [];
  final StreamController<void> whiteboardClearedController = StreamController.broadcast();

  static const _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      // اگه TURN server خودتون رو راه انداختید (پیشنهاد DEPLOY.md سرور realtime)، اینجا اضافه کنید:
      // {'urls': 'turn:your-turn-server:3478', 'username': '...', 'credential': '...'}
    ],
  };

  Future<void> join({required int sessionId, required String token, required bool wantsCamera}) async {
    try {
      localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': wantsCamera
            ? {'facingMode': 'user', 'width': 640, 'height': 480}
            : false,
      });
      // پیش‌فرض: میکروفون و دوربین خاموش تا خود کاربر روشنش کنه
      for (final t in localStream!.getAudioTracks()) t.enabled = false;
      for (final t in localStream!.getVideoTracks()) t.enabled = false;
    } catch (e) {
      errorMessage = 'اجازه‌ی دسترسی به میکروفون/دوربین داده نشد';
      notifyListeners();
    }

    _socket = io.io(
      kSignalingUrl,
      io.OptionBuilder().setTransports(['websocket']).disableAutoConnect().build(),
    );

    _registerSocketEvents();
    _socket!.connect();
    _socket!.onConnect((_) {
      mySocketId = _socket!.id;
      _socket!.emit('join-room', {'sessionId': sessionId, 'token': token});
    });
  }

  void _registerSocketEvents() {
    final s = _socket!;

    s.on('room-joined', (data) async {
      final you = data['you'];
      roleInRoom = you['roleInRoom'] ?? you['role_in_room'] ?? 'participant';
      whiteboardColor = data['whiteboardColor'] ?? whiteboardColor;
      connected = true;

      final others = (data['participants'] as List).cast<Map>();
      for (final o in others) {
        _addParticipant(o);
        // من تازه واردم؛ به همه‌ی حاضرین offer می‌فرستم (الگوی mesh استاندارد)
        await _createPeerConnection(o['socketId'], initiator: true);
      }
      notifyListeners();
    });

    s.on('join-error', (data) {
      errorMessage = data['message'] ?? 'خطا در ورود به کلاس';
      notifyListeners();
    });

    s.on('participant-joined', (data) {
      _addParticipant(Map<String, dynamic>.from(data));
      notifyListeners();
      // منتظر می‌مونم خودش offer بفرسته (چون تازه‌وارد اونه)
    });

    s.on('participant-left', (data) {
      final socketId = data['socketId'];
      _peerConnections[socketId]?.close();
      _peerConnections.remove(socketId);
      participants.remove(socketId);
      notifyListeners();
    });

    s.on('webrtc-offer', (data) async {
      final from = data['from'];
      final pc = await _createPeerConnection(from, initiator: false);
      await pc.setRemoteDescription(RTCSessionDescription(data['sdp']['sdp'], data['sdp']['type']));
      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);
      s.emit('webrtc-answer', {'to': from, 'sdp': {'sdp': answer.sdp, 'type': answer.type}});
    });

    s.on('webrtc-answer', (data) async {
      final from = data['from'];
      final pc = _peerConnections[from];
      if (pc != null) {
        await pc.setRemoteDescription(RTCSessionDescription(data['sdp']['sdp'], data['sdp']['type']));
      }
    });

    s.on('webrtc-ice-candidate', (data) async {
      final from = data['from'];
      final pc = _peerConnections[from];
      final c = data['candidate'];
      if (pc != null && c != null) {
        await pc.addCandidate(RTCIceCandidate(c['candidate'], c['sdpMid'], c['sdpMLineIndex']));
      }
    });

    s.on('participant-mic-state', (data) {
      participants[data['socketId']]?.micOpen = data['open'] ?? false;
      notifyListeners();
    });
    s.on('participant-cam-state', (data) {
      participants[data['socketId']]?.camOpen = data['open'] ?? false;
      notifyListeners();
    });

    s.on('hand-raised', (data) {
      participants[data['socketId']]?.handRaised = true;
      notifyListeners();
    });
    s.on('hand-lowered', (data) {
      participants[data['socketId']]?.handRaised = false;
      notifyListeners();
    });
    s.on('mic-permission-granted', (_) {
      micPermissionGranted = true;
      notifyListeners();
    });
    s.on('force-mute', (_) {
      setMic(false);
    });

    s.on('screen-share-started', (data) => notifyListeners());
    s.on('screen-share-stopped', (data) => notifyListeners());

    s.on('whiteboard-draw', (stroke) {
      whiteboardStrokes.add(Map<String, dynamic>.from(stroke));
      notifyListeners();
    });
    s.on('whiteboard-color-change', (data) {
      whiteboardColor = data['color'] ?? whiteboardColor;
      notifyListeners();
    });
    s.on('whiteboard-clear', (_) {
      whiteboardStrokes.clear();
      whiteboardClearedController.add(null);
      notifyListeners();
    });
  }

  void _addParticipant(Map<dynamic, dynamic> o) {
    participants[o['socketId']] = RemoteParticipant(
      socketId: o['socketId'],
      userId: o['userId'] ?? 0,
      fullName: o['fullName'] ?? '',
      role: o['role'] ?? '',
      roleInRoom: o['roleInRoom'] ?? 'participant',
      micOpen: o['micOpen'] ?? false,
      camOpen: o['camOpen'] ?? false,
      handRaised: o['handRaised'] ?? false,
    );
  }

  Future<RTCPeerConnection> _createPeerConnection(String remoteSocketId, {required bool initiator}) async {
    if (_peerConnections.containsKey(remoteSocketId)) return _peerConnections[remoteSocketId]!;

    final pc = await createPeerConnection(_iceServers);
    _peerConnections[remoteSocketId] = pc;

    if (localStream != null) {
      for (final track in localStream!.getTracks()) {
        pc.addTrack(track, localStream!);
      }
    }

    pc.onIceCandidate = (candidate) {
      _socket?.emit('webrtc-ice-candidate', {
        'to': remoteSocketId,
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };

    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        participants[remoteSocketId]?.stream = event.streams[0];
        notifyListeners();
      }
    };

    if (initiator) {
      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      _socket?.emit('webrtc-offer', {
        'to': remoteSocketId,
        'sdp': {'sdp': offer.sdp, 'type': offer.type},
      });
    }

    return pc;
  }

  // ---------------- کنترل‌های محلی ----------------

  void setMic(bool open) {
    if (localStream == null) return;
    for (final t in localStream!.getAudioTracks()) t.enabled = open;
    micOpen = open;
    _socket?.emit('mic-state-changed', {'open': open});
    notifyListeners();
  }

  void setCam(bool open) {
    if (localStream == null) return;
    for (final t in localStream!.getVideoTracks()) t.enabled = open;
    camOpen = open;
    _socket?.emit('cam-state-changed', {'open': open});
    notifyListeners();
  }

  void raiseHand() {
    handRaised = true;
    _socket?.emit('raise-hand');
    notifyListeners();
  }

  void lowerHand() {
    handRaised = false;
    _socket?.emit('lower-hand');
    notifyListeners();
  }

  /// میزبان/ناظر: به یه دانش‌آموز خاص اجازه‌ی باز کردن میکروفون می‌ده
  void allowUnmute(String targetSocketId) {
    _socket?.emit('allow-unmute', {'targetSocketId': targetSocketId});
  }

  void forceMute(String targetSocketId) {
    _socket?.emit('force-mute', {'targetSocketId': targetSocketId});
  }

  /// اشتراک‌گذاری صفحه: تِرَک ویدیوی دوربین رو با تِرَک صفحه عوض می‌کنه (بدون نیاز به renegotiation)
  Future<void> startScreenShare() async {
    try {
      screenStream = await navigator.mediaDevices.getDisplayMedia({'video': true, 'audio': false});
      final newTrack = screenStream!.getVideoTracks().first;
      for (final pc in _peerConnections.values) {
        final senders = await pc.getSenders();
        for (final s in senders) {
          if (s.track?.kind == 'video') await s.replaceTrack(newTrack);
        }
      }
      screenSharing = true;
      _socket?.emit('screen-share-started');
      newTrack.onEnded = () => stopScreenShare();
      notifyListeners();
    } catch (_) {
      // کاربر اشتراک‌گذاری رو لغو کرد یا اجازه نداد
    }
  }

  Future<void> stopScreenShare() async {
    if (localStream == null) return;
    final camTrack = localStream!.getVideoTracks().isNotEmpty ? localStream!.getVideoTracks().first : null;
    if (camTrack != null) {
      for (final pc in _peerConnections.values) {
        final senders = await pc.getSenders();
        for (final s in senders) {
          if (s.track?.kind == 'video') await s.replaceTrack(camTrack);
        }
      }
    }
    await screenStream?.dispose();
    screenStream = null;
    screenSharing = false;
    _socket?.emit('screen-share-stopped');
    notifyListeners();
  }

  // ---------------- تخته‌ی مشترک ----------------

  void drawStroke(Map<String, dynamic> stroke) {
    _socket?.emit('whiteboard-draw', stroke);
  }

  void changeWhiteboardColor(String hexColor) {
    whiteboardColor = hexColor;
    _socket?.emit('whiteboard-color-change', {'color': hexColor});
    notifyListeners();
  }

  void clearWhiteboard() {
    whiteboardStrokes.clear();
    _socket?.emit('whiteboard-clear');
    notifyListeners();
  }

  Future<void> leave() async {
    _socket?.emit('leave-room');
    for (final pc in _peerConnections.values) {
      await pc.close();
    }
    _peerConnections.clear();
    participants.clear();
    await localStream?.dispose();
    await screenStream?.dispose();
    _socket?.disconnect();
    _socket?.dispose();
    connected = false;
    notifyListeners();
  }
}
