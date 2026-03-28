import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../widgets/particle_canvas.dart';

class MarketingHomePage extends StatefulWidget {
  final VoidCallback onLaunch;
  final Widget? backgroundWidget;

  const MarketingHomePage({
    super.key,
    required this.onLaunch,
    this.backgroundWidget,
  });

  @override
  State<MarketingHomePage> createState() => _MarketingHomePageState();
}



class _MarketingHomePageState extends State<MarketingHomePage> {
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollProgress);
  }

  void _updateScrollProgress() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    setState(() {
      _scrollProgress = (currentScroll / maxScroll).clamp(0.0, 1.0);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A0F0A), // #0a0f0a
                  Color(0xFF0D1B0D), // #0d1b0d
                  Color(0xFF0A0F0A), // #0a0f0a
                ],
              ),
            ),
          ),

          // Particle Animation
          Positioned.fill(
            child: widget.backgroundWidget ?? const ParticleCanvas(),
          ),

          // Main Content
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                _buildHeroSection(context),
                _buildProblemSection(context),
                _buildSolutionSection(context),
                _buildFeaturesSection(context),
                _buildUniquenessSection(context),
                _buildTechStackSection(context),
                _buildImpactSection(context),
                _buildFinalCTA(context),
                _buildFooter(context),
              ],
            ),
          ),

          // Progress Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: _scrollProgress,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 900;
          
          if (isDesktop) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildHeroContent(context, true),
                  ),
                ),
                const SizedBox(width: 60),
                _buildVisualStats(),
              ],
            );
          } else {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: _buildHeroContent(context, false),
                ),
                const SizedBox(height: 60),
                _buildVisualStats(),
              ],
            );
          }
        }
      ),
    );
  }

  List<Widget> _buildHeroContent(BuildContext context, bool isDesktop) {
    return [
      // Floating Badge
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.accentGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
              Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                color: AppColors.accentGreen,
                shape: BoxShape.circle,
              ),
            ),
            const Text(
              'AI-Powered Agriculture',
              style: TextStyle(
                color: AppColors.accentGreen,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 30),
      
      Text(
        'CropAId',
        style: TextStyle(
          fontSize: isDesktop ? 72 : 48,
          fontWeight: FontWeight.w800,
          height: 1.1,
          color: Colors.white,
          shadows: [
            Shadow(
              color: AppColors.accentGreen.withOpacity(0.5),
              blurRadius: 20,
            )
          ],
          decoration: TextDecoration.none,
        ),
      ).gradient(
        const LinearGradient(
          colors: [AppColors.accentGreen, AppColors.nature600],
        ),
      ),
      
      Text(
        'Smart Treatment Starts Here',
        style: TextStyle(
          fontSize: isDesktop ? 28 : 20,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFE0FFE0).withOpacity(0.7),
          letterSpacing: 1,
        ),
        textAlign: isDesktop ? TextAlign.start : TextAlign.center,
      ),
      
      const SizedBox(height: 30),
      
      Text(
        'Empowering farmers with intelligent crop disease diagnosis and actionable remediation guidance through AI-driven insights, native language support, and offline-first accessibility.',
        style: TextStyle(
          fontSize: 18,
          height: 1.7,
          color: const Color(0xFFE0FFE0).withOpacity(0.8),
        ),
        textAlign: isDesktop ? TextAlign.start : TextAlign.center,
      ),
      
      const SizedBox(height: 50),
      
      // Buttons
      Wrap(
        spacing: 20,
        runSpacing: 20,
        alignment: WrapAlignment.center,
        children: [
          ElevatedButton(
            onPressed: widget.onLaunch,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGreen,
              foregroundColor: Colors.black, // Dark text on green
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 22),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 10,
              shadowColor: AppColors.accentGreen.withOpacity(0.4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Launch Application',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward),
              ],
            ),
          ),
          
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accentGreen,
              padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 22),
              side: BorderSide(color: AppColors.accentGreen.withOpacity(0.4), width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Watch Demo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.play_arrow),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildVisualStats() {
    return Wrap(
      spacing: 40,
      alignment: WrapAlignment.center,
      children: [
        _buildStatItem('95%+', 'Accuracy'),
        _buildStatItem('15+', 'Languages'),
        _buildStatItem('24/7', 'Offline Access'),
      ],
    );
        }


  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.accentGreen,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: const Color(0xFFE0FFE0).withOpacity(0.6),
            letterSpacing: 1,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // --- Placeholders for other sections ---
  // To avoid huge file size initially, I will implement barebones for other sections
  // and flesh them out in subsequent passes if needed, or put them here if space allows.

  Widget _buildProblemSection(BuildContext context) {
    return _buildSectionContainer(
      title: 'The Real-World Crisis',
      tag: 'The Challenge',
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              _buildProblemCard('⏱️', 'Delayed Detection', 'Yield loss due to slow manual inspection.'),
              _buildProblemCard('🌐', 'Limited Access', 'Lack of expert guidance for smallholders.'),
              _buildProblemCard('📱', 'Connectivity Issues', 'Unreliable internet in rural areas.'),
              _buildProblemCard('📖', 'Literacy Barriers', 'Text-based advice fails legibility.'),
            ],
          );
        }
      ),
    );
  }

  Widget _buildProblemCard(String icon, String title, String desc) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.7), height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSolutionSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
       child: Column(
         children: [
           const Text(
             'Our Innovation',
             style: TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.bold),
           ),
           const SizedBox(height: 10),
           const Text(
             'Intelligent Decision Support',
             style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
             textAlign: TextAlign.center,
           ),
           const SizedBox(height: 40),
           Text(
             'CropAId transforms disease management with computer vision + agronomic intelligence.',
             style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 18),
             textAlign: TextAlign.center,
           ),
         ],
       ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    // List of features
     final features = [
      {'icon': '🎯', 'title': 'AI-Powered Precision', 'desc': '95%+ accuracy in disease detection'},
      {'icon': '🌍', 'title': 'Native Language Support', 'desc': 'Voice-first interface in 15+ languages'},
      {'icon': '📡', 'title': 'Offline-First Design', 'desc': 'Works without internet connectivity'},
      {'icon': '🔒', 'title': 'Privacy-Preserving AI', 'desc': 'Federated learning protects data'},
      {'icon': '💊', 'title': 'Complete Treatment Plans', 'desc': 'Organic & chemical remediation'},
      {'icon': '🌾', 'title': 'Regional Intelligence', 'desc': 'Context-aware recommendations'},
    ];

    return _buildSectionContainer(
      title: 'Powerful Features',
      tag: 'Capabilities',
      child: Wrap(
        spacing: 20,
        runSpacing: 20,
        alignment: WrapAlignment.center,
        children: features.map((f) => _buildProblemCard(f['icon']!, f['title']!, f['desc']!)).toList(),
      ),
    );
  }
  
  Widget _buildUniquenessSection(BuildContext context) {
      return const SizedBox.shrink(); // Simplified for now
  }

  Widget _buildTechStackSection(BuildContext context) {
      return const SizedBox.shrink(); // Simplified for now
  }

  Widget _buildImpactSection(BuildContext context) {
      return _buildSectionContainer(
        title: 'Transforming Agriculture',
        tag: 'Real-World Impact',
         child: Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              _buildImpactCard('🌾', 'Early Detection', 'Prevents crop loss'),
              _buildImpactCard('💰', 'Cost Reduction', 'Optimized treatment'),
              _buildImpactCard('🌱', 'Sustainable Farming', 'Organic alternatives'),
              _buildImpactCard('👨‍🌾', 'Farmer Empowerment', 'Independent decisions'),
            ],
          ),
      );
  }
  
  Widget _buildImpactCard(String icon, String title, String desc) {
     return Container(
       width: 250,
       padding: const EdgeInsets.all(20),
       decoration: BoxDecoration(
         color: AppColors.accentGreen.withOpacity(0.05),
         borderRadius: BorderRadius.circular(16),
         border: Border.all(color: AppColors.accentGreen.withOpacity(0.1)),
       ),
       child: Column(
         children: [
           Text(icon, style: const TextStyle(fontSize: 32)),
           const SizedBox(height: 10),
           Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentGreen)),
           const SizedBox(height: 5),
           Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12), textAlign: TextAlign.center),
         ],
       ),
     );
  }

  Widget _buildFinalCTA(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(60),
      child: Column(
        children: [
          const Text(
            'Ready to Transform Your Farming?',
             style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
             textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: widget.onLaunch,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGreen,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            ),
             child: const Text('Launch CropAId 🚀', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      color: Colors.black.withOpacity(0.3),
      child: Column(
        children: [
          const Text('CropAId', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 10),
          Text('© 2026 CropAId - Team 7 • Built with ❤️ for Farmers', style: TextStyle(color: Colors.white.withOpacity(0.5))),
        ],
      ),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required String tag,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accentGreen.withOpacity(0.5)),
            ),
            child: Text(tag, style: const TextStyle(color: AppColors.accentGreen, fontSize: 12)),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          child,
        ],
      ),
    );
  }
}

// Extension for Gradient Text
extension GradientText on Text {
  Widget gradient(Gradient gradient) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: this,
    );
  }
}
