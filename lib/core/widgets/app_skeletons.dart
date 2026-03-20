import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AppSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final ShapeBorder shape;

  const AppSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.shape = const RoundedRectangleBorder(),
  });

  const AppSkeleton.rectangular({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.shape = const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
  });

  const AppSkeleton.circular({
    super.key,
    required this.width,
    required this.height,
    this.shape = const CircleBorder(),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[800]!
          : Colors.grey[300]!,
      highlightColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[700]!
          : Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(
          color: Colors.white10,
          shape: shape,
        ),
      ),
    );
  }
}

class BoardCardSkeleton extends StatelessWidget {
  const BoardCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppSkeleton.rectangular(height: 16, width: 140),
            const SizedBox(height: 12),
            const AppSkeleton.rectangular(height: 14),
            const SizedBox(height: 6),
            const AppSkeleton.rectangular(height: 14, width: 200),
            const SizedBox(height: 12),
            Row(
              children: [
                const AppSkeleton.circular(width: 24, height: 24),
                const SizedBox(width: 8),
                const AppSkeleton.rectangular(height: 12, width: 60),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ColumnSkeleton extends StatelessWidget {
  const ColumnSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.grey[100]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppSkeleton.rectangular(height: 20, width: 120),
              const AppSkeleton.circular(width: 20, height: 20),
            ],
          ),
          const SizedBox(height: 24),
          const BoardCardSkeleton(),
          const BoardCardSkeleton(),
          const BoardCardSkeleton(),
        ],
      ),
    );
  }
}

class BoardListSkeleton extends StatelessWidget {
  const BoardListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppSkeleton.rectangular(height: 18, width: 140),
                  Row(
                    children: [
                      AppSkeleton.circular(width: 24, height: 24),
                      SizedBox(width: 8),
                      AppSkeleton.circular(width: 24, height: 24),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12),
              AppSkeleton.rectangular(height: 14, width: 220),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppSkeleton.rectangular(height: 12, width: 80),
                  AppSkeleton.rectangular(height: 20, width: 60),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
