import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const PanhaToolApp());
}

class PanhaToolApp extends StatelessWidget {
  const PanhaToolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PanhaTool Sign IPA',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF05070D),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F5C8),
          secondary: Color(0xFFFF4FD8),
        ),
        useMaterial3: true,
      ),
      home: const SignPage(),
    );
  }
}

class SignPage extends StatefulWidget {
  const SignPage({super.key});

  @override
  State<SignPage> createState() => _SignPageState();
}

class _SignPageState extends State<SignPage> {
  static const green = Color(0xFF00F5C8);
  static const pink = Color(0xFFFF4FD8);
  static const blue = Color(0xFF54B8FF);
  static const purple = Color(0xFF9B7BFF);
  static const yellow = Color(0xFFFFD166);

  final Dio dio = Dio();
  final TextEditingController serverController =
      TextEditingController();
  final TextEditingController passwordController =
      TextEditingController();

  PlatformFile? p12File;
  PlatformFile? ipaFile;
  PlatformFile? profileFile;

  final List<String> logs = [];

  int step = 0;
  bool busy = false;
  bool hidePassword = true;

  double progress = 0;

  String status = 'SYSTEM READY';
  String? error;
  String? installUrl;
  String? appTitle;
  String? appVersion;
  String? bundleId;

  @override
  void initState() {
    super.initState();
    log('PANHATOOL SIGN IPA INITIALIZED', green);
    log('GIVE ME YOUR P12 FILE', yellow);
  }

  @override
  void dispose() {
    serverController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void log(String message, [Color color = Colors.white70]) {
    setState(() {
      logs.add(message);
      if (logs.length > 60) logs.removeAt(0);
    });
  }

  void notify(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<PlatformFile?> pickFile(List<String> extensions) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      allowMultiple: false,
      withData: false,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;

    if (file.path == null) {
      notify('Cannot access selected file.');
      return null;
    }

    return file;
  }

  Future<void> chooseP12() async {
    final file = await pickFile(['p12', 'pfx']);
    if (file == null || !mounted) return;

    setState(() {
      p12File = file;
      step = 1;
      status = 'P12 CERTIFICATE RECEIVED';
    });

    log('P12 RECEIVED: ${file.name}', green);
    log('NEXT: ENTER P12 PASSWORD', yellow);
  }

  void continuePassword() {
    if (passwordController.text.isEmpty) {
      notify('Please enter your P12 password.');
      return;
    }

    setState(() {
      step = 2;
      status = 'PASSWORD RECEIVED';
    });

    log('PASSWORD ENTERED', pink);
    log('NEXT: GIVE ME YOUR IPA FILE', yellow);
  }

  Future<void> chooseIpa() async {
    final file = await pickFile(['ipa']);
    if (file == null || !mounted) return;

    setState(() {
      ipaFile = file;
      step = 3;
      status = 'IPA FILE RECEIVED';
    });

    log('IPA RECEIVED: ${file.name}', blue);
    log('NEXT: GIVE ME YOUR MOBILEPROVISION', yellow);
  }

  Future<void> chooseProfile() async {
    final file = await pickFile(['mobileprovision']);
    if (file == null || !mounted) return;

    setState(() {
      profileFile = file;
      step = 4;
      status = 'ALL FILES RECEIVED';
    });

    log('PROFILE RECEIVED: ${file.name}', purple);
    log('STARTING REMOTE SIGNING...', green);

    await signIpa();
  }

  Future<void> signIpa() async {
    if (busy) return;

    final base = serverController.text.trim().replaceFirst(
      RegExp(r'/+$'),
      '',
    );

    final uri = Uri.tryParse(base);

    if (uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      setState(() {
        error = 'Enter a valid signing server URL.';
        status = 'SERVER URL ERROR';
      });
      log('ERROR: INVALID SERVER URL', Colors.redAccent);
      return;
    }

    if (uri.scheme != 'https' &&
        uri.host != 'localhost' &&
        uri.host != '10.0.2.2') {
      setState(() {
        error = 'Use HTTPS for remote signing.';
        status = 'SECURE CONNECTION REQUIRED';
      });
      return;
    }

    if (p12File?.path == null ||
        ipaFile?.path == null ||
        profileFile?.path == null ||
        passwordController.text.isEmpty) {
      notify('Complete all signing steps first.');
      return;
    }

    setState(() {
      busy = true;
      progress = 0;
      error = null;
      installUrl = null;
      status = 'CONNECTING TO SIGNING SERVER';
    });

    try {
      final form = FormData.fromMap({
        'p12': await MultipartFile.fromFile(
          p12File!.path!,
          filename: p12File!.name,
        ),
        'password': passwordController.text,
        'ipa': await MultipartFile.fromFile(
          ipaFile!.path!,
          filename: ipaFile!.name,
        ),
        'mobileprovision': await MultipartFile.fromFile(
          profileFile!.path!,
          filename: profileFile!.name,
        ),
      });

      log('UPLOADING FILES TO SERVER...', blue);

      final response = await dio.post(
        '$base/api/sign',
        data: form,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(minutes: 10),
          receiveTimeout: const Duration(minutes: 15),
        ),
        onSendProgress: (sent, total) {
          if (!mounted || total <= 0) return;

          setState(() {
            progress = (sent / total) * 0.75;
            status =
                'UPLOADING ${(sent / total * 100).toStringAsFixed(0)}%';
          });
        },
      );

      final data = response.data;

      if (data is! Map ||
          data['ok'] != true ||
          data['installUrl'] is! String) {
        throw Exception(
          data is Map
              ? (data['error'] ?? 'Signing failed').toString()
              : 'Invalid server response',
        );
      }

      final returnedUrl = Uri.tryParse(
        data['installUrl'].toString(),
      );

      if (returnedUrl == null ||
          !returnedUrl.hasScheme ||
          returnedUrl.host.isEmpty ||
          !['https', 'http', 'itms-services']
              .contains(returnedUrl.scheme)) {
        throw Exception('Invalid installation URL');
      }

      if (!mounted) return;

      setState(() {
        installUrl = returnedUrl.toString();
        appTitle = (data['title'] ?? ipaFile!.name).toString();
        appVersion = data['version']?.toString();
        bundleId = data['bundleId']?.toString();

        progress = 1;
        status = 'SIGNING SUCCESSFUL';
      });

      log('SIGNING COMPLETED SUCCESSFULLY', green);
      log('APP: $appTitle', blue);
      if (bundleId != null) log('BUNDLE ID: $bundleId!', purple);
      log('INSTALL LINK RECEIVED', green);
    } on DioException catch (e) {
      final body = e.response?.data;
      final message = body is Map
          ? (body['error'] ?? body['message'])?.toString()
          : null;

      final reason =
          message ?? e.message ?? 'Server connection failed';

      if (!mounted) return;

      setState(() {
        error = reason;
        status = 'SIGNING FAILED';
      });

      log('ERROR: $reason', Colors.redAccent);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        status = 'SIGNING FAILED';
      });

      log('ERROR: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> installApp() async {
    if (installUrl == null) return;

    final uri = Uri.parse(installUrl!);

    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!ok) notify('Could not open installation link.');
  }

  void reset() {
    setState(() {
      p12File = null;
      ipaFile = null;
      profileFile = null;
      passwordController.clear();

      step = 0;
      busy = false;
      progress = 0;

      error = null;
      installUrl = null;
      appTitle = null;
      appVersion = null;
      bundleId = null;

      status = 'SYSTEM READY';
      logs.clear();
    });

    log('NEW SESSION STARTED', green);
    log('GIVE ME YOUR P12 FILE', yellow);
  }

  Widget tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        border: Border.all(color: color.withOpacity(.5)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget terminal(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(
        '› $text',
        style: TextStyle(
          color: color,
          fontSize: 11,
          height: 1.5,
        ),
      ),
    );
  }

  Widget actionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback callback,
  ) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: busy ? null : callback,
        icon: Icon(icon),
        label: Text(text),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
        ),
      ),
    );
  }

  Widget fileStep({
    required int number,
    required String title,
    required String filename,
    required Color color,
    required bool complete,
    required bool active,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF101725),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: active
              ? color
              : complete
                  ? color.withOpacity(.4)
                  : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(.13),
            child: complete
                ? Icon(Icons.check, color: color)
                : Text(
                    '$number',
                    style: TextStyle(color: color),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  complete ? filename : 'Waiting for selection...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: complete ? color : Colors.white38,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (active)
            TextButton(
              onPressed: busy ? null : onPressed,
              child: Text(
                'SELECT',
                style: TextStyle(color: color),
              ),
            )
          else if (!complete)
            const Icon(Icons.lock_outline, color: Colors.white24),
        ],
      ),
    );
  }

  Widget passwordStep() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF101725),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: pink),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          tag('STEP 02', pink),
          const SizedBox(height: 10),
          const Text(
            'GIVE ME YOUR P12 PASSWORD',
            style: TextStyle(
              color: pink,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: passwordController,
            obscureText: hidePassword,
            decoration: InputDecoration(
              hintText: 'P12 password',
              filled: true,
              fillColor: const Color(0xFF05070D),
              suffixIcon: IconButton(
                icon: Icon(
                  hidePassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() => hidePassword = !hidePassword);
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 10),
          actionButton(
            'CONTINUE TO IPA',
            Icons.arrow_forward,
            pink,
            () {
              if (passwordController.text.isEmpty) {
                notify('Enter your password.');
                return;
              }

              setState(() => step = 2);
              log('PASSWORD RECEIVED', pink);
              log('GIVE ME YOUR IPA FILE', yellow);
            },
          ),
        ],
      ),
    );
  }

  Widget signingResult() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF0B261F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: green),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified, color: green),
              SizedBox(width: 8),
              Text(
                'SIGNING SUCCESSFUL',
                style: TextStyle(
                  color: green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'APP: ${appTitle ?? "Signed app"}',
            style: const TextStyle(color: green, fontSize: 11),
          ),
          if (appVersion != null)
            Text(
              'VERSION: $appVersion',
              style: const TextStyle(color: blue, fontSize: 11),
            ),
          if (bundleId != null)
            Text(
              'BUNDLE ID: $bundleId',
              style: const TextStyle(color: purple, fontSize: 11),
            ),
          const SizedBox(height: 14),
          actionButton(
            'INSTALL APP ON IPHONE',
            Icons.install_mobile,
            green,
            installApp,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF05070D),
        title: const Row(
          children: [
            Icon(Icons.terminal, color: green),
            SizedBox(width: 8),
            Text(
              'PANHA',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            Text(
              'TOOL',
              style: TextStyle(
                color: pink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: busy ? null : reset,
            icon: const Icon(Icons.refresh, color: blue),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF17243A),
                  Color(0xFF29162E),
                  Color(0xFF102D2A),
                ],
              ),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: purple.withOpacity(.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tag('REMOTE SIGNING TERMINAL', green),
                const SizedBox(height: 13),
                const Text(
                  'SIGN IPA',
                  style: TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'One step at a time. Your app, your signature.',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  '● $status',
                  style: const TextStyle(
                    color: green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFF020509),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: green.withOpacity(.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    tag('TERMINAL OUTPUT', green),
                    const Spacer(),
                    const Text(
                      'PANHA_OS',
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...logs.map(
                  (entry) => terminal(
                    entry,
                    entry.contains('ERROR')
                        ? Colors.redAccent
                        : entry.contains('SUCCESS')
                            ? green
                            : Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          fileStep(
            number: 1,
            title: 'P12 CERTIFICATE',
            filename: p12File?.name ?? '',
            color: green,
            complete: p12File != null,
            active: step == 0,
            onPressed: chooseP12,
          ),

          if (step == 1) ...[
            const SizedBox(height: 10),
            passwordStep(),
          ],

          if (step >= 2) ...[
            const SizedBox(height: 10),
            fileStep(
              number: 2,
              title: 'P12 PASSWORD',
              filename: 'PASSWORD ENTERED • HIDDEN',
              color: pink,
              complete: true,
              active: false,
              onPressed: () {},
            ),
          ],

          if (step >= 2) ...[
            const SizedBox(height: 10),
            fileStep(
              number: 3,
              title: 'IPA APPLICATION',
              filename: ipaFile?.name ?? '',
              color: blue,
              complete: ipaFile != null,
              active: step == 2,
              onPressed: chooseIpa,
            ),
          ],

          if (step >= 3) ...[
            const SizedBox(height: 10),
            fileStep(
              number: 4,
              title: 'MOBILEPROVISION',
              filename: profileFile?.name ?? '',
              color: purple,
              complete: profileFile != null,
              active: step == 3,
              onPressed: chooseProfile,
            ),
          ],

          if (busy) ...[
            const SizedBox(height: 15),
            const Text(
              'SIGNING IN PROGRESS',
              style: TextStyle(color: yellow, fontSize: 11),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress == 0 ? null : progress,
              color: green,
              backgroundColor: Colors.white12,
            ),
          ],

          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              'ERROR: $error',
              style: const TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: busy ? null : signIpa,
              child: const Text('RETRY'),
            ),
          ],

          if (installUrl != null) ...[
            const SizedBox(height: 18),
            signingResult(),
          ],

          const SizedBox(height: 22),

          ExpansionTile(
            title: const Text(
              'SERVER SETTINGS',
              style: TextStyle(
                color: blue,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            children: [
              TextField(
                controller: serverController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  hintText: 'https://your-signing-server.com',
                  filled: true,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),

          const SizedBox(height: 18),
          const Center(
            child: Text(
              'PANHATOOL SIGN IPA',
              style: TextStyle(
                color: Colors.white24,
                fontSize: 9,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> chooseP12() async {
    final file = await pickFile(['p12', 'pfx']);
    if (file == null) return;

    setState(() {
      p12File = file;
      step = 1;
      status = 'P12 RECEIVED';
    });

    log('P12 RECEIVED: ${file.name}');
    log('ENTER YOUR P12 PASSWORD');
  }

  Future<void> chooseIpa() async {
    final file = await pickFile(['ipa']);
    if (file == null) return;

    setState(() {
      ipaFile = file;
      step = 3;
      status = 'IPA RECEIVED';
    });

    log('IPA RECEIVED: ${file.name}');
    log('GIVE ME YOUR MOBILEPROVISION');
  }

  Future<void> chooseProfile() async {
    final file = await pickFile(['mobileprovision']);
    if (file == null) return;

    setState(() {
      profileFile = file;
      step = 4;
      status = 'STARTING SIGNING';
    });

    log('MOBILEPROVISION RECEIVED');
    log('STARTING REMOTE SIGNING...');

    await signIpa();
  }

  Future<PlatformFile?> pickFile(List<String> extensions) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;

    if (file.path == null) {
      notify('Cannot read selected file.');
      return null;
    }

    return file;
  }

  Future<void> signIpa() async {
    if (busy) return;

    final base = serverController.text.trim().replaceFirst(
      RegExp(r'/+$'),
      '',
    );

    final uri = Uri.tryParse(base);

    if (uri == null ||
        uri.host.isEmpty ||
        !['https', 'http'].contains(uri.scheme) ||
        (uri.scheme == 'http' &&
            uri.host != 'localhost' &&
            uri.host != '10.0.2.2')) {
      setState(() {
        error = 'Enter a valid HTTPS signing server URL.';
        status = 'SERVER URL ERROR';
      });
      return;
    }

    if (p12File?.path == null ||
        ipaFile?.path == null ||
        profileFile?.path == null ||
        passwordController.text.isEmpty) {
      notify('Complete all steps first.');
      return;
    }

    setState(() {
      busy = true;
      progress = 0;
      error = null;
      installUrl = null;
      status = 'UPLOADING FILES';
    });

    try {
      final form = FormData.fromMap({
        'p12': await MultipartFile.fromFile(
          p12File!.path!,
          filename: p12File!.name,
        ),
        'password': passwordController.text,
        'ipa': await MultipartFile.fromFile(
          ipaFile!.path!,
          filename: ipaFile!.name,
        ),
        'mobileprovision': await MultipartFile.fromFile(
          profileFile!.path!,
          filename: profileFile!.name,
        ),
      });

      final response = await dio.post(
        '$base/api/sign',
        data: form,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(minutes: 10),
          receiveTimeout: const Duration(minutes: 15),
        ),
        onSendProgress: (sent, total) {
          if (!mounted || total <= 0) return;

          setState(() {
            progress = (sent / total) * .75;
            status =
                'UPLOADING ${(sent / total * 100).toStringAsFixed(0)}%';
          });
        },
      );

      final data = response.data;

      if (data is! Map ||
          data['ok'] != true ||
          data['installUrl'] is! String) {
        throw Exception(
          data is Map
              ? (data['error'] ?? 'Signing failed').toString()
              : 'Invalid server response',
        );
      }

      final returned = Uri.tryParse(
        data['installUrl'].toString(),
      );

      if (returned == null ||
          !returned.hasScheme ||
          returned.host.isEmpty ||
          !['https', 'http', 'itms-services']
              .contains(returned.scheme)) {
        throw Exception('Invalid installation URL');
      }

      if (!mounted) return;

      setState(() {
        installUrl = returned.toString();
        appTitle = (data['title'] ?? ipaFile!.name).toString();
        appVersion = data['version']?.toString();
        bundleId = data['bundleId']?.toString();
        progress = 1;
        status = 'SIGNING SUCCESSFUL';
      });

      log('SIGNING SUCCESSFUL');
      log('APP: $appTitle');
      if (appVersion != null) log('VERSION: $appVersion');
      if (bundleId != null) log('BUNDLE ID: $bundleId');
      log('INSTALL LINK RECEIVED');
    } on DioException catch (e) {
      final body = e.response?.data;
      final message = body is Map
          ? (body['error'] ?? body['message'])?.toString()
          : null;

      if (!mounted) return;

      setState(() {
        error = message ?? e.message ?? 'Server connection failed';
        status = 'SIGNING FAILED';
      });

      log('ERROR: $error');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        status = 'SIGNING FAILED';
      });

      log('ERROR: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> installApp() async {
    if (installUrl == null) return;

    final ok = await launchUrl(
      Uri.parse(installUrl!),
      mode: LaunchMode.externalApplication,
    );

    if (!ok) notify('Could not open installation link.');
  }
}
