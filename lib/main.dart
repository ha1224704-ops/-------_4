import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

void main() => runApp(const QuranApp());

class QuranApp extends StatefulWidget {
  const QuranApp({super.key});
  @override
  State<QuranApp> createState() => _QuranAppState();
}

class _QuranAppState extends State<QuranApp> {
  double fs = 22;
  bool dark = true;
  String reciter = "ياسر الدوسري";

  @override
  void initState() {
    super.initState();
    _load();
  }

  _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      fs = p.getDouble('fs') ?? 22;
      dark = p.getBool('dark') ?? true;
      reciter = p.getString('reciter') ?? "ياسر الدوسري";
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: dark
          ? ThemeData.dark(useMaterial3: true).copyWith(
              scaffoldBackgroundColor: const Color(0xFF0F0F0F))
          : ThemeData.light(useMaterial3: true),
      home: Home(
        fs: fs,
        dark: dark,
        reciter: reciter,
        onChanged: (f, d, r) async {
          final p = await SharedPreferences.getInstance();
          await p.setDouble('fs', f);
          await p.setBool('dark', d);
          await p.setString('reciter', r);
          setState(() {
            fs = f;
            dark = d;
            reciter = r;
          });
        },
      ),
    );
  }
}

class Home extends StatefulWidget {
  final double fs;
  final bool dark;
  final String reciter;
  final Function(double, bool, String) onChanged;
  const Home(
      {super.key,
      required this.fs,
      required this.dark,
      required this.reciter,
      required this.onChanged});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int idx = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: [
        SurahList(fs: widget.fs),
        const AzkarPage(),
        SebhaPage(),
        SettingsPage(
            fs: widget.fs,
            dark: widget.dark,
            reciter: widget.reciter,
            onChanged: widget.onChanged)
      ][idx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: idx,
        onTap: (i) => setState(() => idx = i),
        selectedItemColor: const Color(0xFFD4AF37),
        backgroundColor: const Color(0xFF1A1A1A),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "القرآن"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "أدعية"),
          BottomNavigationBarItem(icon: Icon(Icons.circle), label: "تسبيح"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "الاعدادات"),
        ],
      ),
    );
  }
}

class SurahList extends StatelessWidget {
  final double fs;
  const SurahList({super.key, required this.fs});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("القرآن الكريم - نور القلوب"),
          centerTitle: true,
          backgroundColor: const Color(0xFF151515)),
      body: ListView.builder(
        itemCount: 114,
        itemBuilder: (c, i) {
          int n = i + 1;
          return Card(
            color: const Color(0xFF1E1E1E),
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: ListTile(
              leading: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37),
                    borderRadius: BorderRadius.circular(10)),
                child: Center(
                    child: Text("$n",
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold))),
              ),
              title: Text(quran.getSurahNameArabic(n),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text("${quran.getVerseCount(n)} آية",
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
              trailing:
                  const Icon(Icons.arrow_forward_ios, color: Color(0xFFD4AF37), size: 16),
              onTap: () => Navigator.push(
                  c,
                  MaterialPageRoute(
                      builder: (_) => ReaderPage(surah: n, fs: fs))),
            ),
          );
        },
      ),
    );
  }
}

class ReaderPage extends StatelessWidget {
  final int surah;
  final double fs;
  const ReaderPage({super.key, required this.surah, required this.fs});

  void showFullVerse(BuildContext context, int verseNum) {
    String text = quran.getVerse(surah, verseNum, verseEndSymbol: false);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text("آية $verseNum - ${quran.getSurahNameArabic(surah)}",
            style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 14)),
        content: Text(text,
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: fs + 2, height: 1.8, color: Colors.white)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إغلاق",
                  style: TextStyle(color: Color(0xFFD4AF37)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37)),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("تم نسخ الآية")));
            },
            child: const Text("نسخ", style: TextStyle(color: Colors.black)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int cnt = quran.getVerseCount(surah);
    return Scaffold(
      appBar: AppBar(title: Text(quran.getSurahNameArabic(surah))),
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: cnt + 1,
        itemBuilder: (c, i) {
          if (i == cnt) {
            return Container(
              margin: const EdgeInsets.only(top: 25, bottom: 30),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(15),
                  border:
                      Border.all(color: const Color(0xFFD4AF37), width: 1.5)),
              child: const Column(
                children: [
                  Text("صدقة جارية",
                      style: TextStyle(color: Color(0xFFD4AF37))),
                  Text("الفاتحة الى روح المرحوم",
                      style: TextStyle(color: Colors.white70)),
                  Text("ناصر عزيز",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Divider(color: Color(0xFFD4AF37)),
                  Text(
                    "بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيمِ\nالْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ\nالرَّحْمٰنِ الرَّحِيمِ\nمَالِكِ يَوْمِ الدِّينِ\nإِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ\nاهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ\nصِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, height: 1.9, fontSize: 18),
                  ),
                ],
              ),
            );
          }
          String verseText = quran.getVerse(surah, i + 1, verseEndSymbol: false);
          return InkWell(
            onTap: () => showFullVerse(context, i + 1),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(verseText,
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: fs, height: 1.9)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text("آية ${i + 1}",
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white70)),
                      ),
                      Text(quran.getVerseEndSymbol(i + 1),
                          style: const TextStyle(color: Colors.white38)),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class AzkarPage extends StatelessWidget {
  const AzkarPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("أدعية"), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: const [
          Card(
            color: Color(0xFF1E1E1E),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("دعاء للمرحوم ناصر عزيز",
                      style: TextStyle(
                          color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                  Divider(color: Colors.white10),
                  Text(
                      "اللهم اغفر لناصر عزيز وارحمه وعافه واعف عنه وأكرم نزله ووسع مدخله واغسله بالماء والثلج والبرد",
                      textAlign: TextAlign.right,
                      style: TextStyle(height: 1.7)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class SebhaPage extends StatefulWidget {
  @override
  State<SebhaPage> createState() => _SebhaPageState();
}

class _SebhaPageState extends State<SebhaPage> {
  int count = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("المسبحة"), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("$count",
                style: const TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4AF37))),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => setState(() => count++),
              child: Container(
                width: 160,
                height: 160,
                decoration: const BoxDecoration(
                    color: Color(0xFFD4AF37), shape: BoxShape.circle),
                child: const Center(
                    child: Text("سبح",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 26,
                            fontWeight: FontWeight.bold))),
              ),
            ),
            TextButton(
                onPressed: () => setState(() => count = 0),
                child: const Text("تصفير",
                    style: TextStyle(color: Colors.white38))),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  final double fs;
  final bool dark;
  final String reciter;
  final Function(double, bool, String) onChanged;
  const SettingsPage(
      {super.key,
      required this.fs,
      required this.dark,
      required this.reciter,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("الإعدادات"), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            color: const Color(0xFF1E1E1E),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("حجم الخط"),
                  Slider(
                      value: fs,
                      min: 16,
                      max: 34,
                      divisions: 9,
                      activeColor: const Color(0xFFD4AF37),
                      onChanged: (v) => onChanged(v, dark, reciter)),
                ],
              ),
            ),
          ),
          Card(
            color: const Color(0xFF1E1E1E),
            child: SwitchListTile(
                title: const Text("الوضع الليلي"),
                value: dark,
                activeColor: const Color(0xFFD4AF37),
                onChanged: (v) => onChanged(fs, v, reciter)),
          ),
          Card(
            color: const Color(0xFF1E1E1E),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("القارئ المفضل (للإصدار القادم)"),
                  RadioListTile(
                      value: "ياسر الدوسري",
                      groupValue: reciter,
                      title: const Text("ياسر الدوسري",
                          style: TextStyle(fontSize: 13)),
                      activeColor: const Color(0xFFD4AF37),
                      onChanged: (v) => onChanged(fs, dark, v!)),
                  RadioListTile(
                      value: "محمد صديق المنشاوي",
                      groupValue: reciter,
                      title: const Text("محمد صديق المنشاوي",
                          style: TextStyle(fontSize: 13)),
                      activeColor: const Color(0xFFD4AF37),
                      onChanged: (v) => onChanged(fs, dark, v!)),
                  RadioListTile(
                      value: "عبد الباسط عبد الصمد",
                      groupValue: reciter,
                      title: const Text("عبد الباسط عبد الصمد",
                          style: TextStyle(fontSize: 13)),
                      activeColor: const Color(0xFFD4AF37),
                      onChanged: (v) => onChanged(fs, dark, v!)),
                ],
              ),
            ),
          ),
          Card(
            color: const Color(0xFFD4AF37).withOpacity(0.15),
            child: ListTile(
              leading:
                  const Icon(Icons.support_agent, color: Color(0xFFD4AF37)),
              title: const Text("مراسلة المطور",
                  style: TextStyle(
                      color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
              onTap: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xFF1E1E1E),
                  title: const Text("مراسلة المطور",
                      style: TextStyle(color: Color(0xFFD4AF37))),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("في حال وجود مشكلة اذكر اسم السورة ورقم الآية",
                          style: TextStyle(color: Colors.white70)),
                      SizedBox(height: 8),
                      Text("noor.alquloob.app@gmail.com",
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("اغلاق")),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37)),
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(
                            text: "noor.alquloob.app@gmail.com"));
                        Navigator.pop(context);
                      },
                      child: const Text("نسخ الإيميل",
                          style: TextStyle(color: Colors.black)),
                    )
                  ],
                ),
              ),
            ),
          ),
          Card(
            color: const Color(0xFF1E1E1E),
            child: Column(
              children: [
                ListTile(
                    leading: const Icon(Icons.privacy_tip),
                    title: const Text("سياسة التطبيق"),
                    onTap: () => showDialog(
                        context: context,
                        builder: (_) => const AlertDialog(
                            backgroundColor: Color(0xFF1E1E1E),
                            title: Text("سياسة التطبيق",
                                style: TextStyle(color: Color(0xFFD4AF37))),
                            content: Text(
                                "التطبيق بدون إعلانات ولا يجمع بيانات\nصدقة جارية لروح المرحوم ناصر عزيز",
                                style: TextStyle(color: Colors.white70))))),
                const Divider(color: Colors.white10, height: 1),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text("مشاركة التطبيق"),
                  onTap: () {
                    Clipboard.setData(const ClipboardData(
                        text:
                            "حمل تطبيق نور القلوب - صدقة لروح المرحوم ناصر عزيز"));
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("تم النسخ")));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD4AF37))),
            child: const Column(
              children: [
                Text("نور القلوب",
                    style: TextStyle(
                        color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                Text("صدقة جارية لروح المرحوم ناصر عزيز",
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text("بدون إعلانات - v3.1",
                    style: TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          )
        ],
      ),
    );
  }
}