import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/app_colors.dart';
import '../../core/localization/language_provider.dart';
import '../../core/api_service.dart';

class NumerologyAnalysisScreen extends StatefulWidget {
  const NumerologyAnalysisScreen({super.key});

  @override
  State<NumerologyAnalysisScreen> createState() =>
      _NumerologyAnalysisScreenState();
}

class _NumerologyAnalysisScreenState extends State<NumerologyAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final Map<int, TextEditingController> _manualCellControllers = {
    for (var n in [4, 9, 2, 3, 5, 7, 8, 1, 6]) n: TextEditingController(),
  };

  bool _mobileAnalyzed = false;
  bool _isMobileLoading = false;
  bool _nameAnalyzed = false;
  bool _dobAnalyzed = false;
  bool _isDOBLoading = false;
  bool _isNameLoading = false;
  int? _nameCompoundNumber;
  int? _nameRootNumber;
  Map<String, dynamic>? _nameCompoundMeaning;
  Map<String, dynamic>? _nameRootMeaning;
  Map<String, dynamic>? _dcRelationship;

  List<dynamic> _mobileAnalysisResults = [];

  // DOB derived values
  Set<int> _dobPresentNumbers = {};
  int? _driverNumber;
  int? _conductorNumber;
  int? _kuaNumber;
  String _gender = 'Male';
  Set<int> _manualGridNumbers = {};

  // DR/CO for Combination Analysis

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _mobileAnalyzed = false;
          _dobAnalyzed = false;
          _nameAnalyzed = false;
          _isNameLoading = false;
          _nameCompoundNumber = null;
          _nameRootNumber = null;
          _nameCompoundMeaning = null;
          _nameRootMeaning = null;
          _mobileAnalysisResults = [];
          _dobPresentNumbers = {};
          _driverNumber = null;
          _conductorNumber = null;
          _kuaNumber = null;
          _manualGridNumbers = {};
          _mobileController.clear();
          _dobController.clear();
          _nameController.clear();
          for (var c in _manualCellControllers.values) {
            c.clear();
          }
        });
      }
    });
  }

  Future<void> _analyzeMobile() async {
    final mobile = _mobileController.text.trim();
    if (mobile.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit mobile number'),
        ),
      );
      return;
    }

    setState(() {
      _isMobileLoading = true;
      _mobileAnalyzed = false;
    });

    try {
      final result = await ApiService.analyzeMobile(mobile);
      setState(() {
        _mobileAnalysisResults = result['analysis'];
        _mobileAnalyzed = true;
        _isMobileLoading = false;
      });
    } catch (e) {
      setState(() => _isMobileLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll('Exception: ', '')}',
            ),
          ),
        );
      }
    }
  }

  Future<void> _analyzeDOB() async {
    final raw = _dobController.text.trim();
    final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid date of birth (DD/MM/YYYY)'),
        ),
      );
      return;
    }

    final day = int.tryParse(digitsOnly.substring(0, 2)) ?? 0;
    final month = int.tryParse(digitsOnly.substring(2, 4)) ?? 0;
    final year = int.tryParse(digitsOnly.substring(4, 8)) ?? 0;

    if (day < 1 || day > 31) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Day: Must be between 01 and 31')),
      );
      return;
    }

    if (month < 1 || month > 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid Month: Must be between 01 and 12'),
        ),
      );
      return;
    }

    if (year < 1800 || year > 2100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid year')),
      );
      return;
    }

    setState(() {
      _isDOBLoading = true;
      _dobAnalyzed = false;
    });

    try {
      // All unique non-zero digits from the full DOB
      final allDigits =
          digitsOnly.split('').map(int.parse).where((d) => d != 0).toSet();

      // Driver Number = sum of day digits, reduced to 1-9 (keep 11/22)
      int driverSum = day
          .toString()
          .split('')
          .map(int.parse)
          .reduce((a, b) => a + b);
      while (driverSum > 9 && driverSum != 11 && driverSum != 22) {
        driverSum = driverSum
            .toString()
            .split('')
            .map(int.parse)
            .reduce((a, b) => a + b);
      }

      // Conductor Number = sum of all DOB digits, reduced
      final fullSum = digitsOnly
          .split('')
          .map(int.parse)
          .reduce((a, b) => a + b);
      int conductorSum = fullSum
          .toString()
          .split('')
          .map(int.parse)
          .reduce((a, b) => a + b);
      while (conductorSum > 9 && conductorSum != 11 && conductorSum != 22) {
        conductorSum = conductorSum
            .toString()
            .split('')
            .map(int.parse)
            .reduce((a, b) => a + b);
      }

      // Kua Number calculation
      int yearSum = year
          .toString()
          .split('')
          .map(int.parse)
          .reduce((a, b) => a + b);
      while (yearSum > 9) {
        yearSum = yearSum
            .toString()
            .split('')
            .map(int.parse)
            .reduce((a, b) => a + b);
      }

      int kua;
      if (_gender == 'Male') {
        kua = 11 - yearSum;
      } else {
        kua = 4 + yearSum;
      }
      while (kua > 9) {
        kua = kua.toString().split('').map(int.parse).reduce((a, b) => a + b);
      }

      // Add derived numbers to the grid (reduced to 1-9)
      final gridDigits = Set<int>.from(allDigits);
      int reduce(int n) {
        int s = n;
        while (s > 9) {
          s = s.toString().split('').map(int.parse).reduce((a, b) => a + b);
        }
        return s;
      }

      gridDigits.add(reduce(driverSum));
      gridDigits.add(reduce(conductorSum));
      gridDigits.add(kua);

      final res = await ApiService.analyzeDriverConductor(
        driver: reduce(driverSum),
        conductor: reduce(conductorSum),
      );

      setState(() {
        _dcRelationship = res['relationship'];
        _dobPresentNumbers = gridDigits;
        _driverNumber = driverSum;
        _conductorNumber = conductorSum;
        _kuaNumber = kua;
        _dobAnalyzed = true;
        _isDOBLoading = false;
      });
    } catch (e) {
      setState(() => _isDOBLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _analyzeName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name')),
      );
      return;
    }

    setState(() {
      _isNameLoading = true;
      _nameAnalyzed = false;
    });

    try {
      final res = await ApiService.analyzeName(name);
      setState(() {
        _nameCompoundNumber = res['compound_number'];
        _nameRootNumber = res['root_number'];
        _nameCompoundMeaning = res['compound_meaning'];
        _nameRootMeaning = res['root_meaning'];
        _nameAnalyzed = true;
        _isNameLoading = false;
      });
    } catch (e) {
      setState(() => _isNameLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll('Exception: ', '')}',
            ),
          ),
        );
      }
    }
  }

  Future<void> _shareMobileAnalysis() async {
    final mobile = _mobileController.text.trim();
    if (mobile.isEmpty || _mobileAnalysisResults.isEmpty) return;

    // Show generating status
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating sharing image...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final controller = ScreenshotController();
      // Pre-calculate height: header(380) + footer(160) + each card(~320px)
      final double estimatedHeight =
          380 + 160 + (_mobileAnalysisResults.length * 320.0) + 80;

      final Uint8List? imageBytes = await controller.captureFromWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(600, double.maxFinite)),
          child: _buildShareableImage(),
        ),
        delay: const Duration(milliseconds: 200),
        targetSize: Size(600, estimatedHeight),
      );

      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final imagePath =
            await File(
              '${directory.path}/mobile_analysis_$mobile.png',
            ).create();
        await imagePath.writeAsBytes(imageBytes);

        await Share.shareXFiles([
          XFile(imagePath.path),
        ], text: 'Check out my Mobile Number Analysis from Aank Sastra! ✨');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to generate image: $e')));
      }
    }
  }

  Widget _buildShareableImage() {
    final mobile = _mobileController.text.trim();
    return Material(
      color: const Color(0xFFFBFBFE),
      child: Container(
        width: 600,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.vip.withOpacity(0.2), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Premium Gradient Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: AppColors.vip,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Aank Sastra',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'UNIVERSAL NUMEROLOGY ANALYSIS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.vip.withOpacity(0.8),
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 48),
                  const Text(
                    'Mobile Number Analysis',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mobile,
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 80,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.vip,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),

            // Analysis Content
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  ..._mobileAnalysisResults.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              width: 100,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.05),
                                border: Border(
                                  right: BorderSide(
                                    color: AppColors.primary.withOpacity(0.1),
                                  ),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Pos ${item['position']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item['pair'],
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLangItem(
                                      'ENG',
                                      item['meaning_en'],
                                      const Color(0xFFE3F2FD),
                                      const Color(0xFF1976D2),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildLangItem(
                                      'हिंदी',
                                      item['meaning_hi'],
                                      const Color(0xFFF3E5F5),
                                      const Color(0xFF7B1FA2),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildLangItem(
                                      'ગુજરાતી',
                                      item['meaning_gu'],
                                      const Color(0xFFE8F5E9),
                                      const Color(0xFF388E3C),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLangItem(String lang, String text, Color bg, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            lang,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF2D3436),
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildCustomTabBar(),
          const SizedBox(height: 40),
          _getActiveTabContent(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _getActiveTabContent() {
    switch (_tabController.index) {
      case 0:
        return _buildMobileAnalysisTab();
      case 1:
        return _buildLoShuGridTab();
      case 2:
        return _buildNameNumerologyTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.vip.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.vip.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppColors.vip,
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Numerology Analysis',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Unveil the divine frequency of numbers and names.',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTabItem(0, 'Mobile Analysis'),
            _buildTabItem(1, 'Date of Birth'),
            _buildTabItem(2, 'Name Analysis'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String title) {
    bool isSelected = _tabController.index == index;
    return InkWell(
      onTap: () {
        _tabController.animateTo(index);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : [],
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  // --- MOBILE ANALYSIS TAB ---
  Widget _buildMobileAnalysisTab() {
    final lang = context.watch<LanguageProvider>().currentLanguageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildInputSection(
                'Mobile Number Analysis',
                'Analyze the vibrational energy of your mobile number pairing by pairing.',
                _mobileController,
                'Enter 10-digit mobile number',
                _isMobileLoading ? null : _analyzeMobile,
                _isMobileLoading ? 'Analyzing...' : 'Analyze Now',
                Icons.phone_android,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.search,
              ),
            ),
          ],
        ),
        if (_mobileAnalyzed) ...[
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Digit Pair Analysis',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _shareMobileAnalysis,
                icon: const Icon(Icons.share_outlined, size: 18),
                label: const Text('Share Result'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _mobileAnalysisResults.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final item = _mobileAnalysisResults[index];
              String meaning = item['meaning_en'];
              if (lang == 'hi') meaning = item['meaning_hi'];
              if (lang == 'gu') meaning = item['meaning_gu'];

              return _buildPairAnalysisCard(
                position: item['position'],
                pair: item['pair'],
                meaning: meaning,
              );
            },
          ),
        ] else if (_isMobileLoading) ...[
          const SizedBox(height: 80),
          const Center(child: CircularProgressIndicator()),
        ] else
          _buildEmptyAnalysisState(
            'Enter a mobile number to reveal its destiny.',
          ),
      ],
    );
  }

  Widget _buildPairAnalysisCard({
    required int position,
    required String pair,
    required String meaning,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.vip.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'Pos $position',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  pair,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Implication',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  meaning,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Lo Shu Grid layout: standard order
  // [4, 9, 2]
  // [3, 5, 7]
  // [8, 1, 6]
  Widget _buildLoShuGridTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // DOB Input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey[100]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.vip.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.cake_outlined,
                      color: AppColors.vip,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date of Birth Analysis',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Lo Shu Grid & Driver/Conductor Numbers',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // Gender Selection
              const Text(
                'Select Gender',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildGenderOption(
                    'Male',
                    Icons.male,
                    const Color(0xFF1E88E5),
                  ),
                  const SizedBox(width: 16),
                  _buildGenderOption(
                    'Female',
                    Icons.female,
                    const Color(0xFFE91E63),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dobController,
                      keyboardType: TextInputType.datetime,
                      textInputAction: TextInputAction.go,
                      onSubmitted: (_) => _analyzeDOB(),
                      maxLength: 10,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                        DateInputFormatter(),
                      ],
                      decoration: InputDecoration(
                        hintText: 'DD/MM/YYYY',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 15,
                        ),
                        prefixIcon: const Icon(
                          Icons.calendar_today_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        counterText: '',
                        contentPadding: const EdgeInsets.all(20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[100]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _isDOBLoading ? null : _analyzeDOB,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 36,
                        vertical: 22,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child:
                        _isDOBLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Row(
                              children: [
                                Text(
                                  'Generate Grid',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Icon(Icons.grid_view_rounded, size: 18),
                              ],
                            ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),

        if (_dobAnalyzed) ...[
          // Driver & Conductor Cards
          Row(
            children: [
              Expanded(
                child: _buildDobStatCard(
                  label: 'Driver Number',
                  labelHi: 'चालक संख्या',
                  labelGu: 'ડ્રાઇવર નંબર',
                  value: _driverNumber!,
                  color: AppColors.primary,
                  icon: Icons.directions_car_outlined,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildDobStatCard(
                  label: 'Conductor Number',
                  labelHi: 'संचालक संख्या',
                  labelGu: 'કન્ડક્ટર નંબર',
                  value: _conductorNumber!,
                  color: AppColors.vip,
                  icon: Icons.music_note_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildDobStatCard(
                  label: 'Kua Number',
                  labelHi: 'कुआ नंबर',
                  labelGu: 'કુઆ નંબર',
                  value: _kuaNumber!,
                  color:
                      _gender == 'Male'
                          ? const Color(0xFF1E88E5)
                          : const Color(0xFFE91E63),
                  icon:
                      _gender == 'Male'
                          ? Icons.shield_outlined
                          : Icons.auto_awesome_outlined,
                ),
              ),
              const SizedBox(width: 24),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 48),

          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              return Column(
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      if (_dobAnalyzed)
                        ElevatedButton.icon(
                          onPressed: _shareDOBAnalysis,
                          icon: const Icon(Icons.share_rounded),
                          label: const Text('Share Analysis'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.vip,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDynamicLoShuGrid(),
                        const SizedBox(width: 48),
                        Expanded(child: _buildLoShuPlanesSection()),
                      ],
                    )
                  else
                    Column(
                      children: [
                        Center(child: _buildDynamicLoShuGrid()),
                        const SizedBox(height: 48),
                        _buildLoShuPlanesSection(),
                      ],
                    ),
                ],
              );
            },
          ),
          if (_dcRelationship != null) ...[
            const SizedBox(height: 48),
            _buildRelationshipCard(),
          ],
          const SizedBox(height: 56),
          const Divider(height: 1),
          const SizedBox(height: 56),
        ] else if (_isDOBLoading)
          Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Analyzing numbers...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 80),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.grid_4x4_outlined,
                    size: 80,
                    color: Colors.grey[200],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Enter a date of birth to reveal the sacred Lo Shu Grid.',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 00),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manual Lo Shu Grid Input',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Staff can manually fill or override grid cells below.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  for (var c in _manualCellControllers.values) {
                    c.clear();
                  }
                });
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Clear Manual Grid'),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildManualGridTab(),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildRelationshipCard() {
    if (_dcRelationship == null) return const SizedBox.shrink();

    final stars = _dcRelationship!['stars'] ?? '';
    final meaningEn = _dcRelationship!['meaning_en'] ?? '';
    final meaningHi = _dcRelationship!['meaning_hi'] ?? '';
    final meaningGu = _dcRelationship!['meaning_gu'] ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.vip.withOpacity(0.2)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, AppColors.vip.withOpacity(0.02)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.vip.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Driver-Conductor Relationship',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'ડ્રાઇવર-કંડક્ટર સંબંધ (81 સંયોજનો)',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (stars.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.vip.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    stars,
                    style: const TextStyle(
                      color: AppColors.vip,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),
          _buildLangItem(
            'ENGLISH',
            meaningEn,
            AppColors.primary.withOpacity(0.1),
            AppColors.primary,
          ),
          const SizedBox(height: 24),
          _buildLangItem(
            'HINDI / हिंदी',
            meaningHi,
            Colors.orange.withOpacity(0.1),
            Colors.orange,
          ),
          const SizedBox(height: 24),
          _buildLangItem(
            'GUJARATI / ગુજરાતી',
            meaningGu,
            Colors.teal.withOpacity(0.1),
            Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildDobStatCard({
    required String label,
    required String labelHi,
    required String labelGu,
    required int value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$labelHi / $labelGu',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String label, IconData icon, Color color) {
    bool isSelected = _gender == label;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (_gender != label) {
            setState(() {
              _gender = label;
              _dobAnalyzed = false;
              _dobPresentNumbers = {};
              _driverNumber = null;
              _conductorNumber = null;
              _kuaNumber = null;
            });
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.grey[200]!,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? color : Colors.grey[400],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicLoShuGrid() {
    // Standard Lo Shu layout
    const gridOrder = [4, 9, 2, 3, 5, 7, 8, 1, 6];
    return Container(
      width: 320,
      height: 320,
      decoration: BoxDecoration(
        color: Colors.black, // Background for the grid lines
        border: Border.all(color: Colors.black, width: 4),
      ),
      child: GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        children:
            gridOrder
                .map(
                  (n) => _buildGridCell(
                    n,
                    isPresent: _dobPresentNumbers.contains(n),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildGridCell(int val, {required bool isPresent}) {
    final Map<int, Map<String, dynamic>> numberInfo = {
      4: {'name': 'RAHU', 'color': const Color(0xFFFF0000)}, // Pure Red
      9: {'name': 'MARS', 'color': const Color(0xFFC6E0B4)}, // Mint Green
      2: {'name': 'MOON', 'color': const Color(0xFFFFE699)}, // Yellow
      3: {'name': 'JUPITER', 'color': const Color(0xFFA9D08E)}, // Green
      5: {'name': 'MERCURY', 'color': const Color(0xFFDDEBF7)}, // Light Blue
      7: {'name': 'KETU', 'color': const Color(0xFF9BC2E6)}, // Cyanish Blue
      8: {'name': 'SATURN', 'color': const Color(0xFFF8CBAD)}, // Tan/Beige
      1: {'name': 'SUN', 'color': const Color(0xFFD9D9F3)}, // Lavender
      6: {'name': 'VENUS', 'color': const Color(0xFFFFF2CC)}, // Cream
    };

    final info = numberInfo[val]!;

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(color: info['color']),
      child: Opacity(
        opacity: 1.0, // Shows text ONLY if present
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$val',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                height: 1.1,
              ),
            ),
            Text(
              info['name'],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoShuPlanesSection() {
    final planes = [
      {
        'numbers': '492',
        'en': 'Mental Plane',
        'hi': 'मेंटल प्लेन',
        'gu': 'માનસિક સ્તર',
      },
      {
        'numbers': '357',
        'en': 'Emotional Plane',
        'hi': 'इમોશનલ પ્લેન',
        'gu': 'ભાવનાત્મક સ્તર',
      },
      {
        'numbers': '816',
        'en': 'Practical Plane',
        'hi': 'प्रैक्टिकल प्लेन',
        'gu': 'વ્યવહારિક સ્તર',
      },
      {
        'numbers': '438',
        'en': 'Thought Plane',
        'hi': 'थॉट प्लेन',
        'gu': 'વિચાર સ્તર',
      },
      {
        'numbers': '951',
        'en': 'Will Plane',
        'hi': 'વિલ પ્લેન',
        'gu': 'ઈચ્છા સ્તર',
      },
      {
        'numbers': '276',
        'en': 'Action Plane',
        'hi': 'एक्शन प्लेन',
        'gu': 'ક્રિયા સ્તર',
      },
      {
        'numbers': '456',
        'en': 'Golden Plane',
        'hi': 'ગોલ્ડન પ્લેન',
        'gu': 'સુવર્ણ સ્તર',
      },
      {'numbers': '258', 'en': 'Rajyog', 'hi': 'રાજયોગ', 'gu': 'રાજયોગ'},
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            color: const Color(0xFF008000),
            child: const Center(
              child: Text(
                'LO SHU GRID ALL PLANES',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children:
                  planes.map((plane) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 45,
                            child: Text(
                              plane['numbers']!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF008000),
                              ),
                            ),
                          ),
                          const Text(
                            ' - ',
                            style: TextStyle(
                              color: Color(0xFF008000),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              plane['en']!,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF008000),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              plane['hi']!,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF008000),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              plane['gu']!,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF008000),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --- NAME NUMEROLOGY TAB ---
  Widget _buildNameNumerologyTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputSection(
          'Name Numerology',
          'Calculate the power behind your identity.',
          _nameController,
          'Enter Full Name',
          _isNameLoading ? null : _analyzeName,
          _isNameLoading ? 'Analyzing...' : 'Calculate Power',
          Icons.person_outline,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.go,
        ),
        if (_nameAnalyzed) ...[
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: _shareNameAnalysis,
                icon: const Icon(Icons.share_outlined, size: 18),
                label: const Text('Share Result'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: _buildPremiumCard(
                    child: Column(
                      children: [
                        const Text(
                          'Destiny Root Number',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '$_nameRootNumber',
                          style: const TextStyle(
                            fontSize: 120,
                            fontWeight: FontWeight.bold,
                            color: AppColors.vip,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Root Meaning
                        if (_nameRootMeaning != null) ...[
                          _buildMeaningSection(
                            'Root Number Meaning ($_nameRootNumber)',
                            _nameRootMeaning!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else
          _buildEmptyAnalysisState(
            'Your identity holds a frequency. Discover it now.',
          ),
      ],
    );
  }

  Widget _buildMeaningSection(String title, Map<String, dynamic> meaning) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.vip, size: 20),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildLangItem(
          'ENGLISH',
          meaning['meaning_en'] ?? 'No data available',
          AppColors.primary.withOpacity(0.1),
          AppColors.primary,
        ),
        const SizedBox(height: 16),
        _buildLangItem(
          'HINDI / हिंदी',
          meaning['meaning_hi'] ?? 'डेटा उपलब्ध नहीं है',
          Colors.orange.withOpacity(0.1),
          Colors.orange,
        ),
        const SizedBox(height: 16),
        _buildLangItem(
          'GUJARATI / ગુજરાતી',
          meaning['meaning_gu'] ?? 'ડેટા ઉપલબ્ધ નથી',
          Colors.teal.withOpacity(0.1),
          Colors.teal,
        ),
      ],
    );
  }

  // --- REUSABLE COMPONENTS ---

  Widget _buildInputSection(
    String title,
    String subtitle,
    TextEditingController ctrl,
    String hint,
    VoidCallback? onAnalyze,
    String btnText,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.done,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  onSubmitted: onAnalyze != null ? (_) => onAnalyze() : null,
                  maxLength: 10,
                  decoration: InputDecoration(
                    hintText: hint,
                    counterText: "",
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                    prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.all(20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[100]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: onAnalyze,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 22,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  children: [
                    Text(
                      btnText,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard({required Widget child, double padding = 32}) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.vip.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: AppColors.vip.withOpacity(0.05),
            blurRadius: 40,
            spreadRadius: -5,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSuggestionBox(String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAnalysisState(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 80,
              color: Colors.grey[200],
            ),
            const SizedBox(height: 16),
            Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualGridTab() {
    return Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  color: const Color(0xFF00B050),
                  child: const Center(
                    child: Text(
                      'LOShUGRID',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(4),
                  color: Colors.black,
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: GridView.count(
                      crossAxisCount: 3,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      children:
                          [4, 9, 2, 3, 5, 7, 8, 1, 6].map((n) {
                            return _buildEditableGridCell(n);
                          }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableGridCell(int val) {
    final Map<int, Map<String, dynamic>> numberInfo = {
      4: {'name': 'RAHU', 'color': const Color(0xFFFF0000)},
      9: {'name': 'MARS', 'color': const Color(0xFFC6E0B4)},
      2: {'name': 'MOON', 'color': const Color(0xFFFFE699)},
      3: {'name': 'JUPITER', 'color': const Color(0xFFA9D08E)},
      5: {'name': 'MERCURY', 'color': const Color(0xFFDDEBF7)},
      7: {'name': 'KETU', 'color': const Color(0xFF9BC2E6)},
      8: {'name': 'SATURN', 'color': const Color(0xFFF8CBAD)},
      1: {'name': 'SUN', 'color': const Color(0xFFD9D9F3)},
      6: {'name': 'VENUS', 'color': const Color(0xFFFFF2CC)},
    };

    final info = numberInfo[val]!;
    final controller = _manualCellControllers[val]!;

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(color: info['color']),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.text,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              info['name'],
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareNameAnalysis() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || !_nameAnalyzed || _nameRootNumber == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preparing your name report...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final controller = ScreenshotController();
      final Uint8List? imageBytes = await controller.captureFromWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(600, double.maxFinite)),
          child: _buildNameShareableImage(),
        ),
        delay: const Duration(milliseconds: 300),
        targetSize: const Size(600, 1600),
      );

      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final imagePath =
            await File(
              '${directory.path}/name_analysis_${name.replaceAll(' ', '_')}.png',
            ).create();
        await imagePath.writeAsBytes(imageBytes);

        await Share.shareXFiles([
          XFile(imagePath.path),
        ], text: 'My Chaldean Name Analysis from Aank Sastra! ✨');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
      }
    }
  }

  Widget _buildNameShareableImage() {
    return Material(
      color: const Color(0xFFFBFBFE),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.vip.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.stars,
                    color: AppColors.vip,
                    size: 40,
                  ),
                ),
                const SizedBox(width: 20),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AANK SASTRA',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: AppColors.vip,
                      ),
                    ),
                    Text(
                      'Sacred Name Numerology',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 60),

            // Profile Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.vip.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  const Text(
                    'NAME ANALYZED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _nameController.text.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // Result Display
            _buildPremiumCard(
              child: Column(
                children: [
                  const Text(
                    'DESTINY ROOT NUMBER',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$_nameRootNumber',
                    style: const TextStyle(
                      fontSize: 120,
                      fontWeight: FontWeight.bold,
                      color: AppColors.vip,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Meaning
                  if (_nameRootMeaning != null) ...[
                    _buildMeaningSection(
                      'Universal Implication',
                      _nameRootMeaning!,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 60),

            // Footer
            const Divider(),
            const SizedBox(height: 40),
            Text(
              'Generated via Aank Sastra App',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Future<void> _shareDOBAnalysis() async {
    final dob = _dobController.text.trim();
    if (dob.isEmpty || !_dobAnalyzed || _driverNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please perform DOB analysis first')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preparing Lo Shu report...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final controller = ScreenshotController();
      const double estimatedHeight = 1500;

      final Uint8List? imageBytes = await controller.captureFromWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(600, double.maxFinite)),
          child: _buildDOBShareableImage(),
        ),
        delay: const Duration(milliseconds: 300),
        targetSize: const Size(600, estimatedHeight),
      );

      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final imagePath =
            await File(
              '${directory.path}/dob_analysis_${dob.replaceAll('/', '_')}.png',
            ).create();
        await imagePath.writeAsBytes(imageBytes);

        await Share.shareXFiles(
          [XFile(imagePath.path)],
          text:
              'My Lo Shu Grid Analysis from Aank Sastra! ✨ #Numerology #AankSastra',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
      }
    }
  }

  Widget _buildDOBShareableImage() {
    return Material(
      color: const Color(0xFFFBFBFE),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.vip.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.vip,
                    size: 40,
                  ),
                ),
                const SizedBox(width: 20),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AANK SASTRA',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: AppColors.vip,
                      ),
                    ),
                    Text(
                      'Sacred Numerology Analytics',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 60),

            // DOB Info
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.vip.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                    'Date of Birth',
                    _dobController.text,
                    Icons.calendar_today,
                  ),
                  _buildSummaryItem(
                    'Driver Number',
                    '$_driverNumber',
                    Icons.stars,
                  ),
                  _buildSummaryItem(
                    'Conductor',
                    '$_conductorNumber',
                    Icons.offline_bolt,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),

            // The Grid
            const Text(
              'YOUR LO SHU GRID',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 32),
            _buildDynamicLoShuGrid(),
            const SizedBox(height: 60),

            // Relationship
            if (_dcRelationship != null) ...[
              const Divider(),
              const SizedBox(height: 40),
              _buildRelationshipCard(),
              const SizedBox(height: 40),
            ],

            // Footer
            const Divider(),
            const SizedBox(height: 40),
            Text(
              'Generated via Aank Sastra App',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.vip, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.selection.baseOffset < oldValue.selection.baseOffset) {
      return newValue;
    }

    final text = newValue.text;
    final digitsOnly = text.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < digitsOnly.length; i++) {
      buffer.write(digitsOnly[i]);
      final index = i + 1;
      if ((index == 2 || index == 4) && index != digitsOnly.length) {
        buffer.write('/');
      }
    }

    if ((digitsOnly.length == 2 || digitsOnly.length == 4) &&
        text.length == digitsOnly.length) {
      buffer.write('/');
    }

    final finalString = buffer.toString();
    return TextEditingValue(
      text:
          finalString.length > 10 ? finalString.substring(0, 10) : finalString,
      selection: TextSelection.collapsed(offset: finalString.length),
    );
  }
}
