//  localhost
const baseUrl                     = "http://10.0.2.2:8000/";
const baseUrl1                     = "http://10.0.2.2:8000";




const String chatMessages = "$baseUrl1/chat/messages/";
const String chatSend = "$baseUrl1/chat/send";
const String chatUploadFile = "$baseUrl1/chat/upload_file/";
const String chatList = "$baseUrl1/chat/list";


// ---------- Admin ----------
const adminLogin  = baseUrl + "admin/login";
const adminCheck  = baseUrl + "admin/check";


//  (Doctor)
const doctorRegister              = baseUrl + "doctors/register-temp";
const doctorLogin                 = baseUrl + "doctors/login";
const doctorLogout                = baseUrl + "doctors/logout";
const doctorUpdate                = baseUrl + "doctors/update";
const doctorMe                    = baseUrl + "doctors/me";
const doctorCV                    = baseUrl + "uploads/cv_files/";


const String getAllDoctorsUrl =  baseUrl + "doctors/all";
const String getDoctorByIdUrl =  baseUrl +"doctors/";

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
const String doctorsListUrl = baseUrl + "appointments/doctors";
const String bookAppointmentUrl = baseUrl + "appointments/book";
const String cancelAppointmentUrl =baseUrl+ "appointments/cancel";
const String myAppointmentsUrl = baseUrl + "appointments/my-appointments";
const String availableSlotsUrl = baseUrl + "appointments/available-slots"; // لاحقًا /{doctor_id}?date=yyyy-mm-dd
const String approveAppointmentUrl = baseUrl+ "appointments/approve";
// لاحقًا /{appointment_id}?approve=true
const String doctorAppointmentsUrl = baseUrl + "appointments/doctor-appointments";
const String completeAppointmentUrl =      baseUrl + "appointments/complete"; // لاحظ نفس اسم endpoint

//
//const String AppointmentsDoctors  = baseUrl + "appointments/doctors";                // جلب قائمة الدكاترة
// const String AppointmentsBook     = baseUrl + "appointments/book";                   // حجز موعد
// const String AppointmentsDoctor   = baseUrl + "appointments/doctor-appointments";
// const String AppointmentsMy       = baseUrl + "appointments/my-appointments";        // جلب مواعيد المريض
// const String AppointmentsCancelRequest = baseUrl + "appointments/request-cancel/";
// const String AppointmentsApproveCancel = baseUrl + "appointments/approve-cancel/";