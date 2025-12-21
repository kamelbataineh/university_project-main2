import 'package:flutter/material.dart';
import '../../../core/config/app_font.dart';
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
  // -------- Controllers --------
  final ageCtrl = TextEditingController();
  final diseaseCtrl = TextEditingController();
  final allergyCtrl = TextEditingController();
  final medNameCtrl = TextEditingController();
  final medDoseCtrl = TextEditingController();
  final surgeryTypeCtrl = TextEditingController();
  final familyCtrl = TextEditingController();
  final exerciseCtrl = TextEditingController();
  final stressCtrl = TextEditingController();
  final symptomsCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  final diagnosisCtrl = TextEditingController();

  String gender = "Male";
  DateTime? surgeryDate;

  List<String> diseases = [];
  List<String> allergies = [];
  List<Map<String, String>> medications = [];
  List<Map<String, dynamic>> surgeries = [];
  List<String> familyHistory = [];

  bool isLoading = false;

  // -------- Save --------
  Future<void> saveRecord() async {
    if (ageCtrl.text.isEmpty) return;

    setState(() => isLoading = true);

    final recordData = {
      "basic_info": {
        "age": int.parse(ageCtrl.text),
        "gender": gender,
      },
      "diseases": diseases,
      "allergies": allergies,
      "medications": medications,
      "surgeries": surgeries,
      "family_history": familyHistory,
      "lifestyle": {
        "exercise": exerciseCtrl.text,
        "stress_level": stressCtrl.text,
      },
      "current_symptoms": symptomsCtrl.text,
      "notes": notesCtrl.text,
      "update_history": [],
      "diagnosis": diagnosisCtrl.text,
    };

    final service = MedicalRecordService(
      baseUrl: "http://10.0.2.2:8000",
      token: widget.token,
    );

    await service.createFullMedicalRecord(
      patientId: widget.patientId,
      data: recordData,
    );

    setState(() => isLoading = false);
    Navigator.pop(context, true);
  }

  // -------- UI --------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),
      appBar: AppBar(
        title: const Text("Add Medical Record"),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade400,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // Basic Info
            sectionCard(
              icon: Icons.person,
              title: "Basic Information",
              child: Column(
                children: [
                  input(ageCtrl, "Age", TextInputType.number),
                  const SizedBox(height: 12),
                  DropdownButtonFormField(
                    value: gender,
                    items: const [
                      DropdownMenuItem(value: "Male", child: Text("Male")),
                      DropdownMenuItem(value: "Female", child: Text("Female")),
                    ],
                    onChanged: (v) => setState(() => gender = v!),
                    decoration: field("Gender"),
                  ),
                ],
              ),
            ),

            // Diseases
            sectionList(
              title: "Diseases",
              icon: Icons.favorite,
              controller: diseaseCtrl,
              list: diseases,
              hint: "Disease name",
            ),

            // Allergies
            sectionList(
              title: "Allergies",
              icon: Icons.warning,
              controller: allergyCtrl,
              list: allergies,
              hint: "Allergy type",
            ),

            // Medications
            sectionCard(
              icon: Icons.medication,
              title: "Medications",
              child: Column(
                children: [
                  input(medNameCtrl, "Medication Name"),
                  const SizedBox(height: 8),
                  input(medDoseCtrl, "Dose"),
                  addBtn(() {
                    if (medNameCtrl.text.isNotEmpty &&
                        medDoseCtrl.text.isNotEmpty) {
                      setState(() {
                        medications.add({
                          "name": medNameCtrl.text,
                          "dose": medDoseCtrl.text,
                        });
                        medNameCtrl.clear();
                        medDoseCtrl.clear();
                      });
                    }
                  }),
                  listView(medications
                      .map((m) => "${m['name']} - ${m['dose']}")
                      .toList(),
                          (i) => setState(() => medications.removeAt(i))),
                ],
              ),
            ),

            // Surgeries
            sectionCard(
              icon: Icons.local_hospital,
              title: "Surgeries",
              child: Column(
                children: [
                  input(surgeryTypeCtrl, "Surgery Type"),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade400,
                      // لون الخلفية اللي تحبه
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7), // حواف دائرية
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      surgeryDate == null
                          ? "Select Surgery Date"
                          : surgeryDate!.toLocal().toString().split(' ')[0],
                      style: const TextStyle(
                        color: Colors.white, // نص باللون الأبيض
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) setState(() => surgeryDate = date);
                    },
                  ),

                  const SizedBox(height: 8),
                  ElevatedButton.icon(

                    icon: const Icon(Icons.add, color: Colors.white,),
                    label: const Text(
                      "Add Surgery",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade400,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14), // حواف دائرية
                      ),
                      elevation: 3,
                    ),
                    onPressed: () {
                      if (surgeryTypeCtrl.text.isNotEmpty &&
                          surgeryDate != null) {
                        setState(() {
                          surgeries.add({
                            "type": surgeryTypeCtrl.text,
                            "date": surgeryDate!.toIso8601String(),
                          });
                          surgeryTypeCtrl.clear();
                          surgeryDate = null;
                        });
                      }
                    },
                  ),
                  Column(
                    children: List.generate(surgeries.length, (i) {
                      final s = surgeries[i];
                      return ListTile(
                        title: Text("${s['type']} - ${s['date'].substring(
                            0, 10)}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              setState(() => surgeries.removeAt(i)),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Family History
            sectionList(
              title: "Family History",
              icon: Icons.group,
              controller: familyCtrl,
              list: familyHistory,
              hint: "Hereditary condition",
            ),

            // Lifestyle
            sectionCard(
              icon: Icons.directions_run,
              title: "Lifestyle",
              child: Column(
                children: [
                  input(exerciseCtrl, "Exercise"),
                  const SizedBox(height: 8),
                  input(stressCtrl, "Stress Level"),
                ],
              ),
            ),

            // Symptoms
            sectionCard(
              icon: Icons.notes,
              title: "Symptoms",
              child: input(symptomsCtrl, "Symptoms"),
            ),

            // Notes
            sectionCard(
              icon: Icons.edit_note,
              title: "Notes",
              child: input(notesCtrl, "Notes", TextInputType.text),
            ),

            // Diagnosis
            sectionCard(
              icon: Icons.assignment,
              title: "Diagnosis",
              child: input(diagnosisCtrl, "diagnosis", TextInputType.text, 3),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: MediaQuery
                  .of(context)
                  .size
                  .width / 2.2,
              child: ElevatedButton(
                onPressed: isLoading ? null : saveRecord,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade400,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 3,
                  shadowColor: Colors.white,
                  minimumSize: const Size(120, 38), // نفس حجم الأزرار الصغيرة
                ),
                child: isLoading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  "Save Medical Record",
                  style: AppFont.regular(
                    size: 13,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // -------- Components --------
  Widget sectionCard(
      {required IconData icon, required String title, required Widget child}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.indigo.shade100,
                  child: Icon(icon, color: Colors.indigo.shade400),
                ),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget sectionList(
      {required String title, required IconData icon, required TextEditingController controller, required List<
          String> list, required String hint}) {
    return sectionCard(
      icon: icon,
      title: title,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: input(controller, hint)),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    setState(() {
                      list.add(controller.text);
                      controller.clear();
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade400,
                  // لون الخلفية اللي تحبه
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14), // حواف دائرية
                  ),
                  elevation: 2,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 18),
              ),
            ],
          ),

          listView(list, (i) => setState(() => list.removeAt(i))),
        ],
      ),
    );
  }

  Widget listView(List<String> items, Function(int) onRemove) {
    return Column(
      children: List.generate(items.length, (i) {
        return ListTile(
          title: Text(items[i]),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => onRemove(i),
          ),
        );
      }),
    );
  }

  Widget input(TextEditingController c, String label,
      [TextInputType type = TextInputType.text, int max = 1]) {
    return TextField(
      controller: c,
      keyboardType: type,
      maxLines: max,
      decoration: field(label),
    );
  }

  InputDecoration field(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget addBtn(VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo.shade400,
        // لون الخلفية
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14), // حواف مستديرة
        ),
        padding: const EdgeInsets.all(12),
        // حجم الكبسة
        elevation: 3,
        shadowColor: Colors.white,
        minimumSize: const Size(50, 38), // حجم الزر
      ),
      child: const Icon(Icons.add, size: 18, color: Colors.white),
    );
  }
}