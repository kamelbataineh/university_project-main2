import 'package:flutter/material.dart';
import '../../../services/medical_record_service.dart';

class EditRecordPage extends StatefulWidget {
  final String token;
  final String recordId;
  final String patientId;

  const EditRecordPage({Key? key, required this.token, required this.recordId, required this.patientId}) : super(key: key);

  @override
  State<EditRecordPage> createState() => _EditRecordPageState();
}

class _EditRecordPageState extends State<EditRecordPage> {
  final _formKey = GlobalKey<FormState>();
  bool loading = true;

  // ======== Controllers ========
  final ageCtrl = TextEditingController();
  String gender = "Male";

  final diseaseCtrl = TextEditingController();
  List<String> diseases = [];

  final allergyCtrl = TextEditingController();
  List<String> allergies = [];

  final medNameCtrl = TextEditingController();
  final medDoseCtrl = TextEditingController();
  List<Map<String, String>> medications = [];

  final surgeryTypeCtrl = TextEditingController();
  List<Map<String, dynamic>> surgeries = [];

  final familyCtrl = TextEditingController();
  List<String> familyHistory = [];

  final exerciseCtrl = TextEditingController();
  final stressCtrl = TextEditingController();

  final symptomsCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchRecord();
  }

  @override
  void dispose() {
    ageCtrl.dispose();
    diseaseCtrl.dispose();
    allergyCtrl.dispose();
    medNameCtrl.dispose();
    medDoseCtrl.dispose();
    surgeryTypeCtrl.dispose();
    familyCtrl.dispose();
    exerciseCtrl.dispose();
    stressCtrl.dispose();
    symptomsCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }
  Future<void> updateRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final service = MedicalRecordService(baseUrl: "http://10.0.2.2:8000", token: widget.token);

      final data = {
        "basic_info": {"age": int.parse(ageCtrl.text), "gender": gender},
        "diseases": diseases,
        "allergies": allergies,
        "medications": medications,
        "surgeries": surgeries,
        "family_history": familyHistory,
        "lifestyle": {"exercise": exerciseCtrl.text, "stress_level": stressCtrl.text},
        "current_symptoms": symptomsCtrl.text,
        "notes": notesCtrl.text,
        "update_history": [],
        "diagnosis": ""
      };

      final success = await service.updateRecord(recordId: widget.recordId, data: data);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم تحديث السجل الطبي بنجاح")),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ فشل تحديث السجل")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ خطأ: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> fetchRecord() async {
    try {
      final service = MedicalRecordService(baseUrl: "http://10.0.2.2:8000", token: widget.token);
      final record = await service.getRecord(widget.recordId);
      final data = record["data"];

      setState(() {
        ageCtrl.text = data["basic_info"]["age"].toString();
        gender = data["basic_info"]["gender"] ?? "Male";
        diseases = List<String>.from(data["diseases"] ?? []);
        allergies = List<String>.from(data["allergies"] ?? []);
        medications = List<Map<String, String>>.from(data["medications"] ?? []);
        surgeries = List<Map<String, dynamic>>.from(data["surgeries"] ?? []);
        familyHistory = List<String>.from(data["family_history"] ?? []);
        exerciseCtrl.text = data["lifestyle"]["exercise"] ?? "";
        stressCtrl.text = data["lifestyle"]["stress_level"] ?? "";
        symptomsCtrl.text = data["current_symptoms"] ?? "";
        notesCtrl.text = data["notes"] ?? "";
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ خطأ: $e")));
    }
  }


  // ======= UI Helpers =======
  Widget sectionTitle(String title) => Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  InputDecoration field(String text) => InputDecoration(labelText: text, border: const OutlineInputBorder());
  Widget rowAdd({required TextEditingController controller, required String hint, required VoidCallback onAdd}) => Row(
    children: [
      Expanded(child: TextField(controller: controller, decoration: InputDecoration(labelText: hint, border: const OutlineInputBorder()))),
      const SizedBox(width: 10),
      ElevatedButton(onPressed: onAdd, child: const Text("إضافة")),
    ],
  );
  Widget listDisplay(List<String> items) => Column(children: items.map((e) => ListTile(title: Text(e))).toList());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تعديل السجل الطبي"), backgroundColor: Colors.purple, centerTitle: true),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ===== Basic Info =====
              sectionTitle("المعلومات الأساسية"),
              TextField(controller: ageCtrl, keyboardType: TextInputType.number, decoration: field("العمر")),
              const SizedBox(height: 10),
              DropdownButtonFormField(
                value: gender,
                decoration: field("الجنس"),
                items: const [
                  DropdownMenuItem(value: "Male", child: Text("ذكر")),
                  DropdownMenuItem(value: "Female", child: Text("أنثى")),
                ],
                onChanged: (v) => setState(() => gender = v!),
              ),
              const SizedBox(height: 20),

              // ===== Diseases =====
              sectionTitle("الأمراض"),
              rowAdd(controller: diseaseCtrl, hint: "اسم المرض", onAdd: () { setState(() { diseases.add(diseaseCtrl.text); diseaseCtrl.clear(); }); }),
              listDisplay(diseases),

              // ===== Allergies =====
              sectionTitle("الحساسية"),
              rowAdd(controller: allergyCtrl, hint: "نوع الحساسية", onAdd: () { setState(() { allergies.add(allergyCtrl.text); allergyCtrl.clear(); }); }),
              listDisplay(allergies),

              // ===== Medications =====
              sectionTitle("الأدوية"),
              TextField(controller: medNameCtrl, decoration: field("اسم الدواء")),
              const SizedBox(height: 8),
              TextField(controller: medDoseCtrl, decoration: field("الجرعة")),
              ElevatedButton(onPressed: () { setState(() { medications.add({"name": medNameCtrl.text,"dose": medDoseCtrl.text}); medNameCtrl.clear(); medDoseCtrl.clear(); }); }, child: const Text("إضافة دواء")),
              listDisplay(medications.map((m) => "${m['name']} - ${m['dose']}").toList()),

              // ===== Surgeries =====
              sectionTitle("العمليات"),
              TextField(controller: surgeryTypeCtrl, decoration: field("نوع العملية")),
              ElevatedButton(
                onPressed: () async {
                  final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(1950), lastDate: DateTime.now());
                  if (picked != null) {
                    setState(() { surgeries.add({"type": surgeryTypeCtrl.text, "date": picked.toIso8601String()}); surgeryTypeCtrl.clear(); });
                  }
                },
                child: const Text("إضافة عملية"),
              ),
              listDisplay(surgeries.map((s) => "${s['type']} - ${s['date']}").toList()),

              // ===== Family History =====
              sectionTitle("التاريخ العائلي"),
              rowAdd(controller: familyCtrl, hint: "مرض وراثي", onAdd: () { setState(() { familyHistory.add(familyCtrl.text); familyCtrl.clear(); }); }),
              listDisplay(familyHistory),

              // ===== Lifestyle =====
              sectionTitle("نمط الحياة"),
              TextField(controller: exerciseCtrl, decoration: field("التمارين الرياضية")),
              const SizedBox(height: 10),
              TextField(controller: stressCtrl, decoration: field("مستوى التوتر")),

              // ===== Symptoms =====
              sectionTitle("الأعراض الحالية"),
              TextField(controller: symptomsCtrl, decoration: field("الأعراض")),

              // ===== Notes =====
              sectionTitle("ملاحظات إضافية"),
              TextField(controller: notesCtrl, maxLines: 3, decoration: field("ملاحظات")),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : updateRecord,
                  child: loading ? const CircularProgressIndicator(color: Colors.white) : const Text("تحديث السجل"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
