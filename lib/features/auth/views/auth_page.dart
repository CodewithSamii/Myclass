import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design_system/tokens.dart';
import '../../../shared/widgets/primitives.dart';
import '../bloc/auth_bloc.dart';

typedef AulaMark = MyClassMark;

class MyClassMark extends StatelessWidget {
  const MyClassMark({super.key, this.size = 30});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _MCMarkPainter(context.colors.ink)),
  );
}

class _MCMarkPainter extends CustomPainter {
  const _MCMarkPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;
    final strokeWidth = w * 0.088;

    final p = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Stroke 1: Left stem and central chevron of 'M'
    final mPath = Path()
      ..moveTo(w * 0.16, h * 0.80)
      ..lineTo(w * 0.16, h * 0.22)
      ..lineTo(w * 0.47, h * 0.56)
      ..lineTo(w * 0.76, h * 0.22);
    canvas.drawPath(mPath, p);

    // Stroke 2: The seamlessly integrated 'C' arc flowing from the right apex of M
    final cPath = Path()
      ..moveTo(w * 0.76, h * 0.22)
      ..cubicTo(
        w * 0.94, h * 0.22,
        w * 0.96, h * 0.76,
        w * 0.64, h * 0.80,
      )
      ..cubicTo(
        w * 0.48, h * 0.82,
        w * 0.36, h * 0.76,
        w * 0.34, h * 0.68,
      );
    canvas.drawPath(cPath, p);
  }

  @override
  bool shouldRepaint(covariant _MCMarkPainter old) => color != old.color;
}

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const MyClassMark(),
                          const SizedBox(width: 9),
                          Text(
                            'myclass',
                            style: context.type.headlineSmall?.copyWith(
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 44),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Label('A little more clarity'),
                            const SizedBox(height: 16),
                            Text(
                              'Your academic life.\nIn one place.',
                              style: context.type.displaySmall,
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Classes, deadlines and everything in between. Know what comes next.',
                              style: context.type.bodyLarge?.copyWith(
                                color: context.colors.secondary,
                                height: 1.65,
                              ),
                            ),
                            const SizedBox(height: 36),
                            const _IntroAgenda(),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          PrimaryButton(
                            'Get started',
                            onPressed: () =>
                                context.read<AuthBloc>().add(AuthBeginSetup()),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => context.read<AuthBloc>().add(
                              AuthReturningRequested(),
                            ),
                            child: const Text('Already have a space? Sign in'),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Made for the way university life actually works.',
                            textAlign: TextAlign.center,
                            style: context.type.bodySmall?.copyWith(
                              color: context.colors.faint,
                            ),
                          ),
                        ],
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

class _IntroAgenda extends StatelessWidget {
  const _IntroAgenda();
  @override
  Widget build(BuildContext context) => Surface(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Label('Your day, in focus'),
            const Spacer(),
            Icon(
              CupertinoIcons.sun_max,
              size: 17,
              color: context.colors.secondary,
            ),
          ],
        ),
        const SizedBox(height: 22),
        _line(context, '10:30', 'Artificial Intelligence', 'Room 403', false),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Divider(color: context.colors.line),
        ),
        _line(
          context,
          '23:59',
          'Database assignment',
          'One thing to finish',
          true,
        ),
      ],
    ),
  );
  Widget _line(
    BuildContext c,
    String time,
    String title,
    String subtitle,
    bool due,
  ) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 52,
        child: Text(
          time,
          style: c.type.bodySmall?.copyWith(color: c.colors.secondary),
        ),
      ),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: c.type.titleSmall),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: c.type.bodySmall?.copyWith(
                color: due ? c.colors.amber : c.colors.secondary,
              ),
            ),
          ],
        ),
      ),
      Icon(
        due ? CupertinoIcons.circle : CupertinoIcons.checkmark,
        size: 15,
        color: c.colors.faint,
      ),
    ],
  );
}

class ReturningPage extends StatelessWidget {
  const ReturningPage({super.key});
  @override
  Widget build(BuildContext context) => BlocBuilder<AuthBloc, AuthState>(
    builder: (context, state) => Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      const MyClassMark(),
                      const SizedBox(width: 10),
                      Text('myclass', style: context.type.headlineSmall),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Back to your space.',
                    style: context.type.headlineLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your classes. Your deadlines. Right where you left them.',
                    style: context.type.bodyLarge?.copyWith(
                      color: context.colors.secondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (state.error != null) ...[
                    ErrorNotice(state.error!),
                    const SizedBox(height: 16),
                  ],
                  GoogleButton(
                    busy: state.busy,
                    onTap: () =>
                        context.read<AuthBloc>().add(AuthGoogleRequested()),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This preview simulates Google sign-in.',
                    style: context.type.bodySmall?.copyWith(
                      color: context.colors.faint,
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: TextButton(
                      onPressed: () =>
                          context.read<AuthBloc>().add(AuthBeginSetup()),
                      child: const Text('Set up a new academic space'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key, required this.onTap, this.busy = false});
  final VoidCallback onTap;
  final bool busy;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: busy ? null : onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (busy)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: context.colors.secondary,
              ),
            )
          else
            Text(
              'G',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 21,
                fontWeight: FontWeight.w600,
                color: context.colors.canvas,
              ),
            ),
          const SizedBox(width: 14),
          Text(busy ? 'Opening your space…' : 'Continue with Google'),
        ],
      ),
    ),
  );
}
