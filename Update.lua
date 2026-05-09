require "import"
import "android.speech.*"
import "android.speech.RecognizerIntent"
import "android.speech.SpeechRecognizer"
import "android.content.*"
import "android.widget.*"
import "android.view.*"
import "android.net.Uri"
import "android.graphics.Typeface" 
import "android.os.Vibrator"
import "android.os.Handler"
import "android.os.Looper"
import "android.media.AudioManager"
import "android.media.ToneGenerator"
import "java.io.*"
import "java.lang.Thread"
import "java.lang.Runnable"
import "java.net.URL"
import "java.util.*"
import "com.androlua.Http"
import "com.androlua.LuaDialog"
import "cjson"

local currentFilePath = debug.getinfo(1, "S").source:match("^@?(.*)$")
local mainHandler = Handler(Looper.getMainLooper())
local updateInProgress = false
local settingsDlg = nil
local moreOptionsDlg = nil

if activity then context = activity elseif service then context = service end

local currentAppVersion = "2.6"
local versionUrl = "https://raw.githubusercontent.com/AnuragAnant29/Kingrag/refs/heads/main/Version.txt"
local notesUrl = "https://raw.githubusercontent.com/AnuragAnant29/Kingrag/refs/heads/main/Notes.txt"
local updateScriptUrl = "https://raw.githubusercontent.com/AnuragAnant29/Kingrag/refs/heads/main/Update.lua"

local prefs = context.getSharedPreferences("ai_voice_typer_permanent_settings", Context.MODE_PRIVATE)
local editor = prefs.edit()

local orKey = prefs.getString("or_key", "")
local geminiKey = prefs.getString("gemini_key", "")
local groqKey = prefs.getString("groq_key", "")
local deepgramKey = prefs.getString("dg_key", "")
local selectedProvider = prefs.getString("provider", "OpenRouter")

local autoDetect = prefs.getBoolean("auto_detect", true)
local pureMode = prefs.getBoolean("pure_mode", false)
local selectedLanguage = prefs.getString("lang", "Hindi")
local emojiEnabled = prefs.getBoolean("emoji_enabled", true)
local emojiQty = prefs.getString("emoji_qty", "Low")
local endAction = prefs.getString("end_action", "Space")

local targetLanguage = prefs.getString("target_lang", "English")
local enableTranslation = prefs.getBoolean("enable_trans", false)
local offlineMode = prefs.getBoolean("offline_mode", false)

local vibrationEnabled = prefs.getBoolean("vibration_enabled", true)
local copyToClipboard = prefs.getBoolean("copy_clipboard", false)
local soundEnabled = prefs.getBoolean("sound_enabled", true)
local soundType = prefs.getString("sound_type", "Default Beep")

local typingMode = prefs.getString("typing_mode", "Auto Detect Script")

local uiLanguage = prefs.getString("ui_language", "English")

local uiTexts = {
  ["English"] = {
    select_typing_mode = "Select Typing Mode",
    ai_settings = "AI Settings",
    source_language = "Source Language (Click to Change)",
    target_language = "Target Language (Click to Change)",
    enable_translation = "Enable Translation",
    swap = "SWAP",
    emoji_settings = "Emoji Settings",
    more_options = "More Options",
    save_close = "Save & Close",
    
    ai_settings_title = "AI Settings",
    select_ai_provider = "Select AI Provider",
    manage_api_keys = "Manage API Keys",
    
    emoji_settings_title = "Emoji Settings",
    enable_smart_emojis = "Enable Smart Emojis",
    emoji_quantity = "Emoji Quantity",
    
    more_options_title = "More Options",
    other_settings = "Other Settings",
    sound_vibration_settings = "Sound & Vibration Settings",
    word_dictionary = "Word Dictionary",
    about = "About",
    contact_us = "Contact Us",
    close = "Close",
    
    other_settings_title = "Other Settings",
    select_ui_lang = "Select UI Language",
    offline_mode = "Offline Mode (No Internet)",
    copy_clipboard = "Copy Dictated Text To Clipboard",
    end_action = "End Action (Text End Behavior)",
    none = "None",
    new_line = "New Line",
    space = "Space",
    space_newline = "Space + New Line",
    
    sound_vibration_title = "Sound & Vibration Settings",
    enable_vibration = "Enable Vibration Feedback",
    enable_typing_sound = "Enable Typing Sound",
    typing_sound_type = "Typing Sound Type",
    default_beep = "Default Beep",
    soft_click = "Soft Click",
    sharp_pop = "Sharp Pop",
    
    word_dictionary_title = "Word Dictionary",
    add_new_words = "Add New Words To Dictionary",
    view_dictionary_words = "View Dictionary Words",
    clear_dictionary = "Clear Dictionary",
    
    add_word_title = "Add New Word to Dictionary",
    word_to_replace = "Word (to be replaced):",
    replacement_word = "Replacement Word:",
    save = "Save",
    cancel = "Cancel",
    
    delete_word = "Delete Word?",
    delete_confirmation = "Delete '{}' from dictionary?",
    delete = "Delete",
    
    clear_dict_title = "Clear Dictionary",
    clear_dict_message = "Are you sure you want to clear ALL words from the dictionary? This cannot be undone.",
    clear_all = "Clear All",
    
    manage_api_title = "Manage API Keys",
    openrouter_key = "OpenRouter Key",
    get_openrouter_key = "Get OpenRouter Key",
    gemini_key = "Gemini Key",
    get_gemini_key = "Get Gemini Key",
    groq_key = "Groq Key",
    get_groq_key = "Get Groq Key",
    deepgram_key = "Deepgram Key",
    get_deepgram_key = "Get Deepgram Key",
    save_keys = "Save Keys",
    
    about_title = "About Plugin",
    about_info = "How to use:\n1. Select AI Provider and add API Keys.\n2. Use Pure Language Mode for pure formal native typing.\n3. Long press on any language to add/remove from favorites.\n4. Emojis and auto-punctuation are added automatically.",
    
    contact_title = "Contact Us",
    join_telegram = "Join our Telegram Channel",
    give_feedback = "Give Feedback on Telegram",
    
    target_lang_title = "Target Language (Long Press to Add/Remove Fav)",
    typing_lang_title = "Typing Language (Long Press to Add/Remove Fav)",
    removed_from_fav = "removed from favorites",
    added_to_fav = "added to favorites",
    
    word_added = "Word added: {} → {}",
    dictionary_empty = "Dictionary is empty. Add some words first.",
    dictionary_words = "Dictionary Words ({} words)",
    deleted_word = "Deleted: {}",
    dictionary_cleared = "Dictionary cleared successfully",
    
    processing = "Processing...",
    key_missing = "Key Missing",
    connection_failed = "Connection Failed. Please check API Key or Internet.",
    please_enter_word = "Please enter a word",
    please_enter_replacement = "Please enter a replacement word",
  },
  
  ["Hindi"] = {
    select_typing_mode = "टाइपिंग मोड चुनें",
    ai_settings = "AI सेटिंग्स",
    source_language = "स्रोत भाषा (बदलने के लिए क्लिक करें)",
    target_language = "लक्ष्य भाषा (बदलने के लिए क्लिक करें)",
    enable_translation = "अनुवाद सक्षम करें",
    swap = "बदलें",
    emoji_settings = "इमोजी सेटिंग्स",
    more_options = "अधिक विकल्प",
    save_close = "सेव करें और बंद करें",
    
    ai_settings_title = "AI सेटिंग्स",
    select_ai_provider = "AI प्रदाता चुनें",
    manage_api_keys = "API कुंजियाँ प्रबंधित करें",
    
    emoji_settings_title = "इमोजी सेटिंग्स",
    enable_smart_emojis = "स्मार्ट इमोजी सक्षम करें",
    emoji_quantity = "इमोजी मात्रा",
    
    more_options_title = "अधिक विकल्प",
    other_settings = "अन्य सेटिंग्स",
    sound_vibration_settings = "ध्वनि और कंपन सेटिंग्स",
    word_dictionary = "शब्दकोश",
    about = "जानकारी",
    contact_us = "संपर्क करें",
    close = "बंद करें",
    
    other_settings_title = "अन्य सेटिंग्स",
    select_ui_lang = "UI भाषा चुनें",
    offline_mode = "ऑफलाइन मोड (इंटरनेट के बिना)",
    copy_clipboard = "टेक्स्ट को क्लिपबोर्ड पर कॉपी करें",
    end_action = "एंड एक्शन (टेक्स्ट एंड व्यवहार)",
    none = "कुछ नहीं",
    new_line = "नई लाइन",
    space = "स्पेस",
    space_newline = "स्पेस + नई लाइन",
    
    sound_vibration_title = "ध्वनि और कंपन सेटिंग्स",
    enable_vibration = "कंपन फीडबैक सक्षम करें",
    enable_typing_sound = "टाइपिंग ध्वनि सक्षम करें",
    typing_sound_type = "टाइपिंग ध्वनि प्रकार",
    default_beep = "डिफ़ॉल्ट बीप",
    soft_click = "सॉफ्ट क्लिक",
    sharp_pop = "शार्प पॉप",
    
    word_dictionary_title = "शब्दकोश",
    add_new_words = "शब्दकोश में नए शब्द जोड़ें",
    view_dictionary_words = "शब्दकोश शब्द देखें",
    clear_dictionary = "शब्दकोश साफ़ करें",
    
    add_word_title = "शब्दकोश में नया शब्द जोड़ें",
    word_to_replace = "शब्द (जिसे बदलना है):",
    replacement_word = "प्रतिस्थापन शब्द:",
    save = "सेव करें",
    cancel = "रद्द करें",
    
    delete_word = "शब्द हटाएं?",
    delete_confirmation = "शब्दकोश से '{}' हटाएं?",
    delete = "हटाएं",
    
    clear_dict_title = "शब्दकोश साफ़ करें",
    clear_dict_message = "क्या आप शब्दकोश से सभी शब्द हटाना चाहते हैं? यह वापस नहीं किया जा सकता।",
    clear_all = "सभी हटाएं",
    
    manage_api_title = "API कुंजियाँ प्रबंधित करें",
    openrouter_key = "OpenRouter कुंजी",
    get_openrouter_key = "OpenRouter कुंजी प्राप्त करें",
    gemini_key = "Gemini कुंजी",
    get_gemini_key = "Gemini कुंजी प्राप्त करें",
    groq_key = "Groq कुंजी",
    get_groq_key = "Groq कुंजी प्राप्त करें",
    deepgram_key = "Deepgram कुंजी",
    get_deepgram_key = "Deepgram कुंजी प्राप्त करें",
    save_keys = "कुंजियाँ सेव करें",
    
    about_title = "प्लगइन के बारे में",
    about_info = "उपयोग कैसे करें:\n1. AI प्रदाता चुनें और API कुंजियाँ जोड़ें।\n2. शुद्ध औपचारिक देशी टाइपिंग के लिए प्यर लैंग्वेज मोड का उपयोग करें।\n3. किसी भाषा को लंबे समय तक दबाकर फेवरेट में जोड़ें/हटाएं।\n4. इमोजी और ऑटो-पंक्चुएशन स्वचालित रूप से जोड़े जाते हैं।",
    
    contact_title = "संपर्क करें",
    join_telegram = "हमारे टेलीग्राम चैनल से जुड़ें",
    give_feedback = "टेलीग्राम पर फीडबैक दें",
    
    target_lang_title = "लक्ष्य भाषा (फेवरेट जोड़ने/हटाने के लिए लंबे समय तक दबाएं)",
    typing_lang_title = "टाइपिंग भाषा (फेवरेट जोड़ने/हटाने के लिए लंबे समय तक दबाएं)",
    removed_from_fav = "फेवरेट से हटा दिया गया",
    added_to_fav = "फेवरेट में जोड़ दिया गया",
    
    word_added = "शब्द जोड़ा गया: {} → {}",
    dictionary_empty = "शब्दकोश खाली है। कुछ शब्द पहले जोड़ें।",
    dictionary_words = "शब्दकोश शब्द ({} शब्द)",
    deleted_word = "हटाया गया: {}",
    dictionary_cleared = "शब्दकोश सफलतापूर्वक साफ़ कर दिया गया",
    
    processing = "प्रोसेसिंग...",
    key_missing = "कुंजी गायब है",
    connection_failed = "कनेक्शन विफल। कृपया API कुंजी या इंटरनेट जांचें।",
    please_enter_word = "कृपया एक शब्द दर्ज करें",
    please_enter_replacement = "कृपया एक प्रतिस्थापन शब्द दर्ज करें",
  },
  
  ["Urdu"] = {
    select_typing_mode = "ٹائپنگ موڈ منتخب کریں",
    ai_settings = "AI ترتیبات",
    source_language = "ماخذ زبان (تبدیل کرنے کے لیے کلک کریں)",
    target_language = "ہدف زبان (تبدیل کرنے کے لیے کلک کریں)",
    enable_translation = "ترجمہ فعال کریں",
    swap = "تبدیل کریں",
    emoji_settings = "ایموجی ترتیبات",
    more_options = "مزید اختیارات",
    save_close = "محفوظ کریں اور بند کریں",
    
    ai_settings_title = "AI ترتیبات",
    select_ai_provider = "AI فراہم کنندہ منتخب کریں",
    manage_api_keys = "API کنجیاں منظم کریں",
    
    emoji_settings_title = "ایموجی ترتیبات",
    enable_smart_emojis = "سمارٹ ایموجی فعال کریں",
    emoji_quantity = "ایموجی مقدار",
    
    more_options_title = "مزید اختیارات",
    other_settings = "دیگر ترتیبات",
    sound_vibration_settings = "آواز اور وائبریشن ترتیبات",
    word_dictionary = "لغت",
    about = "تعارف",
    contact_us = "رابطہ کریں",
    close = "بند کریں",
    
    other_settings_title = "دیگر ترتیبات",
    select_ui_lang = "UI زبان منتخب کریں",
    offline_mode = "آف لائن موڈ (بغیر انٹرنیٹ)",
    copy_clipboard = "متن کو کلپ بورڈ پر کاپی کریں",
    end_action = "اینڈ ایکشن (متن کے آخر میں رویہ)",
    none = "کچھ نہیں",
    new_line = "نئی لائن",
    space = "خالی جگہ",
    space_newline = "خالی جگہ + نئی لائن",
    
    sound_vibration_title = "آواز اور وائبریشن ترتیبات",
    enable_vibration = "وائبریشن فیڈبیک فعال کریں",
    enable_typing_sound = "ٹائپنگ آواز فعال کریں",
    typing_sound_type = "ٹائپنگ آواز کی قسم",
    default_beep = "پہلے سے طے شدہ بیپ",
    soft_click = "نرم کلک",
    sharp_pop = "تیز پاپ",
    
    word_dictionary_title = "لغت",
    add_new_words = "لغت میں نئے الفاظ شامل کریں",
    view_dictionary_words = "لغت کے الفاظ دیکھیں",
    clear_dictionary = "لغت صاف کریں",
    
    add_word_title = "لغت میں نیا لفظ شامل کریں",
    word_to_replace = "لفظ (جسے تبدیل کرنا ہے):",
    replacement_word = "متبادل لفظ:",
    save = "محفوظ کریں",
    cancel = "منسوخ کریں",
    
    delete_word = "لفظ حذف کریں؟",
    delete_confirmation = "لغت سے '{}' حذف کریں؟",
    delete = "حذف کریں",
    
    clear_dict_title = "لغت صاف کریں",
    clear_dict_message = "کیا آپ لغت سے تمام الفاظ حذف کرنا چاہتے ہیں؟ یہ واپس نہیں کیا جا سکتا۔",
    clear_all = "سب حذف کریں",
    
    manage_api_title = "API کنجیاں منظم کریں",
    openrouter_key = "OpenRouter کنجی",
    get_openrouter_key = "OpenRouter کنجی حاصل کریں",
    gemini_key = "Gemini کنجی",
    get_gemini_key = "Gemini کنجی حاصل کریں",
    groq_key = "Groq کنجی",
    get_groq_key = "Groq کنجی حاصل کریں",
    deepgram_key = "Deepgram کنجی",
    get_deepgram_key = "Deepgram کنجی حاصل کریں",
    save_keys = "کنجیاں محفوظ کریں",
    
    about_title = "پلگ ان کے بارے میں",
    about_info = "استعمال کیسے کریں:\n1. AI فراہم کنندہ منتخب کریں اور API کنجیاں شامل کریں۔\n2. خالص رسمی مقامی ٹائپنگ کے لیے پیور لینگویج موڈ استعمال کریں۔\n3. کسی بھی زبان کو لمبے وقت تک دباکر فیورٹ میں شامل/ہٹائیں۔\n4. ایموجی اور آٹو پنکچویشن خود بخود شامل ہوتے ہیں۔",
    
    contact_title = "رابطہ کریں",
    join_telegram = "ہمارے ٹیلیگرام چینل میں شامل ہوں",
    give_feedback = "ٹیلیگرام پر فیڈبیک دیں",
    
    target_lang_title = "ہدف زبان (فیورٹ شامل/ہٹانے کے لیے لمبے وقت تک دبائیں)",
    typing_lang_title = "ٹائپنگ زبان (فیورٹ شامل/ہٹانے کے لیے لمبے وقت تک دبائیں)",
    removed_from_fav = "فیورٹ سے ہٹا دیا گیا",
    added_to_fav = "فیورٹ میں شامل کر دیا گیا",
    
    word_added = "لفظ شامل کیا گیا: {} → {}",
    dictionary_empty = "لغت خالی ہے۔ پہلے کچھ الفاظ شامل کریں۔",
    dictionary_words = "لغت کے الفاظ ({} الفاظ)",
    deleted_word = "حذف کردہ: {}",
    dictionary_cleared = "لغت کامیابی سے صاف کر دی گئی",
    
    processing = "پروسیسنگ...",
    key_missing = "کنجی غائب ہے",
    connection_failed = "کنکشن ناکام۔ براہ کرم API کنجی یا انٹرنیٹ چیک کریں۔",
    please_enter_word = "براہ کرم ایک لفظ درج کریں",
    please_enter_replacement = "براہ کرم ایک متبادل لفظ درج کریں",
  },
  
  ["Marathi"] = {
    select_typing_mode = "टाइपिंग मोड निवडा",
    ai_settings = "AI सेटिंग्ज",
    source_language = "स्रोत भाषा (बदलण्यासाठी क्लिक करा)",
    target_language = "लक्ष्य भाषा (बदलण्यासाठी क्लिक करा)",
    enable_translation = "भाषांतर सक्षम करा",
    swap = "बदला",
    emoji_settings = "इमोजी सेटिंग्ज",
    more_options = "अधिक पर्याय",
    save_close = "जतन करा आणि बंद करा",
    
    ai_settings_title = "AI सेटिंग्ज",
    select_ai_provider = "AI प्रदाता निवडा",
    manage_api_keys = "API की व्यवस्थापित करा",
    
    emoji_settings_title = "इमोजी सेटिंग्ज",
    enable_smart_emojis = "स्मार्ट इमोजी सक्षम करा",
    emoji_quantity = "इमोजी प्रमाण",
    
    more_options_title = "अधिक पर्याय",
    other_settings = "इतर सेटिंग्ज",
    sound_vibration_settings = "ध्वनी आणि कंपन सेटिंग्ज",
    word_dictionary = "शब्दकोश",
    about = "माहिती",
    contact_us = "संपर्क करा",
    close = "बंद करा",
    
    other_settings_title = "इतर सेटिंग्ज",
    select_ui_lang = "UI भाषा निवडा",
    offline_mode = "ऑफलाइन मोड (इंटरनेटशिवाय)",
    copy_clipboard = "मजकूर क्लिपबोर्डवर कॉपी करा",
    end_action = "एंड ॲक्शन (मजकूर शेवटचे वर्तन)",
    none = "काहीही नाही",
    new_line = "नवीन ओळ",
    space = "स्पेस",
    space_newline = "स्पेस + नवीन ओळ",
    
    sound_vibration_title = "ध्वनी आणि कंपन सेटिंग्ज",
    enable_vibration = "कंपन फीडबॅक सक्षम करा",
    enable_typing_sound = "टाइपिंग ध्वनि सक्षम करा",
    typing_sound_type = "टाइपिंग ध्वनि प्रकार",
    default_beep = "डिफॉल्ट बीप",
    soft_click = "सॉफ्ट क्लिक",
    sharp_pop = "शार्प पॉप",
    
    word_dictionary_title = "शब्दकोश",
    add_new_words = "शब्दकोशात नवीन शब्द जोडा",
    view_dictionary_words = "शब्दकोश शब्द पहा",
    clear_dictionary = "शब्दकोश साफ करा",
    
    add_word_title = "शब्दकोशात नवीन शब्द जोडा",
    word_to_replace = "शब्द (जो बदलायचा आहे):",
    replacement_word = "प्रतिस्थापन शब्द:",
    save = "जतन करा",
    cancel = "रद्द करा",
    
    delete_word = "शब्द हटवा?",
    delete_confirmation = "शब्दकोशातून '{}' हटवा?",
    delete = "हटवा",
    
    clear_dict_title = "शब्दकोश साफ करा",
    clear_dict_message = "तुम्हाला शब्दकोशातून सर्व शब्द हटवायचे आहेत का? हे परत करता येत नाही.",
    clear_all = "सर्व हटवा",
    
    manage_api_title = "API की व्यवस्थापित करा",
    openrouter_key = "OpenRouter की",
    get_openrouter_key = "OpenRouter की मिळवा",
    gemini_key = "Gemini की",
    get_gemini_key = "Gemini की मिळवा",
    groq_key = "Groq की",
    get_groq_key = "Groq की मिळवा",
    deepgram_key = "Deepgram की",
    get_deepgram_key = "Deepgram की मिळवा",
    save_keys = "की जतन करा",
    
    about_title = "प्लगइन बद्दल माहिती",
    about_info = "कसे वापरावे:\n1. AI प्रदाता निवडा आणि API की जोडा।\n2. शुद्ध औपचारिक मूळ टाइपिंगसाठी प्योर लँग्वेज मोड वापरा।\n3. कोणतीही भाषा दीर्घकाळ दाबून फेवरेटमध्ये जोडा/हटवा।\n4. इमोजी आणि ऑटो-पंक्चुएशन स्वयंचलितपणे जोडले जातात।",
    
    contact_title = "संपर्क करा",
    join_telegram = "आमच्या टेलिग्राम चॅनलमध्ये सामील व्हा",
    give_feedback = "टेलिग्रामवर फीडबॅक द्या",
    
    target_lang_title = "लक्ष्य भाषा (फेवरेट जोडण्यासाठी/हटवण्यासाठी दीर्घकाळ दाबा)",
    typing_lang_title = "टाइपिंग भाषा (फेवरेट जोडण्यासाठी/हटवण्यासाठी दीर्घकाळ दाबा)",
    removed_from_fav = "फेवरेटमधून हटवले",
    added_to_fav = "फेवरेटमध्ये जोडले",
    
    word_added = "शब्द जोडला: {} → {}",
    dictionary_empty = "शब्दकोश रिकामा आहे. प्रथम काही शब्द जोडा।",
    dictionary_words = "शब्दकोश शब्द ({} शब्द)",
    deleted_word = "हटवले: {}",
    dictionary_cleared = "शब्दकोश यशस्वीरित्या साफ झाला",
    
    processing = "प्रोसेसिंग...",
    key_missing = "की गहाळ आहे",
    connection_failed = "कनेक्शन अयशस्वी। कृपया API की किंवा इंटरनेट तपासा।",
    please_enter_word = "कृपया एक शब्द प्रविष्ट करा",
    please_enter_replacement = "कृपया एक प्रतिस्थापन शब्द प्रविष्ट करा",
  },
  
  ["Gujarati"] = {
    select_typing_mode = "ટાઇપિંગ મોડ પસંદ કરો",
    ai_settings = "AI સેટિંગ્સ",
    source_language = "સ્રોત ભાષા (બદલવા માટે ક્લિક કરો)",
    target_language = "લક્ષ્ય ભાષા (બદલવા માટે ક્લિક કરો)",
    enable_translation = "અનુવાદ સક્ષમ કરો",
    swap = "બદલો",
    emoji_settings = "ઇમોજી સેટિંગ્સ",
    more_options = "વધુ વિકલ્પો",
    save_close = "સાચવો અને બંધ કરો",
    
    ai_settings_title = "AI સેટિંગ્સ",
    select_ai_provider = "AI પ્રદાતા પસંદ કરો",
    manage_api_keys = "API કીઓ મેનેજ કરો",
    
    emoji_settings_title = "ઇમોજી સેટિંગ્સ",
    enable_smart_emojis = "સ્માર્ટ ઇમોજી સક્ષમ કરો",
    emoji_quantity = "ઇમોજી જથ્થો",
    
    more_options_title = "વધુ વિકલ્પો",
    other_settings = "અન્ય સેટિંગ્સ",
    sound_vibration_settings = "ધ્વનિ અને વાઇબ્રેશન સેટિંગ્સ",
    word_dictionary = "શબ્દકોશ",
    about = "વિશે",
    contact_us = "સંપર્ક કરો",
    close = "બંધ કરો",
    
    other_settings_title = "અન્ય સેટિંગ્સ",
    select_ui_lang = "UI ભાષા પસંદ કરો",
    offline_mode = "ઑફલાઇન મોડ (ઇન્ટરનેટ વિના)",
    copy_clipboard = "ટેક્સ્ટ ક્લિપબોર્ડ પર કૉપિ કરો",
    end_action = "એન્ડ એક્શન (ટેક્સ્ટ એન્ડ વર્તન)",
    none = "કંઈ નહીં",
    new_line = "નવી લાઇન",
    space = "સ્પેસ",
    space_newline = "સ્પેસ + નવી લાઇન",
    
    sound_vibration_title = "ધ્વનિ અને વાઇબ્રેશન સેટિંગ્સ",
    enable_vibration = "વાઇબ્રેશન ફીડબેક સક્ષમ કરો",
    enable_typing_sound = "ટાઇપિંગ ધ્વનિ સક્ષમ કરો",
    typing_sound_type = "ટાઇપિંગ ધ્વનિ પ્રકાર",
    default_beep = "ડિફોલ્ટ બીપ",
    soft_click = "સોફ્ટ ક્લિક",
    sharp_pop = "શાર્પ પૉપ",
    
    word_dictionary_title = "શબ્દકોશ",
    add_new_words = "શબ્દકોશમાં નવા શબ્દો ઉમેરો",
    view_dictionary_words = "શબ્દકોશ શબ્દો જુઓ",
    clear_dictionary = "શબ્દકોશ સાફ કરો",
    
    add_word_title = "શબ્દકોશમાં નવો શબ્દ ઉમેરો",
    word_to_replace = "શબ્દ (જેને બદલવો છે):",
    replacement_word = "પ્રતિસ્થાપન શબ્દ:",
    save = "સાચવો",
    cancel = "રદ કરો",
    
    delete_word = "શબ્દ કાઢી નાખો?",
    delete_confirmation = "શબ્દકોશમાંથી '{}' કાઢી નાખો?",
    delete = "કાઢી નાખો",
    
    clear_dict_title = "શબ્દકોશ સાફ કરો",
    clear_dict_message = "શું તમે શબ્દકોશમાંથી બધા શબ્દો કાઢી નાખવા માંગો છો? આ પાછું કરી શકાતું નથી.",
    clear_all = "બધા કાઢી નાખો",
    
    manage_api_title = "API કીઓ મેનેજ કરો",
    openrouter_key = "OpenRouter કી",
    get_openrouter_key = "OpenRouter કી મેળવો",
    gemini_key = "Gemini કી",
    get_gemini_key = "Gemini કી મેળવો",
    groq_key = "Groq કી",
    get_groq_key = "Groq કી મેળવો",
    deepgram_key = "Deepgram કી",
    get_deepgram_key = "Deepgram કી મેળવો",
    save_keys = "કીઓ સાચવો",
    
    about_title = "પ્લગઇન વિશે",
    about_info = "ઉપયોગ કેવી રીતે કરવો:\n1. AI પ્રદાતા પસંદ કરો અને API કીઓ ઉમેરો.\n2. શુદ્ધ ઔપચારિક મૂળ ટાઇપિંગ માટે પ્યોર લેંગ્વેજ મોડનો ઉપયોગ કરો.\n3. કોઈપણ ભાષાને લાંબા સમય સુધી દબાવીને ફેવરિટમાં ઉમેરો/કાઢો.\n4. ઇમોજી અને ઓટો-પંક્ચ્યુએશન આપમેળે ઉમેરાય છે.",
    
    contact_title = "સંપર્ક કરો",
    join_telegram = "અમારા ટેલિગ્રામ ચેનલમાં જોડાઓ",
    give_feedback = "ટેલિગ્રામ પર ફીડબેક આપો",
    
    target_lang_title = "લક્ષ્ય ભાષા (ફેવરિટ ઉમેરવા/કાઢવા માટે લાંબા સમય સુધી દબાવો)",
    typing_lang_title = "ટાઇપિંગ ભાષા (ફેવરિટ ઉમેરવા/કાઢવા માટે લાંબા સમય સુધી દબાવો)",
    removed_from_fav = "ફેવરિટમાંથી દૂર કર્યું",
    added_to_fav = "ફેવરિટમાં ઉમેર્યું",
    
    word_added = "શબ્દ ઉમેર્યો: {} → {}",
    dictionary_empty = "શબ્દકોશ ખાલી છે. પહેલા કેટલાક શબ્દો ઉમેરો.",
    dictionary_words = "શબ્દકોશ શબ્દો ({} શબ્દો)",
    deleted_word = "કાઢી નાખ્યું: {}",
    dictionary_cleared = "શબ્દકોશ સફળતાપૂર્વક સાફ થયો",
    
    processing = "પ્રોસેસિંગ...",
    key_missing = "કી ખૂટે છે",
    connection_failed = "કનેક્શન નિષ્ફળ. કૃપા કરીને API કી અથવા ઇન્ટરનેટ ચેક કરો.",
    please_enter_word = "કૃપા કરીને એક શબ્દ દાખલ કરો",
    please_enter_replacement = "કૃપા કરીને એક પ્રતિસ્થાપન શબ્દ દાખલ કરો",
  },
}

local function getUIText(key, ...)
  local lang = uiLanguage
  local text = nil
  if uiTexts[lang] and uiTexts[lang][key] then
    text = uiTexts[lang][key]
  else
    text = uiTexts["English"][key] or key
  end
  local args = {...}
  for i, arg in ipairs(args) do
    text = text:gsub("{}", tostring(arg), 1)
  end
  return text
end

local dictionaryData = prefs.getString("word_dictionary", "{}")
local changeTable = {}
pcall(function() changeTable = cjson.decode(dictionaryData) end)
if type(changeTable) ~= "table" then changeTable = {} end

local langList = {
  "Afrikaans", "Albanian", "Amharic", "Arabic", "Armenian", "Assamese", "Azerbaijani",
  "Basque", "Belarusian", "Bengali", "Bosnian", "Bulgarian", "Burmese", "Catalan",
  "Cebuano", "Chichewa", "Chinese (Mandarin)", "Corsican", "Croatian", "Czech", "Danish",
  "Dutch", "English", "Esperanto", "Estonian", "Filipino", "Finnish", "French",
  "Galician", "Georgian", "German", "Greek", "Gujarati", "Haitian Creole", "Hausa",
  "Hawaiian", "Hebrew", "Hindi", "Hmong", "Hungarian", "Icelandic", "Igbo",
  "Indonesian", "Irish", "Italian", "Japanese", "Javanese", "Kannada", "Kazakh",
  "Khmer", "Kinyarwanda", "Korean", "Kurdish", "Kyrgyz", "Lao", "Latin", "Latvian",
  "Lithuanian", "Luxembourgish", "Macedonian", "Malagasy", "Malay", "Malayalam",
  "Maltese", "Maori", "Marathi", "Mongolian", "Nepali", "Norwegian", "Odia",
  "Pashto", "Persian", "Polish", "Portuguese", "Punjabi", "Romanian", "Russian",
  "Samoan", "Scots Gaelic", "Serbian", "Sesotho", "Shona", "Sindhi", "Sinhala",
  "Slovak", "Slovenian", "Somali", "Spanish", "Sundanese", "Swahili", "Swedish",
  "Tajik", "Tamil", "Telugu", "Thai", "Turkish", "Ukrainian", "Urdu", "Uzbek",
  "Vietnamese", "Welsh", "Xhosa", "Yiddish", "Yoruba", "Zulu"
}

local function getLangCode(langName)
  local map = {
    ["Hindi"]="hi-IN", ["English"]="en-IN", ["Spanish"]="es-ES", ["French"]="fr-FR", 
    ["German"]="de-DE", ["Gujarati"]="gu-IN", ["Marathi"]="mr-IN", ["Bengali"]="bn-IN", 
    ["Telugu"]="te-IN", ["Tamil"]="ta-IN", ["Urdu"]="ur-PK", ["Arabic"]="ar-SA", 
    ["Russian"]="ru-RU", ["Japanese"]="ja-JP", ["Korean"]="ko-KR", ["Chinese (Mandarin)"]="zh-CN",
    ["Italian"]="it-IT", ["Portuguese"]="pt-PT", ["Dutch"]="nl-NL", ["Turkish"]="tr-TR",
    ["Punjabi"]="pa-IN", ["Malayalam"]="ml-IN", ["Kannada"]="kn-IN", ["Odia"]="or-IN",
    ["Assamese"]="as-IN", ["Sindhi"]="sd-IN", ["Nepali"]="ne-NP", ["Sinhala"]="si-LK"
  }
  return map[langName] or (string.sub(string.lower(langName), 1, 2) .. "-" .. string.sub(string.upper(langName), 1, 2))
end

local toneGen = nil

function triggerSound()
  if not soundEnabled then return end
  pcall(function()
    if not toneGen then toneGen = ToneGenerator(AudioManager.STREAM_SYSTEM, 100) end
    if soundType == "Soft Click" then
      toneGen.startTone(ToneGenerator.TONE_DTMF_0, 40)
    elseif soundType == "Sharp Pop" then
      toneGen.startTone(ToneGenerator.TONE_PROP_BEEP2, 40)
    else
      toneGen.startTone(ToneGenerator.TONE_PROP_BEEP, 50)
    end
  end)
end

function triggerVibration(vType)
  if not vibrationEnabled then return end
  pcall(function()
    local vib = context.getSystemService(Context.VIBRATOR_SERVICE)
    if vib then
      if vType == "typing" then
        vib.vibrate(150)
      elseif vType == "settings" then
        vib.vibrate(200)
      end
    end
  end)
end

function announce(msg)
  if not msg then return end
  pcall(function() if service and service.speak then service.speak(msg) end end)
end

function openUrl(url)
  local intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
  intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
  context.startActivity(intent)
end

function finalGuard(text)
  if not text then return "" end
  local t = text
  local nums = {
    ["one"]="1",["two"]="2",["three"]="3",["four"]="4",["five"]="5",
    ["six"]="6",["seven"]="7",["eight"]="8",["nine"]="9",["ten"]="10",
    ["One"]="1",["Two"]="2",["Three"]="3",["Four"]="4",["Five"]="5",
    ["Six"]="6",["Seven"]="7",["Eight"]="8",["Nine"]="9",["Ten"]="10"
  }
  for k,v in pairs(nums) do t = t:gsub("%f[%a]"..k.."%f[%A]", v) end
  return t
end

function applyDictionaryReplacement(text)
  if not text or text == "" then return text end
  local result = text
  for originalWord, replacementWord in pairs(changeTable) do
    result = result:gsub(originalWord, replacementWord)
  end
  return result
end

function processOffline(text, callback)
  local t = text
  if selectedLanguage == "Hindi" or selectedLanguage == "Marathi" or selectedLanguage == "Bengali" or selectedLanguage == "Gujarati" then
    t = t .. " " 
  else
    t = t:gsub("^%l", string.upper)
    t = t .. "."
  end
  callback(t)
end

function processWithAI(text, isTranslatedAlready, callback)
  local apiKey, apiUrl, modelList, payloadFormat
  local minE, maxE = 1, 3
  if emojiQty == "Medium" then minE, maxE = 3, 5 elseif emojiQty == "High" then minE, maxE = 5, 7 end

  if selectedProvider == "OpenRouter" then
    apiKey = orKey
    apiUrl = "https://openrouter.ai/api/v1/chat/completions"
    modelList = {"openai/gpt-4o", "openai/gpt-4o-mini"}
    payloadFormat = "openai"
  elseif selectedProvider == "Groq" or selectedProvider == "Deepgram" then
    apiKey = groqKey
    apiUrl = "https://api.groq.com/openai/v1/chat/completions"
    modelList = {"llama-3.3-70b-versatile", "llama-3.1-8b-instant"}
    payloadFormat = "openai"
  elseif selectedProvider == "Gemini" then
    apiKey = geminiKey
    apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/"
    modelList = {"gemini-2.0-flash-exp", "gemini-1.5-flash"}
    payloadFormat = "google"
  end

  if (not apiKey or apiKey == "") then 
    announce(selectedProvider .. " " .. getUIText("key_missing"))
    return 
  end

  apiKey = apiKey:gsub("^%s*(.-)%s*$", "%1")

local transRule = ""
  if isTranslatedAlready then
    transRule = "TRANSLATION MODE ON: The text has already been accurately translated via Google Engine. Do NOT translate it again. Provide flawless formatting, advanced punctuation, and emojis."
  else
    transRule = [[
TRANSLATION MODE OFF - ABSOLUTE PROHIBITION OF TRANSLATION:

CRITICAL RULES (STRICT ENFORCEMENT):

1. NEVER TRANSLATE ANY WORD - ABSOLUTE ZERO TOLERANCE:
   - "नमस्ते" MUST remain "नमस्ते" - NEVER change to "hello"
   - "समस्या" MUST remain "समस्या" - NEVER change to "problem"  
   - "बदलाव" MUST remain "बदलाव" - NEVER change to "change"
   - EVERY word MUST stay in its ORIGINAL language exactly as spoken

2. NO WORD SUBSTITUTION OF ANY KIND:
   - Do NOT replace Hindi/Urdu/Marathi/Gujarati words with English equivalents
   - Do NOT replace any native language word with an English word
   - Every single word from the input must appear in the output in the same language

3. SCRIPT PRESERVATION:
   - Hindi words → Keep in Devanagari script (नमस्ते, समस्या, बदलाव)
   - Urdu words → Keep in Arabic script (سلام, مسئلہ, تبدیلی)
   - English words → Keep in Roman script (hello, problem, change)

4. OUTPUT LANGUAGE RULE:
   - If input contains "नमस्ते" and "hello", output must contain "नमस्ते" and "hello"
   - NEVER convert "नमस्ते" to "hello" or "hello" to "नमस्ते"
   - NEVER convert any word from its original language to another language

5. ZERO TRANSLATION POLICY:
   - This is a TRANSCRIPTION system, NOT a translation system
   - Transcribe exactly what was spoken in the original language
   - If user spoke in Hindi, output Hindi. If in English, output English.

REMEMBER: Your job is to TRANSCRIBE, not to TRANSLATE. Every word must stay in its original language exactly as spoken.
]]
  end

  local styleDirectives = "TONE: Auto-Correct. Fix minor spelling mistakes. DO NOT add extra information or filler."

  local isAIWriterMode = (typingMode == "A.I. Writer Mode")
  local isPureMode = (typingMode == "Pure Language Mode")
  
  local scriptRule = ""
  local userForceScriptCmd = ""

if isPureMode then
    scriptRule = [[
PURE LANGUAGE MODE (ULTRA PURE - CRITICAL & STRICT):
- MISSION: Output the text using 100% PURE, CLASSICAL, and HIGHLY ACCURATE literary vocabulary of the target language.
- STRICT SCRIPT LOCK: You MUST ABSOLUTELY use the native script exclusively. NEVER use A-Z Roman characters under any circumstances.
- VOCABULARY PURIFICATION: Identify and translate ANY English word, slang, or mixed language word into the purest, most formal native word.
  - Examples: 'problem' → 'समस्या' (Hindi), 'समस्या' (Marathi), 'সমস্যা' (Bengali)
  - 'mobile' → 'मोबाइल' is NOT pure. Use 'दूरभाष' or 'हस्तचलित दूरभाष'
  - 'setting' → 'विन्यास' or 'प्राचल'
  - 'perfect' → 'परिपूर्ण' or 'उत्तम'
- GRAMMAR PURITY: Use only native grammatical structures. Avoid any sentence structure influenced by English.
- FORMALITY LEVEL: Use the highest standard literary form (Suddha/Shuddha) - as found in advanced textbooks and literary works.
- NO COMPROMISES: Every single word must be in pure native language. If a word has no direct native equivalent, use the closest scholarly accepted native term.
- OUTPUT: Return ONLY the pure language text. NO explanations, NO meta-text.
]]
    userForceScriptCmd = "Convert EVERY word to 100% PURE classical native vocabulary in native script. NO Roman script anywhere. Use highest literary standard."
  
  elseif typingMode == "Auto Detect Script" then
    scriptRule = [[
SCRIPT MAPPING (STRICT DICTIONARY-BACKED ENGINE):
- THE FIRST WORD RULE: Pay intense attention to the very first word of the dictation. If it is a greeting like 'hello', 'hi', or 'hey', it MUST be output in A-Z Roman script (e.g., 'Hello'), NEVER in a native script.
- CROSS-CHECK EVERY WORD: You must verify if each spoken word exists in the standard English dictionary.
- IF IT IS AN ENGLISH DICTIONARY WORD: You are STRICTLY FORBIDDEN from outputting it in a native script. It MUST be written in A-Z Roman script. This applies to ALL English words (e.g., 'hello', 'problem', 'perfect', 'typing', 'mobile', 'setting', 'offline', 'mode') regardless of their position in the sentence.
- Native language words MUST remain in their original native script. NEVER romanize native words.
- ACRONYMS: Apply periods ONLY to genuine known abbreviations (e.g., C.I.D., A.T.M., V.I.P.). DO NOT format regular English words as acronyms.
]]
    userForceScriptCmd = "Enforce the FIRST WORD RULE. Convert ALL English dictionary words to A-Z Roman script."
  
  elseif isAIWriterMode then
    scriptRule = [[
A.I. WRITER MODE (PROFESSIONAL ENHANCEMENT - ADVANCED):
- MISSION: Transform the spoken text into exceptionally well-written, polished, and professional content while preserving 100% of the original meaning.

COMPREHENSIVE ENHANCEMENT RULES:

1. GRAMMAR MASTERY:
   - Fix ALL grammar mistakes including subject-verb agreement, tense consistency, and article usage.
   - Correct preposition errors and sentence fragments.
   - Ensure proper use of conjunctions and transition words.

2. SENTENCE STRUCTURE:
   - Improve sentence flow by restructuring awkward or run-on sentences.
   - Vary sentence length for natural rhythm (mix short and medium-length sentences).
   - Eliminate unnecessary repetition and wordiness.
   - Convert passive voice to active voice where appropriate for clarity.

3. PROFESSIONAL VOCABULARY:
   - Replace informal or casual words with more precise, professional alternatives.
   - Choose vivid, impactful words over generic ones (e.g., "implement" instead of "do", "analyze" instead of "look at").
   - Remove filler words like "actually", "basically", "you know", "sort of", "kind of".

4. CLARITY & READABILITY:
   - Break down complex ideas into clear, digestible statements.
   - Ensure logical progression of thoughts.
   - Add appropriate transition phrases for coherence (e.g., "Furthermore", "However", "Consequently").
   - Remove ambiguity - make every sentence crystal clear.

5. TONE ADAPTATION:
   - Adapt to professional/business tone suitable for emails, reports, or documentation.
   - Maintain confidence without being arrogant.
   - Keep warmth and approachability when appropriate.

6. PUNCTUATION & FORMATTING:
   - Add proper punctuation: periods, commas, semicolons, colons where needed.
   - Use bullet points or numbered lists ONLY if the original speech clearly indicates a list.
   - Capitalize proper nouns, beginnings of sentences, and important terms.

7. PRESERVATION RULES (CRITICAL):
   - ABSOLUTELY DO NOT change any factual information, numbers, dates, names, or specific data.
   - DO NOT add new ideas, opinions, or information that wasn't spoken.
   - DO NOT remove any key information - enhance, never delete meaningful content.
   - Keep the original meaning 100% intact.

8. LANGUAGE CONSISTENCY:
   - Output MUST be in the same language as the input (]] .. selectedLanguage .. [[).
   - Do NOT translate between languages.

OUTPUT REQUIREMENT: Return ONLY the enhanced professional text. NO prefixes like "Enhanced:", "Output:", or any meta-text. NO explanations of what you changed.
]]

    userForceScriptCmd = "Enhance the following dictation to professional quality: Fix grammar, improve clarity, strengthen vocabulary, optimize sentence flow. PRESERVE ALL FACTS and MEANING. Return ONLY the enhanced text in " .. selectedLanguage .. ". NO meta-text, NO explanations And follow all the typing mode rules."

  end

  local acronymRule = [[
ACRONYM & SHORT FORM FORMATTING:
- Ensure ANY spoken sequence of individual letters or unknown short forms (like V I T, V I D, C I D, A P I) is forcefully formatted WITH dots (e.g., V.I.T., V.I.D., C.I.D., A.P.I.). Do NOT alter or guess the letters spoken.
]]

  local emojiRules = ""
  if isAIWriterMode then
    emojiRules = emojiEnabled and ([[
EMOJIS: Insert between 1 and ]] .. maxE .. [[ professional and contextually relevant emojis at the end. Use sparingly - only when they add genuine value. Prefer subtle, professional emojis over flashy ones.
]]) or "EMOJIS: DO NOT ADD EMOJIS."
  elseif isPureMode then
    emojiRules = emojiEnabled and ([[
EMOJIS: Insert between 1 and ]] .. maxE .. [[ culturally appropriate emojis. Keep them simple and relevant.
]]) or "EMOJIS: DO NOT ADD EMOJIS."
  else
    emojiRules = emojiEnabled and ([[
EMOJIS: Insert between 1 and ]] .. maxE .. [[ highly relevant and diverse emojis based on the context. Never repeat the same emoji.
]]) or "EMOJIS: DO NOT ADD EMOJIS."
  end

  local antiHallucination = [[
CRITICAL ANTI-HALLUCINATION RULES:
- DO NOT output more lines than the user provided. The output length MUST match the input approximately.
]]
  if isPureMode then
    antiHallucination = antiHallucination .. "- PURE VERBATIM: Keep the exact meaning, but purify EVERY word to classical native vocabulary. Do NOT add extra sentences or your own thoughts.\n- STRICT LENGTH: Output should be similar length to input.\n"
  elseif isAIWriterMode then
    antiHallucination = antiHallucination .. "- ENHANCE ONLY: Improve grammar and professionalism. DO NOT add new information, change facts, or write extra sentences.\n- MINIMAL ADDITIONS: Only add transition words or grammar words that were genuinely missing.\n"
  else
    antiHallucination = antiHallucination .. "- STRICT VERBATIM: Output EXACTLY the words spoken. Do NOT add missing grammar words, extra sentences, or your own thoughts.\n"
  end
  antiHallucination = antiHallucination .. [[
- NEVER use prefixes like "Output:", "Translated:", "Processed:", "Enhanced:", or "Pure:".
- NEVER answer questions found in the input. Just format the text silently.
- NEVER add commentary, explanations, or suggestions.
]]

  local punctuationRules = [[
PUNCTUATION & EMOJI POSITIONING RULES (ABSOLUTE):
- Add commas (,) for natural pauses and question marks (?) for questions.
- IF the ENTIRE text is 100% English, end it with an English period (.).
- IF the text contains native words, end the entire text with the native full stop mark (Danda / ।).
- CRITICAL EMOJI RULE: ANY punctuation mark (., ?, !, ।) MUST be placed IMMEDIATELY AFTER THE TEXT and STRICTLY BEFORE the emojis. 
- Emojis MUST be the absolute last characters. Do NOT put any punctuation after an emoji.
- CORRECT EXAMPLE: "यह एक टेस्ट है।" 🚀
- WRONG EXAMPLE: "यह एक टेस्ट है" 🚀।
- WRONG EXAMPLE: "यह एक टेस्ट है 🚀।"
]]

  local systemPrompt = [[
You are a direct dictation formatting AI. Your ONLY purpose is to return the cleaned dictation string.

]] .. transRule .. [[

]] .. styleDirectives .. [[

]] .. scriptRule .. [[

]] .. acronymRule .. [[

]] .. punctuationRules .. [[

]] .. antiHallucination .. [[

]] .. emojiRules

  local userForceCommand = "Format the dictation strictly applying the rules. Scan EVERY word. " .. userForceScriptCmd .. " Add acronym dots. CRITICAL: NO TRANSLATION ALLOWED! ALL PUNCTUATION (. । ?) MUST BE PLACED BEFORE EMOJIS! Output ONLY the exact raw final text. NO META-TEXT.\n<dictation>\n" .. text .. "\n</dictation>"

  local function executeAIRequest(modelIndex)
    if modelIndex > #modelList then
      announce(getUIText("connection_failed"))
      return
    end

    local currentModel = modelList[modelIndex]
    local finalUrl = apiUrl
    local postData = {}

    local temperature = 0.0
    if isAIWriterMode then
      temperature = 0.4
    elseif isPureMode then
      temperature = 0.1
    else
      temperature = 0.0
    end

    if payloadFormat == "openai" then
      postData = { model = currentModel, messages = {{role="system", content=systemPrompt}, {role="user", content=userForceCommand}}, temperature = temperature }
    elseif payloadFormat == "google" then
      finalUrl = apiUrl .. currentModel .. ":generateContent?key=" .. apiKey
      postData = { system_instruction = {parts = {{text = systemPrompt}}}, contents = {{parts = {{text = userForceCommand}}}}, generationConfig = {temperature = temperature} }
    end

    local headers = {
      ["Content-Type"] = "application/json",
      ["Accept"] = "application/json"
    }
    
    if payloadFormat == "openai" then
      headers["Authorization"] = "Bearer " .. apiKey
    end

    Http.post(finalUrl, cjson.encode(postData), headers, function(status, data)
      if status == 200 and data then
        local ok, decoded = pcall(cjson.decode, data)
        if ok and decoded then
          local outputText = nil
          if payloadFormat == "openai" and decoded.choices and decoded.choices[1] then
            outputText = decoded.choices[1].message.content
          elseif payloadFormat == "google" and decoded.candidates and decoded.candidates[1] then
            outputText = decoded.candidates[1].content.parts[1].text
          end

          if outputText then
            callback(outputText)
            return
          end
        end
      end
      executeAIRequest(modelIndex + 1)
    end)
  end

  executeAIRequest(1)
end

function trim(s)
    if s == nil then return "" end
    return tostring(s):gsub("^%s*(.-)%s*$", "%1")
end

function showUpdateErrorDialog(title, message)
    mainHandler.post(Runnable({
        run = function()
            local errorDialog = LuaDialog(context)
            errorDialog.setTitle(title)
            errorDialog.setMessage(message)
            errorDialog.setButton("OK", function()
                errorDialog.dismiss()
            end)
            errorDialog.show()
        end
    }))
end

function performUpdate(mainCode, onlineVersion)
    if not mainCode or trim(mainCode) == "" then
        showUpdateErrorDialog("Update Failed", "Update script is empty.")
        return
    end
    
    updateInProgress = true
    
    local function updateProcess()
        local success = false
        local tempPath = currentFilePath .. ".temp_update"
        local f = io.open(tempPath, "w")
        if f then
            f:write(mainCode)
            f:close()
            
            local fileExists = io.open(currentFilePath, "r")
            if fileExists then
                fileExists:close()
                local delSuccess = pcall(function()
                    os.remove(currentFilePath)
                end)
                if delSuccess then
                    local renameSuccess = pcall(function()
                        os.rename(tempPath, currentFilePath)
                    end)
                    if renameSuccess then
                        success = true
                    end
                end
            else
                local renameSuccess = pcall(function()
                    os.rename(tempPath, currentFilePath)
                end)
                if renameSuccess then
                    success = true
                end
            end
            
            if not success then
                pcall(function() os.remove(tempPath) end)
            end
        end
        
        if success then
            updateInProgress = false
            mainHandler.post(Runnable({
                run = function()
                    local successDialog = LuaDialog(context)
                    successDialog.setTitle("Update Successful")
                    successDialog.setMessage("Plugin successfully updated to version " .. onlineVersion .. ".\n\nPlugin will restart automatically.")
                    successDialog.setButton("OK", function()
                        successDialog.dismiss()
                        if moreOptionsDlg then pcall(function() moreOptionsDlg.dismiss() end) end
                        if settingsDlg then pcall(function() settingsDlg.dismiss() end) end
                        mainHandler.postDelayed(Runnable({
                            run = function()
                                local func, err = loadfile(currentFilePath)
                                if func then
                                    pcall(func)
                                else
                                    announce("Error reloading plugin")
                                end
                            end
                        }), 2000)
                    end)
                    successDialog.show()
                end
            }))
        else
            updateInProgress = false
            showUpdateErrorDialog("Update Failed", "Update failed. Please try again.")
        end
    end
    
    local updateThread = Thread(luajava.bindClass("java.lang.Runnable"){
        run = updateProcess
    })
    updateThread.start()
end

function checkForUpdates(manualCheck)
    if updateInProgress then
        if manualCheck then
            showUpdateErrorDialog("Update In Progress", "An update is already in progress. Please wait.")
        end
        return
    end
    
    if manualCheck then announce("Checking for updates...") end
    
    local timestamp = tostring(os.time())
    local Http = luajava.bindClass("com.androlua.Http")
    if not Http then Http = import("com.androlua.Http") end
    
    Http.get(versionUrl .. "?t=" .. timestamp, function(code, response)
        if code == 200 and response then
            local onlineVersion = trim(response)
            if onlineVersion ~= "" and onlineVersion ~= currentAppVersion then
                Http.get(updateScriptUrl .. "?t=" .. timestamp, function(code2, mainCode)
                    if code2 == 200 and mainCode and trim(mainCode) ~= "" then
                        Http.get(notesUrl .. "?t=" .. timestamp, function(nCode, notesData)
                            local releaseNotes = "A new version (" .. onlineVersion .. ") is available.\nCurrent version: " .. currentAppVersion .. "\n\nWould you like to update now?"
                            if nCode == 200 and notesData then
                                releaseNotes = "A new version (" .. onlineVersion .. ") is available.\n\nRelease Notes:\n" .. notesData .. "\n\nWould you like to update now?"
                            end
                            
                            mainHandler.post(Runnable({
                                run = function()
                                    local updateAlertDlg = LuaDialog(context)
                                    updateAlertDlg.setTitle("Update Available!")
                                    updateAlertDlg.setMessage(releaseNotes)
                                    updateAlertDlg.setButton("Update Now", function()
                                        updateAlertDlg.dismiss()
                                        performUpdate(mainCode, onlineVersion)
                                    end)
                                    updateAlertDlg.setButton2("Later", function()
                                        updateAlertDlg.dismiss()
                                    end)
                                    updateAlertDlg.show()
                                end
                            }))
                        end)
                    elseif manualCheck then
                        showUpdateErrorDialog("Update Failed", "Failed to fetch update script.")
                    end
                end)
            else
                if manualCheck then announce("You are on the latest version.") end
            end
        else
            if manualCheck then announce("Failed to check for updates.") end
        end
    end)
end

function showWordDictionaryDialog()
  local dlg = LuaDialog(context)
  local layout = {
    LinearLayout, orientation="vertical", padding="20dp",
    {TextView, text=getUIText("word_dictionary_title"), textSize="20sp", textColor="#2196F3", layout_marginBottom="20dp", gravity="center"},
    {Button, id="add_word_btn", text=getUIText("add_new_words"), backgroundColor="#4CAF50", textColor="#FFFFFF", layout_marginBottom="15dp"},
    {Button, id="view_words_btn", text=getUIText("view_dictionary_words"), backgroundColor="#2196F3", textColor="#FFFFFF", layout_marginBottom="15dp"},
    {Button, id="clear_dict_btn", text=getUIText("clear_dictionary"), backgroundColor="#F44336", textColor="#FFFFFF", layout_marginBottom="20dp"},
    {Button, id="close_dict_btn", text=getUIText("close"), backgroundColor="#9E9E9E", textColor="#FFFFFF"}
  }
  local view = loadlayout(layout)
  dlg.setView(view).show()
  
  add_word_btn.onClick = function()
    dlg.dismiss()
    showAddWordDialog()
  end
  
  view_words_btn.onClick = function()
    dlg.dismiss()
    showViewDictionaryDialog()
  end
  
  clear_dict_btn.onClick = function()
    dlg.dismiss()
    showClearDictionaryConfirmDialog()
  end
  
  close_dict_btn.onClick = function()
    dlg.dismiss()
  end
end

function showAddWordDialog()
  local dlg = LuaDialog(context)
  local layout = {
    LinearLayout, orientation="vertical", padding="20dp",
    {TextView, text=getUIText("add_word_title"), textSize="18sp", textColor="#2196F3", layout_marginBottom="15dp", gravity="center"},
    {TextView, text=getUIText("word_to_replace"), layout_marginBottom="5dp"},
    {EditText, id="original_word_et", hint="e.g., hello", layout_marginBottom="15dp", backgroundColor="#F5F5F5", padding="10dp"},
    {TextView, text=getUIText("replacement_word"), layout_marginBottom="5dp"},
    {EditText, id="replacement_word_et", hint="e.g., नमस्ते", layout_marginBottom="20dp", backgroundColor="#F5F5F5", padding="10dp"},
    {LinearLayout, orientation="horizontal",
      {Button, id="save_word_btn", text=getUIText("save"), backgroundColor="#4CAF50", textColor="#FFFFFF", layout_weight=1, layout_marginRight="5dp"},
      {Button, id="cancel_word_btn", text=getUIText("cancel"), backgroundColor="#F44336", textColor="#FFFFFF", layout_weight=1}
    }
  }
  local view = loadlayout(layout)
  dlg.setView(view).show()
  
  save_word_btn.onClick = function()
    local originalWord = tostring(original_word_et.text):gsub("^%s*(.-)%s*$", "%1")
    local replacementWord = tostring(replacement_word_et.text):gsub("^%s*(.-)%s*$", "%1")
    
    if originalWord == "" then
      announce(getUIText("please_enter_word"))
      return
    end
    
    if replacementWord == "" then
      announce(getUIText("please_enter_replacement"))
      return
    end
    
    changeTable[originalWord] = replacementWord
    local saveJson = cjson.encode(changeTable)
    editor.putString("word_dictionary", saveJson).commit()
    announce(getUIText("word_added", originalWord, replacementWord))
    dlg.dismiss()
    showWordDictionaryDialog()
  end
  
  cancel_word_btn.onClick = function()
    dlg.dismiss()
    showWordDictionaryDialog()
  end
end

function showViewDictionaryDialog()
  if not next(changeTable) then
    announce(getUIText("dictionary_empty"))
    showWordDictionaryDialog()
    return
  end
  
  local dictList = {}
  for orig, repl in pairs(changeTable) do
    table.insert(dictList, orig .. " → " .. repl)
  end
  table.sort(dictList)
  
  local listDlg = LuaDialog(context)
  listDlg.setTitle(getUIText("dictionary_words", #dictList))
  local list = ListView(context)
  list.setAdapter(ArrayAdapter(context, android.R.layout.simple_list_item_1, dictList))
  list.onItemClick = function(parent, view, position, id)
    -- Optional: Show options to delete individual word
  end
  list.onItemLongClick = function(parent, view, position, id)
    local selectedItem = dictList[position + 1]
    local originalWord = selectedItem:match("^(.-) →")
    if originalWord then
      local confirmDlg = LuaDialog(context)
      confirmDlg.setTitle(getUIText("delete_word"))
      confirmDlg.setMessage(getUIText("delete_confirmation", originalWord))
      confirmDlg.setButton(getUIText("delete"), function()
        changeTable[originalWord] = nil
        local saveJson = cjson.encode(changeTable)
        editor.putString("word_dictionary", saveJson).commit()
        announce(getUIText("deleted_word", originalWord))
        confirmDlg.dismiss()
        listDlg.dismiss()
        showViewDictionaryDialog()
      end)
      confirmDlg.setButton2(getUIText("cancel"), function() confirmDlg.dismiss() end)
      confirmDlg.show()
    end
    return true
  end
  listDlg.setView(list)
  listDlg.setButton(getUIText("close"), function() listDlg.dismiss() end)
  listDlg.show()
end

function showClearDictionaryConfirmDialog()
  local confirmDlg = LuaDialog(context)
  confirmDlg.setTitle(getUIText("clear_dict_title"))
  confirmDlg.setMessage(getUIText("clear_dict_message"))
  confirmDlg.setButton(getUIText("clear_all"), function()
    changeTable = {}
    editor.putString("word_dictionary", "{}").commit()
    announce(getUIText("dictionary_cleared"))
    confirmDlg.dismiss()
    showWordDictionaryDialog()
  end)
  confirmDlg.setButton2(getUIText("cancel"), function() confirmDlg.dismiss(); showWordDictionaryDialog() end)
  confirmDlg.show()
end

function showLanguageSelectDialog(isTarget, sourceBtn)
  local favStr = prefs.getString("fav_languages", "[]")
  local favs = {}
  pcall(function() favs = cjson.decode(favStr) end)
  if type(favs) ~= "table" then favs = {} end

  local sortedList = {}
  local displayList = {}
  local counter = 1

  for _, fl in ipairs(favs) do
    table.insert(sortedList, fl)
    table.insert(displayList, counter .. ". " .. fl .. " ⭐")
    counter = counter + 1
  end
  
  for _, l in ipairs(langList) do
    local isFav = false
    for _, fl in ipairs(favs) do
      if l == fl then isFav = true break end
    end
    if not isFav then 
      table.insert(sortedList, l)
      table.insert(displayList, counter .. ". " .. l)
      counter = counter + 1
    end
  end

  local listDlg = LuaDialog(context)
  listDlg.setTitle(isTarget and getUIText("target_lang_title") or getUIText("typing_lang_title"))
  local list = ListView(context)
  list.setAdapter(ArrayAdapter(context, android.R.layout.simple_list_item_1, displayList))
  
  list.onItemClick = function(parent, view, position, id)
    local selected = sortedList[position + 1]
    if isTarget then
      targetLanguage = selected
    else
      selectedLanguage = selected
    end
    if sourceBtn then sourceBtn.setText(selected) end
    listDlg.dismiss()
  end
  
  list.onItemLongClick = function(parent, view, position, id)
    local selected = sortedList[position + 1]
    local isFav = false
    local favIdx = -1
    for i, fl in ipairs(favs) do
      if fl == selected then
        isFav = true
        favIdx = i
        break
      end
    end
    
    if isFav then
      table.remove(favs, favIdx)
      announce(selected .. " " .. getUIText("removed_from_fav"))
    else
      table.insert(favs, selected)
      announce(selected .. " " .. getUIText("added_to_fav"))
    end
    
    editor.putString("fav_languages", cjson.encode(favs)).commit()
    listDlg.dismiss()
    showLanguageSelectDialog(isTarget, sourceBtn)
    return true
  end
  
  listDlg.setView(list)
  listDlg.show()
end

function showOtherSettingsDialog()
  local uiLanguagesList = {"English", "Hindi", "Urdu", "Marathi", "Gujarati"}
  local endActionsList = {getUIText("none"), getUIText("new_line"), getUIText("space"), getUIText("space_newline")}
  
  local dlg = LuaDialog(context)
  local layout = {
    LinearLayout, orientation="vertical", padding="20dp",
    {TextView, text=getUIText("other_settings_title"), textSize="20sp", textColor="#2196F3", layout_marginBottom="20dp", gravity="center"},
    {TextView, text=getUIText("select_ui_lang"), layout_marginBottom="5dp"},
    {Spinner, id="ui_lang_sp", layout_marginBottom="15dp"},
    {CheckBox, id="sub_offline_chk", text=getUIText("offline_mode"), checked=offlineMode, layout_marginBottom="15dp"},
    {CheckBox, id="sub_copy_chk", text=getUIText("copy_clipboard"), checked=copyToClipboard, layout_marginBottom="15dp"},
    {TextView, text=getUIText("end_action"), layout_marginBottom="5dp"},
    {Spinner, id="sub_end_sp", layout_marginBottom="20dp"},
    {Button, id="sub_other_save_btn", text=getUIText("save_close"), backgroundColor="#4CAF50", textColor="#FFFFFF"}
  }
  dlg.setView(loadlayout(layout)).show()
  
  ui_lang_sp.setAdapter(ArrayAdapter(context, android.R.layout.simple_spinner_item, uiLanguagesList))
  for i,v in ipairs(uiLanguagesList) do if v == uiLanguage then ui_lang_sp.setSelection(i-1) end end
  
  sub_end_sp.setAdapter(ArrayAdapter(context, android.R.layout.simple_spinner_item, endActionsList))
  local endActionText = getUIText(string.lower(endAction:gsub(" ", "_"):gsub("%+", "_plus")))
  for i,v in ipairs(endActionsList) do 
    if v == endAction or v == endActionText then 
      sub_end_sp.setSelection(i-1) 
      break
    end
  end

  sub_other_save_btn.onClick = function()
    uiLanguage = uiLanguagesList[ui_lang_sp.getSelectedItemPosition() + 1]
    offlineMode = sub_offline_chk.isChecked()
    copyToClipboard = sub_copy_chk.isChecked()
    local selectedEndAction = endActionsList[sub_end_sp.getSelectedItemPosition() + 1]
    if selectedEndAction == getUIText("none") then endAction = "None"
    elseif selectedEndAction == getUIText("new_line") then endAction = "New Line"
    elseif selectedEndAction == getUIText("space") then endAction = "Space"
    elseif selectedEndAction == getUIText("space_newline") then endAction = "Space + New Line"
    end
    editor.putString("ui_language", uiLanguage).commit()
    dlg.dismiss()
  end
end

function showAISettingsDialog()
  local providers = {"OpenRouter", "Gemini", "Groq", "Deepgram"}
  local dlg = LuaDialog(context)
  local layout = {
    LinearLayout, orientation="vertical", padding="20dp",
    {TextView, text=getUIText("ai_settings_title"), textSize="20sp", textColor="#2196F3", layout_marginBottom="20dp", gravity="center"},
    {TextView, text=getUIText("select_ai_provider"), layout_marginBottom="5dp"},
    {Spinner, id="sub_provider_sp", layout_marginBottom="15dp"},
    {Button, id="sub_manage_api_btn", text=getUIText("manage_api_keys"), backgroundColor="#FF9800", textColor="#FFFFFF", layout_marginBottom="20dp"},
    {Button, id="sub_ai_save_btn", text=getUIText("save_close"), backgroundColor="#4CAF50", textColor="#FFFFFF"}
  }
  dlg.setView(loadlayout(layout)).show()
  
  sub_provider_sp.setAdapter(ArrayAdapter(context, android.R.layout.simple_spinner_item, providers))
  for i,v in ipairs(providers) do if v == selectedProvider then sub_provider_sp.setSelection(i-1) end end
  
  sub_manage_api_btn.onClick = function() showApiDialog() end
  
  sub_ai_save_btn.onClick = function()
    selectedProvider = providers[sub_provider_sp.getSelectedItemPosition() + 1]
    dlg.dismiss()
  end
end

function showAboutDialog()
  local dlg = LuaDialog(context)
  local info = "Extreme AI Voice Typer v2.6\n\n" ..
  "Developer: Anurag Anant\n\n" ..
  getUIText("about_info")
  
  local layout = {
    LinearLayout, orientation="vertical", padding="20dp",
    {TextView, text=getUIText("about_title"), textSize="20sp", textColor="#2196F3", layout_marginBottom="15dp", gravity="center"},
    {TextView, text=info, textSize="15sp", textColor="#333333", layout_marginBottom="20dp"},
    {Button, text=getUIText("close"), backgroundColor="#F44336", textColor="#FFFFFF", onClick=function() dlg.dismiss() end}
  }
  dlg.setView(loadlayout(layout)).show()
end

function showContactDialog()
  local dlg = LuaDialog(context)
  local layout = {
    LinearLayout, orientation="vertical", padding="20dp",
    {TextView, text=getUIText("contact_title"), textSize="20sp", textColor="#2196F3", layout_marginBottom="20dp", gravity="center"},
    {Button, text=getUIText("join_telegram"), onClick=function() openUrl("https://t.me/Ttforblind") end, backgroundColor="#2196F3", textColor="#FFFFFF", layout_marginBottom="15dp"},
    {Button, text=getUIText("give_feedback"), onClick=function() openUrl("https://t.me/Anurag_anant") end, backgroundColor="#FF9800", textColor="#FFFFFF", layout_marginBottom="20dp"},
    {Button, text=getUIText("close"), backgroundColor="#F44336", textColor="#FFFFFF", onClick=function() dlg.dismiss() end}
  }
  dlg.setView(loadlayout(layout)).show()
end

function showMoreOptionsDialog()
  moreOptionsDlg = LuaDialog(context)
  local layout = {
    ScrollView, layout_width="fill",
    {LinearLayout, orientation="vertical", padding="20dp",
      {TextView, text=getUIText("more_options_title"), textSize="22sp", textColor="#2196F3", layout_marginBottom="20dp", gravity="center"},
      {Button, text="Check For Updates", onClick=function() checkForUpdates(true); moreOptionsDlg.dismiss() end, backgroundColor="#FF5722", textColor="#FFFFFF", layout_marginBottom="10dp"},
      {Button, text=getUIText("other_settings"), onClick=function() showOtherSettingsDialog() end, backgroundColor="#607D8B", textColor="#FFFFFF", layout_marginBottom="10dp"},
      {Button, text=getUIText("sound_vibration_settings"), onClick=function() showSoundVibSettingsDialog() end, backgroundColor="#607D8B", textColor="#FFFFFF", layout_marginBottom="10dp"},
      {Button, text=getUIText("word_dictionary"), onClick=function() showWordDictionaryDialog() end, backgroundColor="#607D8B", textColor="#FFFFFF", layout_marginBottom="10dp"},
      {Button, text=getUIText("about"), onClick=function() showAboutDialog() end, backgroundColor="#607D8B", textColor="#FFFFFF", layout_marginBottom="10dp"},
      {Button, text=getUIText("contact_us"), onClick=function() showContactDialog() end, backgroundColor="#607D8B", textColor="#FFFFFF", layout_marginBottom="20dp"},
      {Button, text=getUIText("close"), backgroundColor="#F44336", textColor="#FFFFFF", onClick=function() moreOptionsDlg.dismiss() end}
    }
  }
  moreOptionsDlg.setView(loadlayout(layout)).show()
end

function showApiDialog()
  local layout = {
    ScrollView, layout_width="fill",
    {LinearLayout, orientation="vertical", padding="15dp",
      {TextView, text=getUIText("manage_api_title"), textSize="20sp", textColor="#2196F3", layout_marginBottom="15dp"},
      {TextView, text=getUIText("openrouter_key")}, {EditText, id="or_et", text=orKey},
      {Button, text=getUIText("get_openrouter_key"), onClick=function() openUrl("https://openrouter.ai/keys") end, backgroundColor="#607D8B", textColor="#FFFFFF", layout_marginBottom="10dp"},
      {TextView, text=getUIText("gemini_key")}, {EditText, id="gem_et", text=geminiKey},
      {Button, text=getUIText("get_gemini_key"), onClick=function() openUrl("https://aistudio.google.com/app/apikey") end, backgroundColor="#607D8B", textColor="#FFFFFF", layout_marginBottom="10dp"},
      {TextView, text=getUIText("groq_key")}, {EditText, id="groq_et", text=groqKey},
      {Button, text=getUIText("get_groq_key"), onClick=function() openUrl("https://console.groq.com/keys") end, backgroundColor="#607D8B", textColor="#FFFFFF", layout_marginBottom="10dp"},
      {TextView, text=getUIText("deepgram_key")}, {EditText, id="dg_et", text=deepgramKey},
      {Button, text=getUIText("get_deepgram_key"), onClick=function() openUrl("https://console.deepgram.com/") end, backgroundColor="#607D8B", textColor="#FFFFFF", layout_marginBottom="10dp"},
      {Button, id="save_api_btn", text=getUIText("save_keys"), backgroundColor="#2196F3", textColor="#FFFFFF"}
    }
  }
  local view = loadlayout(layout)
  local dlg = LuaDialog(context).setView(view).show()
  save_api_btn.onClick = function()
    editor.putString("or_key", tostring(or_et.text)).putString("gemini_key", tostring(gem_et.text)).putString("groq_key", tostring(groq_et.text)).putString("dg_key", tostring(dg_et.text)).commit()
    orKey = tostring(or_et.text); geminiKey = tostring(gem_et.text); groqKey = tostring(groq_et.text); deepgramKey = tostring(dg_et.text)
    dlg.dismiss()
  end
end

function showEmojiSettingsDialog()
  local qtyList = {"Low", "Medium", "High"}
  local layout = {
    LinearLayout, orientation="vertical", padding="20dp",
    {TextView, text=getUIText("emoji_settings_title"), textSize="20sp", textColor="#2196F3", layout_marginBottom="15dp", gravity="center"},
    {CheckBox, id="sub_emoji_chk", text=getUIText("enable_smart_emojis"), checked=emojiEnabled, layout_marginBottom="15dp"},
    {TextView, text=getUIText("emoji_quantity"), layout_marginBottom="5dp"},
    {Spinner, id="sub_emoji_qty_sp", layout_marginBottom="20dp"},
    {Button, id="sub_emoji_save_btn", text=getUIText("save_close"), backgroundColor="#4CAF50", textColor="#FFFFFF"}
  }
  local view = loadlayout(layout)
  local dlg = LuaDialog(context).setView(view).show()
  sub_emoji_qty_sp.setAdapter(ArrayAdapter(context, android.R.layout.simple_spinner_item, qtyList))
  for i,v in ipairs(qtyList) do if v == emojiQty then sub_emoji_qty_sp.setSelection(i-1) end end
  sub_emoji_save_btn.onClick = function()
    emojiEnabled = sub_emoji_chk.isChecked()
    emojiQty = qtyList[sub_emoji_qty_sp.getSelectedItemPosition() + 1]
    dlg.dismiss()
  end
end

function showSoundVibSettingsDialog()
  local sList = {getUIText("default_beep"), getUIText("soft_click"), getUIText("sharp_pop")}
  local dlg = LuaDialog(context)
  local layout = {
    LinearLayout, orientation="vertical", padding="20dp",
    {TextView, text=getUIText("sound_vibration_title"), textSize="20sp", textColor="#2196F3", layout_marginBottom="15dp", gravity="center"},
    {CheckBox, id="sub_vib_chk", text=getUIText("enable_vibration"), checked=vibrationEnabled, layout_marginBottom="15dp"},
    {CheckBox, id="sub_sound_chk", text=getUIText("enable_typing_sound"), checked=soundEnabled, layout_marginBottom="15dp"},
    {TextView, text=getUIText("typing_sound_type"), layout_marginBottom="5dp"},
    {Spinner, id="sub_sound_sp", layout_marginBottom="20dp"},
    {Button, id="sub_sv_save_btn", text=getUIText("save_close"), backgroundColor="#4CAF50", textColor="#FFFFFF"}
  }
  dlg.setView(loadlayout(layout)).show()
  sub_sound_sp.setAdapter(ArrayAdapter(context, android.R.layout.simple_spinner_item, sList))
  local soundTypeText = getUIText(soundType:lower():gsub(" ", "_"))
  for i,v in ipairs(sList) do 
    if v == soundType or v == soundTypeText then 
      sub_sound_sp.setSelection(i-1) 
      break
    end
  end
  sub_sv_save_btn.onClick = function()
    vibrationEnabled = sub_vib_chk.isChecked()
    soundEnabled = sub_sound_chk.isChecked()
    local selectedSound = sList[sub_sound_sp.getSelectedItemPosition() + 1]
    if selectedSound == getUIText("default_beep") then soundType = "Default Beep"
    elseif selectedSound == getUIText("soft_click") then soundType = "Soft Click"
    elseif selectedSound == getUIText("sharp_pop") then soundType = "Sharp Pop"
    end
    dlg.dismiss()
  end
end

function showSettings()
  local typingModes = {"Auto Detect Script", "Pure Language Mode", "A.I. Writer Mode"}
  
  local layout = {
    ScrollView, layout_width="fill",
    {LinearLayout, orientation="vertical", padding="20dp",
      {TextView, text="Extreme AI Voice Typer v2.6", textSize="22sp", gravity="center", textColor="#2196F3"},
      {TextView, text="Developer: Anurag Anant", textSize="14sp", gravity="center", textColor="#757575", layout_marginBottom="20dp"},
      
      {TextView, text=getUIText("select_typing_mode"), textSize="16sp", textColor="#2196F3", layout_marginBottom="5dp"},
      {Spinner, id="typing_mode_sp", layout_marginBottom="20dp"},
      
      {Button, id="ai_settings_btn", text=getUIText("ai_settings"), backgroundColor="#2196F3", textColor="#FFFFFF", layout_marginBottom="15dp"},
      
      {View, layout_height="1dp", backgroundColor="#CCCCCC", layout_marginTop="5dp", layout_marginBottom="15dp"},
      
      {TextView, text=getUIText("source_language"), layout_marginBottom="5dp"},
      {Button, id="src_btn", text=selectedLanguage, backgroundColor="#607D8B", textColor="#FFFFFF", layout_marginBottom="10dp"},
      
      {LinearLayout, orientation="horizontal", layout_marginTop="10dp", gravity="center_vertical",
        {CheckBox, id="trans_chk", text=getUIText("enable_translation"), checked=enableTranslation, layout_weight=1},
        {Button, id="swap_btn", text=getUIText("swap"), backgroundColor="#607D8B", textColor="#FFFFFF"}},
      {TextView, text=getUIText("target_language"), layout_marginTop="10dp", layout_marginBottom="5dp"},
      {Button, id="tgt_btn", text=targetLanguage, backgroundColor="#607D8B", textColor="#FFFFFF", layout_marginBottom="15dp"},
      
      {View, layout_height="1dp", backgroundColor="#CCCCCC", layout_marginTop="15dp", layout_marginBottom="15dp"},
      
      {Button, id="emoji_settings_btn", text=getUIText("emoji_settings"), backgroundColor="#607D8B", textColor="#FFFFFF", layout_marginTop="10dp"},
      
      {Button, id="more_options_btn", text=getUIText("more_options"), backgroundColor="#9E9E9E", textColor="#FFFFFF", layout_marginTop="10dp"},
      
      {View, layout_height="1dp", backgroundColor="#CCCCCC", layout_marginTop="20dp", layout_marginBottom="15dp"},
      {Button, id="save_main_btn", text=getUIText("save_close"), backgroundColor="#4CAF50", textColor="#FFFFFF"}
    }
  }
  
  triggerVibration("settings")
  local view = loadlayout(layout)
  settingsDlg = LuaDialog(context).setView(view)
  settingsDlg.show()
  
  Thread(luajava.bindClass("java.lang.Runnable"){
      run = function()
          Thread.sleep(3000)
          checkForUpdates(false)
      end
  }).start()
  
  typing_mode_sp.setAdapter(ArrayAdapter(context, android.R.layout.simple_spinner_item, typingModes))
  for i,v in ipairs(typingModes) do if v == typingMode then typing_mode_sp.setSelection(i-1) end end
  
  ai_settings_btn.onClick = function() showAISettingsDialog() end
  emoji_settings_btn.onClick = function() showEmojiSettingsDialog() end
  more_options_btn.onClick = function() showMoreOptionsDialog() end
  
  src_btn.onClick = function() showLanguageSelectDialog(false, src_btn) end
  tgt_btn.onClick = function() showLanguageSelectDialog(true, tgt_btn) end
  
  swap_btn.onClick = function()
    local temp = selectedLanguage
    selectedLanguage = targetLanguage
    targetLanguage = temp
    src_btn.setText(selectedLanguage)
    tgt_btn.setText(targetLanguage)
  end

  save_main_btn.onClick = function()
    typingMode = typingModes[typing_mode_sp.getSelectedItemPosition() + 1]
    pureMode = (typingMode == "Pure Language Mode")
    autoDetect = (typingMode == "Auto Detect Script")
    enableTranslation = trans_chk.isChecked()
    
    editor.putString("typing_mode", typingMode).putBoolean("auto_detect", autoDetect).putBoolean("pure_mode", pureMode).putString("lang", selectedLanguage).putString("target_lang", targetLanguage).putBoolean("emoji_enabled", emojiEnabled).putBoolean("vibration_enabled", vibrationEnabled).putBoolean("sound_enabled", soundEnabled).putString("sound_type", soundType).putBoolean("copy_clipboard", copyToClipboard).putString("emoji_qty", emojiQty).putString("end_action", endAction).putBoolean("enable_trans", enableTranslation).putBoolean("offline_mode", offlineMode).commit()
    settingsDlg.dismiss() 
  end
end

function insertText(spoken)
  if not spoken or spoken == "" then return end

  announce(getUIText("processing"))
  
  local function executeAIFinalFormat(textToProcess, isTranslatedFlag)
    processWithAI(textToProcess, isTranslatedFlag, function(aiText)
      local finalText = finalGuard(aiText)
      finalText = applyDictionaryReplacement(finalText)
      local node = service.getEditText()
      if node then
        local suffix = (endAction == "New Line" and "\n" or (endAction == "Space" and " " or (endAction == "Space + New Line" and " \n" or "")))
        pcall(function() service.insert(node, finalText .. suffix)
          if copyToClipboard then 
            local clip = ClipData.newPlainText("AI Voice Typer", finalText)
            context.getSystemService(Context.CLIPBOARD_SERVICE).setPrimaryClip(clip) end
          triggerVibration("typing"); triggerSound(); announce(finalText) end)
      end 
    end)
  end

  if offlineMode then
    local finalText = finalGuard(spoken)
    processOffline(finalText, function(resText)
      resText = applyDictionaryReplacement(resText)
      local node = service.getEditText()
      if node then
        local suffix = (endAction == "New Line" and "\n" or (endAction == "Space" and " " or (endAction == "Space + New Line" and " \n" or "")))
        pcall(function() service.insert(node, resText .. suffix)
          if copyToClipboard then 
            local clip = ClipData.newPlainText("AI Voice Typer", resText)
            context.getSystemService(Context.CLIPBOARD_SERVICE).setPrimaryClip(clip) end
          triggerVibration("typing"); triggerSound(); announce(resText) end)
      end end)
    return 
  end

  if enableTranslation then
    local targetCode = getLangCode(targetLanguage)
    targetCode = string.sub(targetCode, 1, 2)
    if targetLanguage == "Chinese (Mandarin)" then targetCode = "zh-CN" end
    
    local url = "https://translate.google.com/m?sl=auto&hl=" .. targetCode .. "&q=" .. Uri.encode(spoken)
    
    pcall(function()
        local Http = luajava.bindClass("com.androlua.Http")
        if not Http then Http = import("com.androlua.Http") end
        if Http then
            Http.get(url, function(status, result)
                if status == 200 and result then
                    local translatedText = result:match('<div class="result%-container">([^<]+)</div>')
                    if translatedText then
                        translatedText = translatedText:gsub("&#39;", "'"):gsub("&quot;", '"'):gsub("&amp;", "&")
                        executeAIFinalFormat(translatedText, true)
                    else
                        executeAIFinalFormat(spoken, false)
                    end
                else
                    executeAIFinalFormat(spoken, false)
                end
            end)
        else
            executeAIFinalFormat(spoken, false)
        end
    end)
  else
    executeAIFinalFormat(spoken, false)
  end
end

function startListening()
  local intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
  intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
  
  local langCode = getLangCode(selectedLanguage)
  intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, langCode)
  
  local sr = SpeechRecognizer.createSpeechRecognizer(context)
  sr.setRecognitionListener({
    onResults = function(res)
      local matches = res.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
      if matches and matches.size() > 0 then insertText(matches.get(0)) end
      sr.destroy() end,
    onError = function() sr.destroy() end})
  sr.startListening(intent)
end

function main() if service and service.getEditText() then startListening() else showSettings() end end
task(300, main)
