import 'dart:ui';

import 'package:flutter/material.dart';

class CategoryCard extends StatelessWidget {
  final String image;
  final String title;

  const CategoryCard({super.key, required this.image, required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 7,
      color: Colors.white,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.85),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: InkWell(
              splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Circular image container with border
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: Image.network(
                        image,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.category_rounded,
                            size: 40,
                            color: Theme.of(context).colorScheme.primary,
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Theme.of(context).colorScheme.primary,
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Title with animated indicator
                    Column(
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        // const SizedBox(height: 8),
                        // // Animated indicator
                        // Container(
                        //   height: 3,
                        //   width: 30,
                        //   decoration: BoxDecoration(
                        //     gradient: LinearGradient(
                        //       colors: [
                        //         Theme.of(context)
                        //             .colorScheme
                        //             .primary
                        //             .withOpacity(0.5),
                        //         Theme.of(context).colorScheme.primary,
                        //       ],
                        //     ),
                        //     borderRadius: BorderRadius.circular(10),
                        //   ),
                        // ),
                      ],
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
}
