import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/config/app_font.dart';
import '../../../services/medical_record_service.dart';

class EditRecordPage extends StatefulWidget {
  final String token;
  final String recordId;
  final String patientId;

  const EditRecordPage({
    super.key,
    required this.token,
    required this.recordId,
    required this.patientId,
  });

  @override
  State<EditRecordPage> createState() => _EditRecordPageState();
}

class _EditRecordPageState extends State<EditRecordPage> {
  final _formKey = GlobalKey<FormState>();
  bool loading = true;

  // ===== Controllers =====
  final ageCtrl = TextEditingController();
  String gender = "Male";

  final diseaseCtrl = TextEditingController();
  List<String> diseases = [];

  final allergyCtrl = TextEditingController();
  List<String> allergies = [];

  final medNameCtrl = TextEditingController();
  final medDoseCtrl = TextEditingController();
  List<Map<String, dynamic>> medications = [];

  final surgeryTypeCtrl = TextEditingController();
  DateTime? surgeryDate;
  List<Map<String, dynamic>> surgeries = [];

  final familyCtrl = TextEditingController();
  List<String> familyHistory = [];

  final exerciseCtrl = TextEditingController();
  final stressCtrl = TextEditingController();

  final symptomsCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  final diagnosisCtrl = TextEditingController();

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
    diagnosisCtrl.dispose();
    super.dispose();
  }

  String doctorName = "Unknown Doctor"; // ⬅ اسم الدكتور

  // ================= Fetch Record =================
  Future<void> fetchRecord() async {
    try {
      final service = MedicalRecordService(
          baseUrl: "http://10.0.2.2:8000", token: widget.token);

      final record = await service.getRecord(widget.recordId);
      final data = record["data"];

      // 🟢 هنا نجلب اسم الدكتور من السجل نفسه
      if (record.containsKey("doctor_id")) {
        // إذا الباكند رجع object مع الاسم مباشرة
        doctorName = record["doctor_name"] ?? "Unknown Doctor";
        // أو إذا الباكند لا يرجع الاسم، نقدر نضع placeholder ثابت:
        // doctorName = "Dr. John";
      }

      setState(() {
        ageCtrl.text = data["basic_info"]["age"].toString();
        gender = data["basic_info"]["gender"] ?? "Male";
        diseases = List<String>.from(data["diseases"] ?? []);
        allergies = List<String>.from(data["allergies"] ?? []);
        medications =
            List<Map<String, dynamic>>.from(data["medications"] ?? []);
        surgeries = List<Map<String, dynamic>>.from(data["surgeries"] ?? []);
        familyHistory = List<String>.from(data["family_history"] ?? []);
        exerciseCtrl.text = data["lifestyle"]["exercise"] ?? "";
        stressCtrl.text = data["lifestyle"]["stress_level"] ?? "";
        symptomsCtrl.text = data["current_symptoms"] ?? "";
        notesCtrl.text = data["notes"] ?? "";
        diagnosisCtrl.text = data["diagnosis"] ?? "";
        loading = false;
      });
    } catch (e) {
      loading = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading record: $e")),
      );
    }
  }

  // ================= Update Record =================
  Future<void> updateRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final service = MedicalRecordService(
          baseUrl: "http://10.0.2.2:8000", token: widget.token);

      final data = {
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
        "updated_by": doctorName, // ⬅ استخدم الاسم هنا مباشرة
      };

      final success = await service.updateRecord(
        recordId: widget.recordId,
        patientId: widget.patientId,
        data: data,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Medical record updated successfully")),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update record")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  // ================= UI Helpers =================
  InputDecoration field(String text) =>
      InputDecoration(labelText: text, border: const OutlineInputBorder());

  Widget sectionCard(String title, IconData icon, Widget child) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                Text(title,
                    style: const TextStyle(
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

  Widget rowAdd({
    required TextEditingController controller,
    required String hint,
    required VoidCallback onAdd,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: field(hint),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: onAdd,
          child: const Text("+", style: TextStyle(fontSize: 18 ,color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo.shade400,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );

  }

  Widget removableList(List<String> items, Function(int) onDelete) {
    return Column(
      children: List.generate(items.length, (i) {
        return Card(
          child: ListTile(
            title: Text(items[i]),
            trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => onDelete(i)),
          ),
        );
      }),
    );
  }

  Widget removableMapList(
      List<Map<String, dynamic>> items, Function(int) onDelete, String label) {
    return Column(
      children: List.generate(items.length, (i) {
        return Card(
          child: ListTile(
            title: Text(
                "${items[i]['name'] ?? items[i]['type']} - ${items[i]['dose'] ?? items[i]['date'] ?? ''}"),
            trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => onDelete(i)),
          ),
        );
      }),
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text("Edit Medical Record",style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.indigo.shade400,
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ===== Basic Info =====
                    sectionCard(
                      "Basic Information",
                      Icons.person,
                      Column(
                        children: [
                          TextFormField(
                            controller: ageCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              // <--- يسمح بالأرقام فقط
                            ],
                            decoration: field("Age"),
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField(
                            value: gender,
                            decoration: field("Gender"),
                            items: const [
                              // DropdownMenuItem(value: "Male", child: Text("Male")),
                              DropdownMenuItem(
                                  value: "Female", child: Text("Female")),
                            ],
                            onChanged: (v) => setState(() => gender = v!),
                          ),
                        ],
                      ),
                    ),

                    // ===== Diseases =====
                    sectionCard(
                      "Diseases",
                      Icons.favorite,
                      Column(
                        children: [
                          rowAdd(
                            controller: diseaseCtrl,
                            hint: "Disease name",
                            onAdd: () {
                              if (diseaseCtrl.text.isNotEmpty) {
                                setState(() {
                                  diseases.add(diseaseCtrl.text);
                                  diseaseCtrl.clear();
                                });
                              }
                            },
                          ),
                          removableList(diseases,
                              (i) => setState(() => diseases.removeAt(i))),
                        ],
                      ),
                    ),

                    // ===== Allergies =====
                    sectionCard(
                      "Allergies",
                      Icons.warning,
                      Column(
                        children: [
                          rowAdd(
                            controller: allergyCtrl,
                            hint: "Allergy type",
                            onAdd: () {
                              if (allergyCtrl.text.isNotEmpty) {
                                setState(() {
                                  allergies.add(allergyCtrl.text);
                                  allergyCtrl.clear();
                                });
                              }
                            },
                          ),
                          removableList(allergies,
                              (i) => setState(() => allergies.removeAt(i))),
                        ],
                      ),
                    ),
                     SizedBox(height: 8),

                    // ===== Medications =====
                    sectionCard(
                      "Medications",
                      Icons.medication,
                      Column(
                        children: [
                          TextField(
                              controller: medNameCtrl,
                              decoration: field("Medication Name")),
                          const SizedBox(height: 15),
                          TextField(
                              controller: medDoseCtrl,
                              decoration: field("Dose")),
                          const SizedBox(height: 15),

                          ElevatedButton(
                            onPressed: () {
                              if (medNameCtrl.text.isNotEmpty &&
                                  medDoseCtrl.text.isNotEmpty) {
                                setState(() {
                                  medications.add({
                                    "name": medNameCtrl.text,
                                    "dose": medDoseCtrl.text
                                  });
                                  medNameCtrl.clear();
                                  medDoseCtrl.clear();
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.shade400,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 3,
                              shadowColor: Colors.white,
                              minimumSize:  Size(50, 38),
                            ),
                            child:  Text("Add Medication",style: TextStyle(color: Colors.white),),
                          ),
                          removableMapList(
                              medications,
                              (i) => setState(() => medications.removeAt(i)),
                              "Medication"),
                        ],
                      ),
                    ),

                    sectionCard(
                      "Surgeries",
                      Icons.local_hospital,
                      Column(
                        children: [
                          TextField(
                            controller: surgeryTypeCtrl,
                            decoration: field("Surgery Type"),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) setState(() => surgeryDate = date);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.shade400, // لون الخلفية الجديد
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14), // حواف مستديرة
                              ),
                              minimumSize: const Size(150, 38), // الحجم الجديد
                            ),
                            child: Text(
                              surgeryDate == null
                                  ? "Select Surgery Date"
                                  : DateFormat('yyyy/MM/dd').format(surgeryDate!),
                              style: const TextStyle(fontSize: 14, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              if (surgeryTypeCtrl.text.isNotEmpty && surgeryDate != null) {
                                setState(() {
                                  surgeries.add({
                                    "type": surgeryTypeCtrl.text,
                                    "date": DateFormat('yyyy-MM-dd').format(surgeryDate!),
                                  });
                                  surgeryTypeCtrl.clear();
                                  surgeryDate = null;
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.shade400, // لون الخلفية الجديد
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              minimumSize: const Size(150, 38),
                            ),
                            child: const Text(
                              "Add Surgery",
                              style: TextStyle(fontSize: 14, color: Colors.white),
                            ),
                          ),
                          removableMapList(
                            surgeries,
                                (i) => setState(() => surgeries.removeAt(i)),
                            "Surgery",
                          ),
                        ],
                      ),
                    ),

                    // ===== Family History =====
                    sectionCard(
                      "Family History",
                      Icons.group,
                      Column(
                        children: [
                          rowAdd(
                            controller: familyCtrl,
                            hint: "Hereditary condition",
                            onAdd: () {
                              if (familyCtrl.text.isNotEmpty) {
                                setState(() {
                                  familyHistory.add(familyCtrl.text);
                                  familyCtrl.clear();
                                });
                              }
                            },
                          ),
                          removableList(familyHistory,
                              (i) => setState(() => familyHistory.removeAt(i))),
                        ],
                      ),
                    ),

                    // ===== Lifestyle =====
                    sectionCard(
                      "Lifestyle",
                      Icons.directions_run,
                      Column(
                        children: [
                          TextFormField(
                              controller: exerciseCtrl,
                              decoration: field("Exercise")),
                          const SizedBox(height: 8),
                          TextFormField(
                              controller: stressCtrl,
                              decoration: field("Stress Level")),
                        ],
                      ),
                    ),

                    // ===== Symptoms =====
                    sectionCard(
                      "Symptoms",
                      Icons.notes,
                      TextField(
                          controller: symptomsCtrl,
                          decoration: field("Symptoms")),
                    ),

                    // ===== Notes =====
                    sectionCard(
                      "Notes",
                      Icons.edit_note,
                      TextField(
                          controller: notesCtrl,
                          maxLines: 3,
                          decoration: field("Notes")),
                    ),

                    // ===== Diagnosis =====
                    sectionCard(
                      "Diagnosis",
                      Icons.assignment,
                      TextField(
                          controller: diagnosisCtrl,
                          maxLines: 3,
                          decoration: field("diagnosis")),
                    ),

                    const SizedBox(height: 20),

                ElevatedButton(
                        onPressed: loading ? null : updateRecord,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade400,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 3,
                          shadowColor: Colors.white,
                          minimumSize: const Size(120, 38), // نفس حجم الأزرار الصغيرة
                        ),
                        child: loading
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          "Update Medical Record",
                          style: AppFont.regular(
                            size: 13,
                            weight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    SizedBox(height: 50),

                  ],
                ),
              ),
            ),
    );
  }
}
