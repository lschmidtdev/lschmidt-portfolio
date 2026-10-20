import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lschmidt_portfolio/presentation/cubits/content_cubit.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _placeholderHeight = 3000.0;

  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SingleChildScrollView(
      controller: _scroll,
      child: SizedBox(
        height: _placeholderHeight,
        child: Center(
          child: BlocBuilder<ContentCubit, ContentState>(
            builder: (context, state) => switch (state) {
              ContentLoading() => const CircularProgressIndicator(),
              ContentReady(:final content) => Text(content.profile.name),
              ContentError() => const Text('Lucas Schmidt'),
            },
          ),
        ),
      ),
    ),
  );
}
