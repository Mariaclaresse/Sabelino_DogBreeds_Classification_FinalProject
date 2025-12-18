import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'firebase_options.dart';
import 'firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

const Color pawGreen = Color(0xFF9CAF88);
const Color pawDarkGreen = Color(0xFF7B9470);
const Color pawCream = Color(0xFFF5F5F0);
const Color pawLightGreen = Color(0xFFBBCFA5);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PawScan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: pawGreen),
        useMaterial3: true,
      ),
      home: const SplashPage(),
    );
  }
}

class DogBreed {
  final String name;
  final String description;
  final String imageUrl;
  final List<String> imageUrls;
  final String longDescription;
  final String size;
  final String weight;
  final String lifespan;
  final String temperament;
  final String energyLevel;

  const DogBreed({
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.longDescription,
    this.imageUrls = const [],
    this.size = 'Medium',
    this.weight = '20-30 lbs',
    this.lifespan = '10-14 years',
    this.temperament = 'Friendly',
    this.energyLevel = 'High',
  });
}

enum UploadSource { camera, gallery }

class Classification {
  final String scannedBreed;
  final String detectedBreed;
  final double confidence;
  final bool isCorrect;
  final DateTime timestamp;
  final UploadSource uploadSource;

  const Classification({
    required this.scannedBreed,
    required this.detectedBreed,
    required this.confidence,
    required this.isCorrect,
    required this.timestamp,
    this.uploadSource = UploadSource.camera,
  });

  Map<String, dynamic> toJson() => {
    'scannedBreed': scannedBreed,
    'detectedBreed': detectedBreed,
    'confidence': confidence,
    'isCorrect': isCorrect,
    'timestamp': timestamp.toIso8601String(),
    'uploadSource': uploadSource.toString(),
  };

  factory Classification.fromJson(Map<String, dynamic> json) {
    return Classification(
      scannedBreed: json['scannedBreed'] as String,
      detectedBreed: json['detectedBreed'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      isCorrect: json['isCorrect'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      uploadSource: json['uploadSource']?.toString().contains('gallery') ?? false 
          ? UploadSource.gallery 
          : UploadSource.camera,
    );
  }
}

Widget _buildBreedImage(String imageUrl, {double height = 120, BoxFit fit = BoxFit.cover}) {
  bool isLocalAsset = imageUrl.startsWith('assets/');
  
  if (isLocalAsset) {
    return Image.asset(
      imageUrl,
      height: height,
      width: double.infinity,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: height,
          width: double.infinity,
          color: pawGreen.withOpacity(0.1),
          child: Icon(
            Icons.pets,
            size: height > 150 ? 60 : 40,
            color: pawGreen,
          ),
        );
      },
    );
  } else {
    return Image.network(
      imageUrl,
      height: height,
      width: double.infinity,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: height,
          width: double.infinity,
          color: pawGreen.withOpacity(0.1),
          child: Icon(
            Icons.pets,
            size: height > 150 ? 60 : 40,
            color: pawGreen,
          ),
        );
      },
    );
  }
}

String _getBreedLogoPath(String breedName) {
  final breedLower = breedName.toLowerCase();
  
  final logoMap = {
    'pug': 'assets/pug_logo.png',
    'airedale': 'assets/airedale_logo.png',
    'cairn terrier': 'assets/cairn_logo.png',
    'chow chow': 'assets/chow_logo.png',
    'bernese': 'assets/bernese_logo.png',
    'beagle': 'assets/beagle_logo.png',
    'entlebucher': 'assets/entlebutcher_logo.png',
    'maltese': 'assets/maltese_logo.png',
    'silky terrier': 'assets/silky_logo.png',
    'tibetan terrier': 'assets/tibetan_logo.png',
  };
  
  return logoMap[breedLower] ?? 'assets/logo1.png';
}

Widget _buildFeatureBadge(String emoji, String label) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: pawGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: pawGreen.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: pawDarkGreen,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    ),
  );
}

final List<DogBreed> dogBreeds = [
  DogBreed(
    name: 'Airedale',
    description: 'Loyal terrier',
    imageUrl: 'assets/airedale.jpg',
    longDescription: 'The Airedale Terrier, often called the "King of Terriers," is known for its intelligence, courage, and energetic personality. This breed is highly adaptable, able to work, play, and protect with equal enthusiasm. Airedales are loyal family companions who love outdoor activities, especially running and exploring. Their wiry coat and alert expression reflect their confident and hardworking nature.',
    imageUrls: ['assets/airedale.jpg', 'assets/airedale1.jpg', 'assets/airedale2.jpg'],
    size: 'Large',
    weight: '50-70 lbs',
    lifespan: '11-14 years',
    temperament: 'Intelligent, Courageous',
    energyLevel: 'Very High',
  ),
  DogBreed(
    name: 'Beagle',
    description: 'Energetic hunter',
    imageUrl: 'assets/beagle.jpg',
    longDescription: 'The Beagle is a cheerful, curious, and energetic hunting dog famous for its excellent sense of smell and friendly disposition. This breed thrives on adventure and loves following interesting scents, making them natural explorers. Beagles are gentle, social, and great with families, often showing a playful and affectionate attitude toward both adults and children.',
    imageUrls: ['assets/beagle.jpg', 'assets/beagle1.jpg', 'assets/beagle2.jpg'],
    size: 'Small',
    weight: '20-30 lbs',
    lifespan: '12-15 years',
    temperament: 'Friendly, Curious',
    energyLevel: 'High',
  ),
  DogBreed(
    name: 'Bernese',
    description: 'Working dog',
    imageUrl: 'assets/bernese.jpg',
    longDescription: 'The Bernese Mountain Dog is a large and sturdy working breed known for its calm temperament, loyalty, and striking tri-colored coat. Originally bred to assist farmers in the Swiss Alps, this dog excels in tasks requiring strength and endurance. Bernese dogs are highly affectionate, gentle with children, and enjoy spending time with people, making them beloved family companions.',
    imageUrls: ['assets/bernese.jpg', 'assets/bernese2.jpg', 'assets/bernese1.jpg'],
    size: 'Large',
    weight: '70-115 lbs',
    lifespan: '7-10 years',
    temperament: 'Calm, Loyal',
    energyLevel: 'Moderate',
  ),
  DogBreed(
    name: 'Cairn Terrier',
    description: 'Scottish terrier',
    imageUrl: 'assets/cairn_terrier.jpg',
    longDescription: 'The Cairn Terrier is a spirited and hardy little dog originating from the rugged landscapes of Scotland. With a lively personality and a curious nature, they love exploring and engaging in play. Cairn Terriers are known for their boldness despite their small size, and they form strong bonds with their families. Their shaggy coat and expressive face give them a charming, mischievous look.',
    imageUrls: ['assets/cairn_terrier.jpg', 'assets/cairn_terrier1.jpg', 'assets/cairn_terrier2.jpg'],
    size: 'Small',
    weight: '13-18 lbs',
    lifespan: '13-15 years',
    temperament: 'Spirited, Bold',
    energyLevel: 'High',
  ),
  DogBreed(
    name: 'Chow Chow',
    description: 'Fluffy breed',
    imageUrl: 'assets/chow.jpg',
    longDescription: 'The Chow Chow is a distinctive and dignified breed known for its lion-like mane, deep-set eyes, and fluffy double coat. Despite their plush appearance, Chows are independent and reserved, often forming deep bonds with only a few people. They are loyal guardians with a calm presence, and their unique blue-black tongue adds to their mysterious and ancient charm.',
    imageUrls: ['assets/chow.jpg', 'assets/chow1.jpg', 'assets/chow2.jpg'],
    size: 'Medium-Large',
    weight: '45-70 lbs',
    lifespan: '9-15 years',
    temperament: 'Independent, Reserved',
    energyLevel: 'Moderate',
  ),
  DogBreed(
    name: 'Entlebucher',
    description: 'Mountain dog',
    imageUrl: 'assets/entlebutcher2.jpg',
    longDescription: 'The Entlebucher Mountain Dog is the smallest of Switzerland\'s herding breeds, known for its agility, intelligence, and hardworking character. Energetic and alert, this dog excels in activities that require quick thinking and endurance. Entlebuchers are loyal family dogs who bond closely with their owners and enjoy tasks that challenge both mind and body.',
    imageUrls: ['assets/entlebutcher2.jpg', 'assets/entlebutcher1.jpg', 'assets/entlebutcher.jpg'],
    size: 'Medium',
    weight: '55-65 lbs',
    lifespan: '11-15 years',
    temperament: 'Energetic, Intelligent',
    energyLevel: 'Very High',
  ),
  DogBreed(
    name: 'Maltese',
    description: 'Small white dog',
    imageUrl: 'assets/maltese.jpg',
    longDescription: 'The Maltese is a gentle, affectionate, and playful small dog known for its long, silky white coat and lively personality. Despite their elegant appearance, Maltese dogs are spirited and enjoy interactive play. They are deeply devoted to their owners and thrive on companionship, making them delightful lapdogs and loyal household pets.',
    imageUrls: ['assets/maltese.jpg', 'assets/maltese1.jpg', 'assets/maltese2.jpg'],
    size: 'Toy',
    weight: '4-7 lbs',
    lifespan: '12-15 years',
    temperament: 'Gentle, Affectionate',
    energyLevel: 'High',
  ),
  DogBreed(
    name: 'Pug',
    description: 'Compact toy breed',
    imageUrl: 'assets/pug.jpg',
    longDescription: 'The Pug is a charming and compact toy breed recognized by its wrinkled face, expressive eyes, and playful nature. Pugs are known for their loving and comical personalities, often entertaining their families with silly antics. They are affectionate, adaptable, and enjoy being the center of attention, making them great companions for both individuals and families.',
    imageUrls: ['assets/pug.jpg', 'assets/pug1.jpg', 'assets/pug2.jpg'],
    size: 'Toy',
    weight: '14-18 lbs',
    lifespan: '12-15 years',
    temperament: 'Playful, Affectionate',
    energyLevel: 'Moderate',
  ),
  DogBreed(
    name: 'Silky Terrier',
    description: 'Elegant terrier',
    imageUrl: 'assets/silky.jpg',
    longDescription: 'The Silky Terrier is a small yet confident breed with a fine, shiny coat and an elegant appearance. Despite their delicate look, they are energetic, curious, and spirited, always eager for adventure. Silkies are intelligent and affectionate, forming strong bonds with their families and enjoying both playful activities and quiet companionship.',
    imageUrls: ['assets/silky.jpg', 'assets/silky1.jpg', 'assets/silky2.jpg'],
    size: 'Small',
    weight: '8-10 lbs',
    lifespan: '12-15 years',
    temperament: 'Spirited, Intelligent',
    energyLevel: 'High',
  ),
  DogBreed(
    name: 'Tibetan Terrier',
    description: 'Rare Asian breed',
    imageUrl: 'assets/tibetan.jpg',
    longDescription: 'The Tibetan Terrier is a rare and ancient breed originating from the Himalayan mountains, where they served as loyal companions and watchdogs. With a soft, flowing coat and expressive eyes, they carry a charming and gentle presence. Tibetan Terriers are known for their balanced temperament playful yet calm and they form deep emotional connections with their owners.',
    imageUrls: ['assets/tibetan.jpg', 'assets/tibetan1.jpg', 'assets/tibetan2.jpg'],
    size: 'Medium',
    weight: '18-30 lbs',
    lifespan: '12-15 years',
    temperament: 'Playful, Calm',
    energyLevel: 'Moderate',
  ),
];

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pawCream,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 160),
            Container(
              width: 400,
              height: 230,
              child: Center(
                child: Image.asset(
                  'assets/logo2.png',
                  width: 400,
                ),
              ),
            ),   
            const SizedBox(height: 45),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  _FeatureBox(
                    icon: Icons.photo_camera,
                    title: 'Capture Photos',
                    description: 'Take or upload dog photos',
                  ),
                  const SizedBox(height: 15),
                  _FeatureBox(
                    icon: Icons.flash_on,
                    title: 'Instant Detection',
                    description: 'AI powered breed identification',
                  ),
                  const SizedBox(height: 15),
                  _FeatureBox(
                    icon: Icons.bar_chart,
                    title: 'Track Results',
                    description: 'View your scan history',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 35),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MainApp()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pawGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'GET STARTED',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _FeatureBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureBox({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: pawGreen.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: pawGreen, size: 30),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: pawDarkGreen,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;
  DogBreed? _selectedBreed;
  final List<Classification> _classifications = [];
  final AnalyticsService _analyticsService = AnalyticsService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClassifications();
  }

  Future<void> _loadClassifications() async {
    try {
      final loaded = await _analyticsService.loadClassifications();
      setState(() {
        _classifications.clear();
        _classifications.addAll(loaded);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveClassification(Classification classification) async {
    try {
      await _analyticsService.saveClassification(classification);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving classification: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: pawCream,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: pawGreen),
              const SizedBox(height: 16),
              const Text('Loading analytics...'),
            ],
          ),
        ),
      );
    }
    if (_selectedBreed != null) {
      return ClassifierPage(
        selectedBreed: _selectedBreed!,
        onBackPressed: () {
          setState(() {
            _selectedBreed = null;
          });
        },
        onClassificationComplete: (classification) {
          setState(() {
            _classifications.add(classification);
          });
          _saveClassification(classification);
        },
        onNavigate: (index) {
          setState(() {
            _selectedBreed = null;
            _currentIndex = index;
          });
        },
        classifications: _classifications,
      );
    }

    List<Widget> pages = [
      HistoryPage(
        onNavigate: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      HomePage(
        onNavigate: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        onBreedSelected: (breed) {
          setState(() {
            _selectedBreed = breed;
          });
        },
      ),
      AnalyticsPage(
        onNavigate: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        classifications: _classifications,
      ),
    ];

    return Scaffold(
      body: _currentIndex < 3 ? pages[_currentIndex] : pages[0],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: pawGreen,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withValues(alpha: 0.4),
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index < 3) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.feed), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: ''),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final Function(int) onNavigate;
  final Function(DogBreed) onBreedSelected;
  final List<Classification> classifications;

  const HomePage({
    required this.onNavigate,
    required this.onBreedSelected,
    this.classifications = const [],
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pawCream,
      appBar: AppBar(
        backgroundColor: pawGreen,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'Paw',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Scan',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const Spacer(),
            Image.asset(
                  'assets/logo3.png',
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                  ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Available Breeds',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: pawDarkGreen,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              width: 80,
                              height: 4,
                              decoration: BoxDecoration(
                                color: pawGreen,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Tap any breed to start classifying',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 15,
                        crossAxisSpacing: 15,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: dogBreeds.length,
                      itemBuilder: (context, index) {
                        return BreedCard(
                          breed: dogBreeds[index],
                          index: index,
                          onTap: () {
                            onBreedSelected(dogBreeds[index]);
                          },
                        );
                      },
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

class BreedCard extends StatefulWidget {
  final DogBreed breed;
  final VoidCallback onTap;
  final int index;

  const BreedCard({
    required this.breed,
    required this.onTap,
    required this.index,
    super.key,
  });

  @override
  State<BreedCard> createState() => _BreedCardState();
}

class _BreedCardState extends State<BreedCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onEnter() {
    setState(() => _isHovered = true);
    _controller.forward();
  }

  void _onExit() {
    setState(() => _isHovered = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: _onEnter,
      child: MouseRegion(
        onEnter: (_) => _onEnter(),
        onExit: (_) => _onExit(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: pawGreen.withValues(alpha: _isHovered ? 0.25 : 0.08),
                  blurRadius: _isHovered ? 20 : 10,
                  offset: Offset(0, _isHovered ? 8 : 4),
                  spreadRadius: _isHovered ? 2 : 0,
                ),
              ],
              border: Border.all(
                color: _isHovered ? pawGreen : pawGreen.withValues(alpha: 0.2),
                width: _isHovered ? 2 : 1.5,
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  flex: 2,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                    child: Stack(
                      children: [
                        _buildBreedImage(widget.breed.imageUrl, height: 150),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: pawGreen,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: const Icon(
                              Icons.pets,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          widget.breed.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: pawDarkGreen,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Container(
                          width: 30,
                          height: 3,
                          decoration: BoxDecoration(
                            color: pawGreen.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Text(
                          widget.breed.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: pawDarkGreen,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: pawGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class DogBreedDetailPage extends StatefulWidget {
  final DogBreed breed;
  final List<Classification> classifications;

  const DogBreedDetailPage({
    required this.breed,
    this.classifications = const [],
    super.key,
  });

  @override
  State<DogBreedDetailPage> createState() => _DogBreedDetailPageState();
}

class _DogBreedDetailPageState extends State<DogBreedDetailPage> {
  late PageController _imagePageController;
  late int _currentImageIndex;

  @override
  void initState() {
    super.initState();
    _currentImageIndex = 0;
    _imagePageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = widget.breed.imageUrls.isNotEmpty ? widget.breed.imageUrls : [widget.breed.imageUrl];
    
    return Scaffold(
      backgroundColor: pawCream,
      appBar: AppBar(
        backgroundColor: pawGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.breed.name,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 330,
                  child: PageView.builder(
                    controller: _imagePageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemCount: imageUrls.length,
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _buildBreedImage(imageUrls[index], height: 330),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      imageUrls.length,
                      (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _currentImageIndex ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _currentImageIndex ? pawGreen : Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.breed.name,
                          style: const TextStyle(
                            fontSize: 35,
                            fontWeight: FontWeight.w800,
                            color: pawDarkGreen,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Image.asset(
                        _getBreedLogoPath(widget.breed.name),
                        width: 70,
                        height: 70,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox(width: 60, height: 60);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Container(
                    height: 4,
                    width: 90,
                    decoration: BoxDecoration(
                      color: pawGreen,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.breed.longDescription,
                    style: TextStyle(
                      fontSize: 14.5,
                      color: Colors.grey[700],
                      height: 1.7,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Row(
                          children: [
                            Icon(Icons.info_outline, color: pawGreen, size: 28),
                            const SizedBox(width: 10),
                            Text(
                              '${widget.breed.name} Stats',
                              style: const TextStyle(
                                color: pawDarkGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _StatRow('Size :', widget.breed.size),
                              const SizedBox(height: 12),
                              _StatRow('Weight :', widget.breed.weight),
                              const SizedBox(height: 12),
                              _StatRow('Lifespan :', widget.breed.lifespan),
                              const SizedBox(height: 12),
                              _StatRow('Character :', widget.breed.temperament),
                              const SizedBox(height: 12),
                              _StatRow('Energy Level :', widget.breed.energyLevel),
                            ],
                          ),
                        ),
                        actions: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: pawGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'CLOSE',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.menu, color: pawGreen),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: pawGreen, width: 1.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClassifierPage(
                            selectedBreed: widget.breed,
                            onBackPressed: () => Navigator.pop(context),
                            onClassificationComplete: (classification) {},
                            classifications: widget.classifications,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pawGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Classify Breed',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class HistoryPage extends StatelessWidget {
  final Function(int) onNavigate;

  const HistoryPage({
    required this.onNavigate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pawCream,
      appBar: AppBar(
        backgroundColor: pawGreen,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'Paw',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Scan',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const Spacer(),
            Image.asset(
                  'assets/logo3.png',
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                  ),
          ],
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        itemCount: dogBreeds.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.white.withValues(alpha: 0.90),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: pawGreen.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                    spreadRadius: 1,
                  ),
                ],
                border: Border.all(
                  color: pawGreen.withValues(alpha: 0.08),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 32,
                          decoration: BoxDecoration(
                            color: pawGreen,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Dog Breed Classification',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: pawDarkGreen,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              Text(
                                'Advanced AI Technology',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: pawGreen,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: pawGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: pawGreen.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.pets,
                            color: pawGreen,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            pawGreen,
                            pawGreen.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'PawScan uses advanced machine learning to classify dog breeds from images. Fast and easy to use for pet lovers.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.grey[600],
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          final breed = dogBreeds[index - 1];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DogBreedDetailPage(breed: breed),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: _buildBreedImage(breed.imageUrl, height: 210),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          breed.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: pawDarkGreen,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          breed.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}



class ClassifierPage extends StatefulWidget {
  final DogBreed selectedBreed;
  final VoidCallback onBackPressed;
  final Function(Classification) onClassificationComplete;
  final Function(int)? onNavigate;
  final List<Classification> classifications;

  const ClassifierPage({
    required this.selectedBreed,
    required this.onBackPressed,
    required this.onClassificationComplete,
    this.onNavigate,
    this.classifications = const [],
    super.key,
  });

  @override
  State<ClassifierPage> createState() => _ClassifierPageState();
}

class _ClassifierPageState extends State<ClassifierPage> {
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseService _firebaseService = FirebaseService();
  File? _selectedImage;
  String _result = 'Select an image to classify';
  String _resultMessage = '';
  double _confidence = 0.0;
  bool _isLoading = false;
  bool _showSyncSuccess = false;
  bool _isSyncing = false;
  Classification? _currentClassification;
  late Interpreter _interpreter;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model_unquant.tflite');
    } catch (e) {
      setState(() {
        _result = 'Error loading model: $e';
      });
    }
  }

  Map<String, dynamic> _getBreedAnalytics() {
    final breedClassifications = widget.classifications
        .where((c) => c.scannedBreed == widget.selectedBreed.name)
        .toList();
    
    final total = breedClassifications.length;
    final correct = breedClassifications.where((c) => c.isCorrect).length;
    final accuracy = total > 0 ? (correct / total * 100) : 0.0;
    
    return {
      'total': total,
      'correct': correct,
      'accuracy': accuracy,
    };
  }

  double _calibrateConfidence(double rawConfidence) {
    const double temperatureFactor = 1.5;
    const double scaleFactor = 0.8;
    
    if (rawConfidence < 0.1) return rawConfidence;
    
    double calibrated = (rawConfidence - 1.0) / temperatureFactor + 1.0;
    calibrated = calibrated.clamp(0.0, 1.0);
    calibrated = calibrated * scaleFactor + (rawConfidence * 0.2);
    
    return calibrated.clamp(0.0, 1.0);
  }

  Widget _buildBreedAccuracyStats() {
    final analytics = _getBreedAnalytics();
    final total = analytics['total'] as int;
    final correct = analytics['correct'] as int;
    final accuracy = analytics['accuracy'] as double;

    return Column(
      children: [
        Text(
          'Breed Statistics',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  color: pawGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: pawGreen.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      total.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: pawDarkGreen,
                      ),
                    ),
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  color: pawGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: pawGreen.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      correct.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: pawDarkGreen,
                      ),
                    ),
                    Text(
                      'Correct',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  color: pawGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: pawGreen.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '${accuracy.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: pawDarkGreen,
                      ),
                    ),
                    Text(
                      'Accuracy',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _classifyImage(File imageFile, {UploadSource uploadSource = UploadSource.camera}) async {
    setState(() {
      _isLoading = true;
      _selectedImage = imageFile;
    });

    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        setState(() {
          _result = 'Could not load image';
          _isLoading = false;
        });
        return;
      }

      final resized = img.copyResize(image, width: 224, height: 224);

      List<List<List<num>>> inputData = [];
      for (int y = 0; y < 224; y++) {
        List<List<num>> row = [];
        for (int x = 0; x < 224; x++) {
          final pixel = resized.getPixelSafe(x, y);
          row.add([pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0]);
        }
        inputData.add(row);
      }

      var output = [List<double>.filled(10, 0.0)];
      _interpreter.run([inputData], output);

      List<double> predictions = output[0];
      
      int selectedBreedIndex = dogBreeds.indexWhere((breed) => breed.name == widget.selectedBreed.name);
      double selectedConfidence = selectedBreedIndex >= 0 ? predictions[selectedBreedIndex] : 0.0;
      
      double calibratedConfidence = _calibrateConfidence(selectedConfidence);
      
      int detectedIndex = 0;
      double maxConfidence = predictions[0];
      for (int i = 1; i < predictions.length; i++) {
        if (predictions[i] > maxConfidence) {
          maxConfidence = predictions[i];
          detectedIndex = i;
        }
      }

      String detectedBreedName = dogBreeds[detectedIndex].name;

      bool isCorrect = detectedBreedName == widget.selectedBreed.name;
      final classification = Classification(
        scannedBreed: widget.selectedBreed.name,
        detectedBreed: detectedBreedName,
        confidence: calibratedConfidence.clamp(0.0, 1.0),
        isCorrect: isCorrect,
        timestamp: DateTime.now(),
        uploadSource: uploadSource,
      );

      setState(() {
        _result = widget.selectedBreed.name;
        _confidence = calibratedConfidence.clamp(0.0, 1.0);
        _currentClassification = classification;
        
        if (isCorrect) {
          _resultMessage = 'This is a ${widget.selectedBreed.name}!';
        } else {
          _resultMessage = "This isn't ${widget.selectedBreed.name}, it's a $detectedBreedName";
        }
        
        _isLoading = false;
      });

      widget.onClassificationComplete(classification);
    } catch (e) {
      setState(() {
        _result = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        final uploadSource = source == ImageSource.camera 
            ? UploadSource.camera 
            : UploadSource.gallery;
        _classifyImage(File(image.path), uploadSource: uploadSource);
      }
    } catch (e) {
      setState(() {
        _result = 'Error picking image: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pawCream,
      appBar: AppBar(
        backgroundColor: pawGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => widget.onBackPressed(),
        ),
        title: Text(
          widget.selectedBreed.name,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                _selectedImage = null;
                _result = 'Select an image to classify';
                _resultMessage = '';
                _confidence = 0.0;
                _showSyncSuccess = false;
              });
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Colors.white),
            onSelected: (value) {
              if (value == 'analytics') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AnalyticsPage(
                      onNavigate: (index) {
                        Navigator.of(context).pop();
                        widget.onBackPressed();
                      },
                      classifications: widget.classifications,
                      breedFilter: widget.selectedBreed.name,
                    ),
                  ),
                );
              } else if (value == 'cloud') {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Firebase'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: pawGreen,
                            minimumSize: Size(double.infinity, 48),
                          ),
                          child: Text('Reconnect', style: TextStyle(color: Colors.white)),
                        ),
                        SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _selectedImage != null && _currentClassification != null
                              ? () async {
                                  Navigator.pop(context);
                                  setState(() {
                                    _isSyncing = true;
                                  });

                                  try {
                                    await _firebaseService.syncClassification(
                                      breedName: _currentClassification!.scannedBreed,
                                      detectedBreed: _currentClassification!.detectedBreed,
                                      confidence: _currentClassification!.confidence,
                                      timestamp: _currentClassification!.timestamp,
                                      isCorrect: _currentClassification!.isCorrect,
                                    );

                                    if (mounted) {
                                      setState(() {
                                        _showSyncSuccess = true;
                                        _isSyncing = false;
                                      });
                                      Future.delayed(Duration(seconds: 2), () {
                                        if (mounted) {
                                          setState(() {
                                            _showSyncSuccess = false;
                                          });
                                        }
                                      });
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      setState(() {
                                        _isSyncing = false;
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Sync failed: ${e.toString()}'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: pawGreen,
                            minimumSize: Size(double.infinity, 48),
                          ),
                          child: Text(
                            _isSyncing ? 'Syncing...' : 'Sync',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            minimumSize: Size(double.infinity, 48),
                          ),
                          child: Text('Close', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'analytics',
                child: Row(
                  children: [
                    Icon(Icons.analytics, color: pawGreen),
                    SizedBox(width: 8),
                    Text('Analytics'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'cloud',
                child: Row(
                  children: [
                    Icon(Icons.cloud, color: pawGreen),
                    SizedBox(width: 8),
                    Text('Firebase Sync'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: _showSyncSuccess
            ? PreferredSize(
                preferredSize: Size.fromHeight(40),
                child: Container(
                  color: Colors.green,
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Synced Successfully!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(19),
                child: Column(
                  children: [
                    const SizedBox(height: 5),
                    const SizedBox(height: 2),
                    if (_selectedImage != null)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: pawGreen,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.file(
                            _selectedImage!,
                            width: 370,
                            height: 440,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 370,
                        height: 440,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: pawGreen,
                            width: 2,
                          ),
                          color: Colors.white,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/upload.jpg',
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    const SizedBox(height: 25),
                    if (_isLoading)
                      const SizedBox(
                        height: 50,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: pawGreen,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _result == 'Not a Dog' ? Colors.red.withOpacity(0.08) : pawGreen.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _result == 'Not a Dog' ? Colors.red.withOpacity(0.5) : pawGreen.withOpacity(0.5),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_result == 'Not a Dog' ? Colors.red : pawGreen).withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _result == 'Not a Dog' ? Icons.close_rounded : Icons.check_circle_rounded,
                                  color: _result == 'Not a Dog' ? Colors.red : pawGreen,
                                  size: 16,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _result == 'Not a Dog' ? 'No Match' : 'Match Found',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _result == 'Not a Dog' ? Colors.red : pawDarkGreen,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _result,
                              style: TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w900,
                                color: _result == 'Not a Dog' ? Colors.red : pawDarkGreen,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 7),
                            Text(
                              _resultMessage,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w800,
                                height: 0.1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_confidence > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 15),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'Confidence',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${(_confidence * 100).toStringAsFixed(1)}%',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: pawGreen,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(10),
                                                child: LinearProgressIndicator(
                                                  value: _confidence,
                                                  minHeight: 8,
                                                  backgroundColor: Colors.grey[300],
                                                  valueColor: const AlwaysStoppedAnimation<Color>(pawGreen),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'Your Accuracy',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  Builder(
                                                    builder: (context) {
                                                      final analytics = _getBreedAnalytics();
                                                      final accuracy = (analytics['accuracy'] as double) / 100;
                                                      return Text(
                                                        '${(accuracy * 100).toStringAsFixed(0)}%',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: pawGreen,
                                                          fontWeight: FontWeight.w800,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Builder(
                                                builder: (context) {
                                                  final analytics = _getBreedAnalytics();
                                                  final accuracy = (analytics['accuracy'] as double) / 100;
                                                  return ClipRRect(
                                                    borderRadius: BorderRadius.circular(10),
                                                    child: LinearProgressIndicator(
                                                      value: accuracy,
                                                      minHeight: 8,
                                                      backgroundColor: Colors.grey[300],
                                                      valueColor: const AlwaysStoppedAnimation<Color>(pawDarkGreen),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: const Text(
                      'Camera',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pawGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.image, color: pawGreen),
                    label: const Text(
                      'Gallery',
                      style: TextStyle(
                        color: pawGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: pawGreen, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _interpreter.close();
    super.dispose();
  }
}

class AnalyticsPage extends StatefulWidget {
  final Function(int) onNavigate;
  final List<Classification> classifications;
  final String? breedFilter;

  const AnalyticsPage({
    required this.onNavigate,
    required this.classifications,
    this.breedFilter,
    super.key,
  });

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final AnalyticsService _analyticsService = AnalyticsService();
  bool _isSaving = false;

  Future<void> _saveAnalytics() async {
    setState(() => _isSaving = true);
    try {
      for (var classification in widget.classifications) {
        await _analyticsService.saveClassification(classification);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Analytics saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving analytics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => _isSaving = false);
  }

  Future<void> _deleteAllAnalytics() async {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete All Analytics'),
        content: const Text('Are you sure you want to delete all classifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _analyticsService.clearAllClassifications();
                if (mounted) {
                  Navigator.of(context).pop();
                  setState(() {
                    widget.classifications.clear();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All analytics deleted!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting analytics: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredClassifications = widget.breedFilter != null
        ? widget.classifications.where((c) => c.scannedBreed == widget.breedFilter).toList()
        : widget.classifications;

    return Scaffold(
      backgroundColor: pawCream,
      appBar: AppBar(
        backgroundColor: pawGreen,
        elevation: 0,
        leading: filteredClassifications.isNotEmpty
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'save') {
                    _saveAnalytics();
                  } else if (value == 'delete') {
                    _deleteAllAnalytics();
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'save',
                    enabled: !_isSaving,
                    child: Row(
                      children: [
                        Icon(Icons.save, color: pawGreen, size: 25),
                        const SizedBox(width: 12),
                        Text(_isSaving ? 'Saving...' : 'Save Analytics'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, color: Colors.red, size: 25),
                        const SizedBox(width: 12),
                        const Text('Delete All'),
                      ],
                    ),
                  ),
                ],
                icon: const Icon(Icons.menu, color: Colors.white),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => widget.onNavigate(0),
              ),
        title: Row(
          children: [
            widget.breedFilter != null
                ? Text(
                    widget.breedFilter!,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    children: [
                      const Text(
                        'Paw',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Scan',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
            const Spacer(),
            Image.asset(
              'assets/logo3.png',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
      body: filteredClassifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 64,
                    color: pawGreen.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Classifications Yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Classify some images to see analytics',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BasicStatsSection(classifications: filteredClassifications),
                  const SizedBox(height: 24),
                  _AccuracySection(classifications: filteredClassifications),
                  const SizedBox(height: 24),
                  _UploadTypeSection(classifications: filteredClassifications),
                  const SizedBox(height: 24),
                  _ConfidenceDistributionSection(classifications: filteredClassifications),
                  const SizedBox(height: 24),
                  if (widget.breedFilter == null) ...[
                    _DailyActivitySection(classifications: filteredClassifications),
                    const SizedBox(height: 24),
                  ],
                  _MisclassificationsSection(classifications: filteredClassifications),
                  const SizedBox(height: 24),
                  if (widget.breedFilter == null) ...[
                    _ScanAnalyticsSection(classifications: filteredClassifications),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final List<Classification> classifications;

  const _StatsGrid({required this.classifications});

  @override
  Widget build(BuildContext context) {
    int total = classifications.length;
    int correct = classifications.where((c) => c.isCorrect).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: pawDarkGreen,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _StatCard(
              title: 'Total Classifications',
              value: total.toString(),
              icon: Icons.image_search,
            ),
            _StatCard(
              title: 'Correct',
              value: '$correct/$total',
              icon: Icons.verified,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: pawGreen, size: 24),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: pawDarkGreen,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}



class _ClassesBreakdown extends StatelessWidget {
  final List<Classification> classifications;

  const _ClassesBreakdown({required this.classifications});

  @override
  Widget build(BuildContext context) {
    Map<String, List<Classification>> breedClassifications = {};
    
    for (var breed in dogBreeds) {
      breedClassifications[breed.name] = [];
    }
    
    for (var c in classifications) {
      if (breedClassifications.containsKey(c.scannedBreed)) {
        breedClassifications[c.scannedBreed]!.add(c);
      }
    }

    int maxCount = 0;
    for (var classifs in breedClassifications.values) {
      if (classifs.isNotEmpty) {
        int total = classifs.length;
        if (total > maxCount) maxCount = total;
      }
    }
    if (maxCount == 0) maxCount = 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Breed Insights',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: pawDarkGreen,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                dogBreeds.length,
                (index) {
                  final breed = dogBreeds[index];
                  final classifs = breedClassifications[breed.name] ?? [];
                  
                  final correct = classifs.where((c) => c.isCorrect).toList();
                  final incorrect = classifs.where((c) => !c.isCorrect).toList();
                  
                  final correctCount = correct.length;
                  final incorrectCount = incorrect.length;
                  
                  final correctAvgConfidence = correct.isEmpty
                      ? 0.0
                      : correct.map((c) => c.confidence).reduce((a, b) => a + b) / correct.length;
                  final incorrectAvgConfidence = incorrect.isEmpty
                      ? 0.0
                      : incorrect.map((c) => c.confidence).reduce((a, b) => a + b) / incorrect.length;
                  
                  final correctHeight = (correctCount / maxCount) * 200;
                  final incorrectHeight = (incorrectCount / maxCount) * 200;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  width: 28,
                                  height: correctHeight,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4),
                                      topRight: Radius.circular(4),
                                    ),
                                  ),
                                  child: correctCount > 0
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                correctCount.toString(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                              if (correctHeight > 40)
                                                Text(
                                                  '${(correctAvgConfidence * 100).toStringAsFixed(0)}%',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 8,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        )
                                      : null,
                                ),
                              ],
                            ),
                            const SizedBox(width: 4),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  width: 28,
                                  height: incorrectHeight,
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4),
                                      topRight: Radius.circular(4),
                                    ),
                                  ),
                                  child: incorrectCount > 0
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                incorrectCount.toString(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                              if (incorrectHeight > 40)
                                                Text(
                                                  '${(incorrectAvgConfidence * 100).toStringAsFixed(0)}%',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 8,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 60,
                          child: Text(
                            breed.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: pawDarkGreen,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Correct',
              style: TextStyle(fontSize: 12, color: pawDarkGreen, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 24),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Incorrect',
              style: TextStyle(fontSize: 12, color: pawDarkGreen, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}

class _DogBreedsBreakdown extends StatelessWidget {
  final List<Classification> classifications;

  const _DogBreedsBreakdown({required this.classifications});

  @override
  Widget build(BuildContext context) {
    Map<String, int> breedCounts = {};
    
    for (var breed in dogBreeds) {
      breedCounts[breed.name] = 0;
    }
    
    for (var c in classifications) {
      breedCounts[c.scannedBreed] = (breedCounts[c.scannedBreed] ?? 0) + 1;
    }

    int total = classifications.length;

    final sortedBreeds = dogBreeds.toList()
      ..sort((a, b) => (breedCounts[b.name] ?? 0).compareTo(breedCounts[a.name] ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Classes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: pawDarkGreen,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedBreeds.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey[200],
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              final breed = sortedBreeds[index];
              final count = breedCounts[breed.name] ?? 0;
              final percentage = total == 0 ? 0.0 : (count / total);

              return Padding(
                key: ValueKey(breed.name),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            breed.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: pawDarkGreen,
                            ),
                          ),
                        ),
                        Text(
                          '${(percentage * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: pawGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage,
                        minHeight: 6,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(pawGreen),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$count image${count != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ClassificationHistory extends StatelessWidget {
  final List<Classification> classifications;

  const _ClassificationHistory({required this.classifications});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Classification History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: pawDarkGreen,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: classifications.length,
          reverse: true,
          itemBuilder: (context, index) {
            final c = classifications[index];
            return Container(
              key: ValueKey('${c.scannedBreed}_${c.detectedBreed}_${c.timestamp}'),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.isCorrect
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      c.isCorrect ? Icons.check : Icons.close,
                      color: c.isCorrect ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scanned: ${c.scannedBreed}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: pawDarkGreen,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Detected: ${c.detectedBreed}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(c.timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(c.confidence * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: pawGreen,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        c.isCorrect ? 'Correct' : 'Wrong',
                        style: TextStyle(
                          fontSize: 11,
                          color: c.isCorrect ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class _BasicStatsSection extends StatelessWidget {
  final List<Classification> classifications;
  final AnalyticsService _analyticsService = AnalyticsService();

  _BasicStatsSection({required this.classifications});

  @override
  Widget build(BuildContext context) {
    final total = _analyticsService.getTotalClassifications(classifications);
    final correct = classifications.where((c) => c.isCorrect).length;
    final accuracy = _analyticsService.getOverallAccuracy(classifications);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Overall Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: pawDarkGreen)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _StatBox('Total', total.toString(), Icons.image_search),
              _StatBox('Correct', correct.toString(), Icons.check_circle),
              _StatBox('Accuracy', '${accuracy.toStringAsFixed(1)}%', Icons.trending_up),
            ],
          ),
        ],
      ),
    );
  }

  Widget _StatBox(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: pawGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: pawGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: pawGreen, size: 24),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: pawDarkGreen)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }
}



class _AccuracySection extends StatelessWidget {
  final List<Classification> classifications;
  final AnalyticsService _analyticsService = AnalyticsService();

  _AccuracySection({required this.classifications});

  @override
  Widget build(BuildContext context) {
    final perBreedAccuracy = _analyticsService.getPerBreedAccuracy(classifications);
    if (perBreedAccuracy.isEmpty) return const SizedBox.shrink();

    final sorted = perBreedAccuracy.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, pawCream],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: pawGreen.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: pawGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.grade,
                  color: pawGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Per-Breed Accuracy',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: pawDarkGreen,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: sorted.map((e) {
                final color = e.value >= 90 ? Colors.green : e.value >= 70 ? Colors.orange : Colors.red;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: color, width: 3),
                        ),
                        child: Center(
                          child: Text(
                            '${e.value.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: 75,
                        child: Text(
                          e.key,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: pawDarkGreen,
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
}

class _UploadTypeSection extends StatelessWidget {
  final List<Classification> classifications;
  final AnalyticsService _analyticsService = AnalyticsService();

  _UploadTypeSection({required this.classifications});

  @override
  Widget build(BuildContext context) {
    final distribution = _analyticsService.getUploadTypeDistribution(classifications);
    final total = distribution['camera']! + distribution['gallery']!;
    if (total == 0) return const SizedBox.shrink();

    final cameraPercent = (distribution['camera']! / total) * 100;
    final galleryPercent = (distribution['gallery']! / total) * 100;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, pawCream],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: pawGreen.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: pawGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.upload,
                  color: pawGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Upload Type Distribution',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: pawDarkGreen,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: PieChart(
                            PieChartData(
                              sections: [
                                PieChartSectionData(
                                  value: cameraPercent,
                                  color: Colors.blue,
                                  title: '${cameraPercent.toStringAsFixed(0)}%',
                                  titleStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                PieChartSectionData(
                                  value: galleryPercent,
                                  color: Colors.orange,
                                  title: '${galleryPercent.toStringAsFixed(0)}%',
                                  titleStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Camera',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: pawDarkGreen,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${distribution['camera']}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Gallery',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: pawDarkGreen,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${distribution['gallery']}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfidenceDistributionSection extends StatelessWidget {
  final List<Classification> classifications;
  final AnalyticsService _analyticsService = AnalyticsService();

  _ConfidenceDistributionSection({required this.classifications});

  @override
  Widget build(BuildContext context) {
    final distribution = _analyticsService.getConfidenceDistribution(classifications);
    final total = distribution.values.reduce((a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final colors = [Colors.green, Colors.blue, Colors.orange, Colors.red];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, pawCream],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: pawGreen.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: pawGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.show_chart,
                  color: pawGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Confidence Distribution',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: pawDarkGreen,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: distribution.entries.toList().asMap().entries.map((e) {
              final index = e.key;
              final entry = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors[index].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors[index],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: pawDarkGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${entry.value}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colors[index],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _DailyActivitySection extends StatelessWidget {
  final List<Classification> classifications;
  
  _DailyActivitySection({required this.classifications});

  @override
  Widget build(BuildContext context) {
    if (classifications.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final dailyData = <int, int>{};
    
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      dailyData[i] = classifications
          .where((c) => c.timestamp.year == date.year && 
                        c.timestamp.month == date.month && 
                        c.timestamp.day == date.day)
          .length;
    }

    final dayNames = <String>[];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      dayNames.add(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1]);
    }

    final spots = <FlSpot>[];
    int maxCount = 1;
    for (int i = 6; i >= 0; i--) {
      spots.add(FlSpot(6 - i.toDouble(), dailyData[i]?.toDouble() ?? 0));
      maxCount = max(maxCount, dailyData[i] ?? 0);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, pawCream],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: pawGreen.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: pawGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: pawGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Daily Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: pawDarkGreen,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxCount > 0 ? maxCount / 4 : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: pawGreen.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < dayNames.length) {
                          return Text(
                            dayNames[index],
                            style: const TextStyle(
                              color: pawDarkGreen,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(
                            color: pawDarkGreen,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        );
                      },
                      interval: maxCount > 0 ? maxCount / 4 : 1,
                      reservedSize: 30,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: pawGreen.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: maxCount.toDouble(),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [pawGreen, pawLightGreen],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: pawGreen,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          pawGreen.withOpacity(0.3),
                          pawLightGreen.withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MisclassificationsSection extends StatelessWidget {
  final List<Classification> classifications;
  final AnalyticsService _analyticsService = AnalyticsService();

  _MisclassificationsSection({required this.classifications});

  @override
  Widget build(BuildContext context) {
    final misclassifications = _analyticsService.getMisclassifications(classifications);
    if (misclassifications.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 32, color: Colors.green),
            const SizedBox(height: 12),
            const Text(
              'No Misclassifications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: pawDarkGreen,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'All classifications were correct',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    final sortedMisclassifications = misclassifications.entries.toList()
        ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: pawGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.analytics,
                      color: pawGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Most Misclassified Breeds',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: pawDarkGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${sortedMisclassifications.length} breeds with issues',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...sortedMisclassifications.map((breedEntry) {
                final totalMisclassifications = breedEntry.value.fold<int>(0, (sum, e) => sum + e.value);
                final topError = breedEntry.value.isNotEmpty ? breedEntry.value.first : null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: pawGreen.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: pawGreen.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      collapsedBackgroundColor: Colors.transparent,
                      backgroundColor: pawGreen.withOpacity(0.03),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      collapsedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: pawGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              breedEntry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: pawDarkGreen,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: pawGreen.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$totalMisclassifications issues',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: pawGreen,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: pawGreen.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.expand_more,
                          color: pawGreen,
                          size: 20,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mistaken classifications:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...breedEntry.value.take(3).map((e) {
                                final percentage = (e.value / totalMisclassifications * 100).toStringAsFixed(1);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration: BoxDecoration(
                                                    color: pawGreen.withOpacity(0.6),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Mistaken as: ${e.key}',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[800],
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '${e.value}x',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: pawGreen,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              Text(
                                                '$percentage%',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey[500],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: e.value / totalMisclassifications,
                                          minHeight: 4,
                                          backgroundColor: pawGreen.withOpacity(0.1),
                                          valueColor: const AlwaysStoppedAnimation<Color>(pawGreen),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              if (breedEntry.value.length > 3)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(
                                    '+ ${breedEntry.value.length - 3} more',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
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
    );
  }
}

class AnalyticsService {
  static const String _classificationsKey = 'classifications_data';
  static final AnalyticsService _instance = AnalyticsService._internal();

  AnalyticsService._internal();

  factory AnalyticsService() {
    return _instance;
  }

  Future<void> saveClassification(Classification classification) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> classifications = prefs.getStringList(_classificationsKey) ?? [];
    final classificationJson = jsonEncode(classification.toJson());
    
    if (!classifications.contains(classificationJson)) {
      classifications.add(classificationJson);
      await prefs.setStringList(_classificationsKey, classifications);
    }
  }

  Future<List<Classification>> loadClassifications() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? classifications = prefs.getStringList(_classificationsKey);
    if (classifications == null) return [];
    return classifications.map((c) => Classification.fromJson(jsonDecode(c))).toList();
  }

  Future<void> clearAllClassifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_classificationsKey);
  }

  int getTotalClassifications(List<Classification> classifications) {
    return classifications.length;
  }

  List<MapEntry<String, int>> getTopBreeds(List<Classification> classifications, {int limit = 3}) {
    Map<String, int> breedCounts = {};
    for (var c in classifications) {
      breedCounts[c.detectedBreed] = (breedCounts[c.detectedBreed] ?? 0) + 1;
    }
    var sorted = breedCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  double getOverallAccuracy(List<Classification> classifications) {
    if (classifications.isEmpty) return 0.0;
    int correct = classifications.where((c) => c.isCorrect).length;
    return (correct / classifications.length) * 100;
  }

  Map<String, double> getPerBreedAccuracy(List<Classification> classifications) {
    Map<String, List<Classification>> breedClassifications = {};
    for (var breed in dogBreeds) {
      breedClassifications[breed.name] = [];
    }
    for (var c in classifications) {
      if (breedClassifications.containsKey(c.scannedBreed)) {
        breedClassifications[c.scannedBreed]!.add(c);
      }
    }

    Map<String, double> accuracy = {};
    breedClassifications.forEach((breed, classifs) {
      if (classifs.isNotEmpty) {
        int correct = classifs.where((c) => c.isCorrect).length;
        accuracy[breed] = (correct / classifs.length) * 100;
      }
    });
    return accuracy;
  }

  Map<String, int> getUploadTypeDistribution(List<Classification> classifications) {
    int cameraCount = classifications.where((c) => c.uploadSource == UploadSource.camera).length;
    int galleryCount = classifications.where((c) => c.uploadSource == UploadSource.gallery).length;
    return {'camera': cameraCount, 'gallery': galleryCount};
  }

  Map<String, int> getDailyActivityCounts(List<Classification> classifications, {int days = 7}) {
    Map<String, int> dailyCounts = {};
    final now = DateTime.now();
    
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      dailyCounts[dateStr] = 0;
    }

    for (var c in classifications) {
      final dateStr = '${c.timestamp.year}-${c.timestamp.month.toString().padLeft(2, '0')}-${c.timestamp.day.toString().padLeft(2, '0')}';
      if (dailyCounts.containsKey(dateStr)) {
        dailyCounts[dateStr] = dailyCounts[dateStr]! + 1;
      }
    }

    return Map.fromEntries(dailyCounts.entries.toList().reversed);
  }

  Map<String, int> getConfidenceDistribution(List<Classification> classifications) {
    Map<String, int> distribution = {
      '90-100%': 0,
      '80-89%': 0,
      '60-79%': 0,
      'Below 60%': 0,
    };

    for (var c in classifications) {
      final conf = c.confidence * 100;
      if (conf >= 90) {
        distribution['90-100%'] = distribution['90-100%']! + 1;
      } else if (conf >= 80) {
        distribution['80-89%'] = distribution['80-89%']! + 1;
      } else if (conf >= 60) {
        distribution['60-79%'] = distribution['60-79%']! + 1;
      } else {
        distribution['Below 60%'] = distribution['Below 60%']! + 1;
      }
    }
    return distribution;
  }

  Map<String, List<MapEntry<String, int>>> getMisclassifications(List<Classification> classifications) {
    Map<String, Map<String, int>> misclassMap = {};

    for (var c in classifications.where((c) => !c.isCorrect)) {
      if (!misclassMap.containsKey(c.scannedBreed)) {
        misclassMap[c.scannedBreed] = {};
      }
      final key = c.detectedBreed;
      misclassMap[c.scannedBreed]![key] = (misclassMap[c.scannedBreed]![key] ?? 0) + 1;
    }

    Map<String, List<MapEntry<String, int>>> result = {};
    misclassMap.forEach((breed, misclassMap) {
      var sorted = misclassMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      result[breed] = sorted;
    });
    return result;
  }
}

class _ScanAnalyticsSection extends StatelessWidget {
  final List<Classification> classifications;
  final AnalyticsService _analyticsService = AnalyticsService();

  _ScanAnalyticsSection({required this.classifications});

  @override
  Widget build(BuildContext context) {
    final perBreedAccuracy = _analyticsService.getPerBreedAccuracy(classifications);
    
    final breedCounts = <String, int>{};
    for (final classification in classifications) {
      breedCounts[classification.scannedBreed] = (breedCounts[classification.scannedBreed] ?? 0) + 1;
    }

    final allBreeds = dogBreeds.map((b) => b.name).toList();
    allBreeds.sort();
    
    final breedData = allBreeds.map((breed) {
      final accuracy = perBreedAccuracy[breed] ?? 0.0;
      final count = breedCounts[breed] ?? 0;
      return {'breed': breed, 'accuracy': accuracy, 'count': count};
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, pawCream],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: pawGreen.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: pawGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: pawGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Scan Analytics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: pawDarkGreen,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            children: List.generate(breedData.length, (index) {
              final breed = breedData[index]['breed'] as String;
              final accuracy = breedData[index]['accuracy'] as double;
              final count = breedData[index]['count'] as int;
              
              final color = count == 0 
                  ? Colors.grey[400]
                  : accuracy >= 80 ? const Color(0xFF4CAF50) : 
                    accuracy >= 60 ? const Color(0xFFFF9800) : 
                    const Color(0xFFF44336);
              
              return Padding(
                padding: EdgeInsets.only(bottom: index < breedData.length - 1 ? 12 : 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: pawGreen.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              breed,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: pawDarkGreen,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: pawGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Count: $count',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: pawDarkGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${accuracy.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: color,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: accuracy / 100,
                          minHeight: 6,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(color ?? Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
