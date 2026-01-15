// flutter pub run flutter_launcher_icons:main
// ipconfig





///////////////////

//
// final String emulatorUrl = "http://10.0.2.2:8000/";
// final String emulatorUrlNoSlash = "http://10.0.2.2:8000";
//
// final String phoneUrl = "http://172.20.10.6:8000/";
// final String phoneUrlNoSlash = "http://172.20.10.6:8000";
//
// final String baseUrl = isEmulator ? emulatorUrl : phoneUrl;
// final String baseUrl1 = isEmulator ? emulatorUrlNoSlash : phoneUrlNoSlash;
// //  localhost
// final baseUrl                     = "http://10.0.2.2:8000/";
// final baseUrl1                     = "http://10.0.2.2:8000";
//
// 10.0.2.2 هو عنوان خاص يُستخدم داخل Android Emulator للوصول إلى localhost الخاص بالجهاز الحقيقي.





final  String baseUrl                     = "http://10.0.2.2:8000/";
final String baseUrl1                     = "http://10.0.2.2:8000";
final String wsUrl                        = "ws://10.0.2.2:8000/chat/ws";


final String chatMarkDelivered = "$baseUrl1/api/chat/delivered";

final String chatMessages      =  "$baseUrl1/chat/messages/";

final String chatSend          = "$baseUrl1/chat/send";
final String chatUploadFile    = "$baseUrl1/chat/upload_file/";
final String chatList          = "$baseUrl1/chat/list";


// ---------- Admin ----------
final adminLogin               = baseUrl + "admin/login";
final adminCheck               = baseUrl + "admin/check";


//  (Doctor)
final doctorRegister           = baseUrl + "doctors/register-temp";
final doctorLogin                 = baseUrl + "doctors/login";
final doctorLogout                = baseUrl + "doctors/logout";
final doctorUpdate                = baseUrl + "doctors/update";
final doctorMe                    = baseUrl + "doctors/me";
final doctorCV                    = baseUrl + "uploads/cv_files/";


final String getAllDoctorsUrl =  baseUrl + "doctors/all";
final String getDoctorByIdUrl =  baseUrl +"doctors/";

//  (User)
final patientRegister             = baseUrl + "patients/register";
final patientLogin                = baseUrl + "patients/login";
final patientLoginLogout          = baseUrl + "patients/logout";
final patientMe                   = baseUrl + "patients/me";
final patientMeUpdate             = baseUrl + "patients/me_update";

////////
///////
//////
/////
////
///
// ==================== Appointments API ====================
final String doctorsListUrl = baseUrl + "appointments/doctors";
final String bookAppointmentUrl = baseUrl + "appointments/book";
final String cancelAppointmentUrl =baseUrl+ "appointments/cancel";
final String myAppointmentsUrl = baseUrl + "appointments/my-appointments";
final String availableSlotsUrl = baseUrl + "appointments/available-slots"; // لاحقًا /{doctor_id}?date=yyyy-mm-dd
final String approveAppointmentUrl = baseUrl+ "appointments/approve";
// لاحقًا /{appointment_id}?approve=true
final String doctorAppointmentsUrl = baseUrl + "appointments/doctor-appointments";
final String completeAppointmentUrl =      baseUrl + "appointments/complete"; // لاحظ نفس اسم endpoint

