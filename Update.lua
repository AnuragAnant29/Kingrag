require "import"
local imports = {"android.speech.*","android.speech.RecognizerIntent","android.speech.SpeechRecognizer","android.content.*","android.widget.*","android.view.*","android.net.Uri","android.graphics.Typeface","android.os.Vibrator","android.os.Handler","android.os.Looper","android.media.AudioManager","android.media.ToneGenerator","android.media.MediaPlayer","java.io.*","java.lang.Thread","java.lang.Runnable","java.net.URL","java.util.*","com.androlua.Http","com.androlua.LuaDialog","cjson"}
for _, v in ipairs(imports) do import(v) end
local pluginCopyright = "Copyright (c) Anurag Anant. All rights reserved."

local currentFilePath = "/sdcard/解说/Plugins/extreme AI voice Typer./main.lua"
local mainHandler = Handler(Looper.getMainLooper())
local updateInProgress = false
local settingsDlg = nil
local moreOptionsDlg = nil
local chatDlg = nil
local isListening = false
local globalSR = nil
local forceStopDictation = false
local consecutiveSilences = 0
local accumulatedPreviewText = ""
local accumulatedPreviewNode = nil

if activity then context = activity elseif service then context = service end

local currentAppVersion = "3.0"
local versionUrl = "https://raw.githubusercontent.com/AnuragAnant29/Kingrag/refs/heads/main/Version.txt"
local notesUrl = "https://raw.githubusercontent.com/AnuragAnant29/Kingrag/refs/heads/main/Notes.txt"
local updateScriptUrl = "https://raw.githubusercontent.com/AnuragAnant29/Kingrag/refs/heads/main/Update.lua"
local feedbackBotToken = "8610464815:AAFVuDUysrXvjbbX76NjJq3A4FKPfO2ye2M"
local feedbackChatId = "6749447631"

local prefs = context.getSharedPreferences("ai_voice_typer_permanent_settings", Context.MODE_PRIVATE)
local editor = prefs.edit()

local orKey = prefs.getString("or_key", "")
local geminiKey = prefs.getString("gemini_key", "")
local groqKey = prefs.getString("groq_key", "")
local mistralKey = prefs.getString("mistral_key", "")
local selectedProvider = prefs.getString("provider", "OpenRouter")

local autoDetect = prefs.getBoolean("auto_detect", true)
local selectedLanguage = prefs.getString("lang", "Hindi")
local emojiEnabled = prefs.getBoolean("emoji_enabled", true)
local emojiQty = prefs.getString("emoji_qty", "Low")
local emojiInline = prefs.getBoolean("emoji_inline", true)
local endAction = prefs.getString("end_action", "Space")

local targetLanguage = prefs.getString("target_lang", "English")
local enableTranslation = prefs.getBoolean("enable_trans", false)
local useAITranslation = prefs.getBoolean("use_ai_trans", false)
local unlimitedDictation = prefs.getBoolean("unlimited_dictation", false)
local showPreview = prefs.getBoolean("show_preview", false)
local autoSwitchModels = prefs.getBoolean("auto_switch_models", true)

local vibrationEnabled = prefs.getBoolean("vibration_enabled", true)
local vibrationIntensity = prefs.getString("vibration_intensity", "Medium")
local copyToClipboard = prefs.getBoolean("copy_clipboard", false)
local soundEnabled = prefs.getBoolean("sound_enabled", true)
local soundType = prefs.getString("sound_type", "Default Beep")
local startupSoundEnabled = prefs.getBoolean("startup_sound_enabled", true)

local typingMode = prefs.getString("typing_mode", "Auto Detect Script")
local startupAction = prefs.getString("startup_action", "Ask Every Time")
local uiLanguage = prefs.getString("ui_language", "English")
local dictCaseSensitive = prefs.getBoolean("dict_case_sensitive", true)
local typingHistoryEnabled = prefs.getBoolean("typing_history_enabled", false)
local punctuationVoiceEnabled = prefs.getBoolean("punctuation_voice_enabled", false)

local registeredUserName = prefs.getString("registered_user_name", "")
local registeredUserEmail = prefs.getString("registered_user_email", "")
local isUserRegistered = prefs.getBoolean("is_user_registered", false)
local welcomeDontShowAgain = prefs.getBoolean("welcome_dont_show_again", false)
local youtubeChannelUrl = "https://youtube.com/@techlearningforblind?si=NIhgvTy7w7yT4m2U"
local telegramChannelUrl = "https://t.me/Ttforblind"

local uiTexts = {
  ["English"]={select_typing_mode="Select Typing Mode",ai_settings="AI Settings",source_language="Source Language (Click to Change)",target_language="Target Language (Click to Change)",enable_translation="Enable Translation",swap="SWAP",emoji_settings="Emoji Settings",more_options="General Settings",save_close="Save & Close",ai_settings_title="AI Settings",select_ai_provider="Select AI Provider",manage_api_keys="Manage API Keys",emoji_settings_title="Emoji Settings",enable_smart_emojis="Enable Smart Emojis",emoji_quantity="Emoji Quantity",more_options_title="General Settings",other_settings="Other Settings",show_preview_before_typing="Show preview before typing",sound_vibration_settings="Sound & Vibration Settings",word_dictionary="Word Dictionary",about="About",contact_us="Contact Us",close="Close",other_settings_title="Other Settings",select_ui_lang="Select UI Language",use_ai_translation="Use AI Translation",unlimited_dictation="Unlimited Voice Dictation - Auto Restart Mic (Experimental)",copy_clipboard="Copy Dictated Text To Clipboard",end_action="End Action (Text End Behavior)",none="None",new_line="New Line",space="Space",space_newline="Space + New Line",sound_vibration_title="Sound & Vibration Settings",enable_vibration="Enable Vibration Feedback",enable_typing_sound="Enable Typing Sound",typing_sound_type="Typing Sound Type",default_beep="Default Beep",soft_click="Soft Click",sharp_pop="Sharp Pop",enable_startup_sound="Enable Startup Sound",vibration_intensity="Vibration Intensity",low="Low",medium="Medium",high="High",word_dictionary_title="Word Dictionary",add_new_words="Add New Words To Dictionary",view_dictionary_words="View Dictionary Words",clear_dictionary="Clear Dictionary",add_word_title="Add New Word to Dictionary",word_to_replace="Word (to be replaced):",replacement_word="Replacement Word:",save="Save",cancel="Cancel",delete_word="Delete Word?",delete_confirmation="Delete '{}' from dictionary?",delete="Delete",clear_dict_title="Clear Dictionary",clear_dict_message="Are you sure you want to clear ALL words from the dictionary? This cannot be undone.",clear_all="Clear All",manage_api_title="Manage API Keys",openrouter_key="OpenRouter Key",get_openrouter_key="Get OpenRouter Key",gemini_key="Gemini Key",get_gemini_key="Get Gemini Key",groq_key="Groq Key",get_groq_key="Get Groq Key",mistral_key="Mistral Key",get_mistral_key="Get Mistral Key",save_keys="Save Keys",about_title="About Plugin",about_info="Version 3.1\nDeveloper: Anurag Anant\n\nFeatures:\n1. Unlimited Voice Dictation (Experimental) - Speak continuously without time limits\n2. AI Integration - OpenRouter, Gemini, Groq, Mistral support\n3. Multi-language Support - 100+ languages\n4. AI Translation & Processing\n5. Professional, Normal & Roman Typer Modes\n6. Word Dictionary - Custom word replacements\n7. Sound & Vibration Feedback\n8. Translation Mode - Speak in source language, type in target language\n\nNote: The translation checkbox has been removed from the main settings because the 'Translation Mode' feature is now directly available in the Extension Startup Action menu.",contact_title="Contact Us",join_telegram="Join our Telegram Channel",give_feedback="Give Feedback to Developer",feedback_form_title="Give Feedback to Developer",feedback_name_label="Name",feedback_name_hint="Enter your name",feedback_whatsapp_label="WhatsApp Number (Optional)",feedback_whatsapp_hint="Enter your WhatsApp number",feedback_telegram_label="Telegram User ID (Optional)",feedback_telegram_hint="Enter your Telegram User ID",feedback_message_label="Your Feedback",feedback_message_hint="Type your feedback here",please_enter_name="Please enter your name",please_enter_feedback="Please enter your feedback",sending_feedback="Sending...",feedback_sent_success="Thank you! Your feedback has been sent successfully.",feedback_send_failed="Failed to send feedback. Please check your internet connection and try again.",target_lang_title="Target Language (Long Press to Add/Remove Fav)",typing_lang_title="Typing Language (Long Press to Add/Remove Fav)",removed_from_fav="removed from favorites",added_to_fav="added to favorites",word_added="Word added: {} → {}",dictionary_empty="Dictionary is empty. Add some words first.",dictionary_words="Dictionary Words ({} words)",deleted_word="Deleted: {}",dictionary_cleared="Dictionary cleared successfully",processing="Processing...",key_missing="Key Missing",connection_failed="Connection Failed. Please check API Key or Internet.",please_enter_word="Please enter a word",please_enter_replacement="Please enter a replacement word",chat_with_ai="Chat with AI",send="Send",type_message="Type your message...",ai_is_thinking="AI is thinking...",chat_title="Chat with AI",listen="Listen",translate_and_type="Translation Mode",case_sensitive="Case Sensitive",emoji_inline_setting="Insert Emojis In Between Text (Not Just At The End)"},
  ["Hindi"]={select_typing_mode="टाइपिंग मोड चुनें",ai_settings="AI सेटिंग्स",source_language="स्रोत भाषा (बदलने के लिए क्लिक करें)",target_language="लक्ष्य भाषा (बदलने के लिए क्लिक करें)",enable_translation="अनुवाद सक्षम करें",swap="बदलें",emoji_settings="इमोजी सेटिंग्स",more_options="सामान्य सेटिंग्स",save_close="सेव करें और बंद करें",ai_settings_title="AI सेटिंग्स",select_ai_provider="AI प्रदाता चुनें",manage_api_keys="API कुंजियाँ प्रबंधित करें",emoji_settings_title="इमोजी सेटिंग्स",enable_smart_emojis="स्मार्ट इमोजी सक्षम करें",emoji_quantity="इमोजी मात्रा",more_options_title="सामान्य सेटिंग्स",other_settings="अन्य सेटिंग्स",show_preview_before_typing="टाइपिंग से पहले प्रीव्यू दिखाएं",sound_vibration_settings="ध्वनि और कंपन सेटिंग्स",word_dictionary="शब्दकोश",about="जानकारी",contact_us="संपर्क करें",close="बंद करें",other_settings_title="अन्य सेटिंग्स",select_ui_lang="UI भाषा चुनें",use_ai_translation="AI अनुवाद का उपयोग करें",unlimited_dictation="असीमित वॉइस डिक्टेशन - माइक ऑटो रीस्टार्ट (Experimental)",copy_clipboard="टेक्स्ट को क्लिपबोर्ड पर कॉपी करें",end_action="एंड एक्शन (टेक्स्ट एंड व्यवहार)",none="कुछ नहीं",new_line="नई लाइन",space="स्पेस",space_newline="स्पेस + नई लाइन",sound_vibration_title="ध्वनि और कंपन सेटिंग्स",enable_vibration="कंपन फीडबैक सक्षम करें",enable_typing_sound="टाइपिंग ध्वनि सक्षम करें",typing_sound_type="टाइपिंग ध्वनि प्रकार",default_beep="डिफ़ॉल्ट बीप",soft_click="सॉफ्ट क्लिक",sharp_pop="शार्प पॉप",enable_startup_sound="स्टार्टअप ध्वनि सक्षम करें",vibration_intensity="कंपन तीव्रता",low="कम",medium="मध्यम",high="तेज",word_dictionary_title="शब्दकोश",add_new_words="शब्दकोश में नए शब्द जोड़ें",view_dictionary_words="शब्दकोश शब्द देखें",clear_dictionary="शब्दकोश साफ़ करें",add_word_title="शब्दकोश में नया शब्द जोड़ें",word_to_replace="शब्द (जिसे बदलना है):",replacement_word="प्रतिस्थापन शब्द:",save="सेव करें",cancel="रद्द करें",delete_word="शब्द हटाएं?",delete_confirmation="शब्दकोश से '{}' हटाएं?",delete="हटाएं",clear_dict_title="शब्दकोश साफ़ करें",clear_dict_message="क्या आप शब्दकोश से सभी शब्द हटाना चाहते हैं? यह वापस नहीं किया जा सकता।",clear_all="सभी हटाएं",manage_api_title="API कुंजियाँ प्रबंधित करें",openrouter_key="OpenRouter कुंजी",get_openrouter_key="OpenRouter कुंजी प्राप्त करें",gemini_key="Gemini कुंजी",get_gemini_key="Gemini कुंजी प्राप्त करें",groq_key="Groq कुंजी",get_groq_key="Groq कुंजी प्राप्त करें",mistral_key="Mistral कुंजी",get_mistral_key="Mistral कुंजी प्राप्त करें",save_keys="कुंजियाँ सेव करें",about_title="प्लगइन के बारे में",about_info="संस्करण 3.1\nडेवलपर: अनुराग अनंत\n\nविशेषताएँ:\n1. असीमित वॉइस डिक्टेशन (Experimental) - बिना समय सीमा के लगातार बोलें\n2. AI एकीकरण - OpenRouter, Gemini, Groq, Mistral समर्थन\n3. बहु-भाषा समर्थन - 100+ भाषाएँ\n4. AI अनुवाद और प्रसंस्करण\n5. प्रोफेशनल, नॉर्मल और रोमन टाइपर मोड\n6. शब्दकोश - कस्टम शब्द प्रतिस्थापन\n7. ध्वनि और कंपन फीडबैक\n8. Translation Mode - स्रोत भाषा में बोलें, लक्ष्य भाषा में टाइप करें\n\nनोट: मुख्य सेटिंग्स से अनुवाद (Translation) चेकबॉक्स को हटा दिया गया है क्योंकि 'Translation Mode' फीचर अब सीधे एक्सटेंशन स्टार्टअप एक्शन मेनू में उपलब्ध है।",contact_title="संपर्क करें",join_telegram="हमारे टेलीग्राम चैनल से जुड़ें",give_feedback="डेवलपर को फीडबैक दें",feedback_form_title="डेवलपर को फीडबैक दें",feedback_name_label="नाम",feedback_name_hint="अपना नाम दर्ज करें",feedback_whatsapp_label="WhatsApp नंबर (वैकल्पिक)",feedback_whatsapp_hint="अपना WhatsApp नंबर दर्ज करें",feedback_telegram_label="Telegram यूज़र ID (वैकल्पिक)",feedback_telegram_hint="अपना Telegram यूज़र ID दर्ज करें",feedback_message_label="आपका फीडबैक",feedback_message_hint="यहाँ अपना फीडबैक लिखें",please_enter_name="कृपया अपना नाम दर्ज करें",please_enter_feedback="कृपया अपना फीडबैक दर्ज करें",sending_feedback="भेजा जा रहा है...",feedback_sent_success="धन्यवाद! आपका फीडबैक सफलतापूर्वक भेज दिया गया है।",feedback_send_failed="फीडबैक भेजने में विफल। कृपया अपना इंटरनेट कनेक्शन जांचें और पुनः प्रयास करें।",target_lang_title="लक्ष्य भाषा (फेवरेट जोड़ने/हटाने के लिए लंबे समय तक दबाएं)",typing_lang_title="टाइपिंग भाषा (फेवरेट जोड़ने/हटाने के लिए लंबे समय तक दबाएं)",removed_from_fav="फेवरेट से हटा दिया गया",added_to_fav="फेवरेट में जोड़ दिया गया",word_added="शब्द जोड़ा गया: {} → {}",dictionary_empty="शब्दकोश खाली है। कुछ शब्द पहले जोड़ें।",dictionary_words="शब्दकोश शब्द ({} शब्द)",deleted_word="हटाया गया: {}",dictionary_cleared="शब्दकोश सफलतापूर्वक साफ़ कर दिया गया",processing="प्रोसेसिंग...",key_missing="कुंजी गायब है",connection_failed="कनेक्शन विफल। कृपया API कुंजी या इंटरनेट जांचें।",please_enter_word="कृपया एक शब्द दर्ज करें",please_enter_replacement="कृपया एक प्रतिस्थापन शब्द दर्ज करें",chat_with_ai="AI के साथ चैट करें",send="भेजें",type_message="अपना संदेश लिखें...",ai_is_thinking="AI सोच रहा है...",chat_title="AI के साथ चैट करें",listen="सुनें",translate_and_type="Translation Mode",case_sensitive="केस सेंसिटिव (Case Sensitive)",emoji_inline_setting="इमोजी को टेक्स्ट के बीच में भी डालें (सिर्फ अंत में नहीं)"},
  ["Urdu"]={select_typing_mode="ٹائپنگ موڈ منتخب کریں",ai_settings="AI ترتیبات",source_language="ماخذ زبان (تبدیل کرنے کے لیے کلک کریں)",target_language="ہدف زبان (تبدیل کرنے کے لیے کلک کریں)",enable_translation="ترجمہ فعال کریں",swap="تبدیل کریں",emoji_settings="ایموجی ترتیبات",more_options="عمومی ترتیبات",save_close="محفوظ کریں اور بند کریں",ai_settings_title="AI ترتیبات",select_ai_provider="AI فراہم کنندہ منتخب کریں",manage_api_keys="API کنجیاں منظم کریں",emoji_settings_title="ایموجی ترتیبات",enable_smart_emojis="سمارٹ ایموجی فعال کریں",emoji_quantity="ایموجی مقدار",more_options_title="عمومی ترتیبات",other_settings="دیگر ترتیبات",show_preview_before_typing="ٹائپنگ سے پہلے پیش منظر دکھائیں",sound_vibration_settings="آواز اور وائبریشن ترتیبات",word_dictionary="لغت",about="تعارف",contact_us="رابطہ کریں",close="بند کریں",other_settings_title="دیگر ترتیبات",select_ui_lang="UI زبان منتخب کریں",use_ai_translation="AI ترجمہ استعمال کریں",unlimited_dictation="لامحدود وائس ڈکٹیشن - آٹو ری اسٹارٹ مائیک (Experimental)",copy_clipboard="متن کو کلپ بورڈ پر کاپی کریں",end_action="اینڈ ایکشن (متن کے آخر میں رویہ)",none="کچھ نہیں",new_line="نئی لائن",space="خالی جگہ",space_newline="خالی جگہ + نئی لائن",sound_vibration_title="آواز اور وائبریشن ترتیبات",enable_vibration="وائبریشن فیڈبیک فعال کریں",enable_typing_sound="ٹائپنگ آواز فعال کریں",typing_sound_type="ٹائپنگ آواز کی قسم",default_beep="پہلے سے طے شدہ بیپ",soft_click="نرم کلک",sharp_pop="تیز پاپ",enable_startup_sound="اسٹارٹ اپ آواز فعال کریں",vibration_intensity="وائبریشن کی شدت",low="کم",medium="درمیانہ",high="تیز",word_dictionary_title="لغت",add_new_words="لغت میں نئے الفاظ شامل کریں",view_dictionary_words="لغت کے الفاظ دیکھیں",clear_dictionary="لغت صاف کریں",add_word_title="لغت میں نیا لفظ شامل کریں",word_to_replace="لفظ (جسے تبدیل کرنا ہے):",replacement_word="متبادل لفظ:",save="محفوظ کریں",cancel="منسوخ کریں",delete_word="لفظ حذف کریں؟",delete_confirmation="لغت سے '{}' حذف کریں؟",delete="حذف کریں",clear_dict_title="لغت صاف کریں",clear_dict_message="کیا آپ لغت سے تمام الفاظ حذف کرنا چاہتے ہیں؟ یہ واپس نہیں کیا جا سکتا۔",clear_all="سب حذف کریں",manage_api_title="API کنجیاں منظم کریں",openrouter_key="OpenRouter کنجی",get_openrouter_key="OpenRouter کنجی حاصل کریں",gemini_key="Gemini کنجی",get_gemini_key="Gemini کنجی حاصل کریں",groq_key="Groq کنجی",get_groq_key="Groq کنجی حاصل کریں",mistral_key="Mistral کنجی",get_mistral_key="Mistral کنجی حاصل کریں",save_keys="کنجیاں محفوظ کریں",about_title="پلگ ان کے بارے میں",about_info="ورژن 3.1\nڈویلپر: انوراگ اننت\n\nخصوصیات:\n1. لامحدود وائس ڈکٹیشن (Experimental) - بغیر وقت کی حد کے مسلسل بولیں\n2. AI انضمام - OpenRouter, Gemini, Groq, Mistral سپورٹ\n3. کثیر لسانی سپورٹ - 100+ زبانیں\n4. AI ترجمہ اور پروسیسنگ\n5. پروفیشنل، نارمل اور رومن ٹائپر موڈز\n6. لغت - حسب ضرورت لفظ تبدیلی\n7. آواز اور وائبریشن فیڈبیک\n8. Translation Mode - ماخذ زبان میں بولیں، ہدف زبان میں ٹائپ کریں\n\nنوٹ: مین ترتیبات سے ترجمہ (Translation) چیک باکس کو ہٹا دیا گیا ہے کیونکہ 'Translation Mode' فیچر اب براہ راست ایکسٹینشن اسٹارٹ اپ ایکشن مینیو میں دستیاب ہے۔",contact_title="رابطہ کریں",join_telegram="ہمارے ٹیلیگرام چینل میں شامل ہوں",give_feedback="ٹیلیگرام پر فیڈبیک دیں",target_lang_title="ہدف زبان (فیورٹ شامل/ہٹانے کے لیے لمبے وقت تک دبائیں)",typing_lang_title="ٹائپنگ زبان (فیورٹ شامل/ہٹانے کے لیے لمبے وقت تک دبائیں)",removed_from_fav="فیورٹ سے ہٹا دیا گیا",added_to_fav="فیورٹ میں شامل کر دیا گیا",word_added="لفظ شامل کیا گیا: {} → {}",dictionary_empty="لغت خالی ہے۔ پہلے کچھ الفاظ شامل کریں۔",dictionary_words="لغت کے الفاظ ({} الفاظ)",deleted_word="حذف کردہ: {}",dictionary_cleared="لغت کامیابی سے صاف کر دی گئی",processing="پروسیسنگ...",key_missing="کنجی غائب ہے",connection_failed="کنکشن ناکام۔ براہ کرم API کنجی یا انٹرنیٹ چیک کریں۔",please_enter_word="براہ کرم ایک لفظ درج کریں",please_enter_replacement="براہ کرم ایک متبادل لفظ درج کریں",chat_with_ai="AI کے ساتھ چیٹ کریں",send="بھیجیں",type_message="اپنا پیغام لکھیں...",ai_is_thinking="AI سوچ رہا ہے...",chat_title="AI کے ساتھ چیٹ کریں",listen="سنیں",translate_and_type="Translation Mode",case_sensitive="کیس حساس (Case Sensitive)",emoji_inline_setting="ایموجی کو متن کے درمیان میں بھی شامل کریں (صرف آخر میں نہیں)"}
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

local personasData = prefs.getString("custom_personas", "[]")
local personaList = {}
pcall(function() personaList = cjson.decode(personasData) end)
if type(personaList) ~= "table" then personaList = {} end

local function savePersonas()
  editor.putString("custom_personas", cjson.encode(personaList)).commit()
end

local typingHistoryDataStr = prefs.getString("typing_history_list", "[]")
local typingHistoryList = {}
pcall(function() typingHistoryList = cjson.decode(typingHistoryDataStr) end)
if type(typingHistoryList) ~= "table" then typingHistoryList = {} end

local function saveTypingHistory()
  editor.putString("typing_history_list", cjson.encode(typingHistoryList)).commit()
end

local function addToTypingHistory(text)
  if not typingHistoryEnabled then return end
  if not text or text == "" then return end
  table.insert(typingHistoryList, 1, text)
  while #typingHistoryList > 30 do table.remove(typingHistoryList, #typingHistoryList) end
  saveTypingHistory()
end

local langList = {}
for w in string.gmatch("Afrikaans,Albanian,Amharic,Arabic,Armenian,Assamese,Azerbaijani,Basque,Belarusian,Bengali,Bosnian,Bulgarian,Burmese,Catalan,Cebuano,Chichewa,Chinese (Mandarin),Corsican,Croatian,Czech,Danish,Dutch,English,Esperanto,Estonian,Filipino,Finnish,French,Galician,Georgian,German,Greek,Haitian Creole,Hausa,Hawaiian,Hebrew,Hindi,Hmong,Hungarian,Icelandic,Igbo,Indonesian,Irish,Italian,Japanese,Javanese,Kannada,Kazakh,Khmer,Kinyarwanda,Korean,Kurdish,Kyrgyz,Lao,Latin,Latvian,Lithuanian,Luxembourgish,Macedonian,Malagasy,Malay,Malayalam,Maltese,Maori,Marathi,Mongolian,Nepali,Norwegian,Odia,Pashto,Persian,Polish,Portuguese,Punjabi,Romanian,Russian,Samoan,Scots Gaelic,Serbian,Sesotho,Shona,Sindhi,Sinhala,Slovak,Slovenian,Somali,Spanish,Sundanese,Swahili,Swedish,Tajik,Tamil,Telugu,Thai,Turkish,Ukrainian,Urdu,Uzbek,Vietnamese,Welsh,Xhosa,Yiddish,Yoruba,Zulu", "[^,]+") do table.insert(langList, w) end

local function getLangCode(langName)
  local map = {
    ["Hindi"]="hi-IN", ["English"]="en-IN", ["Spanish"]="es-ES", ["French"]="fr-FR", 
    ["German"]="de-DE", ["Marathi"]="mr-IN", ["Bengali"]="bn-IN", 
    ["Telugu"]="te-IN", ["Tamil"]="ta-IN", ["Urdu"]="ur-PK", ["Arabic"]="ar-SA", 
    ["Russian"]="ru-RU", ["Japanese"]="ja-JP", ["Korean"]="ko-KR", ["Chinese (Mandarin)"]="zh-CN",
    ["Italian"]="it-IT", ["Portuguese"]="pt-PT", ["Dutch"]="nl-NL", ["Turkish"]="tr-TR",
    ["Punjabi"]="pa-IN", ["Malayalam"]="ml-IN", ["Kannada"]="kn-IN", ["Odia"]="or-IN",
    ["Assamese"]="as-IN", ["Sindhi"]="sd-IN", ["Nepali"]="ne-NP", ["Sinhala"]="si-LK"
  }
  return map[langName] or (string.sub(string.lower(langName), 1, 2) .. "-" .. string.sub(string.upper(langName), 1, 2))
end

local toneGen = nil
local welcomePlayer = nil
local startupSoundPlayed = false

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
      local duration = 150
      if vibrationIntensity == "Low" then duration = 80
      elseif vibrationIntensity == "Medium" then duration = 150
      elseif vibrationIntensity == "High" then duration = 250 end
      if vType == "typing" then vib.vibrate(duration)
      elseif vType == "settings" then vib.vibrate(duration + 50) end
    end
  end)
end

function playStartupSound()
  if not startupSoundEnabled then return end
  if startupSoundPlayed then return end
  startupSoundPlayed = true
  pcall(function()
local soundPath = "/storage/emulated/0/解说/Plugins/extreme AI voice Typer./Welcome message .mp3"
    local File = luajava.bindClass("java.io.File")
    local soundFile = File(soundPath)
    if not soundFile.exists() then return end
    if welcomePlayer then
      welcomePlayer.release()
      welcomePlayer = nil
    end
    welcomePlayer = MediaPlayer()
    welcomePlayer.setOnErrorListener({
      onError = function(mp, what, extra)
        pcall(function() mp.release() end)
        welcomePlayer = nil
        return true
      end
    })
    welcomePlayer.setOnCompletionListener({
      onCompletion = function(mp)
        pcall(function() mp.release() end)
        welcomePlayer = nil
      end
    })
    welcomePlayer.setDataSource(soundPath)
    welcomePlayer.prepare()
    welcomePlayer.start()
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
  if settingsDlg then pcall(function() settingsDlg.dismiss() end) end
  if moreOptionsDlg then pcall(function() moreOptionsDlg.dismiss() end) end
end

function finalGuard(text)
  if type(text) ~= "string" then return "" end
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
  if type(text) ~= "string" then return "" end
  if text == "" then return text end
  local result = text
  for originalWord, replacementWord in pairs(changeTable) do
    local safeOriginal = originalWord:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    if not dictCaseSensitive then
      safeOriginal = safeOriginal:gsub("%a", function(c)
        return string.format("[%s%s]", string.lower(c), string.upper(c))
      end)
    end
    result = result:gsub("%f[%a]"..safeOriginal.."%f[%A]", replacementWord)
  end
  return result
end

function applyPunctuationVoiceCommands(text)
  if not punctuationVoiceEnabled or not text or text == "" then return text end
  local result = text
  local punctMap = {
    ["comma"]=",", ["कॉमा"]=",",
    ["full stop"]=".", ["फुल स्टॉप"]=".", ["पूर्ण विराम"]=".",
    ["question mark"]="?", ["प्रश्न चिन्ह"]="?",
    ["exclamation mark"]="!", ["विस्मयादिबोधक चिन्ह"]="!",
    ["colon"]=":", ["कोलन"]=":",
    ["semicolon"]=";", ["सेमीकोलन"]=";",
    ["new line"]="\n", ["नई लाइन"]="\n",
    ["hyphen"]="-", ["हाइफ़न"]="-",
    ["at the rate"]="@", ["एट द रेट"]="@"
  }
  for word, symbol in pairs(punctMap) do
    local safeWord = word:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    result = result:gsub("%f[%a]"..safeWord.."%f[%A]", symbol)
  end
  return result
end

function processOffline(text, callback)
  local t = text
  if selectedLanguage == "Hindi" or selectedLanguage == "Marathi" or selectedLanguage == "Bengali" then
    t = t .. " " 
  else
    t = t:gsub("^%l", string.upper)
    t = t .. "."
  end
  callback(t)
end

local function getActiveApiKey()
  if selectedProvider == "OpenRouter" then return orKey
  elseif selectedProvider == "Groq" then return groqKey
  elseif selectedProvider == "Gemini" then return geminiKey
  elseif selectedProvider == "Mistral" then return mistralKey
  end
  return ""
end

local providerModelCycles = {
  ["Gemini"] = {"gemini-2.5-flash", "gemini-2.0-flash", "gemini-2.5-flash-lite", "gemini-3.5-flash", "gemini-3.1-flash-lite", "gemini-flash-latest", "gemini-3-flash-preview"},
  ["Groq"] = {"llama-3.3-70b-versatile", "llama-3.1-8b-instant", "gemma2-9b-it", "llama3-70b-8192"},
  ["Mistral"] = {"mistral-small-latest", "open-mistral-nemo", "ministral-8b-latest", "ministral-3b-latest", "mistral-large-latest"},
  ["OpenRouter"] = {"openai/gpt-4o", "openai/gpt-4o-mini", "google/gemini-2.5-flash", "google/gemini-2.0-flash-001"}
}
local providerStickyState = {}

local function buildModelCycle(provider, currentModel)
  local base = providerModelCycles[provider] or {currentModel}
  local cycle = {currentModel}
  local seen = {[currentModel] = true}
  for _, m in ipairs(base) do
    if not seen[m] then
      table.insert(cycle, m)
      seen[m] = true
    end
  end
  return cycle
end

function executeMasterAIApiCall(provider, systemText, userText, temperature, callback)
  local apiKey = getActiveApiKey()
  if not apiKey or apiKey == "" then
    announce(provider .. " " .. getUIText("key_missing"))
    callback(nil)
    return
  end
  apiKey = apiKey:gsub("^%s*(.-)%s*$", "%1")

  local apiUrl, currentModel, payloadFormat
  if provider == "OpenRouter" then
    apiUrl = "https://openrouter.ai/api/v1/chat/completions"
    currentModel = prefs.getString("or_model", "openai/gpt-4o")
    payloadFormat = "openai"
  elseif provider == "Groq" then
    apiUrl = "https://api.groq.com/openai/v1/chat/completions"
    currentModel = prefs.getString("groq_model", "llama-3.3-70b-versatile")
    payloadFormat = "openai"
  elseif provider == "Mistral" then
    apiUrl = "https://api.mistral.ai/v1/chat/completions"
    currentModel = prefs.getString("mistral_model", "mistral-small-latest")
    payloadFormat = "openai"
  elseif provider == "Gemini" then
    apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/"
    currentModel = prefs.getString("gemini_model", "gemini-2.5-flash")
    payloadFormat = "google"
  else
    announce("Invalid AI Provider")
    callback(nil)
    return
  end

  local modelsToTry = {currentModel}
  if autoSwitchModels then
    local cycle = buildModelCycle(provider, currentModel)
    local startIndex = 1
    local state = providerStickyState[provider]
    if state and state.model == currentModel and state.idx and state.idx <= #cycle then
      startIndex = state.idx
    end
    modelsToTry = {}
    for i = 1, #cycle do
      local idx = ((startIndex - 1 + i - 1) % #cycle) + 1
      table.insert(modelsToTry, cycle[idx])
    end
  end

  local lastFailStatus = nil
  local maxFullPasses = 3
  local totalAttemptsAllowed = autoSwitchModels and (#modelsToTry * maxFullPasses) or #modelsToTry
  local function attemptRequest(modelIndex, isSwitch)
    if modelIndex > totalAttemptsAllowed then
      if lastFailStatus == 429 then
        announce(provider .. " rate limit reached. Please wait a few seconds and try again.")
      else
        announce(getUIText("connection_failed"))
      end
      callback(nil)
      return
    end
    local cyclePos = ((modelIndex - 1) % #modelsToTry) + 1
    local tryingModel = modelsToTry[cyclePos]
    if isSwitch then
      announce("Switching model, " .. tryingModel)
    end
    local finalUrl = apiUrl
    local postData = {}

    if payloadFormat == "openai" then
      local messages = {}
      if systemText and systemText ~= "" then table.insert(messages, {role="system", content=systemText}) end
      table.insert(messages, {role="user", content=userText})
      postData = { model = tryingModel, messages = messages, temperature = temperature, max_tokens = 6144 }
      if provider == "OpenRouter" and tryingModel:lower():find("google/gemini") then
        postData.reasoning = { max_tokens = 1024 }
      end
    elseif payloadFormat == "google" then
      finalUrl = apiUrl .. tryingModel .. ":generateContent?key=" .. apiKey
      postData = { contents = {{parts = {{text = userText}}}}, generationConfig = {temperature = temperature} }
      if systemText and systemText ~= "" then postData.systemInstruction = {parts = {{text = systemText}}} end
    end

    local headers = { ["Content-Type"] = "application/json", ["Accept"] = "application/json" }
    if payloadFormat == "openai" then headers["Authorization"] = "Bearer " .. apiKey end

    local ok, callErr = pcall(function()
      Http.post(finalUrl, cjson.encode(postData), headers, function(status, data)
        local handled = false
        local outputText = nil
        pcall(function()
          if status == 200 and data then
            local ok2, decoded = pcall(cjson.decode, data)
            if ok2 and decoded then
              if payloadFormat == "openai" and decoded.choices and decoded.choices[1] and decoded.choices[1].message then
                outputText = decoded.choices[1].message.content
              elseif payloadFormat == "google" and decoded.candidates and decoded.candidates[1] and decoded.candidates[1].content and decoded.candidates[1].content.parts and decoded.candidates[1].content.parts[1] then
                outputText = decoded.candidates[1].content.parts[1].text
              end
              if type(outputText) == "string" and outputText ~= "" then handled = true else outputText = nil end
            end
          end
        end)
        mainHandler.post(Runnable({run = function()
          if handled then
            if autoSwitchModels then
              local successCycleIdx = 1
              local cycle = buildModelCycle(provider, currentModel)
              for i, m in ipairs(cycle) do
                if m == tryingModel then successCycleIdx = i break end
              end
              providerStickyState[provider] = {model = currentModel, idx = successCycleIdx}
              if isSwitch then announce("Typing with " .. tryingModel) end
            end
            callback(outputText)
          else
            lastFailStatus = status
            attemptRequest(modelIndex + 1, autoSwitchModels)
          end
        end}))
      end)
    end)
    if not ok then
      mainHandler.post(Runnable({run = function() attemptRequest(modelIndex + 1, autoSwitchModels) end}))
    end
  end
  attemptRequest(1, false)
end

function googleTranslateQuick(text, targetLangCode, callback)
  local encodedText = luajava.bindClass("java.net.URLEncoder").encode(tostring(text), "UTF-8")
  local url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=" .. targetLangCode .. "&dt=t&q=" .. encodedText
  local ThreadCls = luajava.bindClass("java.lang.Thread")
  local RunnableCls = luajava.bindClass("java.lang.Runnable")
  ThreadCls(RunnableCls({run = function()
    local translatedText = nil
    pcall(function()
      local URL = luajava.bindClass("java.net.URL")
      local conn = URL(url).openConnection()
      conn.setRequestMethod("GET")
      conn.setConnectTimeout(3000)
      conn.setReadTimeout(3000)
      local responseCode = conn.getResponseCode()
      if responseCode == 200 then
        local is = conn.getInputStream()
        local Scanner = luajava.bindClass("java.util.Scanner")
        local scanner = Scanner(is).useDelimiter("\\A")
        local result = scanner.hasNext() and scanner.next() or ""
        scanner.close()
        local ok, decoded = pcall(cjson.decode, result)
        if ok and type(decoded) == "table" and decoded[1] then
          translatedText = ""
          for i = 1, #decoded[1] do
            if type(decoded[1][i]) == "table" and decoded[1][i][1] then translatedText = translatedText .. decoded[1][i][1] end
          end
        end
      end
    end)
    mainHandler.post(Runnable({run = function() callback(translatedText) end}))
  end})).start()
end

function quickAITranslate(text, targetLang, callback)
  local apiKey = getActiveApiKey()
  if not apiKey or apiKey == "" then
    callback(nil)
    return
  end
  apiKey = apiKey:gsub("^%s*(.-)%s*$", "%1")

  local apiUrl, currentModel, payloadFormat
  if selectedProvider == "OpenRouter" then
    apiUrl = "https://openrouter.ai/api/v1/chat/completions"
    currentModel = prefs.getString("or_model", "openai/gpt-4o")
    payloadFormat = "openai"
  elseif selectedProvider == "Groq" then
    apiUrl = "https://api.groq.com/openai/v1/chat/completions"
    currentModel = prefs.getString("groq_model", "llama-3.3-70b-versatile")
    payloadFormat = "openai"
  elseif selectedProvider == "Mistral" then
    apiUrl = "https://api.mistral.ai/v1/chat/completions"
    currentModel = prefs.getString("mistral_model", "mistral-small-latest")
    payloadFormat = "openai"
  elseif selectedProvider == "Gemini" then
    apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/"
    currentModel = prefs.getString("gemini_model", "gemini-2.5-flash")
    payloadFormat = "google"
  else
    callback(nil)
    return
  end

  local prompt = "Translate the following text into " .. targetLang .. " with strict word-for-word accuracy. Maintain the original tone, meaning and sentence structure exactly. CRITICAL: 1. ABSOLUTELY DO NOT add any new emojis. 2. If the original text has emojis, keep them exactly as they are. 3. If the original text has no emojis, the output MUST have no emojis. 4. ABSOLUTE PROHIBITION: DO NOT add any extra words, phrases, greetings, filler, explanations, or meaning that is not present in the original text. 5. DO NOT expand, elaborate, or paraphrase; translate ONLY what is literally present, nothing more. 6. The translated output MUST have the same number of sentences as the original text. 7. Output strictly the translated text and nothing else. No explanations, no markdown, no quotes, no preamble.\n\nText: " .. text

  local finalUrl = apiUrl
  local postData = {}
  local headers = {}
  if payloadFormat == "openai" then
    postData = { model = currentModel, messages = {{role="user", content=prompt}}, temperature = 0.3 }
    headers["Authorization"] = "Bearer " .. apiKey
  elseif payloadFormat == "google" then
    finalUrl = apiUrl .. currentModel .. ":generateContent?key=" .. apiKey
    postData = { contents = {{parts = {{text = prompt}}}}, generationConfig = {temperature = 0.3} }
  end

  local ThreadCls = luajava.bindClass("java.lang.Thread")
  local RunnableCls = luajava.bindClass("java.lang.Runnable")
  ThreadCls(RunnableCls({run = function()
    local outputText = nil
    pcall(function()
      local URL = luajava.bindClass("java.net.URL")
      local conn = URL(finalUrl).openConnection()
      conn.setRequestMethod("POST")
      conn.setDoOutput(true)
      conn.setConnectTimeout(5000)
      conn.setReadTimeout(5000)
      conn.setRequestProperty("Content-Type", "application/json")
      for k,v in pairs(headers) do conn.setRequestProperty(k, v) end
      local OutputStreamWriter = luajava.bindClass("java.io.OutputStreamWriter")
      local writer = OutputStreamWriter(conn.getOutputStream(), "UTF-8")
      writer.write(cjson.encode(postData))
      writer.flush()
      writer.close()
      local responseCode = conn.getResponseCode()
      if responseCode == 200 then
        local is = conn.getInputStream()
        local Scanner = luajava.bindClass("java.util.Scanner")
        local scanner = Scanner(is).useDelimiter("\\A")
        local result = scanner.hasNext() and scanner.next() or ""
        scanner.close()
        local ok, decoded = pcall(cjson.decode, result)
        if ok and decoded then
          if payloadFormat == "openai" and decoded.choices and decoded.choices[1] then
            outputText = decoded.choices[1].message.content
          elseif payloadFormat == "google" and decoded.candidates and decoded.candidates[1] then
            outputText = decoded.candidates[1].content.parts[1].text
          end
          if type(outputText) ~= "string" or outputText == "" then outputText = nil end
        end
      end
    end)
    mainHandler.post(Runnable({run = function() callback(outputText) end}))
  end})).start()
end

function stopListening()
  forceStopDictation = true
  isListening = false
  consecutiveSilences = 0
  if globalSR then
    pcall(function() globalSR.cancel(); globalSR.destroy() end)
    globalSR = nil
  end
end

function startVoiceInput(callback)
  if isListening then return end
  isListening = true
  local intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
  intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
  intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, "en-IN")
  intent.putExtra(RecognizerIntent.EXTRA_PROMPT, "Speak your question...")
  local sr = SpeechRecognizer.createSpeechRecognizer(context)
  sr.setRecognitionListener({
    onResults = function(res)
      local matches = res.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
      if matches and matches.size() > 0 then
        local spokenText = matches.get(0)
        if callback then callback(spokenText) end
      end
      sr.destroy()
      isListening = false
    end,
    onError = function(error)
      sr.destroy()
      isListening = false
      if callback then callback(nil) end
    end,
    onReadyForSpeech = function(params) triggerSound() end
  })
  sr.startListening(intent)
end

function showChatDialog()
  local dlg = LuaDialog(context)
  dlg.setTitle(getUIText("chat_title"))
  local layout = {
    LinearLayout, orientation="vertical", layout_width="fill", layout_height="fill", padding="10dp",
    {ScrollView, id="scroll", layout_width="fill", layout_height="0dp", layout_weight=1,
      {LinearLayout, id="messages_container", orientation="vertical", layout_width="fill", padding="5dp"}
    },
    {LinearLayout, orientation="horizontal", layout_width="fill", layout_marginTop="10dp",
      {EditText, id="input_msg", hint=getUIText("type_message"), layout_width="0dp", layout_weight=1, backgroundColor="#F5F5F5", padding="10dp"},
      {Button, id="mic_btn", text="🎤", textSize="20sp", backgroundColor="#4CAF50", textColor="#FFFFFF", padding="10dp", layout_marginLeft="5dp"},
      {Button, id="send_btn", text=getUIText("send"), backgroundColor="#2196F3", textColor="#FFFFFF", padding="10dp", layout_marginLeft="5dp"},
      {Button, id="close_chat_btn", text=getUIText("close"), backgroundColor="#F44336", textColor="#FFFFFF", padding="10dp", layout_marginLeft="5dp"}
    }
  }
  dlg.setView(loadlayout(layout))
  dlg.show()
  local scroll = scroll
  local container = messages_container
  local input = input_msg
  local sendBtn = send_btn
  local micBtn = mic_btn
  local closeBtn = close_chat_btn
  local function addMessage(text, isUser)
    local msgLayout = LinearLayout(container.getContext())
    msgLayout.setOrientation(LinearLayout.VERTICAL)
    msgLayout.setLayoutParams(LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
    local marginLeft = isUser and 100 or 10
    local marginRight = isUser and 10 or 100
    local params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
    params.setMargins(marginLeft, 5, marginRight, 5)
    msgLayout.setLayoutParams(params)
    local msgText = TextView(container.getContext())
    msgText.setText(text)
    msgText.setTextSize(14)
    msgText.setPadding(15, 10, 15, 10)
    if isUser then
      msgText.setBackgroundColor(0xFF2196F3)
      msgText.setTextColor(0xFFFFFFFF)
      msgText.setGravity(Gravity.RIGHT)
    else
      if text:match("^Error:") then
        msgText.setBackgroundColor(0xFFFF5722)
        msgText.setTextColor(0xFFFFFFFF)
      else
        msgText.setBackgroundColor(0xFFE0E0E0)
        msgText.setTextColor(0xFF000000)
      end
      msgText.setGravity(Gravity.LEFT)
    end
    msgLayout.addView(msgText)
    container.addView(msgLayout)
    mainHandler.post(Runnable({run = function() scroll.fullScroll(ScrollView.FOCUS_DOWN) end}))
  end
  local function sendMessage(msg)
    if msg == "" then return end
    addMessage(msg, true)
    input.setText("")
    addMessage(getUIText("ai_is_thinking"), false)
    local sysPrompt = "You are a helpful, friendly AI assistant. You chat naturally and provide helpful answers. Keep responses conversational and engaging."
    executeMasterAIApiCall(selectedProvider, sysPrompt, msg, 0.7, function(reply)
      mainHandler.post(Runnable({
        run = function()
          if container.getChildCount() > 0 then container.removeViewAt(container.getChildCount() - 1) end
          if reply then
            addMessage(reply, false)
            announce(reply)
          else
            addMessage("Sorry, I couldn't process that. Please check your API Key and internet connection.", false)
          end
        end
      }))
    end)
  end
  sendBtn.setOnClickListener({onClick = function(v) sendMessage(input.getText().toString()) end})
  micBtn.setOnClickListener({
    onClick = function(v)
      startVoiceInput(function(spokenText)
        if spokenText and spokenText ~= "" then
          input.setText(spokenText)
          sendMessage(spokenText)
        end
      end)
    end
  })
  closeBtn.setOnClickListener({onClick = function(v) dlg.dismiss() end})
  input.setOnEditorActionListener({
    onEditorAction = function(v, actionId, event)
      if actionId == android.view.inputmethod.EditorInfo.IME_ACTION_SEND then
        sendMessage(input.getText().toString())
        return true
      end
      return false
    end
  })
end

function processWithAI(text, isTranslatedAlready, callback)
  local minE, maxE = 1, 3
  if emojiQty == "Medium" then minE, maxE = 3, 5 elseif emojiQty == "High" then minE, maxE = 5, 7 end

  local transRule = ""
  local transForceCmd = "CRITICAL: NO TRANSLATION ALLOWED! YOU MUST KEEP EVERY SINGLE WORD IN ITS ORIGINAL LANGUAGE! "
  if enableTranslation and useAITranslation and not isTranslatedAlready then
    transRule = "TRANSLATION MODE ON (AI TRANSLATION): You MUST fully translate the spoken text into " .. targetLanguage .. " with strict word-for-word accuracy. Maintain the original tone, meaning and sentence structure exactly. Do NOT output the original language. ABSOLUTE PROHIBITION: DO NOT add any extra words, phrases, greetings, filler, or meaning that is not present in the original spoken text. DO NOT expand or elaborate; translate ONLY what was literally spoken. " .. (emojiEnabled and "Provide flawless formatting, advanced punctuation, and emojis." or "Provide flawless formatting and advanced punctuation. DO NOT add any emojis.")
    transForceCmd = "CRITICAL: TRANSLATE TO " .. targetLanguage .. " REQUIRED! "
  elseif isTranslatedAlready then
    transRule = "TRANSLATION MODE ON: The text has already been accurately translated via Google Engine. Do NOT translate it again. " .. (emojiEnabled and "Provide flawless formatting, advanced punctuation, and emojis." or "Provide flawless formatting and advanced punctuation. DO NOT add any emojis.")
  else
    transRule = "TRANSLATION MODE OFF - ABSOLUTE PROHIBITION OF TRANSLATION:\nCRITICAL RULES (STRICT ENFORCEMENT):\n1. THIS IS A FORMATTING TASK, NOT TRANSLATION.\n2. NEVER TRANSLATE ANY NATIVE WORD TO ENGLISH. ABSOLUTE ZERO TOLERANCE.\n3. If input has 'नमस्ते', output 'नमस्ते' (NEVER 'hello').\n4. If input has 'समस्या', output 'समस्या' (NEVER 'problem').\n5. Every single word MUST remain in its exact original spoken language and script.\n6. DO NOT replace Hindi/Urdu/Marathi words with English equivalents under any circumstances."
  end

  local styleDirectives = "TONE: Auto-Correct. Fix minor spelling mistakes. DO NOT add extra information or filler."
  local isProfessionalMode = (typingMode == "Professional Writer Mode")
  local isNormalMode = (typingMode == "Normal Typer Mode (AI Grammar Correction)")
  local isRomanTyperMode = (typingMode == "Roman Typer")
  local isCustomMode = (typingMode == "Custom Typing Mode")
  local scriptRule = ""
  local userForceScriptCmd = ""

  if isTranslatedAlready or (enableTranslation and useAITranslation and not isTranslatedAlready) then
    scriptRule = "[SYSTEM DIRECTIVE: TRANSLATION MODE SCRIPT LOCK - ABSOLUTE HIGHEST PRIORITY, OVERRIDES THE CURRENTLY SELECTED TYPING MODE COMPLETELY]\nThe output MUST be a complete, accurate, professional-quality translation into " .. targetLanguage .. ", and the ENTIRE output MUST be written strictly and exclusively in the native script of " .. targetLanguage .. ", with ZERO exceptions.\n- Do NOT mix in any other script under any circumstances.\n- If " .. targetLanguage .. " is English, the ENTIRE output must be written purely in plain A-Z Roman script.\n- If " .. targetLanguage .. " has its own native script (for example Hindi uses Devanagari, Tamil uses Tamil script, Urdu uses Urdu script), the ENTIRE output must be written purely in that one native script only.\n- This rule completely overrides any Auto Detect Script mixed-script behavior, and overrides any script or formatting behavior from Professional, Normal, Roman Typer, or Custom typing modes. Only the translation and script rules apply here."
    userForceScriptCmd = "CRITICAL SCRIPT LOCK: The final translated output must be entirely in the single native script of " .. targetLanguage .. ". Do NOT mix any other script anywhere in the output."
  elseif typingMode == "Auto Detect Script" then
    scriptRule = "SCRIPT MAPPING (STRICT DICTIONARY-BACKED ENGINE):\n- THE FIRST WORD RULE: Pay intense attention to the very first word of the dictation. If it is a greeting like 'hello', 'hi', or 'hey', it MUST be output in A-Z Roman script (e.g., 'Hello'), NEVER in a native script.\n- CROSS-CHECK EVERY WORD: You must verify if each spoken word exists in the standard English dictionary.\n- IF IT IS AN ENGLISH DICTIONARY WORD: You are STRICTLY FORBIDDEN from outputting it in a native script. It MUST be written in A-Z Roman script. This applies to ALL English words (e.g., 'hello', 'problem', 'perfect', 'typing', 'mobile', 'setting', 'offline', 'mode') regardless of their position in the sentence.\n- IF IT IS A NATIVE LANGUAGE WORD (in the source language, " .. selectedLanguage .. "): It MUST remain in its own native script (for example, Hindi words in Devanagari, Tamil words in Tamil script, Urdu words in Urdu script, matching whatever the source language's native script is). NEVER romanize native words, and NEVER transliterate them into any other script.\n- MANDATORY MIXED-SCRIPT OUTPUT: Every single sentence MUST correctly mix both scripts together, word by word, exactly following the two rules above. This is NEVER optional and applies to 100% of the output, every single time, with zero exceptions.\n- ABSOLUTELY FORBIDDEN (COMMON MISTAKE - NEVER DO THIS): Do NOT output the entire sentence purely in Roman/transliterated script by romanizing the native words too. Do NOT output the entire sentence purely in the native script by transliterating the English words into that native script either. Both of these are SEVERE FAILURES of this rule.\n- MANDATORY EXAMPLE (for a Hindi source sentence): if the person says 'mujhe apna mobile setting mein jaake wifi on karna hai', the CORRECT output is 'मुझे अपना mobile setting में जाके wifi on करना है।' The WRONG output, which must NEVER be produced, is 'mujhe apna mobile setting mein jaake wifi on karna hai.' (everything in Roman) and it is EQUALLY WRONG to produce 'मुझे अपना मोबाइल सेटिंग में जाके वाईफाई ऑन करना है।' (English words wrongly transliterated into the native script). The SAME mixed-script principle applies identically no matter which native language is being used."
    userForceScriptCmd = "Enforce the FIRST WORD RULE. Convert ALL English dictionary words to A-Z Roman script, and keep ALL native-language words strictly in their own native script. NEVER output the whole sentence purely in Roman script, and NEVER output the whole sentence purely in the native script by transliterating the English words into it. Mix both scripts correctly in every single sentence, word by word."
  elseif isProfessionalMode then
    scriptRule = "[SYSTEM DIRECTIVE: PROFESSIONAL WRITER MODE - ULTRA PROFESSIONAL TYPING]\n[LANGUAGE: " .. selectedLanguage .. "]\n[PRIORITY: HIGHEST - PROFESSIONAL QUALITY IS MANDATORY]\nYou MUST transform the input text into HIGHLY PROFESSIONAL, FORMAL, POLITE, and POLISHED content.\nMANDATORY RULES:\n1. GRAMMAR PERFECTION: Ensure flawless grammar in the target language.\n2. HIGH-END VOCABULARY & EXTREME POLITENESS: Replace casual/everyday words with their most formal, refined, and respectful equivalents. For example, in Hindi, ALWAYS use 'आप' instead of 'तुम/तू', use 'भोजन ग्रहण' instead of 'खाना खाया', use 'कार्य' instead of 'काम'. Apply this highest level of formal vocabulary and extreme politeness to ALL languages.\n3. SENTENCE PROFESSIONALIZATION: Convert short, choppy sentences into smooth, flowing, and authoritative yet highly respectful sentences.\n4. PERFECT PUNCTUATION: Add ALL necessary advanced punctuation.\n5. NO TRANSLATION: The output MUST remain in the SAME EXACT language as the input."
    userForceScriptCmd = "CRITICAL: Transform this into ULTRA PROFESSIONAL and EXTREMELY POLITE writing. Strictly upgrade all vocabulary to the highest formal standard (e.g., use 'आप', 'भोजन', 'कार्य' in Hindi). Fix ALL grammar. KEEP THE TEXT IN ITS ORIGINAL NATIVE LANGUAGE. Output ONLY the professional text. NO explanations. For language: " .. selectedLanguage
  elseif isRomanTyperMode then
    scriptRule = "[SYSTEM DIRECTIVE: ROMAN TYPER MODE - PERFECT TRANSLITERATION]\n[LANGUAGE: " .. selectedLanguage .. "]\nTransform the input text by changing its script to the Roman alphabet (A-Z) with 100% accuracy.\nCRITICAL ROMAN TYPER RULES:\n1. TRANSLITERATE ONLY: If the input is Hindi, output perfect 'Hinglish', etc.\n2. NO TRANSLATION: DO NOT translate the words into English meaning (e.g., 'नमस्ते' must become 'Namaste', NEVER 'Hello').\n3. PERFECT SPELLING: Use standard and widely accepted Roman spellings for the native words."
    userForceScriptCmd = "Transliterate this text into the Roman alphabet (A-Z) with perfect spelling. DO NOT translate the meaning. Output ONLY the transliterated Roman text."
  elseif isCustomMode then
    local customPrompt = prefs.getString("custom_typing_prompt", "")
    scriptRule = "[SYSTEM DIRECTIVE: CUSTOM TYPING MODE]\n[LANGUAGE: " .. selectedLanguage .. "]\n[PRIORITY: ABSOLUTE HIGHEST FOR CUSTOM INSTRUCTION]\nYou MUST transform the input text EXACTLY following the tone, style, and persona requested in the user's custom instruction.\nUSER CUSTOM INSTRUCTION: " .. customPrompt .. "\nCRITICAL RULES:\n1. The output MUST perfectly reflect the requested tone in the custom instruction.\n2. DO NOT translate the language unless the custom instruction explicitly asks for it.\n3. KEEP the original language and script."
    userForceScriptCmd = "CRITICAL: You MUST type exactly in the tone and style of this instruction: '" .. customPrompt .. "'. Adhere to this instruction completely. DO NOT TRANSLATE UNLESS REQUESTED. Output ONLY the processed text. NO META-TEXT. For language: " .. selectedLanguage
  elseif isNormalMode then
    scriptRule = "[SYSTEM DIRECTIVE: NORMAL TYPING MODE]\n[LANGUAGE: " .. selectedLanguage .. "]\nTransform the input text into a cleanly typed string. Fix obvious voice-to-text spelling/grammar glitches but KEEP the original tone, style, and words. DO NOT make it overly professional or casual. Just natural normal typing.\nCRITICAL RULE: DO NOT TRANSLATE. Keep the text in the exact language it was spoken in. DO NOT translate native words to English."
    userForceScriptCmd = "Format this as normal typed text. Fix voice typing glitches but maintain exact tone. DO NOT TRANSLATE. Output ONLY the text. For language: " .. selectedLanguage
  end

  local acronymRule = "ACRONYM & SHORT FORM FORMATTING - ABSOLUTE RULE:\n- ONLY apply this rule when the SPOKEN input is a genuine, well-known real-world abbreviation or short form, such as LPG, CNG, PNG, CSR, SIR, SBI, RBI, CID, URL, API, PDF, HTML, JSON, and similar established short forms.\n- When such a genuine short form is spoken, output it with a dot (full stop) placed immediately after EACH letter, including a trailing dot after the final letter. For example, CID must be typed as C.I.D., LPG must be typed as L.P.G., SBI must be typed as S.B.I., CSR must be typed as C.S.R.\n- STRICTLY FORBIDDEN: Do NOT apply this rule to normal English words, brand names, product names, or multi-word phrases, even if they sound short. For example, 'Play Store', 'Application', 'Store', 'Mobile', 'Setting', 'Play' are ORDINARY WORDS and MUST be typed exactly as normal words, NEVER split into individual dotted capital letters.\n- If you are not completely certain that the spoken word is a genuine, real-world short form, you MUST treat it as a normal word and leave it exactly as spoken, without any reformatting.\n- Do NOT convert genuine acronyms to dictionary words under ANY circumstances, but equally do NOT convert normal words into acronym-style formatting."

  local emojiPlacement = emojiInline and "immediately after the specific word or phrase they match, spread naturally through the whole text" or "at the end"
  local emojiRules = ""
  if isProfessionalMode then emojiRules = emojiEnabled and ("EMOJIS: Insert between 1 and " .. maxE .. " professional emojis " .. emojiPlacement .. ".") or "EMOJIS: DO NOT ADD EMOJIS."
  elseif isRomanTyperMode then emojiRules = emojiEnabled and ("EMOJIS: Insert between 1 and " .. maxE .. " relevant emojis " .. emojiPlacement .. ".") or "EMOJIS: DO NOT ADD EMOJIS."
  elseif isCustomMode then emojiRules = emojiEnabled and ("EMOJIS: Add emojis if relevant to custom instruction, placed " .. emojiPlacement .. ".") or "EMOJIS: DO NOT ADD EMOJIS."
  else emojiRules = emojiEnabled and ("EMOJIS: Insert between 1 and " .. maxE .. " relevant emojis " .. emojiPlacement .. ".") or "EMOJIS: DO NOT ADD EMOJIS." end
  if emojiEnabled and emojiInline then emojiRules = emojiRules .. " Match each emoji to the exact word or phrase it follows, for example a greeting gets a waving hand, a food word like mango gets a mango emoji, and a question about thoughts or feelings gets a thinking face. Draw from the full range of available emoji categories (faces, gestures, hearts, animals, food, nature, weather, travel, objects, activities, symbols) to find the emoji that is genuinely the closest match to each word or phrase. STRICT NO-REPEAT RULE (ABSOLUTE): The EXACT SAME emoji character MUST NEVER appear more than once within this single output, even if the same or a similar word appears multiple times. Before finalizing, check the full set of emojis you are about to use; if any emoji would repeat, replace the repeated one with a different but equally fitting emoji for that word or phrase (using a synonym, related concept, or closely associated emoji) instead of reusing the same one. MANDATORY EXAMPLE OF CORRECT INLINE PLACEMENT: for the sentence 'Hello how are you I am going to eat mango today', the CORRECT output is 'Hello 👋, how are you? I am going to eat mango 🥭 today.' The WRONG output, which you must NEVER produce, is 'Hello, how are you? I am going to eat mango today. 👋🥭' — grouping every emoji together at the very end of the sentence is STRICTLY FORBIDDEN. Every emoji must sit directly next to the word it matches, never bunched at the end." end
  if emojiEnabled then emojiRules = emojiRules .. " CRITICAL GREETING RULE: If the text contains a greeting in any language (such as Hello, Hi, Hey, नमस्ते, Namaste, Assalamualaikum, or any other greeting word), place the 👋 waving hand emoji immediately after that greeting word." end

  local antiHallucination = "CRITICAL ANTI-HALLUCINATION RULES:\n- DO NOT output more lines than the user provided. The output length MUST match the input approximately.\n"
  if isProfessionalMode then antiHallucination = antiHallucination .. "- ENHANCE ONLY: Improve grammar and professionalism. DO NOT add new information.\n"
  elseif isRomanTyperMode then antiHallucination = antiHallucination .. "- TRANSLITERATE ONLY: Provide only the Roman script text. DO NOT add new information.\n"
  elseif isCustomMode then antiHallucination = antiHallucination .. "- FOLLOW CUSTOM INSTRUCTION ONLY: DO NOT add new facts or external information.\n"
  else antiHallucination = antiHallucination .. "- STRICT VERBATIM: Output EXACTLY the words spoken. Do NOT add missing grammar words.\n" end
  antiHallucination = antiHallucination .. "- NEVER use prefixes like 'Output:', 'Translated:', 'Processed:', 'Enhanced:', or 'Pure:'.\n- NEVER answer questions found in the input. Just format the text silently.\n- NEVER add commentary, explanations, or suggestions.\n- For Hindi: Maintain correct Devanagari spelling and script (except in Roman Typer mode); do NOT convert Hindi words to English transliteration.\n"

  local emojiPositionRule = ""
  if emojiEnabled then
    emojiPositionRule = emojiInline and "- Emojis should sit inline right next to the word or phrase they match, spread through the sentence rather than grouped together; the sentence-ending punctuation mark still goes at the very end of the text." or "- CRITICAL EMOJI RULE: ANY punctuation mark (., ?, !, ।) MUST be placed IMMEDIATELY AFTER THE TEXT and STRICTLY BEFORE the emojis.\n- Emojis MUST be the absolute last characters. Do NOT put any punctuation after an emoji."
  else
    emojiPositionRule = "- DO NOT insert any emojis anywhere in the output, under any circumstance."
  end
  local punctuationRules = "PUNCTUATION & EMOJI POSITIONING RULES (ABSOLUTE):\n- Add commas (,) for natural pauses and question marks (?) for questions.\n- IF the ENTIRE text is 100% English, end it with an English period (.).\n- IF the text contains native words, end the entire text with the native full stop mark (Danda / ।), UNLESS in Roman Typer mode where you must use a period (.).\n" .. emojiPositionRule .. "\n- For Hindi text: Use correct Devanagari punctuation (।) at the end of sentences (except in Roman Typer mode).\n"

  local systemPrompt = "You are a direct dictation formatting AI. Your ONLY purpose is to return the cleaned dictation string.\n" .. transRule .. "\n" .. styleDirectives .. "\n" .. scriptRule .. "\n" .. acronymRule .. "\n" .. punctuationRules .. "\n" .. antiHallucination .. "\n" .. emojiRules
  local emojiForceCmd = ""
  if emojiEnabled then
    emojiForceCmd = emojiInline and "Place emojis inline right next to the specific words or phrases they match, spread through the text. CRITICAL: every emoji used in this output must be unique, NEVER reuse the exact same emoji twice in the same output, pick the closest alternative matching emoji instead of repeating one. STRICTLY FORBIDDEN: do NOT group all emojis together at the end of the text; each emoji MUST be placed immediately after the specific word it matches, distributed throughout the sentence. " or "ALL PUNCTUATION (. । ?) MUST BE PLACED BEFORE EMOJIS! "
  else
    emojiForceCmd = "DO NOT use any emojis anywhere in this output, under any circumstance. The output must contain zero emoji characters. "
  end
  local userForceCommand = "Format the dictation strictly applying the rules. Scan EVERY word. " .. userForceScriptCmd .. " Only reformat genuine, well-known short forms (like LPG, CNG, PNG, CSR, SIR, SBI, RBI, CID, URL, API) by placing a dot after each letter, including a trailing dot (e.g. C.I.D., L.P.G.); leave all normal words, brand names, and phrases (like Play Store, Application) completely untouched. " .. transForceCmd .. emojiForceCmd .. "Output ONLY the exact raw final text. NO META-TEXT.\n<dictation>\n" .. text .. "\n</dictation>"

  local temp = 0.0
  if isProfessionalMode then temp = 0.4 elseif isCustomMode then temp = 0.4 elseif isRomanTyperMode then temp = 0.2 elseif isNormalMode then temp = 0.1 end
  executeMasterAIApiCall(selectedProvider, systemPrompt, userForceCommand, temp, function(outputText)
    if outputText then callback(outputText) end
  end)
end

function trim(s)
    if type(s) ~= "string" then return "" end
    return s:gsub("^%s*(.-)%s*$", "%1")
end

function showUpdateErrorDialog(title, message)
    mainHandler.post(Runnable({
        run = function()
            local errorDialog = LuaDialog(context)
            errorDialog.setTitle(title)
            errorDialog.setMessage(message)
            errorDialog.setButton(getUIText("close"), function() errorDialog.dismiss() end)
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
        local tempPath = currentFilePath .. ".tmp"
        local bakPath = currentFilePath .. ".bak"
        pcall(function()
            local f = io.open(currentFilePath, "w")
            if f then
                f:write(mainCode)
                f:close()
                local v = io.open(currentFilePath, "r")
                if v then
                    local content = v:read("*a")
                    v:close()
                    if content and #content == #mainCode then success = true end
                end
            end
        end)
        if not success then
            pcall(function()
                local tf = io.open(tempPath, "w")
                if tf then
                    tf:write(mainCode)
                    tf:close()
                    os.remove(bakPath)
                    os.rename(currentFilePath, bakPath)
                    os.rename(tempPath, currentFilePath)
                    local v = io.open(currentFilePath, "r")
                    if v then
                        local content = v:read("*a")
                        v:close()
                        if content and #content == #mainCode then success = true end
                    end
                end
            end)
        end
        if not success then
            pcall(function()
                local File = luajava.bindClass("java.io.File")
                local FileOutputStream = luajava.bindClass("java.io.FileOutputStream")
                local String = luajava.bindClass("java.lang.String")
                local curF = File(currentFilePath)
                local bakF = File(bakPath)
                local tmpF = File(tempPath)
                if tmpF.exists() then tmpF.delete() end
                local fos = FileOutputStream(tmpF)
                fos.write(String(mainCode).getBytes("UTF-8"))
                fos.close()
                if bakF.exists() then bakF.delete() end
                curF.renameTo(bakF)
                tmpF.renameTo(File(currentFilePath))
                local v = io.open(currentFilePath, "r")
                if v then
                    local content = v:read("*a")
                    v:close()
                    if content and #content == #mainCode then success = true end
                end
            end)
        end
        if not success then
            pcall(function()
                os.execute("rm -f '" .. bakPath .. "'")
                os.execute("mv '" .. currentFilePath .. "' '" .. bakPath .. "'")
                os.execute("mv '" .. tempPath .. "' '" .. currentFilePath .. "'")
                local v = io.open(currentFilePath, "r")
                if v then
                    local content = v:read("*a")
                    v:close()
                    if content and #content == #mainCode then success = true end
                end
            end)
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
                                if func then pcall(func) else announce("Error reloading plugin") end
                            end
                        }), 2000)
                    end)
                    successDialog.show()
                end
            }))
        else
            updateInProgress = false
            showUpdateErrorDialog("Update Failed", "Update failed please, try again later.")
        end
    end
    local updateThread = Thread(luajava.bindClass("java.lang.Runnable"){ run = updateProcess })
    updateThread.start()
end

function checkForUpdates(manualCheck)
    if updateInProgress then
        if manualCheck then showUpdateErrorDialog("Update In Progress", "An update is already in progress. Please wait.") end
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
                            if nCode == 200 and notesData then releaseNotes = "A new version (" .. onlineVersion .. ") is available.\n\nRelease Notes:\n" .. notesData .. "\n\nWould you like to update now?" end
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
    {CheckBox, id="dict_case_chk", text=getUIText("case_sensitive"), checked=dictCaseSensitive, layout_marginBottom="15dp"},
    {Button, id="add_word_btn", text=getUIText("add_new_words"), backgroundColor="#4CAF50", textColor="#FFFFFF", layout_marginBottom="15dp"},
    {Button, id="view_words_btn", text=getUIText("view_dictionary_words"), backgroundColor="#2196F3", textColor="#FFFFFF", layout_marginBottom="15dp"},
    {Button, id="clear_dict_btn", text=getUIText("clear_dictionary"), backgroundColor="#F44336", textColor="#FFFFFF", layout_marginBottom="20dp"},
    {Button, id="close_dict_btn", text=getUIText("close"), backgroundColor="#9E9E9E", textColor="#FFFFFF"}
  }
  dlg.setView(loadlayout(layout)).show()
  dict_case_chk.onClick = function()
    dictCaseSensitive = dict_case_chk.isChecked()
    editor.putBoolean("dict_case_sensitive", dictCaseSensitive).commit()
  end
  add_word_btn.onClick = function() dlg.dismiss(); showAddWordDialog() end
  view_words_btn.onClick = function() dlg.dismiss(); showViewDictionaryDialog() end
  clear_dict_btn.onClick = function() dlg.dismiss(); showClearDictionaryConfirmDialog() end
  close_dict_btn.onClick = function() dlg.dismiss() end
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
  dlg.setView(loadlayout(layout)).show()
  save_word_btn.onClick = function()
    local originalWord = tostring(original_word_et.text):gsub("^%s*(.-)%s*$", "%1")
    local replacementWord = tostring(replacement_word_et.text):gsub("^%s*(.-)%s*$", "%1")
    if originalWord == "" then announce(getUIText("please_enter_word")); return end
    if replacementWord == "" then announce(getUIText("please_enter_replacement")); return end
    changeTable[originalWord] = replacementWord
    local saveJson = cjson.encode(changeTable)
    editor.putString("word_dictionary", saveJson).commit()
    announce(getUIText("word_added", originalWord, replacementWord))
    dlg.dismiss()
    showWordDictionaryDialog()
  end
  cancel_word_btn.onClick = function() dlg.dismiss(); showWordDictionaryDialog() end
end

function showViewDictionaryDialog()
  if not next(changeTable) then
    announce(getUIText("dictionary_empty"))
    showWordDictionaryDialog()
    return
  end
  local dictList = {}
  for orig, repl in pairs(changeTable) do table.insert(dictList, orig .. " → " .. repl) end
  table.sort(dictList)
  local listDlg = LuaDialog(context)
  listDlg.setTitle(getUIText("dictionary_words", #dictList))
  local list = ListView(context)
  list.setAdapter(ArrayAdapter(context, android.R.layout.simple_list_item_1, dictList))
  list.onItemClick = function(parent, view, position, id) end
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

function showTypingHistoryDialog(node)
  if #typingHistoryList == 0 then
    announce("No typing history yet.")
    return
  end
  local listDlg = LuaDialog(context)
  listDlg.setTitle("Typing History (" .. #typingHistoryList .. ")")
  local list = ListView(context)
  list.setAdapter(ArrayAdapter(context, android.R.layout.simple_list_item_1, typingHistoryList))
  list.onItemClick = function(parent, view, position, id)
    local selText = typingHistoryList[position + 1]
    if selText and node then
      listDlg.dismiss()
      pcall(function()
        local freshNode = service.getEditText()
        if not freshNode then freshNode = node end
        service.insert(freshNode, selText)
        triggerVibration("typing"); triggerSound()
      end)
    end
  end
  listDlg.setView(list)
  listDlg.setButton("Clear History", function()
    typingHistoryList = {}
    saveTypingHistory()
    announce("Typing history cleared")
    listDlg.dismiss()
  end)
  listDlg.setButton2(getUIText("close"), function() listDlg.dismiss() end)
  listDlg.show()
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
    for _, fl in ipairs(favs) do if l == fl then isFav = true break end end
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
    if isTarget then targetLanguage = selected else selectedLanguage = selected end
    if sourceBtn then sourceBtn.setText(selected) end
    listDlg.dismiss()
  end
  list.onItemLongClick = function(parent, view, position, id)
    local selected = sortedList[position + 1]
    local isFav = false
    local favIdx = -1
    for i, fl in ipairs(favs) do if fl == selected then isFav = true; favIdx = i; break end end
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
  local uiLanguagesList = {"English", "Hindi", "Urdu"}
  local endActionsList = {getUIText("none"), getUIText("new_line"), getUIText("space"), getUIText("space_newline")}
  local dlg = LuaDialog(context)
  local layout = {
    LinearLayout, orientation="vertical", padding="20dp",
    {TextView, text=getUIText("other_settings_title"), textSize="20sp", textColor="#2196F3", layout_marginBottom="20dp", gravity="center"},
    {TextView, text=getUIText("select_ui_lang"), layout_marginBottom="5dp"},
    {Spinner, id="ui_lang_sp", layout_marginBottom="15dp"},
    {CheckBox, id="sub_unlimited_chk", text=getUIText("unlimited_dictation"), checked=unlimitedDictation, layout_marginBottom="15dp"},
    {CheckBox, id="sub_show_preview_chk", text=getUIText("show_preview_before_typing"), checked=showPreview, layout_marginBottom="15dp"},
    {CheckBox, id="sub_ai_trans_chk", text=getUIText("use_ai_translation"), checked=useAITranslation, layout_marginBottom="15dp"},
    {CheckBox, id="sub_copy_chk", text=getUIText("copy_clipboard"), checked=copyToClipboard, layout_marginBottom="15dp"},
    {CheckBox, id="sub_typing_history_chk", text="Enable Typing History", checked=typingHistoryEnabled, layout_marginBottom="10dp"},
    {Button, id="sub_show_history_btn", text="Show Typing History", backgroundColor="#607D8B", textColor="#FFFFFF", layout_marginBottom="15dp"},
    {CheckBox, id="sub_punct_voice_chk", text="Enable Punctuation Voice Commands", checked=punctuationVoiceEnabled, layout_marginBottom="15dp"},
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
    if v == endAction or v == endActionText then sub_end_sp.setSelection(i-1); break end
  end
  sub_show_history_btn.setVisibility(typingHistoryEnabled and 0 or 8)
  sub_typing_history_chk.onClick = function()
    local nowChecked = sub_typing_history_chk.isChecked()
    sub_show_history_btn.setVisibility(nowChecked and 0 or 8)
  end
  sub_show_history_btn.onClick = function() showTypingHistoryDialog(nil) end
  sub_punct_voice_chk.onClick = function()
    if sub_punct_voice_chk.isChecked() then
      announce("Punctuation voice commands enabled. Say comma, full stop, question mark, exclamation mark, colon, semicolon, new line, hyphen, or at the rate to insert symbols.")
    end
  end
  sub_other_save_btn.onClick = function()
    uiLanguage = uiLanguagesList[ui_lang_sp.getSelectedItemPosition() + 1]
    unlimitedDictation = sub_unlimited_chk.isChecked()
    showPreview = sub_show_preview_chk.isChecked()
    useAITranslation = sub_ai_trans_chk.isChecked()
    copyToClipboard = sub_copy_chk.isChecked()
    typingHistoryEnabled = sub_typing_history_chk.isChecked()
    punctuationVoiceEnabled = sub_punct_voice_chk.isChecked()
    local selectedEndAction = endActionsList[sub_end_sp.getSelectedItemPosition() + 1]
    if selectedEndAction == getUIText("none") then endAction = "None"
    elseif selectedEndAction == getUIText("new_line") then endAction = "New Line"
    elseif selectedEndAction == getUIText("space") then endAction = "Space"
    elseif selectedEndAction == getUIText("space_newline") then endAction = "Space + New Line" end
    editor.putString("ui_language", uiLanguage).putBoolean("unlimited_dictation", unlimitedDictation).putBoolean("show_preview", showPreview).putBoolean("use_ai_trans", useAITranslation).putBoolean("typing_history_enabled", typingHistoryEnabled).putBoolean("punctuation_voice_enabled", punctuationVoiceEnabled).commit()
    dlg.dismiss()
  end
end

function showAISettingsDialog()
  local providers = {"OpenRouter", "Gemini", "Groq", "Mistral"}
  local currentRawModelsList = {}

  local dlg = LuaDialog(context)
  local layout = {
    LinearLayout, orientation="vertical", padding="20dp",
    {TextView, text=getUIText("ai_settings_title"), textSize="20sp", textColor="#2196F3", layout_marginBottom="20dp", gravity="center"},
    {TextView, text=getUIText("select_ai_provider"), layout_marginBottom="5dp"},
    {Spinner, id="sub_provider_sp", layout_marginBottom="15dp"},
    {LinearLayout, orientation="horizontal", layout_marginBottom="5dp", gravity="center_vertical",
      {TextView, text="Select Model", layout_weight=1},
      {Button, id="sub_fetch_btn", text="Fetch Models", padding="5dp"}
    },
    {Spinner, id="sub_model_sp", layout_marginBottom="20dp"},
    {CheckBox, id="sub_auto_switch_chk", text="Auto-Switch Models (Seamless Multi-Model Fallback, Never Stops on Limit Reached)", checked=autoSwitchModels, layout_marginBottom="20dp"},
    {Button, id="sub_manage_api_btn", text=getUIText("manage_api_keys"), backgroundColor="#FF9800", textColor="#FFFFFF", layout_marginBottom="20dp"},
    {Button, id="sub_ai_save_btn", text=getUIText("save_close"), backgroundColor="#4CAF50", textColor="#FFFFFF"}
  }
  dlg.setView(loadlayout(layout)).show()

  sub_provider_sp.setAdapter(ArrayAdapter(context, android.R.layout.simple_spinner_item, providers))
  for i,v in ipairs(providers) do if v == selectedProvider then sub_provider_sp.setSelection(i-1) end end

  sub_auto_switch_chk.onClick = function()
    autoSwitchModels = sub_auto_switch_chk.isChecked()
    editor.putBoolean("auto_switch_models", autoSwitchModels).commit()
  end

  local function updateModelSpinner(fetchedData)
     local prov = providers[sub_provider_sp.getSelectedItemPosition() + 1]
     local mainM, secM = "", ""
     local savedM = ""
     if prov == "OpenRouter" then mainM = "openai/gpt-4o"; secM = "openai/gpt-4o-mini"; savedM = prefs.getString("or_model", mainM)
     elseif prov == "Groq" then mainM = "llama-3.3-70b-versatile"; secM = "llama-3.1-8b-instant"; savedM = prefs.getString("groq_model", mainM)
     elseif prov == "Mistral" then mainM = "mistral-small-latest"; secM = "open-mistral-nemo"; savedM = prefs.getString("mistral_model", mainM)
     elseif prov == "Gemini" then mainM = "gemini-2.5-flash"; secM = "gemini-2.0-flash"; savedM = prefs.getString("gemini_model", mainM) end

     local seenModels = {}
     local rawList = {}
     local uiList = {}
     table.insert(rawList, mainM)
     table.insert(uiList, mainM .. " (Recommended)")
     seenModels[mainM] = true
     table.insert(rawList, secM)
     table.insert(uiList, secM)
     seenModels[secM] = true

     if prov == "Gemini" then
        local curatedGemini = {"gemini-2.5-flash-lite","gemini-3.5-flash","gemini-3.1-flash-lite","gemini-flash-latest","gemini-3-flash-preview"}
        for _, m in ipairs(curatedGemini) do
           if not seenModels[m] then
              table.insert(rawList, m)
              table.insert(uiList, m)
              seenModels[m] = true
           end
        end
     elseif prov == "OpenRouter" then
        local curatedOpenRouter = {"google/gemini-2.5-flash","google/gemini-2.0-flash-001"}
        for _, m in ipairs(curatedOpenRouter) do
           if not seenModels[m] then
              table.insert(rawList, m)
              table.insert(uiList, m)
              seenModels[m] = true
           end
        end
     elseif prov == "Mistral" then
        local curatedMistral = {"ministral-8b-latest","ministral-3b-latest","mistral-large-latest"}
        for _, m in ipairs(curatedMistral) do
           if not seenModels[m] then
              table.insert(rawList, m)
              table.insert(uiList, m)
              seenModels[m] = true
           end
        end
     end

     if fetchedData then
        for _, m in ipairs(fetchedData) do
           if not seenModels[m] then
              table.insert(rawList, m)
              table.insert(uiList, m)
              seenModels[m] = true
           end
           if #rawList >= 15 then break end
        end
     end

     currentRawModelsList = rawList
     local selIdx = 0
     for i, v in ipairs(rawList) do
        if v == savedM then selIdx = i - 1; break end
     end

     mainHandler.post(Runnable({
         run = function()
             sub_model_sp.setAdapter(ArrayAdapter(context, android.R.layout.simple_spinner_item, uiList))
             sub_model_sp.setSelection(selIdx)
         end
     }))
  end

  local function doFetch()
     local prov = providers[sub_provider_sp.getSelectedItemPosition() + 1]
     local url = ""
     local headers = {["Content-Type"] = "application/json"}
     if prov == "OpenRouter" then
        url = "https://openrouter.ai/api/v1/models"
     elseif prov == "Groq" then
        if groqKey == "" then updateModelSpinner(nil); return end
        url = "https://api.groq.com/openai/v1/models"
        headers["Authorization"] = "Bearer " .. groqKey:gsub("^%s*(.-)%s*$", "%1")
     elseif prov == "Gemini" then
        if geminiKey == "" then updateModelSpinner(nil); return end
        url = "https://generativelanguage.googleapis.com/v1beta/models?pageSize=1000&key=" .. geminiKey:gsub("^%s*(.-)%s*$", "%1")
     elseif prov == "Mistral" then
        if mistralKey == "" then updateModelSpinner(nil); return end
        url = "https://api.mistral.ai/v1/models"
        headers["Authorization"] = "Bearer " .. mistralKey:gsub("^%s*(.-)%s*$", "%1")
     end

     mainHandler.post(Runnable({run = function() sub_fetch_btn.setText("Fetching...") announce("Fetching models") end}))

     pcall(function()
         local Thread = luajava.bindClass("java.lang.Thread")
         local Runnable = luajava.bindClass("java.lang.Runnable")
         Thread(Runnable({run = function()
             pcall(function()
                 local URL = luajava.bindClass("java.net.URL")
                 local conn = URL(url).openConnection()
                 conn.setRequestMethod("GET")
                 for k,v in pairs(headers) do conn.setRequestProperty(k, v) end
                 conn.setConnectTimeout(2000)
                 conn.setReadTimeout(2000)
                 local responseCode = conn.getResponseCode()
                 if responseCode == 200 then
                     local is = conn.getInputStream()
                     local Scanner = luajava.bindClass("java.util.Scanner")
                     local scanner = Scanner(is).useDelimiter("\\A")
                     local result = scanner.hasNext() and scanner.next() or ""
                     scanner.close()

                     local ok, j = pcall(cjson.decode, result)
                     if ok and j then
                         local fetched = {}
                         if prov == "Gemini" and j.models then
                             for _, m in ipairs(j.models) do
                                 local supportsText = false
                                 if m.supportedGenerationMethods then
                                     for _, method in ipairs(m.supportedGenerationMethods) do
                                         if method == "generateContent" then supportsText = true end
                                     end
                                 end
                                 local modelId = m.name:gsub("models/", "")
                                 if supportsText and not modelId:lower():find("pro") then table.insert(fetched, modelId) end
                             end
                         elseif prov == "Groq" and j.data then
                             for _, m in ipairs(j.data) do
                                 local isActive = (m.active == nil) or (m.active == true)
                                 if isActive and not m.id:lower():find("pro") then table.insert(fetched, m.id) end
                             end
                         elseif prov == "OpenRouter" and j.data then
                             for _, m in ipairs(j.data) do
                                 local isFree = m.id:lower():find(":free") ~= nil
                                 if m.pricing and m.pricing.prompt == "0" and m.pricing.completion == "0" then isFree = true end
                                 if isFree and not m.id:lower():find("pro") then table.insert(fetched, m.id) end
                             end
                         elseif prov == "Mistral" and j.data then
                             for _, m in ipairs(j.data) do
                                 if not m.id:lower():find("embed") and not m.id:lower():find("ocr") and not m.id:lower():find("moderation") then table.insert(fetched, m.id) end
                             end
                         end
                         updateModelSpinner(fetched)
                         mainHandler.post(Runnable({run = function() announce(#fetched .. " models fetch successfully") end}))
                     end
                 end
             end)
             mainHandler.post(Runnable({run = function() sub_fetch_btn.setText("Fetch Models") end}))
         end})).start()
     end)
  end

  sub_provider_sp.setOnItemSelectedListener(luajava.createProxy("android.widget.AdapterView$OnItemSelectedListener", {
      onItemSelected = function(parent, view, position, id)
          updateModelSpinner(nil)
          doFetch()
      end,
      onNothingSelected = function(parent) end
  }))

  sub_fetch_btn.onClick = function() doFetch() end

  sub_manage_api_btn.onClick = function() showApiDialog() end
  sub_ai_save_btn.onClick = function()
    selectedProvider = providers[sub_provider_sp.getSelectedItemPosition() + 1]
    editor.putString("provider", selectedProvider)
    local selModelIdx = sub_model_sp.getSelectedItemPosition() + 1
    if currentRawModelsList[selModelIdx] then
        if selectedProvider == "OpenRouter" then
            editor.putString("or_model", currentRawModelsList[selModelIdx])
        elseif selectedProvider == "Groq" then
            editor.putString("groq_model", currentRawModelsList[selModelIdx])
        elseif selectedProvider == "Gemini" then
            editor.putString("gemini_model", currentRawModelsList[selModelIdx])
        elseif selectedProvider == "Mistral" then
            editor.putString("mistral_model", currentRawModelsList[selModelIdx])
        end
    end
    editor.commit()
    dlg.dismiss()
  end

  updateModelSpinner(nil)
  doFetch()
end

function showAboutDialog()
  local dlg = LuaDialog(context)
  local info = getUIText("about_info")
  local layout = {
    LinearLayout, orientation="vertical", padding="20dp",
    {TextView, text=getUIText("about_title"), textSize="20sp", textColor="#2196F3", layout_marginBottom="15dp", gravity="center"},
    {ScrollView, layout_width="fill", layout_weight=1, layout_marginBottom="20dp",
      {TextView, text=info, textSize="15sp", textColor="#333333"}
    },
    {Button, text=getUIText("close"), backgroundColor="#F44336", textColor="#FFFFFF", onClick=function() dlg.dismiss() end}
  }
  dlg.setView(loadlayout(layout)).show()
end

function showContactDialog()
  local dlg = LuaDialog(context)
  local layout = {
    LinearLayout, orientation="vertical", padding="20dp",
    {TextView, text=getUIText("contact_title"), textSize="20sp", textColor="#2196F3", layout_marginBottom="20dp", gravity="center"},
    {Button, text="Subscribe to YouTube Channel", onClick=function() openUrl(youtubeChannelUrl) end, backgroundColor="#F44336", textColor="#FFFFFF", layout_marginBottom="15dp"},
    {Button, text=getUIText("join_telegram"), onClick=function() openUrl("https://t.me/Ttforblind") end, backgroundColor="#2196F3", textColor="#FFFFFF", layout_marginBottom="15dp"},
    {Button, text=getUIText("give_feedback"), onClick=function() dlg.dismiss(); showFeedbackDialog() end, backgroundColor="#FF9800", textColor="#FFFFFF", layout_marginBottom="20dp"},
    {Button, text=getUIText("close"), backgroundColor="#F44336", textColor="#FFFFFF", onClick=function() dlg.dismiss() end}
  }
  dlg.setView(loadlayout(layout)).show()
end

function sendFeedbackToTelegram(nameVal, whatsappVal, telegramIdVal, feedbackVal, callback)
  local whatsappDisplay = whatsappVal ~= "" and whatsappVal or "Not Provided"
  local telegramIdDisplay = telegramIdVal ~= "" and telegramIdVal or "Not Provided"
  local messageText = "New Feedback Received\n\nName: " .. nameVal .. "\nWhatsApp Number: " .. whatsappDisplay .. "\nTelegram User ID: " .. telegramIdDisplay .. "\n\nFeedback:\n" .. feedbackVal
  local encodedText = luajava.bindClass("java.net.URLEncoder").encode(messageText, "UTF-8")
  local url = "https://api.telegram.org/bot" .. feedbackBotToken .. "/sendMessage?chat_id=" .. feedbackChatId .. "&text=" .. encodedText
  local ThreadCls = luajava.bindClass("java.lang.Thread")
  local RunnableCls = luajava.bindClass("java.lang.Runnable")
  ThreadCls(RunnableCls({run = function()
    local success = false
    pcall(function()
      local URL = luajava.bindClass("java.net.URL")
      local conn = URL(url).openConnection()
      conn.setRequestMethod("GET")
      conn.setConnectTimeout(8000)
      conn.setReadTimeout(8000)
      local responseCode = conn.getResponseCode()
      if responseCode == 200 then success = true end
    end)
    mainHandler.post(Runnable({run = function() callback(success) end}))
  end})).start()
end

function showFeedbackSuccessDialog()
  local successDlg = LuaDialog(context)
  successDlg.setTitle(getUIText("feedback_form_title"))
  successDlg.setMessage(getUIText("feedback_sent_success"))
  successDlg.setButton(getUIText("close"), function() successDlg.dismiss() end)
  successDlg.show()
end

function showFeedbackDialog()
  local dlg = LuaDialog(context)
  local layout = {
    LinearLayout, orientation="vertical", padding="20dp",
    {TextView, text=getUIText("feedback_form_title"), textSize="20sp", textColor="#2196F3", layout_marginBottom="15dp", gravity="center"},
    {TextView, text=getUIText("feedback_name_label"), layout_marginBottom="5dp"},
    {EditText, id="feedback_name_et", text=registeredUserName, hint=getUIText("feedback_name_hint"), layout_marginBottom="15dp", backgroundColor="#F5F5F5", padding="10dp"},
    {TextView, text=getUIText("feedback_whatsapp_label"), layout_marginBottom="5dp"},
    {EditText, id="feedback_whatsapp_et", hint=getUIText("feedback_whatsapp_hint"), inputType="phone", layout_marginBottom="15dp", backgroundColor="#F5F5F5", padding="10dp"},
    {TextView, text=getUIText("feedback_telegram_label"), layout_marginBottom="5dp"},
    {EditText, id="feedback_telegram_et", hint=getUIText("feedback_telegram_hint"), layout_marginBottom="15dp", backgroundColor="#F5F5F5", padding="10dp"},
    {TextView, text=getUIText("feedback_message_label"), layout_marginBottom="5dp"},
    {EditText, id="feedback_message_et", hint=getUIText("feedback_message_hint"), minLines=4, gravity="top", layout_marginBottom="20dp", backgroundColor="#F5F5F5", padding="10dp"},
    {LinearLayout, orientation="horizontal",
      {Button, id="feedback_send_btn", text=getUIText("send"), backgroundColor="#4CAF50", textColor="#FFFFFF", layout_weight=1, layout_marginRight="5dp"},
      {Button, id="feedback_cancel_btn", text=getUIText("cancel"), backgroundColor="#F44336", textColor="#FFFFFF", layout_weight=1}
    }
  }
  dlg.setView(loadlayout(layout)).show()
  feedback_send_btn.onClick = function()
    local nameVal = tostring(feedback_name_et.text):gsub("^%s*(.-)%s*$", "%1")
    local whatsappVal = tostring(feedback_whatsapp_et.text):gsub("^%s*(.-)%s*$", "%1")
    local telegramIdVal = tostring(feedback_telegram_et.text):gsub("^%s*(.-)%s*$", "%1")
    local feedbackVal = tostring(feedback_message_et.text):gsub("^%s*(.-)%s*$", "%1")
    if nameVal == "" then announce(getUIText("please_enter_name")); return end
    if feedbackVal == "" then announce(getUIText("please_enter_feedback")); return end
    feedback_send_btn.setEnabled(false)
    feedback_send_btn.text = getUIText("sending_feedback")
    sendFeedbackToTelegram(nameVal, whatsappVal, telegramIdVal, feedbackVal, function(success)
      if success then
        dlg.dismiss()
        showFeedbackSuccessDialog()
      else
        feedback_send_btn.setEnabled(true)
        feedback_send_btn.text = getUIText("send")
        announce(getUIText("feedback_send_failed"))
      end
    end)
  end
  feedback_cancel_btn.onClick = function() dlg.dismiss(); showContactDialog() end
end

function sendRegistrationToTelegram(nameVal, emailVal, deviceVal, callback)
  local messageText = "New User Registration\n\nName: " .. nameVal .. "\nEmail: " .. emailVal .. "\nDevice Information: " .. deviceVal
  local encodedText = luajava.bindClass("java.net.URLEncoder").encode(messageText, "UTF-8")
  local url = "https://api.telegram.org/bot" .. feedbackBotToken .. "/sendMessage?chat_id=" .. feedbackChatId .. "&text=" .. encodedText
  local ThreadCls = luajava.bindClass("java.lang.Thread")
  local RunnableCls = luajava.bindClass("java.lang.Runnable")
  ThreadCls(RunnableCls({run = function()
    local success = false
    pcall(function()
      local URL = luajava.bindClass("java.net.URL")
      local conn = URL(url).openConnection()
      conn.setRequestMethod("GET")
      conn.setConnectTimeout(8000)
      conn.setReadTimeout(8000)
      local responseCode = conn.getResponseCode()
      if responseCode == 200 then success = true end
    end)
    mainHandler.post(Runnable({run = function() callback(success) end}))
  end})).start()
end

function showRegistrationDialog(onDone)
  local dlg = LuaDialog(context)
  local layout = {
    LinearLayout, orientation="vertical", padding="20dp",
    {TextView, text="User Registration", textSize="20sp", textColor="#2196F3", layout_marginBottom="15dp", gravity="center"},
    {TextView, text="To use this plugin, please register your name, email and device information below.", textSize="14sp", textColor="#757575", layout_marginBottom="15dp", gravity="center"},
    {TextView, text="Name", layout_marginBottom="5dp"},
    {EditText, id="reg_name_et", hint="Enter your name", layout_marginBottom="15dp", backgroundColor="#F5F5F5", padding="10dp"},
    {TextView, text="Email ID", layout_marginBottom="5dp"},
    {EditText, id="reg_email_et", hint="Enter your email ID", inputType="textEmailAddress", layout_marginBottom="15dp", backgroundColor="#F5F5F5", padding="10dp"},
    {TextView, text="Device Information", layout_marginBottom="5dp"},
    {EditText, id="reg_device_et", hint="Enter your device information", layout_marginBottom="20dp", backgroundColor="#F5F5F5", padding="10dp"},
    {Button, id="reg_submit_btn", text="Submit", backgroundColor="#4CAF50", textColor="#FFFFFF"}
  }
  dlg.setView(loadlayout(layout))
  pcall(function() dlg.setCancelable(false) end)
  dlg.show()
  reg_submit_btn.onClick = function()
    local nameVal = tostring(reg_name_et.text):gsub("^%s*(.-)%s*$", "%1")
    local emailVal = tostring(reg_email_et.text):gsub("^%s*(.-)%s*$", "%1")
    local deviceVal = tostring(reg_device_et.text):gsub("^%s*(.-)%s*$", "%1")
    if nameVal == "" then announce("Please enter your name"); return end
    if emailVal == "" then announce("Please enter your email ID"); return end
    if deviceVal == "" then announce("Please enter your device information"); return end
    reg_submit_btn.setEnabled(false)
    reg_submit_btn.text = getUIText("sending_feedback")
    sendRegistrationToTelegram(nameVal, emailVal, deviceVal, function(success)
      if success then
        registeredUserName = nameVal
        registeredUserEmail = emailVal
        isUserRegistered = true
        editor.putString("registered_user_name", registeredUserName).putString("registered_user_email", registeredUserEmail).putBoolean("is_user_registered", true).commit()
        dlg.dismiss()
        if onDone then onDone() end
      else
        reg_submit_btn.setEnabled(true)
        reg_submit_btn.text = "Submit"
        announce(getUIText("feedback_send_failed"))
      end
    end)
  end
end

function showWelcomeDialog(onDone)
  local dlg = LuaDialog(context)
  local welcomeName = registeredUserName ~= "" and registeredUserName or ""
  local layout = {
    LinearLayout, orientation="vertical", padding="20dp",
    {TextView, text="Welcome to Extreme AI Voice Typer", textSize="20sp", textColor="#2196F3", layout_marginBottom="10dp", gravity="center"},
    {TextView, text="Developer: Anurag Anant", textSize="14sp", textColor="#757575", gravity="center", layout_marginBottom="5dp"},
    {TextView, text="Welcome, " .. welcomeName, textSize="16sp", textColor="#333333", gravity="center", layout_marginBottom="20dp"},
    {Button, text="Subscribe to YouTube Channel", onClick=function() openUrl(youtubeChannelUrl) end, backgroundColor="#F44336", textColor="#FFFFFF", layout_marginBottom="15dp"},
    {Button, text="Subscribe to Telegram Channel", onClick=function() openUrl(telegramChannelUrl) end, backgroundColor="#2196F3", textColor="#FFFFFF", layout_marginBottom="15dp"},
    {Button, text="Give Feedback to Developer", onClick=function() dlg.dismiss(); showFeedbackDialog() end, backgroundColor="#FF9800", textColor="#FFFFFF", layout_marginBottom="20dp"},
    {CheckBox, id="welcome_dont_show_chk", text="Don't show this again", checked=false, layout_marginBottom="15dp"},
    {Button, id="welcome_close_btn", text=getUIText("close"), backgroundColor="#9E9E9E", textColor="#FFFFFF"}
  }
  dlg.setView(loadlayout(layout)).show()
  welcome_close_btn.onClick = function()
    if welcome_dont_show_chk.isChecked() then
      welcomeDontShowAgain = true
      editor.putBoolean("welcome_dont_show_again", true).commit()
    end
    dlg.dismiss()
    if onDone then onDone() end
  end
end

function showSoundVibSettingsDialog()
  local sList = {getUIText("default_beep"), getUIText("soft_click"), getUIText("sharp_pop")}
  local vibIntensityList = {getUIText("low"), getUIText("medium"), getUIText("high")}
  local dlg = LuaDialog(context)
  local layout = {
    LinearLayout, orientation="vertical", padding="20dp",
    {TextView, text=getUIText("sound_vibration_title"), textSize="20sp", textColor="#2196F3", layout_marginBottom="15dp", gravity="center"},
    {CheckBox, id="sub_vib_chk", text=getUIText("enable_vibration"), checked=vibrationEnabled, layout_marginBottom="15dp"},
    {TextView, text=getUIText("vibration_intensity"), layout_marginBottom="5dp"},
    {Spinner, id="sub_vib_intensity_sp", layout_marginBottom="15dp"},
    {CheckBox, id="sub_sound_chk", text=getUIText("enable_typing_sound"), checked=soundEnabled, layout_marginBottom="15dp"},
    {CheckBox, id="sub_startup_sound_chk", text=getUIText("enable_startup_sound"), checked=startupSoundEnabled, layout_marginBottom="15dp"},
    {TextView, text=getUIText("typing_sound_type"), layout_marginBottom="5dp"},
    {Spinner, id="sub_sound_sp", layout_marginBottom="20dp"},
    {Button, id="sub_sv_save_btn", text=getUIText("save_close"), backgroundColor="#4CAF50", textColor="#FFFFFF"}
  }
  dlg.setView(loadlayout(layout)).show()
  sub_sound_sp.setAdapter(ArrayAdapter(context, android.R.layout.simple_spinner_item, sList))
  local soundTypeText = getUIText(soundType:lower():gsub(" ", "_"))
  for i,v in ipairs(sList) do 
    if v == soundType or v == soundTypeText then sub_sound_sp.setSelection(i-1); break end
  end
  sub_vib_intensity_sp.setAdapter(ArrayAdapter(context, android.R.layout.simple_spinner_item, vibIntensityList))
  local vibIntensityText = getUIText(vibrationIntensity:lower())
  for i,v in ipairs(vibIntensityList) do 
    if v == vibrationIntensity or v == vibIntensityText then sub_vib_intensity_sp.setSelection(i-1); break end
  end
  sub_sv_save_btn.onClick = function()
    vibrationEnabled = sub_vib_chk.isChecked()
    soundEnabled = sub_sound_chk.isChecked()
    startupSoundEnabled = sub_startup_sound_chk.isChecked()
    local selectedSound = sList[sub_sound_sp.getSelectedItemPosition() + 1]
    if selectedSound == getUIText("default_beep") then soundType = "Default Beep"
    elseif selectedSound == getUIText("soft_click") then soundType = "Soft Click"
    elseif selectedSound == getUIText("sharp_pop") then soundType = "Sharp Pop" end
    local selectedVibIntensity = vibIntensityList[sub_vib_intensity_sp.getSelectedItemPosition() + 1]
    if selectedVibIntensity == getUIText("low") then vibrationIntensity = "Low"
    elseif selectedVibIntensity == getUIText("medium") then vibrationIntensity = "Medium"
    elseif selectedVibIntensity == getUIText("high") then vibrationIntensity = "High" end
    editor.putBoolean("vibration_enabled", vibrationEnabled).putBoolean("sound_enabled", soundEnabled).putString("sound_type", soundType).putBoolean("startup_sound_enabled", startupSoundEnabled).putString("vibration_intensity", vibrationIntensity).commit()
    dlg.dismiss()
  end
end

function showMoreOptionsDialog()
  moreOptionsDlg = LuaDialog(context)
  local layout = {
    ScrollView, layout_width="fill",
    {LinearLayout, orientation="vertical", padding="20dp",
      {TextView, text=getUIText("more_options_title"), textSize="22sp", textColor="#2196F3", layout_marginBottom="20dp", gravity="center"},
      {Button, text="Check For Updates", onClick=function() checkForUpdates(true); moreOptionsDlg.dismiss() end, backgroundColor="#FF5722", textColor="#FFFFFF", layout_marginBottom="10dp"},
      {Button, text=getUIText("chat_with_ai"), onClick=function() 
        local key = getActiveApiKey()
        if not key or key == "" then announce("Please add API Settings first."); return end
        moreOptionsDlg.dismiss()
        showChatDialog()
      end, backgroundColor="#FF9800", textColor="#FFFFFF", layout_marginBottom="10dp"},
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
      {TextView, text=getUIText("mistral_key")}, {EditText, id="mistral_et", text=mistralKey},
      {Button, text=getUIText("get_mistral_key"), onClick=function() openUrl("https://console.mistral.ai/api-keys/") end, backgroundColor="#607D8B", textColor="#FFFFFF", layout_marginBottom="10dp"},
      {Button, id="save_api_btn", text=getUIText("save_keys"), backgroundColor="#2196F3", textColor="#FFFFFF"}
    }
  }
  local dlg = LuaDialog(context).setView(loadlayout(layout)).show()
  save_api_btn.onClick = function()
    editor.putString("or_key", tostring(or_et.text)).putString("gemini_key", tostring(gem_et.text)).putString("groq_key", tostring(groq_et.text)).putString("mistral_key", tostring(mistral_et.text)).commit()
    orKey = tostring(or_et.text); geminiKey = tostring(gem_et.text); groqKey = tostring(groq_et.text); mistralKey = tostring(mistral_et.text)
    dlg.dismiss()
  end
end

function showEmojiSettingsDialog()
  local qtyList = {"Low", "Medium", "High"}
  local layout = {
    LinearLayout, orientation="vertical", padding="20dp",
    {TextView, text=getUIText("emoji_settings_title"), textSize="20sp", textColor="#2196F3", layout_marginBottom="15dp", gravity="center"},
    {CheckBox, id="sub_emoji_chk", text=getUIText("enable_smart_emojis"), checked=emojiEnabled, layout_marginBottom="15dp"},
    {CheckBox, id="sub_emoji_inline_chk", text=getUIText("emoji_inline_setting"), checked=emojiInline, layout_marginBottom="15dp"},
    {TextView, text=getUIText("emoji_quantity"), layout_marginBottom="5dp"},
    {Spinner, id="sub_emoji_qty_sp", layout_marginBottom="20dp"},
    {Button, id="sub_emoji_save_btn", text=getUIText("save_close"), backgroundColor="#4CAF50", textColor="#FFFFFF"}
  }
  local dlg = LuaDialog(context).setView(loadlayout(layout)).show()
  sub_emoji_qty_sp.setAdapter(ArrayAdapter(context, android.R.layout.simple_spinner_item, qtyList))
  for i,v in ipairs(qtyList) do if v == emojiQty then sub_emoji_qty_sp.setSelection(i-1) end end
  sub_emoji_save_btn.onClick = function()
    emojiEnabled = sub_emoji_chk.isChecked()
    emojiInline = sub_emoji_inline_chk.isChecked()
    emojiQty = qtyList[sub_emoji_qty_sp.getSelectedItemPosition() + 1]
    dlg.dismiss()
  end
end

function handleTranslateAndType(spokenText)
  if not spokenText or spokenText == "" then return end
  announce("Translating and processing...")
  local function executeAIFinalFormat(textToProcess, isTranslatedFlag)
    processWithAI(textToProcess, isTranslatedFlag, function(aiText)
      local finalText = finalGuard(aiText)
      finalText = applyDictionaryReplacement(finalText)
      local node = service.getEditText()
      if node then
        finalizeTyping(node, finalText)
      end
    end)
  end
  if useAITranslation then
    local originalEnableTrans = enableTranslation
    enableTranslation = true
    executeAIFinalFormat(spokenText, false)
    enableTranslation = originalEnableTrans
  else
    local targetCode = getLangCode(targetLanguage)
    targetCode = string.sub(targetCode, 1, 2)
    if targetLanguage == "Chinese (Mandarin)" then targetCode = "zh-CN" end
    googleTranslateQuick(spokenText, targetCode, function(translatedText)
      if translatedText and translatedText ~= "" then
        executeAIFinalFormat(translatedText, true)
      else
        local originalEnableTrans = enableTranslation
        enableTranslation = true
        executeAIFinalFormat(spokenText, false)
        enableTranslation = originalEnableTrans
      end
    end)
  end
end

function showCustomPromptDialog()
  local dlg = LuaDialog(context)
  dlg.setTitle("Custom Typing Mode")
  local layout = {
    LinearLayout, orientation="vertical", padding="20dp",
    {TextView, text="Give your custom instruction to AI for typing:", layout_marginBottom="10dp", textColor="#2196F3"},
    {EditText, id="custom_prompt_et", hint="e.g., Type professionally or type casually", layout_marginBottom="15dp", backgroundColor="#F5F5F5", padding="10dp", text=prefs.getString("custom_typing_prompt", "")},
    {LinearLayout, orientation="horizontal", layout_marginBottom="15dp",
      {Button, id="save_persona_btn", text="Save As Style", backgroundColor="#FF9800", textColor="#FFFFFF", layout_weight=1, layout_marginRight="5dp"},
      {Button, id="my_personas_btn", text="My Styles", backgroundColor="#9C27B0", textColor="#FFFFFF", layout_weight=1}
    },
    {LinearLayout, orientation="horizontal",
      {Button, id="save_cp_btn", text="Save", backgroundColor="#4CAF50", textColor="#FFFFFF", layout_weight=1, layout_marginRight="5dp"},
      {Button, id="cancel_cp_btn", text="Cancel", backgroundColor="#F44336", textColor="#FFFFFF", layout_weight=1}
    }
  }
  dlg.setView(loadlayout(layout))
  dlg.show()
  save_cp_btn.onClick = function()
    local cp = tostring(custom_prompt_et.text)
    editor.putString("custom_typing_prompt", cp).commit()
    dlg.dismiss()
    announce("Custom prompt saved")
  end
  cancel_cp_btn.onClick = function() dlg.dismiss() end
  save_persona_btn.onClick = function()
    local cp = tostring(custom_prompt_et.text):gsub("^%s*(.-)%s*$", "%1")
    if cp == "" then announce("Please enter an instruction first"); return end
    dlg.dismiss()
    showSaveAsPersonaDialog(cp)
  end
  my_personas_btn.onClick = function()
    dlg.dismiss()
    showPersonaListDialog()
  end
end

function showSaveAsPersonaDialog(promptText)
  local dlg = LuaDialog(context)
  dlg.setTitle("Save As Style")
  local layout = {
    LinearLayout, orientation="vertical", padding="20dp",
    {TextView, text="Give this style a name:", layout_marginBottom="10dp", textColor="#2196F3"},
    {EditText, id="persona_name_et", hint="e.g., Formal Boss, Funny Friend", layout_marginBottom="20dp", backgroundColor="#F5F5F5", padding="10dp"},
    {LinearLayout, orientation="horizontal",
      {Button, id="save_persona_name_btn", text="Save", backgroundColor="#4CAF50", textColor="#FFFFFF", layout_weight=1, layout_marginRight="5dp"},
      {Button, id="cancel_persona_name_btn", text="Cancel", backgroundColor="#F44336", textColor="#FFFFFF", layout_weight=1}
    }
  }
  dlg.setView(loadlayout(layout))
  dlg.show()
  save_persona_name_btn.onClick = function()
    local pname = tostring(persona_name_et.text):gsub("^%s*(.-)%s*$", "%1")
    if pname == "" then announce("Please enter a name"); return end
    local foundIndex = nil
    for i, p in ipairs(personaList) do if p.name == pname then foundIndex = i; break end end
    if foundIndex then personaList[foundIndex].prompt = promptText
    else table.insert(personaList, {name = pname, prompt = promptText}) end
    savePersonas()
    announce("Style saved: " .. pname)
    dlg.dismiss()
    showCustomPromptDialog()
  end
  cancel_persona_name_btn.onClick = function() dlg.dismiss(); showCustomPromptDialog() end
end

function showPersonaListDialog()
  if #personaList == 0 then
    announce("No saved styles yet. Save one first.")
    showCustomPromptDialog()
    return
  end
  local names = {}
  for i, p in ipairs(personaList) do table.insert(names, p.name) end
  local listDlg = LuaDialog(context)
  listDlg.setTitle("My Styles (Tap to Use, Long Press to Delete)")
  local list = ListView(context)
  list.setAdapter(ArrayAdapter(context, android.R.layout.simple_list_item_1, names))
  list.onItemClick = function(parent, view, position, id)
    local p = personaList[position + 1]
    if p then
      editor.putString("custom_typing_prompt", p.prompt).commit()
      announce("Style applied: " .. p.name)
      listDlg.dismiss()
      showCustomPromptDialog()
    end
  end
  list.onItemLongClick = function(parent, view, position, id)
    local p = personaList[position + 1]
    if p then
      local confirmDlg = LuaDialog(context)
      confirmDlg.setTitle("Delete Style?")
      confirmDlg.setMessage("Delete '" .. p.name .. "' from saved styles?")
      confirmDlg.setButton("Delete", function()
        table.remove(personaList, position + 1)
        savePersonas()
        announce("Deleted: " .. p.name)
        confirmDlg.dismiss()
        listDlg.dismiss()
        showPersonaListDialog()
      end)
      confirmDlg.setButton2("Cancel", function() confirmDlg.dismiss() end)
      confirmDlg.show()
    end
    return true
  end
  listDlg.setView(list)
  listDlg.setButton("Close", function() listDlg.dismiss(); showCustomPromptDialog() end)
  listDlg.show()
end

function showSettings()
  if not isUserRegistered then
    showRegistrationDialog(function()
      if welcomeDontShowAgain then
        showSettingsMain()
      else
        showWelcomeDialog(function() showSettingsMain() end)
      end
    end)
    return
  end
  if welcomeDontShowAgain then
    showSettingsMain()
  else
    showWelcomeDialog(function() showSettingsMain() end)
  end
end

function showSettingsMain()
  local typingModes = {"Auto Detect Script", "Professional Writer Mode", "Normal Typer Mode (AI Grammar Correction)", "Roman Typer", "Offline Dictation (No AI)", "Custom Typing Mode"}
  local startupActionsList = {"Ask Every Time", "AI Dictation", "Process the Text From Textbox", "Translate Text From Textbox", getUIText("translate_and_type")}
  local layout = {
    ScrollView, layout_width="fill",
    {LinearLayout, orientation="vertical", padding="20dp",
      {TextView, text="Extreme AI Voice Typer v3.1", textSize="22sp", gravity="center", textColor="#2196F3"},
      {TextView, text="Developer: Anurag Anant", textSize="14sp", gravity="center", textColor="#757575", layout_marginBottom="5dp"},
      {TextView, text="Welcome, " .. registeredUserName, textSize="14sp", gravity="center", textColor="#333333", layout_marginBottom="20dp"},
      {TextView, text=getUIText("select_typing_mode"), textSize="16sp", textColor="#2196F3", layout_marginBottom="5dp"},
      {Spinner, id="typing_mode_sp", layout_marginBottom="10dp"},
      {Button, id="edit_custom_prompt_btn", text="Edit Custom Prompt", backgroundColor="#FF9800", textColor="#FFFFFF", layout_marginBottom="20dp"},
      {TextView, text="Extension Startup Action", textSize="16sp", textColor="#2196F3", layout_marginBottom="5dp"},
      {Spinner, id="startup_action_sp", layout_marginBottom="15dp"},
      {Button, id="ai_settings_btn", text=getUIText("ai_settings"), backgroundColor="#2196F3", textColor="#FFFFFF", layout_marginBottom="15dp"},
      {View, layout_height="1dp", backgroundColor="#CCCCCC", layout_marginTop="5dp", layout_marginBottom="15dp"},
      {TextView, text=getUIText("source_language"), layout_marginBottom="5dp"},
      {Button, id="src_btn", text=selectedLanguage, backgroundColor="#607D8B", textColor="#FFFFFF", layout_marginBottom="10dp"},
      {Button, id="swap_btn", text=getUIText("swap"), backgroundColor="#607D8B", textColor="#FFFFFF", layout_marginTop="10dp"},
      {TextView, text=getUIText("target_language"), layout_marginTop="10dp", layout_marginBottom="5dp"},
      {Button, id="tgt_btn", text=targetLanguage, backgroundColor="#607D8B", textColor="#FFFFFF", layout_marginBottom="15dp"},
      {View, layout_height="1dp", backgroundColor="#CCCCCC", layout_marginTop="15dp", layout_marginBottom="15dp"},
      {Button, id="emoji_settings_btn", text=getUIText("emoji_settings"), backgroundColor="#607D8B", textColor="#FFFFFF", layout_marginTop="10dp"},
      {Button, id="more_options_btn", text=getUIText("more_options"), backgroundColor="#9E9E9E", textColor="#FFFFFF", layout_marginTop="10dp"},
      {View, layout_height="1dp", backgroundColor="#CCCCCC", layout_marginTop="20dp", layout_marginBottom="15dp"},
      {Button, id="save_main_btn", text=getUIText("save_close"), backgroundColor="#4CAF50", textColor="#FFFFFF"}
    }
  }
  triggerVibration("settings"); playStartupSound()
  settingsDlg = LuaDialog(context).setView(loadlayout(layout))
  settingsDlg.show()
  
  local isSpinnerInit = true
  typing_mode_sp.setAdapter(ArrayAdapter(context, android.R.layout.simple_spinner_item, typingModes))
  for i,v in ipairs(typingModes) do if v == typingMode then typing_mode_sp.setSelection(i-1) end end
  typing_mode_sp.setOnItemSelectedListener(luajava.createProxy("android.widget.AdapterView$OnItemSelectedListener", {
    onItemSelected = function(parent, view, position, id)
      local sel = typingModes[position + 1]
      if sel == "Custom Typing Mode" then
        edit_custom_prompt_btn.setVisibility(0)
        if not isSpinnerInit then
          showCustomPromptDialog()
        end
      else
        edit_custom_prompt_btn.setVisibility(8)
      end
      isSpinnerInit = false
    end,
    onNothingSelected = function(parent) end
  }))
  edit_custom_prompt_btn.onClick = function() showCustomPromptDialog() end

  Thread(luajava.bindClass("java.lang.Runnable"){
      run = function() Thread.sleep(3000); checkForUpdates(false) end
  }).start()
  startup_action_sp.setAdapter(ArrayAdapter(context, android.R.layout.simple_spinner_item, startupActionsList))
  for i,v in ipairs(startupActionsList) do if v == startupAction then startup_action_sp.setSelection(i-1) end end
  
  ai_settings_btn.onClick = function() showAISettingsDialog() end
  emoji_settings_btn.onClick = function() showEmojiSettingsDialog() end
  more_options_btn.onClick = function() showMoreOptionsDialog() end
  src_btn.onClick = function() showLanguageSelectDialog(false, src_btn) end
  tgt_btn.onClick = function() showLanguageSelectDialog(true, tgt_btn) end
  swap_btn.onClick = function()
    local temp = selectedLanguage; selectedLanguage = targetLanguage; targetLanguage = temp
    src_btn.setText(selectedLanguage); tgt_btn.setText(targetLanguage)
    announce("Source language is " .. selectedLanguage .. ", Target language is " .. targetLanguage)
  end
  save_main_btn.onClick = function()
    typingMode = typingModes[typing_mode_sp.getSelectedItemPosition() + 1]
    startupAction = startupActionsList[startup_action_sp.getSelectedItemPosition() + 1]
    autoDetect = (typingMode == "Auto Detect Script"); enableTranslation = false
    editor.putString("typing_mode", typingMode).putString("startup_action", startupAction).putBoolean("auto_detect", autoDetect).putString("lang", selectedLanguage).putString("target_lang", targetLanguage).putBoolean("emoji_enabled", emojiEnabled).putBoolean("emoji_inline", emojiInline).putBoolean("vibration_enabled", vibrationEnabled).putBoolean("sound_enabled", soundEnabled).putString("sound_type", soundType).putBoolean("copy_clipboard", copyToClipboard).putString("emoji_qty", emojiQty).putString("end_action", endAction).putBoolean("enable_trans", enableTranslation).putBoolean("use_ai_trans", useAITranslation).putBoolean("startup_sound_enabled", startupSoundEnabled).putString("vibration_intensity", vibrationIntensity).commit()
    settingsDlg.dismiss() 
  end
end

function flushUnlimitedDeactivation()
  if not unlimitedDictation then return end
  announce("No voice detected. Microphone stopped.")
  if showPreview and accumulatedPreviewText ~= "" then
    local pendingText = accumulatedPreviewText
    local pendingNode = accumulatedPreviewNode
    accumulatedPreviewText = ""
    accumulatedPreviewNode = nil
    showSmartPreviewDialog(pendingNode, pendingText)
  end
end

function startListening(overrideLang, customHandler)
  if forceStopDictation then return end
  forceStopDictation = false
  consecutiveSilences = 0
  isListening = true
  local intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
  intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
  local langCode = getLangCode(overrideLang or selectedLanguage)
  intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, langCode)
  local sr = SpeechRecognizer.createSpeechRecognizer(context)
  globalSR = sr
  sr.setRecognitionListener({
    onResults = function(res)
      isListening = false; consecutiveSilences = 0
      local matches = res.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
      local spokenText = nil
      if matches and matches.size() > 0 then
        spokenText = matches.get(0)
      end
      if globalSR then pcall(function() globalSR.destroy() end); globalSR = nil end
      if customHandler then
        customHandler(spokenText)
      elseif spokenText and spokenText ~= "" then
        if startupAction == "Translate & Type" or startupAction == getUIText("translate_and_type") then handleTranslateAndType(spokenText)
        else insertText(spokenText) end
      elseif not forceStopDictation then
        flushUnlimitedDeactivation()
      end
    end,
    onError = function(err)
      isListening = false
      local wasManualStop = forceStopDictation
      if globalSR then pcall(function() globalSR.destroy() end); globalSR = nil end
      if customHandler then
        customHandler(nil)
      elseif not wasManualStop then
        flushUnlimitedDeactivation()
      end
    end
  })
  sr.startListening(intent)
end

function finalizeTyping(node, finalText)
  if showPreview and unlimitedDictation then
    if accumulatedPreviewText ~= "" then
      accumulatedPreviewText = accumulatedPreviewText .. " " .. finalText
    else
      accumulatedPreviewText = finalText
    end
    accumulatedPreviewNode = node
    if forceStopDictation then
      local pendingText = accumulatedPreviewText
      local pendingNode = accumulatedPreviewNode
      accumulatedPreviewText = ""
      accumulatedPreviewNode = nil
      showSmartPreviewDialog(pendingNode, pendingText)
    else
      mainHandler.postDelayed(Runnable({run = function()
        if unlimitedDictation and not forceStopDictation and not isListening then
          startListening()
        end
      end}), 350)
    end
    return
  end
  if showPreview then
    showSmartPreviewDialog(node, finalText)
    return
  end
  local suffix = (endAction == "New Line" and "\n" or (endAction == "Space" and " " or (endAction == "Space + New Line" and " \n" or "")))
  pcall(function()
    service.insert(node, finalText .. suffix)
    if copyToClipboard then
      local clip = ClipData.newPlainText("AI Voice Typer", finalText)
      context.getSystemService(Context.CLIPBOARD_SERVICE).setPrimaryClip(clip)
    end
    addToTypingHistory(finalText)
    triggerVibration("typing"); triggerSound(); announce(finalText)
  end)
  if unlimitedDictation and not forceStopDictation then
    mainHandler.postDelayed(Runnable({run = function()
      if unlimitedDictation and not forceStopDictation and not isListening then
        startListening()
      end
    end}), 350)
  end
end

function showSmartPreviewDialog(node, initialText)
  local previewTypingModes = {"Auto Detect Script", "Professional Writer Mode", "Normal Typer Mode (AI Grammar Correction)", "Roman Typer", "Offline Dictation (No AI)", "Custom Typing Mode"}
  local dlg = LuaDialog(context)
  dlg.setTitle("Smart Preview")
  local layout = {
    ScrollView, layout_width="fill",
    {LinearLayout, orientation="vertical", padding="20dp",
      {EditText, id="preview_et", text=initialText, minLines=4, gravity="top|left", backgroundColor="#F5F5F5", padding="10dp", layout_marginBottom="15dp"},
      {TextView, text=getUIText("select_typing_mode"), layout_marginBottom="5dp"},
      {Spinner, id="preview_mode_sp", layout_marginBottom="15dp"},
      {LinearLayout, orientation="horizontal", layout_marginBottom="10dp",
        {Button, id="preview_copy_btn", text="Copy", backgroundColor="#607D8B", textColor="#FFFFFF", layout_weight=1, layout_marginRight="5dp"},
        {Button, id="preview_translate_btn", text="Translate", backgroundColor="#FF9800", textColor="#FFFFFF", layout_weight=1, layout_marginRight="5dp"},
        {Button, id="preview_continue_btn", text="Continue Typing", backgroundColor="#4CAF50", textColor="#FFFFFF", layout_weight=1}
      },
      {LinearLayout, orientation="horizontal",
        {Button, id="preview_insert_btn", text="Insert Text", backgroundColor="#4CAF50", textColor="#FFFFFF", layout_weight=1, layout_marginRight="5dp"},
        {Button, id="preview_close_btn", text=getUIText("close"), backgroundColor="#F44336", textColor="#FFFFFF", layout_weight=1}
      }
    }
  }
  dlg.setView(loadlayout(layout))
  dlg.setCancelable(false)
  dlg.show()

  preview_mode_sp.setAdapter(ArrayAdapter(context, android.R.layout.simple_spinner_item, previewTypingModes))
  for i,v in ipairs(previewTypingModes) do if v == typingMode then preview_mode_sp.setSelection(i-1) end end
  local isPreviewSpinnerInit = true
  preview_mode_sp.setOnItemSelectedListener(luajava.createProxy("android.widget.AdapterView$OnItemSelectedListener", {
    onItemSelected = function(parent, view, position, id)
      if not isPreviewSpinnerInit then
        typingMode = previewTypingModes[position + 1]
        autoDetect = (typingMode == "Auto Detect Script")
        editor.putString("typing_mode", typingMode).putBoolean("auto_detect", autoDetect).commit()
      end
      isPreviewSpinnerInit = false
    end,
    onNothingSelected = function(parent) end
  }))

  preview_copy_btn.onClick = function()
    pcall(function()
      local clip = ClipData.newPlainText("AI Voice Typer", tostring(preview_et.text))
      context.getSystemService(Context.CLIPBOARD_SERVICE).setPrimaryClip(clip)
      announce("Copied")
    end)
  end

  preview_translate_btn.onClick = function()
    local currentText = tostring(preview_et.text)
    if currentText == "" then return end
    local transLangs = {"English", "Hindi", "Marathi", "Bengali", "Tamil", "Telugu", "Kannada", "Malayalam", "Punjabi", "Urdu", "Odia", "Assamese", "Sindhi", "Nepali", "Sinhala", "Arabic", "Spanish", "French", "German", "Russian", "Japanese", "Korean", "Chinese (Mandarin)", "Italian", "Portuguese", "Dutch", "Turkish", "Persian", "Swahili"}
    local listDlg = LuaDialog(context)
    listDlg.setTitle("Choose target language")
    local list = ListView(context)
    list.setAdapter(ArrayAdapter(context, android.R.layout.simple_list_item_1, transLangs))
    list.onItemClick = function(parent, view, position, id)
      local selectedLang = transLangs[position + 1]
      listDlg.dismiss()
      preview_translate_btn.setText(getUIText("processing"))
      local translationPrompt = "Translate the following text into " .. selectedLang .. " with strict word-for-word accuracy. Maintain the original tone, meaning and sentence structure exactly. CRITICAL: 1. ABSOLUTELY DO NOT add any new emojis. 2. If the original text has emojis, keep them exactly as they are. 3. If the original text has no emojis, the output MUST have no emojis. 4. ABSOLUTE PROHIBITION: DO NOT add any extra words, phrases, greetings, filler, explanations, or meaning that is not present in the original text. 5. DO NOT expand, elaborate, or paraphrase; translate ONLY what is literally present, nothing more. 6. The translated output MUST have the same number of sentences as the original text. 7. TRANSLATE, DO NOT TRANSLITERATE: Every word, including greetings, MUST be converted to its actual meaning in " .. selectedLang .. " using the vocabulary and script of " .. selectedLang .. ". For example, नमस्ते MUST become the real greeting word of the target language (such as Hello in English), NEVER a romanized or transliterated spelling like Namaste. Do NOT simply romanize or transliterate any word; every word must carry its true translated meaning. 8. Output strictly the translated text and nothing else. No explanations, no markdown, no quotes, no preamble.\n\nText: " .. currentText
      executeMasterAIApiCall(selectedProvider, nil, translationPrompt, 0.3, function(outputText)
        mainHandler.post(Runnable({run = function()
          preview_translate_btn.setText("Translate")
          if outputText then
            local finalText = finalGuard(outputText); finalText = applyDictionaryReplacement(finalText)
            preview_et.setText(finalText)
            announce(finalText)
          end
        end}))
      end)
    end
    listDlg.setView(list)
    listDlg.show()
  end

  preview_continue_btn.onClick = function()
    preview_continue_btn.setText(getUIText("processing"))
    startListening(selectedLanguage, function(spokenText)
      local function finishContinue()
        mainHandler.post(Runnable({run = function() preview_continue_btn.setText("Continue Typing") end}))
      end
      if not spokenText or spokenText == "" then finishContinue(); return end
      local function appendResult(processedText)
        mainHandler.post(Runnable({run = function()
          local existing = tostring(preview_et.text)
          local combined = existing
          if existing ~= "" then combined = combined .. " " end
          combined = combined .. processedText
          preview_et.setText(combined)
          pcall(function() preview_et.setSelection(string.len(combined)) end)
          triggerVibration("typing"); triggerSound(); announce(processedText)
        end}))
        finishContinue()
      end
      if typingMode == "Offline Dictation (No AI)" then
        local ft = finalGuard(spokenText)
        processOffline(ft, function(resText)
          resText = applyDictionaryReplacement(resText)
          appendResult(resText)
        end)
      else
        processWithAI(spokenText, false, function(aiText)
          local finalText2 = finalGuard(aiText)
          finalText2 = applyDictionaryReplacement(finalText2)
          appendResult(finalText2)
        end)
      end
    end)
  end

  preview_insert_btn.onClick = function()
    local finalText = tostring(preview_et.text)
    dlg.dismiss()
    local freshNode = service.getEditText()
    if not freshNode then freshNode = node end
    if freshNode and finalText ~= "" then
      local suffix = (endAction == "New Line" and "\n" or (endAction == "Space" and " " or (endAction == "Space + New Line" and " \n" or "")))
      pcall(function()
        service.insert(freshNode, finalText .. suffix)
        if copyToClipboard then
          local clip = ClipData.newPlainText("AI Voice Typer", finalText)
          context.getSystemService(Context.CLIPBOARD_SERVICE).setPrimaryClip(clip)
        end
        addToTypingHistory(finalText)
        triggerVibration("typing"); triggerSound(); announce(finalText)
      end)
    end
  end

  preview_close_btn.onClick = function()
    dlg.dismiss()
  end
end

function insertText(spoken)
  if not spoken or spoken == "" then return end
  spoken = applyPunctuationVoiceCommands(spoken)
  announce(getUIText("processing"))
  local function executeAIFinalFormat(textToProcess, isTranslatedFlag)
    processWithAI(textToProcess, isTranslatedFlag, function(aiText)
      local finalText = finalGuard(aiText)
      finalText = applyDictionaryReplacement(finalText)
      local node = service.getEditText()
      if node then
        finalizeTyping(node, finalText)
      end 
    end)
  end

  if typingMode == "Offline Dictation (No AI)" then
    local finalText = finalGuard(spoken)
    processOffline(finalText, function(resText)
      resText = applyDictionaryReplacement(resText)
      local node = service.getEditText()
      if node then
        finalizeTyping(node, resText)
      end end)
    return 
  end

  if enableTranslation then
    if useAITranslation then executeAIFinalFormat(spoken, false)
    else
      local targetCode = getLangCode(targetLanguage)
      targetCode = string.sub(targetCode, 1, 2)
      if targetLanguage == "Chinese (Mandarin)" then targetCode = "zh-CN" end
      local encodedText = luajava.bindClass("java.net.URLEncoder").encode(tostring(spoken), "UTF-8")
      local url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=" .. targetCode .. "&dt=t&q=" .. encodedText
      pcall(function()
          local Http = luajava.bindClass("com.androlua.Http")
          if not Http then Http = import("com.androlua.Http") end
          if Http then
              Http.get(url, function(status, result)
                  if status == 200 and result then
                      local ok, decoded = pcall(cjson.decode, result)
                      if ok and type(decoded) == "table" and decoded[1] then
                          local translatedText = ""
                          for i = 1, #decoded[1] do
                              if type(decoded[1][i]) == "table" and decoded[1][i][1] then translatedText = translatedText .. decoded[1][i][1] end
                          end
                          if translatedText ~= "" then executeAIFinalFormat(translatedText, true); return end
                      end
                  end
                  local originalUseAITrans = useAITranslation
                  useAITranslation = true
                  executeAIFinalFormat(spoken, false)
                  useAITranslation = originalUseAITrans
              end)
          else executeAIFinalFormat(spoken, false) end
      end)
    end
  else executeAIFinalFormat(spoken, false) end
end

function processTextboxText(node, text)
  if not text or text == "" or text == "nil" then if node then pcall(function() text = tostring(node.getText() or "") end) end end
  if not text or text == "" or text == "nil" then return end
  announce("Processing text with AI for professional conversion.")
  local professionalUserCommand = "Transform the following text into professional quality content. Fix grammar, improve vocabulary, add proper punctuation, use professional tone. Keep the text in its original language. Do NOT translate to English or any other language. Return ONLY the enhanced text in the original language.\n\nText: " .. text
  
  executeMasterAIApiCall(selectedProvider, nil, professionalUserCommand, 0.3, function(outputText)
    if outputText then
      local finalText = finalGuard(outputText); finalText = applyDictionaryReplacement(finalText)
      mainHandler.post(Runnable({
        run = function()
          pcall(function()
            local freshNode = service.getEditText()
            if not freshNode then freshNode = node end
            local suffix = (endAction == "New Line" and "\n" or (endAction == "Space" and " " or (endAction == "Space + New Line" and " \n" or "")))
            local fullText = finalText .. suffix
            local Bundle = luajava.bindClass("android.os.Bundle")
            local bundle = Bundle()
            bundle.putCharSequence("ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE", fullText)
            local success = freshNode.performAction(2097152, bundle)
            if not success then
               bundle.putCharSequence("ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE", "")
               freshNode.performAction(2097152, bundle)
               service.insert(freshNode, fullText)
            end
            if copyToClipboard then 
              local clip = ClipData.newPlainText("AI Voice Typer", fullText)
              context.getSystemService(Context.CLIPBOARD_SERVICE).setPrimaryClip(clip) 
            end
            addToTypingHistory(finalText)
            triggerVibration("typing"); triggerSound(); announce("Professional conversion complete")
          end)
        end
      }))
    else announce("Professional conversion failed") end
  end)
end

function translateTextboxTextWithAI(node, text, targetLang)
  announce("Translating text to " .. targetLang)
  local translationPrompt = "Translate the following text into " .. targetLang .. " with strict word-for-word accuracy. Maintain the original tone, meaning and sentence structure exactly. CRITICAL: 1. ABSOLUTELY DO NOT add any new emojis. 2. If the original text has emojis, keep them exactly as they are. 3. If the original text has no emojis, the output MUST have no emojis. 4. ABSOLUTE PROHIBITION: DO NOT add any extra words, phrases, greetings, filler, explanations, or meaning that is not present in the original text. 5. DO NOT expand, elaborate, or paraphrase; translate ONLY what is literally present, nothing more. 6. The translated output MUST have the same number of sentences as the original text. 7. Output strictly the translated text and nothing else. No explanations, no markdown, no quotes, no preamble.\n\nText: " .. text
  
  executeMasterAIApiCall(selectedProvider, nil, translationPrompt, 0.3, function(outputText)
    if outputText then
      local finalText = finalGuard(outputText); finalText = applyDictionaryReplacement(finalText)
      mainHandler.post(Runnable({
        run = function()
          pcall(function()
            local freshNode = service.getEditText()
            if not freshNode then freshNode = node end
            local suffix = (endAction == "New Line" and "\n" or (endAction == "Space" and " " or (endAction == "Space + New Line" and " \n" or "")))
            local fullText = finalText .. suffix
            local Bundle = luajava.bindClass("android.os.Bundle")
            local bundle = Bundle()
            bundle.putCharSequence("ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE", fullText)
            local success = freshNode.performAction(2097152, bundle)
            if not success then
               bundle.putCharSequence("ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE", "")
               freshNode.performAction(2097152, bundle)
               service.insert(freshNode, fullText)
            end
            if copyToClipboard then 
              local clip = ClipData.newPlainText("AI Voice Typer", fullText)
              context.getSystemService(Context.CLIPBOARD_SERVICE).setPrimaryClip(clip) 
            end
            addToTypingHistory(finalText)
            triggerVibration("typing"); triggerSound(); announce("Translation complete")
          end)
        end
      }))
    else announce("Translation failed") end
  end)
end

function showTranslationLanguageDialog(node, text)
  if not text or text == "" or text == "nil" then if node then pcall(function() text = tostring(node.getText() or "") end) end end
  if not text or text == "" or text == "nil" then announce("Textbox is empty"); return end
  local transLangs = {"English", "Hindi", "Marathi", "Bengali", "Tamil", "Telugu", "Kannada", "Malayalam", "Punjabi", "Urdu", "Odia", "Assamese", "Sindhi", "Nepali", "Sinhala", "Arabic", "Spanish", "French", "German", "Russian", "Japanese", "Korean", "Chinese (Mandarin)", "Italian", "Portuguese", "Dutch", "Turkish", "Persian", "Swahili"}
  local listDlg = LuaDialog(context)
  listDlg.setTitle("Choose target language")
  local list = ListView(context)
  list.setAdapter(ArrayAdapter(context, android.R.layout.simple_list_item_1, transLangs))
  list.onItemClick = function(parent, view, position, id)
    local selectedLang = transLangs[position + 1]
    listDlg.dismiss()
    translateTextboxTextWithAI(node, text, selectedLang)
  end
  listDlg.setView(list)
  listDlg.show()
end

function showChangeTypingModeDialog()
  local tModes = {"Auto Detect Script", "Professional Writer Mode", "Normal Typer Mode (AI Grammar Correction)", "Roman Typer", "Offline Dictation (No AI)", "Custom Typing Mode"}
  local listDlg = LuaDialog(context)
  listDlg.setTitle("Change typing mode")
  local list = ListView(context)
  list.setAdapter(ArrayAdapter(context, android.R.layout.simple_list_item_1, tModes))
  list.onItemClick = function(parent, view, position, id)
    typingMode = tModes[position + 1]
    autoDetect = (typingMode == "Auto Detect Script")
    editor.putString("typing_mode", typingMode).putBoolean("auto_detect", autoDetect).commit()
    mainHandler.postDelayed(Runnable({
      run = function()
        announce("Typing mode changed to " .. typingMode)
      end
    }), 3000)
    listDlg.dismiss()
    if typingMode == "Custom Typing Mode" then
        showCustomPromptDialog()
    end
  end
  listDlg.setView(list)
  listDlg.setButton(getUIText("cancel"), function() listDlg.dismiss() end)
  listDlg.show()
end

function showStartupDialog(node, initialText)
  local dlg = LuaDialog(context)
  dlg.setTitle("What do you want to do?")
  local layout = {
    LinearLayout, orientation="vertical", padding="20dp",
    {Button, text="AI Voice Dictation", backgroundColor="#4CAF50", textColor="#FFFFFF", layout_marginBottom="10dp", onClick=function() dlg.dismiss() startListening() end},
    {Button, text=getUIText("translate_and_type"), backgroundColor="#9C27B0", textColor="#FFFFFF", layout_marginBottom="10dp", onClick=function() 
      dlg.dismiss(); startupAction = getUIText("translate_and_type"); startListening()
    end},
    {Button, text="Process the Text From Textbox", backgroundColor="#2196F3", textColor="#FFFFFF", layout_marginBottom="10dp", onClick=function() 
      dlg.dismiss() 
      mainHandler.postDelayed(Runnable({run = function() processTextboxText(node, initialText) end}), 200)
    end},
    {Button, text="Translate Text From Textbox", backgroundColor="#FF5722", textColor="#FFFFFF", layout_marginBottom="10dp", onClick=function() 
      dlg.dismiss() 
      mainHandler.postDelayed(Runnable({run = function() showTranslationLanguageDialog(node, initialText) end}), 200)
    end},
    {Button, text="Change typing mode", backgroundColor="#607D8B", textColor="#FFFFFF", layout_marginBottom="10dp", onClick=function() dlg.dismiss() showChangeTypingModeDialog() end},
    {Button, text="Open Settings", backgroundColor="#9E9E9E", textColor="#FFFFFF", onClick=function() dlg.dismiss() showSettings() end}
  }
  if typingHistoryEnabled then
    table.insert(layout, #layout, {Button, text="Typing History", backgroundColor="#009688", textColor="#FFFFFF", layout_marginBottom="10dp", onClick=function() dlg.dismiss() showTypingHistoryDialog(node) end})
  end
  dlg.setView(loadlayout(layout))
  dlg.show()
end

function main()
  if not service then showSettings(); return end
  if isListening then
    stopListening()
    return
  end
  forceStopDictation = false
  consecutiveSilences = 0
  accumulatedPreviewText = ""
  accumulatedPreviewNode = nil
  local node = service.getEditText()
  if not node then showSettings(); return end
  local initialText = ""
  pcall(function() initialText = tostring(node.getText() or "") end)
  if initialText == "nil" then initialText = "" end
  if startupAction == "Ask Every Time" then showStartupDialog(node, initialText)
  elseif startupAction == "AI Dictation" then startListening()
  elseif startupAction == "Translate & Type" or startupAction == getUIText("translate_and_type") then startListening()
  elseif startupAction == "Process the Text From Textbox" then processTextboxText(node, initialText)
  elseif startupAction == "Translate Text From Textbox" then showTranslationLanguageDialog(node, initialText)
  else showSettings() end
end

task(300, main)