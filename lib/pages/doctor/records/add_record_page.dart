import 'package:flutter/material.dart';
import '../../../services/medical_record_service.dart';

class AddRecordPage extends StatefulWidget {
  final String token;
  final String patientId;

  const AddRecordPage({
    super.key,
    required this.token,
    required this.patientId,
  });

  @override
  State<AddRecordPage> createState() => _AddRecordPageState();
}

class _AddRecordPageState extends State<AddRecordPage> {
  // -------- Basic Info --------
  final ageCtrl = TextEditingController();
  String gender = "Male";

  // -------- Diseases --------
  final diseaseCtrl = TextEditingController();
  List<String> diseases = [];

  // -------- Allergies --------
  final allergyCtrl = TextEditingController();
  List<String> allergies = [];

  // -------- Medications --------
  final medNameCtrl = TextEditingController();
  final medDoseCtrl = TextEditingController();
  List<Map<String, String>> medications = [];

  // -------- Surgeries --------
  final surgeryTypeCtrl = TextEditingController();
  DateTime? surgeryDate;
  List<Map<String, dynamic>> surgeries = [];

  // -------- Family History --------
  final familyCtrl = TextEditingController();
  List<String> familyHistory = [];

  // -------- Lifestyle --------
  final exerciseCtrl = TextEditingController();
  final stressCtrl = TextEditingController();

  // -------- Symptoms & Notes --------
  final symptomsCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  bool isLoading = false;

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

  Future<void> saveRecord() async {
    if (ageCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى إدخال العمر")),
      );
      return;
    }

    if (exerciseCtrl.text.isEmpty || stressCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى تعبئة نمط الحياة")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final service = MedicalRecordService(
        baseUrl: "http://10.0.2.2:8000",
        token: widget.token,
      );

      // بناء Map متوافق مع backend
      final recordData = {
        "basic_info": {
          "age": int.parse(ageCtrl.text),
          "gender": gender,
        },
        "diseases": diseases,
        "allergies": allergies,
        "medications": medications,
        "surgeries": surgeries.map((s) => {
          "type": s["type"],
          "date": s["date"],
        }).toList(),
        "family_history": familyHistory,
        "lifestyle": {
          "exercise": exerciseCtrl.text,
          "stress_level": stressCtrl.text,
        },
        "current_symptoms": symptomsCtrl.text,
        "notes": notesCtrl.text,
        "update_history": [],
        "diagnosis": ""   // ✅ أضف هذا الحقل
      };



      final success = await service.createFullMedicalRecord(
        patientId: widget.patientId,
        data: recordData,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم حفظ السجل الطبي بالكامل")),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ فشل حفظ السجل")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ خطأ: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("إضافة سجل طبي شامل")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // -------- Basic Info --------
            const Text("المعلومات الأساسية", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              controller: ageCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "العمر", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField(
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "الجنس"),
              value: gender,
              items: const [
                DropdownMenuItem(value: "Male", child: Text("ذكر")),
                DropdownMenuItem(value: "Female", child: Text("أنثى")),
              ],
              onChanged: (v) => setState(() => gender = v!),
            ),

            const SizedBox(height: 20),

            // -------- Diseases --------
            sectionTitle("الأمراض"),
            rowAdd(
              controller: diseaseCtrl,
              hint: "اسم المرض",
              onAdd: () {
                setState(() {
                  diseases.add(diseaseCtrl.text);
                  diseaseCtrl.clear();
                });
              },
            ),
            listDisplay(diseases),

            const SizedBox(height: 20),

            // -------- Allergies --------
            sectionTitle("الحساسية"),
            rowAdd(
              controller: allergyCtrl,
              hint: "نوع الحساسية",
              onAdd: () {
                setState(() {
                  allergies.add(allergyCtrl.text);
                  allergyCtrl.clear();
                });
              },
            ),
            listDisplay(allergies),

            const SizedBox(height: 20),

            // -------- Medications --------
            sectionTitle("الأدوية"),
            TextField(controller: medNameCtrl, decoration: field("اسم الدواء")),
            const SizedBox(height: 8),
            TextField(controller: medDoseCtrl, decoration: field("الجرعة")),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  medications.add({
                    "name": medNameCtrl.text,
                    "dose": medDoseCtrl.text,
                  });
                  medNameCtrl.clear();
                  medDoseCtrl.clear();
                });
              },
              child: const Text("إضافة دواء"),
            ),
            listDisplay(medications.map((m) => "${m['name']} - ${m['dose']}").toList()),

            const SizedBox(height: 20),

            // -------- Surgeries --------
            sectionTitle("العمليات"),
            TextField(controller: surgeryTypeCtrl, decoration: field("نوع العملية")),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => surgeryDate = picked);
                  surgeries.add({
                    "type": surgeryTypeCtrl.text,
                    "date": picked.toIso8601String(),
                  });
                  surgeryTypeCtrl.clear();
                }
              },
              child: const Text("إضافة عملية"),
            ),
            listDisplay(surgeries.map((s) => "${s['type']} - ${s['date']}").toList()),

            const SizedBox(height: 20),

            // -------- Family History --------
            sectionTitle("التاريخ العائلي"),
            rowAdd(
              controller: familyCtrl,
              hint: "مرض وراثي",
              onAdd: () {
                setState(() {
                  familyHistory.add(familyCtrl.text);
                  familyCtrl.clear();
                });
              },
            ),
            listDisplay(familyHistory),

            const SizedBox(height: 20),

            // -------- Lifestyle --------
            sectionTitle("نمط الحياة"),
            TextField(controller: exerciseCtrl, decoration: field("التمارين الرياضية")),
            const SizedBox(height: 10),
            TextField(controller: stressCtrl, decoration: field("مستوى التوتر")),

            const SizedBox(height: 20),

            // -------- Symptoms --------
            sectionTitle("الأعراض الحالية"),
            TextField(controller: symptomsCtrl, decoration: field("الأعراض")),

            const SizedBox(height: 20),

            // -------- Notes --------
            sectionTitle("ملاحظات إضافية"),
            TextField(
              controller: notesCtrl,
              maxLines: 3,
              decoration: field("ملاحظات"),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : saveRecord,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("حفظ السجل الطبي"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------- UI Helpers -------
  Widget sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  InputDecoration field(String text) {
    return InputDecoration(labelText: text, border: const OutlineInputBorder());
  }

  Widget rowAdd({required TextEditingController controller, required String hint, required VoidCallback onAdd}) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: hint, border: const OutlineInputBorder()),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(onPressed: onAdd, child: const Text("إضافة"))
      ],
    );
  }

  Widget listDisplay(List<String> items) {
    return Column(
      children: items.map((e) => ListTile(title: Text(e))).toList(),
    );
  }
}
