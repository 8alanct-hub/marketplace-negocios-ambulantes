import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async{

    WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
  
    url: 'https://pnwtcmbdcywulywkwwdp.supabase.co',
    
    publishableKey: 'sb_publishable_VUVWBoLWEmUBVDT00suY2Q_ZOXxG0Q9'
  
  );

  runApp(const MyApp());

}

class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    
    return const MaterialApp(

      home: Scaffold(
        backgroundColor: Colors.blueGrey,
        body: Center(
          child: 

              Text(
                'Test 3',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.yellow
                )),

        ),
      ),
    );

  }


}

