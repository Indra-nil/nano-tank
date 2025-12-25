import 'package:flutter/material.dart';
import '../models/tank.dart';
import '../widgets/glass_card.dart';

class PumpSetupScreen extends StatefulWidget {
  final Tank tank;
  const PumpSetupScreen({Key? key, required this.tank}) : super(key: key);

  @override
  State<PumpSetupScreen> createState() => _PumpSetupScreenState();
}

class _PumpSetupScreenState extends State<PumpSetupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Pump data
  String pumpName = '';
  bool isPriming = false;
  final Map<String, double> calibrationData = {'3s': 0.0, '5s': 0.0, '10s': 0.0};
  bool calibrationComplete = false;
  double finalMeasurement = 0.0;
  
  // ✅ WEEKLY SCHEDULE DATA
  List<bool> weeklyEnabled = [true, true, true, true, true, true, true];
  List<String> days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  String scheduleType = 'single';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('New Pump Setup')),
      body: TabBarView(
        controller: _tabController,
        children: [
          _NameStep(onNameChanged: (name) => setState(() => pumpName = name ?? ''), onNext: _nextStep),
          _PrimeStep(isPriming: isPriming, onPrime: _togglePriming, onNext: _nextStep),
          _CalibrationStep(
            calibrationData: calibrationData,
            onDataChanged: (data) => calibrationData.addAll(data),
            onComplete: () {
              setState(() => calibrationComplete = true);
              _nextStep();
            },
          ),
          _VerifyStep(
            finalMeasurement: finalMeasurement,
            onMeasurementChanged: (value) => setState(() => finalMeasurement = value),
            onPass: _nextStep,
            onFail: () => _tabController.animateTo(2),
          ),
          _ScheduleStep(
            pumpName: pumpName,
            weeklyEnabled: weeklyEnabled,
            days: days,
            scheduleType: scheduleType,
            onWeeklyChanged: (index, enabled) => _updateWeekly(index, enabled),
            onScheduleTypeChanged: (type) => setState(() => scheduleType = type ?? 'single'),
            onComplete: _savePump,
          ),
        ],
      ),
    );
  }

  void _nextStep() => _tabController.animateTo(_tabController.index + 1);  // ✅ FIXED
  void _togglePriming() => setState(() => isPriming = !isPriming);
  void _updateWeekly(int index, bool enabled) {
    setState(() => weeklyEnabled[index] = enabled);
  }
  
  void _savePump() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pump "$pumpName" saved!\n${weeklyEnabled.where((e) => e).length}/7 days')),
    );
    Navigator.pop(context);
  }
}

/// STEP 1: Name - ✅ FIXED
class _NameStep extends StatelessWidget {
  final ValueChanged<String?> onNameChanged;  // ✅ FIXED
  final VoidCallback onNext;
  const _NameStep({required this.onNameChanged, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: GlassCard(
        child: Column(children: [
          Icon(Icons.edit, size: 64, color: Colors.cyan),
          SizedBox(height: 20),
          Text('Pump Name', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          TextField(
            onChanged: onNameChanged,
            decoration: InputDecoration(
              labelText: 'K+, Fe, NO3, PO4...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: Icon(Icons.water_drop),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          Spacer(),
          ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, minimumSize: Size(double.infinity, 56)),
            child: Text('Continue', style: TextStyle(fontSize: 18)),
          ),
        ]),
      ),
    );
  }
}

/// STEP 2: Prime
class _PrimeStep extends StatelessWidget {
  final bool isPriming;
  final VoidCallback onPrime;
  final VoidCallback onNext;
  const _PrimeStep({required this.isPriming, required this.onPrime, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: GlassCard(
        child: Column(children: [
          Icon(Icons.flash_on, size: 80, color: Colors.orange),
          SizedBox(height: 20),
          Text('Priming', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text('Fill dosing tube from container to outlet tip', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
          SizedBox(height: 40),
          ElevatedButton(
            onPressed: onPrime,
            style: ElevatedButton.styleFrom(
              backgroundColor: isPriming ? Colors.red : Colors.orange,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: Text(isPriming ? 'STOP' : 'START PRIMING', style: TextStyle(fontSize: 18)),
          ),
          Spacer(),
          ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, minimumSize: Size(double.infinity, 56)),
            child: Text('Tube Filled → Continue'),
          ),
        ]),
      ),
    );
  }
}

/// STEP 3: Calibration
class _CalibrationStep extends StatefulWidget {
  final Map<String, double> calibrationData;
  final Function(Map<String, double>) onDataChanged;
  final VoidCallback onComplete;
  const _CalibrationStep({required this.calibrationData, required this.onDataChanged, required this.onComplete});

  @override
  State<_CalibrationStep> createState() => _CalibrationStepState();
}

class _CalibrationStepState extends State<_CalibrationStep> {
  int currentTest = 0;
  final List<String> tests = ['3s', '5s', '10s'];
  double measuredMl = 0.0;

  void _startTest() {
    Future.delayed(Duration(seconds: int.parse(tests[currentTest][0])), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dosed ${tests[currentTest]}! Measure cylinder.')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: GlassCard(
        child: Column(children: [
          Icon(Icons.precision_manufacturing, size: 64, color: Colors.purple),
          SizedBox(height: 20),
          Text('Calibration', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text('Measure cylinder → Enter value'),
          SizedBox(height: 20),
          Row(children: tests.asMap().entries.map((e) => Expanded(child: Container(
            height: 8, margin: EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(color: e.key < currentTest ? Colors.cyan : Colors.grey, borderRadius: BorderRadius.circular(4)),
          ))).toList()),
          SizedBox(height: 20),
          Text('Test ${currentTest + 1}: ${tests[currentTest]}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          Row(children: [
            Expanded(child: TextField(
              keyboardType: TextInputType.number,
              onChanged: (v) => measuredMl = double.tryParse(v) ?? 0.0,
              decoration: InputDecoration(labelText: 'Measured (ml)', border: OutlineInputBorder()),
            )),
            SizedBox(width: 12),
            ElevatedButton(onPressed: _startTest, child: Text('START')),
          ]),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: currentTest < 2 ? () {
              widget.calibrationData[tests[currentTest]] = measuredMl;
              setState(() => currentTest++);
              widget.onDataChanged(widget.calibrationData);
            } : widget.onComplete,
            child: Text(currentTest < 2 ? 'Next Test' : 'Complete'),
          ),
        ]),
      ),
    );
  }
}

/// STEP 4: Verify
class _VerifyStep extends StatefulWidget {
  final double finalMeasurement;
  final ValueChanged<double> onMeasurementChanged;  // ✅ FIXED
  final VoidCallback onPass;
  final VoidCallback onFail;
  const _VerifyStep({required this.finalMeasurement, required this.onMeasurementChanged, required this.onPass, required this.onFail});

  @override
  State<_VerifyStep> createState() => _VerifyStepState();
}

class _VerifyStepState extends State<_VerifyStep> {
  void _test4ml() {
    Future.delayed(Duration(seconds: 10), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dosed 4ml! Measure & enter.')));
      }
    });
  }

  bool get isValid => widget.finalMeasurement >= 3.95 && widget.finalMeasurement <= 4.05;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: GlassCard(
        child: Column(children: [
          Icon(Icons.check_circle, size: 80, color: isValid ? Colors.green : Colors.orange),
          SizedBox(height: 20),
          Text('Final Check', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text('Dose 4ml → Must be 3.95-4.05ml'),
          SizedBox(height: 20),
          TextField(
            keyboardType: TextInputType.number,
            onChanged: (v) => widget.onMeasurementChanged(double.tryParse(v) ?? 0.0),  // ✅ FIXED
            decoration: InputDecoration(labelText: 'Measured (ml)', border: OutlineInputBorder()),
          ),
          SizedBox(height: 20),
          Text('${widget.finalMeasurement.toStringAsFixed(2)}ml', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isValid ? Colors.green : Colors.red)),
          Text(isValid ? '✅ Perfect!' : '⚠️ 3.95-4.05ml range'),
          SizedBox(height: 30),
          ElevatedButton(onPressed: _test4ml, style: ElevatedButton.styleFrom(backgroundColor: Colors.purple), child: Text('Test 4ml')),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: isValid ? widget.onPass : widget.onFail,
            style: ElevatedButton.styleFrom(backgroundColor: isValid ? Colors.green : Colors.red, minimumSize: Size(double.infinity, 56)),
            child: Text(isValid ? '✅ Calibration Perfect!' : '🔄 Recalibrate'),
          ),
        ]),
      ),
    );
  }
}

/// STEP 5: ✅ FULL WEEKLY SCHEDULE - ✅ FIXED
class _ScheduleStep extends StatelessWidget {
  final String pumpName;
  final List<bool> weeklyEnabled;
  final List<String> days;
  final String scheduleType;
  final Function(int, bool) onWeeklyChanged;
  final ValueChanged<String?> onScheduleTypeChanged;  // ✅ FIXED
  final VoidCallback onComplete;
  
  const _ScheduleStep({
    required this.pumpName, required this.weeklyEnabled, required this.days,
    required this.scheduleType, required this.onWeeklyChanged, required this.onScheduleTypeChanged, required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: GlassCard(
        child: Column(children: [
          Icon(Icons.schedule, size: 64, color: Colors.cyan),
          SizedBox(height: 20),
          Text('Dosing Schedule', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          Text('Daily: 4.0ml', style: TextStyle(fontSize: 18)),
          
          // Delivery method
          Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Delivery:', style: TextStyle(fontWeight: FontWeight.bold)),
            RadioListTile<String>(title: Text('4ml at once'), value: 'single', groupValue: scheduleType, onChanged: onScheduleTypeChanged),  // ✅ FIXED
            RadioListTile<String>(title: Text('2ml × 2 (2hr apart)'), value: 'split_2ml', groupValue: scheduleType, onChanged: onScheduleTypeChanged),  // ✅ FIXED
            RadioListTile<String>(title: Text('1ml × 8 (2hr apart)'), value: 'split_1ml', groupValue: scheduleType, onChanged: onScheduleTypeChanged),  // ✅ FIXED
          ])),
          
          // ✅ FULL WEEKLY SCHEDULE
          Text('Weekly Schedule:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          GlassCard(padding: EdgeInsets.all(16), child: Wrap(
            spacing: 8,
            children: List.generate(7, (i) => FilterChip(
              label: Text(days[i]),
              selected: weeklyEnabled[i],
              onSelected: (selected) => onWeeklyChanged(i, selected),
              selectedColor: Colors.cyan.withOpacity(0.3),
              checkmarkColor: Colors.white,
            )),
          )),
          SizedBox(height: 16),
          Text('${weeklyEnabled.where((e) => e).length}/7 days active', style: TextStyle(color: Colors.cyan, fontSize: 16)),
          
          Spacer(),
          ElevatedButton(
            onPressed: onComplete,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, minimumSize: Size(double.infinity, 56)),
            child: Text('Save "$pumpName"', style: TextStyle(fontSize: 18)),
          ),
        ]),
      ),
    );
  }
}