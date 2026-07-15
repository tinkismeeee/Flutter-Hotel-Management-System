import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppText {
  home,
  myBooking,
  profile,
  openProfile,
  welcomeBack,
  findPerfectRoom,
  searchRooms,
  noRoomsFound,
  showing,
  available,
  total,
  filterBy,
  reset,
  roomType,
  allRoomCategories,
  price,
  noPriceRange,
  roomStatus,
  anyAvailability,
  applyFilter,
  retry,
  setting,
  email,
  phone,
  address,
  dateOfBirth,
  customerId,
  notProvided,
  editProfile,
  profileUpdated,
  logout,
  signOutDescription,
  signingOut,
  language,
  english,
  vietnamese,
  selectLanguage,
  firstName,
  lastName,
  saveChanges,
  enterEmail,
  invalidEmail,
  invalidDate,
  loginTitle,
  loginSubtitle,
  emailAddress,
  enterEmailAddress,
  password,
  enterPassword,
  rememberMe,
  forgotPassword,
  login,
  noAccount,
  signUp,
  signInWith,
  signInWithGoogle,
  identityCard,
  identityCardDescription,
  identityCardFront,
  identityCardBack,
  complete,
  missing,
  uploaded,
  addImage,
  replaceImage,
  viewImage,
  delete,
  cancel,
  deleteIdentityImage,
  deleteIdentityImageConfirm,
  identityCardRequired,
  identityCardRequiredDescription,
  manageIdentityCard,
}

class AppLocalizations {
  static const supportedLocales = [Locale('en'), Locale('vi')];
  static const delegate = _AppLocalizationsDelegate();

  final Locale locale;

  const AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(Locale('en'));
  }

  bool get isVietnamese => locale.languageCode == 'vi';

  String text(AppText key) {
    return (_translations[locale.languageCode] ?? _translations['en']!)[key] ??
        _translations['en']![key] ??
        key.name;
  }

  String roomNumber(String number) =>
      isVietnamese ? 'Phòng $number' : 'Room $number';

  String floor(Object floor) => isVietnamese ? 'Tầng $floor' : 'Floor $floor';

  String guests(Object count) =>
      isVietnamese ? '$count khách' : '$count guests';

  String beds(Object count) => isVietnamese ? '$count giường' : '$count beds';

  String pricePerNight(String price) =>
      isVietnamese ? '$price VND/đêm' : '$price VND/night';
}

extension AppLocalizationsContext on BuildContext {
  String tr(AppText key) => AppLocalizations.of(this).text(key);
}

class AppLocaleStore {
  static const _localeKey = 'app_locale';

  static Future<Locale> load() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_localeKey);
    return languageCode == 'vi' ? const Locale('vi') : const Locale('en');
  }

  static Future<void> save(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

const _translations = <String, Map<AppText, String>>{
  'en': {
    AppText.home: 'Home',
    AppText.myBooking: 'My Booking',
    AppText.profile: 'Profile',
    AppText.openProfile: 'Open profile',
    AppText.welcomeBack: 'Welcome back',
    AppText.findPerfectRoom: 'Find your perfect room',
    AppText.searchRooms: 'Search room number, type, status',
    AppText.noRoomsFound: 'No rooms found',
    AppText.showing: 'Showing',
    AppText.available: 'Available',
    AppText.total: 'Total',
    AppText.filterBy: 'Filter By',
    AppText.reset: 'Reset',
    AppText.roomType: 'Room type',
    AppText.allRoomCategories: 'All room categories',
    AppText.price: 'Price',
    AppText.noPriceRange: 'No price range',
    AppText.roomStatus: 'Room status',
    AppText.anyAvailability: 'Any availability',
    AppText.applyFilter: 'Apply Filter',
    AppText.retry: 'Retry',
    AppText.setting: 'Setting',
    AppText.email: 'Email',
    AppText.phone: 'Phone',
    AppText.address: 'Address',
    AppText.dateOfBirth: 'Date of birth',
    AppText.customerId: 'Customer ID',
    AppText.notProvided: 'Not provided',
    AppText.editProfile: 'Edit Profile',
    AppText.profileUpdated: 'Profile updated.',
    AppText.logout: 'Logout',
    AppText.signOutDescription: 'Sign out of your account',
    AppText.signingOut: 'Signing out...',
    AppText.language: 'Language',
    AppText.english: 'English',
    AppText.vietnamese: 'Vietnamese',
    AppText.selectLanguage: 'Select language',
    AppText.firstName: 'First name',
    AppText.lastName: 'Last name',
    AppText.saveChanges: 'Save Changes',
    AppText.enterEmail: 'Please enter your email.',
    AppText.invalidEmail: 'Please enter a valid email.',
    AppText.invalidDate: 'Invalid date.',
    AppText.loginTitle: "Let's sign you in",
    AppText.loginSubtitle: 'Welcome back! Please login to continue.',
    AppText.emailAddress: 'Email address',
    AppText.enterEmailAddress: 'Enter your email address',
    AppText.password: 'Password',
    AppText.enterPassword: 'Enter your password',
    AppText.rememberMe: 'Remember me',
    AppText.forgotPassword: 'Forgot Password?',
    AppText.login: 'Login',
    AppText.noAccount: "Don't have an account?",
    AppText.signUp: 'Sign Up',
    AppText.signInWith: 'Or Sign In with',
    AppText.signInWithGoogle: 'Sign in with Google',
    AppText.identityCard: 'Identity card',
    AppText.identityCardDescription:
        'Add both sides of your identity card before creating a booking.',
    AppText.identityCardFront: 'Front side',
    AppText.identityCardBack: 'Back side',
    AppText.complete: 'Complete',
    AppText.missing: 'Missing',
    AppText.uploaded: 'Uploaded',
    AppText.addImage: 'Add image',
    AppText.replaceImage: 'Replace',
    AppText.viewImage: 'View image',
    AppText.delete: 'Delete',
    AppText.cancel: 'Cancel',
    AppText.deleteIdentityImage: 'Delete image?',
    AppText.deleteIdentityImageConfirm:
        'You must upload both sides again before booking.',
    AppText.identityCardRequired: 'Identity card required',
    AppText.identityCardRequiredDescription:
        'Upload both sides to continue with this booking.',
    AppText.manageIdentityCard: 'Upload identity card',
  },
  'vi': {
    AppText.home: 'Trang chủ',
    AppText.myBooking: 'Đặt phòng',
    AppText.profile: 'Hồ sơ',
    AppText.openProfile: 'Mở hồ sơ',
    AppText.welcomeBack: 'Chào mừng trở lại',
    AppText.findPerfectRoom: 'Tìm căn phòng phù hợp',
    AppText.searchRooms: 'Tìm số phòng, loại phòng, trạng thái',
    AppText.noRoomsFound: 'Không tìm thấy phòng',
    AppText.showing: 'Hiển thị',
    AppText.available: 'Còn trống',
    AppText.total: 'Tổng cộng',
    AppText.filterBy: 'Bộ lọc',
    AppText.reset: 'Đặt lại',
    AppText.roomType: 'Loại phòng',
    AppText.allRoomCategories: 'Tất cả loại phòng',
    AppText.price: 'Giá',
    AppText.noPriceRange: 'Không có khoảng giá',
    AppText.roomStatus: 'Trạng thái phòng',
    AppText.anyAvailability: 'Tất cả trạng thái',
    AppText.applyFilter: 'Áp dụng bộ lọc',
    AppText.retry: 'Thử lại',
    AppText.setting: 'Cài đặt',
    AppText.email: 'Email',
    AppText.phone: 'Số điện thoại',
    AppText.address: 'Địa chỉ',
    AppText.dateOfBirth: 'Ngày sinh',
    AppText.customerId: 'Mã khách hàng',
    AppText.notProvided: 'Chưa cung cấp',
    AppText.editProfile: 'Chỉnh sửa hồ sơ',
    AppText.profileUpdated: 'Đã cập nhật hồ sơ.',
    AppText.logout: 'Đăng xuất',
    AppText.signOutDescription: 'Đăng xuất khỏi tài khoản',
    AppText.signingOut: 'Đang đăng xuất...',
    AppText.language: 'Ngôn ngữ',
    AppText.english: 'Tiếng Anh',
    AppText.vietnamese: 'Tiếng Việt',
    AppText.selectLanguage: 'Chọn ngôn ngữ',
    AppText.firstName: 'Tên',
    AppText.lastName: 'Họ',
    AppText.saveChanges: 'Lưu thay đổi',
    AppText.enterEmail: 'Vui lòng nhập email.',
    AppText.invalidEmail: 'Vui lòng nhập email hợp lệ.',
    AppText.invalidDate: 'Ngày không hợp lệ.',
    AppText.loginTitle: 'Đăng nhập',
    AppText.loginSubtitle: 'Chào mừng trở lại! Vui lòng đăng nhập để tiếp tục.',
    AppText.emailAddress: 'Địa chỉ email',
    AppText.enterEmailAddress: 'Nhập địa chỉ email',
    AppText.password: 'Mật khẩu',
    AppText.enterPassword: 'Nhập mật khẩu',
    AppText.rememberMe: 'Ghi nhớ đăng nhập',
    AppText.forgotPassword: 'Quên mật khẩu?',
    AppText.login: 'Đăng nhập',
    AppText.noAccount: 'Chưa có tài khoản?',
    AppText.signUp: 'Đăng ký',
    AppText.signInWith: 'Hoặc đăng nhập bằng',
    AppText.signInWithGoogle: 'Đăng nhập bằng Google',
    AppText.identityCard: 'Căn cước công dân',
    AppText.identityCardDescription:
        'Thêm ảnh hai mặt căn cước trước khi tạo đơn đặt phòng.',
    AppText.identityCardFront: 'Mặt trước',
    AppText.identityCardBack: 'Mặt sau',
    AppText.complete: 'Đã đầy đủ',
    AppText.missing: 'Còn thiếu',
    AppText.uploaded: 'Đã tải lên',
    AppText.addImage: 'Thêm ảnh',
    AppText.replaceImage: 'Thay ảnh',
    AppText.viewImage: 'Xem ảnh',
    AppText.delete: 'Xóa',
    AppText.cancel: 'Hủy',
    AppText.deleteIdentityImage: 'Xóa ảnh?',
    AppText.deleteIdentityImageConfirm:
        'Bạn phải tải lại đủ hai mặt trước khi đặt phòng.',
    AppText.identityCardRequired: 'Yêu cầu căn cước công dân',
    AppText.identityCardRequiredDescription:
        'Tải lên đủ hai mặt để tiếp tục đặt phòng.',
    AppText.manageIdentityCard: 'Tải ảnh căn cước',
  },
};
