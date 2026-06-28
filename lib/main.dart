import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String _supabaseUrl = 'https://xtzuepyhocsyhuhcqucu.supabase.co';
const String _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh0enVlcHlob2NzeWh1aGNxdWN1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA3MjY1MTAsImV4cCI6MjA5NjMwMjUxMH0.qw5al21ZyPgq7JWzqAWVnUxPMCMeJAEOh9PoQ8lg6ts';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey); // ignore: deprecated_member_use
  runApp(const MyApp());
}

SupabaseClient get supabase => Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CARO KING',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, fontFamily: 'Roboto'),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Session? _session;
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _session = supabase.auth.currentSession;
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      setState(() => _session = data.session);
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = _session?.user.email;
    if (_session != null && email != null && email.isNotEmpty) {
      return CaroGameScreen(userEmail: email);
    }
    return const LoginScreen();
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Sign in failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      if (response.session == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign up successful. Please check your email to confirm your account.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isRegisterMode = false);
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Sign up failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleAuthMode() {
    if (_isLoading) return;
    setState(() {
      _isRegisterMode = !_isRegisterMode;
      _confirmPasswordController.clear();
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C20), Color(0xFF15102A), Color(0xFF06040A)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  color: const Color(0xFF17132E).withValues(alpha: 0.94),
                  elevation: 18,
                  shadowColor: Colors.black54,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(Icons.sports_esports, size: 54, color: Color(0xFF00E5FF)),
                          const SizedBox(height: 18),
                          Text(
                            _isRegisterMode ? 'Sign up' : 'Sign in',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isRegisterMode
                                ? 'Create an account with your email and password to enter the game.'
                                : 'Use your Supabase email and password to enter the game.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.62), height: 1.35),
                          ),
                          const SizedBox(height: 28),
                          TextFormField(
                            controller: _emailController,
                            enabled: !_isLoading,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty) return 'Please enter your email';
                              if (!email.contains('@')) return 'Please enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            enabled: !_isLoading,
                            obscureText: _obscurePassword,
                            textInputAction: _isRegisterMode ? TextInputAction.next : TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _isRegisterMode ? _signUp() : _signIn(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                                onPressed: _isLoading
                                    ? null
                                    : () => setState(() => _obscurePassword = !_obscurePassword),
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              final password = value ?? '';
                              if (password.isEmpty) return 'Please enter your password';
                              if (_isRegisterMode && password.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          if (_isRegisterMode) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPasswordController,
                              enabled: !_isLoading,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.newPassword],
                              onFieldSubmitted: (_) => _signUp(),
                              decoration: InputDecoration(
                                labelText: 'Confirm password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                                  onPressed: _isLoading
                                      ? null
                                      : () => setState(() => _obscurePassword = !_obscurePassword),
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                final confirmPassword = value ?? '';
                                if (confirmPassword.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (confirmPassword != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                          ],
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: _isLoading ? null : (_isRegisterMode ? _signUp : _signIn),
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Icon(_isRegisterMode ? Icons.person_add_alt_1 : Icons.login),
                            label: Text(
                              _isLoading
                                  ? (_isRegisterMode ? 'Signing up...' : 'Signing in...')
                                  : (_isRegisterMode ? 'Sign up' : 'Sign in'),
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _isLoading ? null : _toggleAuthMode,
                            child: Text(
                              _isRegisterMode
                                  ? 'Already have an account? Sign in'
                                  : 'Do not have an account? Sign up',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  DATA MODELS
// ════════════════════════════════════════════════════════════

enum BParticleType { fire, smoke, debris, spark }

class BParticle {
  BParticleType type;
  Offset position;
  Offset velocity;
  double life;       // 1.0 → 0.0
  double maxLife;
  double size;
  Color color;
  double rotation;
  double rotSpeed;
  bool isTriangle;

  BParticle({
    required this.type,
    required this.position,
    required this.velocity,
    required this.life,
    required this.maxLife,
    required this.size,
    required this.color,
    this.rotation = 0,
    this.rotSpeed = 0,
    this.isTriangle = false,
  });

  double get alpha => (life / maxLife).clamp(0.0, 1.0);
}

class RocketData {
  final String player;
  final Offset start;   // in board-local coords
  final Offset end;     // in board-local coords
  final double angle;

  const RocketData({
    required this.player,
    required this.start,
    required this.end,
    required this.angle,
  });
}

// ════════════════════════════════════════════════════════════
//  GAME SCREEN
// ════════════════════════════════════════════════════════════
class CaroGameScreen extends StatefulWidget {
  final String userEmail;

  const CaroGameScreen({super.key, required this.userEmail});

  @override
  State<CaroGameScreen> createState() => _CaroGameScreenState();
}

class _CaroGameScreenState extends State<CaroGameScreen>
    with TickerProviderStateMixin {
  int boardSize = 20;
  static const double _cellSize = 44.0;

  late List<List<String>> board;
  late String currentPlayer;
  late bool isGameOver;
  late String winner;
  late List<List<int>> winningLine;
  int? lastMoveRow, lastMoveCol;
  int scoreX = 0, scoreO = 0;
  String gameMode = 'PvP'; // 'PvP', 'PvE', 'Online'
  String difficulty = 'Medium';
  bool isAiThinking = false;

  // Tùy chọn quân cờ
  String playerSymbol = 'X'; 
  String aiSymbol = 'O';     
  bool isGameStarted = false;

  final TransformationController _tvController = TransformationController();
  double _vpW = 0, _vpH = 0;

  // ── Rocket ──
  RocketData? _rocket;
  AnimationController? _rocketCtrl;
  Animation<double>? _rocketAnim;

  // ── Cell explosion ──
  List<BParticle> _cellParticles = [];
  AnimationController? _cellExCtrl;

  // ── Board explosion (win) ──
  List<BParticle> _boardParticles = [];
  AnimationController? _boardExCtrl;

  // ── Shockwave (win) ──
  AnimationController? _shockwaveCtrl;

  // ── Board shake (win) ──
  AnimationController? _shakeCtrl;
  Animation<double>? _shakeAnim;

  // ── Explosion audio ──
  late final AudioPlayer _cellExplosionPlayer;
  late final AudioPlayer _winExplosionPlayer;

  // ── Pending move while rocket is flying ──
  int? _pendingR, _pendingC;

  final Random _rng = Random();

  // ══════════════════════════════════════════════════════════
  //  ONLINE MODE STATE
  // ══════════════════════════════════════════════════════════
  String? _matchId;
  String? _roomCode;
  String? _mySymbol; // 'X' or 'O'
  String _myNickname = '';
  String _opponentNickname = '';
  RealtimeChannel? _matchChannel;
  bool _isOnlineWaiting = false;   // waiting for opponent to join
  bool _isOnlineConnecting = false;
  String _onlineError = '';

  // UI controllers for online mode
  final TextEditingController _nicknameCtrl = TextEditingController();
  final TextEditingController _roomCodeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cellExplosionPlayer = AudioPlayer(playerId: 'cell_explosion');
    _winExplosionPlayer = AudioPlayer(playerId: 'win_explosion');
    _primeExplosionAudio();
    _initGame();
  }

  @override
  void dispose() {
    _rocketCtrl?.dispose();
    _cellExCtrl?.dispose();
    _boardExCtrl?.dispose();
    _shockwaveCtrl?.dispose();
    _shakeCtrl?.dispose();
    _tvController.dispose();
    _nicknameCtrl.dispose();
    _roomCodeCtrl.dispose();
    _cellExplosionPlayer.dispose();
    _winExplosionPlayer.dispose();
    _leaveOnlineMatch();
    super.dispose();
  }

  Future<void> _primeExplosionAudio() async {
    try {
      await _cellExplosionPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _winExplosionPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _cellExplosionPlayer.setSource(AssetSource('sounds/explosion_cell.wav'));
      await _winExplosionPlayer.setSource(AssetSource('sounds/explosion_win.wav'));
    } catch (_) {
      // Audio is cosmetic; gameplay should continue if a platform cannot prime it.
    }
  }

  Future<void> _playCellExplosionSound() async {
    try {
      await _cellExplosionPlayer.stop();
      await _cellExplosionPlayer.play(
        AssetSource('sounds/explosion_cell.wav'),
        volume: 0.95,
        mode: PlayerMode.lowLatency,
      );
    } catch (_) {}
  }

  Future<void> _playWinExplosionSound() async {
    try {
      await _winExplosionPlayer.stop();
      await _winExplosionPlayer.play(
        AssetSource('sounds/explosion_win.wav'),
        volume: 1.0,
        mode: PlayerMode.lowLatency,
      );
    } catch (_) {}
  }

  void _initGame() {
    board = List.generate(boardSize, (_) => List.generate(boardSize, (_) => ''));
    currentPlayer = 'X';
    isGameOver = false;
    winner = '';
    winningLine = [];
    lastMoveRow = lastMoveCol = null;
    _clearAllEffects();

    // Nếu chơi PvE và AI là quân X, máy sẽ đi nước đầu tiên
    if (gameMode == 'PvE' && aiSymbol == 'X') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _makeAiMove();
      });
    }
  }

  void _clearAllEffects() {
    _rocketCtrl?.dispose(); _rocketCtrl = null; _rocket = null;
    _cellExCtrl?.dispose(); _cellExCtrl = null; _cellParticles = [];
    _boardExCtrl?.dispose(); _boardExCtrl = null; _boardParticles = [];
    _shockwaveCtrl?.dispose(); _shockwaveCtrl = null;
    _shakeCtrl?.dispose(); _shakeCtrl = null;
    _pendingR = _pendingC = null;
  }

  void _resetGame() => setState(() { _initGame(); isAiThinking = false; });
  void _resetAll() => setState(() { _initGame(); scoreX = scoreO = 0; isAiThinking = false; });

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Are you sure you want to sign out of this account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    _leaveOnlineMatch();
    await supabase.auth.signOut();
  }

  // ── Zoom / pan ──────────────────────────────────────────────────────────
  Offset _cellCenter(int r, int c) =>
      Offset(c * _cellSize + _cellSize / 2, r * _cellSize + _cellSize / 2);

  void _zoom(double factor) {
    final m = _tvController.value;
    final s = m.getMaxScaleOnAxis();
    final ns = (s * factor).clamp(0.3, 2.5);
    if (ns == s) return;
    final tx = m.storage[12], ty = m.storage[13];
    final cx = _vpW / 2, cy = _vpH / 2;
    _tvController.value = Matrix4.identity()
      ..translateByDouble(cx * (1 - factor) + tx * factor, cy * (1 - factor) + ty * factor, 0.0, 1.0)
      ..scaleByDouble(ns, ns, 1.0, 1.0);
  }

  void _resetZoom() {
    if (_vpW > 0 && _vpH > 0) {
      final bw = boardSize * _cellSize;
      _tvController.value = Matrix4.translationValues((_vpW - bw) / 2, (_vpH - bw) / 2, 0);
    }
  }

  void _handleScroll(PointerScrollEvent e) {
    // Ctrl+Scroll = zoom, Scroll thường = pan
    final isCtrlHeld = HardwareKeyboard.instance.logicalKeysPressed
        .any((k) => k == LogicalKeyboardKey.controlLeft || k == LogicalKeyboardKey.controlRight);
    if (isCtrlHeld) {
      // Zoom in/out dựa trên hướng scroll
      if (e.scrollDelta.dy < 0) {
        _zoom(1.15);
      } else if (e.scrollDelta.dy > 0) {
        _zoom(1 / 1.15);
      }
    } else {
      final m = _tvController.value;
      _tvController.value = m * Matrix4.translationValues(
        -e.scrollDelta.dx / m.getMaxScaleOnAxis(),
        -e.scrollDelta.dy / m.getMaxScaleOnAxis(), 0);
    }
  }

  // ── Rocket launching ───────────────────────────────────────────────────
  void _launchRocket(int r, int c, String player) {
    final inv = Matrix4.inverted(_tvController.value);
    final tl = MatrixUtils.transformPoint(inv, Offset.zero);
    final br = MatrixUtils.transformPoint(inv, Offset(_vpW, _vpH));
    final visW = br.dx - tl.dx;
    final visH = br.dy - tl.dy;

    final target = _cellCenter(r, c);

    final side = _rng.nextInt(4);
    Offset start;
    switch (side) {
      case 0: start = Offset(tl.dx + _rng.nextDouble() * visW, tl.dy - 80); break;
      case 1: start = Offset(tl.dx + _rng.nextDouble() * visW, br.dy + 80); break;
      case 2: start = Offset(tl.dx - 80, tl.dy + _rng.nextDouble() * visH); break;
      default: start = Offset(br.dx + 80, tl.dy + _rng.nextDouble() * visH); break;
    }

    final dx = target.dx - start.dx;
    final dy = target.dy - start.dy;
    final angle = atan2(dy, dx);

    _rocketCtrl?.dispose();
    _rocketCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _rocketAnim = CurvedAnimation(parent: _rocketCtrl!, curve: Curves.easeIn);
    _rocket = RocketData(player: player, start: start, end: target, angle: angle);

    _rocketCtrl!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        final hitPos = _rocket!.end;
        setState(() => _rocket = null);
        _triggerCellExplosion(hitPos, player);
        Future.delayed(const Duration(milliseconds: 180), () {
          if (mounted) _processMove(r, c);
        });
      }
    });
    _rocketCtrl!.forward();
  }

  // ── Cell bomb explosion ────────────────────────────────────────────────
  void _triggerCellExplosion(Offset pos, String player) {
    _playCellExplosionSound();
    final pColor = player == 'X' ? const Color(0xFF00E5FF) : const Color(0xFFFF2D55);
    final particles = <BParticle>[];

    for (int i = 0; i < 20; i++) {
      final a = _rng.nextDouble() * 2 * pi;
      final spd = 80 + _rng.nextDouble() * 180;
      final t = 0.5 + _rng.nextDouble() * 0.5;
      final fireColors = [
        const Color(0xFFFF6B00), const Color(0xFFFFB300),
        const Color(0xFFFF3D00), const Color(0xFFFFE066),
      ];
      particles.add(BParticle(
        type: BParticleType.fire,
        position: pos + Offset(_rng.nextDouble() * 12 - 6, _rng.nextDouble() * 12 - 6),
        velocity: Offset(cos(a) * spd, sin(a) * spd),
        life: t, maxLife: t,
        size: 6 + _rng.nextDouble() * 10,
        color: fireColors[_rng.nextInt(fireColors.length)],
      ));
    }

    for (int i = 0; i < 12; i++) {
      final a = _rng.nextDouble() * 2 * pi;
      final spd = 15 + _rng.nextDouble() * 35;
      final t = 0.7 + _rng.nextDouble() * 0.5;
      final smokeVal = (80 + _rng.nextInt(80)).toDouble() / 255;
      particles.add(BParticle(
        type: BParticleType.smoke,
        position: pos + Offset(_rng.nextDouble() * 20 - 10, _rng.nextDouble() * 20 - 10),
        velocity: Offset(cos(a) * spd, sin(a) * spd - 20),
        life: t, maxLife: t,
        size: 14 + _rng.nextDouble() * 20,
        color: Color.fromRGBO((smokeVal * 255).toInt(), (smokeVal * 255).toInt(), (smokeVal * 255).toInt(), 1),
      ));
    }

    for (int i = 0; i < 14; i++) {
      final a = _rng.nextDouble() * 2 * pi;
      final spd = 100 + _rng.nextDouble() * 200;
      final t = 0.4 + _rng.nextDouble() * 0.4;
      final debrisColors = [pColor, Colors.white, Colors.orangeAccent, const Color(0xFF888888)];
      particles.add(BParticle(
        type: BParticleType.debris,
        position: pos,
        velocity: Offset(cos(a) * spd, sin(a) * spd),
        life: t, maxLife: t,
        size: 3 + _rng.nextDouble() * 5,
        color: debrisColors[_rng.nextInt(debrisColors.length)],
        rotation: _rng.nextDouble() * 2 * pi,
        rotSpeed: (_rng.nextDouble() - 0.5) * 15,
        isTriangle: _rng.nextBool(),
      ));
    }

    for (int i = 0; i < 16; i++) {
      final a = _rng.nextDouble() * 2 * pi;
      final spd = 200 + _rng.nextDouble() * 300;
      final t = 0.2 + _rng.nextDouble() * 0.25;
      particles.add(BParticle(
        type: BParticleType.spark,
        position: pos,
        velocity: Offset(cos(a) * spd, sin(a) * spd),
        life: t, maxLife: t,
        size: 1.5 + _rng.nextDouble() * 2,
        color: _rng.nextBool() ? Colors.white : const Color(0xFFFFE066),
      ));
    }

    _cellExCtrl?.dispose();
    _cellExCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _cellParticles = particles;

    _cellExCtrl!.addStatusListener((s) {
      if (s == AnimationStatus.completed) setState(() => _cellParticles = []);
    });
    _cellExCtrl!.forward();
  }

  // ── Board explosion + shockwave + shake (win) ─────────────────────────
  void _triggerWinEffect(String winPlayer) {
    _playWinExplosionSound();
    final pColor = winPlayer == 'X' ? const Color(0xFF00E5FF) : const Color(0xFFFF2D55);
    final bW = boardSize * _cellSize;
    final bH = boardSize * _cellSize;
    final center = Offset(bW / 2, bH / 2);

    final particles = <BParticle>[];
    for (int i = 0; i < 80; i++) {
      final pos = Offset(_rng.nextDouble() * bW, _rng.nextDouble() * bH);
      final a = _rng.nextDouble() * 2 * pi;
      final spd = 60 + _rng.nextDouble() * 200;
      final t = 0.6 + _rng.nextDouble() * 0.8;
      final fireColors = [const Color(0xFFFF6B00), const Color(0xFFFFB300), pColor, Colors.white, const Color(0xFFFF3D00)];
      particles.add(BParticle(
        type: i % 4 == 0 ? BParticleType.smoke : (i % 4 == 1 ? BParticleType.debris : BParticleType.fire),
        position: pos,
        velocity: Offset(cos(a) * spd, sin(a) * spd),
        life: t, maxLife: t,
        size: i % 4 == 0 ? 20 + _rng.nextDouble() * 30 : 4 + _rng.nextDouble() * 10,
        color: fireColors[i % fireColors.length],
        rotation: _rng.nextDouble() * 2 * pi,
        rotSpeed: (_rng.nextDouble() - 0.5) * 10,
        isTriangle: i % 3 == 0,
      ));
    }
    for (int i = 0; i < 40; i++) {
      final a = _rng.nextDouble() * 2 * pi;
      final spd = 150 + _rng.nextDouble() * 350;
      final t = 0.3 + _rng.nextDouble() * 0.4;
      particles.add(BParticle(
        type: BParticleType.spark,
        position: center + Offset(_rng.nextDouble() * 100 - 50, _rng.nextDouble() * 100 - 50),
        velocity: Offset(cos(a) * spd, sin(a) * spd),
        life: t, maxLife: t,
        size: 1.5, color: _rng.nextBool() ? Colors.white : const Color(0xFFFFE066),
      ));
    }

    _boardExCtrl?.dispose();
    _boardExCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _boardParticles = particles;
    _boardExCtrl!.addStatusListener((s) {
      if (s == AnimationStatus.completed) setState(() => _boardParticles = []);
    });

    _shockwaveCtrl?.dispose();
    _shockwaveCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _shockwaveCtrl!.addStatusListener((s) {
      if (s == AnimationStatus.completed) setState(() {});
    });

    _shakeCtrl?.dispose();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 5.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: -4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 3.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 3.0, end: 0.0), weight: 2),
    ]).animate(CurvedAnimation(parent: _shakeCtrl!, curve: Curves.easeInOut));

    _shakeCtrl!.addStatusListener((s) {
      if (s == AnimationStatus.completed) setState(() {});
    });

    _boardExCtrl!.forward();
    _shockwaveCtrl!.forward();
    _shakeCtrl!.forward();
  }

  // ── Move processing ────────────────────────────────────────────────────
  void _handleCellTap(int r, int c) {
    if (isGameOver || board[r][c].isNotEmpty || isAiThinking) return;
    if (_rocket != null || _pendingR != null) return;

    // Online mode: only allow tap on my turn
    if (gameMode == 'Online') {
      if (_mySymbol == null || currentPlayer != _mySymbol) return;
      if (_matchId == null || _isOnlineWaiting) return;
    }

    _pendingR = r; _pendingC = c;
    setState(() {});
    _launchRocket(r, c, currentPlayer);
  }

  void _processMove(int r, int c) {
    if (!mounted) return;
    setState(() {
      _pendingR = _pendingC = null;
      board[r][c] = currentPlayer;
      lastMoveRow = r; lastMoveCol = c;

      if (_checkWin(r, c)) {
        isGameOver = true; winner = currentPlayer;
        if (currentPlayer == 'X') {
          scoreX++;
        } else {
          scoreO++;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _triggerWinEffect(winner);
          Future.delayed(const Duration(milliseconds: 900), () {
            if (mounted) _showGameOverDialog(winner);
          });
        });
        // Update Supabase if online
        if (gameMode == 'Online') _pushOnlineMove(r, c, isGameOver: true, winnerVal: winner, winLineVal: winningLine);
      } else if (_checkDraw()) {
        isGameOver = true; winner = 'Draw';
        if (gameMode == 'Online') _pushOnlineMove(r, c, isGameOver: true, winnerVal: 'Draw', winLineVal: []);
        WidgetsBinding.instance.addPostFrameCallback((_) => _showGameOverDialog(winner));
      } else {
        currentPlayer = currentPlayer == 'X' ? 'O' : 'X';
        if (gameMode == 'Online') {
          _pushOnlineMove(r, c);
        } else if (gameMode == 'PvE' && currentPlayer == aiSymbol) {
          _makeAiMove();
        }
      }
    });
  }

  bool _checkWin(int row, int col) {
    final p = board[row][col];
    if (p.isEmpty) return false;
    for (var dir in [[0,1],[1,0],[1,1],[1,-1]]) {
      final dr = dir[0], dc = dir[1];
      final line = <List<int>>[[row, col]];
      for (int s = 1; s <= 4; s++) {
        final nr = row + dr*s, nc = col + dc*s;
        if (nr < 0 || nr >= boardSize || nc < 0 || nc >= boardSize || board[nr][nc] != p) break;
        line.add([nr, nc]);
      }
      for (int s = 1; s <= 4; s++) {
        final nr = row - dr*s, nc = col - dc*s;
        if (nr < 0 || nr >= boardSize || nc < 0 || nc >= boardSize || board[nr][nc] != p) break;
        line.add([nr, nc]);
      }
      if (line.length >= 5) { winningLine = line; return true; }
    }
    return false;
  }

  bool _checkDraw() {
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (board[r][c].isEmpty) return false;
      }
    }
    return true;
  }

  // ── AI ────────────────────────────────────────────────────────────────
  void _makeAiMove() {
    setState(() => isAiThinking = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || isGameOver) { setState(() => isAiThinking = false); return; }
      final move = _calcBest();
      setState(() => isAiThinking = false);
      _pendingR = move[0]; _pendingC = move[1];
      setState(() {});
      _launchRocket(move[0], move[1], aiSymbol);
    });
  }

  List<int> _calcBest() {
    int best = -1;
    List<List<int>> bestMoves = [];
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (board[r][c].isEmpty) {
          final s = _scoreCell(r, c);
          if (s > best) {
            best = s;
            bestMoves = [[r, c]];
          } else if (s == best) {
            bestMoves.add([r, c]);
          }
        }
      }
    }
    if (bestMoves.isEmpty) return [boardSize~/2, boardSize~/2];
    if (difficulty == 'Easy') {
      if (_rng.nextDouble() < 0.4) {
        final near = _nearMoves();
        if (near.isNotEmpty) return near[_rng.nextInt(near.length)];
      }
      return _topMoves(5)[0];
    } else if (difficulty == 'Medium') {
      if (_rng.nextDouble() < 0.2) {
        final near = _nearMoves();
        if (near.isNotEmpty) return near[_rng.nextInt(near.length)];
      }
      final top = _topMoves(3);
      return top[_rng.nextInt(top.length)];
    }
    return bestMoves[_rng.nextInt(bestMoves.length)];
  }

  List<List<int>> _nearMoves() {
    final c = <List<int>>[];
    for (int r = 0; r < boardSize; r++) {
      for (int cc = 0; cc < boardSize; cc++) {
        if (board[r][cc].isEmpty) {
          bool nb = false;
          outer: for (int dr = -2; dr <= 2; dr++) {
            for (int dc = -2; dc <= 2; dc++) {
              final nr = r+dr, nc = cc+dc;
              if (nr>=0&&nr<boardSize&&nc>=0&&nc<boardSize&&board[nr][nc].isNotEmpty) { nb=true; break outer; }
            }
          }
          if (nb) c.add([r,cc]);
        }
      }
    }
    if (c.isEmpty) c.add([boardSize~/2,boardSize~/2]);
    return c;
  }

  List<List<int>> _topMoves(int k) {
    final list = <MapEntry<List<int>,int>>[];
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (board[r][c].isEmpty) {
          list.add(MapEntry([r,c],_scoreCell(r,c)));
        }
      }
    }
    list.sort((a,b)=>b.value.compareTo(a.value));
    final res = <List<int>>[];
    for (int i = 0; i < min(k,list.length); i++) {
      res.add(list[i].key);
    }
    return res.isNotEmpty ? res : [[boardSize~/2,boardSize~/2]];
  }

  int _scoreCell(int row, int col) {
    int atk = 0, def = 0;
    final aiSym = aiSymbol;
    final playSym = playerSymbol;

    for (var d in [[0,1],[1,0],[1,1],[1,-1]]) {
      atk += _evalLine(row, col, d[0], d[1], aiSym);
      def += _evalLine(row, col, d[0], d[1], playSym);
    }
    
    if (difficulty == 'Asian') {
      if (atk >= 100000) return 10000000;
      if (def >= 100000) return 9000000;
      return atk + (def * 3.0).toInt();
    } else {
      if (atk >= 100000) return 10000000;
      if (def >= 100000) return 5000000;
      return atk + (def * 1.25).toInt();
    }
  }

  int _evalLine(int row, int col, int dr, int dc, String p) {
    int cnt = 1, open = 0;
    int r = row + dr, c = col + dc;
    while (r >= 0 && r < boardSize && c >= 0 && c < boardSize && board[r][c] == p) { cnt++; r += dr; c += dc; }
    if (r >= 0 && r < boardSize && c >= 0 && c < boardSize && board[r][c] == '') open++;
    r = row - dr; c = col - dc;
    while (r >= 0 && r < boardSize && c >= 0 && c < boardSize && board[r][c] == p) { cnt++; r -= dr; c -= dc; }
    if (r >= 0 && r < boardSize && c >= 0 && c < boardSize && board[r][c] == '') open++;
    
    if (cnt >= 5) return 100000;
    
    if (difficulty == 'Asian') {
      if (cnt == 4) return open == 2 ? 80000 : open == 1 ? 40000 : 0;
      if (cnt == 3) return open == 2 ? 30000 : open == 1 ? 1000 : 0;
      if (cnt == 2) return open == 2 ? 500 : open == 1 ? 50 : 0;
      if (cnt == 1 && open == 2) return 20;
    } else {
      if (cnt == 4) return open == 2 ? 10000 : open == 1 ? 1000 : 0;
      if (cnt == 3) return open == 2 ? 1000 : open == 1 ? 100 : 0;
      if (cnt == 2) return open == 2 ? 100 : open == 1 ? 10 : 0;
      if (cnt == 1 && open == 2) return 10;
    }
    return 0;
  }

  // ══════════════════════════════════════════════════════════
  //  ONLINE MODE LOGIC
  // ══════════════════════════════════════════════════════════

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[_rng.nextInt(chars.length)]).join();
  }

  List<List<String>> _emptyBoard() =>
      List.generate(boardSize, (_) => List.generate(boardSize, (_) => ''));

  List<dynamic> _boardToJson(List<List<String>> b) =>
      b.map((row) => row.toList()).toList();

  List<List<String>> _boardFromJson(List<dynamic> json) =>
      json.map<List<String>>((row) => (row as List).map<String>((c) => c as String).toList()).toList();

  Future<void> _createRoom() async {
    final nick = _nicknameCtrl.text.trim();
    if (nick.isEmpty) {
      setState(() => _onlineError = 'Vui lòng nhập tên của bạn');
      return;
    }
    setState(() { _isOnlineConnecting = true; _onlineError = ''; });

    try {
      final code = _generateRoomCode();
      final response = await supabase.from('matches').insert({
        'room_code': code,
        'player_x': playerSymbol == 'X' ? nick : null,
        'player_o': playerSymbol == 'O' ? nick : null,
        'board': _boardToJson(_emptyBoard()),
        'current_player': 'X',
        'status': 'waiting',
      }).select().single();

      setState(() {
        _matchId = response['id'] as String;
        _roomCode = code;
        _mySymbol = playerSymbol;
        _myNickname = nick;
        _opponentNickname = '';
        _isOnlineWaiting = true;
        _isOnlineConnecting = false;
        gameMode = 'Online';
        isGameStarted = true;
        _initGame();
      });
      _subscribeToMatch(_matchId!);
    } catch (e) {
      setState(() {
        _onlineError = 'Lỗi tạo phòng: $e';
        _isOnlineConnecting = false;
      });
    }
  }

  Future<void> _joinRoom() async {
    final nick = _nicknameCtrl.text.trim();
    final code = _roomCodeCtrl.text.trim().toUpperCase();
    if (nick.isEmpty) {
      setState(() => _onlineError = 'Vui lòng nhập tên của bạn');
      return;
    }
    if (code.length != 6) {
      setState(() => _onlineError = 'Mã phòng phải có 6 ký tự');
      return;
    }
    setState(() { _isOnlineConnecting = true; _onlineError = ''; });

    try {
      final rows = await supabase
          .from('matches')
          .select()
          .eq('room_code', code)
          .eq('status', 'waiting')
          .limit(1);

      if (rows.isEmpty) {
        setState(() {
          _onlineError = 'Không tìm thấy phòng hoặc phòng đã đầy';
          _isOnlineConnecting = false;
        });
        return;
      }

      final row = rows.first;
      final matchId = row['id'] as String;
      final creatorIsX = row['player_x'] != null;

      final mySym = creatorIsX ? 'O' : 'X';
      final oppName = creatorIsX 
          ? (row['player_x'] as String? ?? '') 
          : (row['player_o'] as String? ?? '');

      await supabase.from('matches').update({
        creatorIsX ? 'player_o' : 'player_x': nick,
        'status': 'playing',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', matchId);

      final updated = await supabase.from('matches').select().eq('id', matchId).single();

      setState(() {
        _matchId = matchId;
        _roomCode = code;
        _mySymbol = mySym;
        _myNickname = nick;
        _opponentNickname = oppName;
        _isOnlineWaiting = false;
        _isOnlineConnecting = false;
        gameMode = 'Online';
        isGameStarted = true;
        _initGame();
        board = _boardFromJson(updated['board'] as List);
        currentPlayer = updated['current_player'] as String? ?? 'X';
      });
      _subscribeToMatch(matchId);
    } catch (e) {
      setState(() {
        _onlineError = 'Lỗi vào phòng: $e';
        _isOnlineConnecting = false;
      });
    }
  }

  void _subscribeToMatch(String matchId) {
    _matchChannel?.unsubscribe();
    _matchChannel = supabase
        .channel('match-$matchId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'matches',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: matchId,
          ),
          callback: (payload) {
            if (!mounted) return;
            final newData = payload.newRecord;
            _handleRemoteUpdate(newData);
          },
        )
        .subscribe();
  }

  void _handleRemoteUpdate(Map<String, dynamic> data) {
    if (!mounted) return;

    final newStatus = data['status'] as String? ?? 'playing';
    final newBoard = _boardFromJson(data['board'] as List);
    final newCurrentPlayer = data['current_player'] as String? ?? 'X';
    final newWinner = data['winner'] as String?;
    final newWinLine = data['winning_line'] as List?;
    final remoteLastRow = data['last_move_row'] as int?;
    final remoteLastCol = data['last_move_col'] as int?;
    final playerO = data['player_o'] as String?;

    // Update opponent name when they join
    final playerX = data['player_x'] as String?;
    if (_mySymbol == 'X' && playerO != null && _opponentNickname.isEmpty) {
      setState(() {
        _opponentNickname = playerO;
        _isOnlineWaiting = false;
      });
    } else if (_mySymbol == 'O' && playerX != null && _opponentNickname.isEmpty) {
      setState(() {
        _opponentNickname = playerX;
        _isOnlineWaiting = false;
      });
    }

    // Detect opponent's move by comparing boards
    if (remoteLastRow != null && remoteLastCol != null) {
      final localCell = board[remoteLastRow][remoteLastCol];
      final remoteCell = newBoard[remoteLastRow][remoteLastCol];

      // If the remote board has a new move that we don't have locally, animate it
      if (localCell.isEmpty && remoteCell.isNotEmpty && _rocket == null && _pendingR == null) {
        final mover = remoteCell;
        // Update local board state first
        setState(() {
          board = newBoard;
          currentPlayer = newCurrentPlayer;
          lastMoveRow = remoteLastRow;
          lastMoveCol = remoteLastCol;
          if (newWinner != null && newWinner.isNotEmpty) {
            isGameOver = true;
            winner = newWinner;
            if (newWinner != 'Draw' && newWinLine != null) {
              winningLine = newWinLine.map<List<int>>((e) => (e as List).map<int>((v) => v as int).toList()).toList();
            }
            if (newWinner == 'X') {
              scoreX++;
            } else if (newWinner == 'O') {
              scoreO++;
            }
          }
        });

        // Trigger rocket + explosion animation for opponent's move
        _pendingR = remoteLastRow; _pendingC = remoteLastCol;
        setState(() {});
        _launchRocketAnimOnly(remoteLastRow, remoteLastCol, mover);

        if (isGameOver) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _triggerWinEffect(winner);
            Future.delayed(const Duration(milliseconds: 900), () {
              if (mounted) _showGameOverDialog(winner);
            });
          });
        }
      } else {
        // Sync state without animation (e.g. on reconnect)
        setState(() {
          board = newBoard;
          currentPlayer = newCurrentPlayer;
          lastMoveRow = remoteLastRow;
          lastMoveCol = remoteLastCol;
        });
      }
    }

    // Handle game status change
    if (newStatus == 'finished' && !isGameOver && newWinner != null) {
      setState(() {
        isGameOver = true;
        winner = newWinner;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGameOverDialog(winner);
      });
    }
  }

  // Variant of _launchRocket that only fires animation but doesn't call _processMove
  // (since the move is already processed from the remote board state)
  void _launchRocketAnimOnly(int r, int c, String player) {
    final inv = Matrix4.inverted(_tvController.value);
    final tl = MatrixUtils.transformPoint(inv, Offset.zero);
    final br = MatrixUtils.transformPoint(inv, Offset(_vpW, _vpH));
    final visW = br.dx - tl.dx;
    final visH = br.dy - tl.dy;

    final target = _cellCenter(r, c);
    final side = _rng.nextInt(4);
    Offset start;
    switch (side) {
      case 0: start = Offset(tl.dx + _rng.nextDouble() * visW, tl.dy - 80); break;
      case 1: start = Offset(tl.dx + _rng.nextDouble() * visW, br.dy + 80); break;
      case 2: start = Offset(tl.dx - 80, tl.dy + _rng.nextDouble() * visH); break;
      default: start = Offset(br.dx + 80, tl.dy + _rng.nextDouble() * visH); break;
    }

    final dx = target.dx - start.dx;
    final dy = target.dy - start.dy;
    final angle = atan2(dy, dx);

    _rocketCtrl?.dispose();
    _rocketCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _rocketAnim = CurvedAnimation(parent: _rocketCtrl!, curve: Curves.easeIn);
    _rocket = RocketData(player: player, start: start, end: target, angle: angle);

    _rocketCtrl!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        final hitPos = _rocket!.end;
        setState(() {
          _rocket = null;
          _pendingR = _pendingC = null;
        });
        _triggerCellExplosion(hitPos, player);
      }
    });
    _rocketCtrl!.forward();
  }

  Future<void> _pushOnlineMove(int r, int c, {
    bool isGameOver = false,
    String? winnerVal,
    List<List<int>>? winLineVal,
  }) async {
    if (_matchId == null) return;
    try {
      await supabase.from('matches').update({
        'board': _boardToJson(board),
        'current_player': currentPlayer,
        'last_move_row': r,
        'last_move_col': c,
        'status': isGameOver ? 'finished' : 'playing',
        'winner': ?winnerVal,
        'winning_line': ?winLineVal,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', _matchId!);
    } catch (e) {
      // silently ignore push failures
    }
  }

  void _leaveOnlineMatch() {
    _matchChannel?.unsubscribe();
    _matchChannel = null;
    _matchId = null;
    _roomCode = null;
    _mySymbol = null;
    _isOnlineWaiting = false;
  }

  void _exitOnlineMode() {
    _leaveOnlineMatch();
    setState(() {
      gameMode = 'PvP';
      isGameStarted = false;
      _initGame();
    });
  }

  Future<void> _resetOnlineGame() async {
    if (_matchId == null) return;
    final newBoard = _emptyBoard();
    try {
      await supabase.from('matches').update({
        'board': _boardToJson(newBoard),
        'current_player': 'X',
        'status': 'playing',
        'winner': null,
        'winning_line': null,
        'last_move_row': null,
        'last_move_col': null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', _matchId!);
      setState(() {
        _initGame();
      });
    } catch (e) {
      // ignore
    }
  }

  // ── Dialog ────────────────────────────────────────────────────────────
  void _showGameOverDialog(String result) {
    if (!mounted) return;
    String displayResult = result;
    if (gameMode == 'Online' && result != 'Draw' && result.isNotEmpty) {
      if (result == _mySymbol) {
        displayResult = 'WIN';
      } else {
        displayResult = 'LOSE';
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1A3A).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 25, offset: const Offset(0,10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  result == 'Draw' ? Icons.handshake : (displayResult == 'LOSE' ? Icons.sentiment_dissatisfied : Icons.emoji_events),
                  size: 80,
                  color: result == 'Draw' ? Colors.amberAccent : (displayResult == 'LOSE' ? Colors.grey : (result == 'X' ? const Color(0xFF00E5FF) : const Color(0xFFFF2D55))),
                ),
                const SizedBox(height: 20),
                Text(
                  result == 'Draw' ? 'HÒA CỜ!' : (displayResult == 'WIN' ? 'CHIẾN THẮNG! 🎉' : displayResult == 'LOSE' ? 'THUA RỒI... 😢' : 'CHIẾN THẮNG!'),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
                ),
                const SizedBox(height: 12),
                Text(
                  result == 'Draw'
                    ? 'Hai bên đã hòa nhau! Hãy thử sức lại ván mới.'
                    : gameMode == 'Online'
                      ? (displayResult == 'WIN' ? 'Bạn đã thắng! Xuất sắc!' : 'Đối thủ thắng lần này. Cố lên!')
                      : 'Người chơi [ $result ] đã thắng với 5 ô liên tiếp! 💥',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.7), height: 1.4),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (gameMode == 'Online') ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _resetOnlineGame();
                        },
                        icon: const Icon(Icons.replay, color: Colors.white),
                        label: const Text('CHƠI LẠI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _exitOnlineMode();
                        },
                        icon: const Icon(Icons.exit_to_app, color: Colors.white70),
                        label: const Text('THOÁT', style: TextStyle(fontSize: 14, color: Colors.white70)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ] else
                      ElevatedButton.icon(
                        onPressed: () { Navigator.of(context).pop(); _resetGame(); },
                        icon: const Icon(Icons.replay, color: Colors.white),
                        label: const Text('CHƠI LẠI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── UI helpers ────────────────────────────────────────────────────────
  Widget _modeBtn(String mode, String label) {
    final sel = gameMode == mode;
    return GestureDetector(
      onTap: () {
        if (gameMode == mode) return;
        if (gameMode == 'Online') _leaveOnlineMatch();
        setState(() { gameMode = mode; _resetGame(); });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF6C63FF).withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: sel ? const Color(0xFF6C63FF) : Colors.white.withValues(alpha: 0.1),
            width: 1.2,
          ),
        ),
        child: Text(label, style: TextStyle(color: sel ? Colors.white : Colors.white60, fontSize: 12, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _diffBtn(String diff, String label, Color color) {
    final sel = difficulty == diff;
    return GestureDetector(
      onTap: () { if (difficulty==diff) return; setState(() { difficulty=diff; _resetGame(); }); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: sel?color.withValues(alpha: 0.2):Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: sel?color:Colors.white.withValues(alpha: 0.08)),
        ),
        child: Text(label, style: TextStyle(color: sel?Colors.white:Colors.white60, fontSize: 11, fontWeight: sel?FontWeight.bold:FontWeight.normal)),
      ),
    );
  }

  Widget _playerCard(String player, String label, int score, bool isActive) {
    final isX = player=='X';
    final pc = isX?const Color(0xFF00E5FF):const Color(0xFFFF2D55);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isActive?pc.withValues(alpha: 0.12):Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isActive?pc:Colors.white.withValues(alpha: 0.08), width: isActive?1.5:1.0),
        boxShadow: isActive?[BoxShadow(color: pc.withValues(alpha: 0.3), blurRadius: 6, spreadRadius: 0.5)]:null,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          if (isAiThinking && !isX) ...[
            const SizedBox(width:8,height:8,child:CircularProgressIndicator(strokeWidth:1.5,valueColor:AlwaysStoppedAnimation(Color(0xFFFF2D55)))),
            const SizedBox(width:6),
          ] else if (isActive) ...[
            Container(width:6,height:6,decoration:BoxDecoration(color:pc,shape:BoxShape.circle,boxShadow:[BoxShadow(color:pc,blurRadius:4,spreadRadius:1)])),
            const SizedBox(width:6),
          ],
          Text(label, style: TextStyle(color:isActive?Colors.white:Colors.white60, fontWeight:FontWeight.bold, fontSize:12)),
        ]),
        const SizedBox(height:4),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text(player, style: TextStyle(color:pc, fontWeight:FontWeight.w900, fontSize:22, shadows:[Shadow(color:pc,blurRadius:4)])),
          const SizedBox(width:8),
          Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:3),
            decoration:BoxDecoration(color:Colors.black26,borderRadius:BorderRadius.circular(6)),
            child: Text('$score', style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold,fontSize:14))),
        ]),
      ]),
    );
  }

  // ── Online Panel (inline in setup screen) ─────────────────────────────
  Widget _buildOnlineSetupSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('TẠO / THAM GIA PHÒNG'),
        const SizedBox(height: 10),
        const Text('Tên của bạn', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _nicknameCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nhập tên hiển thị...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00C896), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: const Icon(Icons.person, color: Color(0xFF00C896), size: 18),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Tạo phòng: bạn nhận quân cờ đã chọn ở trên. Vào phòng: bạn nhận quân cờ còn lại.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.58), fontSize: 12, height: 1.35),
        ),
        const SizedBox(height: 12),

        // Create Room button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isOnlineConnecting ? null : _createRoom,
            icon: _isOnlineConnecting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.add_circle_outline, color: Colors.white),
            label: const Text('TẠO PHÒNG MỚI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C896),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),

        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('hoặc', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
          ),
          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
        ]),
        const SizedBox(height: 16),

        // Join room
        const Text('Mã phòng', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _roomCodeCtrl,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 3, fontSize: 16),
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'XXXXXX',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2), letterSpacing: 3),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _isOnlineConnecting ? null : _joinRoom,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isOnlineConnecting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('VÀO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ]),

        if (_onlineError.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF2D55).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFF2D55).withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline, color: Color(0xFFFF2D55), size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_onlineError, style: const TextStyle(color: Color(0xFFFF2D55), fontSize: 12))),
            ]),
          ),
        ],
      ],
    );
  }

  // ── Waiting for opponent banner ─────────────────────────────────────
  Widget _buildWaitingBanner() {
    return Positioned(
      left: 0, right: 0, bottom: 80,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0C24).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: const Color(0xFF00C896).withValues(alpha: 0.5)),
            boxShadow: [BoxShadow(color: const Color(0xFF00C896).withValues(alpha: 0.15), blurRadius: 20)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFF00C896))),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mã phòng: $_roomCode', style: const TextStyle(color: Color(0xFF00C896), fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2)),
                  Text('Đang chờ đối thủ tham gia...', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Online status bar ──────────────────────────────────────────────
  Widget _buildOnlineStatusBar() {
    final mySymbol = _mySymbol ?? 'X';
    final opponentSymbol = mySymbol == 'X' ? 'O' : 'X';
    final myColor = mySymbol == 'X' ? const Color(0xFF00E5FF) : const Color(0xFFFF2D55);
    final oppColor = opponentSymbol == 'X' ? const Color(0xFF00E5FF) : const Color(0xFFFF2D55);
    final isMyTurn = currentPlayer == mySymbol && !isGameOver;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF00C896).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF00C896).withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi, color: Color(0xFF00C896), size: 12),
          const SizedBox(width: 6),
          Text('Phòng: $_roomCode ', style: const TextStyle(color: Color(0xFF00C896), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(width: 4),
          Text(
            isMyTurn ? "⚡ Lượt bạn" : "⏳ Chờ...",
            style: TextStyle(color: isMyTurn ? Colors.white : Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 16, color: Colors.white12),
          const SizedBox(width: 8),
          Text(_myNickname.isEmpty ? 'Bạn' : _myNickname, style: TextStyle(color: myColor, fontWeight: FontWeight.bold, fontSize: 11)),
          Text(' ($mySymbol)', style: TextStyle(color: myColor, fontSize: 10)),
          const Text(' vs ', style: TextStyle(color: Colors.white38, fontSize: 10)),
          Text(_opponentNickname.isEmpty ? '???' : _opponentNickname, style: TextStyle(color: oppColor, fontWeight: FontWeight.bold, fontSize: 11)),
          Text(' ($opponentSymbol)', style: TextStyle(color: oppColor, fontSize: 10)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  SETUP SCREEN (MÀN HÌNH CẤU HÌNH TRẬN ĐẤU)
  // ══════════════════════════════════════════════════════════

  // Hàm xây dựng màn hình Setup tùy chỉnh trước khi bắt đầu game
  Widget _buildSetupScreen() {
    return Scaffold(
      body: Container(
        // Hiệu ứng Gradient động mượt mà làm nền background cho game
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C20), Color(0xFF15102A), Color(0xFF06040A)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                // Thẻ Card thiết kế dạng kính mờ (Glassmorphism) cực kỳ Premium
                child: Card(
                  color: const Color(0xFF17132E).withValues(alpha: 0.92),
                  elevation: 24,
                  shadowColor: Colors.black.withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.08)), // Viền sáng nhẹ tạo cảm giác nổi khối
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo game Caro King với hiệu ứng ánh sáng Neon tỏa bóng
                        const Center(
                          child: Text(
                            'CARO KING',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 4,
                              shadows: [
                                Shadow(color: Color(0xFF00E5FF), blurRadius: 12),
                                Shadow(color: Colors.indigoAccent, blurRadius: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            'CẤU HÌNH TRẬN ĐẤU',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Phần 1: Lựa chọn Chế độ chơi
                        _buildSectionTitle('CHẾ ĐỘ CHƠI'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _buildModeSelectorCard('PvP', '👥', '2 Người')),
                            const SizedBox(width: 10),
                            Expanded(child: _buildModeSelectorCard('PvE', '🤖', 'Với Máy')),
                            const SizedBox(width: 10),
                            Expanded(child: _buildModeSelectorCard('Online', '🌐', 'Online')),
                          ],
                        ),
                        const SizedBox(height: 22),

                        // Phần 2: Kích thước bản đồ (Từ 20x20 đến 50x50)
                        _buildSectionTitle('KÍCH THƯỚC BẢN ĐỒ'),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Số ô: ${boardSize}x$boardSize',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              '(${boardSize * boardSize} ô cờ)',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFF6C63FF),
                            inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                            thumbColor: const Color(0xFF00E5FF),
                            overlayColor: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                            valueIndicatorColor: const Color(0xFF6C63FF),
                            valueIndicatorTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          child: Slider(
                            value: boardSize.toDouble(),
                            min: 20,
                            max: 50,
                            divisions: 30,
                            label: '${boardSize}x$boardSize',
                            onChanged: (val) {
                              setState(() {
                                boardSize = val.toInt();
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Phần 3: Lựa chọn Quân cờ (Chỉ hiển thị cho Máy hoặc Online)
                        if (gameMode == 'PvE' || gameMode == 'Online') ...[
                          _buildSectionTitle('CHỌN BÊN CỦA BẠN'),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSymbolSelectorCard('X', const Color(0xFF00E5FF)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildSymbolSelectorCard('O', const Color(0xFFFF2D55)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                        ],

                        // Phần 4: Độ khó máy (Chỉ hiển thị cho Máy - PvE)
                        if (gameMode == 'PvE') ...[
                          _buildSectionTitle('ĐỘ KHÓ CỦA MÁY'),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildDifficultyBadgeWidget('Easy', 'Dễ', Colors.green),
                              _buildDifficultyBadgeWidget('Medium', 'Vừa', Colors.orange),
                              _buildDifficultyBadgeWidget('Hard', 'Khó', Colors.redAccent),
                              _buildDifficultyBadgeWidget('Asian', 'Châu Á 👑', const Color(0xFFFF2D55)),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Online: hiển thị form tạo/tham gia phòng inline
                        if (gameMode == 'Online') ...[
                          const SizedBox(height: 8),
                          _buildOnlineSetupSection(),
                        ],

                        // Nút bắt đầu cho PvP / PvE
                        if (gameMode != 'Online') ...[
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                aiSymbol = playerSymbol == 'X' ? 'O' : 'X';
                                isGameStarted = true;
                                _initGame();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              shadowColor: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                              elevation: 8,
                            ),
                            child: const Text(
                              'BẮT ĐẦU TRẬN ĐẤU',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: _signOut,
                          icon: const Icon(Icons.logout, size: 16, color: Colors.white38),
                          label: const Text('Đăng xuất tài khoản', style: TextStyle(color: Colors.white38, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.6),
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildModeSelectorCard(String mode, String emoji, String label) {
    final isSelected = gameMode == mode;
    final themeColor = mode == 'Online' ? const Color(0xFF00C896) : const Color(0xFF6C63FF);
    return GestureDetector(
      onTap: () {
        setState(() {
          gameMode = mode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? themeColor.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? themeColor : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: themeColor.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3))]
              : null,
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymbolSelectorCard(String sym, Color color) {
    final isSelected = playerSymbol == sym;
    return GestureDetector(
      onTap: () {
        setState(() {
          playerSymbol = sym;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 6)]
              : null,
        ),
        child: Center(
          child: Text(
            sym,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              shadows: isSelected ? [Shadow(color: color, blurRadius: 6)] : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyBadgeWidget(String diff, String label, Color color) {
    final isSelected = difficulty == diff;
    return GestureDetector(
      onTap: () {
        setState(() {
          difficulty = diff;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.01),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected && diff == 'Asian'
              ? [const BoxShadow(color: Colors.redAccent, blurRadius: 8)]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (!isGameStarted) {
      return _buildSetupScreen();
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C20), Color(0xFF15102A), Color(0xFF06040A)],
          ),
        ),
        child: SafeArea(
          child: Stack(children: [

            // Board area
            Positioned.fill(
              child: Center(
                child: AnimatedBuilder(
                  animation: _shakeAnim ?? const AlwaysStoppedAnimation(0.0),
                  builder: (context, child) {
                    final shakeX = _shakeAnim?.value ?? 0.0;
                    return Transform.translate(
                      offset: Offset(shakeX, 0),
                      child: child,
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 2),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0,10))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        color: const Color(0xFF0F0C24),
                        child: LayoutBuilder(builder: (context, constraints) {
                          final w = constraints.maxWidth;
                          final h = constraints.maxHeight;
                          if (_vpW == 0 && _vpH == 0) {
                            _vpW = w; _vpH = h;
                            WidgetsBinding.instance.addPostFrameCallback((_) => _resetZoom());
                          } else { _vpW = w; _vpH = h; }

                          return Listener(
                            onPointerSignal: (e) { if (e is PointerScrollEvent) _handleScroll(e); },
                            child: InteractiveViewer(
                              transformationController: _tvController,
                              boundaryMargin: const EdgeInsets.all(double.infinity),
                              minScale: 0.3, maxScale: 2.5,
                              panEnabled: true,
                              scaleEnabled: true,
                              constrained: false,
                              child: SizedBox(
                                width: boardSize * _cellSize,
                                height: boardSize * _cellSize,
                                child: Stack(children: [
                                  // Grid
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(boardSize, (r) => Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(boardSize, (c) {
                                        final val = board[r][c];
                                        final isWin = winningLine.any((cell)=>cell[0]==r&&cell[1]==c);
                                        final isLast = lastMoveRow==r&&lastMoveCol==c;
                                        final isPending = _pendingR==r&&_pendingC==c;
                                        return CaroCell(
                                          row: r, col: c,
                                          value: val, isWinning: isWin,
                                          isLastMove: isLast, isPending: isPending,
                                          currentPlayer: currentPlayer,
                                          cellSize: _cellSize,
                                          onTap: () => _handleCellTap(r, c),
                                        );
                                      }),
                                    )),
                                  ),

                                  // Shockwave rings
                                  if (_shockwaveCtrl != null)
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        child: ShockwaveOverlay(
                                          animation: _shockwaveCtrl!,
                                          winner: winner,
                                          boardWidth: boardSize * _cellSize,
                                          boardHeight: boardSize * _cellSize,
                                        ),
                                      ),
                                    ),

                                  // Cell explosion particles
                                  if (_cellParticles.isNotEmpty && _cellExCtrl != null)
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        child: ParticlesOverlay(
                                          controller: _cellExCtrl!,
                                          particles: _cellParticles,
                                          isBoardExplosion: false,
                                        ),
                                      ),
                                    ),

                                  // Board explosion particles (win)
                                  if (_boardParticles.isNotEmpty && _boardExCtrl != null)
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        child: ParticlesOverlay(
                                          controller: _boardExCtrl!,
                                          particles: _boardParticles,
                                          isBoardExplosion: true,
                                        ),
                                      ),
                                    ),

                                  // Rocket
                                  if (_rocket != null && _rocketAnim != null)
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        child: RocketOverlay(
                                          rocket: _rocket,
                                          animation: _rocketAnim,
                                        ),
                                      ),
                                    ),
                                ]),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Top bar
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F0C20).withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 8))],
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Column(mainAxisSize: MainAxisSize.min, children: [
                          const Text('CARO KING', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                              color: Colors.white, letterSpacing: 2,
                              shadows: [Shadow(color: Color(0xFF00E5FF), blurRadius: 12)])),
                          Text('BẢN ĐỒ LỚN ${boardSize}x$boardSize',
                              style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.5), letterSpacing: 1.4)),
                        ]),
                        Container(width: 1, height: 36, color: Colors.white12),
                        if (gameMode != 'Online')
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            const Text('Chế độ:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            _modeBtn('PvP','👥 2 Người'),
                            const SizedBox(width: 8),
                            _modeBtn('PvE','🤖 Máy'),
                          ]),
                        if (gameMode == 'PvE')
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            const Text('Độ khó:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            _diffBtn('Easy','Dễ',Colors.green),
                            const SizedBox(width: 6),
                            _diffBtn('Medium','T.Bình',Colors.orange),
                            const SizedBox(width: 6),
                            _diffBtn('Hard','Khó',Colors.redAccent),
                            const SizedBox(width: 6),
                            _diffBtn('Asian','Châu Á',const Color(0xFFFF9100)),
                          ]),
                        if (gameMode == 'Online' && !_isOnlineWaiting)
                          _buildOnlineStatusBar(),
                        if (gameMode != 'Online' || !_isOnlineWaiting)
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            _playerCard('X', gameMode=='Online' ? (_mySymbol=='X' ? _myNickname.isEmpty ? 'Bạn (X)' : _myNickname : _opponentNickname.isEmpty ? 'Đối thủ' : _opponentNickname) : gameMode=='PvE'?'Bạn (X)':'Người chơi 1', scoreX, currentPlayer=='X'&&!isGameOver),
                            const Padding(padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text('VS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white38))),
                            _playerCard('O', gameMode=='Online' ? (_mySymbol=='O' ? _myNickname.isEmpty ? 'Bạn (O)' : _myNickname : _opponentNickname.isEmpty ? 'Đối thủ' : _opponentNickname) : isAiThinking?'Đang tính...':(gameMode=='PvE'?'Máy':'Người chơi 2'),
                                scoreO, currentPlayer=='O'&&!isGameOver),
                          ]),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(icon: const Icon(Icons.zoom_out, color: Colors.white70), onPressed: () => _zoom(1/1.25), tooltip: 'Thu nhỏ'),
                            Container(height: 20, width: 1, color: Colors.white12),
                            IconButton(icon: const Icon(Icons.filter_center_focus, color: Colors.white), onPressed: _resetZoom, tooltip: 'Căn giữa'),
                            Container(height: 20, width: 1, color: Colors.white12),
                            IconButton(icon: const Icon(Icons.zoom_in, color: Colors.white70), onPressed: () => _zoom(1.25), tooltip: 'Phóng to'),
                          ]),
                        ),
                        if (gameMode == 'Online')
                          IconButton(
                            icon: const Icon(Icons.exit_to_app, color: Colors.white54),
                            tooltip: 'Thoát khỏi phòng',
                            onPressed: _exitOnlineMode,
                          ),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 260),
                          padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.account_circle_outlined, size: 18, color: Color(0xFF00E5FF)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                widget.userEmail,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              iconSize: 18,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              tooltip: 'Sign out',
                              onPressed: _signOut,
                              icon: const Icon(Icons.logout, color: Colors.white54),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom bar
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  'Scroll: kéo bàn cờ  •  Ctrl+Scroll: thu phóng  •  Chạm 2 ngón: phóng to/thu nhỏ',
                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.45), fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      _leaveOnlineMatch();
                      setState(() {
                        isGameStarted = false;
                      });
                    },
                    icon: const Icon(Icons.settings, color: Colors.white),
                    label: const Text('CÀI ĐẶT LẠI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: gameMode == 'Online' ? _resetOnlineGame : _resetGame,
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    label: const Text('CHƠI LẠI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F0C20).withValues(alpha: 0.72),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (gameMode != 'Online') ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _resetAll,
                      icon: const Icon(Icons.cleaning_services, color: Colors.white),
                      label: const Text('RESET TỈ SỐ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF2D55).withValues(alpha: 0.28),
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFFF2D55), width: 1.5),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ]),
              ]),
            ),



            // Waiting for opponent banner
            if (gameMode == 'Online' && _isOnlineWaiting)
              _buildWaitingBanner(),
          ]),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  PAINTERS
// ════════════════════════════════════════════════════════════

class RocketPainter extends CustomPainter {
  final Offset position;
  final double angle;
  final String player;
  final double progress;

  const RocketPainter({required this.position, required this.angle,
    required this.player, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final isX = player == 'X';
    final primary = isX ? const Color(0xFF00E5FF) : const Color(0xFFFF2D55);
    final glow = isX ? const Color(0xFF00B8D4) : const Color(0xFFE91E63);

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(angle + pi / 2);

    final trailLen = 30.0 + 50.0 * progress;
    final trailPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [primary.withValues(alpha: 0.0), primary.withValues(alpha: 0.7)],
      ).createShader(Rect.fromLTWH(-6, 10, 12, trailLen));
    final trailPath = Path()
      ..moveTo(-4, 10)
      ..quadraticBezierTo(-8, 10 + trailLen * 0.5, 0, 10 + trailLen)
      ..quadraticBezierTo(8, 10 + trailLen * 0.5, 4, 10)
      ..close();
    canvas.drawPath(trailPath, trailPaint);

    final glowPaint = Paint()
      ..color = glow.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final bodyPath = _buildBody();
    canvas.drawPath(bodyPath, glowPaint);

    canvas.drawPath(bodyPath, Paint()..color = primary);

    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft, end: Alignment.centerRight,
          colors: [Colors.white.withValues(alpha: 0.4), Colors.transparent],
        ).createShader(const Rect.fromLTWH(-6, -22, 14, 36)),
    );

    final wingPaint = Paint()..color = primary.withValues(alpha: 0.85);
    canvas.drawPath(_buildWingL(), wingPaint);
    canvas.drawPath(_buildWingR(), wingPaint);

    final nosePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    final nosePath = Path()
      ..moveTo(0, -22)
      ..lineTo(-3, -12)
      ..lineTo(3, -12)
      ..close();
    canvas.drawPath(nosePath, nosePaint);

    final ts = TextStyle(
        color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900,
        shadows: [Shadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 3)]);
    final tp = TextPainter(text: TextSpan(text: player, style: ts), textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(-tp.width / 2, -5));

    final t = progress;
    final flameR = 5 + 4 * sin(t * 30);
    final flamePaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white, const Color(0xFFFFB300), const Color(0xFFFF6B00), Colors.transparent],
        stops: const [0.0, 0.4, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: const Offset(0, 13), radius: flameR));
    canvas.drawCircle(const Offset(0, 13), flameR, flamePaint);

    canvas.restore();
  }

  Path _buildBody() => Path()
    ..moveTo(0, -22)
    ..lineTo(-5, -8)
    ..lineTo(-5, 10)
    ..lineTo(5, 10)
    ..lineTo(5, -8)
    ..close();

  Path _buildWingL() => Path()
    ..moveTo(-5, 0)
    ..lineTo(-14, 10)
    ..lineTo(-5, 9)
    ..close();

  Path _buildWingR() => Path()
    ..moveTo(5, 0)
    ..lineTo(14, 10)
    ..lineTo(5, 9)
    ..close();

  @override
  bool shouldRepaint(RocketPainter old) => true;
}

class BombParticlePainter extends CustomPainter {
  final List<BParticle> particles;
  const BombParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      if (p.life <= 0 || p.alpha <= 0) continue;
      switch (p.type) {
        case BParticleType.fire:   _drawFire(canvas, p);   break;
        case BParticleType.smoke:  _drawSmoke(canvas, p);  break;
        case BParticleType.debris: _drawDebris(canvas, p); break;
        case BParticleType.spark:  _drawSpark(canvas, p);  break;
      }
    }
  }

  void _drawFire(Canvas canvas, BParticle p) {
    final a = p.alpha;
    canvas.drawCircle(p.position, p.size * 1.4,
      Paint()..color = p.color.withValues(alpha: a * 0.3)..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size));
    final innerColor = Color.lerp(Colors.white, p.color, 0.4)!.withValues(alpha: a);
    canvas.drawCircle(p.position, p.size,
      Paint()..shader = RadialGradient(
        colors: [innerColor, p.color.withValues(alpha: a * 0.8), p.color.withValues(alpha: 0)],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: p.position, radius: p.size)));
  }

  void _drawSmoke(Canvas canvas, BParticle p) {
    canvas.drawCircle(p.position, p.size,
      Paint()..color = p.color.withValues(alpha: p.alpha * 0.45)..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 0.6));
  }

  void _drawDebris(Canvas canvas, BParticle p) {
    final a = p.alpha;
    canvas.save();
    canvas.translate(p.position.dx, p.position.dy);
    canvas.rotate(p.rotation);
    if (p.isTriangle) {
      final path = Path()
        ..moveTo(0, -p.size)
        ..lineTo(p.size * 0.8, p.size * 0.6)
        ..lineTo(-p.size * 0.8, p.size * 0.6)
        ..close();
      canvas.drawPath(path, Paint()..color = p.color.withValues(alpha: a)..style = PaintingStyle.fill);
    } else {
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size * 1.4, height: p.size * 0.6),
        Paint()..color = p.color.withValues(alpha: a),
      );
    }
    canvas.drawCircle(Offset.zero, p.size * 0.6,
        Paint()..color = p.color.withValues(alpha: a * 0.3)..maskFilter = MaskFilter.blur(BlurStyle.normal, 3));
    canvas.restore();
  }

  void _drawSpark(Canvas canvas, BParticle p) {
    if (p.velocity.distance < 1) return;
    final dir = p.velocity / p.velocity.distance;
    final tail = p.position - dir * p.size * 12 * p.alpha;
    canvas.drawLine(tail, p.position, Paint()
      ..strokeWidth = p.size
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [p.color.withValues(alpha: 0), p.color.withValues(alpha: p.alpha)],
      ).createShader(Rect.fromPoints(tail, p.position)));
  }

  @override
  bool shouldRepaint(BombParticlePainter old) => true;
}

class ShockwavePainter extends CustomPainter {
  final Offset center;
  final List<double> radii;
  final List<double> alphas;
  final Color color;

  const ShockwavePainter({required this.center, required this.radii, required this.alphas, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < radii.length; i++) {
      final r = radii[i];
      final a = alphas[i];
      if (r <= 0 || a <= 0) continue;
      canvas.drawCircle(center, r, Paint()
        ..color = color.withValues(alpha: a * 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15));
      canvas.drawCircle(center, r, Paint()
        ..color = color.withValues(alpha: a * 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5);
      if (i == 0 && a > 0.6) {
        canvas.drawCircle(center, r * 0.3, Paint()
          ..color = Colors.white.withValues(alpha: (a - 0.6) * 2 * 0.15)
          ..style = PaintingStyle.fill);
      }
    }
  }

  @override
  bool shouldRepaint(ShockwavePainter old) => old.radii != radii || old.alphas != alphas;
}

// ════════════════════════════════════════════════════════════
//  CARO CELL WIDGET
// ════════════════════════════════════════════════════════════
class CaroCell extends StatefulWidget {
  final int row, col;
  final String value;
  final bool isWinning, isLastMove, isPending;
  final String currentPlayer;
  final VoidCallback onTap;
  final double cellSize;

  const CaroCell({
    super.key,
    required this.row, required this.col,
    required this.value, required this.isWinning,
    required this.isLastMove, required this.isPending,
    required this.currentPlayer, required this.onTap,
    required this.cellSize,
  });

  @override
  State<CaroCell> createState() => _CaroCellState();
}

class _CaroCellState extends State<CaroCell> with SingleTickerProviderStateMixin {
  bool _hovered = false;
  AnimationController? _pulseCtrl;
  Animation<double>? _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl!, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _pulseCtrl?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final pc = widget.currentPlayer == 'X' ? const Color(0xFF00E5FF) : const Color(0xFFFF2D55);
    Color cellBg = Colors.white.withValues(alpha: 0.03);
    if (widget.isWinning) {
      cellBg = const Color(0xFF4CAF50).withValues(alpha: 0.25);
    } else if (widget.isLastMove) {
      cellBg = const Color(0xFFFFC107).withValues(alpha: 0.15);
    } else if (_hovered && widget.value.isEmpty) {
      cellBg = pc.withValues(alpha: 0.08);
    }

    final interactive = widget.value.isEmpty && !widget.isWinning && !widget.isPending;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: interactive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: widget.cellSize - 4, height: widget.cellSize - 4,
          margin: const EdgeInsets.all(2),
          transformAlignment: Alignment.center,
          transform: Matrix4.identity()
            ..scaleByDouble(
              _hovered && interactive ? 1.07 : 1.0,
              _hovered && interactive ? 1.07 : 1.0,
              1.0,
              1.0,
            ),
          decoration: BoxDecoration(
            color: cellBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: widget.isWinning ? const Color(0xFF4CAF50).withValues(alpha: 0.9)
                  : widget.isLastMove ? const Color(0xFFFFC107).withValues(alpha: 0.7)
                  : _hovered && interactive ? pc.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.12),
              width: widget.isWinning || widget.isLastMove || _hovered ? 1.5 : 1.0,
            ),
            boxShadow: _hovered && interactive
                ? [BoxShadow(color: pc.withValues(alpha: 0.2), blurRadius: 8, spreadRadius: 1)]
                : null,
          ),
          alignment: Alignment.center,
          child: widget.value.isNotEmpty
              ? TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 380),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.elasticOut,
                  builder: (_, s, child) => Transform.scale(scale: s, child: child),
                  child: _buildMark(widget.value),
                )
              : _hovered && interactive && _pulseAnim != null
                  ? AnimatedBuilder(
                      animation: _pulseAnim!,
                      builder: (_, _) => CustomPaint(
                        size: Size(widget.cellSize - 8, widget.cellSize - 8),
                        painter: CrosshairPainter(color: pc, opacity: _pulseAnim!.value),
                      ),
                    )
                  : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildMark(String val) => Text(
    val,
    style: TextStyle(
      fontSize: 20, fontWeight: FontWeight.bold,
      color: val == 'X' ? const Color(0xFF00E5FF) : const Color(0xFFFF2D55),
      shadows: [Shadow(
        color: val == 'X' ? const Color(0xFF00E5FF) : const Color(0xFFFF2D55),
        blurRadius: 8,
      )],
    ),
  );
}

// ════════════════════════════════════════════════════════════
//  CROSSHAIR PAINTER
// ════════════════════════════════════════════════════════════
class CrosshairPainter extends CustomPainter {
  final Color color;
  final double opacity;
  const CrosshairPainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = min(cx, cy) * 0.65;
    final gap = r * 0.28;
    final tickLen = r * 0.42;
    final corner = r * 0.88;
    final cLen = r * 0.28;

    Paint linePaint(double strokeW) => Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    Paint glowPaint(double strokeW) => Paint()
      ..color = color.withValues(alpha: opacity * 0.25)
      ..strokeWidth = strokeW + 3
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(Offset(cx, cy), r * 0.22, glowPaint(1.5));
    canvas.drawCircle(Offset(cx, cy), r * 0.22, linePaint(1.2));

    for (final line in [
      [Offset(cx, cy - gap), Offset(cx, cy - gap - tickLen)],
      [Offset(cx, cy + gap), Offset(cx, cy + gap + tickLen)],
      [Offset(cx - gap, cy), Offset(cx - gap - tickLen, cy)],
      [Offset(cx + gap, cy), Offset(cx + gap + tickLen, cy)],
    ]) {
      canvas.drawLine(line[0], line[1], glowPaint(1.5));
      canvas.drawLine(line[0], line[1], linePaint(1.5));
    }

    final corners = [
      [Offset(cx-corner, cy-corner), Offset(cx-corner+cLen, cy-corner), Offset(cx-corner, cy-corner+cLen)],
      [Offset(cx+corner, cy-corner), Offset(cx+corner-cLen, cy-corner), Offset(cx+corner, cy-corner+cLen)],
      [Offset(cx-corner, cy+corner), Offset(cx-corner+cLen, cy+corner), Offset(cx-corner, cy+corner-cLen)],
      [Offset(cx+corner, cy+corner), Offset(cx+corner-cLen, cy+corner), Offset(cx+corner, cy+corner-cLen)],
    ];
    for (final pts in corners) {
      canvas.drawLine(pts[0], pts[1], glowPaint(1.5));
      canvas.drawLine(pts[0], pts[2], glowPaint(1.5));
      canvas.drawLine(pts[0], pts[1], linePaint(1.5));
      canvas.drawLine(pts[0], pts[2], linePaint(1.5));
    }
  }

  @override
  bool shouldRepaint(CrosshairPainter old) => old.opacity != opacity;
}

// ════════════════════════════════════════════════════════════
//  OPTIMIZED ANIMATION OVERLAYS (TỐI ƯU HIỆU NĂNG)
// ════════════════════════════════════════════════════════════

// Widget quản lý và tự cập nhật các hạt nổ độc lập, tránh rebuild bàn cờ
class ParticlesOverlay extends StatefulWidget {
  final AnimationController controller;
  final List<BParticle> particles;
  final bool isBoardExplosion;

  const ParticlesOverlay({
    super.key,
    required this.controller,
    required this.particles,
    this.isBoardExplosion = false,
  });

  @override
  State<ParticlesOverlay> createState() => _ParticlesOverlayState();
}

class _ParticlesOverlayState extends State<ParticlesOverlay> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateParticles);
  }

  @override
  void didUpdateWidget(ParticlesOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_updateParticles);
      widget.controller.addListener(_updateParticles);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateParticles);
    super.dispose();
  }

  // Cập nhật vị trí và thuộc tính hạt theo thời gian thực (mỗi frame)
  void _updateParticles() {
    if (!mounted) return;
    const dt = 0.016; // Giả lập thời gian delta mỗi frame 60fps
    if (widget.isBoardExplosion) {
      for (final p in widget.particles) {
        if (p.life <= 0) continue;
        p.position += p.velocity * dt;
        p.velocity = Offset(p.velocity.dx * 0.98, p.velocity.dy * 0.98);
        if (p.type == BParticleType.debris || p.type == BParticleType.spark) {
          p.velocity = Offset(p.velocity.dx, p.velocity.dy + 80 * dt);
        }
        if (p.type == BParticleType.smoke) {
          p.size = (p.size + dt * 12).clamp(0, 80);
          p.velocity = Offset(p.velocity.dx, p.velocity.dy - 8 * dt);
        }
        p.life -= p.maxLife / (1.4 / dt);
        p.rotation += p.rotSpeed * dt;
      }
    } else {
      for (final p in widget.particles) {
        if (p.life <= 0) continue;
        p.position += p.velocity * dt;
        p.velocity = Offset(p.velocity.dx * 0.97, p.velocity.dy * 0.97);
        if (p.type == BParticleType.debris || p.type == BParticleType.spark) {
          p.velocity = Offset(p.velocity.dx, p.velocity.dy + 120 * dt);
        }
        if (p.type == BParticleType.smoke) {
          p.size = (p.size + dt * 8).clamp(0, 60);
          p.velocity = Offset(p.velocity.dx, p.velocity.dy - 5 * dt);
        }
        p.life -= p.maxLife / (0.8 / dt);
        p.rotation += p.rotSpeed * dt;
      }
    }
    setState(() {}); // Chỉ rebuild nội bộ widget nổ hạt
  }

  @override
  Widget build(BuildContext context) {
    if (widget.particles.isEmpty) return const SizedBox.shrink();
    return CustomPaint(
      painter: BombParticlePainter(widget.particles),
    );
  }
}

// Widget quản lý hiệu ứng vòng loang chấn độc lập khi thắng cuộc
class ShockwaveOverlay extends StatelessWidget {
  final Animation<double> animation;
  final String winner;
  final double boardWidth;
  final double boardHeight;

  const ShockwaveOverlay({
    super.key,
    required this.animation,
    required this.winner,
    required this.boardWidth,
    required this.boardHeight,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        final maxRadius = max(boardWidth, boardHeight) * 0.85;
        final radii = <double>[];
        final alphas = <double>[];
        
        // Tính toán bán kính và độ mờ của 3 vòng loang
        for (int i = 0; i < 3; i++) {
          final delay = i * 0.15;
          final localT = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
          radii.add(localT * maxRadius);
          alphas.add((1.0 - localT) * (i == 0 ? 0.9 : i == 1 ? 0.6 : 0.35));
        }

        return CustomPaint(
          painter: ShockwavePainter(
            center: Offset(boardWidth / 2, boardHeight / 2),
            radii: radii,
            alphas: alphas,
            color: winner == 'X' ? const Color(0xFF00E5FF) : const Color(0xFFFF2D55),
          ),
        );
      },
    );
  }
}

// Widget quản lý chuyển động tên lửa bay độc lập, tránh rebuild bàn cờ
class RocketOverlay extends StatelessWidget {
  final RocketData? rocket;
  final Animation<double>? animation;

  const RocketOverlay({
    super.key,
    this.rocket,
    this.animation,
  });

  @override
  Widget build(BuildContext context) {
    if (rocket == null || animation == null) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: animation!,
      builder: (context, _) {
        final t = animation!.value;
        final pos = Offset.lerp(rocket!.start, rocket!.end, t)!;
        return CustomPaint(
          painter: RocketPainter(
            position: pos,
            angle: rocket!.angle,
            player: rocket!.player,
            progress: t,
          ),
        );
      },
    );
  }
}

