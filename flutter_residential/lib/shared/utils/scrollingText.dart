


import 'package:flutter/material.dart';

class ScrollingText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const ScrollingText({super.key, required this.text, this.style});

  @override
  State<ScrollingText> createState() => ScrollingTextState();
}

class ScrollingTextState extends State<ScrollingText> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _iniciarScroll());
  }

  Future<void> _iniciarScroll() async {
    if (!mounted || !_controller.hasClients) return;
    final maxScroll = _controller.position.maxScrollExtent;
    if (maxScroll <= 0) return; // cabe completo — nada que hacer

    await _ciclo(maxScroll);
  }

  Future<void> _ciclo(double maxScroll) async {
    while (mounted) {
      // Pausa inicial para que el usuario lea el inicio
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;

      // Desplaza hasta el final — 15 ms por px, acotado entre 1 s y 4 s
      final duracion = Duration(
        milliseconds: (maxScroll * 15).round().clamp(1000, 4000),
      );
      await _controller.animateTo(
        maxScroll,
        duration: duracion,
        curve: Curves.linear,
      );
      if (!mounted) return;

      // Pausa al final antes de reiniciar
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      _controller.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(widget.text, style: widget.style, maxLines: 1),
    );
  }
}