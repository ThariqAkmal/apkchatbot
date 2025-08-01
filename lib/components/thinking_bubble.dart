import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../constants/app_colors.dart';

class ThinkingBubble extends StatefulWidget {
  const ThinkingBubble({Key? key}) : super(key: key);

  @override
  _ThinkingBubbleState createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<ThinkingBubble>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.smart_toy,
              color: AppColors.primaryText,
              size: 18,
            ),
          ),
          SizedBox(width: 8),

          // Thinking bubble
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.botBubble,
                    borderRadius: BorderRadius.circular(
                      18,
                    ).copyWith(bottomLeft: Radius.circular(4)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBackground.withValues(
                          alpha: 0.3,
                        ),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                      // Glowing effect
                      BoxShadow(
                        color: AppColors.accent.withValues(
                          alpha: _glowAnimation.value * 0.3,
                        ),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated thinking text
                      AnimatedBuilder(
                        animation: _glowAnimation,
                        builder: (context, child) {
                          return ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                colors: [
                                  AppColors.primaryText.withValues(alpha: 0.7),
                                  AppColors.accent.withValues(
                                    alpha: _glowAnimation.value,
                                  ),
                                  AppColors.primaryText.withValues(alpha: 0.7),
                                ],
                                stops: [0.0, 0.5, 1.0],
                              ).createShader(bounds);
                            },
                            child: Text(
                              'thinking...',
                              style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: AppColors.primaryText,
                                height: 1.4,
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(width: 8),
                      // Animated dots
                      _buildAnimatedDots(),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final delay = index * 0.2;
            final animationValue = (_animationController.value + delay) % 1.0;
            final opacity =
                0.3 +
                (0.7 * (0.5 + 0.5 * math.sin(animationValue * 2 * math.pi)));

            return Container(
              margin: EdgeInsets.symmetric(horizontal: 1),
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: opacity),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: opacity * 0.5),
                      blurRadius: 2,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
