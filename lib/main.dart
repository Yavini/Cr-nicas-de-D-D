import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

void main() {
  runApp(const DnDBattleApp());
}

enum GameMode {
  singlePlayer,
  twoPlayersCoop,
  twoPlayersPvp,
  freeBattleRealtime,
}

enum BotDifficulty {
  easy,
  medium,
  hard,
}

enum ActionCostType {
  action,
  bonusAction,
  freePassive,
}

enum TargetType {
  enemySingle,
  allyOrSelf,
  selfOnly,
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

class DnDBattleApp extends StatelessWidget {
  const DnDBattleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'D&D 5e Arena & Batalha Livre',
      debugShowCheckedModeBanner: false,
      scrollBehavior: AppScrollBehavior(),
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1412),
        fontFamily: 'Georgia',
      ),
      home: const HomeScreen(),
    );
  }
}

// ==========================================
// 1. TELA INICIAL (MODO ARENA POR TURNOS + MODO BATALHA LIVRE)
// ==========================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _intro;
  final ValueNotifier<Offset> _pointer = ValueNotifier(Offset.zero);
  bool _isHoveringPlay = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _intro.dispose();
    _pointer.dispose();
    super.dispose();
  }

  void _showBotDifficultyDialog(BuildContext context, GameMode mode) {
    BotDifficulty selectedDifficulty = BotDifficulty.medium;
    int botCount = mode == GameMode.twoPlayersCoop ? 2 : 2;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF231814),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: const BorderSide(color: Color(0xFFD4AF37), width: 2.5),
              ),
              title: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.smart_toy, color: Color(0xFFD4AF37)),
                  SizedBox(width: 10),
                  Text(
                    'CONFIGURAR BOTS DA ARENA',
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nível de Inteligência e Poder dos Inimigos:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontFamily: 'sans-serif',
                      ),
                    ),
                    const SizedBox(height: 10),
                    _difficultyTile(
                      title: 'FÁCIL (Iniciante)',
                      subtitle:
                          'Bots com menos PV, movimentação básica e raramente usam habilidades.',
                      color: Colors.lightGreenAccent,
                      selected: selectedDifficulty == BotDifficulty.easy,
                      onTap: () => setDialogState(
                          () => selectedDifficulty = BotDifficulty.easy),
                    ),
                    const SizedBox(height: 8),
                    _difficultyTile(
                      title: 'MÉDIO (Tático)',
                      subtitle:
                          'Bots equilibrados, buscam alcance ideal e usam habilidades próprias.',
                      color: Colors.amberAccent,
                      selected: selectedDifficulty == BotDifficulty.medium,
                      onTap: () => setDialogState(
                          () => selectedDifficulty = BotDifficulty.medium),
                    ),
                    const SizedBox(height: 8),
                    _difficultyTile(
                      title: 'DIFÍCIL (Estrategista)',
                      subtitle:
                          'Bots focam alvos feridos, combinam habilidades e têm atributos elevados.',
                      color: Colors.redAccent,
                      selected: selectedDifficulty == BotDifficulty.hard,
                      onTap: () => setDialogState(
                          () => selectedDifficulty = BotDifficulty.hard),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Quantidade de Bots na Arena:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            fontFamily: 'sans-serif',
                          ),
                        ),
                        Row(
                          children: [1, 2, 3].map((count) {
                            final bool isSel = botCount == count;
                            return Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: ChoiceChip(
                                label: Text(
                                  '$count ${count == 1 ? "Bot" : "Bots"}',
                                  style: TextStyle(
                                    color: isSel
                                        ? const Color(0xFF1A110E)
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'sans-serif',
                                  ),
                                ),
                                selected: isSel,
                                selectedColor: const Color(0xFFD4AF37),
                                backgroundColor: Colors.black45,
                                onSelected: (_) =>
                                    setDialogState(() => botCount = count),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Voltar',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CharacterSelectionScreen(
                          mode: mode,
                          botDifficulty: selectedDifficulty,
                          botCount: botCount,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: const Color(0xFF1A110E),
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text(
                    'CONTINUAR',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _difficultyTile({
    required String title,
    required String subtitle,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.18) : Colors.black45,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.white24,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? color : Colors.white54,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      fontFamily: 'sans-serif',
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontFamily: 'sans-serif',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showModeSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF231814),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFFD4AF37), width: 2.5),
        ),
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_moon, color: Color(0xFFD4AF37)),
            SizedBox(width: 10),
            Text(
              'ESCOLHA O MODO DE JOGO',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 470,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _modeOptionTile(
                icon: Icons.bolt,
                title: 'BATALHA LIVRE TEMPO REAL (2 Jogadores)',
                subtitle:
                    'P1 (WASD) vs P2 (Setas)! Ação livre em tempo real, obstáculos e 3 poderes por herói.',
                accentColor: Colors.cyanAccent,
                onTap: () {
                  Navigator.pop(dialogContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CharacterSelectionScreen(
                        mode: GameMode.freeBattleRealtime,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _modeOptionTile(
                icon: Icons.person,
                title: 'BATALHA EM ARENA 1 JOGADOR (vs Bots)',
                subtitle:
                    'Escolha a dificuldade (Fácil/Médio/Difícil) e enfrente até 3 bots inteligentes.',
                accentColor: const Color(0xFF95D5B2),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _showBotDifficultyDialog(context, GameMode.singlePlayer);
                },
              ),
              const SizedBox(height: 12),
              _modeOptionTile(
                icon: Icons.groups,
                title: 'BATALHA EM ARENA 2J COOPERATIVO (vs Bots)',
                subtitle:
                    'Player 1 e Player 2 unem forças contra múltiplos bots com habilidades próprias.',
                accentColor: const Color(0xFFFFD54F),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _showBotDifficultyDialog(context, GameMode.twoPlayersCoop);
                },
              ),
              const SizedBox(height: 12),
              _modeOptionTile(
                icon: Icons.sports_kabaddi,
                title: 'BATALHA EM ARENA 2J DUELO PVP (Turnos)',
                subtitle:
                    'Duelo tático por turnos com Pontos de Magia (PM), Testes de Resistência e D20.',
                accentColor: const Color(0xFFFF4D6D),
                onTap: () {
                  Navigator.pop(dialogContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CharacterSelectionScreen(
                        mode: GameMode.twoPlayersPvp,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentColor.withOpacity(0.75), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      fontFamily: 'sans-serif',
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11.5,
                      fontFamily: 'sans-serif',
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: accentColor, size: 16),
          ],
        ),
      ),
    );
  }

  // BLOCO B — _reveal + novo build (ver instruções no chat)

  // Aparece com fade + sobe suavemente, num intervalo da animação de entrada
  Widget _reveal({
    required double begin,
    required double end,
    required Widget child,
    double dy = 30,
  }) {
    final interval = Interval(begin, end, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: _intro,
      child: child,
      builder: (context, child) {
        final v = interval.transform(_intro.value);
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * dy),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    const cream = Color(0xFFF5E6C8);
    const titleStyle = TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.bold,
      letterSpacing: 3,
      color: Colors.white,
    );

    return Scaffold(
      body: Listener(
        // translucent: recebe o mouse mesmo com widgets por cima
        behavior: HitTestBehavior.translucent,
        onPointerHover: (e) {
          final size = MediaQuery.of(context).size;
          _pointer.value = Offset(
            (e.position.dx / size.width * 2 - 1).clamp(-1.0, 1.0).toDouble(),
            (e.position.dy / size.height * 2 - 1).clamp(-1.0, 1.0).toDouble(),
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ===== FUNDO ANIMADO =====
            AnimatedFantasyBackground(pointer: _pointer),

            // ===== CONTEÚDO =====
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // ---------- TÍTULO ----------
                      _reveal(
                        begin: 0.0,
                        end: 0.45,
                        dy: -24,
                        child: Column(
                          children: [
                            AnimatedBuilder(
                              animation: _controller,
                              builder: (context, _) {
                                final v =
                                    Curves.easeInOut.transform(_controller.value);
                                return Icon(
                                  Icons.shield_moon,
                                  color: gold,
                                  size: 44,
                                  shadows: [
                                    Shadow(
                                      color: gold.withOpacity(0.35 + 0.4 * v),
                                      blurRadius: 12 + 16 * v,
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            // Título com brilho dourado que passa por cima
                            AnimatedBuilder(
                              animation: _controller,
                              builder: (context, _) {
                                final v =
                                    Curves.easeInOut.transform(_controller.value);
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // sombra
                                    Transform.translate(
                                      offset: const Offset(2, 4),
                                      child: Text(
                                        'CRÔNICAS DE D&D 5E',
                                        textAlign: TextAlign.center,
                                        style: titleStyle.copyWith(
                                          color: Colors.black.withOpacity(0.55),
                                        ),
                                      ),
                                    ),
                                    ShaderMask(
                                      blendMode: BlendMode.srcIn,
                                      shaderCallback: (rect) => LinearGradient(
                                        begin: Alignment(-1.6 + 3.2 * v, 0),
                                        end: Alignment(-0.4 + 3.2 * v, 0),
                                        colors: const [
                                          cream,
                                          Color(0xFFFFE9A8),
                                          cream,
                                        ],
                                      ).createShader(rect),
                                      child: const Text(
                                        'CRÔNICAS DE D&D 5E',
                                        textAlign: TextAlign.center,
                                        style: titleStyle,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '~ Arena Tática & Batalha Livre ~',
                              style: TextStyle(
                                fontSize: 17,
                                fontStyle: FontStyle.italic,
                                color: gold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ---------- D20 FLUTUANDO COM AURA ----------
                      _reveal(
                        begin: 0.2,
                        end: 0.75,
                        dy: 40,
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) {
                            final v =
                                Curves.easeInOut.transform(_controller.value);
                            final wave =
                                math.sin(_controller.value * math.pi * 2);
                            return Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                // aura pulsante
                                Container(
                                  width: 260,
                                  height: 260,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        gold.withOpacity(0.16 + 0.18 * v),
                                        gold.withOpacity(0.0),
                                      ],
                                    ),
                                  ),
                                ),
                                // dado flutuando e girando levemente em 3D
                                Transform.translate(
                                  offset: Offset(0, wave * 8),
                                  child: Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()
                                      ..setEntry(3, 2, 0.0012)
                                      ..rotateY(wave * 0.35)
                                      ..rotateZ((v - 0.5) * 0.12),
                                    child: CustomPaint(
                                      size: const Size(170, 170),
                                      painter: D20Painter(),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      // ---------- BOTÃO JOGAR ----------
                      _reveal(
                        begin: 0.5,
                        end: 1.0,
                        dy: 40,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          onEnter: (_) => setState(() => _isHoveringPlay = true),
                          onExit: (_) => setState(() => _isHoveringPlay = false),
                          child: GestureDetector(
                            onTap: () => _showModeSelectionDialog(context),
                            child: AnimatedScale(
                              scale: _isHoveringPlay ? 1.07 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // halo pulsante atrás do botão
                                  Positioned.fill(
                                    child: AnimatedBuilder(
                                      animation: _controller,
                                      builder: (context, _) {
                                        final v = Curves.easeInOut
                                            .transform(_controller.value);
                                        return DecoratedBox(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: gold.withOpacity(
                                                    0.10 + 0.25 * v),
                                                blurRadius: 30 + 20 * v,
                                                spreadRadius: 2 + 6 * v,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  // botão (igual ao seu)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 60,
                                      vertical: 18,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: _isHoveringPlay
                                            ? const [
                                                Color(0xFFB71C1C),
                                                Color(0xFF6A0000),
                                              ]
                                            : const [
                                                Color(0xFF8B0000),
                                                Color(0xFF4A0000),
                                              ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _isHoveringPlay
                                            ? const Color(0xFFFFE082)
                                            : gold,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: gold.withOpacity(
                                              _isHoveringPlay ? 0.65 : 0.3),
                                          blurRadius: _isHoveringPlay ? 25 : 15,
                                          spreadRadius: _isHoveringPlay ? 4 : 2,
                                        ),
                                        const BoxShadow(
                                          color: Colors.black,
                                          offset: Offset(0, 6),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.play_arrow_rounded,
                                            color: cream, size: 34),
                                        SizedBox(width: 8),
                                        Text(
                                          'JOGAR',
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 4,
                                            color: cream,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // faixa de brilho deslizando sobre o botão
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: AnimatedBuilder(
                                          animation: _controller,
                                          builder: (context, _) {
                                            final v = Curves.easeInOut
                                                .transform(_controller.value);
                                            return DecoratedBox(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Colors.white.withOpacity(0),
                                                    Colors.white
                                                        .withOpacity(0.20),
                                                    Colors.white.withOpacity(0),
                                                  ],
                                                  stops: const [0.4, 0.5, 0.6],
                                                  transform:
                                                      _SlideGradientTransform(
                                                          -1.0 + 2.0 * v),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAntigo(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFF3E2723),
              Color(0xFF1A110E),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      const Icon(
                        Icons.shield_moon,
                        color: Color(0xFFD4AF37),
                        size: 44,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'CRÔNICAS DE D&D 5E',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                          color: const Color(0xFFF5E6C8),
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.8),
                              offset: const Offset(2, 4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '~ Arena Tática & Batalha Livre ~',
                        style: TextStyle(
                          fontSize: 17,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                    ],
                  ),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                            0, math.sin(_controller.value * math.pi * 2) * 8),
                        child: CustomPaint(
                          size: const Size(170, 170),
                          painter: D20Painter(),
                        ),
                      );
                    },
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => _isHoveringPlay = true),
                    onExit: (_) => setState(() => _isHoveringPlay = false),
                    child: GestureDetector(
                      onTap: () => _showModeSelectionDialog(context),
                      child: AnimatedScale(
                        scale: _isHoveringPlay ? 1.07 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 60,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isHoveringPlay
                                  ? [
                                      const Color(0xFFB71C1C),
                                      const Color(0xFF6A0000)
                                    ]
                                  : [
                                      const Color(0xFF8B0000),
                                      const Color(0xFF4A0000)
                                    ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isHoveringPlay
                                  ? const Color(0xFFFFE082)
                                  : const Color(0xFFD4AF37),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD4AF37).withOpacity(
                                    _isHoveringPlay ? 0.65 : 0.3),
                                blurRadius: _isHoveringPlay ? 25 : 15,
                                spreadRadius: _isHoveringPlay ? 4 : 2,
                              ),
                              const BoxShadow(
                                color: Colors.black,
                                offset: Offset(0, 6),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow_rounded,
                                  color: Color(0xFFF5E6C8), size: 34),
                              SizedBox(width: 8),
                              Text(
                                'JOGAR',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4,
                                  color: Color(0xFFF5E6C8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. TELA DE SELEÇÃO DE CAMPEÃO (HABILIDADES EQUILIBRADAS)
// ==========================================
class CharacterSelectionScreen extends StatefulWidget {
  final GameMode mode;
  final BotDifficulty botDifficulty;
  final int botCount;

  const CharacterSelectionScreen({
    super.key,
    required this.mode,
    this.botDifficulty = BotDifficulty.medium,
    this.botCount = 1,
  });

  @override
  State<CharacterSelectionScreen> createState() =>
      _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _runeRotationController;
  CharacterData? _player1Choice;

  final List<CharacterData> _characters = [
    // =====================================
    // AFRODITE - DRUIDA NV.7 (5 Habilidades + 9 Magias)
    // =====================================
    CharacterData(
      name: 'AFRODITE',
      className: 'Druida • Nv.7',
      subclass: 'Círculo dos Esporos',
      badgeText: '38 PM • 4º CÍRCULO',
      quote: '"Mas quem realmente sou eu?"',
      speedMeters: 9.0,
      maxHp: 52,
      ac: 15,
      maxSpellPoints: 38,
      spellSaveDc: 15,
      spellAttackBonus: 7,
      strMod: -1,
      dexMod: 2,
      conMod: 1,
      intMod: 1,
      wisMod: 4,
      chaMod: 3,
      attacks: [
        MeleeAttack(
          name: 'Cajado (Bordão Místico)',
          description: 'Usa Sabedoria (+4) + Prof (+3) = +7 no acerto.',
          diceCount: 1,
          diceSides: 8,
          attackMod: 7,
          damageMod: 4,
          statLabel: 'SAB +4',
          damageType: 'Contundente',
          icon: Icons.eco,
          isFinesse: false,
        ),
        MeleeAttack(
          name: 'Garras Fúngicas',
          description: 'Toque necrótico canalizado com Sabedoria (+7).',
          diceCount: 1,
          diceSides: 6,
          attackMod: 7,
          damageMod: 4,
          statLabel: 'SAB +4',
          damageType: 'Necrótico',
          icon: Icons.back_hand,
          isFinesse: false,
        ),
      ],
      spells: [
        SpellItem(
          id: 'afro_toque_arrepiante',
          name: 'Toque Arrepiante',
          circle: 0,
          pmCost: 0,
          costType: ActionCostType.action,
          targetType: TargetType.enemySingle,
          rangeMeters: 36.0,
          description: 'Truque (36m): 2d8 necrótico (Nv.7).',
          diceCount: 2,
          diceSides: 8,
          flatBonus: 0,
          usesSpellAttack: true,
          isHealing: false,
          icon: Icons.dark_mode,
        ),
        SpellItem(
          id: 'afro_produzir_chama',
          name: 'Produzir Chama',
          circle: 0,
          pmCost: 0,
          costType: ActionCostType.action,
          targetType: TargetType.enemySingle,
          rangeMeters: 9.0,
          description: 'Truque (9m): 2d8 fogo (Nv.7).',
          diceCount: 2,
          diceSides: 8,
          flatBonus: 0,
          usesSpellAttack: true,
          isHealing: false,
          icon: Icons.local_fire_department,
        ),
        SpellItem(
          id: 'afro_borrifada',
          name: 'Borrifada Venenosa',
          circle: 0,
          pmCost: 0,
          costType: ActionCostType.action,
          targetType: TargetType.enemySingle,
          rangeMeters: 4.5,
          description: 'Truque (4,5m): Resist. CON (CD 15) ou 2d12 veneno.',
          diceCount: 2,
          diceSides: 12,
          flatBonus: 0,
          usesSpellAttack: false,
          saveStat: 'CON',
          halfOnSave: false,
          isHealing: false,
          icon: Icons.science,
        ),
        SpellItem(
          id: 'afro_palavra_curativa',
          name: 'Palavra Curativa',
          circle: 1,
          pmCost: 2,
          costType: ActionCostType.bonusAction,
          targetType: TargetType.allyOrSelf,
          rangeMeters: 18.0,
          description: '1° Círculo (Ação Bônus 18m): Cura 1d4+4 PV.',
          diceCount: 1,
          diceSides: 4,
          flatBonus: 4,
          usesSpellAttack: false,
          isHealing: true,
          icon: Icons.healing,
        ),
        SpellItem(
          id: 'afro_curar_ferimentos',
          name: 'Curar Ferimentos',
          circle: 1,
          pmCost: 2,
          costType: ActionCostType.action,
          targetType: TargetType.allyOrSelf,
          rangeMeters: 1.5,
          description: '1° Círculo (Toque): Cura 1d8+4 PV.',
          diceCount: 1,
          diceSides: 8,
          flatBonus: 4,
          usesSpellAttack: false,
          isHealing: true,
          icon: Icons.favorite,
        ),
        SpellItem(
          id: 'afro_onda_trovejante',
          name: 'Onda Trovejante',
          circle: 1,
          pmCost: 2,
          costType: ActionCostType.action,
          targetType: TargetType.enemySingle,
          rangeMeters: 4.5,
          description: '1° Círculo (4,5m): Resist. CON (CD 15), 2d8 trovejante.',
          diceCount: 2,
          diceSides: 8,
          flatBonus: 0,
          usesSpellAttack: false,
          saveStat: 'CON',
          halfOnSave: true,
          isHealing: false,
          icon: Icons.bolt,
        ),
        SpellItem(
          id: 'afro_raio_lunar',
          name: 'Raio Lunar',
          circle: 2,
          pmCost: 3,
          costType: ActionCostType.action,
          targetType: TargetType.enemySingle,
          rangeMeters: 36.0,
          description: '2° Círculo (36m): Resist. CON (CD 15), 2d10 radiante.',
          diceCount: 2,
          diceSides: 10,
          flatBonus: 0,
          usesSpellAttack: false,
          saveStat: 'CON',
          halfOnSave: true,
          isHealing: false,
          icon: Icons.nights_stay,
        ),
        SpellItem(
          id: 'afro_convocar_relampagos',
          name: 'Convocar Relâmpagos',
          circle: 3,
          pmCost: 5,
          costType: ActionCostType.action,
          targetType: TargetType.enemySingle,
          rangeMeters: 36.0,
          description: '3° Círculo (36m): Resist. DES (CD 15), 3d10 elétrico.',
          diceCount: 3,
          diceSides: 10,
          flatBonus: 0,
          usesSpellAttack: false,
          saveStat: 'DES',
          halfOnSave: true,
          isHealing: false,
          icon: Icons.flash_on,
        ),
        SpellItem(
          id: 'afro_malogro',
          name: 'Malogro (Esporos)',
          circle: 4,
          pmCost: 6,
          costType: ActionCostType.action,
          targetType: TargetType.enemySingle,
          rangeMeters: 9.0,
          description: '4° Círculo (9m): Resist. CON (CD 15), 8d8 necrótico!',
          diceCount: 8,
          diceSides: 8,
          flatBonus: 0,
          usesSpellAttack: false,
          saveStat: 'CON',
          halfOnSave: true,
          isHealing: false,
          icon: Icons.coronavirus,
        ),
      ],
      abilities: [
        ClassAbilityItem(
          id: 'afro_entidade_simbiotica',
          name: 'Entidade Simbiótica',
          costType: ActionCostType.action,
          maxUses: 2,
          description:
              'Gasta 1 Forma Selvagem: +28 PV temp, dobra Halo (2d6) e +1d6 necrótico nos ataques.',
          icon: Icons.shield_moon,
        ),
        ClassAbilityItem(
          id: 'afro_forma_selvagem',
          name: 'Forma Selvagem (Lobo)',
          costType: ActionCostType.action,
          maxUses: 2,
          description:
              'Gasta 1 Forma Selvagem: assume forma de fera com +22 PV de besta.',
          icon: Icons.pets,
        ),
        ClassAbilityItem(
          id: 'afro_halo_esporos',
          name: 'Halo de Esporos (4,5m)',
          costType: ActionCostType.bonusAction,
          maxUses: 99,
          description:
              'Ação Bônus: alvo a 4,5m faz Resist. CON (CD 15) ou sofre 1d6 (2d6 Simbiótica) necrótico.',
          icon: Icons.blur_on,
        ),
        ClassAbilityItem(
          id: 'afro_nuvem_esporos',
          name: 'Nuvem de Esporos (9m)',
          costType: ActionCostType.action,
          maxUses: 2,
          description:
              'Lança esporos a até 9m: alvo faz Resist. CON (CD 15) ou sofre 3d6 veneno (metade se passar).',
          icon: Icons.cloud,
        ),
        ClassAbilityItem(
          id: 'afro_recuperacao_natural',
          name: 'Recuperação Natural',
          costType: ActionCostType.bonusAction,
          maxUses: 1,
          description:
              '1 uso: medita brevemente e recupera +8 PM durante o combate.',
          icon: Icons.spa,
        ),
      ],
      themeGradient: const [Color(0xFF1B4332), Color(0xFF2D6A4F)],
      themeColor: const Color(0xFF95D5B2),
      imagePath: 'assets/Afrodite.jpg',
      bgIcon1: Icons.grass,
      bgIcon2: Icons.eco,
      decoEmoji: '🌿',
    ),

    // =====================================
    // ALASH - PALADINA NV.7 (5 Habilidades + 7 Magias)
    // =====================================
    CharacterData(
      name: 'ALASH',
      className: 'Paladina • Nv.7',
      subclass: 'Juramento da Devoção (Tyr)',
      badgeText: '18 PM • 2º CÍRCULO',
      quote: '"Ter pena dos culpados é trair os inocentes."',
      speedMeters: 6.0,
      maxHp: 68,
      ac: 18,
      maxSpellPoints: 18,
      spellSaveDc: 14,
      spellAttackBonus: 6,
      strMod: 3,
      dexMod: 0,
      conMod: 2,
      intMod: 0,
      wisMod: 1,
      chaMod: 3,
      attacks: [
        MeleeAttack(
          name: 'Espada Motosserra',
          description: 'Usa Força (+3) + Prof (+3) = +6 no acerto.',
          diceCount: 2,
          diceSides: 8,
          attackMod: 6,
          damageMod: 3,
          statLabel: 'FOR +3',
          damageType: 'Cortante',
          icon: Icons.carpenter,
          isFinesse: false,
        ),
        MeleeAttack(
          name: 'Soco de Manopla',
          description: 'Golpe direto impulsionado por Força (+3).',
          diceCount: 1,
          diceSides: 6,
          attackMod: 6,
          damageMod: 3,
          statLabel: 'FOR +3',
          damageType: 'Contundente',
          icon: Icons.back_hand,
          isFinesse: false,
        ),
      ],
      spells: [
        SpellItem(
          id: 'alash_favor_divino',
          name: 'Favor Divino',
          circle: 1,
          pmCost: 2,
          costType: ActionCostType.bonusAction,
          targetType: TargetType.selfOnly,
          rangeMeters: 0.0,
          description: '1° Círculo (Ação Bônus): +1d4 radiante nos ataques.',
          diceCount: 0,
          diceSides: 0,
          flatBonus: 0,
          usesSpellAttack: false,
          isHealing: false,
          icon: Icons.wb_sunny,
        ),
        SpellItem(
          id: 'alash_escudo_fe',
          name: 'Escudo da Fé (+2 CA)',
          circle: 1,
          pmCost: 2,
          costType: ActionCostType.bonusAction,
          targetType: TargetType.allyOrSelf,
          rangeMeters: 18.0,
          description: '1° Círculo (Ação Bônus 18m): Concede +2 de CA.',
          diceCount: 0,
          diceSides: 0,
          flatBonus: 0,
          usesSpellAttack: false,
          isHealing: false,
          icon: Icons.shield,
        ),
        SpellItem(
          id: 'alash_curar_ferimentos',
          name: 'Curar Ferimentos',
          circle: 1,
          pmCost: 2,
          costType: ActionCostType.action,
          targetType: TargetType.allyOrSelf,
          rangeMeters: 1.5,
          description: '1° Círculo (Toque): Cura 1d8+3 PV (Carisma).',
          diceCount: 1,
          diceSides: 8,
          flatBonus: 3,
          usesSpellAttack: false,
          isHealing: true,
          icon: Icons.favorite,
        ),
        SpellItem(
          id: 'alash_comando_radiante',
          name: 'Chama Sagrada de Tyr',
          circle: 1,
          pmCost: 2,
          costType: ActionCostType.action,
          targetType: TargetType.enemySingle,
          rangeMeters: 18.0,
          description: '1° Círculo (18m): Resist. DES (CD 14) ou 2d8 radiante.',
          diceCount: 2,
          diceSides: 8,
          flatBonus: 0,
          usesSpellAttack: false,
          saveStat: 'DES',
          halfOnSave: false,
          isHealing: false,
          icon: Icons.whatshot,
        ),
        SpellItem(
          id: 'alash_golpe_marcador',
          name: 'Golpe Marcador',
          circle: 2,
          pmCost: 3,
          costType: ActionCostType.bonusAction,
          targetType: TargetType.selfOnly,
          rangeMeters: 0.0,
          description: '2° Círculo (Ação Bônus): Próximo acerto causa +2d6 radiante!',
          diceCount: 0,
          diceSides: 0,
          flatBonus: 0,
          usesSpellAttack: false,
          isHealing: false,
          icon: Icons.flare,
        ),
        SpellItem(
          id: 'alash_julgamento_divino',
          name: 'Julgamento de Tyr',
          circle: 2,
          pmCost: 3,
          costType: ActionCostType.action,
          targetType: TargetType.enemySingle,
          rangeMeters: 18.0,
          description: '2° Círculo (18m): Resist. SAB (CD 14), 3d8 radiante.',
          diceCount: 3,
          diceSides: 8,
          flatBonus: 0,
          usesSpellAttack: false,
          saveStat: 'SAB',
          halfOnSave: true,
          isHealing: false,
          icon: Icons.gavel,
        ),
        SpellItem(
          id: 'alash_auxilio_divino',
          name: 'Prece Restauradora',
          circle: 2,
          pmCost: 3,
          costType: ActionCostType.bonusAction,
          targetType: TargetType.allyOrSelf,
          rangeMeters: 9.0,
          description: '2° Círculo (Ação Bônus 9m): Cura 2d6+3 PV.',
          diceCount: 2,
          diceSides: 6,
          flatBonus: 3,
          usesSpellAttack: false,
          isHealing: true,
          icon: Icons.health_and_safety,
        ),
      ],
      abilities: [
        ClassAbilityItem(
          id: 'alash_imposicao_maos',
          name: 'Imposição das Mãos',
          costType: ActionCostType.action,
          maxUses: 35,
          description:
              'Reserva de 35 PV: gasta até 15 PV da reserva para curar a si ou aliado adjacente.',
          icon: Icons.volunteer_activism,
        ),
        ClassAbilityItem(
          id: 'alash_destruicao_divina',
          name: 'Destruição Divina (2 PM)',
          costType: ActionCostType.bonusAction,
          maxUses: 99,
          description:
              'Consome 2 PM para carregar o próximo golpe corpo a corpo com +2d8 de dano radiante!',
          icon: Icons.auto_awesome,
        ),
        ClassAbilityItem(
          id: 'alash_arma_sagrada',
          name: 'Arma Sagrada (Canalizar)',
          costType: ActionCostType.action,
          maxUses: 1,
          description:
              '1 uso: soma seu modificador de Carisma (+3) nas jogadas de ataque com arma!',
          icon: Icons.gavel,
        ),
        ClassAbilityItem(
          id: 'alash_aura_protecao',
          name: 'Aura de Proteção (+1 CA)',
          costType: ActionCostType.bonusAction,
          maxUses: 1,
          description:
              '1 uso: emana luz dourada, concedendo +1 CA permanente e +10 PV temporários.',
          icon: Icons.verified_user,
        ),
        ClassAbilityItem(
          id: 'alash_onda_justiceira',
          name: 'Onda Justiceira (6m)',
          costType: ActionCostType.action,
          maxUses: 2,
          description:
              'Canaliza luz sagrada a até 6m: inimigo faz Resist. CON (CD 14) ou sofre 2d10 radiante.',
          icon: Icons.brightness_high,
        ),
      ],
      themeGradient: const [Color(0xFFFFB3C6), Color(0xFFFB6F92)],
      themeColor: const Color(0xFFFF4D6D),
      imagePath: 'assets/Alash.jpg',
      bgIcon1: Icons.local_florist,
      bgIcon2: Icons.favorite,
      decoEmoji: '⚔️',
    ),

    // =====================================
    // ARES - LADINO NV.7 (6 Habilidades Táticas + 3 Ataques)
    // =====================================
    CharacterData(
      name: 'ARES',
      className: 'Ladino • Nv.7',
      subclass: 'Híbrido Simic • Furtivo 4d6',
      badgeText: '0 PM • FURTIVO +4d6',
      quote: '"Roubar não é errado quando quem é roubado não percebe."',
      speedMeters: 9.0,
      maxHp: 56,
      ac: 16,
      maxSpellPoints: 0,
      spellSaveDc: 14,
      spellAttackBonus: 7,
      strMod: 2,
      dexMod: 4,
      conMod: 1,
      intMod: 1,
      wisMod: 0,
      chaMod: 1,
      attacks: [
        MeleeAttack(
          name: 'Espada Curta (Acuidade)',
          description: 'DES (+4) + Prof (+3) = +7. Ativa Ataque Furtivo (+4d6)!',
          diceCount: 1,
          diceSides: 6,
          attackMod: 7,
          damageMod: 4,
          statLabel: 'DES +4',
          damageType: 'Cortante',
          icon: Icons.colorize,
          isFinesse: true,
        ),
        MeleeAttack(
          name: 'Adaga Furtiva (Acuidade)',
          description: 'DES (+4) + Prof (+3) = +7. Ativa Ataque Furtivo (+4d6)!',
          diceCount: 1,
          diceSides: 4,
          attackMod: 7,
          damageMod: 4,
          statLabel: 'DES +4',
          damageType: 'Perfurante',
          icon: Icons.gps_fixed,
          isFinesse: true,
        ),
        MeleeAttack(
          name: 'Soco Dracônico',
          description: 'Golpe físico usando sua Força (+2) + Prof (+3) = +5.',
          diceCount: 1,
          diceSides: 4,
          attackMod: 5,
          damageMod: 2,
          statLabel: 'FOR +2',
          damageType: 'Contundente',
          icon: Icons.back_hand,
          isFinesse: false,
        ),
      ],
      spells: [],
      abilities: [
        ClassAbilityItem(
          id: 'ares_spit',
          name: 'Spit (Jato Ácido 9m)',
          costType: ActionCostType.action,
          maxUses: 2,
          description:
              'Habilidade Racial (2 usos): alvo a 9m faz Resist. DES (CD 14) ou sofre 2d10 ácido.',
          icon: Icons.water_drop,
        ),
        ClassAbilityItem(
          id: 'ares_acao_ardilosa',
          name: 'Ação Ardilosa: Correr',
          costType: ActionCostType.bonusAction,
          maxUses: 99,
          description:
              'Ação Bônus: ganha +9m de deslocamento extra neste turno (total 18m)!',
          icon: Icons.directions_run,
        ),
        ClassAbilityItem(
          id: 'ares_ataque_furtivo',
          name: 'Ataque Furtivo (+4d6)',
          costType: ActionCostType.freePassive,
          maxUses: 99,
          description:
              'Passiva (1x por turno): soma +4d6 de dano ao acertar com arma de acuidade.',
          icon: Icons.visibility_off,
        ),
        ClassAbilityItem(
          id: 'ares_bomba_veneno',
          name: 'Frasco Tóxico (12m)',
          costType: ActionCostType.action,
          maxUses: 2,
          description:
              'Arremessa frasco a 12m: alvo faz Resist. CON (CD 14) ou sofre 3d6 veneno (metade se passar).',
          icon: Icons.science,
        ),
        ClassAbilityItem(
          id: 'ares_finta_mortal',
          name: 'Finta Sombria (+3 Acerto)',
          costType: ActionCostType.bonusAction,
          maxUses: 3,
          description:
              'Ação Bônus: finta o inimigo, ganhando +3 no próximo ataque e recarregando Furtivo.',
          icon: Icons.flash_on,
        ),
        ClassAbilityItem(
          id: 'ares_esquiva_sobrenatural',
          name: 'Postura Evasiva (+2 CA)',
          costType: ActionCostType.bonusAction,
          maxUses: 2,
          description:
              'Ação Bônus: assume postura ágil, ganhando +2 CA e +8 PV temporários.',
          icon: Icons.shield,
        ),
      ],
      themeGradient: const [Color(0xFF3E2723), Color(0xFF795548)],
      themeColor: const Color(0xFFFFD54F),
      imagePath: 'assets/Ares.jpg',
      bgIcon1: Icons.local_fire_department,
      bgIcon2: Icons.shield,
      decoEmoji: '🐉',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _runeRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }

  @override
  void dispose() {
    _runeRotationController.dispose();
    super.dispose();
  }

  void _onCharacterChosen(CharacterData chosen) {
    if (widget.mode == GameMode.singlePlayer) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BattleGridScreen(
            mode: GameMode.singlePlayer,
            player1: chosen,
            botDifficulty: widget.botDifficulty,
            botCount: widget.botCount,
          ),
        ),
      );
      return;
    }

    if (_player1Choice == null) {
      setState(() {
        _player1Choice = chosen;
      });
    } else {
      final p1 = _player1Choice!;
      final p2 = chosen;
      setState(() {
        _player1Choice = null;
      });

      if (widget.mode == GameMode.freeBattleRealtime) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FreeBattleRealtimeScreen(
              player1: p1,
              player2: p2,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BattleGridScreen(
              mode: widget.mode,
              player1: p1,
              player2: p2,
              botDifficulty: widget.botDifficulty,
              botCount: widget.botCount,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isTwoPlayers = widget.mode != GameMode.singlePlayer;
    final bool pickingP2 = isTwoPlayers && _player1Choice != null;

    String headerTitle = 'ESCOLHA SEU CAMPEÃO';
    if (isTwoPlayers) {
      headerTitle = pickingP2
          ? 'JOGADOR 2 ESCOLHA SEU CAMPEÃO'
          : 'JOGADOR 1 ESCOLHA SEU CAMPEÃO';
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              pickingP2 ? Icons.looks_two : Icons.looks_one,
              color: pickingP2
                  ? Colors.lightBlueAccent
                  : const Color(0xFFD4AF37),
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              headerTitle,
              style: TextStyle(
                color: pickingP2
                    ? Colors.lightBlueAccent
                    : const Color(0xFFD4AF37),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.8,
                fontSize: 20,
                fontFamily: 'Georgia',
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.black.withOpacity(0.55),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
        actions: [
          if (pickingP2)
            TextButton.icon(
              onPressed: () => setState(() => _player1Choice = null),
              icon: const Icon(Icons.undo, color: Colors.amberAccent, size: 18),
              label: Text(
                'Trocar P1 (${_player1Choice!.name})',
                style: const TextStyle(color: Colors.amberAccent),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.3,
                colors: [Color(0xFF2E1E19), Color(0xFF120B09)],
              ),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _runeRotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _runeRotationController.value * 2 * math.pi,
                  child: CustomPaint(
                    size: const Size(650, 650),
                    painter: ArcaneCirclePainter(),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  children: [
                    if (isTwoPlayers)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: pickingP2
                                ? Colors.lightBlueAccent
                                : const Color(0xFFD4AF37),
                          ),
                        ),
                        child: Text(
                          pickingP2
                              ? 'Jogador 1 escolheu ${_player1Choice!.name} ${_player1Choice!.decoEmoji} — Agora é a vez do Jogador 2!'
                              : (widget.mode == GameMode.freeBattleRealtime
                                  ? 'Batalha Livre Tempo Real: P1 (WASD) vs P2 (Setas)'
                                  : widget.mode == GameMode.twoPlayersPvp
                                      ? 'Modo Duelo PvP (Turnos): Jogador 1 vs Jogador 2'
                                      : 'Modo Cooperativo (${widget.botCount} Bots • ${widget.botDifficulty.name.toUpperCase()})'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontFamily: 'sans-serif',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      alignment: WrapAlignment.center,
                      children: _characters
                          .map(
                            (char) => InteractiveCharacterCard(
                              character: char,
                              isChosenByP1:
                                  _player1Choice?.name == char.name,
                              pickerLabel: isTwoPlayers
                                  ? (pickingP2
                                      ? 'ESCOLHER (P2)'
                                      : 'ESCOLHER (P1)')
                                  : 'SELECIONAR',
                              onConfirmed: () => _onCharacterChosen(char),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PARTE 2 — CARD DE PERSONAGEM COMO UMA CARTA DE VERDADE
//           (substitua a classe InteractiveCharacterCard inteira por esta)
//
//  O que ela faz:
//   • Entrada: a carta é "distribuída" (sobe, desinclina e aparece)
//   • Hover: a carta levanta e INCLINA EM 3D seguindo o mouse
//   • Brilho (glare) que acompanha o cursor, como carta holográfica
//   • Reflexo arco-íris sutil + faixa de brilho que atravessa a carta
//   • Parallax: a arte e os ícones de fundo se mexem em profundidade
//   • Sombra que acompanha a inclinação
//   • Partículas subindo dentro da carta
// ============================================================================

class InteractiveCharacterCard extends StatefulWidget {
  final CharacterData character;
  final bool isChosenByP1;
  final String pickerLabel;
  final VoidCallback onConfirmed;

  /// Atraso da animação de entrada (use índice * 90ms para escalonar).
  final Duration entranceDelay;

  const InteractiveCharacterCard({
    super.key,
    required this.character,
    required this.isChosenByP1,
    required this.pickerLabel,
    required this.onConfirmed,
    this.entranceDelay = Duration.zero,
  });

  @override
  State<InteractiveCharacterCard> createState() =>
      _InteractiveCharacterCardState();
}

class _InteractiveCharacterCardState extends State<InteractiveCharacterCard>
    with TickerProviderStateMixin {
  static const double _w = 320;
  static const double _h = 565;

  // ---- Ajustes rápidos (mexa aqui se quiser mais/menos efeito) ----
  static const double _maxTiltX = 0.20; // inclinação vertical (radianos)
  static const double _maxTiltY = 0.24; // inclinação horizontal (radianos)
  static const double _liftPx = 16; // quanto a carta sobe no hover
  static const double _hoverScale = 0.05; // +5% de tamanho no hover

  late final AnimationController _hover;
  late final AnimationController _shine;
  late final AnimationController _sparks;
  late final AnimationController _enter;
  Timer? _enterTimer;

  Offset _tilt = Offset.zero; // -1..1
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hover = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 260),
    );
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _sparks = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    if (widget.entranceDelay == Duration.zero) {
      _enter.forward();
    } else {
      _enterTimer = Timer(widget.entranceDelay, () {
        if (mounted) _enter.forward();
      });
    }
  }

  @override
  void dispose() {
    _enterTimer?.cancel();
    _hover.dispose();
    _shine.dispose();
    _sparks.dispose();
    _enter.dispose();
    super.dispose();
  }

  void _onEnter(PointerEnterEvent e) {
    _isHovered = true;
    _hover.forward();
    _shine.forward(from: 0);
    _sparks.repeat();
  }

  void _onExit(PointerExitEvent e) {
    _isHovered = false;
    _hover.reverse().whenComplete(() {
      if (!_isHovered) _sparks.stop();
    });
    setState(() => _tilt = Offset.zero);
  }

  void _onHover(PointerHoverEvent e) {
    final nx = (e.localPosition.dx / _w * 2 - 1).clamp(-1.0, 1.0).toDouble();
    final ny = (e.localPosition.dy / _h * 2 - 1).clamp(-1.0, 1.0).toDouble();
    setState(() => _tilt = Offset(nx, ny));
  }

  String _fmtMod(int m) => m >= 0 ? '+$m' : '$m';

  @override
  Widget build(BuildContext context) {
    final char = widget.character;
    return SizedBox(
      width: _w,
      height: _h,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: _onEnter,
        onExit: _onExit,
        onHover: _onHover,
        child: GestureDetector(
          onTap: widget.onConfirmed,
          child: AnimatedBuilder(
            animation: Listenable.merge([_hover, _shine, _sparks, _enter]),
            builder: (context, _) {
              // Suaviza a inclinação (segue o mouse sem tremer)
              return TweenAnimationBuilder<Offset>(
                tween: Tween<Offset>(begin: Offset.zero, end: _tilt),
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                builder: (context, tilt, _) => _buildCard(char, tilt),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCard(CharacterData char, Offset tilt) {
    final h = Curves.easeOutCubic.transform(_hover.value);

    // Entrada: a carta "chega" de baixo, desinclinando
    final en = _enter.value;
    final enOpacity =
        Curves.easeOut.transform((en * 1.4).clamp(0.0, 1.0).toDouble());
    final enT = Curves.easeOutBack.transform(en);
    final slide = (1 - enT) * 90;
    final enRot = (1 - enT) * 0.9;

    // Se quiser que a carta incline PARA LONGE do mouse (em vez de "afundar"
    // sob o cursor), troque o sinal das duas linhas rotateX / rotateY.
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0011) // perspectiva
      ..translate(0.0, slide - _liftPx * h)
      ..rotateX(enRot + tilt.dy * _maxTiltX * h)
      ..rotateY(-tilt.dx * _maxTiltY * h)
      ..scale(1.0 + _hoverScale * h);

    final shineRunning = _shine.value > 0 && _shine.value < 1;
    final shinePercent = -1.0 + 2.0 * Curves.easeInOut.transform(_shine.value);

    final card = Container(
      width: _w,
      height: _h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [...char.themeGradient, const Color(0xFF19100C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              Color.lerp(char.themeColor.withOpacity(0.75), Colors.white, h)!,
          width: 2.0 + h,
        ),
        boxShadow: [
          // brilho colorido
          BoxShadow(
            color: char.themeColor.withOpacity(0.2 + 0.5 * h),
            blurRadius: 14 + 22 * h,
            spreadRadius: 1 + 4 * h,
            offset: Offset(-tilt.dx * 16 * h, 8 + 6 * h - tilt.dy * 10 * h),
          ),
          // sombra no chão (afasta quando a carta levanta)
          BoxShadow(
            color: Colors.black87,
            blurRadius: 12 + 14 * h,
            offset: Offset(-tilt.dx * 10 * h, 8 + 12 * h - tilt.dy * 6 * h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // ---- ícones de fundo com parallax ----
            Positioned(
              right: -15,
              bottom: 65,
              child: Transform.translate(
                offset: Offset(-tilt.dx * 14 * h, -tilt.dy * 10 * h),
                child: Icon(
                  char.bgIcon1,
                  size: 130,
                  color: char.themeColor.withOpacity(0.12 + 0.06 * h),
                ),
              ),
            ),
            Positioned(
              left: -22,
              bottom: 150,
              child: Transform.translate(
                offset: Offset(tilt.dx * 10 * h, tilt.dy * 8 * h),
                child: Icon(
                  char.bgIcon2,
                  size: 90,
                  color: char.themeColor.withOpacity(0.05 + 0.05 * h),
                ),
              ),
            ),

            // ---- conteúdo ----
            _buildContent(char, tilt, h),

            // ---- reflexo holográfico (arco-íris sutil) ----
            if (h > 0.001)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-1.0 + tilt.dx, -1.0 + tilt.dy),
                        end: Alignment(1.0 + tilt.dx, 1.0 + tilt.dy),
                        colors: [
                          const Color(0xFFFF0080).withOpacity(0.10 * h),
                          const Color(0xFF00E5FF).withOpacity(0.10 * h),
                          const Color(0xFFFFEA00).withOpacity(0.10 * h),
                          const Color(0xFF7C4DFF).withOpacity(0.10 * h),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ---- brilho que segue o cursor ----
            if (h > 0.001)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(tilt.dx, tilt.dy),
                        radius: 0.85,
                        colors: [
                          Colors.white.withOpacity(0.26 * h),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ---- faixa de luz atravessando a carta (1x ao entrar o mouse) ----
            if (shineRunning)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.28),
                          Colors.white.withOpacity(0.0),
                        ],
                        stops: const [0.35, 0.5, 0.65],
                        transform: _SlideGradientTransform(shinePercent),
                      ),
                    ),
                  ),
                ),
              ),

            // ---- partículas ----
            if (h > 0.001)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _SparklePainter(
                      t: _sparks.value,
                      color: char.themeColor,
                      intensity: h,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return Transform(
      alignment: Alignment.center,
      transform: matrix,
      child: enOpacity >= 1.0 ? card : Opacity(opacity: enOpacity, child: card),
    );
  }

  Widget _buildContent(CharacterData char, Offset tilt, double h) {
    return Column(
      children: [
        // ---------- ARTE DO PERSONAGEM ----------
        Container(
          height: 205,
          width: double.infinity,
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Color.lerp(
                  char.themeColor.withOpacity(0.45), char.themeColor, h)!,
              width: 2,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                // Parallax: a imagem se desloca no sentido oposto ao da carta
                child: Transform.translate(
                  offset: Offset(-tilt.dx * 8 * h, -tilt.dy * 6 * h),
                  child: Transform.scale(
                    scale: 1.10 + 0.04 * h,
                    child: Image.asset(
                      char.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: char.themeColor,
                            size: 42,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A110E).withOpacity(0.92),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: char.themeColor, width: 1.5),
                  ),
                  child: Text(
                    char.badgeText,
                    style: TextStyle(
                      color: char.themeColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 10.5,
                      fontFamily: 'sans-serif',
                    ),
                  ),
                ),
              ),
              if (widget.isChosenByP1)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'P1 ESCOLHEU',
                      style: TextStyle(
                        color: Color(0xFF1A110E),
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        fontFamily: 'sans-serif',
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 8,
                left: 10,
                child: Text(
                  char.decoEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ],
          ),
        ),

        // ---------- TEXTOS / STATS / BOTÃO ----------
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text(
                      char.name,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: char.themeColor.withOpacity(0.8),
                            blurRadius: 6 + 10 * h,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${char.className} • ${char.subclass}',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: char.themeColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      char.quote,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: char.themeColor.withOpacity(0.45),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _modChip('FOR', _fmtMod(char.strMod), char.strMod),
                      _modChip('DES', _fmtMod(char.dexMod), char.dexMod),
                      _modChip('CON', _fmtMod(char.conMod), char.conMod),
                      _modChip('INT', _fmtMod(char.intMod), char.intMod),
                      _modChip('SAB', _fmtMod(char.wisMod), char.wisMod),
                      _modChip('CAR', _fmtMod(char.chaMod), char.chaMod),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: char.themeColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statColumn(Icons.favorite, 'Vida', '${char.maxHp} PV',
                          Colors.redAccent),
                      _divider(),
                      _statColumn(
                          Icons.shield, 'Defesa', '${char.ac} CA', Colors.amber),
                      _divider(),
                      _statColumn(
                        Icons.auto_fix_high,
                        'Habilidades',
                        '${char.abilities.length} Hab.',
                        Colors.cyanAccent,
                      ),
                    ],
                  ),
                ),
                // Botão: gradiente "acende" no hover
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.lerp(char.themeGradient.last, char.themeColor, h)!,
                        Color.lerp(
                            char.themeGradient.first, char.themeGradient.last, h)!,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Color.lerp(
                          char.themeColor.withOpacity(0.8), Colors.white, h)!,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sports_martial_arts,
                        size: 18,
                        color: Color.lerp(
                            Colors.white, const Color(0xFF1A110E), h),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.pickerLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5 + 0.8 * h,
                          color: Color.lerp(
                              Colors.white, const Color(0xFF1A110E), h),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _modChip(String label, String value, int raw) {
    Color valColor = Colors.white;
    if (raw >= 3) {
      valColor = Colors.lightGreenAccent;
    } else if (raw < 0) {
      valColor = Colors.redAccent;
    }
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            fontFamily: 'sans-serif',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valColor,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            fontFamily: 'sans-serif',
          ),
        ),
      ],
    );
  }

  Widget _divider() =>
      Container(height: 24, width: 1, color: Colors.white.withOpacity(0.15));

  Widget _statColumn(
      IconData icon, String label, String value, Color accentColor) {
    return Column(
      children: [
        Icon(icon, color: accentColor, size: 15),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 9.5)),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            fontFamily: 'sans-serif',
          ),
        ),
      ],
    );
  }
}

  Widget _modChip(String label, String value, int raw) {
    Color valColor = Colors.white;
    if (raw >= 3) {
      valColor = Colors.lightGreenAccent;
    } else if (raw < 0) {
      valColor = Colors.redAccent;
    }
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            fontFamily: 'sans-serif',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valColor,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            fontFamily: 'sans-serif',
          ),
        ),
      ],
    );
  }

  Widget _divider() =>
      Container(height: 24, width: 1, color: Colors.white.withOpacity(0.15));

  Widget _statColumn(
      IconData icon, String label, String value, Color accentColor) {
    return Column(
      children: [
        Icon(icon, color: accentColor, size: 15),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 9.5)),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            fontFamily: 'sans-serif',
          ),
        ),
      ],
    );
  }


// ==========================================
// 3. MODO: BATALHA LIVRE EM TEMPO REAL (WASD vs SETAS + 3 PODERES)
// ==========================================
class FreeAbilitySpec {
  final String name;
  final String subtitle;
  final double baseCooldownSec;
  final IconData icon;

  const FreeAbilitySpec({
    required this.name,
    required this.subtitle,
    required this.baseCooldownSec,
    required this.icon,
  });
}

class RealtimePlayerState {
  final CharacterData hero;
  final int playerIndex;
  double x;
  double y;
  double facingX;
  double facingY;
  int hp;
  int maxHp;
  double moveSpeedTilesPerSec;
  List<double> cooldowns = [0.0, 0.0, 0.0];
  double hurtFlashTimer = 0.0;
  double auraRemainingSec = 0.0;
  bool awaitingTargetClick = false;

  RealtimePlayerState({
    required this.hero,
    required this.playerIndex,
    required this.x,
    required this.y,
    required this.facingX,
    required this.facingY,
    required this.hp,
    required this.maxHp,
    required this.moveSpeedTilesPerSec,
  });

  List<FreeAbilitySpec> get abilities {
    if (hero.name == 'AFRODITE') {
      return const [
        FreeAbilitySpec(
          name: 'Lançar Chama',
          subtitle: 'Projétil rápido (14 dano)',
          baseCooldownSec: 0.80,
          icon: Icons.local_fire_department,
        ),
        FreeAbilitySpec(
          name: 'Criar Obstáculo',
          subtitle: 'Ergue bloco barreira',
          baseCooldownSec: 7.0,
          icon: Icons.account_balance,
        ),
        FreeAbilitySpec(
          name: 'Curar Ferimentos',
          subtitle: 'Cura 14 a 26 PV (sorte)',
          baseCooldownSec: 9.5,
          icon: Icons.favorite,
        ),
      ];
    } else if (hero.name == 'ARES') {
      return const [
        FreeAbilitySpec(
          name: 'Adaga Ágil',
          subtitle: 'Corte rápido (13 dano)',
          baseCooldownSec: 0.65,
          icon: Icons.colorize,
        ),
        FreeAbilitySpec(
          name: 'Quebrar Bloco',
          subtitle: 'Destrói obstáculo',
          baseCooldownSec: 4.5,
          icon: Icons.hardware,
        ),
        FreeAbilitySpec(
          name: 'Cuspida Ácida',
          subtitle: 'Armadilha ácida (24 dano)',
          baseCooldownSec: 7.5,
          icon: Icons.water_drop,
        ),
      ];
    } else {
      return const [
        FreeAbilitySpec(
          name: 'Espada Motosserra',
          subtitle: 'Golpe pesado (25 dano)',
          baseCooldownSec: 1.35,
          icon: Icons.carpenter,
        ),
        FreeAbilitySpec(
          name: 'Aura Divina',
          subtitle: 'Retarda recarga inimiga',
          baseCooldownSec: 11.0,
          icon: Icons.wb_sunny,
        ),
        FreeAbilitySpec(
          name: 'Destruição Divina',
          subtitle: 'Clique no mapa (28 dano)',
          baseCooldownSec: 8.5,
          icon: Icons.flare,
        ),
      ];
    }
  }
}

class FireballProjectile {
  final int ownerIndex;
  double x;
  double y;
  final double vx;
  final double vy;
  final int damage;

  FireballProjectile({
    required this.ownerIndex,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.damage,
  });
}

class AcidPuddleHazard {
  final int ownerIndex;
  final double x;
  final double y;
  final int damage;

  AcidPuddleHazard({
    required this.ownerIndex,
    required this.x,
    required this.y,
    required this.damage,
  });
}

class DivineStrikeTelegraph {
  final int ownerIndex;
  final double x;
  final double y;
  double timerSec;
  final double radiusTiles;
  final int damage;

  DivineStrikeTelegraph({
    required this.ownerIndex,
    required this.x,
    required this.y,
    required this.timerSec,
    required this.radiusTiles,
    required this.damage,
  });
}

class VisualSlashEffect {
  final double x;
  final double y;
  final Color color;
  double timerSec;

  VisualSlashEffect({
    required this.x,
    required this.y,
    required this.color,
    required this.timerSec,
  });
}

class FreeBattleRealtimeScreen extends StatefulWidget {
  final CharacterData player1;
  final CharacterData player2;

  const FreeBattleRealtimeScreen({
    super.key,
    required this.player1,
    required this.player2,
  });

  @override
  State<FreeBattleRealtimeScreen> createState() =>
      _FreeBattleRealtimeScreenState();
}

class _FreeBattleRealtimeScreenState extends State<FreeBattleRealtimeScreen> {
  static const int cols = 16;
  static const int rows = 10;
  static const double playerRadius = 0.34;
  final math.Random _rng = math.Random();
  double _hypot(double dx, double dy) => math.sqrt(dx * dx + dy * dy);

  final FocusNode _focusNode = FocusNode();
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  late RealtimePlayerState p1;
  late RealtimePlayerState p2;
  final Map<String, bool> obstacles = {};
  final List<FireballProjectile> projectiles = [];
  final List<AcidPuddleHazard> acidPuddles = [];
  final List<DivineStrikeTelegraph> divineStrikes = [];
  final List<VisualSlashEffect> slashEffects = [];
  Timer? _gameLoopTimer;
  String? winnerBanner;
  String statusBanner =
      'P1: WASD (Mover) + Q/E/R | P2: Setas (Mover) + Enter / Shift / Ctrl';

  @override
  void initState() {
    super.initState();
    _initRealtimeMatch();
    _gameLoopTimer = Timer.periodic(
      const Duration(milliseconds: 25),
      (_) => _updateSimulation(0.025),
    );
  }

  @override
  void dispose() {
    _gameLoopTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  int _balancedFreeHp(CharacterData c) {
    if (c.name == 'ALASH') return 135;
    if (c.name == 'ARES') return 115;
    return 110;
  }

  double _balancedFreeSpeed(CharacterData c) {
    if (c.name == 'ALASH') return 4.3;
    if (c.name == 'ARES') return 5.4;
    return 4.9;
  }

  void _initRealtimeMatch() {
    obstacles.clear();
    projectiles.clear();
    acidPuddles.clear();
    divineStrikes.clear();
    slashEffects.clear();
    winnerBanner = null;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if ((c <= 2 && r >= 3 && r <= 6) ||
            (c >= cols - 3 && r >= 3 && r <= 6)) {
          continue;
        }
        if (_rng.nextDouble() < 0.22) {
          obstacles['$r,$c'] = true;
        }
      }
    }

    p1 = RealtimePlayerState(
      hero: widget.player1,
      playerIndex: 1,
      x: 1.5,
      y: 5.0,
      facingX: 1.0,
      facingY: 0.0,
      hp: _balancedFreeHp(widget.player1),
      maxHp: _balancedFreeHp(widget.player1),
      moveSpeedTilesPerSec: _balancedFreeSpeed(widget.player1),
    );

    p2 = RealtimePlayerState(
      hero: widget.player2,
      playerIndex: 2,
      x: cols - 1.5,
      y: 5.0,
      facingX: -1.0,
      facingY: 0.0,
      hp: _balancedFreeHp(widget.player2),
      maxHp: _balancedFreeHp(widget.player2),
      moveSpeedTilesPerSec: _balancedFreeSpeed(widget.player2),
    );
  }

  void _updateSimulation(double dt) {
    if (!mounted) return;
    if (winnerBanner != null) return;

    setState(() {
      _tickPlayerTimers(p1, p2, dt);
      _tickPlayerTimers(p2, p1, dt);

      _handlePlayerMovement(
        player: p1,
        up: _pressedKeys.contains(LogicalKeyboardKey.keyW),
        down: _pressedKeys.contains(LogicalKeyboardKey.keyS),
        left: _pressedKeys.contains(LogicalKeyboardKey.keyA),
        right: _pressedKeys.contains(LogicalKeyboardKey.keyD),
        dt: dt,
      );

      _handlePlayerMovement(
        player: p2,
        up: _pressedKeys.contains(LogicalKeyboardKey.arrowUp),
        down: _pressedKeys.contains(LogicalKeyboardKey.arrowDown),
        left: _pressedKeys.contains(LogicalKeyboardKey.arrowLeft),
        right: _pressedKeys.contains(LogicalKeyboardKey.arrowRight),
        dt: dt,
      );

      for (int i = projectiles.length - 1; i >= 0; i--) {
        final proj = projectiles[i];
        proj.x += proj.vx * dt;
        proj.y += proj.vy * dt;

        if (proj.x < 0 || proj.x >= cols || proj.y < 0 || proj.y >= rows) {
          projectiles.removeAt(i);
          continue;
        }

        final int cellR = proj.y.floor();
        final int cellC = proj.x.floor();
        if (obstacles.containsKey('$cellR,$cellC')) {
          slashEffects.add(VisualSlashEffect(
            x: proj.x,
            y: proj.y,
            color: Colors.orangeAccent,
            timerSec: 0.25,
          ));
          projectiles.removeAt(i);
          continue;
        }

        final RealtimePlayerState target = proj.ownerIndex == 1 ? p2 : p1;
        final double dist = _hypot(proj.x - target.x, proj.y - target.y);
        if (dist <= playerRadius + 0.22) {
          _damagePlayer(target, proj.damage,
              'Chama atingiu ${target.hero.name} (-${proj.damage} PV)!');
          slashEffects.add(VisualSlashEffect(
            x: target.x,
            y: target.y,
            color: Colors.deepOrangeAccent,
            timerSec: 0.3,
          ));
          projectiles.removeAt(i);
        }
      }

      for (int i = acidPuddles.length - 1; i >= 0; i--) {
        final puddle = acidPuddles[i];
        final RealtimePlayerState victim = puddle.ownerIndex == 1 ? p2 : p1;
        final double dist = _hypot(puddle.x - victim.x, puddle.y - victim.y);
        if (dist <= playerRadius + 0.32) {
          _damagePlayer(victim, puddle.damage,
              '${victim.hero.name} pisou na Cuspida Ácida (-${puddle.damage} PV)!');
          slashEffects.add(VisualSlashEffect(
            x: puddle.x,
            y: puddle.y,
            color: Colors.lightGreenAccent,
            timerSec: 0.35,
          ));
          acidPuddles.removeAt(i);
        }
      }

      for (int i = divineStrikes.length - 1; i >= 0; i--) {
        final strike = divineStrikes[i];
        strike.timerSec -= dt;
        if (strike.timerSec <= 0) {
          final int minR = math.max(0, (strike.y - strike.radiusTiles).floor());
          final int maxR =
              math.min(rows - 1, (strike.y + strike.radiusTiles).ceil());
          final int minC = math.max(0, (strike.x - strike.radiusTiles).floor());
          final int maxC =
              math.min(cols - 1, (strike.x + strike.radiusTiles).ceil());

          for (int r = minR; r <= maxR; r++) {
            for (int c = minC; c <= maxC; c++) {
              final double cellCenterX = c + 0.5;
              final double cellCenterY = r + 0.5;
              if (_hypot(cellCenterX - strike.x, cellCenterY - strike.y) <=
                  strike.radiusTiles) {
                obstacles.remove('$r,$c');
              }
            }
          }

          final RealtimePlayerState target = strike.ownerIndex == 1 ? p2 : p1;
          if (_hypot(target.x - strike.x, target.y - strike.y) <=
              strike.radiusTiles + playerRadius) {
            _damagePlayer(
              target,
              strike.damage,
              'Destruição Divina explodiu em ${target.hero.name} (-${strike.damage} PV)!',
            );
          }

          slashEffects.add(VisualSlashEffect(
            x: strike.x,
            y: strike.y,
            color: Colors.amberAccent,
            timerSec: 0.45,
          ));
          divineStrikes.removeAt(i);
        }
      }

      for (int i = slashEffects.length - 1; i >= 0; i--) {
        slashEffects[i].timerSec -= dt;
        if (slashEffects[i].timerSec <= 0) {
          slashEffects.removeAt(i);
        }
      }
    });
  }

  void _tickPlayerTimers(
      RealtimePlayerState self, RealtimePlayerState other, double dt) {
    if (self.hurtFlashTimer > 0) {
      self.hurtFlashTimer = math.max(0, self.hurtFlashTimer - dt);
    }
    if (self.auraRemainingSec > 0) {
      self.auraRemainingSec = math.max(0, self.auraRemainingSec - dt);
    }
    double cooldownSpeedMultiplier = 1.0;
    if (other.auraRemainingSec > 0) {
      final double dist = _hypot(self.x - other.x, self.y - other.y);
      if (dist <= 2.7) {
        cooldownSpeedMultiplier = 0.60;
      }
    }
    for (int i = 0; i < 3; i++) {
      if (self.cooldowns[i] > 0) {
        self.cooldowns[i] =
            math.max(0.0, self.cooldowns[i] - (dt * cooldownSpeedMultiplier));
      }
    }
  }

  void _handlePlayerMovement({
    required RealtimePlayerState player,
    required bool up,
    required bool down,
    required bool left,
    required bool right,
    required double dt,
  }) {
    double dx = 0;
    double dy = 0;
    if (up) dy -= 1;
    if (down) dy += 1;
    if (left) dx -= 1;
    if (right) dx += 1;
    if (dx == 0 && dy == 0) return;

    final double len = _hypot(dx, dy);
    dx /= len;
    dy /= len;
    player.facingX = dx;
    player.facingY = dy;

    final double step = player.moveSpeedTilesPerSec * dt;
    final double nextX =
        (player.x + dx * step).clamp(playerRadius, cols - playerRadius);
    final double nextY =
        (player.y + dy * step).clamp(playerRadius, rows - playerRadius);

    if (!_collidesWithObstacle(nextX, player.y)) {
      player.x = nextX;
    }
    if (!_collidesWithObstacle(player.x, nextY)) {
      player.y = nextY;
    }
  }

  bool _collidesWithObstacle(double cx, double cy) {
    final int minR = math.max(0, (cy - playerRadius).floor());
    final int maxR = math.min(rows - 1, (cy + playerRadius).floor());
    final int minC = math.max(0, (cx - playerRadius).floor());
    final int maxC = math.min(cols - 1, (cx + playerRadius).floor());

    for (int r = minR; r <= maxR; r++) {
      for (int c = minC; c <= maxC; c++) {
        if (obstacles.containsKey('$r,$c')) {
          final double closestX = cx.clamp(c.toDouble(), (c + 1).toDouble());
          final double closestY = cy.clamp(r.toDouble(), (r + 1).toDouble());
          final double dist = _hypot(cx - closestX, cy - closestY);
          if (dist < playerRadius - 0.03) {
            return true;
          }
        }
      }
    }
    return false;
  }

  void _damagePlayer(
      RealtimePlayerState target, int amount, String logMessage) {
    target.hp = math.max(0, target.hp - amount);
    target.hurtFlashTimer = 0.25;
    statusBanner = logMessage;
    if (target.hp == 0) {
      final RealtimePlayerState winner = target.playerIndex == 1 ? p2 : p1;
      winnerBanner =
          'VITÓRIA DO JOGADOR ${winner.playerIndex} (${winner.hero.name})!';
    }
  }

  void _triggerAbility(RealtimePlayerState actor, int slotIndex) {
    if (winnerBanner != null) return;
    if (actor.cooldowns[slotIndex] > 0) return;

    final RealtimePlayerState opponent = actor.playerIndex == 1 ? p2 : p1;
    final spec = actor.abilities[slotIndex];

    setState(() {
      if (actor.hero.name == 'AFRODITE') {
        if (slotIndex == 0) {
          projectiles.add(FireballProjectile(
            ownerIndex: actor.playerIndex,
            x: actor.x + actor.facingX * 0.45,
            y: actor.y + actor.facingY * 0.45,
            vx: actor.facingX * 10.5,
            vy: actor.facingY * 10.5,
            damage: 14,
          ));
          actor.cooldowns[0] = spec.baseCooldownSec;
        } else if (slotIndex == 1) {
          final int targetC =
              (actor.x + actor.facingX * 1.15).floor().clamp(0, cols - 1);
          final int targetR =
              (actor.y + actor.facingY * 1.15).floor().clamp(0, rows - 1);
          final bool hitsP1 = targetC == p1.x.floor() && targetR == p1.y.floor();
          final bool hitsP2 = targetC == p2.x.floor() && targetR == p2.y.floor();
          if (!hitsP1 &&
              !hitsP2 &&
              !obstacles.containsKey('$targetR,$targetC')) {
            obstacles['$targetR,$targetC'] = true;
            actor.cooldowns[1] = spec.baseCooldownSec;
            statusBanner = 'Afrodite ergueu um obstáculo natural!';
          } else {
            statusBanner = 'Espaço bloqueado para criar obstáculo!';
          }
        } else if (slotIndex == 2) {
          final int healAmount = 14 + _rng.nextInt(13);
          actor.hp = math.min(actor.maxHp, actor.hp + healAmount);
          actor.cooldowns[2] = spec.baseCooldownSec;
          slashEffects.add(VisualSlashEffect(
            x: actor.x,
            y: actor.y,
            color: Colors.greenAccent,
            timerSec: 0.4,
          ));
          statusBanner =
              'Afrodite curou +$healAmount PV com Curar Ferimentos!';
        }
      } else if (actor.hero.name == 'ARES') {
        if (slotIndex == 0) {
          actor.cooldowns[0] = spec.baseCooldownSec;
          final double hitX = actor.x + actor.facingX * 0.75;
          final double hitY = actor.y + actor.facingY * 0.75;
          slashEffects.add(VisualSlashEffect(
            x: hitX,
            y: hitY,
            color: Colors.amberAccent,
            timerSec: 0.22,
          ));
          if (_hypot(opponent.x - hitX, opponent.y - hitY) <= 0.95) {
            _damagePlayer(opponent, 13,
                'Adaga de Ares acertou ${opponent.hero.name} (-13 PV)!');
          }
        } else if (slotIndex == 1) {
          bool brokeAny = false;
          for (double step = 0.7; step <= 1.4; step += 0.35) {
            final int checkC =
                (actor.x + actor.facingX * step).floor().clamp(0, cols - 1);
            final int checkR =
                (actor.y + actor.facingY * step).floor().clamp(0, rows - 1);
            if (obstacles.remove('$checkR,$checkC') != null) {
              brokeAny = true;
              slashEffects.add(VisualSlashEffect(
                x: checkC + 0.5,
                y: checkR + 0.5,
                color: Colors.brown.shade200,
                timerSec: 0.3,
              ));
              break;
            }
          }
          if (brokeAny) {
            actor.cooldowns[1] = spec.baseCooldownSec;
            statusBanner = 'Ares quebrou um obstáculo do caminho!';
          } else {
            statusBanner =
                'Vire-se de frente para um obstáculo para quebrá-lo!';
          }
        } else if (slotIndex == 2) {
          acidPuddles.add(AcidPuddleHazard(
            ownerIndex: actor.playerIndex,
            x: actor.x,
            y: actor.y,
            damage: 24,
          ));
          actor.cooldowns[2] = spec.baseCooldownSec;
          statusBanner = 'Ares deixou uma armadilha de Cuspida Ácida!';
        }
      } else {
        if (slotIndex == 0) {
          actor.cooldowns[0] = spec.baseCooldownSec;
          final double hitX = actor.x + actor.facingX * 0.85;
          final double hitY = actor.y + actor.facingY * 0.85;
          slashEffects.add(VisualSlashEffect(
            x: hitX,
            y: hitY,
            color: Colors.pinkAccent,
            timerSec: 0.32,
          ));
          if (_hypot(opponent.x - hitX, opponent.y - hitY) <= 1.05) {
            _damagePlayer(opponent, 25,
                'Espada Motosserra de Alash dilacerou ${opponent.hero.name} (-25 PV)!');
          }
        } else if (slotIndex == 1) {
          actor.auraRemainingSec = 5.0;
          actor.cooldowns[1] = spec.baseCooldownSec;
          statusBanner =
              'Aura Divina ativa! Inimigos dentro da aura recarregam mais devagar!';
        } else if (slotIndex == 2) {
          actor.awaitingTargetClick = !actor.awaitingTargetClick;
          statusBanner = actor.awaitingTargetClick
              ? 'Alash: CLIQUE EM QUALQUER PONTO DO MAPA para invocar Destruição Divina!'
              : 'Mira da Destruição Divina cancelada.';
        }
      }
    });
  }

  void _handleMapTapDown(TapDownDetails details, BoxConstraints constraints) {
    if (winnerBanner != null) return;
    final double gridX =
        (details.localPosition.dx / constraints.maxWidth) * cols;
    final double gridY =
        (details.localPosition.dy / constraints.maxHeight) * rows;

    for (final player in [p1, p2]) {
      if (player.awaitingTargetClick && player.cooldowns[2] <= 0) {
        setState(() {
          player.awaitingTargetClick = false;
          player.cooldowns[2] = player.abilities[2].baseCooldownSec;
          divineStrikes.add(DivineStrikeTelegraph(
            ownerIndex: player.playerIndex,
            x: gridX,
            y: gridY,
            timerSec: 1.1,
            radiusTiles: 1.45,
            damage: 28,
          ));
          statusBanner =
              'Destruição Divina marcada! Vai explodir em 1,1 segundo!';
        });
        return;
      }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      _pressedKeys.add(event.logicalKey);
      if (event.logicalKey == LogicalKeyboardKey.keyQ) {
        _triggerAbility(p1, 0);
      } else if (event.logicalKey == LogicalKeyboardKey.keyE) {
        _triggerAbility(p1, 1);
      } else if (event.logicalKey == LogicalKeyboardKey.keyR) {
        _triggerAbility(p1, 2);
      }

      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpad1 ||
          event.logicalKey == LogicalKeyboardKey.digit1) {
        _triggerAbility(p2, 0);
      } else if (event.logicalKey == LogicalKeyboardKey.shiftRight ||
          event.logicalKey == LogicalKeyboardKey.numpad2 ||
          event.logicalKey == LogicalKeyboardKey.digit2) {
        _triggerAbility(p2, 1);
      } else if (event.logicalKey == LogicalKeyboardKey.controlRight ||
          event.logicalKey == LogicalKeyboardKey.numpad3 ||
          event.logicalKey == LogicalKeyboardKey.digit3) {
        _triggerAbility(p2, 2);
      }
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF140D0B),
          iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
          title: Row(
            children: [
              const Icon(Icons.bolt, color: Colors.cyanAccent, size: 22),
              const SizedBox(width: 8),
              const Text(
                'BATALHA LIVRE TEMPO REAL (P1: WASD vs P2: SETAS)',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _initRealtimeMatch();
                    _focusNode.requestFocus();
                  });
                },
                icon: const Icon(Icons.refresh, color: Color(0xFFD4AF37)),
                label: const Text(
                  'Reiniciar Arena Livre',
                  style: TextStyle(color: Color(0xFFD4AF37)),
                ),
              ),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.3,
              colors: [Color(0xFF261A16), Color(0xFF0F0908)],
            ),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                color: Colors.black54,
                child: Text(
                  statusBanner,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'sans-serif',
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: AspectRatio(
                      aspectRatio: cols / rows,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final double tileW = constraints.maxWidth / cols;
                          final double tileH = constraints.maxHeight / rows;
                          return GestureDetector(
                            onTapDown: (details) =>
                                _handleMapTapDown(details, constraints),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F1916),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: (p1.awaitingTargetClick ||
                                          p2.awaitingTargetClick)
                                      ? Colors.redAccent
                                      : const Color(0xFFD4AF37),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.85),
                                    blurRadius: 24,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Stack(
                                  children: [
                                    Column(
                                      children: List.generate(rows, (r) {
                                        return Expanded(
                                          child: Row(
                                            children: List.generate(cols, (c) {
                                              final bool isEven =
                                                  (r + c) % 2 == 0;
                                              return Expanded(
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: isEven
                                                        ? const Color(
                                                            0xFF2B231E)
                                                        : const Color(
                                                            0xFF241D19),
                                                    border: Border.all(
                                                      color: Colors.white
                                                          .withOpacity(0.06),
                                                      width: 0.5,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                          ),
                                        );
                                      }),
                                    ),
                                    ...obstacles.keys.map((key) {
                                      final parts = key.split(',');
                                      final int r = int.parse(parts[0]);
                                      final int c = int.parse(parts[1]);
                                      return Positioned(
                                        left: c * tileW + 2,
                                        top: r * tileH + 2,
                                        width: tileW - 4,
                                        height: tileH - 4,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF5D4037),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: const Color(0xFF8D6E63),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.account_balance,
                                            color: Colors.brown.shade100
                                                .withOpacity(0.65),
                                            size: tileW * 0.55,
                                          ),
                                        ),
                                      );
                                    }),
                                    ...acidPuddles.map((puddle) {
                                      return Positioned(
                                        left: (puddle.x - 0.38) * tileW,
                                        top: (puddle.y - 0.38) * tileH,
                                        width: tileW * 0.76,
                                        height: tileH * 0.76,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.lightGreenAccent
                                                .withOpacity(0.45),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.greenAccent,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Text('🧪',
                                                style: TextStyle(fontSize: 16)),
                                          ),
                                        ),
                                      );
                                    }),
                                    ...divineStrikes.map((strike) {
                                      final double size =
                                          strike.radiusTiles * 2 * tileW;
                                      return Positioned(
                                        left: strike.x * tileW - size / 2,
                                        top: strike.y * tileH - size / 2,
                                        width: size,
                                        height: size,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent
                                                .withOpacity(0.45),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.red,
                                              width: 3,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Icon(Icons.warning_amber,
                                                color: Colors.white, size: 28),
                                          ),
                                        ),
                                      );
                                    }),
                                    for (final pl in [p1, p2])
                                      if (pl.auraRemainingSec > 0)
                                        Positioned(
                                          left: (pl.x - 2.7) * tileW,
                                          top: (pl.y - 2.7) * tileH,
                                          width: 5.4 * tileW,
                                          height: 5.4 * tileH,
                                          child: IgnorePointer(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.amberAccent
                                                    .withOpacity(0.14),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.amberAccent
                                                      .withOpacity(0.75),
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    _buildRealtimeHeroWidget(p1, tileW, tileH),
                                    _buildRealtimeHeroWidget(p2, tileW, tileH),
                                    ...projectiles.map((proj) {
                                      return Positioned(
                                        left: (proj.x - 0.24) * tileW,
                                        top: (proj.y - 0.24) * tileH,
                                        width: tileW * 0.48,
                                        height: tileH * 0.48,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.deepOrange,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.orangeAccent
                                                    .withOpacity(0.9),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: const Center(
                                            child: Text('🔥',
                                                style: TextStyle(fontSize: 14)),
                                          ),
                                        ),
                                      );
                                    }),
                                    ...slashEffects.map((fx) {
                                      return Positioned(
                                        left: (fx.x - 0.4) * tileW,
                                        top: (fx.y - 0.4) * tileH,
                                        width: tileW * 0.8,
                                        height: tileH * 0.8,
                                        child: IgnorePointer(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: fx.color.withOpacity(0.45),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                    if (winnerBanner != null)
                                      Container(
                                        color: Colors.black.withOpacity(0.75),
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                winnerBanner!,
                                                style: const TextStyle(
                                                  color: Colors.amberAccent,
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              ElevatedButton.icon(
                                                onPressed: () {
                                                  setState(() {
                                                    _initRealtimeMatch();
                                                    _focusNode.requestFocus();
                                                  });
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      const Color(0xFFD4AF37),
                                                  foregroundColor:
                                                      const Color(0xFF1A110E),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 28,
                                                      vertical: 14),
                                                ),
                                                icon: const Icon(Icons.replay),
                                                label: const Text(
                                                  'JOGAR NOVAMENTE',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                height: 168,
                decoration: BoxDecoration(
                  color: const Color(0xFF140D0B),
                  border: Border(
                    top: BorderSide(
                      color: const Color(0xFFD4AF37).withOpacity(0.65),
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSplitPlayerPanel(
                        player: p1,
                        keyHints: const ['Q', 'E', 'R'],
                        moveHint: 'Mover: WASD',
                      ),
                    ),
                    Container(
                      width: 3,
                      color: const Color(0xFFD4AF37),
                    ),
                    Expanded(
                      child: _buildSplitPlayerPanel(
                        player: p2,
                        keyHints: const ['1 / Enter', '2 / Shift', '3 / Ctrl'],
                        moveHint: 'Mover: Setas',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRealtimeHeroWidget(
      RealtimePlayerState pl, double tileW, double tileH) {
    final double diameter = playerRadius * 2 * tileW;
    final bool isHurt = pl.hurtFlashTimer > 0;
    return Positioned(
      left: pl.x * tileW - diameter / 2,
      top: pl.y * tileH - diameter / 2,
      width: diameter,
      height: diameter,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isHurt ? Colors.redAccent : pl.hero.themeColor,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isHurt ? Colors.red : pl.hero.themeColor)
                      .withOpacity(0.8),
                  blurRadius: 10,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                pl.hero.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Center(child: Text(pl.hero.decoEmoji)),
              ),
            ),
          ),
          Positioned(
            left: diameter / 2 + pl.facingX * (diameter * 0.42) - 5,
            top: diameter / 2 + pl.facingY * (diameter * 0.42) - 5,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
            ),
          ),
          Positioned(
            top: -12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: pl.hero.themeColor, width: 1),
                ),
                child: Text(
                  'P${pl.playerIndex}',
                  style: TextStyle(
                    color: pl.hero.themeColor,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'sans-serif',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitPlayerPanel({
    required RealtimePlayerState player,
    required List<String> keyHints,
    required String moveHint,
  }) {
    final double hpRatio = (player.hp / player.maxHp).clamp(0.0, 1.0);
    final specs = player.abilities;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Text(player.hero.decoEmoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                'P${player.playerIndex} • ${player.hero.name}',
                style: TextStyle(
                  color: player.hero.themeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '($moveHint)',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontFamily: 'sans-serif',
                ),
              ),
              const Spacer(),
              Text(
                '${player.hp}/${player.maxHp} PV',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  fontFamily: 'sans-serif',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: hpRatio,
              minHeight: 7,
              backgroundColor: Colors.black54,
              valueColor: AlwaysStoppedAnimation<Color>(
                hpRatio > 0.4 ? Colors.greenAccent : Colors.redAccent,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: List.generate(3, (i) {
                final spec = specs[i];
                final double cd = player.cooldowns[i];
                final bool ready = cd <= 0.0;
                final bool isAiming = i == 2 && player.awaitingTargetClick;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                    child: InkWell(
                      onTap: ready
                          ? () {
                              _triggerAbility(player, i);
                              _focusNode.requestFocus();
                            }
                          : null,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: isAiming
                              ? Colors.redAccent.withOpacity(0.28)
                              : (ready
                                  ? player.hero.themeColor.withOpacity(0.16)
                                  : Colors.black45),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isAiming
                                ? Colors.redAccent
                                : (ready
                                    ? player.hero.themeColor
                                    : Colors.white24),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  spec.icon,
                                  size: 15,
                                  color: ready
                                      ? player.hero.themeColor
                                      : Colors.white38,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    spec.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: ready
                                          ? Colors.white
                                          : Colors.white54,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              spec.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 9.5,
                                fontFamily: 'sans-serif',
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '[${keyHints[i]}]',
                                  style: const TextStyle(
                                    color: Colors.amberAccent,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'sans-serif',
                                  ),
                                ),
                                Text(
                                  isAiming
                                      ? 'CLIQUE MAPA'
                                      : (ready
                                          ? 'PRONTO'
                                          : '${cd.toStringAsFixed(1)}s'),
                                  style: TextStyle(
                                    color: isAiming
                                        ? Colors.redAccent
                                        : (ready
                                            ? Colors.lightGreenAccent
                                            : Colors.orangeAccent),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'sans-serif',
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
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ESTADO DINÂMICO DO JOGADOR EM ARENA POR TURNOS
// ==========================================
class HeroBattleState {
  int hp;
  int maxHp;
  int tempHp;
  int spellPoints;
  int maxSpellPoints;
  int row;
  int col;
  bool symbioticEntityActive = false;
  bool favorDivinoActive = false;
  bool golpeMarcadorActive = false;
  bool destruicaoDivinaCharged = false;
  bool armaSagradaActive = false;
  int fintaAttackBonus = 0;
  int acBonus = 0;
  double extraMoveThisTurn = 0.0;
  bool sneakAttackUsedThisTurn = false;
  final Map<String, int> remainingUses = {};

  HeroBattleState({
    required CharacterData template,
    required this.row,
    required this.col,
  })  : hp = template.maxHp,
        maxHp = template.maxHp,
        tempHp = 0,
        spellPoints = template.maxSpellPoints,
        maxSpellPoints = template.maxSpellPoints {
    for (final ab in template.abilities) {
      remainingUses[ab.id] = ab.maxUses;
    }
  }

  void takeDamage(int dmg) {
    if (dmg <= 0) return;
    int remaining = dmg;
    if (tempHp > 0) {
      if (tempHp >= remaining) {
        tempHp -= remaining;
        remaining = 0;
      } else {
        remaining -= tempHp;
        tempHp = 0;
      }
      if (tempHp == 0 && symbioticEntityActive) {
        symbioticEntityActive = false;
      }
    }
    hp = math.max(0, hp - remaining);
  }

  void heal(int amount) {
    hp = math.min(maxHp, hp + amount);
  }
}

// ==========================================
// BOT INTELIGENTE COM HABILIDADES PRÓPRIAS
// ==========================================
class BotAbilitySpec {
  final String name;
  final String description;
  final double rangeMeters;
  final int diceCount;
  final int diceSides;
  final int flatBonus;
  final String saveStat; // vazio = ataque normal ou buff
  final int saveDc;
  final bool halfOnSave;
  final bool isSelfBuff;
  int usesLeft;

  BotAbilitySpec({
    required this.name,
    required this.description,
    required this.rangeMeters,
    required this.diceCount,
    required this.diceSides,
    required this.flatBonus,
    this.saveStat = '',
    this.saveDc = 13,
    this.halfOnSave = true,
    this.isSelfBuff = false,
    required this.usesLeft,
  });
}

class ArenaBot {
  final int index;
  final String name;
  final String emoji;
  final String weaponName;
  final int maxHp;
  int currentHp;
  int ac;
  final double speedMeters;
  int attackBonus;
  final int diceCount;
  final int diceSides;
  final int bonusDamage;
  final int saveMod;
  int row;
  int col;
  final List<BotAbilitySpec> abilities;
  final AnimationController shakeController;

  ArenaBot({
    required this.index,
    required this.name,
    required this.emoji,
    required this.weaponName,
    required this.maxHp,
    required this.currentHp,
    required this.ac,
    required this.speedMeters,
    required this.attackBonus,
    required this.diceCount,
    required this.diceSides,
    required this.bonusDamage,
    required this.saveMod,
    required this.row,
    required this.col,
    required this.abilities,
    required this.shakeController,
  });
}

// ==========================================
// 4. ARENA TÁTICA D&D 5E (MODO POR TURNOS)
// ==========================================
enum ActiveTurnEntity {
  player1,
  player2,
  enemy,
}

class BattleGridScreen extends StatefulWidget {
  final GameMode mode;
  final CharacterData player1;
  final CharacterData? player2;
  final BotDifficulty botDifficulty;
  final int botCount;

  const BattleGridScreen({
    super.key,
    required this.mode,
    required this.player1,
    this.player2,
    this.botDifficulty = BotDifficulty.medium,
    this.botCount = 1,
  });

  @override
  State<BattleGridScreen> createState() => _BattleGridScreenState();
}

class _BattleGridScreenState extends State<BattleGridScreen>
    with TickerProviderStateMixin {
  static const double tileMeters = 1.5;
  static const int cols = 12;
  static const int rows = 8;
  final math.Random _rng = math.Random();
  final ScrollController _bottomCardsScrollController = ScrollController();

  late HeroBattleState p1State;
  HeroBattleState? p2State;
  final List<ArenaBot> bots = [];
  int activeBotIndex = 0;
  int selectedTargetBotIndex = 0;

  ActiveTurnEntity currentTurn = ActiveTurnEntity.player1;
  bool actionAvailable = true;
  bool bonusActionAvailable = true;
  bool hasMovedThisTurn = false;
  bool _isAutoPassing = false;
  int roundNumber = 1;
  bool battleOver = false;
  bool _isScreenFlashing = false;

  String? _turnAnnouncementText;
  Color _turnAnnouncementColor = const Color(0xFFD4AF37);
  int _announcementTicket = 0;
  String _currentMapName = 'Arena Clássica';
  final Set<String> obstacles = {};
  int selectedMenuTab = 0;
  final List<CombatLogEntry> combatLog = [];
  final List<ActiveFloatingText> floatingTexts = [];

  late AnimationController _p1ShakeController;
  late AnimationController _p2ShakeController;

  bool get _hasPlayer2 => widget.mode != GameMode.singlePlayer;
  bool get _hasBots => widget.mode != GameMode.twoPlayersPvp;
  bool get _isHumanTurn =>
      currentTurn == ActiveTurnEntity.player1 ||
      currentTurn == ActiveTurnEntity.player2;
  CharacterData get _activeHero =>
      currentTurn == ActiveTurnEntity.player2 ? widget.player2! : widget.player1;
  HeroBattleState get _activeState =>
      currentTurn == ActiveTurnEntity.player2 ? p2State! : p1State;

  ArenaBot? get _selectedTargetBot {
    if (bots.isEmpty) return null;
    if (selectedTargetBotIndex >= 0 &&
        selectedTargetBotIndex < bots.length &&
        bots[selectedTargetBotIndex].currentHp > 0) {
      return bots[selectedTargetBotIndex];
    }
    for (int i = 0; i < bots.length; i++) {
      if (bots[i].currentHp > 0) {
        selectedTargetBotIndex = i;
        return bots[i];
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _p1ShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _p2ShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _setupBattle();
  }

  @override
  void dispose() {
    _bottomCardsScrollController.dispose();
    _p1ShakeController.dispose();
    _p2ShakeController.dispose();
    for (final b in bots) {
      b.shakeController.dispose();
    }
    super.dispose();
  }

  void _generateRandomMapAndSpawns() {
    obstacles.clear();
    final int mapPreset = _rng.nextInt(5);
    switch (mapPreset) {
      case 0:
        _currentMapName = 'Pilares do Templo Antigo';
        obstacles.addAll({'1,4', '2,4', '5,4', '6,4', '2,7', '5,7'});
        break;
      case 1:
        _currentMapName = 'Corredor das Ruínas';
        obstacles.addAll({'0,5', '1,5', '3,3', '4,8', '6,6', '7,6'});
        break;
      case 2:
        _currentMapName = 'Santuário Central';
        obstacles.addAll({'3,5', '3,6', '4,5', '4,6', '1,2', '6,9'});
        break;
      case 3:
        _currentMapName = 'Bastião Quebrado';
        obstacles.addAll({'1,3', '2,3', '2,8', '5,3', '5,8', '6,8'});
        break;
      case 4:
        _currentMapName = 'Pátio de Pedra Aberto';
        obstacles.addAll({'1,6', '6,5', '3,2', '4,9'});
        break;
    }

    final p1Spawn = _pickRandomFreeTile(minCol: 0, maxCol: 3);
    p1State = HeroBattleState(
      template: widget.player1,
      row: p1Spawn[0],
      col: p1Spawn[1],
    );

    if (widget.mode == GameMode.twoPlayersPvp) {
      final p2Spawn = _pickRandomFreeTile(
        minCol: 8,
        maxCol: 11,
        avoid: {'${p1State.row},${p1State.col}'},
      );
      p2State = HeroBattleState(
        template: widget.player2!,
        row: p2Spawn[0],
        col: p2Spawn[1],
      );
    } else if (widget.mode == GameMode.twoPlayersCoop) {
      final p2Spawn = _pickRandomFreeTile(
        minCol: 0,
        maxCol: 3,
        avoid: {'${p1State.row},${p1State.col}'},
      );
      p2State = HeroBattleState(
        template: widget.player2!,
        row: p2Spawn[0],
        col: p2Spawn[1],
      );
    } else {
      p2State = null;
    }
  }

  List<int> _pickRandomFreeTile({
    required int minCol,
    required int maxCol,
    Set<String> avoid = const {},
  }) {
    final List<List<int>> candidates = [];
    for (int r = 0; r < rows; r++) {
      for (int c = minCol; c <= maxCol; c++) {
        final key = '$r,$c';
        if (!obstacles.contains(key) && !avoid.contains(key)) {
          candidates.add([r, c]);
        }
      }
    }
    if (candidates.isEmpty) return [0, minCol];
    return candidates[_rng.nextInt(candidates.length)];
  }

  void _announceTurn(String text, Color color) {
    _announcementTicket++;
    final int currentTicket = _announcementTicket;
    setState(() {
      _turnAnnouncementText = text;
      _turnAnnouncementColor = color;
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _announcementTicket == currentTicket) {
        setState(() {
          _turnAnnouncementText = null;
        });
      }
    });
  }

  void _setupBattle() {
    for (final b in bots) {
      b.shakeController.dispose();
    }
    bots.clear();
    _generateRandomMapAndSpawns();

    if (_hasBots) {
      _spawnBots();
    }

    roundNumber = 1;
    selectedTargetBotIndex = 0;
    currentTurn = ActiveTurnEntity.player1;
    _resetTurnFlagsForActiveHero();
    _isAutoPassing = false;
    battleOver = false;
    combatLog.clear();

    _addLog(
      'Mapa: $_currentMapName | Regras Nível 7 com Pontos de Magia (PM) ativos!',
      const Color(0xFFD4AF37),
    );

    if (widget.mode == GameMode.twoPlayersPvp) {
      _addLog(
        'DUELO PVP! P1 (${widget.player1.name}) vs P2 (${widget.player2!.name})!',
        Colors.amberAccent,
      );
    } else {
      final diffName = widget.botDifficulty == BotDifficulty.easy
          ? 'FÁCIL'
          : (widget.botDifficulty == BotDifficulty.medium ? 'MÉDIO' : 'DIFÍCIL');
      _addLog(
        'Modo Bots [$diffName]: ${bots.length} inimigo(s) entraram na arena! Clique em um bot no grid para focar seu alvo.',
        Colors.amberAccent,
      );
    }

    _announceTurn(
      'TURNO DO JOGADOR 1 • ${widget.player1.name}',
      widget.player1.themeColor,
    );
  }

  void _resetTurnFlagsForActiveHero() {
    actionAvailable = true;
    bonusActionAvailable = true;
    hasMovedThisTurn = false;
    if (_isHumanTurn) {
      _activeState.sneakAttackUsedThisTurn = false;
      _activeState.extraMoveThisTurn = 0.0;
    }
  }

  void _spawnBots() {
    final int count = widget.botCount.clamp(1, 3);
    final bool isCoop = widget.mode == GameMode.twoPlayersCoop;

    final double hpMult = widget.botDifficulty == BotDifficulty.easy
        ? 0.72
        : (widget.botDifficulty == BotDifficulty.medium ? 1.0 : 1.32);
    final int acBonus = widget.botDifficulty == BotDifficulty.easy
        ? -1
        : (widget.botDifficulty == BotDifficulty.medium ? 0 : 2);
    final int atkBonusAdd = widget.botDifficulty == BotDifficulty.easy
        ? -1
        : (widget.botDifficulty == BotDifficulty.medium ? 0 : 2);
    final int saveMod = widget.botDifficulty == BotDifficulty.easy
        ? 1
        : (widget.botDifficulty == BotDifficulty.medium ? 2 : 4);
    final int saveDc = widget.botDifficulty == BotDifficulty.easy
        ? 12
        : (widget.botDifficulty == BotDifficulty.medium ? 14 : 16);

    final archetypes = [
      {
        'name': 'Campeão Hobgoblin',
        'emoji': '👹',
        'weapon': 'Espada Longa Marcial',
        'baseHp': 58,
        'ac': 15,
        'speed': 9.0,
        'diceCount': 2,
        'diceSides': 6,
        'bonusDmg': 3,
        'abilities': [
          BotAbilitySpec(
            name: 'Postura de Falange',
            description: '+2 CA e foco marcial!',
            rangeMeters: 0,
            diceCount: 0,
            diceSides: 0,
            flatBonus: 2,
            isSelfBuff: true,
            usesLeft: 1,
          ),
          BotAbilitySpec(
            name: 'Golpe Estilhaçante',
            description: 'Impacto sísmico (Resist. FOR/CON)',
            rangeMeters: 3.0,
            diceCount: 2,
            diceSides: 8,
            flatBonus: 2,
            saveStat: 'CON',
            saveDc: saveDc,
            halfOnSave: true,
            usesLeft: 2,
          ),
        ],
      },
      {
        'name': 'Necromante Esqueleto',
        'emoji': '💀',
        'weapon': 'Toque Gélido',
        'baseHp': 48,
        'ac': 13,
        'speed': 9.0,
        'diceCount': 1,
        'diceSides': 8,
        'bonusDmg': 2,
        'abilities': [
          BotAbilitySpec(
            name: 'Raio Necrótico (15m)',
            description: 'Drenagem sombria à distância',
            rangeMeters: 15.0,
            diceCount: 2,
            diceSides: 8,
            flatBonus: 2,
            saveStat: 'CON',
            saveDc: saveDc,
            halfOnSave: true,
            usesLeft: 3,
          ),
          BotAbilitySpec(
            name: 'Miasma Sombrio (9m)',
            description: 'Explosão de energia negativa',
            rangeMeters: 9.0,
            diceCount: 3,
            diceSides: 6,
            flatBonus: 0,
            saveStat: 'SAB',
            saveDc: saveDc,
            halfOnSave: true,
            usesLeft: 2,
          ),
        ],
      },
      {
        'name': 'Manticora Caçadora',
        'emoji': '🦁',
        'weapon': 'Garras Dilacerantes',
        'baseHp': 54,
        'ac': 14,
        'speed': 10.5,
        'diceCount': 2,
        'diceSides': 6,
        'bonusDmg': 3,
        'abilities': [
          BotAbilitySpec(
            name: 'Saraivada de Espinhos (18m)',
            description: 'Dispara espinhos da cauda',
            rangeMeters: 18.0,
            diceCount: 2,
            diceSides: 8,
            flatBonus: 2,
            saveStat: 'DES',
            saveDc: saveDc,
            halfOnSave: true,
            usesLeft: 3,
          ),
          BotAbilitySpec(
            name: 'Rugido Aterrador (6m)',
            description: 'Onda sonora intimidadora',
            rangeMeters: 6.0,
            diceCount: 2,
            diceSides: 6,
            flatBonus: 2,
            saveStat: 'SAB',
            saveDc: saveDc,
            halfOnSave: false,
            usesLeft: 1,
          ),
        ],
      },
    ];

    final Set<String> occupied = {'${p1State.row},${p1State.col}'};
    if (p2State != null) {
      occupied.add('${p2State!.row},${p2State!.col}');
    }

    for (int i = 0; i < count; i++) {
      final arch = archetypes[i % archetypes.length];
      final spawn = _pickRandomFreeTile(
        minCol: 8,
        maxCol: 11,
        avoid: occupied,
      );
      occupied.add('${spawn[0]},${spawn[1]}');

      final double countScale = count == 1 ? 1.35 : (count == 2 ? 0.95 : 0.78);
      final double coopScale = isCoop ? 1.35 : 1.0;
      final int finalHp =
          ((arch['baseHp'] as int) * hpMult * countScale * coopScale).round();

      bots.add(
        ArenaBot(
          index: i + 1,
          name: count > 1 ? '${arch['name']} #${i + 1}' : arch['name'] as String,
          emoji: arch['emoji'] as String,
          weaponName: arch['weapon'] as String,
          maxHp: finalHp,
          currentHp: finalHp,
          ac: (arch['ac'] as int) + acBonus,
          speedMeters: arch['speed'] as double,
          attackBonus: 5 + atkBonusAdd,
          diceCount: arch['diceCount'] as int,
          diceSides: arch['diceSides'] as int,
          bonusDamage: (arch['bonusDmg'] as int) + math.max(0, atkBonusAdd),
          saveMod: saveMod,
          row: spawn[0],
          col: spawn[1],
          abilities: arch['abilities'] as List<BotAbilitySpec>,
          shakeController: AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 450),
          ),
        ),
      );
    }
  }

  void _addLog(String message, Color color) {
    combatLog.insert(0, CombatLogEntry(text: message, color: color));
  }

  bool _isObstacle(int r, int c) => obstacles.contains('$r,$c');

  double _distanceMeters(int r1, int c1, int r2, int c2) {
    final int squares = math.max((r1 - r2).abs(), (c1 - c2).abs());
    return squares * tileMeters;
  }

  bool _isTileOccupied(int r, int c) {
    if (p1State.hp > 0 && r == p1State.row && c == p1State.col) return true;
    if (_hasPlayer2 &&
        p2State != null &&
        p2State!.hp > 0 &&
        r == p2State!.row &&
        c == p2State!.col) {
      return true;
    }
    for (final b in bots) {
      if (b.currentHp > 0 && r == b.row && c == b.col) return true;
    }
    return false;
  }

  double _distanceToPrimaryTarget(HeroBattleState state) {
    if (widget.mode == GameMode.twoPlayersPvp) {
      final other = currentTurn == ActiveTurnEntity.player1 ? p2State! : p1State;
      if (other.hp <= 0) return 9999;
      return _distanceMeters(state.row, state.col, other.row, other.col);
    } else {
      final targetBot = _selectedTargetBot;
      if (targetBot == null || targetBot.currentHp <= 0) return 9999;
      return _distanceMeters(
          state.row, state.col, targetBot.row, targetBot.col);
    }
  }

  bool _hasTargetInMeleeRange() {
    if (!_isHumanTurn) return false;
    return _distanceToPrimaryTarget(_activeState) <= 1.5;
  }

  void _checkAutoPassTurn() {
    if (!_isHumanTurn || battleOver || _isAutoPassing) return;
    if (!actionAvailable && !bonusActionAvailable) {
      _isAutoPassing = true;
      Future.delayed(const Duration(milliseconds: 650), () {
        if (!mounted || battleOver) return;
        _isAutoPassing = false;
        _passCurrentTurn();
      });
    }
  }

  void _handleTileTap(int r, int c) {
    // Permite clicar em um bot vivo para selecioná-lo como alvo principal
    if (_hasBots) {
      for (int i = 0; i < bots.length; i++) {
        if (bots[i].currentHp > 0 && bots[i].row == r && bots[i].col == c) {
          setState(() {
            selectedTargetBotIndex = i;
            _addLog('Alvo selecionado: ${bots[i].name} (${bots[i].currentHp}/${bots[i].maxHp} PV).',
                Colors.amberAccent);
          });
          return;
        }
      }
    }

    if (!_isHumanTurn || battleOver || _isAutoPassing) return;
    if (_isObstacle(r, c) || _isTileOccupied(r, c)) return;

    final bool isP1 = currentTurn == ActiveTurnEntity.player1;
    final HeroBattleState state = _activeState;
    final CharacterData hero = _activeHero;
    final double allowedMove = hero.speedMeters + state.extraMoveThisTurn;

    if (!bonusActionAvailable && state.extraMoveThisTurn <= 0) {
      _addLog(
        '${hero.name} já gastou a Ação Bônus (Locomoção) neste turno!',
        Colors.orangeAccent,
      );
      setState(() {});
      return;
    }
    if (hasMovedThisTurn) {
      _addLog(
        '${hero.name} já se deslocou neste turno!',
        Colors.orangeAccent,
      );
      setState(() {});
      return;
    }

    final double distMeters = _distanceMeters(state.row, state.col, r, c);
    if (distMeters > allowedMove) {
      _addLog(
        'Distância de ${distMeters.toStringAsFixed(1)}m excede o deslocamento de ${hero.name} (${allowedMove.toStringAsFixed(0)}m).',
        Colors.redAccent,
      );
      setState(() {});
      return;
    }

    setState(() {
      state.row = r;
      state.col = c;
      hasMovedThisTurn = true;
      bonusActionAvailable = false;
      _addLog(
        '[Ação Bônus ${isP1 ? "P1" : "P2"}] ${hero.name} se locomoveu ${distMeters.toStringAsFixed(1)}m.',
        hero.themeColor,
      );
    });
    _checkAutoPassTurn();
  }

  Future<void> _openHumanAttackModal(MeleeAttack attack) async {
    if (!_isHumanTurn || battleOver || _isAutoPassing) return;
    final bool isP1 = currentTurn == ActiveTurnEntity.player1;
    final CharacterData attacker = _activeHero;
    final HeroBattleState attState = _activeState;

    if (!actionAvailable) {
      _addLog(
        '${attacker.name} já usou a Ação neste turno!',
        Colors.orangeAccent,
      );
      setState(() {});
      return;
    }
    if (!_hasTargetInMeleeRange()) {
      _addLog(
        'Nenhum alvo a 1,5m! Aproxime-se antes de atacar.',
        Colors.orangeAccent,
      );
      setState(() {});
      return;
    }

    final bool targetIsPlayer = widget.mode == GameMode.twoPlayersPvp;
    final HeroBattleState? targetPlayerState =
        targetIsPlayer ? (isP1 ? p2State! : p1State) : null;
    final CharacterData? targetPlayerData =
        targetIsPlayer ? (isP1 ? widget.player2! : widget.player1) : null;
    final ArenaBot? targetBot = targetIsPlayer ? null : _selectedTargetBot;

    if (!targetIsPlayer && targetBot == null) return;

    final String targetName = targetIsPlayer
        ? (isP1
            ? 'P2 ${targetPlayerData!.name}'
            : 'P1 ${targetPlayerData!.name}')
        : targetBot!.name;

    final int targetAc = targetIsPlayer
        ? (targetPlayerData!.ac + targetPlayerState!.acBonus)
        : targetBot!.ac;

    final int extraAtkBonus =
        (attState.armaSagradaActive ? attacker.chaMod : 0) +
            attState.fintaAttackBonus;

    int extraDiceCount = 0;
    int extraDiceSides = 6;
    String buffTag = '';

    if (attacker.name == 'ARES' &&
        attack.isFinesse &&
        !attState.sneakAttackUsedThisTurn) {
      extraDiceCount = 4;
      extraDiceSides = 6;
      buffTag = ' + Furtivo 4d6';
    } else if (attState.symbioticEntityActive) {
      extraDiceCount = 1;
      extraDiceSides = 6;
      buffTag = ' + Esporos 1d6';
    } else if (attState.destruicaoDivinaCharged) {
      extraDiceCount = 2;
      extraDiceSides = 8;
      buffTag = ' + Destruição 2d8';
    } else if (attState.golpeMarcadorActive) {
      extraDiceCount = 2;
      extraDiceSides = 6;
      buffTag = ' + Golpe Marcador 2d6';
    } else if (attState.favorDivinoActive) {
      extraDiceCount = 1;
      extraDiceSides = 4;
      buffTag = ' + Favor Divino 1d4';
    }

    final DiceRollOutcome? outcome = await showDialog<DiceRollOutcome>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DiceCombatModal(
        isPlayerRolling: true,
        attackerName: '${isP1 ? "P1" : "P2"} ${attacker.name}',
        defenderName: targetName,
        targetAc: targetAc,
        attackName: '${attack.name}$buffTag',
        attackBonus: attack.attackMod + extraAtkBonus,
        diceCount: attack.diceCount,
        diceSides: attack.diceSides,
        bonusDamage: attack.damageMod,
        extraDiceCount: extraDiceCount,
        extraDiceSides: extraDiceSides,
        accentColor: attacker.themeColor,
      ),
    );

    if (outcome == null || !mounted) return;

    setState(() {
      actionAvailable = false;
      attState.fintaAttackBonus = 0;

      if (outcome.hit) {
        if (attacker.name == 'ARES' &&
            attack.isFinesse &&
            !attState.sneakAttackUsedThisTurn) {
          attState.sneakAttackUsedThisTurn = true;
        }
        if (attState.destruicaoDivinaCharged) {
          attState.destruicaoDivinaCharged = false;
        }
        if (attState.golpeMarcadorActive) {
          attState.golpeMarcadorActive = false;
        }

        if (targetIsPlayer) {
          targetPlayerState!.takeDamage(outcome.totalDamage);
          if (isP1) {
            _p2ShakeController.forward(from: 0.0);
          } else {
            _p1ShakeController.forward(from: 0.0);
          }
        } else {
          targetBot!.currentHp =
              math.max(0, targetBot.currentHp - outcome.totalDamage);
          targetBot.shakeController.forward(from: 0.0);
        }

        final int totalMod = attack.attackMod + extraAtkBonus;
        final String modStr = totalMod >= 0 ? '+$totalMod' : '$totalMod';
        _addLog(
          '${outcome.isCrit ? "CRÍTICO (20)!" : "ACERTOU!"} ${attacker.name} (${attack.name}$buffTag): '
          '1d20(${outcome.d20})$modStr = ${outcome.totalAttack} vs CA $targetAc. '
          'Dano: ${outcome.totalDamage}!',
          outcome.isCrit ? Colors.amberAccent : Colors.lightGreenAccent,
        );
        _checkVictoryConditions();
      } else {
        final int totalMod = attack.attackMod + extraAtkBonus;
        final String modStr = totalMod >= 0 ? '+$totalMod' : '$totalMod';
        _addLog(
          'ERROU! ${attacker.name} (${attack.name}): '
          '1d20(${outcome.d20})$modStr = ${outcome.totalAttack} (CA $targetAc).',
          Colors.white60,
        );
      }
    });
    _checkAutoPassTurn();
  }

  int _getStatModifier(CharacterData hero, String stat) {
    switch (stat.toUpperCase()) {
      case 'FOR':
        return hero.strMod;
      case 'DES':
        return hero.dexMod;
      case 'CON':
        return hero.conMod;
      case 'INT':
        return hero.intMod;
      case 'SAB':
        return hero.wisMod;
      case 'CAR':
        return hero.chaMod;
      default:
        return 2;
    }
  }

  Future<void> _castSpell(SpellItem spell) async {
    if (!_isHumanTurn || battleOver || _isAutoPassing) return;
    final bool isP1 = currentTurn == ActiveTurnEntity.player1;
    final CharacterData caster = _activeHero;
    final HeroBattleState casterState = _activeState;

    if (casterState.spellPoints < spell.pmCost) {
      _addLog(
        'PM insuficientes! ${spell.name} custa ${spell.pmCost} PM (você tem ${casterState.spellPoints} PM).',
        Colors.redAccent,
      );
      setState(() {});
      return;
    }
    if (spell.costType == ActionCostType.action && !actionAvailable) {
      _addLog('Você já gastou sua Ação neste turno!', Colors.orangeAccent);
      setState(() {});
      return;
    }
    if (spell.costType == ActionCostType.bonusAction && !bonusActionAvailable) {
      _addLog(
          'Você já gastou sua Ação Bônus neste turno!', Colors.orangeAccent);
      setState(() {});
      return;
    }

    if (spell.targetType == TargetType.enemySingle) {
      final double dist = _distanceToPrimaryTarget(casterState);
      if (dist > spell.rangeMeters) {
        _addLog(
          'Alvo fora de alcance (${dist.toStringAsFixed(1)}m > ${spell.rangeMeters.toStringAsFixed(0)}m)!',
          Colors.orangeAccent,
        );
        setState(() {});
        return;
      }
    }

    // Magias de Cura ou Buff Pessoal
    if (spell.isHealing || spell.targetType != TargetType.enemySingle) {
      setState(() {
        casterState.spellPoints -= spell.pmCost;
        if (spell.costType == ActionCostType.action) {
          actionAvailable = false;
        } else if (spell.costType == ActionCostType.bonusAction) {
          bonusActionAvailable = false;
        }

        if (spell.isHealing) {
          int rolled = 0;
          for (int i = 0; i < spell.diceCount; i++) {
            rolled += _rng.nextInt(spell.diceSides) + 1;
          }
          final int totalHeal = rolled + spell.flatBonus;
          HeroBattleState healTarget = casterState;
          String targetLabel = caster.name;

          if (widget.mode == GameMode.twoPlayersCoop && p2State != null) {
            final HeroBattleState ally = isP1 ? p2State! : p1State;
            final String allyName =
                isP1 ? widget.player2!.name : widget.player1.name;
            final double distToAlly = _distanceMeters(
                casterState.row, casterState.col, ally.row, ally.col);
            if (ally.hp > 0 &&
                distToAlly <= spell.rangeMeters &&
                (ally.maxHp - ally.hp) > (casterState.maxHp - casterState.hp)) {
              healTarget = ally;
              targetLabel = allyName;
            }
          }

          healTarget.heal(totalHeal);
          _addLog(
            '[${spell.pmCost} PM] ${caster.name} conjurou ${spell.name} em $targetLabel e restaurou +$totalHeal PV!',
            Colors.greenAccent,
          );
        } else if (spell.id == 'alash_favor_divino') {
          casterState.favorDivinoActive = true;
          _addLog(
            '[${spell.pmCost} PM] ${caster.name} ativou Favor Divino (+1d4 radiante nos ataques)!',
            Colors.amberAccent,
          );
        } else if (spell.id == 'alash_escudo_fe') {
          casterState.acBonus += 2;
          _addLog(
            '[${spell.pmCost} PM] ${caster.name} conjurou Escudo da Fé (+2 CA)!',
            Colors.cyanAccent,
          );
        } else if (spell.id == 'alash_golpe_marcador') {
          casterState.golpeMarcadorActive = true;
          _addLog(
            '[${spell.pmCost} PM] ${caster.name} preparou Golpe Marcador (+2d6 radiante no próximo acerto)!',
            Colors.amberAccent,
          );
        }
      });
      _checkAutoPassTurn();
      return;
    }

    final bool targetIsPlayer = widget.mode == GameMode.twoPlayersPvp;
    final HeroBattleState? targetPlayerState =
        targetIsPlayer ? (isP1 ? p2State! : p1State) : null;
    final CharacterData? targetPlayerData =
        targetIsPlayer ? (isP1 ? widget.player2! : widget.player1) : null;
    final ArenaBot? targetBot = targetIsPlayer ? null : _selectedTargetBot;

    if (!targetIsPlayer && targetBot == null) return;

    final String targetName = targetIsPlayer
        ? (isP1
            ? 'P2 ${targetPlayerData!.name}'
            : 'P1 ${targetPlayerData!.name}')
        : targetBot!.name;

    final int targetAc = targetIsPlayer
        ? (targetPlayerData!.ac + targetPlayerState!.acBonus)
        : targetBot!.ac;

    if (spell.usesSpellAttack) {
      final DiceRollOutcome? outcome = await showDialog<DiceRollOutcome>(
        context: context,
        barrierDismissible: false,
        builder: (context) => DiceCombatModal(
          isPlayerRolling: true,
          attackerName: '${isP1 ? "P1" : "P2"} ${caster.name}',
          defenderName: targetName,
          targetAc: targetAc,
          attackName: '${spell.name} (${spell.pmCost} PM)',
          attackBonus: caster.spellAttackBonus,
          diceCount: spell.diceCount,
          diceSides: spell.diceSides,
          bonusDamage: spell.flatBonus,
          accentColor: Colors.cyanAccent,
        ),
      );

      if (outcome == null || !mounted) return;

      setState(() {
        casterState.spellPoints -= spell.pmCost;
        if (spell.costType == ActionCostType.action) {
          actionAvailable = false;
        } else {
          bonusActionAvailable = false;
        }

        if (outcome.hit) {
          if (targetIsPlayer) {
            targetPlayerState!.takeDamage(outcome.totalDamage);
            if (isP1) {
              _p2ShakeController.forward(from: 0.0);
            } else {
              _p1ShakeController.forward(from: 0.0);
            }
          } else {
            targetBot!.currentHp =
                math.max(0, targetBot.currentHp - outcome.totalDamage);
            targetBot.shakeController.forward(from: 0.0);
          }

          _addLog(
            '[${spell.pmCost} PM] ${caster.name} acertou ${spell.name} '
            '(1d20(${outcome.d20})+${caster.spellAttackBonus}=${outcome.totalAttack} vs CA $targetAc): '
            '${outcome.totalDamage} de dano!',
            Colors.cyanAccent,
          );
          _checkVictoryConditions();
        } else {
          _addLog(
            '[${spell.pmCost} PM] ${caster.name} errou ${spell.name} '
            '(1d20(${outcome.d20})+${caster.spellAttackBonus}=${outcome.totalAttack} vs CA $targetAc).',
            Colors.white60,
          );
        }
      });
    } else {
      // ============================================
      // MAGIA COM TESTE DE RESISTÊNCIA ANIMADO NA TELA
      // ============================================
      final int saveMod = (targetIsPlayer && targetPlayerData != null)
          ? _getStatModifier(targetPlayerData, spell.saveStat)
          : targetBot!.saveMod;

      final SavingThrowOutcome? saveOutcome =
          await showDialog<SavingThrowOutcome>(
        context: context,
        barrierDismissible: false,
        builder: (context) => SavingThrowModal(
          casterName: caster.name,
          targetName: targetName,
          spellName: spell.name,
          saveStat: spell.saveStat,
          spellSaveDc: caster.spellSaveDc,
          targetSaveMod: saveMod,
          diceCount: spell.diceCount,
          diceSides: spell.diceSides,
          flatBonus: spell.flatBonus,
          halfOnSave: spell.halfOnSave,
          accentColor: caster.themeColor,
        ),
      );

      if (saveOutcome == null || !mounted) return;

      setState(() {
        casterState.spellPoints -= spell.pmCost;
        if (spell.costType == ActionCostType.action) {
          actionAvailable = false;
        } else {
          bonusActionAvailable = false;
        }

        if (saveOutcome.finalDamage > 0) {
          if (targetIsPlayer) {
            targetPlayerState!.takeDamage(saveOutcome.finalDamage);
            if (isP1) {
              _p2ShakeController.forward(from: 0.0);
            } else {
              _p1ShakeController.forward(from: 0.0);
            }
          } else {
            targetBot!.currentHp =
                math.max(0, targetBot.currentHp - saveOutcome.finalDamage);
            targetBot.shakeController.forward(from: 0.0);
          }
        }

        _addLog(
          '[${spell.pmCost} PM] ${caster.name} conjurou ${spell.name}! '
          '$targetName rolou Resist. ${spell.saveStat}: 1d20(${saveOutcome.d20})+$saveMod = ${saveOutcome.totalSave} vs CD ${caster.spellSaveDc} '
          '(${saveOutcome.saved ? "PASSOU" : "FALHOU"}) → ${saveOutcome.finalDamage} de dano!',
          saveOutcome.saved ? Colors.amberAccent : Colors.purpleAccent,
        );
        _checkVictoryConditions();
      });
    }
    _checkAutoPassTurn();
  }

  Future<void> _useClassAbility(ClassAbilityItem ability) async {
    if (!_isHumanTurn || battleOver || _isAutoPassing) return;
    final bool isP1 = currentTurn == ActiveTurnEntity.player1;
    final CharacterData hero = _activeHero;
    final HeroBattleState state = _activeState;

    if (ability.costType == ActionCostType.freePassive) {
      _addLog(
        '${ability.name} é uma habilidade passiva e já está ativa automaticamente!',
        hero.themeColor,
      );
      setState(() {});
      return;
    }

    final int usesLeft = state.remainingUses[ability.id] ?? 0;
    if (usesLeft <= 0) {
      _addLog('Sem usos restantes para ${ability.name}!', Colors.orangeAccent);
      setState(() {});
      return;
    }
    if (ability.costType == ActionCostType.action && !actionAvailable) {
      _addLog('Você já gastou sua Ação neste turno!', Colors.orangeAccent);
      setState(() {});
      return;
    }
    if (ability.costType == ActionCostType.bonusAction &&
        !bonusActionAvailable) {
      _addLog(
          'Você já gastou sua Ação Bônus neste turno!', Colors.orangeAccent);
      setState(() {});
      return;
    }

    // Habilidades que exigem Teste de Resistência animado
    if (ability.id == 'afro_halo_esporos' ||
        ability.id == 'afro_nuvem_esporos' ||
        ability.id == 'alash_onda_justiceira' ||
        ability.id == 'ares_spit' ||
        ability.id == 'ares_bomba_veneno') {
      double maxRange = 4.5;
      String stat = 'CON';
      int diceCount = 1;
      int diceSides = 6;
      bool halfOnSave = false;
      bool consumesUse = true;

      if (ability.id == 'afro_halo_esporos') {
        maxRange = 4.5;
        stat = 'CON';
        diceCount = state.symbioticEntityActive ? 2 : 1;
        diceSides = 6;
        halfOnSave = false;
        consumesUse = false;
      } else if (ability.id == 'afro_nuvem_esporos') {
        maxRange = 9.0;
        stat = 'CON';
        diceCount = 3;
        diceSides = 6;
        halfOnSave = true;
      } else if (ability.id == 'alash_onda_justiceira') {
        maxRange = 6.0;
        stat = 'CON';
        diceCount = 2;
        diceSides = 10;
        halfOnSave = false;
      } else if (ability.id == 'ares_spit') {
        maxRange = 9.0;
        stat = 'DES';
        diceCount = 2;
        diceSides = 10;
        halfOnSave = false;
      } else if (ability.id == 'ares_bomba_veneno') {
        maxRange = 12.0;
        stat = 'CON';
        diceCount = 3;
        diceSides = 6;
        halfOnSave = true;
      }

      if (_distanceToPrimaryTarget(state) > maxRange) {
        _addLog(
            'Alvo fora do alcance de ${maxRange.toStringAsFixed(1)}m para ${ability.name}!',
            Colors.orangeAccent);
        setState(() {});
        return;
      }

      final bool targetIsPlayer = widget.mode == GameMode.twoPlayersPvp;
      final HeroBattleState? targetPlayerState =
          targetIsPlayer ? (isP1 ? p2State! : p1State) : null;
      final CharacterData? targetPlayerData =
          targetIsPlayer ? (isP1 ? widget.player2! : widget.player1) : null;
      final ArenaBot? targetBot = targetIsPlayer ? null : _selectedTargetBot;
      if (!targetIsPlayer && targetBot == null) return;

      final String targetName = targetIsPlayer
          ? (isP1
              ? 'P2 ${targetPlayerData!.name}'
              : 'P1 ${targetPlayerData!.name}')
          : targetBot!.name;

      final int saveMod = (targetIsPlayer && targetPlayerData != null)
          ? _getStatModifier(targetPlayerData, stat)
          : targetBot!.saveMod;

      final SavingThrowOutcome? saveOutcome =
          await showDialog<SavingThrowOutcome>(
        context: context,
        barrierDismissible: false,
        builder: (context) => SavingThrowModal(
          casterName: hero.name,
          targetName: targetName,
          spellName: ability.name,
          saveStat: stat,
          spellSaveDc: hero.spellSaveDc,
          targetSaveMod: saveMod,
          diceCount: diceCount,
          diceSides: diceSides,
          flatBonus: 0,
          halfOnSave: halfOnSave,
          accentColor: hero.themeColor,
        ),
      );

      if (saveOutcome == null || !mounted) return;

      setState(() {
        if (consumesUse) {
          state.remainingUses[ability.id] = usesLeft - 1;
        }
        if (ability.costType == ActionCostType.action) {
          actionAvailable = false;
        } else {
          bonusActionAvailable = false;
        }

        if (saveOutcome.finalDamage > 0) {
          _applyDirectDamageToOpponent(isP1, saveOutcome.finalDamage);
        }

        _addLog(
          '[${ability.name}] $targetName rolou $stat (${saveOutcome.totalSave} vs CD ${hero.spellSaveDc}): '
          '${saveOutcome.saved ? "RESISTIU!" : "FALHOU!"} → ${saveOutcome.finalDamage} de dano!',
          saveOutcome.saved ? Colors.white60 : Colors.lightGreenAccent,
        );
        _checkVictoryConditions();
      });
      _checkAutoPassTurn();
      return;
    }

    // Demais habilidades de buff/utilidade
    setState(() {
      if (ability.id == 'afro_entidade_simbiotica') {
        final int wildUses = state.remainingUses['afro_forma_selvagem'] ?? 0;
        if (wildUses <= 0) {
          _addLog('Sem usos de Forma Selvagem para Entidade Simbiótica!',
              Colors.orangeAccent);
          return;
        }
        state.remainingUses['afro_forma_selvagem'] = wildUses - 1;
        state.remainingUses['afro_entidade_simbiotica'] = wildUses - 1;
        state.tempHp = 28;
        state.symbioticEntityActive = true;
        actionAvailable = false;
        _addLog(
          '[Ação] Afrodite ativou Entidade Simbiótica! (+28 PV temp, Halo 2d6 e +1d6 necrótico)',
          Colors.lightGreenAccent,
        );
      } else if (ability.id == 'afro_forma_selvagem') {
        final int wildUses = state.remainingUses['afro_forma_selvagem'] ?? 0;
        state.remainingUses['afro_forma_selvagem'] = wildUses - 1;
        state.remainingUses['afro_entidade_simbiotica'] = wildUses - 1;
        state.tempHp = 22;
        state.symbioticEntityActive = false;
        actionAvailable = false;
        _addLog(
          '[Ação] Afrodite assumiu Forma Selvagem (Lobo Atroz) e ganhou +22 PV de besta!',
          Colors.lightGreenAccent,
        );
      } else if (ability.id == 'afro_recuperacao_natural') {
        state.remainingUses[ability.id] = usesLeft - 1;
        bonusActionAvailable = false;
        state.spellPoints = math.min(state.maxSpellPoints, state.spellPoints + 8);
        _addLog(
          '[Recuperação Natural] Afrodite recuperou +8 PM!',
          Colors.cyanAccent,
        );
      } else if (ability.id == 'alash_imposicao_maos') {
        final int healAmount = math.min(15, usesLeft);
        state.remainingUses[ability.id] = usesLeft - healAmount;
        actionAvailable = false;
        state.heal(healAmount);
        _addLog(
          '[Imposição das Mãos] Alash curou +$healAmount PV (Reserva: ${state.remainingUses[ability.id]} PV).',
          Colors.pinkAccent,
        );
      } else if (ability.id == 'alash_destruicao_divina') {
        if (state.spellPoints < 2) {
          _addLog('Alash precisa de 2 PM para Destruição Divina!',
              Colors.redAccent);
          return;
        }
        state.spellPoints -= 2;
        bonusActionAvailable = false;
        state.destruicaoDivinaCharged = true;
        _addLog(
          '[Destruição Divina 2 PM] Próximo acerto corpo a corpo causará +2d8 radiante!',
          Colors.amberAccent,
        );
      } else if (ability.id == 'alash_arma_sagrada') {
        state.remainingUses[ability.id] = usesLeft - 1;
        actionAvailable = false;
        state.armaSagradaActive = true;
        _addLog(
          '[Arma Sagrada] Alash somou Carisma (+3) às jogadas de ataque!',
          Colors.amberAccent,
        );
      } else if (ability.id == 'alash_aura_protecao') {
        state.remainingUses[ability.id] = usesLeft - 1;
        bonusActionAvailable = false;
        state.acBonus += 1;
        state.tempHp += 10;
        _addLog(
          '[Aura de Proteção] Alash ganhou +1 CA e +10 PV temporários!',
          Colors.amberAccent,
        );
      } else if (ability.id == 'ares_acao_ardilosa') {
        bonusActionAvailable = false;
        state.extraMoveThisTurn = 9.0;
        hasMovedThisTurn = false;
        _addLog(
          '[Ação Ardilosa: Correr] Ares ganhou +9m de deslocamento extra neste turno (total 18m)!',
          Colors.amberAccent,
        );
      } else if (ability.id == 'ares_finta_mortal') {
        state.remainingUses[ability.id] = usesLeft - 1;
        bonusActionAvailable = false;
        state.fintaAttackBonus = 3;
        state.sneakAttackUsedThisTurn = false;
        _addLog(
          '[Finta Sombria] Ares ganhou +3 no próximo acerto!',
          Colors.amberAccent,
        );
      } else if (ability.id == 'ares_esquiva_sobrenatural') {
        state.remainingUses[ability.id] = usesLeft - 1;
        bonusActionAvailable = false;
        state.acBonus += 2;
        state.tempHp += 8;
        _addLog(
          '[Postura Evasiva] Ares ganhou +2 CA e +8 PV temporários!',
          Colors.lightGreenAccent,
        );
      }
    });
    _checkAutoPassTurn();
  }

  void _applyDirectDamageToOpponent(bool isP1, int dmg) {
    if (widget.mode == GameMode.twoPlayersPvp) {
      final target = isP1 ? p2State! : p1State;
      target.takeDamage(dmg);
      if (isP1) {
        _p2ShakeController.forward(from: 0.0);
      } else {
        _p1ShakeController.forward(from: 0.0);
      }
    } else {
      final targetBot = _selectedTargetBot;
      if (targetBot != null) {
        targetBot.currentHp = math.max(0, targetBot.currentHp - dmg);
        targetBot.shakeController.forward(from: 0.0);
      }
    }
  }

  void _checkVictoryConditions() {
    if (widget.mode == GameMode.twoPlayersPvp) {
      if (p2State!.hp == 0) {
        battleOver = true;
        _addLog('VITÓRIA DO JOGADOR 1 (${widget.player1.name})!', Colors.amber);
      } else if (p1State.hp == 0) {
        battleOver = true;
        _addLog('VITÓRIA DO JOGADOR 2 (${widget.player2!.name})!', Colors.amber);
      }
    } else {
      final bool allBotsDefeated = bots.every((b) => b.currentHp <= 0);
      if (allBotsDefeated) {
        battleOver = true;
        _addLog('VITÓRIA! Todos os bots da arena foram derrotados!', Colors.amber);
      }
    }
  }

  Future<void> _passCurrentTurn() async {
    if (!_isHumanTurn || battleOver) return;

    if (widget.mode == GameMode.singlePlayer) {
      await _runAllBotsTurn();
      if (!battleOver && mounted) {
        setState(() {
          roundNumber++;
          currentTurn = ActiveTurnEntity.player1;
          _resetTurnFlagsForActiveHero();
        });
        _announceTurn(
          'TURNO DO JOGADOR 1 • ${widget.player1.name}',
          widget.player1.themeColor,
        );
      }
    } else if (widget.mode == GameMode.twoPlayersPvp) {
      setState(() {
        if (currentTurn == ActiveTurnEntity.player1) {
          currentTurn = ActiveTurnEntity.player2;
        } else {
          roundNumber++;
          currentTurn = ActiveTurnEntity.player1;
        }
        _resetTurnFlagsForActiveHero();
      });
      if (currentTurn == ActiveTurnEntity.player2) {
        _announceTurn(
          'TURNO DO JOGADOR 2 • ${widget.player2!.name}',
          widget.player2!.themeColor,
        );
      } else {
        _announceTurn(
          'TURNO DO JOGADOR 1 • ${widget.player1.name}',
          widget.player1.themeColor,
        );
      }
    } else if (widget.mode == GameMode.twoPlayersCoop) {
      if (currentTurn == ActiveTurnEntity.player1 && p2State!.hp > 0) {
        setState(() {
          currentTurn = ActiveTurnEntity.player2;
          _resetTurnFlagsForActiveHero();
        });
        _announceTurn(
          'TURNO DO JOGADOR 2 • ${widget.player2!.name}',
          widget.player2!.themeColor,
        );
      } else {
        await _runAllBotsTurn();
        if (!battleOver && mounted) {
          setState(() {
            roundNumber++;
            currentTurn = p1State.hp > 0
                ? ActiveTurnEntity.player1
                : ActiveTurnEntity.player2;
            _resetTurnFlagsForActiveHero();
          });
          if (currentTurn == ActiveTurnEntity.player1) {
            _announceTurn(
              'TURNO DO JOGADOR 1 • ${widget.player1.name}',
              widget.player1.themeColor,
            );
          } else {
            _announceTurn(
              'TURNO DO JOGADOR 2 • ${widget.player2!.name}',
              widget.player2!.themeColor,
            );
          }
        }
      }
    }
  }

  // ==========================================
  // INTELIGÊNCIA ARTIFICIAL DOS BOTS (ANDAM + USAM HABILIDADES + DIFICULDADE)
  // ==========================================
  Future<void> _runAllBotsTurn() async {
    if (battleOver) return;

    for (int i = 0; i < bots.length; i++) {
      final bot = bots[i];
      if (bot.currentHp <= 0 || battleOver || !mounted) continue;

      setState(() {
        currentTurn = ActiveTurnEntity.enemy;
        activeBotIndex = i;
      });
      _announceTurn('TURNO DE ${bot.name.toUpperCase()}', Colors.redAccent);
      await Future.delayed(const Duration(milliseconds: 550));
      if (!mounted || battleOver) return;

      // 1. Escolha inteligente de alvo conforme dificuldade
      int targetPlayerIndex = 1;
      HeroBattleState targetState = p1State;
      CharacterData targetHero = widget.player1;

      if (_hasPlayer2 && p2State != null && p2State!.hp > 0) {
        if (p1State.hp <= 0) {
          targetPlayerIndex = 2;
          targetState = p2State!;
          targetHero = widget.player2!;
        } else if (widget.botDifficulty == BotDifficulty.hard) {
          // No Difícil, foca quem tem menos PV
          if (p2State!.hp < p1State.hp) {
            targetPlayerIndex = 2;
            targetState = p2State!;
            targetHero = widget.player2!;
          }
        } else {
          // No Fácil/Médio, foca o mais próximo
          final double d1 =
              _distanceMeters(bot.row, bot.col, p1State.row, p1State.col);
          final double d2 =
              _distanceMeters(bot.row, bot.col, p2State!.row, p2State!.col);
          if (d2 < d1) {
            targetPlayerIndex = 2;
            targetState = p2State!;
            targetHero = widget.player2!;
          }
        }
      }

      // 2. Verifica se o bot vai usar Buff próprio (Médio/Difícil)
      final double useAbilityChance = widget.botDifficulty == BotDifficulty.easy
          ? 0.25
          : (widget.botDifficulty == BotDifficulty.medium ? 0.65 : 0.95);

      for (final ab in bot.abilities) {
        if (ab.isSelfBuff &&
            ab.usesLeft > 0 &&
            _rng.nextDouble() < useAbilityChance) {
          setState(() {
            ab.usesLeft--;
            bot.ac += ab.flatBonus;
            _addLog(
              '[Habilidade Bot] ${bot.name} usou ${ab.name} (+${ab.flatBonus} CA)!',
              Colors.orangeAccent,
            );
          });
          await Future.delayed(const Duration(milliseconds: 350));
          break;
        }
      }

      // 3. Verifica se o bot tem uma habilidade ofensiva pronta e em alcance
      BotAbilitySpec? chosenOffensiveAbility;
      if (_rng.nextDouble() < useAbilityChance) {
        for (final ab in bot.abilities) {
          if (!ab.isSelfBuff && ab.usesLeft > 0) {
            chosenOffensiveAbility = ab;
            break;
          }
        }
      }

      final double desiredRange =
          chosenOffensiveAbility != null ? chosenOffensiveAbility.rangeMeters : 1.5;

      // 4. Movimentação inteligente do Bot pelo Grid
      int stepsAllowed = (bot.speedMeters / tileMeters).round();
      double movedMeters = 0;

      while (stepsAllowed > 0 &&
          _distanceMeters(targetState.row, targetState.col, bot.row, bot.col) >
              desiredRange) {
        int bestR = bot.row;
        int bestC = bot.col;
        double bestDist =
            _distanceMeters(targetState.row, targetState.col, bot.row, bot.col);

        for (int dr = -1; dr <= 1; dr++) {
          for (int dc = -1; dc <= 1; dc++) {
            if (dr == 0 && dc == 0) continue;
            int nr = bot.row + dr;
            int nc = bot.col + dc;
            if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) continue;
            if (_isObstacle(nr, nc) || _isTileOccupied(nr, nc)) continue;

            double d =
                _distanceMeters(targetState.row, targetState.col, nr, nc);
            if (d < bestDist) {
              bestDist = d;
              bestR = nr;
              bestC = nc;
            }
          }
        }

        if (bestR == bot.row && bestC == bot.col) break;
        setState(() {
          bot.row = bestR;
          bot.col = bestC;
        });
        stepsAllowed--;
        movedMeters += tileMeters;
        await Future.delayed(const Duration(milliseconds: 120));
      }

      if (movedMeters > 0 && mounted) {
        setState(() {
          _addLog(
            '[Movimento Bot] ${bot.name} avançou ${movedMeters.toStringAsFixed(1)}m.',
            Colors.red.shade200,
          );
        });
      }

      final double currentDist =
          _distanceMeters(targetState.row, targetState.col, bot.row, bot.col);

      // 5. Executa Habilidade Própria com Teste de Resistência animado OU Ataque Corpo a Corpo
      if (chosenOffensiveAbility != null &&
          currentDist <= chosenOffensiveAbility.rangeMeters &&
          mounted) {
        final ab = chosenOffensiveAbility;
        ab.usesLeft--;
        final int targetSaveMod = _getStatModifier(targetHero, ab.saveStat);

        final SavingThrowOutcome? saveOutcome =
            await showDialog<SavingThrowOutcome>(
          context: context,
          barrierDismissible: false,
          builder: (context) => SavingThrowModal(
            casterName: bot.name,
            targetName: 'P$targetPlayerIndex ${targetHero.name}',
            spellName: ab.name,
            saveStat: ab.saveStat,
            spellSaveDc: ab.saveDc,
            targetSaveMod: targetSaveMod,
            diceCount: ab.diceCount,
            diceSides: ab.diceSides,
            flatBonus: ab.flatBonus,
            halfOnSave: ab.halfOnSave,
            accentColor: Colors.redAccent,
            isBotAttacking: true,
          ),
        );

        if (saveOutcome != null && mounted) {
          setState(() {
            if (saveOutcome.finalDamage > 0) {
              targetState.takeDamage(saveOutcome.finalDamage);
              if (targetPlayerIndex == 1) {
                _p1ShakeController.forward(from: 0.0);
              } else {
                _p2ShakeController.forward(from: 0.0);
              }
            }
            _addLog(
              '[Habilidade Bot] ${bot.name} usou ${ab.name} em P$targetPlayerIndex (${targetHero.name})! '
              'Resist. ${ab.saveStat}: ${saveOutcome.totalSave} vs CD ${ab.saveDc} → ${saveOutcome.finalDamage} dano!',
              Colors.redAccent,
            );
            _checkHeroesDefeated();
          });
        }
      } else if (currentDist <= 1.5 && mounted) {
        await Future.delayed(const Duration(milliseconds: 220));
        if (!mounted) return;
        final int effectiveAc = targetHero.ac + targetState.acBonus;

        final DiceRollOutcome? enemyOutcome = await showDialog<DiceRollOutcome>(
          context: context,
          barrierDismissible: false,
          builder: (context) => DiceCombatModal(
            isPlayerRolling: false,
            attackerName: bot.name,
            defenderName: 'P$targetPlayerIndex ${targetHero.name}',
            targetAc: effectiveAc,
            attackName: bot.weaponName,
            attackBonus: bot.attackBonus,
            diceCount: bot.diceCount,
            diceSides: bot.diceSides,
            bonusDamage: bot.bonusDamage,
            accentColor: Colors.redAccent,
          ),
        );

        if (enemyOutcome != null && mounted) {
          setState(() {
            if (enemyOutcome.hit) {
              int finalDmg = enemyOutcome.totalDamage;
              String extraNote = '';
              if (targetHero.name == 'ARES' && finalDmg > 1) {
                finalDmg = finalDmg ~/ 2;
                extraNote = ' [Esquiva Sobrenatural: dano reduzido à metade!]';
              }
              targetState.takeDamage(finalDmg);
              // 👇 ADICIONE ISTO LOGO APÓS O takeDamage:
setState(() {
  floatingTexts.add(ActiveFloatingText(
    row: targetPlayerIndex == 1 ? p1State.row.toDouble() : p2State!.row.toDouble(),
    col: targetPlayerIndex == 1 ? p1State.col.toDouble() : p2State!.col.toDouble(),
    text: '-$finalDmg PV',
    color: Colors.redAccent,
  ));
});
Future.delayed(const Duration(milliseconds: 800), () {
  if (mounted) setState(() => floatingTexts.removeAt(0));
});
              if (targetPlayerIndex == 1) {
                _p1ShakeController.forward(from: 0.0);
              } else {
                _p2ShakeController.forward(from: 0.0);
              }
              _addLog(
                '${bot.name} acertou P$targetPlayerIndex (${targetHero.name}): '
                '1d20(${enemyOutcome.d20})+${bot.attackBonus} = ${enemyOutcome.totalAttack} vs CA $effectiveAc. '
                'Dano: $finalDmg!$extraNote',
                Colors.redAccent,
              );
              _checkHeroesDefeated();
            } else {
              _addLog(
                '${bot.name} ERROU P$targetPlayerIndex (${targetHero.name})! '
                '(1d20(${enemyOutcome.d20})+${bot.attackBonus} = ${enemyOutcome.totalAttack} vs CA $effectiveAc).',
                Colors.lightBlueAccent,
              );
            }
          });
        }
      } else if (mounted) {
        setState(() {
          _addLog(
            '${bot.name} reposicionou-se na arena.',
            Colors.white54,
          );
        });
      }
    }
  }

  void _checkHeroesDefeated() {
    final bool allHeroesDown =
        p1State.hp == 0 && (!_hasPlayer2 || p2State!.hp == 0);
    if (allHeroesDown) {
      battleOver = true;
      _addLog('DERROTA! Os heróis caíram em combate!', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canMelee = _hasTargetInMeleeRange();
    String modeLabel = '1P (${widget.botDifficulty.name.toUpperCase()})';
    if (widget.mode == GameMode.twoPlayersCoop) {
      modeLabel = '2P CO-OP (${widget.botDifficulty.name.toUpperCase()})';
    }
    if (widget.mode == GameMode.twoPlayersPvp) modeLabel = '2P DUELO PVP';

    Color bannerColor = widget.player1.themeColor;
    String turnBannerText =
        'TURNO DO JOGADOR 1 (${widget.player1.name}) • RODADA $roundNumber';
    IconData bannerIcon = Icons.looks_one;

    if (currentTurn == ActiveTurnEntity.player2) {
      bannerColor = widget.player2!.themeColor;
      turnBannerText =
          'TURNO DO JOGADOR 2 (${widget.player2!.name}) • RODADA $roundNumber';
      bannerIcon = Icons.looks_two;
    } else if (currentTurn == ActiveTurnEntity.enemy && bots.isNotEmpty) {
      final activeBot = bots[activeBotIndex.clamp(0, bots.length - 1)];
      bannerColor = Colors.redAccent;
      turnBannerText =
          'TURNO DO BOT (${activeBot.name}) • RODADA $roundNumber';
      bannerIcon = Icons.smart_toy;
    }

    final double activeMaxMove = _activeHero.speedMeters +
        (_isHumanTurn ? _activeState.extraMoveThisTurn : 0.0);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF140D0B),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
        title: Row(
          children: [
            Text(
              'ARENA D&D 5E • $modeLabel • $_currentMapName',
              style: const TextStyle(
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => setState(() => _setupBattle()),
              icon: const Icon(Icons.shuffle, color: Color(0xFFD4AF37), size: 18),
              label: const Text(
                'Novo Mapa / Reiniciar',
                style: TextStyle(color: Color(0xFFD4AF37)),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.3,
            colors: [Color(0xFF261A16), Color(0xFF0F0908)],
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                // Barra superior de turno e economia de ação
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: currentTurn == ActiveTurnEntity.enemy
                        ? const Color(0xFF2D1414)
                        : const Color(0xFF1A241E),
                    border: Border(
                      bottom: BorderSide(color: bannerColor, width: 2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: bannerColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(bannerIcon,
                                color: const Color(0xFF1A110E), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              turnBannerText,
                              style: const TextStyle(
                                color: Color(0xFF1A110E),
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                fontFamily: 'sans-serif',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (_isHumanTurn && !battleOver) ...[
                        _economyPill(
                          label: '1 AÇÃO',
                          available: actionAvailable,
                          activeColor: Colors.amberAccent,
                        ),
                        const SizedBox(width: 8),
                        _economyPill(
                          label:
                              '1 AÇÃO BÔNUS (Mover ${activeMaxMove.toStringAsFixed(0)}m / Magia)',
                          available: bonusActionAvailable,
                          activeColor: _activeHero.themeColor,
                        ),
                      ],
                      const Spacer(),
                      if (!battleOver)
                        ElevatedButton.icon(
                          onPressed: (_isHumanTurn && !_isAutoPassing)
                              ? _passCurrentTurn
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B0000),
                            foregroundColor: const Color(0xFFF5E6C8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(
                                  color: Color(0xFFD4AF37), width: 1.5),
                            ),
                          ),
                          icon: const Icon(Icons.skip_next_rounded, size: 20),
                          label: Text(
                            _isAutoPassing
                                ? 'PASSANDO...'
                                : (_isHumanTurn ? 'PASSAR TURNO' : 'AGUARDE...'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () => setState(() => _setupBattle()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            foregroundColor: const Color(0xFF1A110E),
                          ),
                          icon: const Icon(Icons.replay, size: 18),
                          label: const Text('NOVO MAPA E BATALHA',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),

                // Cards de status dos combatentes (Heróis + Todos os Bots)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  color: Colors.black.withOpacity(0.45),
                  child: Row(
                    children: [
                      Expanded(
                        child: _combatantStatusCard(
                          title: 'P1 • ${widget.player1.name}',
                          currentHp: p1State.hp,
                          maxHp: p1State.maxHp,
                          tempHp: p1State.tempHp,
                          ac: widget.player1.ac + p1State.acBonus,
                          currentPm: p1State.spellPoints,
                          maxPm: p1State.maxSpellPoints,
                          subtitle: widget.player1.modsSummary,
                          accentColor: widget.player1.themeColor,
                          emoji: widget.player1.decoEmoji,
                          isActiveTurn:
                              currentTurn == ActiveTurnEntity.player1,
                        ),
                      ),
                      if (_hasPlayer2 && p2State != null) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: _combatantStatusCard(
                            title: 'P2 • ${widget.player2!.name}',
                            currentHp: p2State!.hp,
                            maxHp: p2State!.maxHp,
                            tempHp: p2State!.tempHp,
                            ac: widget.player2!.ac + p2State!.acBonus,
                            currentPm: p2State!.spellPoints,
                            maxPm: p2State!.maxSpellPoints,
                            subtitle: widget.player2!.modsSummary,
                            accentColor: widget.player2!.themeColor,
                            emoji: widget.player2!.decoEmoji,
                            isActiveTurn:
                                currentTurn == ActiveTurnEntity.player2,
                          ),
                        ),
                      ],
                      if (_hasBots)
                        for (int i = 0; i < bots.length; i++) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: bots[i].currentHp > 0
                                  ? () => setState(
                                      () => selectedTargetBotIndex = i)
                                  : null,
                              child: _combatantStatusCard(
                                title:
                                    '${selectedTargetBotIndex == i && bots[i].currentHp > 0 ? "🎯 " : ""}${bots[i].name}',
                                currentHp: bots[i].currentHp,
                                maxHp: bots[i].maxHp,
                                tempHp: 0,
                                ac: bots[i].ac,
                                currentPm: 0,
                                maxPm: 0,
                                subtitle:
                                    'Hab: ${bots[i].abilities.map((a) => a.name).join(", ")}',
                                accentColor: selectedTargetBotIndex == i
                                    ? Colors.orangeAccent
                                    : Colors.redAccent,
                                emoji: bots[i].emoji,
                                isActiveTurn:
                                    currentTurn == ActiveTurnEntity.enemy &&
                                        activeBotIndex == i,
                              ),
                            ),
                          ),
                        ],
                    ],
                  ),
                ),

                // Grid central + Crônica do Combate
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 7,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: AspectRatio(
                              aspectRatio: cols / rows,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1916),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFD4AF37),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.85),
                                      blurRadius: 24,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(9),
                                  child: Column(
                                    children: List.generate(rows, (r) {
                                      return Expanded(
                                        child: Row(
                                          children: List.generate(cols, (c) {
                                            return Expanded(
                                              child: _buildGridTile(r, c),
                                            );
                                          }),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(0, 12, 16, 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFD4AF37).withOpacity(0.4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.history_edu,
                                      color: Color(0xFFD4AF37), size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'CRÔNICA DO COMBATE',
                                    style: TextStyle(
                                      color: Color(0xFFD4AF37),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.white24),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: combatLog.length,
                                  itemBuilder: (context, index) {
                                    final entry = combatLog[index];
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8.0),
                                      child: Text(
                                        entry.text,
                                        style: TextStyle(
                                          color: entry.color,
                                          fontSize: 12,
                                          fontFamily: 'sans-serif',
                                          height: 1.35,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Barra inferior de Ataques, Magias e Habilidades (Com rolagem + setas visuais)
                Container(
                  height: 184,
                  decoration: BoxDecoration(
                    color: const Color(0xFF140D0B),
                    border: Border(
                      top: BorderSide(
                        color: const Color(0xFFD4AF37).withOpacity(0.6),
                        width: 2,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        color: Colors.black.withOpacity(0.4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 6),
                        child: Row(
                          children: [
                            _menuTabButton(
                              index: 0,
                              icon: Icons.sports_martial_arts,
                              label:
                                  'Ataques (${_activeHero.attacks.length})',
                              accentColor: _activeHero.themeColor,
                            ),
                            const SizedBox(width: 12),
                            _menuTabButton(
                              index: 1,
                              icon: Icons.auto_fix_high,
                              label: _activeHero.maxSpellPoints > 0
                                  ? 'Magias (${_activeHero.spells.length}) • ${_activeState.spellPoints}/${_activeState.maxSpellPoints} PM'
                                  : 'Magias (0)',
                              accentColor: Colors.cyanAccent,
                            ),
                            const SizedBox(width: 12),
                            _menuTabButton(
                              index: 2,
                              icon: Icons.stars,
                              label:
                                  'Habilidades (${_activeHero.abilities.length})',
                              accentColor: Colors.amberAccent,
                            ),
                            const Spacer(),
                            Text(
                              canMelee
                                  ? '✅ Alvo corpo a corpo (1,5m)'
                                  : '📏 Distância do alvo: ${_distanceToPrimaryTarget(_activeState).toStringAsFixed(1)}m',
                              style: TextStyle(
                                color: canMelee
                                    ? Colors.lightGreenAccent
                                    : Colors.white60,
                                fontSize: 12,
                                fontFamily: 'sans-serif',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: 'Rolar para a esquerda',
                              onPressed: () {
                                if (_bottomCardsScrollController.hasClients) {
                                  _bottomCardsScrollController.animateTo(
                                    math.max(
                                        0,
                                        _bottomCardsScrollController.offset -
                                            290),
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeOut,
                                  );
                                }
                              },
                              icon: const Icon(Icons.chevron_left,
                                  color: Color(0xFFD4AF37), size: 28),
                            ),
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: _buildBottomTabContent(canMelee),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Rolar para a direita (ver todas)',
                              onPressed: () {
                                if (_bottomCardsScrollController.hasClients) {
                                  _bottomCardsScrollController.animateTo(
                                    math.min(
                                        _bottomCardsScrollController
                                            .position.maxScrollExtent,
                                        _bottomCardsScrollController.offset +
                                            290),
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeOut,
                                  );
                                }
                              },
                              icon: const Icon(Icons.chevron_right,
                                  color: Color(0xFFD4AF37), size: 28),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Anúncio central de turno
            if (_turnAnnouncementText != null && !battleOver)
              IgnorePointer(
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(_announcementTicket),
                    tween: Tween(begin: 0.75, end: 1.0),
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 34, vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF140D0B).withOpacity(0.92),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: _turnAnnouncementColor,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _turnAnnouncementColor.withOpacity(0.6),
                                blurRadius: 28,
                                spreadRadius: 4,
                              ),
                              const BoxShadow(
                                color: Colors.black,
                                blurRadius: 16,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_moon,
                                  color: _turnAnnouncementColor, size: 28),
                              const SizedBox(width: 12),
                              Text(
                                _turnAnnouncementText!,
                                style: TextStyle(
                                  color: _turnAnnouncementColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  fontFamily: 'Georgia',
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _economyPill({
    required String label,
    required bool available,
    required Color activeColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: available ? activeColor.withOpacity(0.18) : Colors.black45,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: available ? activeColor : Colors.white24,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            available ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: available ? activeColor : Colors.white38,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: available ? Colors.white : Colors.white38,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              fontFamily: 'sans-serif',
              decoration:
                  available ? TextDecoration.none : TextDecoration.lineThrough,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuTabButton({
    required int index,
    required IconData icon,
    required String label,
    required Color accentColor,
  }) {
    final bool isSelected = selectedMenuTab == index;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() => selectedMenuTab = index);
          if (_bottomCardsScrollController.hasClients) {
            _bottomCardsScrollController.jumpTo(0);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withOpacity(0.22)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? accentColor : Colors.white12,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 16, color: isSelected ? accentColor : Colors.white54),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12.5,
                  fontFamily: 'sans-serif',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomTabContent(bool canMelee) {
    final hero = _activeHero;
    final state = _activeState;

    if (selectedMenuTab == 0) {
      return Scrollbar(
        controller: _bottomCardsScrollController,
        thumbVisibility: true,
        child: ListView.separated(
          controller: _bottomCardsScrollController,
          scrollDirection: Axis.horizontal,
          itemCount: hero.attacks.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final atk = hero.attacks[index];
            final bool enabled = _isHumanTurn &&
                !battleOver &&
                !_isAutoPassing &&
                actionAvailable &&
                canMelee;
            return WeaponAttackCard(
              attack: atk,
              themeColor: hero.themeColor,
              enabled: enabled,
              statusHint: !_isHumanTurn
                  ? 'Turno do inimigo'
                  : !actionAvailable
                      ? 'Ação já gasta'
                      : !canMelee
                          ? 'Aproxime-se (1,5m)'
                          : 'Clique para rolar D20',
              onTap: () => _openHumanAttackModal(atk),
            );
          },
        ),
      );
    }

    if (selectedMenuTab == 1) {
      if (hero.spells.isEmpty) {
        return Center(
          child: Text(
            '🐉 ${hero.name} é Ladino comum (0 PM) — veja suas 6 manobras na aba Habilidades!',
            style: const TextStyle(
              color: Colors.white60,
              fontStyle: FontStyle.italic,
              fontSize: 14,
            ),
          ),
        );
      }
      return Scrollbar(
        controller: _bottomCardsScrollController,
        thumbVisibility: true,
        child: ListView.separated(
          controller: _bottomCardsScrollController,
          scrollDirection: Axis.horizontal,
          itemCount: hero.spells.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final spell = hero.spells[index];
            final bool hasPm = state.spellPoints >= spell.pmCost;
            final bool hasEconomy = spell.costType == ActionCostType.action
                ? actionAvailable
                : bonusActionAvailable;
            final bool inRange = spell.targetType != TargetType.enemySingle ||
                _distanceToPrimaryTarget(state) <= spell.rangeMeters;
            final bool enabled = _isHumanTurn &&
                !battleOver &&
                !_isAutoPassing &&
                hasPm &&
                hasEconomy &&
                inRange;

            String hint = 'Conjurar (${spell.pmCost} PM)';
            if (!hasPm) {
              hint = 'Sem PM (${spell.pmCost} PM)';
            } else if (!hasEconomy) {
              hint = spell.costType == ActionCostType.action
                  ? 'Ação já gasta'
                  : 'Ação Bônus gasta';
            } else if (!inRange) {
              hint = 'Fora de alcance (${spell.rangeMeters.toStringAsFixed(0)}m)';
            }

            return SpellCardWidget(
              spell: spell,
              enabled: enabled,
              statusHint: hint,
              onTap: () => _castSpell(spell),
            );
          },
        ),
      );
    }

    return Scrollbar(
      controller: _bottomCardsScrollController,
      thumbVisibility: true,
      child: ListView.separated(
        controller: _bottomCardsScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: hero.abilities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final ability = hero.abilities[index];
          final int usesLeft = state.remainingUses[ability.id] ?? 0;
          bool enabled = _isHumanTurn && !battleOver && !_isAutoPassing;
          String hint = 'Ativar Habilidade';

          if (ability.costType == ActionCostType.freePassive) {
            enabled = true;
            hint = 'Passiva Ativa';
          } else if (usesLeft <= 0) {
            enabled = false;
            hint = 'Sem usos';
          } else if (ability.costType == ActionCostType.action &&
              !actionAvailable) {
            enabled = false;
            hint = 'Ação já gasta';
          } else if (ability.costType == ActionCostType.bonusAction &&
              !bonusActionAvailable) {
            enabled = false;
            hint = 'Ação Bônus gasta';
          }

          return AbilityCardWidget(
            ability: ability,
            usesLeft: usesLeft,
            themeColor: hero.themeColor,
            enabled: enabled,
            statusHint: hint,
            onTap: () => _useClassAbility(ability),
          );
        },
      ),
    );
  }

  Widget _combatantStatusCard({
  required String title,
  required int currentHp,
  required int maxHp,
  required int tempHp,
  required int ac,
  required int currentPm,
  required int maxPm,
  required String subtitle,
  required Color accentColor,
  required String emoji,
  required bool isActiveTurn,
}) {
  final double hpRatio = maxHp > 0 ? (currentHp / maxHp).clamp(0.0, 1.0) : 0;
  return AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: isActiveTurn
          ? Color.alphaBlend(accentColor.withOpacity(0.22), const Color(0xFF1C1411))
          : const Color(0xFF1C1411),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isActiveTurn ? accentColor : accentColor.withOpacity(0.45),
        width: isActiveTurn ? 2.5 : 1.2,
      ),
      boxShadow: [
        if (isActiveTurn)
          BoxShadow(
            color: accentColor.withOpacity(0.4),
            blurRadius: 14,
            spreadRadius: 2,
          ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            if (maxPm > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.cyanAccent),
                ),
                child: Text(
                  '$currentPm/$maxPm PM',
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    fontFamily: 'sans-serif',
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber),
              ),
              child: Text(
                'CA $ac',
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  fontFamily: 'sans-serif',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: hpRatio,
                  minHeight: 8,
                  backgroundColor: Colors.black54,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    hpRatio > 0.4 ? Colors.greenAccent : Colors.redAccent,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              tempHp > 0 ? '$currentHp/$maxHp (+$tempHp)' : '$currentHp/$maxHp',
              style: TextStyle(
                color: tempHp > 0 ? Colors.lightGreenAccent : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                fontFamily: 'sans-serif',
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 9.5,
            fontFamily: 'sans-serif',
          ),
        ),
      ],
    ),
  );
}

  Widget _buildGridTile(int r, int c) {
    final bool isP1 = (p1State.hp > 0 && r == p1State.row && c == p1State.col);
    final bool isP2 = (_hasPlayer2 &&
        p2State != null &&
        p2State!.hp > 0 &&
        r == p2State!.row &&
        c == p2State!.col);

    ArenaBot? botHere;
    int botIndexHere = -1;
    if (_hasBots) {
      for (int i = 0; i < bots.length; i++) {
        if (bots[i].currentHp > 0 && bots[i].row == r && bots[i].col == c) {
          botHere = bots[i];
          botIndexHere = i;
          break;
        }
      }
    }

    final bool isWall = _isObstacle(r, c);
    final HeroBattleState state = _activeState;
    final CharacterData activeHero = _activeHero;
    final double allowedMove =
        activeHero.speedMeters + state.extraMoveThisTurn;
    final double distMeters = _distanceMeters(state.row, state.col, r, c);

    final bool canWalkHere = _isHumanTurn &&
        !battleOver &&
        !_isAutoPassing &&
        !hasMovedThisTurn &&
        (bonusActionAvailable || state.extraMoveThisTurn > 0) &&
        !isWall &&
        !_isTileOccupied(r, c) &&
        distMeters <= allowedMove;

    final bool isEvenTile = (r + c) % 2 == 0;
    Color tileColor =
        isEvenTile ? const Color(0xFF2C2520) : const Color(0xFF251F1B);
    if (isWall) {
      tileColor = const Color(0xFF4E342E);
    } else if (canWalkHere) {
      tileColor = Color.alphaBlend(
          activeHero.themeColor.withOpacity(0.28), tileColor);
    }

    return MouseRegion(
      cursor: isWall
          ? SystemMouseCursors.forbidden
          : (canWalkHere || botHere != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic),
      child: GestureDetector(
        onTap: () => _handleTileTap(r, c),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            color: tileColor,
            border: Border.all(
              color: canWalkHere
                  ? activeHero.themeColor.withOpacity(0.8)
                  : Colors.white.withOpacity(0.08),
              width: canWalkHere ? 1.8 : 0.6,
            ),
            boxShadow: canWalkHere
                ? [
                    BoxShadow(
                      color: activeHero.themeColor.withOpacity(0.25),
                      blurRadius: 4,
                    )
                  ]
                : null,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (canWalkHere)
                Positioned(
                  bottom: 2,
                  right: 3,
                  child: Text(
                    '${distMeters.toStringAsFixed(1)}m',
                    style: TextStyle(
                      fontSize: 8.5,
                      color: activeHero.themeColor,
                      fontFamily: 'sans-serif',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              if (isWall)
                Center(
                  child: Icon(
                    Icons.account_balance,
                    color: Colors.brown.shade200.withOpacity(0.55),
                    size: 24,
                  ),
                ),
              if (isP1)
                _buildHeroToken(
                  hero: widget.player1,
                  shakeController: _p1ShakeController,
                  badge: 'P1',
                  isActive: currentTurn == ActiveTurnEntity.player1,
                ),
              if (isP2)
                _buildHeroToken(
                  hero: widget.player2!,
                  shakeController: _p2ShakeController,
                  badge: 'P2',
                  isActive: currentTurn == ActiveTurnEntity.player2,
                ),
              if (botHere != null)
                AnimatedBuilder(
                  animation: botHere.shakeController,
                  builder: (context, child) {
                    final double progress = botHere!.shakeController.value;
                    final double dx = progress > 0 && progress < 1
                        ? math.sin(progress * math.pi * 8) * 7
                        : 0;
                    final bool isTakingDamage = progress > 0 && progress < 1;
                    final bool isSelectedTarget =
                        selectedTargetBotIndex == botIndexHere;
                    return Transform.translate(
                      offset: Offset(dx, 0),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isTakingDamage
                                ? Colors.redAccent
                                : Colors.red.shade900,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelectedTarget
                                  ? Colors.amberAccent
                                  : (isTakingDamage
                                      ? Colors.white
                                      : Colors.redAccent),
                              width: isSelectedTarget ? 3.2 : 2.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isSelectedTarget
                                        ? Colors.amberAccent
                                        : Colors.red)
                                    .withOpacity(0.75),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              botHere.emoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  

  Widget _buildHeroToken({
    required CharacterData hero,
    required AnimationController shakeController,
    required String badge,
    required bool isActive,
  }) {
    return AnimatedBuilder(
      animation: shakeController,
      builder: (context, child) {
        final double progress = shakeController.value;
        final double dx = progress > 0 && progress < 1
            ? math.sin(progress * math.pi * 8) * 7
            : 0;
        final bool isTakingDamage = progress > 0 && progress < 1;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isTakingDamage
                          ? Colors.redAccent
                          : (isActive ? Colors.white : hero.themeColor),
                      width: isActive ? 3.2 : 2.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isTakingDamage ? Colors.red : hero.themeColor)
                            .withOpacity(isActive ? 0.95 : 0.6),
                        blurRadius: isActive ? 14 : 8,
                        spreadRadius: isActive ? 2 : 0,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: ColorFiltered(
                      colorFilter: isTakingDamage
                          ? ColorFilter.mode(
                              Colors.red.withOpacity(0.45), BlendMode.srcATop)
                          : const ColorFilter.mode(
                              Colors.transparent, BlendMode.dst),
                      child: Image.asset(
                        hero.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(hero.decoEmoji),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_hasPlayer2)
                Positioned(
                  top: 1,
                  left: 1,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A110E),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: hero.themeColor, width: 1),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: hero.themeColor,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'sans-serif',
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// CARDS DA BARRA INFERIOR DO MODO ARENA
// ==========================================
class WeaponAttackCard extends StatefulWidget {
  final MeleeAttack attack;
  final Color themeColor;
  final bool enabled;
  final String statusHint;
  final VoidCallback onTap;

  const WeaponAttackCard({
    super.key,
    required this.attack,
    required this.themeColor,
    required this.enabled,
    required this.statusHint,
    required this.onTap,
  });

  @override
  State<WeaponAttackCard> createState() => _WeaponAttackCardState();
}

class _WeaponAttackCardState extends State<WeaponAttackCard> {
  bool _hover = false;
  String _fmtMod(int m) => m >= 0 ? '+$m' : '$m';

  @override
  Widget build(BuildContext context) {
    final atk = widget.attack;
    final bool active = widget.enabled;
    return PulsingGlowWrapper(
      active: active,
      glowColor: widget.themeColor,
      child: MouseRegion(
        cursor: active ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: active ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 260,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: active
                    ? [
                        const Color(0xFF2B1E19),
                        Color.alphaBlend(
                            widget.themeColor.withOpacity(_hover ? 0.28 : 0.14),
                            const Color(0xFF1A120F))
                      ]
                    : [const Color(0xFF1C1715), const Color(0xFF14100E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active
                    ? (_hover ? Colors.white : widget.themeColor)
                    : Colors.white12,
                width: active ? 2.0 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(atk.icon,
                        size: 18,
                        color: active ? widget.themeColor : Colors.white38),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        atk.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: active ? Colors.white : Colors.white54,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: active
                              ? widget.themeColor.withOpacity(0.6)
                              : Colors.white12,
                        ),
                      ),
                      child: Text(
                        '${atk.diceCount}d${atk.diceSides}${_fmtMod(atk.damageMod)}',
                        style: TextStyle(
                          color: active ? widget.themeColor : Colors.white38,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          fontFamily: 'sans-serif',
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  atk.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? Colors.white70 : Colors.white30,
                    fontSize: 10.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '1d20${_fmtMod(atk.attackMod)} (${atk.statLabel})',
                      style: TextStyle(
                        color: active ? Colors.amberAccent : Colors.white30,
                        fontSize: 10.5,
                        fontFamily: 'sans-serif',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.statusHint,
                      style: TextStyle(
                        color: active ? widget.themeColor : Colors.white38,
                        fontSize: 10.5,
                        fontFamily: 'sans-serif',
                        fontWeight: FontWeight.bold,
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
}

class SpellCardWidget extends StatefulWidget {
  final SpellItem spell;
  final bool enabled;
  final String statusHint;
  final VoidCallback onTap;

  const SpellCardWidget({
    super.key,
    required this.spell,
    required this.enabled,
    required this.statusHint,
    required this.onTap,
  });

  @override
  State<SpellCardWidget> createState() => _SpellCardWidgetState();
}

class _SpellCardWidgetState extends State<SpellCardWidget> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.spell;
    final bool active = widget.enabled;
    const Color spellColor = Colors.cyanAccent;
    return MouseRegion(
      cursor: active ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: active ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 270,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: active
                  ? [
                      const Color(0xFF13262E),
                      Color.alphaBlend(
                          spellColor.withOpacity(_hover ? 0.25 : 0.12),
                          const Color(0xFF10181D))
                    ]
                  : [const Color(0xFF1C1715), const Color(0xFF14100E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active
                  ? (_hover ? Colors.white : spellColor)
                  : Colors.white12,
              width: active ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(s.icon,
                      size: 18, color: active ? spellColor : Colors.white38),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: active ? Colors.white : Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: active
                            ? spellColor.withOpacity(0.7)
                            : Colors.white12,
                      ),
                    ),
                    child: Text(
                      s.pmCost == 0 ? 'TRUQUE (0 PM)' : '${s.pmCost} PM',
                      style: TextStyle(
                        color: active ? spellColor : Colors.white38,
                        fontWeight: FontWeight.w900,
                        fontSize: 10.5,
                        fontFamily: 'sans-serif',
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                s.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? Colors.white70 : Colors.white30,
                  fontSize: 10.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.costType == ActionCostType.bonusAction
                        ? 'Ação Bônus • ${s.rangeMeters > 0 ? "${s.rangeMeters.toStringAsFixed(0)}m" : "Pessoal"}'
                        : 'Ação • ${s.rangeMeters.toStringAsFixed(0)}m',
                    style: TextStyle(
                      color: active ? Colors.amberAccent : Colors.white30,
                      fontSize: 10.5,
                      fontFamily: 'sans-serif',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.statusHint,
                    style: TextStyle(
                      color: active ? spellColor : Colors.white38,
                      fontSize: 10.5,
                      fontFamily: 'sans-serif',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AbilityCardWidget extends StatefulWidget {
  final ClassAbilityItem ability;
  final int usesLeft;
  final Color themeColor;
  final bool enabled;
  final String statusHint;
  final VoidCallback onTap;

  const AbilityCardWidget({
    super.key,
    required this.ability,
    required this.usesLeft,
    required this.themeColor,
    required this.enabled,
    required this.statusHint,
    required this.onTap,
  });

  @override
  State<AbilityCardWidget> createState() => _AbilityCardWidgetState();
}

class _AbilityCardWidgetState extends State<AbilityCardWidget> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final ab = widget.ability;
    final bool active = widget.enabled;
    const Color abColor = Colors.amberAccent;
    String costLabel = 'Ação';
    if (ab.costType == ActionCostType.bonusAction) costLabel = 'Ação Bônus';
    if (ab.costType == ActionCostType.freePassive) costLabel = 'Passiva';

    return MouseRegion(
      cursor: active ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: active ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 270,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: active
                  ? [
                      const Color(0xFF2B2214),
                      Color.alphaBlend(
                          abColor.withOpacity(_hover ? 0.24 : 0.12),
                          const Color(0xFF1A140D))
                    ]
                  : [const Color(0xFF1C1715), const Color(0xFF14100E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  active ? (_hover ? Colors.white : abColor) : Colors.white12,
              width: active ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(ab.icon,
                      size: 18, color: active ? abColor : Colors.white38),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ab.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: active ? Colors.white : Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (ab.maxUses < 90)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: active
                              ? abColor.withOpacity(0.7)
                              : Colors.white12,
                        ),
                      ),
                      child: Text(
                        '${widget.usesLeft}/${ab.maxUses}',
                        style: TextStyle(
                          color: active ? abColor : Colors.white38,
                          fontWeight: FontWeight.w900,
                          fontSize: 10.5,
                          fontFamily: 'sans-serif',
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                ab.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? Colors.white70 : Colors.white30,
                  fontSize: 10.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    costLabel,
                    style: TextStyle(
                      color: active ? widget.themeColor : Colors.white30,
                      fontSize: 10.5,
                      fontFamily: 'sans-serif',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.statusHint,
                    style: TextStyle(
                      color: active ? abColor : Colors.white38,
                      fontSize: 10.5,
                      fontFamily: 'sans-serif',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// NOVO MODAL: ANIMAÇÃO DE TESTE DE RESISTÊNCIA (SAVING THROW)
// ==========================================
class SavingThrowOutcome {
  final int d20;
  final int totalSave;
  final bool saved;
  final int rawDamage;
  final int finalDamage;

  SavingThrowOutcome({
    required this.d20,
    required this.totalSave,
    required this.saved,
    required this.rawDamage,
    required this.finalDamage,
  });
}

class SavingThrowModal extends StatefulWidget {
  final String casterName;
  final String targetName;
  final String spellName;
  final String saveStat;
  final int spellSaveDc;
  final int targetSaveMod;
  final int diceCount;
  final int diceSides;
  final int flatBonus;
  final bool halfOnSave;
  final Color accentColor;
  final bool isBotAttacking;

  const SavingThrowModal({
    super.key,
    required this.casterName,
    required this.targetName,
    required this.spellName,
    required this.saveStat,
    required this.spellSaveDc,
    required this.targetSaveMod,
    required this.diceCount,
    required this.diceSides,
    required this.flatBonus,
    required this.halfOnSave,
    required this.accentColor,
    this.isBotAttacking = false,
  });

  @override
  State<SavingThrowModal> createState() => _SavingThrowModalState();
}

class _SavingThrowModalState extends State<SavingThrowModal>
    with SingleTickerProviderStateMixin {
  final math.Random _rng = math.Random();
  late AnimationController _spinController;
  int _phase = 0; // 0: girando save, 1: resultado save, 2: dano calculado
  int _displayD20 = 10;
  int _finalD20 = 10;
  bool _saved = false;
  int _rawDamage = 0;
  int _finalDamage = 0;
  List<int> _damageDice = [];

  String _fmtMod(int m) => m >= 0 ? '+$m' : '$m';

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _startSavingThrowSequence();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _startSavingThrowSequence() async {
    _spinController.repeat();
    for (int i = 0; i < 14; i++) {
      await Future.delayed(const Duration(milliseconds: 60));
      if (!mounted) return;
      setState(() {
        _displayD20 = _rng.nextInt(20) + 1;
      });
    }
    _spinController.stop();

    final int rolled = _rng.nextInt(20) + 1;
    final int total = rolled + widget.targetSaveMod;
    final bool didSave = rolled == 20 || (rolled != 1 && total >= widget.spellSaveDc);

    setState(() {
      _finalD20 = rolled;
      _displayD20 = rolled;
      _saved = didSave;
      _phase = 1;
    });

    await Future.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;

    // Rola os dados de dano
    for (int i = 0; i < 8; i++) {
      await Future.delayed(const Duration(milliseconds: 55));
      if (!mounted) return;
      setState(() {
        _damageDice = List.generate(
            widget.diceCount, (_) => _rng.nextInt(widget.diceSides) + 1);
      });
    }

    final List<int> finalDice = List.generate(
        widget.diceCount, (_) => _rng.nextInt(widget.diceSides) + 1);
    final int raw =
        finalDice.fold(0, (a, b) => a + b) + widget.flatBonus;
    final int finalDmg =
        _saved ? (widget.halfOnSave ? (raw ~/ 2) : 0) : raw;

    setState(() {
      _damageDice = finalDice;
      _rawDamage = raw;
      _finalDamage = finalDmg;
      _phase = 2;
    });

    if (widget.isBotAttacking) {
      await Future.delayed(const Duration(milliseconds: 1100));
      if (mounted) {
        Navigator.of(context).pop(
          SavingThrowOutcome(
            d20: _finalD20,
            totalSave: total,
            saved: _saved,
            rawDamage: _rawDamage,
            finalDamage: _finalDamage,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _phase == 0
        ? Colors.amberAccent
        : (_saved ? Colors.lightGreenAccent : Colors.redAccent);

    return AlertDialog(
      backgroundColor: const Color(0xFF1D1411),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: widget.accentColor, width: 2.5),
      ),
      title: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, color: widget.accentColor, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'TESTE DE RESISTÊNCIA (${widget.saveStat})',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: widget.accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.casterName} conjurou ${widget.spellName} em ${widget.targetName}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontFamily: 'sans-serif',
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 390,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                'Classe de Dificuldade (CD): ${widget.spellSaveDc}',
                style: const TextStyle(
                  color: Colors.amberAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  fontFamily: 'sans-serif',
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Dado D20 animado girando para o Teste de Resistência
            RotationTransition(
              turns: _spinController,
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      statusColor.withOpacity(0.35),
                      const Color(0xFF120B09),
                    ],
                  ),
                  border: Border.all(color: statusColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.45),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$_displayD20',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Georgia',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _phase == 0
                  ? '${widget.targetName} está rolando ${widget.saveStat}...'
                  : '1d20 ($_finalD20) ${_fmtMod(widget.targetSaveMod)} = ${_finalD20 + widget.targetSaveMod} vs CD ${widget.spellSaveDc}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                fontFamily: 'sans-serif',
              ),
            ),
            if (_phase >= 1) ...[
              const SizedBox(height: 10),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.6, end: 1.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: (_saved
                                ? Colors.lightGreenAccent
                                : Colors.redAccent)
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _saved
                              ? Colors.lightGreenAccent
                              : Colors.redAccent,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        _saved
                            ? (widget.halfOnSave
                                ? 'PASSOU NA RESISTÊNCIA! (Metade do dano)'
                                : 'RESISTIU COMPLETAMENTE! (0 de dano)')
                            : 'FALHOU NA RESISTÊNCIA! (Dano total)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _saved
                              ? Colors.lightGreenAccent
                              : Colors.redAccent,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          fontFamily: 'sans-serif',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
            if (_damageDice.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              const SizedBox(height: 6),
              Text(
                'Dados de Dano (${widget.diceCount}d${widget.diceSides}${widget.flatBonus > 0 ? "+${widget.flatBonus}" : ""}):',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontFamily: 'sans-serif',
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _damageDice.map((val) {
                  return Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: widget.accentColor, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '$val',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          fontFamily: 'sans-serif',
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_phase == 2) ...[
                const SizedBox(height: 12),
                Text(
                  'Dano Final Aplicado: $_finalDamage PV',
                  style: TextStyle(
                    color: _finalDamage > 0
                        ? Colors.orangeAccent
                        : Colors.lightGreenAccent,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    fontFamily: 'sans-serif',
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        if (_phase == 2 && !widget.isBotAttacking)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(
                  SavingThrowOutcome(
                    d20: _finalD20,
                    totalSave: _finalD20 + widget.targetSaveMod,
                    saved: _saved,
                    rawDamage: _rawDamage,
                    finalDamage: _finalDamage,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: const Color(0xFF1A110E),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.check_circle),
              label: const Text(
                'APLICAR RESULTADO',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
      ],
    );
  }
}

// ==========================================
// MODAL DE ROLAGEM DE ATAQUE D20 (DICE COMBAT MODAL)
// ==========================================
class DiceRollOutcome {
  final int d20;
  final int totalAttack;
  final bool hit;
  final bool isCrit;
  final int totalDamage;

  DiceRollOutcome({
    required this.d20,
    required this.totalAttack,
    required this.hit,
    required this.isCrit,
    required this.totalDamage,
  });
}

class DiceCombatModal extends StatefulWidget {
  final bool isPlayerRolling;
  final String attackerName;
  final String defenderName;
  final int targetAc;
  final String attackName;
  final int attackBonus;
  final int diceCount;
  final int diceSides;
  final int bonusDamage;
  final int extraDiceCount;
  final int extraDiceSides;
  final Color accentColor;

  const DiceCombatModal({
    super.key,
    required this.isPlayerRolling,
    required this.attackerName,
    required this.defenderName,
    required this.targetAc,
    required this.attackName,
    required this.attackBonus,
    required this.diceCount,
    required this.diceSides,
    required this.bonusDamage,
    this.extraDiceCount = 0,
    this.extraDiceSides = 6,
    required this.accentColor,
  });

  @override
  State<DiceCombatModal> createState() => _DiceCombatModalState();
}

class _DiceCombatModalState extends State<DiceCombatModal>
    with SingleTickerProviderStateMixin {
  final math.Random _rng = math.Random();
  late AnimationController _spinController;
  int _phase = 0;
  int _displayD20 = 10;
  int _finalD20 = 10;
  bool _hit = false;
  bool _isCrit = false;
  int _totalDamage = 0;
  List<int> _rolledDice = [];

  String _fmtMod(int m) => m >= 0 ? '+$m' : '$m';

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _rollSequence();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _rollSequence() async {
    _spinController.repeat();
    for (int i = 0; i < 13; i++) {
      await Future.delayed(const Duration(milliseconds: 55));
      if (!mounted) return;
      setState(() {
        _displayD20 = _rng.nextInt(20) + 1;
      });
    }
    _spinController.stop();

    final int d20 = _rng.nextInt(20) + 1;
    final int totalAtk = d20 + widget.attackBonus;
    final bool crit = d20 == 20;
    final bool didHit = crit || (d20 != 1 && totalAtk >= widget.targetAc);

    setState(() {
      _finalD20 = d20;
      _displayD20 = d20;
      _isCrit = crit;
      _hit = didHit;
      _phase = 1;
    });

    if (didHit) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      final int mult = crit ? 2 : 1;
      final List<int> diceResults = [];
      for (int i = 0; i < widget.diceCount * mult; i++) {
        diceResults.add(_rng.nextInt(widget.diceSides) + 1);
      }
      for (int i = 0; i < widget.extraDiceCount * mult; i++) {
        diceResults.add(_rng.nextInt(widget.extraDiceSides) + 1);
      }

      final int dmgSum =
          diceResults.fold(0, (a, b) => a + b) + widget.bonusDamage;

      setState(() {
        _rolledDice = diceResults;
        _totalDamage = math.max(1, dmgSum);
        _phase = 2;
      });
    } else {
      setState(() {
        _totalDamage = 0;
        _phase = 2;
      });
    }

    if (!widget.isPlayerRolling) {
      await Future.delayed(const Duration(milliseconds: 1100));
      if (mounted) {
        Navigator.of(context).pop(
          DiceRollOutcome(
            d20: _finalD20,
            totalAttack: _finalD20 + widget.attackBonus,
            hit: _hit,
            isCrit: _isCrit,
            totalDamage: _totalDamage,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color resultColor = _phase == 0
        ? widget.accentColor
        : (_isCrit
            ? Colors.amberAccent
            : (_hit ? Colors.lightGreenAccent : Colors.redAccent));

    return AlertDialog(
      backgroundColor: const Color(0xFF1D1411),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: widget.accentColor, width: 2.5),
      ),
      title: Column(
        children: [
          Text(
            widget.attackName.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.accentColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.attackerName} ⚔️ ${widget.defenderName} (CA ${widget.targetAc})',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontFamily: 'sans-serif',
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 370,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: _spinController,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black54,
                  border: Border.all(color: resultColor, width: 3),
                ),
                child: Center(
                  child: Text(
                    '$_displayD20',
                    style: TextStyle(
                      color: resultColor,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _phase == 0
                  ? 'Rolando 1d20${_fmtMod(widget.attackBonus)}...'
                  : '1d20 ($_finalD20) ${_fmtMod(widget.attackBonus)} = ${_finalD20 + widget.attackBonus} vs CA ${widget.targetAc}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                fontFamily: 'sans-serif',
              ),
            ),
            if (_phase >= 1) ...[
              const SizedBox(height: 8),
              Text(
                _isCrit
                    ? 'ACERTO CRÍTICO (20 NATURAL)!'
                    : (_hit ? 'ACERTOU O GOLPE!' : 'ATAQUE BLOQUEADO / ERROU!'),
                style: TextStyle(
                  color: resultColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  fontFamily: 'sans-serif',
                ),
              ),
            ],
            if (_phase == 2 && _hit) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: _rolledDice
                    .map(
                      (d) => Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: widget.accentColor),
                        ),
                        child: Center(
                          child: Text(
                            '$d',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'sans-serif',
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              Text(
                'Dano Total: $_totalDamage PV',
                style: const TextStyle(
                  color: Colors.amberAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  fontFamily: 'sans-serif',
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (_phase == 2 && widget.isPlayerRolling)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(
                  DiceRollOutcome(
                    d20: _finalD20,
                    totalAttack: _finalD20 + widget.attackBonus,
                    hit: _hit,
                    isCrit: _isCrit,
                    totalDamage: _totalDamage,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: const Color(0xFF1A110E),
              ),
              child: const Text(
                'CONTINUAR',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}

// ==========================================
// MODELOS DE DADOS DOS CAMPEÕES E COMBATE
// ==========================================
class CharacterData {
  final String name;
  final String className;
  final String subclass;
  final String badgeText;
  final String quote;
  final double speedMeters;
  final int maxHp;
  final int ac;
  final int maxSpellPoints;
  final int spellSaveDc;
  final int spellAttackBonus;
  final int strMod;
  final int dexMod;
  final int conMod;
  final int intMod;
  final int wisMod;
  final int chaMod;
  final List<MeleeAttack> attacks;
  final List<SpellItem> spells;
  final List<ClassAbilityItem> abilities;
  final List<Color> themeGradient;
  final Color themeColor;
  final String imagePath;
  final IconData bgIcon1;
  final IconData bgIcon2;
  final String decoEmoji;

  const CharacterData({
    required this.name,
    required this.className,
    required this.subclass,
    required this.badgeText,
    required this.quote,
    required this.speedMeters,
    required this.maxHp,
    required this.ac,
    required this.maxSpellPoints,
    required this.spellSaveDc,
    required this.spellAttackBonus,
    required this.strMod,
    required this.dexMod,
    required this.conMod,
    required this.intMod,
    required this.wisMod,
    required this.chaMod,
    required this.attacks,
    required this.spells,
    required this.abilities,
    required this.themeGradient,
    required this.themeColor,
    required this.imagePath,
    required this.bgIcon1,
    required this.bgIcon2,
    required this.decoEmoji,
  });

  String get modsSummary {
    String fmt(int v) => v >= 0 ? '+$v' : '$v';
    return 'FOR ${fmt(strMod)} • DES ${fmt(dexMod)} • CON ${fmt(conMod)} • SAB ${fmt(wisMod)} • CAR ${fmt(chaMod)}';
  }
}

class MeleeAttack {
  final String name;
  final String description;
  final int diceCount;
  final int diceSides;
  final int attackMod;
  final int damageMod;
  final String statLabel;
  final String damageType;
  final IconData icon;
  final bool isFinesse;

  const MeleeAttack({
    required this.name,
    required this.description,
    required this.diceCount,
    required this.diceSides,
    required this.attackMod,
    required this.damageMod,
    required this.statLabel,
    required this.damageType,
    required this.icon,
    required this.isFinesse,
  });
}

class SpellItem {
  final String id;
  final String name;
  final int circle;
  final int pmCost;
  final ActionCostType costType;
  final TargetType targetType;
  final double rangeMeters;
  final String description;
  final int diceCount;
  final int diceSides;
  final int flatBonus;
  final bool usesSpellAttack;
  final String saveStat;
  final bool halfOnSave;
  final bool isHealing;
  final IconData icon;

  const SpellItem({
    required this.id,
    required this.name,
    required this.circle,
    required this.pmCost,
    required this.costType,
    required this.targetType,
    required this.rangeMeters,
    required this.description,
    required this.diceCount,
    required this.diceSides,
    required this.flatBonus,
    required this.usesSpellAttack,
    this.saveStat = '',
    this.halfOnSave = true,
    required this.isHealing,
    required this.icon,
  });
}

class ClassAbilityItem {
  final String id;
  final String name;
  final ActionCostType costType;
  final int maxUses;
  final String description;
  final IconData icon;

  const ClassAbilityItem({
    required this.id,
    required this.name,
    required this.costType,
    required this.maxUses,
    required this.description,
    required this.icon,
  });
}

class CombatLogEntry {
  final String text;
  final Color color;

  const CombatLogEntry({
    required this.text,
    required this.color,
  });
}

// ==========================================
// PINTORES CUSTOMIZADOS (D20 E CÍRCULO ARCANO)
// ==========================================
class D20Painter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.44;

    final fillPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF8B0000), Color(0xFF3E0000)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final borderPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - math.pi / 2;
      final pt = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);

    // Triângulo interno do D20
    final innerRadius = radius * 0.56;
    final triPath = Path();
    for (int i = 0; i < 3; i++) {
      final angle = (2 * math.pi / 3) * i - math.pi / 2;
      final pt = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );
      if (i == 0) {
        triPath.moveTo(pt.dx, pt.dy);
      } else {
        triPath.lineTo(pt.dx, pt.dy);
      }
    }
    triPath.close();
    canvas.drawPath(triPath, borderPaint..strokeWidth = 2);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: '20',
        style: TextStyle(
          color: Color(0xFFF5E6C8),
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: 'Georgia',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2 + 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ArcaneCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width * 0.45;
    final innerR = size.width * 0.34;

    final paint = Paint()
      ..color = const Color(0xFFD4AF37).withOpacity(0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, outerR, paint);
    canvas.drawCircle(center, innerR, paint);

    for (int i = 0; i < 12; i++) {
      final angle = (2 * math.pi / 12) * i;
      final p1 = Offset(
        center.dx + innerR * math.cos(angle),
        center.dy + innerR * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + outerR * math.cos(angle),
        center.dy + outerR * math.sin(angle),
      );
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FloatingDamageText extends StatefulWidget {
  final String text;
  final Color color;
  final VoidCallback onFinished;

  const FloatingDamageText({
    super.key,
    required this.text,
    required this.color,
    required this.onFinished,
  });

  @override
  State<FloatingDamageText> createState() => _FloatingDamageTextState();
}

class _FloatingDamageTextState extends State<FloatingDamageText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;
  late Animation<Offset> _offsetAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _opacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _offsetAnim = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -1.5),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward().then((_) => widget.onFinished());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnim,
      child: FadeTransition(
        opacity: _opacityAnim,
        child: Material(
          color: Colors.transparent,
          child: Text(
            widget.text,
            style: TextStyle(
              color: widget.color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              shadows: const [
                Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1))
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PulsingGlowWrapper extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final bool active;

  const PulsingGlowWrapper({
    super.key,
    required this.child,
    required this.glowColor,
    required this.active,
  });

  @override
  State<PulsingGlowWrapper> createState() => _PulsingGlowWrapperState();
}

class _PulsingGlowWrapperState extends State<PulsingGlowWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final double spread = 2.0 + (_pulseController.value * 4.0);
        final double blur = 6.0 + (_pulseController.value * 8.0);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withOpacity(0.35 + (_pulseController.value * 0.25)),
                blurRadius: blur,
                spreadRadius: spread,
              ),
            ],
          ),
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

class ActiveFloatingText {
  final double row;
  final double col;
  final String text;
  final Color color;
  ActiveFloatingText({
    required this.row,
    required this.col,
    required this.text,
    required this.color,
  });
}

class CriticalHitFlash extends StatefulWidget {
  final bool triggerFlash;

  const CriticalHitFlash({super.key, required this.triggerFlash});

  @override
  State<CriticalHitFlash> createState() => _CriticalHitFlashState();
}

class _CriticalHitFlashState extends State<CriticalHitFlash>
    with SingleTickerProviderStateMixin {
  late AnimationController _flashController;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void didUpdateWidget(CriticalHitFlash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.triggerFlash && !oldWidget.triggerFlash) {
      _flashController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flashController,
      builder: (context, child) {
        if (_flashController.isDismissed) return const SizedBox.shrink();
        final double val = 1.0 - _flashController.value;
        return IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.red.withOpacity(val * 0.85),
                width: 8,
              ),
              color: Colors.red.withOpacity(val * 0.15),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// PARTE 1 — FUNDO ANIMADO + UTILITÁRIOS  (colar no final do main.dart)
// ============================================================================

/// Faz um gradiente "deslizar" — usado no brilho (sheen) que passa pelos cards
/// e pelo botão JOGAR.
class _SlideGradientTransform extends GradientTransform {
  const _SlideGradientTransform(this.percent);
  final double percent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * percent, 0.0, 0.0);
  }
}

/// Fundo vivo da tela inicial:
///  • névoas coloridas que flutuam devagar
///  • dados/hexágonos dourados subindo e girando
///  • brasas com brilho subindo da parte de baixo
///  • dois círculos arcanos girando em sentidos opostos
///  • leve parallax seguindo o mouse
///  • vinheta escura nas bordas
class AnimatedFantasyBackground extends StatefulWidget {
  /// Se false, não desenha os círculos arcanos (útil na tela de seleção,
  /// que já tem o seu próprio).
  final bool showRunes;

  /// Posição do mouse normalizada (-1..1). Opcional.
  final ValueListenable<Offset>? pointer;

  const AnimatedFantasyBackground({
    super.key,
    this.showRunes = true,
    this.pointer,
  });

  @override
  State<AnimatedFantasyBackground> createState() =>
      _AnimatedFantasyBackgroundState();
}

class _AnimatedFantasyBackgroundState extends State<AnimatedFantasyBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop;
  Offset _smooth = Offset.zero;

  @override
  void initState() {
    super.initState();
    // Um ciclo completo a cada 40s. Todos os movimentos usam múltiplos
    // inteiros desse ciclo, então o loop nunca "dá um pulo".
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
    _loop.addListener(() {
      final target = widget.pointer?.value ?? Offset.zero;
      _smooth = Offset.lerp(_smooth, target, 0.05)!;
    });
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _loop,
          builder: (context, _) {
            final t = _loop.value;
            final p = _smooth;
            return Stack(
              fit: StackFit.expand,
              children: [
                // Base
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.2,
                      colors: [Color(0xFF3E2723), Color(0xFF1A110E)],
                    ),
                  ),
                ),
                // Névoas + dados + brasas
                CustomPaint(
                  painter: _AmbientPainter(t: t, parallax: p),
                ),
                // Círculos arcanos
                if (widget.showRunes) ...[
                  Center(
                    child: Transform.translate(
                      offset: p * 10,
                      child: Transform.rotate(
                        angle: t * 2 * math.pi,
                        child: CustomPaint(
                          size: const Size(760, 760),
                          painter: ArcaneCirclePainter(),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Transform.translate(
                      offset: p * 18,
                      child: Transform.rotate(
                        angle: -t * 4 * math.pi,
                        child: CustomPaint(
                          size: const Size(520, 520),
                          painter: ArcaneCirclePainter(),
                        ),
                      ),
                    ),
                  ),
                ],
                // Vinheta
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.1,
                      colors: [Colors.transparent, Color(0xCC000000)],
                      stops: [0.55, 1.0],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  final double t; // 0..1 (ciclo de 40s)
  final Offset parallax; // -1..1

  _AmbientPainter({required this.t, required this.parallax});

  static const double _tau = math.pi * 2;

  @override
  void paint(Canvas canvas, Size size) {
    _paintNebulas(canvas, size);
    _paintDice(canvas, size);
    _paintEmbers(canvas, size);
  }

  // ---------- Névoas ----------
  void _blob(Canvas canvas, Offset c, double r, Color color, double opacity) {
    final rect = Rect.fromCircle(center: c, radius: r);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withOpacity(opacity), color.withOpacity(0)],
      ).createShader(rect);
    canvas.drawCircle(c, r, paint);
  }

  void _paintNebulas(Canvas canvas, Size s) {
    final side = math.max(s.width, s.height);
    final shift = parallax * 18;

    _blob(
      canvas,
      Offset(
        s.width * (0.22 + 0.07 * math.sin(t * _tau)),
        s.height * (0.28 + 0.06 * math.cos(t * _tau * 2)),
      ) + shift,
      side * 0.55,
      const Color(0xFFB71C1C),
      0.28,
    );
    _blob(
      canvas,
      Offset(
        s.width * (0.80 + 0.06 * math.cos(t * _tau)),
        s.height * (0.72 + 0.07 * math.sin(t * _tau * 2)),
      ) - shift,
      side * 0.50,
      const Color(0xFFFF8F00),
      0.14,
    );
    final pulse = math.sin(t * _tau * 4);
    _blob(
      canvas,
      Offset(s.width * 0.5, s.height * 0.48) + shift * 0.5,
      side * 0.42 * (1 + 0.05 * pulse),
      const Color(0xFFD4AF37),
      0.10 + 0.04 * pulse,
    );
  }

  // ---------- Dados / hexágonos flutuantes ----------
  void _paintDice(Canvas canvas, Size s) {
    final rnd = math.Random(42);
    for (int i = 0; i < 9; i++) {
      final xr = rnd.nextDouble();
      final cycles = 2 + rnd.nextInt(3); // 2..4 subidas por ciclo
      final phase = rnd.nextDouble();
      final size = 14.0 + rnd.nextDouble() * 30;
      final spin = (1 + rnd.nextInt(2)) * (rnd.nextBool() ? 1 : -1);

      final q = (t * cycles + phase) % 1.0;
      final depth = size / 44;
      final c = Offset(
            s.width * xr + math.sin((q + phase) * _tau) * 22,
            s.height * (1.12 - 1.24 * q),
          ) +
          parallax * (28 * depth);
      final alpha = math.sin(q * math.pi) * (0.10 + 0.10 * depth);
      _hex(canvas, c, size, t * _tau * spin + phase * _tau, alpha);
    }
  }

  void _hex(Canvas canvas, Offset c, double r, double rot, double alpha) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFFD4AF37).withOpacity(alpha.clamp(0.0, 1.0));

    final hex = Path();
    for (int i = 0; i < 6; i++) {
      final a = rot + (math.pi / 3) * i - math.pi / 2;
      final pt = c + Offset(math.cos(a) * r, math.sin(a) * r);
      if (i == 0) {
        hex.moveTo(pt.dx, pt.dy);
      } else {
        hex.lineTo(pt.dx, pt.dy);
      }
    }
    hex.close();
    canvas.drawPath(hex, stroke);

    final tri = Path();
    for (int i = 0; i < 3; i++) {
      final a = rot + (2 * math.pi / 3) * i - math.pi / 2;
      final pt = c + Offset(math.cos(a) * r * 0.56, math.sin(a) * r * 0.56);
      if (i == 0) {
        tri.moveTo(pt.dx, pt.dy);
      } else {
        tri.lineTo(pt.dx, pt.dy);
      }
    }
    tri.close();
    canvas.drawPath(tri, stroke);
  }

  // ---------- Brasas ----------
  void _paintEmbers(Canvas canvas, Size s) {
    final rnd = math.Random(7);
    final paint = Paint();
    for (int i = 0; i < 48; i++) {
      final xr = rnd.nextDouble();
      final cycles = 4 + rnd.nextInt(5); // 4..8 subidas por ciclo
      final phase = rnd.nextDouble();
      final radius = 0.8 + rnd.nextDouble() * 2.0;
      final seed = rnd.nextDouble();

      final q = (t * cycles + phase) % 1.0;
      final sway = math.sin((q * 2 + phase) * _tau) * (10 + 14 * seed);
      final pos = Offset(
            s.width * xr + sway + q * 40,
            s.height * (1.06 - 1.12 * q),
          ) +
          parallax * (10 + radius * 6);

      final flicker = 0.65 + 0.35 * math.sin((t * 24 + seed) * _tau);
      final a = (math.sin(q * math.pi) * flicker).clamp(0.0, 1.0);
      final color =
          Color.lerp(const Color(0xFFFFE082), const Color(0xFFFF5722), q)!;

      paint.color = color.withOpacity(a * 0.10);
      canvas.drawCircle(pos, radius * 5, paint);
      paint.color = color.withOpacity(a * 0.28);
      canvas.drawCircle(pos, radius * 2.4, paint);
      paint.color = color.withOpacity(a * 0.95);
      canvas.drawCircle(pos, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter old) =>
      old.t != t || old.parallax != parallax;
}

/// Partículas de brilho que sobem dentro do card quando o mouse está em cima.
/// Partículas de brilho que sobem dentro do card quando o mouse está em cima.
class _SparklePainter extends CustomPainter {
  final double t; // 0..1 repetindo
  final Color color;
  final double intensity; // 0..1

  _SparklePainter({
    required this.t,
    required this.color,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0) return;
    final rnd = math.Random(11);
    final paint = Paint();
    for (int i = 0; i < 20; i++) {
      final xr = rnd.nextDouble();
      final speed = 1 + rnd.nextInt(2);
      final phase = rnd.nextDouble();
      final r = 1.0 + rnd.nextDouble() * 2.2;

      final p = (t * speed + phase) % 1.0;
      final x = size.width * xr + math.sin((p + phase) * math.pi * 2) * 10;
      final y = size.height * (1.0 - p);
      final a = (math.sin(p * math.pi) * intensity).clamp(0.0, 1.0);

      paint.color = color.withOpacity(a * 0.18);
      canvas.drawCircle(Offset(x, y), r * 3.2, paint);
      paint.color = Colors.white.withOpacity(a * 0.9);
      canvas.drawCircle(Offset(x, y), r * 0.8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) =>
      old.t != t || old.intensity != intensity || old.color != color;
}
