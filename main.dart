import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() {
  runApp(const WoodCraftAIApp());
}

class WoodCraftAIApp extends StatelessWidget {
  const WoodCraftAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مساعد نجارة الذكاء الاصطناعي',
      debugShowCheckedModeBanner: false, // إخفاء شريط الديباج
      theme: ThemeData(
        primarySwatch: Colors.brown,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      locale: const Locale('ar', 'AE'),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('صانع الأفكار الخشبية 🪵'),
        backgroundColor: Colors.brown,
        centerTitle: true,
      ),
      body: const WoodCraftBody(),
    );
  }
}

class WoodCraftBody extends StatefulWidget {
  const WoodCraftBody({super.key});

  @override
  State<WoodCraftBody> createState() => _WoodCraftBodyState();
}

class _WoodCraftBodyState extends State<WoodCraftBody> {
  XFile? _webImage;
  final ImagePicker _picker = ImagePicker();
  String _result = 'ارفع صورة الخشب المتوفر لديك لبدء التحليل...';
  String _generatedImageUrl = '';
  bool _isLoading = false;

  // تعريف متحكم لصندوق إدخال مفتاح الـ API في الواجهة
  final TextEditingController _apiKeyController = TextEditingController();

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _webImage = pickedFile;
        _result = 'الصورة جاهزة، اضغط على زر التحليل الآن.';
        _generatedImageUrl = '';
      });
    }
  }

  Future<void> _analyzeImage() async {
    final String apiKey = _apiKeyController.text.trim();

    // التحقق من أن المستخدم قام بإدخال المفتاح
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'الرجاء إدخال مفتاح الـ API الخاص بك أولاً في الصندوق المخصص!')),
      );
      return;
    }

    if (_webImage == null) return;

    setState(() {
      _isLoading = true;
      _result = 'جاري تحليل الخشب وتوليد الخطوات والصورة النهائية مجاناً...';
      _generatedImageUrl = '';
    });

    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
      final imageBytes = await _webImage!.readAsBytes();

      final prompt = TextPart('''
        قم بتحليل صورة الخشب المرفقة بدقة. 
        1. اقترح مشروعاً واحداً مميزاً وعملياً يمكن صنعه باستخدام هذه الأخشاب.
        2. اكتب اسم المشروع كعنوان رئيسي واضح.
        3. اكتب خطوات العمل بالتفصيل والترتيب (1، 2، 3...) باللغة العربية.
      ''');

      final imagePart = DataPart('image/jpeg', imageBytes);
      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      String textResult =
          response.text ?? 'لم يتم الحصول على نتيجة، حاول مجدداً.';

      String projectTitle = textResult.split('\n').first.replaceAll('**', '');
      String imagePrompt =
          "A high quality rustic furniture photo of $projectTitle made from scrap wood pieces, detailed woodworking craftsmanship";

      final encodedPrompt = Uri.encodeComponent(imagePrompt);
      const seed = "42";
      final imageUrl = "https://pollinations.ai";

      setState(() {
        _result = textResult;
        _generatedImageUrl = imageUrl;
      });
    } catch (e) {
      setState(() {
        _result = 'حدث خطأ أثناء الاتصال: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🌟 صندوق إدخال مفتاح الـ API المضاف حديثاً في الواجهة
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'أدخل مفتاح Gemini API المجاني الخاص بك:',
                hintText: 'AIzaSy...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.vpn_key, color: Colors.brown),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.brown.shade300),
              ),
              child: _webImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.network(_webImage!.path, fit: BoxFit.cover),
                    )
                  : const Center(child: Text('لم يتم اختيار صورة بعد')),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library, color: Colors.white),
                    label: const Text('اختر صورة',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _webImage != null && !_isLoading ? _analyzeImage : null,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_awesome, color: Colors.white),
                    label: const Text('تحليل وتوليد العمل النهائي',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'النتيجة وخطوات العمل:',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Text(
                _result,
                style: const TextStyle(
                    fontSize: 16, height: 1.5, color: Colors.black87),
              ),
            ),
            if (_generatedImageUrl.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'صورة تخيلية للعمل النهائي 🎨:',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown),
              ),
              const SizedBox(height: 8),
              Container(
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.brown.shade200),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.network(
                    _generatedImageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text('جاري رسم صورة العمل النهائي بدقة...'),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
