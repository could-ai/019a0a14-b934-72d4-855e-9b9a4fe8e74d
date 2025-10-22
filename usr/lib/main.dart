import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Air Combat Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Player _player = Player(position: const Offset(200, 700));
  List<Enemy> _enemies = [];
  List<Bullet> _bullets = [];
  int _score = 0;
  bool _isGameOver = false;
  final Random _random = Random();
  Timer? _enemySpawnTimer;
  Timer? _bulletSpawnTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_gameLoop);
    startGame();
  }

  void startGame() {
    _player = Player(position: Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height - 100));
    _enemies.clear();
    _bullets.clear();
    _score = 0;
    _isGameOver = false;

    _controller.repeat();

    _enemySpawnTimer?.cancel();
    _enemySpawnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _spawnEnemy();
    });

    _bulletSpawnTimer?.cancel();
    _bulletSpawnTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      _spawnBullet();
    });
  }

  void _spawnEnemy() {
    if (!_isGameOver) {
      final screenWidth = MediaQuery.of(context).size.width;
      _enemies.add(Enemy(
          position: Offset(_random.nextDouble() * screenWidth, -50),
          size: const Size(50, 50)));
    }
  }

  void _spawnBullet() {
    if (!_isGameOver) {
      _bullets.add(Bullet(
          position: _player.position + const Offset(24, 0),
          size: const Size(5, 20)));
    }
  }

  void _gameLoop() {
    if (_isGameOver) {
      _controller.stop();
      _enemySpawnTimer?.cancel();
      _bulletSpawnTimer?.cancel();
      return;
    }

    final screenHeight = MediaQuery.of(context).size.height;

    // Move bullets
    _bullets.removeWhere((bullet) => bullet.position.dy < 0);
    for (var bullet in _bullets) {
      bullet.move();
    }

    // Move enemies
    _enemies.removeWhere((enemy) => enemy.position.dy > screenHeight);
    for (var enemy in _enemies) {
      enemy.move();
    }

    // Check for collisions
    _checkCollisions();

    setState(() {});
  }

  void _checkCollisions() {
    final List<Bullet> bulletsToRemove = [];
    final List<Enemy> enemiesToRemove = [];

    for (final bullet in _bullets) {
      for (final enemy in _enemies) {
        if (bullet.toRect().overlaps(enemy.toRect())) {
          bulletsToRemove.add(bullet);
          enemiesToRemove.add(enemy);
          _score++;
        }
      }
    }

    for (final enemy in _enemies) {
      if (enemy.toRect().overlaps(_player.toRect())) {
        setState(() {
          _isGameOver = true;
        });
      }
    }

    _bullets.removeWhere((b) => bulletsToRemove.contains(b));
    _enemies.removeWhere((e) => enemiesToRemove.contains(e));
  }

  @override
  void dispose() {
    _controller.dispose();
    _enemySpawnTimer?.cancel();
    _bulletSpawnTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onPanUpdate: (details) {
          if (!_isGameOver) {
            setState(() {
              _player.move(details.delta, context);
            });
          }
        },
        child: Stack(
          children: [
            CustomPaint(
              painter: GamePainter(
                player: _player,
                enemies: _enemies,
                bullets: _bullets,
                score: _score,
              ),
              child: Container(),
            ),
            if (_isGameOver)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Game Over',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    Text(
                      'Score: $_score',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: startGame,
                      child: const Text('Restart'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class GamePainter extends CustomPainter {
  final Player player;
  final List<Enemy> enemies;
  final List<Bullet> bullets;
  final int score;

  GamePainter({
    required this.player,
    required this.enemies,
    required this.bullets,
    required this.score,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.black87);

    // Player
    player.draw(canvas);

    // Enemies
    for (final enemy in enemies) {
      enemy.draw(canvas);
    }

    // Bullets
    for (final bullet in bullets) {
      bullet.draw(canvas);
    }

    // Score
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Score: $score',
        style: const TextStyle(color: Colors.white, fontSize: 24),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(20, 20));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class Player {
  Offset position;
  Size size;

  Player({required this.position, this.size = const Size(50, 50)});

  void move(Offset delta, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final newX = (position.dx + delta.dx).clamp(0.0, screenWidth - size.width);
    position = Offset(newX, position.dy);
  }

  void draw(Canvas canvas) {
    final paint = Paint()..color = Colors.blue;
    canvas.drawRect(toRect(), paint);
  }

  Rect toRect() => Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
}

class Enemy {
  Offset position;
  Size size;
  double speed;

  Enemy({required this.position, required this.size, this.speed = 3.0});

  void move() {
    position = Offset(position.dx, position.dy + speed);
  }

  void draw(Canvas canvas) {
    final paint = Paint()..color = Colors.red;
    canvas.drawRect(toRect(), paint);
  }

  Rect toRect() => Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
}

class Bullet {
  Offset position;
  Size size;
  double speed;

  Bullet({required this.position, required this.size, this.speed = 8.0});

  void move() {
    position = Offset(position.dx, position.dy - speed);
  }

  void draw(Canvas canvas) {
    final paint = Paint()..color = Colors.yellow;
    canvas.drawRect(toRect(), paint);
  }

  Rect toRect() => Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
}
