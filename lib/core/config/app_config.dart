//  localhost
const baseUrl                     = "http://10.0.2.2:8000/";



// ---------- Admin ----------
const adminCreate = baseUrl + "admin/create";
const adminLogin  = baseUrl + "admin/login";
const adminCheck  = baseUrl + "admin/check";

// ---------- Doctors Management ----------
const pendingDoctors   = baseUrl + "admin/pending-doctors";
const approveDoctor    = baseUrl + "admin/approve-doctor/"; // لاحظ: لازم تضيف ID بعد الرابط
const rejectDoctor     = baseUrl + "admin/reject-doctor/";  // لاحظ: لازم تضيف ID بعد الرابط

//  (Doctor)
const doctorRegister              = baseUrl + "doctors/register";
const doctorLogin                 = baseUrl + "doctors/login";
const doctorLogout                = baseUrl + "doctors/logout";
const doctorUpdate                = baseUrl + "doctors/update";
const doctorMe                    = baseUrl + "doctors/me";
const doctorCV                    = baseUrl + "uploads/cv_files/";

//  (User)
const patientRegister             = baseUrl + "patients/register";
const patientLogin                = baseUrl + "patients/login";
const patientLoginLogout          = baseUrl + "patients/logout";
const patientMe                   = baseUrl + "patients/me";
const patientMeUpdate             = baseUrl + "patients/me_update";

////////
///////
//////
/////
////
///
// ==================== Appointments API ====================

// 🧑‍⚕ قائمة الأطباء
const AppointmentsListDoctors = baseUrl + "appointments/doctors";

// 📅 حجز موعد جديد
const AppointmentsBook = baseUrl + "appointments/book";

// ❌ إلغاء الموعد
const AppointmentsCancel = baseUrl + "appointments/cancel"; // لاحقًا ستضيف /{appointment_id} عند الاستدعاء

// 🧍‍♂ مواعيد المريض
const AppointmentsMy = baseUrl + "appointments/my-appointments";

// 🧑‍⚕ مواعيد الطبيب
const AppointmentsDoctor = baseUrl + "appointments/doctor-appointments";

// 🩺 موافقة أو رفض الموعد (Doctor)
const AppointmentsApprove = baseUrl + "appointments/approve"; // لاحقًا ستضيف /{appointment_id} عند الاستدعاء

// 🕓 عرض الأوقات المتاحة للطبيب
const AppointmentsDoctorAvailable = baseUrl + "appointments/available-slots"; // لاحقًا ستضيف /{doctor_id}?date=yyyy-mm-dd



//
//const String AppointmentsDoctors  = baseUrl + "appointments/doctors";                // جلب قائمة الدكاترة
// const String AppointmentsBook     = baseUrl + "appointments/book";                   // حجز موعد
// const String AppointmentsDoctor   = baseUrl + "appointments/doctor-appointments";
// const String AppointmentsMy       = baseUrl + "appointments/my-appointments";        // جلب مواعيد المريض
// const String AppointmentsCancelRequest = baseUrl + "appointments/request-cancel/";
// const String AppointmentsApproveCancel = baseUrl + "appointments/approve-cancel/";