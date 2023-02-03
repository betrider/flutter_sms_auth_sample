import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sms/firebase_options.dart';

FirebaseAuth auth = FirebaseAuth.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 비동기 사용시 추가
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); // 필수추가
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  // 재발송 토큰번호
  int? resendToken;
  // 인증 고유코드
  String? verificationId;
  // 인증번호
  String smsCode = '';
  // 발송여부
  bool isSend = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: isSend == false
            ? ElevatedButton(
                onPressed: () {
                  setState(() {
                    isSend = true;
                  });
                  verifyPhoneNumber();
                },
                child: Text('인증번호 발송'),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => verifyPhoneNumber(),
                    child: Text('인증번호 재발송'),
                  ),
                  SizedBox(height: 16,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              smsCode = value;
                            });
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: '인증번호를 입력해주세요.',
                          ),
                        ),
                      ),
                      SizedBox(width: 16,),
                      ElevatedButton(
                        onPressed: smsCode.length == 6 ? () => signInWithCredential() : null,
                        child: Text('인증'),
                      ),
                    ],
                  )
                ],
              ),
      ),
    );
  }

  /// 인증번호 발송&재발송
  void verifyPhoneNumber() async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+82 10 1111 2222',
      timeout: const Duration(seconds: 60),
      forceResendingToken: resendToken,
      // Android 기기에서 SMS 코드를 자동으로 처리합니다.
      verificationCompleted: (PhoneAuthCredential credential) async {
        print('verificationCompleted');
        await auth.signInWithCredential(credential,);
      },
      // 유효하지 않은 전화번호 또는 SMS 할당량 초과 여부와 같은 실패 이벤트를 처리합니다.
      verificationFailed: (FirebaseAuthException e) {
        print('verificationFailed');
        if (e.code == 'invalid-phone-number') {
          print('The provided phone number is not valid.');
        }
      },
      // 사용자에게 코드를 입력하라는 메시지를 표시하는 데 사용되는 코드가 Firebase에서 기기로 전송된 경우를 처리합니다.
      codeSent: (String verificationId, int? resendToken) async {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('인증번호가 발송되었습니다.'),
          ),
        );
        setState(() {
          this.verificationId = verificationId;
          this.resendToken = resendToken;
        });
      },
      // 자동 SMS 코드 처리가 실패할 때의 시간 초과를 처리합니다.
      codeAutoRetrievalTimeout: (String verificationId) {
        print('codeAutoRetrievalTimeout');
      },
    );
  }

  /// 인증
  void signInWithCredential() async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(verificationId: verificationId!, smsCode: smsCode);
      UserCredential userCredential = await auth.signInWithCredential(credential);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('인증 성공'),
        ),
      );
      print(userCredential);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('인증 실패'),
        ),
      );
    }
  }
}
