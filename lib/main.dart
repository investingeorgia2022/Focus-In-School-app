 import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

void main() => runApp(const SchoolFocusApp());

class SchoolFocusApp extends StatelessWidget {
  const SchoolFocusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const LoginScreen(),
    );
  }
}

// LOGIN
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final _nameController = TextEditingController();
  String _selectedClass = 'მე-9 კლასი';

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? name = prefs.getString("user_name");

    if(name != null){
      _navigateToMain(name, prefs.getString("user_class") ?? _selectedClass);
    }
  }

  void _navigateToMain(String name, String group) {
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) =>
            MainNavigation(name: name, classGroup: group)));
  }

  Future<void> saveUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("user_name", _nameController.text);
    await prefs.setString("user_class", _selectedClass);

    _navigateToMain(_nameController.text, _selectedClass);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                  labelText: "შენი სახელი",
                  border: OutlineInputBorder()),
            ),

            const SizedBox(height:20),

            ElevatedButton(
              onPressed: () {
                if(_nameController.text.isNotEmpty){
                  saveUser();
                }
              },
              child: const Text("შესვლა"),
            )

          ]),
        ),
      ),
    );
  }
}

// NAVIGATION
class MainNavigation extends StatefulWidget {
  final String name;
  final String classGroup;
  const MainNavigation({super.key, required this.name, required this.classGroup});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {

  int _currentIndex = 0;
  int _points = 150;

  @override
  void initState() {
    super.initState();
    loadPoints();
  }

  Future<void> loadPoints() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _points = prefs.getInt("user_points") ?? 150;
    });
  }

  Future<void> updatePoints(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _points += amount;
    });
    await prefs.setInt("user_points", _points);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          FocusPage(points: _points, onAdd: updatePoints),
          const Center(child: Text("რეიტინგი მალე")),
          const Center(child: Text("მაღაზია მალე")),
          ProfilePage(name: widget.name, classGroup: widget.classGroup, points: _points),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i)=>setState(()=>_currentIndex=i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: "ფოკუსი"),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: "რეიტინგი"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: "მაღაზია"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "პროფილი"),
        ],
      ),
    );
  }
}

// FOCUS
class FocusPage extends StatefulWidget {

  final int points;
  final Function(int) onAdd;

  const FocusPage({super.key, required this.points, required this.onAdd});

  @override
  State<FocusPage> createState()=>_FocusPageState();
}

class _FocusPageState extends State<FocusPage>{

  int s=0;
  bool active=false;
  Timer? t;

  void go(){
    if(active){
      t?.cancel();
      widget.onAdd(s~/10);
      setState((){s=0;active=false;});
    }else{
      active=true;
      t=Timer.periodic(const Duration(seconds:1),(timer){
        setState(()=>s++);
      });
    }
  }

  @override
  Widget build(BuildContext context){

    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center,children:[

        Text("${widget.points} ⭐",style: const TextStyle(fontSize:40)),

        Text("${(s~/60)}:${(s%60).toString().padLeft(2,'0')}",
            style: const TextStyle(fontSize:30)),

        ElevatedButton(onPressed: go, child: Text(active?"STOP":"START"))

      ]),
    );
  }
}

// PROFILE
class ProfilePage extends StatelessWidget {

  final String name;
  final String classGroup;
  final int points;

  const ProfilePage({super.key, required this.name, required this.classGroup, required this.points});

  Future<void> reset() async{
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  @override
  Widget build(BuildContext context){

    return Column(children:[

      const SizedBox(height:50),

      Text(name,style: const TextStyle(fontSize:24)),

      Text("ბალანსი: $points ⭐"),

      const Spacer(),

      TextButton(
          onPressed: () async {
            await reset();
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder:(_)=>const LoginScreen()));
          },
          child: const Text("Reset",style: TextStyle(color: Colors.red))
      ),

      const SizedBox(height:20)

    ]);
  }
}
