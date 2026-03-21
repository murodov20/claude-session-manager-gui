import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case en = "en"
    case ru = "ru"
    case ar = "ar"
    case uz = "uz"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .en: return "English"
        case .ru: return "Русский"
        case .ar: return "العربية"
        case .uz: return "O'zbekcha"
        }
    }
}

enum L10nKey: String {
    // Main view
    case appTitle
    case searchPlaceholder
    case noSessionsFound
    case noMatchingFound
    case sessionsCount
    case openInTerminal
    case refreshSessions
    case msgs
    case empty
    case copied

    // Settings
    case settings
    case language
    case globalHotkey
    case copyHotkey
    case refreshHotkey
    case sessionsFolder
    case terminalCommand
    case terminalCommandHint
    case save
    case cancel
    case pressHotkey
    case resetDefault
    case browseFolder
}

class L10n: ObservableObject {
    static let shared = L10n()

    @Published var current: AppLanguage {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: "appLanguage")
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        self.current = AppLanguage(rawValue: saved) ?? .en
    }

    func t(_ key: L10nKey) -> String {
        return Self.strings[current]?[key] ?? Self.strings[.en]![key]!
    }

    func t(_ key: L10nKey, _ args: CVarArg...) -> String {
        let format = Self.strings[current]?[key] ?? Self.strings[.en]![key]!
        return String(format: format, arguments: args)
    }

    // MARK: - All translations

    static let strings: [AppLanguage: [L10nKey: String]] = [
        .en: [
            .appTitle: "Claude Code Sessions",
            .searchPlaceholder: "Search sessions...",
            .noSessionsFound: "No sessions found",
            .noMatchingFound: "No matching sessions",
            .sessionsCount: "%d sessions",
            .openInTerminal: "Open in Terminal",
            .refreshSessions: "Refresh sessions",
            .msgs: "%d msgs",
            .empty: "(empty)",
            .copied: "Copied!",
            .settings: "Settings",
            .language: "Language",
            .globalHotkey: "Toggle popover",
            .copyHotkey: "Copy command",
            .refreshHotkey: "Refresh",
            .sessionsFolder: "Sessions folder",
            .terminalCommand: "Terminal command",
            .terminalCommandHint: "Use {cmd} as placeholder for the session command",
            .save: "Save",
            .cancel: "Cancel",
            .pressHotkey: "Press a key combination...",
            .resetDefault: "Reset to default",
            .browseFolder: "Browse...",
        ],
        .ru: [
            .appTitle: "Сессии Claude Code",
            .searchPlaceholder: "Поиск сессий...",
            .noSessionsFound: "Сессии не найдены",
            .noMatchingFound: "Ничего не найдено",
            .sessionsCount: "%d сессий",
            .openInTerminal: "Открыть в терминале",
            .refreshSessions: "Обновить сессии",
            .msgs: "%d сообщ.",
            .empty: "(пусто)",
            .copied: "Скопировано!",
            .settings: "Настройки",
            .language: "Язык",
            .globalHotkey: "Открыть/закрыть",
            .copyHotkey: "Копировать команду",
            .refreshHotkey: "Обновить",
            .sessionsFolder: "Папка сессий",
            .terminalCommand: "Команда терминала",
            .terminalCommandHint: "Используйте {cmd} как плейсхолдер для команды сессии",
            .save: "Сохранить",
            .cancel: "Отмена",
            .pressHotkey: "Нажмите комбинацию клавиш...",
            .resetDefault: "По умолчанию",
            .browseFolder: "Обзор...",
        ],
        .ar: [
            .appTitle: "جلسات Claude Code",
            .searchPlaceholder: "بحث في الجلسات...",
            .noSessionsFound: "لم يتم العثور على جلسات",
            .noMatchingFound: "لا توجد نتائج مطابقة",
            .sessionsCount: "%d جلسات",
            .openInTerminal: "فتح في الطرفية",
            .refreshSessions: "تحديث الجلسات",
            .msgs: "%d رسائل",
            .empty: "(فارغ)",
            .copied: "تم النسخ!",
            .settings: "الإعدادات",
            .language: "اللغة",
            .globalHotkey: "فتح/إغلاق",
            .copyHotkey: "نسخ الأمر",
            .refreshHotkey: "تحديث",
            .sessionsFolder: "مجلد الجلسات",
            .terminalCommand: "أمر الطرفية",
            .terminalCommandHint: "استخدم {cmd} كعنصر نائب لأمر الجلسة",
            .save: "حفظ",
            .cancel: "إلغاء",
            .pressHotkey: "اضغط مجموعة مفاتيح...",
            .resetDefault: "إعادة تعيين",
            .browseFolder: "تصفح...",
        ],
        .uz: [
            .appTitle: "Claude Code Sessiyalari",
            .searchPlaceholder: "Sessiyalarni qidirish...",
            .noSessionsFound: "Sessiyalar topilmadi",
            .noMatchingFound: "Mos sessiyalar topilmadi",
            .sessionsCount: "%d ta sessiya",
            .openInTerminal: "Terminalda ochish",
            .refreshSessions: "Sessiyalarni yangilash",
            .msgs: "%d xabar",
            .empty: "(bo'sh)",
            .copied: "Nusxalandi!",
            .settings: "Sozlamalar",
            .language: "Til",
            .globalHotkey: "Ochish/Yopish",
            .copyHotkey: "Buyruqni nusxalash",
            .refreshHotkey: "Yangilash",
            .sessionsFolder: "Sessiyalar papkasi",
            .terminalCommand: "Terminal buyrug'i",
            .terminalCommandHint: "Sessiya buyrug'i uchun {cmd} ishlatiladi",
            .save: "Saqlash",
            .cancel: "Bekor qilish",
            .pressHotkey: "Tugmalar kombinatsiyasini bosing...",
            .resetDefault: "Standart holatga",
            .browseFolder: "Tanlash...",
        ],
    ]
}
