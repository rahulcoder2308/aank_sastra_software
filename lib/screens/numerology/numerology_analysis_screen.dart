import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/app_colors.dart';
import '../../core/localization/language_provider.dart';
import '../../core/api_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:ui' as ui;

class NumerologyAnalysisScreen extends StatefulWidget {
  const NumerologyAnalysisScreen({super.key});

  @override
  State<NumerologyAnalysisScreen> createState() =>
      _NumerologyAnalysisScreenState();
}

class _NumerologyAnalysisScreenState extends State<NumerologyAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScreenshotController _screenshotController = ScreenshotController();

  Future<Uint8List> _captureTextAsImage(
    String text, {
    double fontSize = 16,
    Color color = Colors.black,
    FontWeight fontWeight = FontWeight.normal,
  }) async {
    return await _screenshotController.captureFromWidget(
      Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            color: color,
            fontWeight: fontWeight,
          ),
        ),
      ),
      pixelRatio: 3.0,
    );
  }

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

  final Map<String, Map<String, String>> _repeatingPatterns = {
    '111': {
      'en':
          'Very talkative, good for business (people who are lacking to express, lack of confidence) ending should be 111. energetic people, saucerful in job and business',
      'gu':
          'ખૂબ જ વાચાળ, વ્યવસાય માટે સારું (જે લોકો વ્યક્ત કરવામાં અસમર્થ હોય છે, આત્મવિશ્વાસનો અભાવ હોય છે) અંત 111 હોવો જોઈએ. મહેનતુ લોકો, નોકરી અને વ્યવસાયમાં રકાબી.',
      'hi':
          'बहुत बातूनी, व्यापार के लिए अच्छा (जिन लोगों में अभिव्यक्ति की कमी है, आत्मविश्वास की कमी है) अंत 111 होना चाहिए। ऊर्जावान लोग, नौकरी और व्यापार में तत्पर',
    },
    '1111': {
      'en':
          'Person will become emotional and sometime he will be a Confusing person, He will take talk unnecessary',
      'gu':
          'વ્યક્તિ લાગણીશીલ બનશે અને ક્યારેક તે મૂંઝવણભર્યો વ્યક્તિ બનશે, તે બિનજરૂરી વાતોને ધ્યાનમાં લેશે.',
      'hi':
          'व्यक्ति भावुक हो जाएगा और कभी-कभी वह भ्रमित करने वाला व्यक्ति हो जाएगा, वह अनावश्यक बातों को लेगा',
    },
    '222': {
      'en': 'Higher expectations from others, sensitive, Unhappy',
      'gu': 'બીજાઓ પાસેથી વધારે અપેક્ષાઓ, સંવેદનશીલ, નાખુશ',
      'hi': 'दूसरों से अधिक अपेक्षाएं, संवेदनशील, अप्रसन्न',
    },
    '2222': {
      'en':
          'sensitive and emotional people, little unhappy, less active, they always remain in their own world (Day dreamer). Struggle is personal life.',
      'gu':
          'સંવેદનશીલ અને લાગણીશીલ લોકો, ઓછા નાખુશ, ઓછા સક્રિય, તેઓ હંમેશા પોતાની દુનિયામાં રહે છે (ડેડ્રીમર્સ). સંઘર્ષ એ અંગત જીવન છે.',
      'hi':
          'संवेदनशील और भावुक लोग, थोड़े दुखी, कम सक्रिय, हमेशा अपनी ही दुनिया में रहते हैं (दिवास्वप्नदर्शी)। संघर्ष निजी जीवन है।',
    },
    '333': {
      'en':
          'Imaginative but difficult to relate to people They don\'t listen to anyone, argue with other',
      'gu':
          'કલ્પનાશીલ પણ લોકો સાથે સંબંધ બાંધવો મુશ્કેલ તેઓ કોઈનું સાંભળતા નથી, બીજા સાથે દલીલ કરતા નથી.',
      'hi':
          'कल्पनाशील लेकिन लोगों से संबंध बनाना मुश्किल वे किसी की नहीं सुनते, दूसरों से बहस करते हैं',
    },
    '3333': {
      'en': 'They are fearful, low confidence, can\'t complete',
      'gu': 'તેઓ ભયભીત છે, આત્મવિશ્વાસ ઓછો છે, પૂર્ણ કરી શકતા નથી',
      'hi': 'वे भयभीत हैं, आत्मविश्वास कम है, पूरा नहीं कर सकते',
    },
    '444': {
      'en':
          'Good planners, very punctual. They always rich to their deadlines. Sometime misuses of power and intelligence. It creates problem to whom it is not required to those field.',
      'gu':
          'સારા આયોજકો, ખૂબ જ સમયના પાબંદ. તેઓ હંમેશા તેમની સમયમર્યાદાનું પાલન કરે છે. ક્યારેક સત્તા અને બુદ્ધિનો દુરુપયોગ કરે છે. તે એવા લોકો માટે સમસ્યા ઊભી કરે છે જેમને તે ક્ષેત્રમાં જવાની જરૂર નથી.',
      'hi':
          'अच्छे योजनाकार, बहुत समयनिष्ठ। वे हमेशा अपनी समयसीमा का ध्यान रखते हैं। कभी-कभी वे शक्ति और बुद्धि का दुरुपयोग करते हैं। यह उन लोगों के लिए समस्या पैदा करता है जिन्हें इसकी आवश्यकता नहीं होती।',
    },
    '4444': {
      'en':
          'Overthinkers, they lose good opportunities personally and professionally. They talk too much time and take lots of time to do work. Lazy and wake up late, always stay away from work, can\'t handle finance They can\'t take good decisions',
      'gu':
          'વધુ પડતું વિચારનારા, તેઓ વ્યક્તિગત અને વ્યવસાયિક રીતે સારી તકો ગુમાવે છે. તેઓ ખૂબ વધારે વાતો કરે છે અને કામ કરવામાં ઘણો સમય લે છે. આળસુ અને મોડા સુધી જાગે છે, હંમેશા કામથી દૂર રહે છે, નાણાકીય બાબતો સંભાળી શકતા નથી તેઓ સારા નિર્ણયો લઈ શકતા નથી.',
      'hi':
          'बहुत ज़्यादा सोचने वाले, वे व्यक्तिगत और पेशेवर रूप से अच्छे अवसर खो देते हैं। वे बहुत ज़्यादा बात करते हैं और काम करने में बहुत समय लगाते हैं। आलसी और देर से उठते हैं, हमेशा काम से दूर रहते हैं, वित्त को संभाल नहीं पाते हैं वे अच्छे निर्णय नहीं ले पाते हैं',
    },
    '555': {
      'en':
          'They speak anything from their mind. Irrespective of time and spent their energy and knowledge in wrong place, good sense of humour, take risks. sometimes it can give stomach related issuer.',
      'gu':
          'તેઓ મનથી કંઈ પણ બોલે છે. સમય ગમે તે હોય અને પોતાની શક્તિ અને જ્ઞાન ખોટી જગ્યાએ ખર્ચ કરે છે, સારી રમૂજવૃત્તિ ધરાવે છે, જોખમ લે છે. ક્યારેક તે પેટ સંબંધિત સમસ્યા પેદા કરી શકે છે.',
      'hi':
          'वे अपने मन की बात कह देते हैं। समय की परवाह किए बिना अपनी ऊर्जा और ज्ञान को गलत जगह खर्च करते हैं, हास्य की अच्छी समझ रखते हैं, जोखिम उठाते हैं। कभी-कभी यह पेट से संबंधित समस्या दे सकता है।',
    },
    '5555': {
      'en':
          'Stubborn, complete task easily, sometimes it can give sudden situations, they don\'t accept changes, can\'t balance personal and professional life. Due to missing they can be influenced easily',
      'gu':
          'હઠીલા, સરળતાથી કાર્ય પૂર્ણ કરી શકે છે, ક્યારેક તે અચાનક પરિસ્થિતિઓનું કારણ બની શકે છે, તેઓ ફેરફારો સ્વીકારતા નથી, વ્યક્તિગત અને વ્યાવસાયિક જીવનને સંતુલિત કરી શકતા નથી. ગેરહાજરીને કારણે તેઓ સરળતાથી પ્રભાવિત થઈ શકે છે.',
      'hi':
          'जिद्दी, आसानी से काम पूरा करने वाले, कभी-कभी अचानक परिस्थितियाँ दे सकते हैं, बदलाव स्वीकार नहीं करते, निजी और पेशेवर जीवन में संतुलन नहीं बना पाते। गुमशुदा होने के कारण आसानी से प्रभावित हो सकते हैं',
    },
    '666': {
      'en':
          'Indication of evil thoughts, weary disturbed metalling try to maintain a proper social image',
      'gu':
          'દુષ્ટ વિચારોનો સંકેત, થાકેલા વિક્ષેપિત ધાતુશાસ્ત્ર યોગ્ય સામાજિક છબી જાળવવાનો પ્રયાસ કરે છે',
      'hi':
          'बुरे विचारों का संकेत, थका हुआ परेशान धातुकरण एक उचित सामाजिक छवि बनाए रखने की कोशिश करता है',
    },
    '6666': {
      'en':
          'Either active or lazy. They might miss golden opportunities. face lots of troubler and obstacles in life',
      'gu':
          'કાં તો સક્રિય હોય કે આળસુ. તેઓ સુવર્ણ તકો ગુમાવી શકે છે. જીવનમાં ઘણી મુશ્કેલીઓ અને અવરોધોનો સામનો કરવો પડે છે.',
      'hi':
          'या तो सक्रिय या आलसी। वे सुनहरे अवसरों को खो सकते हैं। जीवन में बहुत सारी परेशानियों और बाधाओं का सामना करना पड़ता है',
    },
    '777': {
      'en':
          'Always worried about money, health and relationship. After facing so many struggles they become strong, marriage issues.',
      'gu':
          'હંમેશા પૈસા, સ્વાસ્થ્ય અને સંબંધોની ચિંતા રહે છે. ઘણા સંઘર્ષોનો સામનો કર્યા પછી તેઓ મજબૂત બને છે, લગ્નના પ્રશ્નો.',
      'hi':
          'हमेशा पैसे, स्वास्थ्य और रिश्ते को लेकर चिंतित रहते हैं। इतने संघर्षों का सामना करने के बाद वे मजबूत बनते हैं, शादी के मुद्दे।',
    },
    '7777': {
      'en':
          'Difficult situation in their lives, health problems, damage personal and professional life. They will not have a piece of mind. They may not be blessed with children. They will have mental stress. kidney issues.',
      'gu':
          'તેમના જીવનમાં મુશ્કેલ પરિસ્થિતિ, સ્વાસ્થ્ય સમસ્યાઓ, વ્યક્તિગત અને વ્યાવસાયિક જીવનને નુકસાન. તેઓ શાંત નહીં હોય. તેમને બાળકોનો આશીર્વાદ નહીં મળે. તેમને માનસિક તણાવ રહેશે. કિડનીની સમસ્યાઓ.',
      'hi':
          'उनके जीवन में कठिन परिस्थितियाँ, स्वास्थ्य समस्याएँ, व्यक्तिगत और व्यावसायिक जीवन को नुकसान। उन्हें मानसिक शांति नहीं मिलेगी। उन्हें संतान सुख नहीं मिलेगा। उन्हें मानसिक तनाव रहेगा। किडनी संबंधी समस्याएँ होंगी।',
    },
    '888': {
      'en':
          'full of troubles after 40 years they but they will get good money but they become rude and angry.',
      'gu':
          '૪૦ વર્ષ પછી મુશ્કેલીઓથી ભરેલા, તેમને સારા પૈસા મળશે પણ તેઓ અસંસ્કારી અને ગુસ્સે થઈ જાય છે.',
      'hi':
          '40 साल के बाद वे परेशानियों से भरे होंगे लेकिन उन्हें अच्छा पैसा मिलेगा लेकिन वे असभ्य और गुस्सैल हो जाएंगे।',
    },
    '8888': {
      'en':
          'They constantly feel need for change. they are insecure regarding money. They might divert from their path and end up with struggles If there is no 8their money will not stay',
      'gu':
          'તેઓ સતત પરિવર્તનની અનુભવે છે. તેઓ વિચારો અસુરક્ષિત હોય છે. તેઓ તેમના માર્ગે ભટકી શકે છે અને જોખમમાં પરિણમી શકે છે જો કોઈ 8 ન હોય તો તેમના કોઈ પણ વ્યક્તિને નહીં.',
      'hi':
          'उन्हें लगातार बदलाव की ज़रूरत महसूस होती है। वे पैसे को लेकर असुरक्षित हैं। वे अपने रास्ते से भटक सकते हैं और संघर्षों में पड़ सकते हैं। अगर कोई 8 नहीं है तो उनका पैसा नहीं टिकेगा।',
    },
    '999': {
      'en':
          'They spent a lot of money without thinking Consequence, do extra ordinary things, always ready to healp others',
      'gu':
          'તેઓ વિચાર્યા વિના ઘણા પૈસા ખર્ચતા હતા પરિણામ, અસાધારણ કાર્યો કરતા હતા, હંમેશા બીજાઓને સાજા કરવા તૈયાર રહેતા હતા',
      'hi':
          'वे बिना सोचे-समझे ढेर सारा पैसा खर्च कर देते हैं, असाधारण काम करते हैं, दूसरों की मदद के लिए हमेशा तैयार रहते हैं',
    },
    '9999': {
      'en':
          'Sometimes it can create negative impression on this person. They deliver much. They don’t have pity on others, detached people, they can’t understand the emotion of people.',
      'gu':
          'ક્યારેક તે વ્યક્તિ પર નકારાત્મક છાપ ઉભી કરી શકે છે. તેઓ ઘણું બધું કરે છે. તેમને બીજાઓ પર દયા નથી હોતી, તેઓ અલગ લોકો હોય છે, તેઓ લોકોની લાગણીઓ સમજી શકતા નથી.',
      'hi':
          'कभी-कभी यह इस व्यक्ति पर नकारात्मक प्रभाव डाल सकता है। वे बहुत कुछ देते हैं। उन्हें दूसरों पर दया नहीं आती, वे अलग-थलग लोग हैं, वे लोगों की भावनाओं को नहीं समझ सकते।',
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

  int _getChaldeanValue(String char) {
    final Map<String, int> chaldeanMapping = {
      'A': 1,
      'I': 1,
      'J': 1,
      'Q': 1,
      'Y': 1,
      'B': 2,
      'K': 2,
      'R': 2,
      'C': 3,
      'G': 3,
      'L': 3,
      'S': 3,
      'D': 4,
      'M': 4,
      'T': 4,
      'E': 5,
      'H': 5,
      'N': 5,
      'X': 5,
      'U': 6,
      'V': 6,
      'W': 6,
      'O': 7,
      'Z': 7,
      'F': 8,
      'P': 8,
    };
    return chaldeanMapping[char.toUpperCase()] ?? 0;
  }

  Future<void> _shareMobileAnalysis() async {
    final mobile = _mobileController.text.trim();
    if (mobile.isEmpty || _mobileAnalysisResults.isEmpty) return;

    // Show generating status
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating PDF Report...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final pdf = pw.Document();

      // Load the logo
      final logoBytes =
          (await rootBundle.load(
            'assets/images/logo_full.jpg',
          )).buffer.asUint8List();
      final logoImage = pw.MemoryImage(logoBytes);

      // Load fonts for better styling and Indic language support
      final baseFont = await PdfGoogleFonts.poppinsRegular();
      final boldFont = await PdfGoogleFonts.poppinsBold();
      // For Hindi/Gujarati support
      final hindiFont = await PdfGoogleFonts.notoSerifDevanagariRegular();
      final gujaratiFont = await PdfGoogleFonts.notoSansGujaratiRegular();

      // Fix: Pre-generate images for broken Indic text shaping
      final List<Map<String, Uint8List>> indicImagesList = [];
      for (final item in _mobileAnalysisResults) {
        final hiImg = await _captureTextAsImage(
          (item['meaning_hi'] ?? '').toString(),
          color: Colors.purple[700]!,
        );
        final guImg = await _captureTextAsImage(
          (item['meaning_gu'] ?? '').toString(),
          color: Colors.green[700]!,
        );
        indicImagesList.add({'hi': hiImg, 'gu': guImg});
      }

      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            buildBackground:
                (context) => pw.FullPage(
                  ignoreMargins: true,
                  child: pw.Center(
                    child: pw.Opacity(
                      opacity: 0.05,
                      child: pw.Image(logoImage, width: 400),
                    ),
                  ),
                ),
          ),
          header:
              (context) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(logoImage, height: 40),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Aank Sastra',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 16,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                      pw.Text(
                        'Universal Numerology Analysis',
                        style: pw.TextStyle(
                          font: baseFont,
                          fontSize: 10,
                          color: PdfColors.blueGrey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          footer:
              (context) => pw.Container(
                alignment: pw.Alignment.centerRight,
                margin: const pw.EdgeInsets.only(top: 20),
                child: pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(
                    font: baseFont,
                    fontSize: 10,
                    color: PdfColors.grey,
                  ),
                ),
              ),
          build:
              (context) => [
                pw.SizedBox(height: 20),
                pw.Header(
                  level: 0,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Mobile Number Analysis',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 24,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Mobile: $mobile',
                        style: pw.TextStyle(
                          font: baseFont,
                          fontSize: 18,
                          color: PdfColors.blue700,
                        ),
                      ),
                      pw.Divider(thickness: 1, color: PdfColors.blueGrey100),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                ..._mobileAnalysisResults.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 20),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey200),
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(12),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 8,
                          ),
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.grey50,
                            borderRadius: pw.BorderRadius.vertical(
                              top: pw.Radius.circular(12),
                            ),
                          ),
                          child: pw.Text(
                            'Pair: ${item['pair']} (Position ${item['position']})',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 14,
                              color: PdfColors.blueGrey800,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(15),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _buildPdfLangItem(
                                'ENGLISH',
                                (item['meaning_en'] ?? '').toString(),
                                PdfColors.blue700,
                                baseFont,
                              ),
                              pw.SizedBox(height: 12),
                              _buildPdfLangItem(
                                'हिन्दी',
                                (item['meaning_hi'] ?? '').toString(),
                                PdfColors.purple700,
                                hindiFont,
                                imageBytes: indicImagesList[index]['hi'],
                              ),
                              pw.SizedBox(height: 12),
                              _buildPdfLangItem(
                                'ગુજરાતી',
                                (item['meaning_gu'] ?? '').toString(),
                                PdfColors.green700,
                                gujaratiFont,
                                imageBytes: indicImagesList[index]['gu'],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                // Full Repeating Digits Reference Table
                pw.SizedBox(height: 30),
                pw.Text(
                  'Repeating Digits Combinations (Angel Numbers)',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 20,
                    color: PdfColors.blueGrey900,
                  ),
                ),
                pw.SizedBox(height: 15),
                ..._repeatingPatterns.entries.map((entry) {
                  final pattern = entry.key;
                  final meaning = entry.value;
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 20),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.amber200),
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(12),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 8,
                          ),
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.amber50,
                            borderRadius: pw.BorderRadius.vertical(
                              top: pw.Radius.circular(12),
                            ),
                          ),
                          child: pw.Text(
                            'Combination: $pattern',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 16,
                              color: PdfColors.amber900,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(15),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _buildPdfLangItem(
                                'ENGLISH',
                                meaning['en'] ?? '',
                                PdfColors.blue700,
                                baseFont,
                              ),
                              pw.SizedBox(height: 12),
                              _buildPdfLangItem(
                                'हिन्दी',
                                meaning['hi'] ?? '',
                                PdfColors.purple700,
                                hindiFont,
                              ),
                              pw.SizedBox(height: 12),
                              _buildPdfLangItem(
                                'ગુજરાતી',
                                meaning['gu'] ?? '',
                                PdfColors.green700,
                                gujaratiFont,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
        ),
      );

      final pdfBytes = await pdf.save();
      final directory =
          Platform.isWindows
              ? await getApplicationDocumentsDirectory()
              : await getTemporaryDirectory();
      final pdfPath =
          await File('${directory.path}/mobile_analysis_$mobile.pdf').create();
      await pdfPath.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [
          XFile(
            pdfPath.path,
            name: 'Mobile_Analysis.pdf',
            mimeType: 'application/pdf',
          ),
        ],
        subject: 'Mobile Number Analysis Report',
        text:
            Platform.isWindows
                ? null
                : 'My Mobile Number Analysis from Aank Sastra! ✨',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to generate PDF: $e')));
      }
    }
  }

  pw.Widget _buildPdfLangItem(
    String lang,
    String text,
    PdfColor color,
    pw.Font font, {
    Uint8List? imageBytes,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey50,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Text(
            lang,
            style: pw.TextStyle(
              font: font,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ),
        pw.SizedBox(height: 4),
        if (imageBytes != null)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Image(
              pw.MemoryImage(imageBytes),
              height: 22, // Matches the scale of 12pt text
            ),
          )
        else
          pw.Text(
            text,
            style: pw.TextStyle(
              font: font,
              fontSize: 12,
              color: PdfColors.black,
            ),
          ),
      ],
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
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
                maxLength: 10,
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
                  labelHi: 'संचાલक संख्या',
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
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Automated Grid ──
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 48,
                                  child: Center(
                                    child: const Text(
                                      'Automated Grid',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.vip,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildDynamicLoShuGrid(),
                              ],
                            ),
                            const SizedBox(width: 80),
                            // ── Manual Grid ──
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 48,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Manual Grid',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            for (var c
                                                in _manualCellControllers
                                                    .values) {
                                              c.clear();
                                            }
                                          });
                                        },
                                        icon: const Icon(
                                          Icons.refresh,
                                          size: 20,
                                          color: AppColors.error,
                                        ),
                                        tooltip: 'Clear Manual Grid',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildManualGridTab(),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 80),
                        _buildLoShuPlanesSection(),
                      ],
                    )
                  else
                    Column(
                      children: [
                        const Text(
                          'Automated Grid',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.vip,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDynamicLoShuGrid(),
                        const SizedBox(height: 56),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Manual Grid',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  for (var c in _manualCellControllers.values) {
                                    c.clear();
                                  }
                                });
                              },
                              icon: const Icon(
                                Icons.refresh,
                                size: 20,
                                color: AppColors.error,
                              ),
                              tooltip: 'Clear Manual Grid',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Center(child: _buildManualGridTab()),
                        const SizedBox(height: 56),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$val',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              height: 1.1,
            ),
          ),
          Text(
            info['name'],
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: 1.2,
            ),
          ),
        ],
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
        'hi': 'इમોશનલ प्लेन',
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
        'hi': 'વિલ प्लेन',
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
        'hi': 'ગોલ્ડન प्लेन',
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
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.go,
          maxLength: 200,
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
    int? maxLength,
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
                  maxLength: maxLength,
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
                  inputFormatters:
                      keyboardType == TextInputType.number
                          ? [FilteringTextInputFormatter.digitsOnly]
                          : null,
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
    return Container(
      width: 320,
      height: 320,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.black, width: 4),
      ),
      child: GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        children:
            [4, 9, 2, 3, 5, 7, 8, 1, 6].map((n) {
              return _buildEditableGridCell(n);
            }).toList(),
      ),
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

  List<String> _getMatchingRepeatingPatterns(String mobile) {
    List<String> found = [];
    final digits = ['1', '2', '3', '4', '5', '6', '7', '8', '9'];

    for (var d in digits) {
      if (mobile.contains(d * 4)) {
        found.add(d * 4);
      } else if (mobile.contains(d * 3)) {
        found.add(d * 3);
      }
    }
    return found;
  }

  Future<void> _shareNameAnalysis() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || !_nameAnalyzed || _nameRootNumber == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating PDF Report...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final pdf = pw.Document();

      // Load assets
      final logoBytes =
          (await rootBundle.load(
            'assets/images/logo_full.jpg',
          )).buffer.asUint8List();
      final logoImage = pw.MemoryImage(logoBytes);

      final baseFont = await PdfGoogleFonts.poppinsRegular();
      final boldFont = await PdfGoogleFonts.poppinsBold();
      final hindiFont = await PdfGoogleFonts.notoSerifDevanagariRegular();
      final gujaratiFont = await PdfGoogleFonts.notoSansGujaratiRegular();

      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            buildBackground:
                (context) => pw.FullPage(
                  ignoreMargins: true,
                  child: pw.Center(
                    child: pw.Opacity(
                      opacity: 0.05,
                      child: pw.Image(logoImage, width: 400),
                    ),
                  ),
                ),
          ),
          header:
              (context) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(logoImage, height: 40),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Aank Sastra',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 16,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                      pw.Text(
                        'Universal Numerology Analysis',
                        style: pw.TextStyle(
                          font: baseFont,
                          fontSize: 10,
                          color: PdfColors.blueGrey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          footer:
              (context) => pw.Container(
                alignment: pw.Alignment.centerRight,
                margin: const pw.EdgeInsets.only(top: 20),
                child: pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(
                    font: baseFont,
                    fontSize: 10,
                    color: PdfColors.grey,
                  ),
                ),
              ),
          build:
              (context) => [
                pw.SizedBox(height: 20),
                pw.Header(
                  level: 0,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Name Numerology Analysis',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 24,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Analysis for: $name',
                        style: pw.TextStyle(
                          font: baseFont,
                          fontSize: 18,
                          color: PdfColors.blue700,
                        ),
                      ),
                      pw.Divider(thickness: 1, color: PdfColors.blueGrey100),
                    ],
                  ),
                ),
                pw.Center(
                  child: pw.Column(
                    children: [
                      // Calculation breakdown
                      pw.Wrap(
                        spacing: 12,
                        runSpacing: 20,
                        alignment: pw.WrapAlignment.center,
                        children:
                            name.split(' ').map((part) {
                              return pw.Row(
                                mainAxisSize: pw.MainAxisSize.min,
                                children:
                                    part.split('').map((char) {
                                      final val = _getChaldeanValue(char);
                                      return pw.Padding(
                                        padding: const pw.EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: pw.Column(
                                          children: [
                                            pw.Text(
                                              char.toUpperCase(),
                                              style: pw.TextStyle(
                                                font: boldFont,
                                                fontSize: 22,
                                                letterSpacing: 2,
                                              ),
                                            ),
                                            pw.SizedBox(height: 5),
                                            pw.Text(
                                              '$val',
                                              style: pw.TextStyle(
                                                font: baseFont,
                                                fontSize: 18,
                                                color: PdfColors.grey700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                              );
                            }).toList(),
                      ),

                      pw.SizedBox(height: 60),

                      // Reduction equation
                      if (_nameCompoundNumber != null) ...[
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text(
                              '$_nameCompoundNumber',
                              style: pw.TextStyle(
                                font: baseFont,
                                fontSize: 24,
                                color: PdfColors.grey700,
                              ),
                            ),
                            pw.Text(
                              '  ---->  ',
                              style: pw.TextStyle(
                                font: baseFont,
                                fontSize: 24,
                                color: PdfColors.grey500,
                              ),
                            ),
                            pw.Text(
                              '${_nameCompoundNumber.toString().split('').join('+')} = $_nameRootNumber',
                              style: pw.TextStyle(
                                font: baseFont,
                                fontSize: 24,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 40),
                      ],

                      // Final Result
                      pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            pw.TextSpan(
                              text: 'Result : ',
                              style: pw.TextStyle(
                                font: baseFont,
                                fontSize: 32,
                                color: PdfColors.black,
                              ),
                            ),
                            pw.TextSpan(
                              text: '$_nameRootNumber',
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 36,
                                color: PdfColors.black,
                              ),
                            ),
                          ],
                        ),
                      ),

                      pw.SizedBox(height: 20),
                      pw.Align(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text(
                          'Chaldean (Indian)',
                          style: pw.TextStyle(
                            font: baseFont,
                            fontSize: 10,
                            color: PdfColors.grey500,
                            fontStyle: pw.FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 40),

                if (_nameRootMeaning != null) ...[
                  pw.Text(
                    'Root Number Meaning',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 18,
                      color: PdfColors.blueGrey900,
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  _buildPdfLangItem(
                    'ENGLISH',
                    _nameRootMeaning!['meaning_en'] ?? '',
                    PdfColors.blue700,
                    baseFont,
                  ),
                  pw.SizedBox(height: 15),
                  _buildPdfLangItem(
                    'हिन्दी',
                    _nameRootMeaning!['meaning_hi'] ?? '',
                    PdfColors.purple700,
                    hindiFont,
                  ),
                  pw.SizedBox(height: 15),
                  _buildPdfLangItem(
                    'ગુજરાતી',
                    _nameRootMeaning!['meaning_gu'] ?? '',
                    PdfColors.green700,
                    gujaratiFont,
                  ),
                ],
              ],
        ),
      );

      final pdfBytes = await pdf.save();
      final directory =
          Platform.isWindows
              ? await getApplicationDocumentsDirectory()
              : await getTemporaryDirectory();
      final pdfPath =
          await File(
            '${directory.path}/name_analysis_${name.replaceAll(' ', '_')}.pdf',
          ).create();
      await pdfPath.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [
          XFile(
            pdfPath.path,
            name: 'Name_Analysis.pdf',
            mimeType: 'application/pdf',
          ),
        ],
        subject: 'Name Numerology Analysis',
        text:
            Platform.isWindows
                ? null
                : 'My Chaldean Name Analysis from Aank Sastra! ✨',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to generate PDF: $e')));
      }
    }
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
        content: Text('Generating PDF Report...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final pdf = pw.Document();

      // Load assets
      final logoBytes =
          (await rootBundle.load(
            'assets/images/logo_full.jpg',
          )).buffer.asUint8List();
      final logoImage = pw.MemoryImage(logoBytes);

      final baseFont = await PdfGoogleFonts.poppinsRegular();
      final boldFont = await PdfGoogleFonts.poppinsBold();
      final hindiFont = await PdfGoogleFonts.notoSerifDevanagariRegular();
      final gujaratiFont = await PdfGoogleFonts.notoSansGujaratiRegular();

      // Pre-capture Indic text as high-res images to fix broken PDF shaping
      Uint8List? hindiImage;
      Uint8List? gujaratiImage;
      if (_dcRelationship != null) {
        hindiImage = await _captureTextAsImage(
          _dcRelationship!['meaning_hi'] ?? '',
          color: Colors.purple[700]!,
        );
        gujaratiImage = await _captureTextAsImage(
          _dcRelationship!['meaning_gu'] ?? '',
          color: Colors.green[700]!,
        );
      }

      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            buildBackground:
                (context) => pw.FullPage(
                  ignoreMargins: true,
                  child: pw.Center(
                    child: pw.Opacity(
                      opacity: 0.05,
                      child: pw.Image(logoImage, width: 400),
                    ),
                  ),
                ),
          ),
          header:
              (context) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(logoImage, height: 40),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Aank Sastra',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 16,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                      pw.Text(
                        'Universal Numerology Analysis',
                        style: pw.TextStyle(
                          font: baseFont,
                          fontSize: 10,
                          color: PdfColors.blueGrey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          footer:
              (context) => pw.Container(
                alignment: pw.Alignment.centerRight,
                margin: const pw.EdgeInsets.only(top: 20),
                child: pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(
                    font: baseFont,
                    fontSize: 10,
                    color: PdfColors.grey,
                  ),
                ),
              ),
          build:
              (context) => [
                pw.SizedBox(height: 20),
                pw.Header(
                  level: 0,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Lo Shu Grid Analysis',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 24,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'DOB: $dob',
                        style: pw.TextStyle(
                          font: baseFont,
                          fontSize: 18,
                          color: PdfColors.blue700,
                        ),
                      ),
                      pw.Divider(thickness: 1, color: PdfColors.blueGrey100),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),

                // Stats
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildPdfStatItem(
                      'DRIVER',
                      '$_driverNumber',
                      PdfColors.blue700,
                      boldFont,
                    ),
                    _buildPdfStatItem(
                      'CONDUCTOR',
                      '$_conductorNumber',
                      PdfColors.amber700,
                      boldFont,
                    ),
                    _buildPdfStatItem(
                      'KUA',
                      '$_kuaNumber',
                      PdfColors.purple700,
                      boldFont,
                    ),
                  ],
                ),

                pw.SizedBox(height: 40),

                // Both Grids Side by Side
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // ── Automated Grid ──
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'Automated Grid',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 13,
                            color: PdfColors.amber800,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Container(
                          width: 210,
                          height: 210,
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.black,
                          ),
                          child: pw.GridView(
                            crossAxisCount: 3,
                            children:
                                [4, 9, 2, 3, 5, 7, 8, 1, 6].map((n) {
                                  return _buildPdfGridCell(
                                    n,
                                    isPresent: _dobPresentNumbers.contains(n),
                                    font: boldFont,
                                  );
                                }).toList(),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(width: 40),
                    // ── Manual Grid ──
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'Manual Grid',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 13,
                            color: PdfColors.green800,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Container(
                          width: 210,
                          height: 210,
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.black,
                          ),
                          child: pw.GridView(
                            crossAxisCount: 3,
                            children:
                                [4, 9, 2, 3, 5, 7, 8, 1, 6].map((n) {
                                  return _buildPdfManualGridCell(
                                    n,
                                    font: boldFont,
                                  );
                                }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 40),

                if (_dcRelationship != null) ...[
                  pw.Text(
                    'Relationship Insight',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 18,
                      color: PdfColors.blueGrey900,
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  _buildPdfLangItem(
                    'ENGLISH',
                    _dcRelationship!['meaning_en'] ?? '',
                    PdfColors.blue700,
                    baseFont,
                  ),
                  pw.SizedBox(height: 12),
                  _buildPdfLangItem(
                    'Hindi',
                    _dcRelationship!['meaning_hi'] ?? '',
                    PdfColors.purple700,
                    hindiFont,
                    imageBytes: hindiImage,
                  ),
                  pw.SizedBox(height: 12),
                  _buildPdfLangItem(
                    'Gujarati',
                    _dcRelationship!['meaning_gu'] ?? '',
                    PdfColors.green700,
                    gujaratiFont,
                    imageBytes: gujaratiImage,
                  ),
                ],
              ],
        ),
      );

      final pdfBytes = await pdf.save();
      final directory =
          Platform.isWindows
              ? await getApplicationDocumentsDirectory()
              : await getTemporaryDirectory();
      final pdfPath =
          await File(
            '${directory.path}/dob_analysis_${dob.replaceAll('/', '_')}.pdf',
          ).create();
      await pdfPath.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [
          XFile(
            pdfPath.path,
            name: 'DOB_Analysis.pdf',
            mimeType: 'application/pdf',
          ),
        ],
        subject: 'Numerology Analysis Report',
        text:
            Platform.isWindows
                ? null
                : 'My Lo Shu Grid Analysis from Aank Sastra! ✨ #Numerology #AankSastra',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to generate PDF: $e')));
      }
    }
  }

  pw.Widget _buildPdfStatItem(
    String label,
    String value,
    PdfColor color,
    pw.Font font,
  ) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey700,
            font: font,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 32,
            fontWeight: pw.FontWeight.bold,
            color: color,
            font: font,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfGridCell(
    int val, {
    required bool isPresent,
    required pw.Font font,
  }) {
    final Map<int, PdfColor> colors = {
      4: PdfColors.red,
      9: PdfColors.lightGreen200,
      2: PdfColors.amber100,
      3: PdfColors.green300,
      5: PdfColors.blue50,
      7: PdfColors.blue200,
      8: PdfColors.orange100,
      1: PdfColors.deepPurple50,
      6: PdfColors.yellow50,
    };

    final Map<int, String> planetNames = {
      4: 'RAHU',
      9: 'MARS',
      2: 'MOON',
      3: 'JUPITER',
      5: 'MERCURY',
      7: 'KETU',
      8: 'SATURN',
      1: 'SUN',
      6: 'VENUS',
    };

    return pw.Container(
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        color: colors[val],
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            '$val',
            style: pw.TextStyle(
              fontSize: 32,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
              font: font,
            ),
          ),
          pw.Text(
            planetNames[val] ?? '',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
              font: font,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfManualGridCell(int val, {required pw.Font font}) {
    final Map<int, PdfColor> colors = {
      4: PdfColors.red,
      9: PdfColors.lightGreen200,
      2: PdfColors.amber100,
      3: PdfColors.green300,
      5: PdfColors.blue50,
      7: PdfColors.blue200,
      8: PdfColors.orange100,
      1: PdfColors.deepPurple50,
      6: PdfColors.yellow50,
    };

    final Map<int, String> planetNames = {
      4: 'RAHU',
      9: 'MARS',
      2: 'MOON',
      3: 'JUPITER',
      5: 'MERCURY',
      7: 'KETU',
      8: 'SATURN',
      1: 'SUN',
      6: 'VENUS',
    };

    // Read typed value from manual cell controller
    final enteredText = _manualCellControllers[val]?.text.trim() ?? '';

    return pw.Container(
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        color: colors[val],
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            enteredText.isEmpty ? ' ' : enteredText,
            style: pw.TextStyle(
              fontSize: 32,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
              font: font,
            ),
          ),
          pw.Text(
            planetNames[val] ?? '',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
              font: font,
            ),
          ),
        ],
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
