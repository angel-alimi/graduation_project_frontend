import '../models/models.dart';

/// The main city of each of the 16 Palestinian governorates (West Bank, Jerusalem
/// and the Gaza Strip). Towns and villages count as their main city, e.g. Birzeit
/// is Ramallah. The backend must seed the same ids.
const List<City> kCities = [
  City(id: 1, nameAr: 'رام الله', nameEn: 'Ramallah'),
  City(id: 2, nameAr: 'نابلس', nameEn: 'Nablus'),
  City(id: 3, nameAr: 'الخليل', nameEn: 'Hebron'),
  City(id: 4, nameAr: 'بيت لحم', nameEn: 'Bethlehem'),
  City(id: 5, nameAr: 'جنين', nameEn: 'Jenin'),
  City(id: 6, nameAr: 'طولكرم', nameEn: 'Tulkarm'),
  City(id: 7, nameAr: 'قلقيلية', nameEn: 'Qalqilya'),
  City(id: 8, nameAr: 'أريحا', nameEn: 'Jericho'),
  City(id: 9, nameAr: 'القدس', nameEn: 'Jerusalem'),
  City(id: 10, nameAr: 'غزة', nameEn: 'Gaza City'),
  City(id: 11, nameAr: 'خان يونس', nameEn: 'Khan Yunis'),
  City(id: 12, nameAr: 'رفح', nameEn: 'Rafah'),
  City(id: 13, nameAr: 'دير البلح', nameEn: 'Deir al-Balah'),
  City(id: 14, nameAr: 'جباليا', nameEn: 'Jabalia'),
  City(id: 17, nameAr: 'طوباس', nameEn: 'Tubas'),
  City(id: 18, nameAr: 'سلفيت', nameEn: 'Salfit'),
];

/// The predefined list of hospitals. Each belongs to the main city of its governorate.
const List<Hospital> kHospitals = [
  // Ramallah & Al-Bireh
  Hospital(id: 1, nameAr: 'مجمع فلسطين الطبي', nameEn: 'Palestine Medical Complex', cityId: 1),
  Hospital(id: 2, nameAr: 'المستشفى الاستشاري العربي', nameEn: 'Istishari Arab Hospital', cityId: 1),
  Hospital(id: 6, nameAr: 'مستشفى الشيخ زايد بن سلطان', nameEn: 'Sheikh Zayed bin Sultan Hospital', cityId: 1),
  Hospital(id: 7, nameAr: 'مستشفى جمعية الهلال الأحمر الفلسطيني (رام الله)', nameEn: 'Palestine Red Crescent Society Hospital (Ramallah)', cityId: 1),
  Hospital(id: 8, nameAr: 'مستشفى خالد الجراحي', nameEn: 'Khalid Surgical Hospital', cityId: 1),
  Hospital(id: 9, nameAr: 'مستشفى وليد الناظر للولادة', nameEn: 'Walid Al-Nather Maternity Hospital', cityId: 1),
  Hospital(id: 10, nameAr: 'مستشفى الرحمة للولادة', nameEn: 'Al-Rahma Maternity Hospital', cityId: 1),
  Hospital(id: 11, nameAr: 'مستشفى الرازي لطب وجراحة العيون', nameEn: 'Al-Razi Eye Hospital', cityId: 1),
  Hospital(id: 12, nameAr: 'مستشفى المستقبل', nameEn: 'Al-Mustaqbal Hospital', cityId: 1),
  Hospital(id: 13, nameAr: 'مستشفى الرعاية العربية التخصصي', nameEn: 'Arab Care Specialized Hospital', cityId: 1),
  Hospital(id: 14, nameAr: 'مستشفى مسلم التخصصي (رام الله)', nameEn: 'Muslim Specialized Hospital (Ramallah)', cityId: 1),
  Hospital(id: 15, nameAr: 'مستشفى الشيخة فاطمة بنت مبارك العسكري', nameEn: 'Sheikha Fatima bint Mubarak Military Hospital', cityId: 1),
  Hospital(id: 16, nameAr: 'مركز خليل أبو ريا للتأهيل', nameEn: 'Khalil Abu Raya Rehabilitation Center', cityId: 1),
  Hospital(id: 17, nameAr: 'المستشفى الفلسطيني الفنزويلي للعيون', nameEn: 'Palestinian-Venezuelan Eye Hospital', cityId: 1),
  Hospital(id: 18, nameAr: 'مستشفى إتش كلينك التخصصي', nameEn: 'H Clinic Specialized Hospital', cityId: 1),
  Hospital(id: 19, nameAr: 'مستشفى يافا الجراحي التخصصي', nameEn: 'Jaffa Specialized Surgical Hospital', cityId: 1),

  // Nablus
  Hospital(id: 3, nameAr: 'مستشفى رفيديا الجراحي الحكومي', nameEn: 'Rafidia Surgical Governmental Hospital', cityId: 2),
  Hospital(id: 21, nameAr: 'المستشفى الوطني الحكومي', nameEn: 'Al-Watani Governmental Hospital', cityId: 2),
  Hospital(id: 22, nameAr: 'مستشفى جمعية الاتحاد النسائي العربي', nameEn: 'Al-Ittihad Hospital (Arab Women’s Union)', cityId: 2),
  Hospital(id: 23, nameAr: 'المستشفى الإنجيلي العربي', nameEn: 'Arab Evangelical Hospital (St. Luke’s)', cityId: 2),
  Hospital(id: 24, nameAr: 'مستشفى نابلس التخصصي', nameEn: 'Nablus Specialized Hospital', cityId: 2),
  Hospital(id: 25, nameAr: 'المستشفى العربي التخصصي', nameEn: 'Arab Specialized Hospital', cityId: 2),
  Hospital(id: 26, nameAr: 'مستشفى النجاح الوطني الجامعي', nameEn: 'An-Najah National University Hospital', cityId: 2),
  Hospital(id: 27, nameAr: 'مستشفى الأمل للتأهيل', nameEn: 'Al-Amal Rehabilitation Hospital', cityId: 2),
  Hospital(id: 28, nameAr: 'مجمع الشهداء الطبي العسكري', nameEn: 'Al-Shuhada Military Medical Complex', cityId: 2),
  Hospital(id: 29, nameAr: 'مستشفى الهلال الأحمر الفلسطيني (نابلس)', nameEn: 'Palestine Red Crescent Hospital (Nablus)', cityId: 2),

  // Hebron governorate
  Hospital(id: 4, nameAr: 'مستشفى الأميرة عالية الحكومي', nameEn: 'Princess Alia Governmental Hospital', cityId: 3),
  Hospital(id: 31, nameAr: 'المستشفى الأهلي', nameEn: 'Al-Ahli Hospital', cityId: 3),
  Hospital(id: 32, nameAr: 'مستشفى الزعتري للولادة', nameEn: 'Al-Zaatari Maternity Hospital', cityId: 3),
  Hospital(id: 33, nameAr: 'مستشفى الميزان التخصصي', nameEn: 'Al-Meezan Specialized Hospital', cityId: 3),
  Hospital(id: 34, nameAr: 'مستشفى العروب', nameEn: 'Al-Arroub Hospital', cityId: 3),
  Hospital(id: 35, nameAr: 'مستشفى حمدان', nameEn: 'Hamdan Hospital', cityId: 3),
  Hospital(id: 36, nameAr: 'مستشفى محمد علي المحتسب الحكومي', nameEn: 'Mohammad Ali Al-Muhtaseb Governmental Hospital', cityId: 3),
  Hospital(id: 37, nameAr: 'مستشفى شهيرة للنساء', nameEn: 'Shahira Women’s Hospital', cityId: 3),
  Hospital(id: 38, nameAr: 'مستشفى ناصر للولادة', nameEn: 'Nasser Maternity Hospital', cityId: 3),
  Hospital(id: 39, nameAr: 'مستشفى الاعتماد التخصصي', nameEn: 'Al-Etimad Specialized Hospital', cityId: 3),
  Hospital(id: 40, nameAr: 'مستشفى الشهيد أبو الحسن القاسم الحكومي', nameEn: 'Martyr Abu Al-Hasan Al-Qasim Governmental Hospital', cityId: 3),
  Hospital(id: 41, nameAr: 'مستشفى جمعية الهلال الأحمر الفلسطيني (الخليل)', nameEn: 'Palestine Red Crescent Society Hospital (Hebron)', cityId: 3),
  Hospital(id: 42, nameAr: 'مستشفى بني نعيم للولادة', nameEn: "Bani Na'im Maternity Hospital", cityId: 3),
  Hospital(id: 43, nameAr: 'مستشفى دورا الحكومي', nameEn: 'Dura Governmental Hospital', cityId: 3),
  Hospital(id: 44, nameAr: 'مستشفى الرئيس محمود عباس الحكومي', nameEn: 'President Mahmoud Abbas Governmental Hospital', cityId: 3),
  Hospital(id: 45, nameAr: 'مستشفى الملكي التخصصي', nameEn: 'Al-Malaki Specialized Hospital', cityId: 3),
  Hospital(id: 46, nameAr: 'مستشفى جمعية الهلال الأحمر الفلسطيني (حلحول)', nameEn: 'Palestine Red Crescent Society Hospital (Halhul)', cityId: 3),
  Hospital(id: 47, nameAr: 'مستشفى سان جون للعيون (الخليل)', nameEn: 'St John Eye Hospital (Hebron)', cityId: 3),

  // Bethlehem governorate
  Hospital(id: 5, nameAr: 'مستشفى الحسين الحكومي', nameEn: 'Al-Hussein Governmental Hospital', cityId: 4),
  Hospital(id: 48, nameAr: 'مستشفى كاريتاس للأطفال', nameEn: 'Caritas Baby Hospital', cityId: 4),
  Hospital(id: 49, nameAr: 'مستشفى الدبس للولادة', nameEn: 'Al-Dibs Maternity Hospital', cityId: 4),
  Hospital(id: 50, nameAr: 'مستشفى العائلة المقدسة', nameEn: 'Holy Family Hospital', cityId: 4),
  Hospital(id: 51, nameAr: 'مستشفى د. محمد كمال للطب النفسي', nameEn: 'Dr. Mohammad Kamal Psychiatric Hospital', cityId: 4),
  Hospital(id: 52, nameAr: 'مستشفى الجمعية العربية', nameEn: 'Arab Society Hospital', cityId: 4),
  Hospital(id: 53, nameAr: 'مستشفى اليمامة التخصصي', nameEn: 'Al-Yamama Specialized Hospital', cityId: 4),
  Hospital(id: 54, nameAr: 'مستشفى حقل الرعاية', nameEn: 'Shepherds’ Field Hospital', cityId: 4),
  Hospital(id: 55, nameAr: 'مستشفى د. أحمد المسلماني', nameEn: 'Dr. Ahmad Al-Muslimani Hospital', cityId: 4),

  // Jenin governorate
  Hospital(id: 56, nameAr: 'مستشفى الشهيد د. خليل سليمان الحكومي', nameEn: 'Martyr Dr. Khalil Suleiman Governmental Hospital', cityId: 5),
  Hospital(id: 57, nameAr: 'مستشفى الرازي', nameEn: 'Al-Razi Hospital', cityId: 5),
  Hospital(id: 58, nameAr: 'مستشفى الشفاء للعيون', nameEn: 'Al-Shifa Eye Hospital', cityId: 5),
  Hospital(id: 59, nameAr: 'المستشفى الإنجيلي (الزبابدة)', nameEn: 'Evangelical Hospital (Zababdeh)', cityId: 5),
  Hospital(id: 60, nameAr: 'مستشفى الأمل للتوليد', nameEn: 'Al-Amal Maternity Hospital', cityId: 5),
  Hospital(id: 62, nameAr: 'مستشفى ابن سينا التخصصي', nameEn: 'Ibn Sina Specialized Hospital', cityId: 5),

  // Tulkarm governorate
  Hospital(id: 63, nameAr: 'مستشفى الشهيد د. ثابت ثابت الحكومي', nameEn: 'Martyr Dr. Thabet Thabet Governmental Hospital', cityId: 6),
  Hospital(id: 64, nameAr: 'مستشفى جمعية الهلال الأحمر الفلسطيني (طولكرم)', nameEn: 'Palestine Red Crescent Society Hospital (Tulkarm)', cityId: 6),
  Hospital(id: 65, nameAr: 'مستشفى الإسراء التخصصي', nameEn: 'Al-Israa Specialized Hospital', cityId: 6),
  Hospital(id: 66, nameAr: 'مستشفى سان جون للعيون (طولكرم)', nameEn: 'St John Eye Hospital (Tulkarm)', cityId: 6),
  Hospital(id: 67, nameAr: 'مستشفى لجنة زكاة طولكرم', nameEn: 'Tulkarm Zakat Committee Hospital', cityId: 6),
  Hospital(id: 68, nameAr: 'مستشفى عتيل الحكومي', nameEn: 'Attil Governmental Hospital', cityId: 6),

  // Qalqilya, Jericho, Tubas, Salfit
  Hospital(id: 69, nameAr: 'مستشفى د. درويش نزال الحكومي', nameEn: 'Dr. Darwish Nazzal Governmental Hospital', cityId: 7),
  Hospital(id: 70, nameAr: 'مستشفى الأونروا (قلقيلية)', nameEn: 'UNRWA Hospital (Qalqilya)', cityId: 7),
  Hospital(id: 71, nameAr: 'مستشفى أريحا الحكومي', nameEn: 'Jericho Governmental Hospital', cityId: 8),
  Hospital(id: 72, nameAr: 'مستشفى طوباس التركي الحكومي', nameEn: 'Tubas Turkish Governmental Hospital', cityId: 17),
  Hospital(id: 73, nameAr: 'مستشفى كشدة', nameEn: 'Kashda Hospital', cityId: 17),
  Hospital(id: 74, nameAr: 'مستشفى الشهيد ياسر عرفات الحكومي', nameEn: 'Martyr Yasser Arafat Governmental Hospital', cityId: 18),

  // Jerusalem
  Hospital(id: 75, nameAr: 'مستشفى جمعية المقاصد الخيرية الإسلامية', nameEn: 'Makassed Hospital', cityId: 9),
  Hospital(id: 76, nameAr: 'مستشفى المطلع (أوغستا فكتوريا)', nameEn: 'Augusta Victoria Hospital', cityId: 9),
  Hospital(id: 77, nameAr: 'مستشفى مار يوسف (الفرنساوي)', nameEn: 'St. Joseph’s Hospital', cityId: 9),
  Hospital(id: 78, nameAr: 'مستشفى سان جون للعيون (القدس)', nameEn: 'St John Eye Hospital (Jerusalem)', cityId: 9),
  Hospital(id: 79, nameAr: 'مستشفى الدجاني للولادة', nameEn: 'Al-Dajani Maternity Hospital', cityId: 9),
  Hospital(id: 80, nameAr: 'مستشفى القدس للولادة', nameEn: 'Al-Quds Maternity Hospital', cityId: 9),
  Hospital(id: 81, nameAr: 'مستشفى جمعية الهلال الأحمر الفلسطيني (القدس)', nameEn: 'Palestine Red Crescent Society Hospital (Jerusalem)', cityId: 9),
  Hospital(id: 82, nameAr: 'مستشفى الأميرة بسمة للتأهيل', nameEn: 'Princess Basma Rehabilitation Hospital', cityId: 9),
  Hospital(id: 83, nameAr: 'مستشفى الجعبة', nameEn: "Al-Ja'bah Hospital", cityId: 9),

  // North Gaza
  Hospital(id: 84, nameAr: 'المستشفى الإندونيسي', nameEn: 'Indonesian Hospital', cityId: 14),
  Hospital(id: 85, nameAr: 'مستشفى كمال عدوان', nameEn: 'Kamal Adwan Hospital', cityId: 14),
  Hospital(id: 86, nameAr: 'مستشفى بلسم العسكري', nameEn: 'Balsam Military Hospital', cityId: 14),
  Hospital(id: 87, nameAr: 'مستشفى العودة', nameEn: 'Al-Awda Hospital', cityId: 14),
  Hospital(id: 88, nameAr: 'مستشفى الكرامة', nameEn: 'Al-Karama Hospital', cityId: 14),
  Hospital(id: 89, nameAr: 'مستشفى بيت حانون الحكومي', nameEn: 'Beit Hanoun Governmental Hospital', cityId: 14),
  Hospital(id: 90, nameAr: 'مستشفى اليمن السعيد', nameEn: 'Al-Yemen Al-Saeed Hospital', cityId: 14),

  // Gaza City
  Hospital(id: 91, nameAr: 'مجمع الشفاء الطبي', nameEn: 'Al-Shifa Medical Complex', cityId: 10),
  Hospital(id: 92, nameAr: 'مستشفى غزة للعيون', nameEn: 'Gaza Eye Hospital', cityId: 10),
  Hospital(id: 93, nameAr: 'مستشفى النصر الحكومي للأطفال', nameEn: 'Al-Nasr Governmental Children’s Hospital', cityId: 10),
  Hospital(id: 94, nameAr: 'مستشفى د. عبد العزيز الرنتيسي التخصصي للأطفال', nameEn: 'Dr. Abdel Aziz Al-Rantisi Children’s Hospital', cityId: 10),
  Hospital(id: 95, nameAr: 'مستشفى القدس (غزة)', nameEn: 'Al-Quds Hospital (Gaza)', cityId: 10),
  Hospital(id: 97, nameAr: 'المستشفى الأهلي العربي', nameEn: 'Al-Ahli Arab Hospital', cityId: 10),
  Hospital(id: 98, nameAr: 'مستشفى سان جون (غزة)', nameEn: 'St John Hospital (Gaza)', cityId: 10),
  Hospital(id: 99, nameAr: 'مستشفى أصدقاء المريض الخيري', nameEn: 'Patient’s Friends Charity Hospital', cityId: 10),
  Hospital(id: 100, nameAr: 'مستشفى الصحابة التخصصي', nameEn: 'Al-Sahaba Specialized Hospital', cityId: 10),
  Hospital(id: 101, nameAr: 'مستشفى جنين (غزة)', nameEn: 'Jenin Hospital (Gaza)', cityId: 10),
  Hospital(id: 102, nameAr: 'مستشفى غزة للطب النفسي', nameEn: 'Gaza Psychiatric Hospital', cityId: 10),
  Hospital(id: 103, nameAr: 'مستشفى الشهيد محمد الدرة للأطفال', nameEn: 'Martyr Mohammad Al-Durra Children’s Hospital', cityId: 10),
  Hospital(id: 104, nameAr: 'مستشفى الوفاء للتأهيل الطبي والجراحة التخصصية', nameEn: 'Al-Wafa Rehabilitation & Specialized Surgery Hospital', cityId: 10),
  Hospital(id: 105, nameAr: 'مستشفى حمد للتأهيل والأطراف الصناعية', nameEn: 'Hamad Rehabilitation & Prosthetics Hospital', cityId: 10),
  Hospital(id: 106, nameAr: 'مستشفى الحلو', nameEn: 'Al-Helou Hospital', cityId: 10),
  Hospital(id: 107, nameAr: 'مستشفى الحياة', nameEn: 'Al-Hayat Hospital', cityId: 10),
  Hospital(id: 108, nameAr: 'مستشفى الصداقة التركي الفلسطيني', nameEn: 'Turkish-Palestinian Friendship Hospital', cityId: 10),
  Hospital(id: 109, nameAr: 'مستشفى الخدمة العامة', nameEn: 'Public Service Hospital', cityId: 10),
  Hospital(id: 110, nameAr: 'مستشفى العيون التخصصي', nameEn: 'Specialized Eye Hospital', cityId: 10),
  Hospital(id: 111, nameAr: 'مستشفى حيفا', nameEn: 'Haifa Hospital', cityId: 10),
  Hospital(id: 112, nameAr: 'مستشفى مهدي للولادة', nameEn: 'Al-Mahdi Maternity Hospital', cityId: 10),
  Hospital(id: 113, nameAr: 'مستشفى مسلم التخصصي (غزة)', nameEn: 'Muslim Specialized Hospital (Gaza)', cityId: 10),

  // Deir al-Balah governorate
  Hospital(id: 114, nameAr: 'مستشفى شهداء الأقصى الحكومي', nameEn: 'Shuhada Al-Aqsa Governmental Hospital', cityId: 13),
  Hospital(id: 115, nameAr: 'مستشفى يافا (دير البلح)', nameEn: 'Jaffa Hospital (Deir al-Balah)', cityId: 13),

  // Khan Yunis governorate
  Hospital(id: 116, nameAr: 'المستشفى الجزائري العسكري', nameEn: 'Algerian Military Hospital', cityId: 11),
  Hospital(id: 117, nameAr: 'مجمع ناصر الطبي', nameEn: 'Nasser Medical Complex', cityId: 11),
  Hospital(id: 118, nameAr: 'مستشفى غزة الأوروبي', nameEn: 'Gaza European Hospital', cityId: 11),
  Hospital(id: 119, nameAr: 'مستشفى الأمل (خان يونس)', nameEn: 'Al-Amal Hospital (Khan Yunis)', cityId: 11),
  Hospital(id: 120, nameAr: 'مستشفى دار السلام', nameEn: 'Dar Al-Salam Hospital', cityId: 11),
  Hospital(id: 122, nameAr: 'مستشفى الخير', nameEn: 'Al-Khair Hospital', cityId: 11),

  // Rafah governorate
  Hospital(id: 123, nameAr: 'مستشفى الشهيد أبو يوسف النجار الحكومي', nameEn: 'Martyr Abu Yousef Al-Najjar Governmental Hospital', cityId: 12),
  Hospital(id: 124, nameAr: 'مستشفى الهلال الإماراتي للولادة', nameEn: 'Emirati Crescent Maternity Hospital', cityId: 12),
  Hospital(id: 125, nameAr: 'مستشفى الكويت التخصصي', nameEn: 'Kuwait Specialized Hospital', cityId: 12),
];
