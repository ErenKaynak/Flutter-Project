import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math' as Math;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:engineering_project/assets/AI/api_config.dart';

class AdminProducts extends StatefulWidget {
  const AdminProducts({super.key});

  @override
  State<AdminProducts> createState() => _AdminProductsState();
}

class _AdminProductsState extends State<AdminProducts> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController imagePathController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  
  // Localized description controllers
  final Map<String, TextEditingController> descriptionControllers = {
    'en': TextEditingController(),
    'tr': TextEditingController(),
    'ar': TextEditingController(),
  };
  
  // Search functionality
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  // For additional images
  final List<TextEditingController> additionalImagesControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  
  // Category selection
  String selectedCategory = "CPU's";
  final List<String> categories = [
    "CPU's", 
    "GPU's", 
    "RAM's", 
    "Storage", 
    "Motherboards",
    "Cases",
    "PSU"
  ];

  String selectedFilterCategory = "All";

  final CollectionReference products =
      FirebaseFirestore.instance.collection('products');

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    nameController.dispose();
    priceController.dispose();
    imagePathController.dispose();
    stockController.dispose();
    descriptionControllers.values.forEach((controller) => controller.dispose());
    for (var controller in additionalImagesControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = searchController.text.trim().toLowerCase();
    });
  }

  Future<String> _generateDescription(String productName, String category, String language) async {
    String prompt;
    String languagePrompt;
    String productType = '';
    Map<String, String> specs = {};
    
    // Enhanced product name parsing
    final String normalizedName = productName.toUpperCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // GPU Detection
    if (normalizedName.contains('RTX') || normalizedName.contains('GTX')) {
      productType = 'NVIDIA GPU';
      // RTX/GTX Series detection
      final gpuMatch = RegExp(r'(RTX|GTX)\s*(\d{4})\s*(TI|SUPER)?').firstMatch(normalizedName);
      if (gpuMatch != null) {
        specs['series'] = gpuMatch.group(1) ?? ''; // RTX or GTX
        specs['model'] = gpuMatch.group(2) ?? ''; // e.g., 3080
        specs['variant'] = gpuMatch.group(3) ?? ''; // TI or SUPER if present
      }
      // Memory detection
      final memoryMatch = RegExp(r'(\d+)\s*GB').firstMatch(normalizedName);
      if (memoryMatch != null) {
        specs['memory'] = memoryMatch.group(1) ?? '';
      }
    } else if (normalizedName.contains('RX') || normalizedName.contains('RADEON')) {
      productType = 'AMD GPU';
      // RX Series detection
      final rxMatch = RegExp(r'RX\s*(\d+)\s*(XT|X)?').firstMatch(normalizedName);
      if (rxMatch != null) {
        specs['model'] = rxMatch.group(1) ?? '';
        specs['variant'] = rxMatch.group(2) ?? '';
      }
      // Memory detection
      final memoryMatch = RegExp(r'(\d+)\s*GB').firstMatch(normalizedName);
      if (memoryMatch != null) {
        specs['memory'] = memoryMatch.group(1) ?? '';
      }
    }
    
    // CPU Detection
    else if (normalizedName.contains('RYZEN')) {
      productType = 'AMD CPU';
      // Ryzen series and model detection
      final ryzenMatch = RegExp(r'RYZEN\s*(\d+)\s*(\d{4}X?)\s*(X|XT|G)?').firstMatch(normalizedName);
      if (ryzenMatch != null) {
        specs['series'] = ryzenMatch.group(1) ?? ''; // e.g., 5, 7, 9
        specs['model'] = ryzenMatch.group(2) ?? ''; // e.g., 5600, 5800
        specs['variant'] = ryzenMatch.group(3) ?? ''; // X, XT, or G
      }
    } else if (normalizedName.contains('INTEL') || normalizedName.contains('CORE')) {
      productType = 'Intel CPU';
      // Intel series and generation detection
      final intelMatch = RegExp(r'(I[357]|I9|CORE\s*I[357]|CORE\s*I9)-(\d{4,5})(K|F|KF)?').firstMatch(normalizedName);
      if (intelMatch != null) {
        specs['series'] = intelMatch.group(1)?.replaceAll('CORE ', '') ?? ''; // i3, i5, i7, i9
        specs['model'] = intelMatch.group(2) ?? ''; // e.g., 12400, 12600
        specs['variant'] = intelMatch.group(3) ?? ''; // K, F, or KF
      }
    }
    
    // RAM Detection
    else if (category.contains('RAM') || normalizedName.contains('DDR')) {
      productType = 'RAM';
      // RAM specifications detection
      final ramMatch = RegExp(r'(DDR\d)\D*(\d+)\s*(GB|TB)?\D*(\d+)?\s*(MHZ|MT/S)?').firstMatch(normalizedName);
      if (ramMatch != null) {
        specs['type'] = ramMatch.group(1) ?? ''; // e.g., DDR4, DDR5
        specs['capacity'] = '${ramMatch.group(2) ?? ''}${ramMatch.group(3) ?? ''}'; // e.g., 16GB
        specs['speed'] = ramMatch.group(4) != null ? '${ramMatch.group(4)}${ramMatch.group(5) ?? ''}' : ''; // e.g., 3200MHz
      }
    }
    
    // Storage Detection
    else if (category.contains('Storage')) {
      productType = 'Storage';
      // Storage specifications detection
      final storageMatch = RegExp(r'(\d+)\s*(GB|TB).*?(SSD|HDD|NVME)').firstMatch(normalizedName);
      if (storageMatch != null) {
        specs['capacity'] = '${storageMatch.group(1) ?? ''}${storageMatch.group(2) ?? ''}'; // e.g., 1TB
        specs['type'] = storageMatch.group(3) ?? ''; // SSD, HDD, or NVMe
      }
    }
    
    // PSU Detection
    else if (category.contains('PSU')) {
      productType = 'PSU';
      // PSU specifications detection
      final psuMatch = RegExp(r'(\d+)W.*?(BRONZE|SILVER|GOLD|PLATINUM|TITANIUM)').firstMatch(normalizedName);
      if (psuMatch != null) {
        specs['wattage'] = psuMatch.group(1) ?? '';
        specs['rating'] = psuMatch.group(2) ?? '';
      }
    }

    // Motherboard Detection
    else if (category.contains('Motherboard')) {
      productType = 'Motherboard';
      // Chipset detection
      final chipsetMatch = RegExp(r'(Z|B|H|X)(\d{3})(E)?').firstMatch(normalizedName);
      if (chipsetMatch != null) {
        specs['chipset_series'] = chipsetMatch.group(1) ?? ''; // Z, B, H, X
        specs['chipset_number'] = chipsetMatch.group(2) ?? ''; // e.g., 790, 660
        specs['variant'] = chipsetMatch.group(3) ?? ''; // E if exists
      }
      
      // Brand and series detection
      if (normalizedName.contains('ROG') || normalizedName.contains('REPUBLIC OF GAMERS')) {
        specs['brand_series'] = 'ROG';
      } else if (normalizedName.contains('TUF')) {
        specs['brand_series'] = 'TUF Gaming';
      } else if (normalizedName.contains('PRIME')) {
        specs['brand_series'] = 'PRIME';
      } else if (normalizedName.contains('PRO')) {
        specs['brand_series'] = 'PRO';
      }
      
      // Socket/Platform detection
      if (normalizedName.contains('LGA1700') || normalizedName.contains('LGA 1700')) {
        specs['socket'] = 'LGA 1700';
      } else if (normalizedName.contains('AM5')) {
        specs['socket'] = 'AM5';
      }
      
      // Form factor detection
      if (normalizedName.contains('ATX')) {
        specs['form_factor'] = 'ATX';
      } else if (normalizedName.contains('MICRO-ATX') || normalizedName.contains('MATX')) {
        specs['form_factor'] = 'Micro-ATX';
      } else if (normalizedName.contains('ITX')) {
        specs['form_factor'] = 'Mini-ITX';
      }
    }

    print('Product Name Analysis:');
    print('Original Name: $productName');
    print('Normalized Name: $normalizedName');
    print('Detected Type: $productType');
    print('Extracted Specs: $specs');

    // Construct detailed prompt based on product type and specs
    String detailedPrompt = '''You are a technical writer specializing in computer hardware. Generate a detailed, technical description for this specific computer component:

PRODUCT SPECIFICATIONS:
Name: $productName
Category: $category
Type: $productType
${specs.entries.map((e) => '${e.key.toUpperCase()}: ${e.value}').join('\n')}

REQUIRED CONTENT:
1. Start with the exact product name and its primary function
2. Technical Specifications:
   - List ALL provided specifications with their values
   - Include performance metrics specific to this model
   - Mention compatibility with other components
3. Key Features:
   - ${_getCategorySpecificFeatures(productType)}
4. Use Cases:
   - ${_getCategorySpecificUseCases(productType)}

FORMATTING REQUIREMENTS:
1. Length: 400-600 characters
2. Use proper technical terminology
3. Format numbers according to language conventions
4. Include model-specific technologies
5. Maintain professional tone
6. Use the complete product name at least once
7. Structure in clear, logical paragraphs

DO NOT:
- Make generic statements
- Include marketing language
- Mention unavailable features
- Exceed character limit
- Omit any provided specifications''';

    // Add language-specific formatting
    switch (language) {
      case 'tr':
        detailedPrompt += '''\n\nOUTPUT FORMAT:
- Write in Turkish (Türkçe)
- Use proper Turkish technical terms
- Format numbers as: 1.234,56
- Use ₺ for prices
- Maintain formal technical language
- Ensure correct Turkish grammar and punctuation''';
        break;
      case 'ar':
        detailedPrompt += '''\n\nOUTPUT FORMAT:
- Write in Arabic (العربية)
- Use proper Arabic technical terms
- Use Arabic numerals
- Use ر.س for prices
- Ensure proper RTL formatting
- Maintain formal technical language
- Use appropriate Arabic technical terminology''';
        break;
      default:
        detailedPrompt += '''\n\nOUTPUT FORMAT:
- Write in English
- Use standard technical terms
- Format numbers as: 1,234.56
- Use \$ for prices
- Maintain professional technical language
- Follow standard English grammar and punctuation''';
    }

    try {
      print('\n=== DESCRIPTION GENERATION DEBUG ===');
      print('Product Name: $productName');
      print('Category: $category');
      print('Language: $language');
      print('Detected Type: $productType');
      print('Extracted Specs: $specs');
      print('\nSending API Request...');
      
      final requestBody = jsonEncode({
        'model': 'openai/gpt-4',
        'messages': [
          {
            'role': 'system',
            'content': '''You are an expert technical writer specializing in computer hardware specifications.
Your task is to generate extremely detailed, technically precise product descriptions.'''
          },
          {
            'role': 'user',
            'content': detailedPrompt
          }
        ]
      });
      
      print('Request Body: $requestBody');
      
      final response = await http.post(
        Uri.parse(APIConfig.openRouterUrl),
        headers: APIConfig.getOpenRouterHeaders(),
        body: requestBody
      );
      
      print('\nAPI Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final description = jsonResponse['choices'][0]['message']['content'];
        print('\nGenerated Description:');
        print('Language: $language');
        print('Length: ${description.length} characters');
        print('Description: $description');
        print('\nVerification:');
        print('Contains product name: ${description.toLowerCase().contains(productName.toLowerCase())}');
        print('Contains category: ${description.toLowerCase().contains(category.toLowerCase())}');
        print('Contains detected type: ${description.toLowerCase().contains(productType.toLowerCase())}');
        print('=== END DEBUG ===\n');
        return description;
      } else {
        print('Error Response: ${response.body}');
        throw Exception('API returned status code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error generating description: $e');
      print('Stack trace: $stackTrace');
      
      // Fallback to template-based description if API fails
      return _generateFallbackDescription(productName, category, specs, language);
    }
  }

  String _generateFallbackDescription(String productName, String category, Map<String, String> specs, String language) {
    String baseDesc = '';
    
    // Generate base description in English
    if (category == 'Motherboards' && specs.isNotEmpty) {
      baseDesc = '${specs['brand_series'] ?? ''} ${specs['chipset_series'] ?? ''}'
                '${specs['chipset_number'] ?? ''} motherboard'
                '${specs['socket'] != null ? ' for ${specs['socket']}' : ''}'
                '${specs['form_factor'] != null ? ' in ${specs['form_factor']} form factor' : ''}. '
                'Features advanced power delivery, extensive connectivity options, '
                'and robust build quality for reliable performance.';
    } else {
      baseDesc = 'High-quality $category product offering reliable performance '
                'and compatibility with modern systems.';
    }
    
    // Translate based on language
    switch (language) {
      case 'tr':
        return _translateToTurkish(baseDesc, category, specs);
      case 'ar':
        return _translateToArabic(baseDesc, category, specs);
      default:
        return baseDesc;
    }
  }

  String _translateToTurkish(String baseDesc, String category, Map<String, String> specs) {
    // Category translations
    final categoryTranslations = {
      'Motherboards': 'Anakart',
      "CPU's": 'İşlemci',
      "GPU's": 'Ekran Kartı',
      "RAM's": 'RAM',
      'Storage': 'Depolama',
      'Cases': 'Kasa',
      'PSU': 'Güç Kaynağı'
    };

    // Spec translations
    final specTranslations = {
      'brand_series': {
        'ROG': 'ROG',
        'TUF Gaming': 'TUF Gaming',
        'PRIME': 'PRIME',
        'PRO': 'PRO'
      },
      'form_factor': {
        'ATX': 'ATX',
        'Micro-ATX': 'Micro-ATX',
        'Mini-ITX': 'Mini-ITX'
      }
    };

    // Replace category
    String translatedDesc = baseDesc;
    final translatedCategory = categoryTranslations[category] ?? category;

    // Translate common terms
    translatedDesc = translatedDesc
      .replaceAll('motherboard', 'anakart')
      .replaceAll('for', 'için')
      .replaceAll('in', '')
      .replaceAll('form factor', 'boyutunda')
      .replaceAll('Features', 'Özellikler')
      .replaceAll('advanced power delivery', 'gelişmiş güç dağıtımı')
      .replaceAll('extensive connectivity options', 'geniş bağlantı seçenekleri')
      .replaceAll('robust build quality', 'sağlam yapı kalitesi')
      .replaceAll('reliable performance', 'güvenilir performans')
      .replaceAll('High-quality', 'Yüksek kaliteli')
      .replaceAll('product offering', 'ürün sunar')
      .replaceAll('and', 've')
      .replaceAll('compatibility', 'uyumluluk')
      .replaceAll('with modern systems', 'modern sistemler ile');

    return translatedDesc;
  }

  String _translateToArabic(String baseDesc, String category, Map<String, String> specs) {
    // Category translations
    final categoryTranslations = {
      'Motherboards': 'اللوحة الأم',
      "CPU's": 'المعالج',
      "GPU's": 'بطاقة الرسومات',
      "RAM's": 'الذاكرة',
      'Storage': 'التخزين',
      'Cases': 'الهيكل',
      'PSU': 'مزود الطاقة'
    };

    // Spec translations
    final specTranslations = {
      'brand_series': {
        'ROG': 'ROG',
        'TUF Gaming': 'TUF Gaming',
        'PRIME': 'PRIME',
        'PRO': 'PRO'
      },
      'form_factor': {
        'ATX': 'ATX',
        'Micro-ATX': 'Micro-ATX',
        'Mini-ITX': 'Mini-ITX'
      }
    };

    // Replace category
    String translatedDesc = baseDesc;
    final translatedCategory = categoryTranslations[category] ?? category;

    // Translate common terms
    translatedDesc = translatedDesc
      .replaceAll('motherboard', 'لوحة أم')
      .replaceAll('for', 'ل')
      .replaceAll('in', 'في')
      .replaceAll('form factor', 'حجم')
      .replaceAll('Features', 'المميزات')
      .replaceAll('advanced power delivery', 'توصيل طاقة متقدم')
      .replaceAll('extensive connectivity options', 'خيارات توصيل واسعة')
      .replaceAll('robust build quality', 'جودة بناء متينة')
      .replaceAll('reliable performance', 'أداء موثوق')
      .replaceAll('High-quality', 'عالي الجودة')
      .replaceAll('product offering', 'منتج يقدم')
      .replaceAll('and', 'و')
      .replaceAll('compatibility', 'توافق')
      .replaceAll('with modern systems', 'مع الأنظمة الحديثة');

    // Add RTL marks for proper text direction
    return '\u202B' + translatedDesc + '\u202C';
  }

  String _getCategorySpecificFeatures(String productType) {
    switch (productType) {
      case 'NVIDIA GPU':
        return '''
- Architecture details (Ampere/Ada Lovelace/etc.)
- CUDA core count and clock speeds (base/boost)
- RT core count and generation
- Tensor core count and generation
- Memory specs: GDDR6/6X, bandwidth, bus width
- Power requirements (TDP, recommended PSU)
- Display outputs (HDMI/DP versions)
- PCIe generation and lanes
- DLSS/NVIDIA Reflex/NVIDIA Broadcast support
- NVENC/NVDEC capabilities
- DirectX/Vulkan/OpenGL support versions
- Physical dimensions and cooling solution''';

      case 'AMD GPU':
        return '''
- RDNA architecture version and features
- Stream processor count and configuration
- Ray accelerator count
- Infinity Cache size
- Memory specs: GDDR6, bandwidth, bus width
- Smart Access Memory compatibility
- FSR version support and capabilities
- Power requirements (TDP, recommended PSU)
- Display outputs (HDMI/DP versions)
- PCIe generation and lanes
- DirectX/Vulkan/OpenGL support versions
- Physical dimensions and cooling design''';

      case 'AMD CPU':
        return '''
- Zen architecture version and features
- Core/thread configuration
- Base/boost clock frequencies per core
- Cache hierarchy (L1/L2/L3 sizes)
- Memory support (DDR4/DDR5, speeds)
- PCIe lanes and generation
- TDP and power states
- Socket compatibility
- Integrated graphics (if present)
- Precision Boost/Core Performance Boost
- Instruction set extensions
- Security features and virtualization support''';

      case 'Intel CPU':
        return '''
- Core architecture (Golden Cove/Raptor Lake/etc.)
- Performance/Efficiency core configuration
- Base/turbo frequencies for each core type
- Cache hierarchy (L1/L2/L3 sizes)
- Memory support (DDR4/DDR5, speeds)
- PCIe lanes and generation
- TDP configurations (base/turbo)
- Socket and chipset compatibility
- Integrated graphics specifications
- Intel Thread Director capabilities
- AVX/SSE instruction support
- Security features (SGX, TME, etc.)''';

      case 'RAM':
        return '''
- Memory technology (DDR4/DDR5)
- Module organization and chip configuration
- Primary timings (CL-tRCD-tRP-tRAS)
- Secondary/tertiary timing specifications
- XMP profile details and voltages
- ECC support status
- Single/dual rank configuration
- PCB layers and design
- Thermal sensor presence
- Heat spreader material and design
- IC manufacturer and revision
- SPD programming details''';

      case 'Storage':
        return '''
- Controller specifications and features
- NAND type and layer count
- Cache implementation (DRAM/SLC)
- Sequential read/write speeds
- Random 4K IOPS (read/write)
- Endurance rating (TBW)
- MTBF rating
- Power consumption (active/idle)
- Interface type and speed
- Form factor and dimensions
- Encryption support (hardware/software)
- SMART attributes monitoring''';

      case 'PSU':
        return '''
- Efficiency certification level details
- Rail distribution (+12V/+5V/+3.3V)
- Ripple suppression specifications
- Protection features (OCP/OVP/UVP/SCP)
- Fan specifications and curve
- Modular cable configuration
- Capacitor types and brands
- Hold-up time
- Power factor correction
- Operating temperature range
- ATX specification version
- DC output quality metrics''';

      case 'Motherboard':
        return '''
- Chipset series and number
- Brand and series
- Socket/Platform compatibility
- Form factor
- Features and expansion slots
- Power delivery and VRM design
- BIOS and UEFI support
- M.2 storage support
- I/O connectivity
- Thermal design and cooling
- Warranty and support''';

      default:
        return 'Detailed technical specifications and features';
    }
  }

  String _getCategorySpecificUseCases(String productType) {
    switch (productType) {
      case 'NVIDIA GPU':
        return '''
- Gaming performance at different resolutions
- Ray tracing performance metrics
- DLSS quality/performance ratios
- Professional 3D rendering capabilities
- Machine learning acceleration
- Video encoding/streaming performance
- Multi-display productivity
- VR/AR application support''';

      case 'AMD GPU':
        return '''
- Gaming performance tiers
- FSR quality/performance impact
- Professional visualization workloads
- Multi-monitor productivity setups
- Video encoding capabilities
- Mining efficiency (if applicable)
- DirectML workload performance
- Content creation acceleration''';

      case 'AMD CPU':
        return '''
- Multi-threaded application performance
- Single-core processing efficiency
- Server/virtualization capabilities
- Content creation workflow impact
- Gaming frame time consistency
- Compilation and rendering tasks
- Scientific computation loads
- Power efficiency scenarios''';

      case 'Intel CPU':
        return '''
- Hybrid architecture workload distribution
- Single/multi-threaded performance
- Integrated graphics capabilities
- Professional software optimization
- Gaming performance metrics
- Power scaling scenarios
- Virtual machine hosting
- AI/ML acceleration support''';

      case 'RAM':
        return '''
- High-frequency gaming scenarios
- Content creation buffer requirements
- Server/workstation applications
- Virtual machine allocation
- Database performance impact
- CAD/CAM workflow optimization
- Video editing requirements
- Scientific computation needs''';

      case 'Storage':
        return '''
- OS boot drive performance
- Game loading time impact
- 4K video editing workflow
- Database hosting requirements
- Virtual machine storage
- Content creation scratch disk
- Backup/archive reliability
- Cache drive scenarios''';

      case 'PSU':
        return '''
- High-end GPU power delivery
- Multi-GPU setup support
- Overclocking headroom
- 24/7 operation reliability
- Workstation stability
- Server redundancy options
- Silent operation scenarios
- Future upgrade compatibility''';

      case 'Motherboard':
        return '''
- Gaming PC build and customization
- Overclocking and performance tuning
- VR and AR platform compatibility
- Multi-monitor setup and productivity
- High-end workstation and server support
- Custom water cooling and liquid metal compatibility
- Future-proof expansion and upgrade paths
- Warranty and support''';

      default:
        return 'Specific use cases and performance scenarios';
    }
  }

  Future<void> _generateAllDescriptions() async {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a product name first')),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Generate descriptions for all languages
      for (var language in ['en', 'tr', 'ar']) {
        try {
          final description = await _generateDescription(
            nameController.text,
            selectedCategory,
            language
          );
          
          if (mounted) {
            descriptionControllers[language]!.text = description;
          }
        } catch (e) {
          print('Error generating description for $language: $e');
          // Continue with other languages even if one fails
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to generate $language description: $e')),
            );
          }
        }
      }

      // Hide loading indicator
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Descriptions generation completed')),
        );
      }
    } catch (e) {
      print('Error in _generateAllDescriptions: $e');
      // Hide loading indicator
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating descriptions: $e')),
        );
      }
    }
  }

  void showProductDialog({DocumentSnapshot? doc}) {
    final isEditing = doc != null;
    
    // Reset all fields
    nameController.clear();
    priceController.clear();
    imagePathController.clear();
    descriptionControllers.values.forEach((controller) => controller.clear());
    stockController.text = '0';
    selectedCategory = "CPU's";
    additionalImagesControllers.forEach((controller) => controller.clear());
    
    if (isEditing) {
      // Populate fields with existing product data
      final data = doc.data() as Map<String, dynamic>;
      nameController.text = data['name'] ?? '';
      priceController.text = data['price']?.toString() ?? '';
      imagePathController.text = data['imagePath'] ?? '';
      stockController.text = (data['stock'] ?? 0).toString();
      
      // Handle category selection
      String docCategory = data['category'] ?? 'CPU\'s';
      if (categories.contains(docCategory)) {
        selectedCategory = docCategory;
      }
      
      // Handle descriptions
      if (data['descriptions'] != null) {
        final descriptions = data['descriptions'] as Map<String, dynamic>;
        descriptions.forEach((lang, desc) {
          if (descriptionControllers.containsKey(lang)) {
            descriptionControllers[lang]!.text = desc.toString();
          }
        });
      } else if (data['description'] != null) {
        // Handle legacy single description
        descriptionControllers['en']!.text = data['description'].toString();
      }
      
      // Handle additional images array
      List<dynamic> images = data['images'] ?? [];
      for (int i = 0; i < Math.min(images.length, additionalImagesControllers.length); i++) {
        additionalImagesControllers[i].text = images[i].toString();
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          title: Text(
            isEditing ? 'Edit Product' : 'Add Product',
            style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: 'Product Name',
                    labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                ),
                TextField(
                  controller: priceController,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: 'Price (TRY)',
                    labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setStateDialog(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                TextField(
                  controller: stockController,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: 'Stock Quantity',
                    labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: imagePathController,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: 'Main Image URL',
                    labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text("Additional Images", style: TextStyle(fontWeight: FontWeight.bold)),
                ...additionalImagesControllers.asMap().entries.map((entry) {
                  int index = entry.key;
                  TextEditingController controller = entry.value;
                  return TextField(
                    controller: controller,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      labelText: 'Image URL ${index + 1}',
                      labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text("Product Descriptions", style: TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.auto_fix_high),
                      onPressed: _generateAllDescriptions,
                      tooltip: 'Generate All Descriptions',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ExpansionTile(
                  title: const Text("English Description"),
                  children: [
                    TextField(
                      controller: descriptionControllers['en'],
                      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        labelText: 'English Description',
                        labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Theme.of(context).dividerColor),
                        ),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
                ExpansionTile(
                  title: const Text("Turkish Description"),
                  children: [
                    TextField(
                      controller: descriptionControllers['tr'],
                      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        labelText: 'Turkish Description',
                        labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Theme.of(context).dividerColor),
                        ),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
                ExpansionTile(
                  title: const Text("Arabic Description"),
                  children: [
                    TextField(
                      controller: descriptionControllers['ar'],
                      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        labelText: 'Arabic Description',
                        labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Theme.of(context).dividerColor),
                        ),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                final priceText = priceController.text.trim();
                final imagePath = imagePathController.text.trim();
                final stockText = stockController.text.trim();
                
                // Validation
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a product name')),
                  );
                  return;
                }
                
                // Parse price (allow both integer and decimal values)
                double? price = double.tryParse(priceText);
                if (priceText.isEmpty || price == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid price')),
                  );
                  return;
                }
                
                // Prepare additional images array
                List<String> additionalImages = [];
                for (var controller in additionalImagesControllers) {
                  String url = controller.text.trim();
                  if (url.isNotEmpty) {
                    additionalImages.add(url);
                  }
                }

                // Prepare descriptions map
                Map<String, String> descriptions = {};
                descriptionControllers.forEach((lang, controller) {
                  final text = controller.text.trim();
                  if (text.isNotEmpty) {
                    descriptions[lang] = text;
                  }
                });

                // Prepare the product data object
                final Map<String, dynamic> productData = {
                  'name': name,
                  'price': price,
                  'category': selectedCategory,
                  'stock': int.tryParse(stockText) ?? 0,
                  'descriptions': descriptions,
                  'imagePath': imagePath,
                  'images': additionalImages,
                  'updatedAt': FieldValue.serverTimestamp(),
                };

                try {
                  if (isEditing) {
                    await products.doc(doc!.id).update(productData);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Product updated successfully')),
                      );
                    }
                  } else {
                    productData['createdAt'] = FieldValue.serverTimestamp();
                    await products.add(productData);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Product added successfully')),
                      );
                    }
                  }
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
              child: Text(isEditing ? 'Update' : 'Add', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void deleteProduct(String id) async {
    // Confirmation dialog before deletion
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this product? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await products.doc(id).delete();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Product deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting product: ${e.toString()}')),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text('Manage Products', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: isDark ? 0 : 2,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showProductDialog(),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Header Section with Stats
          Container(
            padding: EdgeInsets.all(16.0),
            margin: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.red.shade900, Colors.grey.shade900]
                    : [Colors.red.shade300, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.red.shade900 : Colors.red.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.inventory_2,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: products.snapshots(),
                    builder: (context, snapshot) {
                      final productCount = snapshot.data?.docs.length ?? 0;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Product Management",
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.grey[400] : Colors.black54,
                            ),
                          ),
                          Text(
                            "$productCount Products",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: searchController,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                prefixIcon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Theme.of(context).iconTheme.color),
                        onPressed: () {
                          searchController.clear();
                          setState(() => searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),

          // Category Filter
          Container(
            height: 60,
            margin: EdgeInsets.symmetric(vertical: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: ["All", ...categories].length, // Add "All" option
              itemBuilder: (context, index) {
                final category = index == 0 ? "All" : categories[index - 1];
                final isSelected = selectedFilterCategory == category;
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(category),
                    onSelected: (selected) {
                      setState(() {
                        selectedFilterCategory = selected ? category : "All";
                      });
                    },
                    backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Products List (existing StreamBuilder code)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: products.orderBy('name').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final productDocs = snapshot.data!.docs;
                
                if (productDocs.isEmpty) {
                  return const Center(child: Text('No products found. Add some!'));
                }

                // Filter products based on search query
                var filteredProducts = productDocs;

                // Apply search filter
                if (searchQuery.isNotEmpty) {
                  filteredProducts = productDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    final description = (data['description'] ?? '').toString().toLowerCase();
                    final category = (data['category'] ?? '').toString().toLowerCase();
                    
                    return name.contains(searchQuery) || 
                           description.contains(searchQuery) ||
                           category.contains(searchQuery);
                  }).toList();
                }

                // Apply category filter
                if (selectedFilterCategory != "All") {
                  filteredProducts = filteredProducts.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['category'] == selectedFilterCategory;
                  }).toList();
                }

                // Update the empty results message to include category
                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isNotEmpty
                              ? 'No products matching "${searchController.text}"'
                              : selectedFilterCategory != "All"
                                  ? 'No products in category "$selectedFilterCategory"'
                                  : 'No products found',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final doc = filteredProducts[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    final name = data['name'] ?? 'Unknown Product';
                    final price = data['price']?.toString() ?? '0';
                    final imagePath = data['imagePath'] ?? '';
                    final description = data['description'] ?? '';
                    final category = data['category'] ?? 'Uncategorized';
                    final stock = data['stock'] ?? 0;

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isDark
                            ? BorderSide(color: Colors.grey.shade800)
                            : BorderSide.none,
                      ),
                      color: Theme.of(context).cardColor,
                      elevation: isDark ? 1 : 2,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ExpansionTile(
                        collapsedIconColor: Theme.of(context).iconTheme.color,
                        iconColor: Theme.of(context).primaryColor,
                        leading: imagePath.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imagePath,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.image_not_supported,
                                      color: isDark ? Colors.red.shade400 : Colors.red.shade300,
                                      size: 50,
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                Icons.inventory_2,
                                color: Theme.of(context).primaryColor,
                                size: 40,
                              ),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.titleMedium?.color,
                          ),
                        ),
                        subtitle: Text(
                          '₺$price • Category: $category • Stock: $stock',
                          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue.shade700),
                              onPressed: () => showProductDialog(doc: doc),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteProduct(doc.id),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (description.isNotEmpty) ...[
                                  const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(description),
                                  const SizedBox(height: 8),
                                ],
                                
                                // Display additional images if available
                                if ((data['images'] as List<dynamic>?)?.isNotEmpty ?? false) ...[
                                  const Text('Additional Images:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 100,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: (data['images'] as List<dynamic>).length,
                                      itemBuilder: (context, imgIndex) {
                                        final imgUrl = (data['images'] as List<dynamic>)[imgIndex];
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 8.0),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8.0),
                                            child: Image.network(
                                              imgUrl,
                                              height: 100,
                                              width: 100,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  height: 100,
                                                  width: 100,
                                                  color: Colors.grey.shade200,
                                                  child: const Icon(Icons.broken_image),
                                                );
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}