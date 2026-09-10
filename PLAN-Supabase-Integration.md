# DSH Mobile — خطة ربط Supabase + الداشبورد
**التاريخ:** 31 أغسطس 2026
**النطاق:** onboarding من الداشبورد · أنيميشن الـ Hero Mosaic · الصفحات الداخلية · دعم 3 لغات

---

## أولاً: اللي اكتشفته من الويب والداشبورد

قبل الخطة، هذي البنية الموجودة فعلاً (مهم نبني عليها مش نخترع بديل):

### 1. جدول `landing_page_config` — هو مصدر الصور من الداشبورد

```
section_key   | enabled | config (JSONB)
──────────────┼─────────┼──────────────────────────────────────
hero          | true    | { text: {...}, slotIds: [...], slots: {...} }
films         | true    | { text: { heading, description, cta },
studio        | true    |   slotIds: ["films-1"],
academy       | true    |   slots: { "films-1": { imageSrc: "..." } } }
read          | true    |
infocus       | true    |
notebook      | true    |
newsletter    | true    |
```

كل `slot` ممكن يحمل: `imageSrc` · `videoSrc` · `mediaType` · `cardTitle` · `cardType` · `title` · `description` · `badge` · `duration` · `whoLeads` · `ctaLink` · `isFree`

**يعني:** الصور اللي ترفعها من الداشبورد تروح على bucket `media` (public) والرابط يتخزّن في `slots[x].imageSrc`. الموبايل يقرأ نفس الصف بالضبط.

### 2. المحتوى متعدد اللغات مخزّن كـ JSONB — مش أعمدة منفصلة

```json
{ "en": "Films", "pt": "Filmes", "ar": "أفلام" }
```

والويب عنده helper `str()` في `mappers.ts` يختار: اللغة المطلوبة ← اللغة الافتراضية ← أي لغة فيها نص.

### 3. اللغات نفسها من الداشبورد

`site_settings.content_languages`:
```json
[
  { "code":"en", "label":"English",    "enabled":true,  "isDefault":true,  "direction":"ltr" },
  { "code":"pt", "label":"Portuguese", "enabled":true,  "isDefault":false, "direction":"ltr" },
  { "code":"ar", "label":"Arabic",     "enabled":false, "isDefault":false, "direction":"rtl" }
]
```

⚠️ **ملاحظة:** العربي `enabled: false` في الـ seed الحالي. لازم يتفعّل من الداشبورد قبل ما يظهر.

### 4. نصوص الواجهة كمان من الداشبورد

`site_settings.ui_strings`:
```json
{ "nav.films": { "en":"Films", "pt":"Filmes", "ar":"أفلام" }, ... }
```

**هنا التعارض:** الموبايل حالياً يستخدم ملفات ARB ثابتة (101 مفتاح × 3 لغات). الويب يقرأ من Supabase. لو عدّلت نص في الداشبورد → الويب يتحدث، الموبايل لأ.

### 5. مفتاح `data_source` لكل موديول

`site_settings` فيه تبديل `mock | live` لكل من: films · studio · academy · articles · events · impact. الويب يحترمه ويعمل fallback للـ mock لو الاستعلام فشل.

---

## ثانياً: قرار اللغات (أهم قرار في الخطة)

عندنا 3 طبقات ترجمة منفصلة، وكل وحدة لها حل مختلف:

| الطبقة | مثال | المصدر المقترح |
|---|---|---|
| **نصوص ثابتة في الواجهة** | "Sign In"، "Retry"، أسماء التابات | ARB **+** `ui_strings` كـ override |
| **محتوى تحريري** | عنوان فيلم، ملخص مقال | JSONB من جداول Supabase |
| **نصوص الداشبورد** | heading قسم Films في اللاندنج | `landing_page_config.config.text` |

### الحل المقترح: Hybrid

```
إقلاع التطبيق
   ↓
ARB (فوري، offline، مضمون)  ← يظهر للمستخدم على طول
   ↓
بالخلفية: جلب ui_strings من Supabase
   ↓
لو وصلت → override للمفاتيح المتطابقة + cache محلي
```

**ليش هيك:** التطبيق ما ينتظر الشبكة عشان يعرض نص، وبنفس الوقت أي تعديل من الداشبورد يوصل. ولو المستخدم offline يشتغل عادي بالـ ARB.

### الحاجات المطلوبة للغات

1. **`LocaleController`** (Riverpod, keepAlive) — يحفظ اختيار المستخدم في SharedPrefs (`SharedPrefsHelper.setLocale()` جاهز ومش مستخدم)
2. **`localesProvider`** — يقرأ `content_languages` من Supabase، ويعرض بس اللي `enabled: true`
3. **`LocalizedText` helper** — نسخة Dart من `str()` في mappers.ts:
   ```dart
   String pickLang(dynamic value, String locale, String defaultLocale) {
     if (value is String) return value;
     if (value is Map) {
       return value[locale]?.trim().isNotEmpty == true ? value[locale]
            : value[defaultLocale]?.trim().isNotEmpty == true ? value[defaultLocale]
            : value.values.firstWhere((v) => v?.trim().isNotEmpty == true, orElse: () => '');
     }
     return '';
   }
   ```
4. **RTL** — `MaterialApp.router` لازم `locale` من الـ provider، وFlutter يتكفّل بالباقي. لكن لازم مراجعة كل صفحة: `EdgeInsets.only(left:)` تنكسر بالعربي → لازم `EdgeInsetsDirectional.only(start:)`
5. **الخط العربي** — `google_fonts` موجود؛ نستخدم Cairo أو Tajawal للعربي زي MontCamp
6. **إكمال ترجمة 7 صفحات** غير مترجمة إطلاقاً (about, academy, discover, events, films, profile, read)

---

## ثالثاً: أنيميشن الـ Hero Mosaic

### شكله في الويب (`HeroMosaic.tsx` + `globals.css`)

```
صف 1  ←←←←←←←←  (يسار)     ارتفاع 215px
صف 2  →→→→→→→→  (يمين)     ارتفاع 215px
صف 3  ←←←←←←←←  (يسار، بتأخير -30s)
```

- مدة الدورة: **90 ثانية** (بطيء ومستمر)
- كل صف يعرض قائمة الصور **مرتين**، والحركة `translateX(-50%)` → لوب سلس بدون قطع
- فلتر على كل صورة: `grayscale(1) brightness(0.5)`
- طبقة تعتيم فوق الكل: `rgba(13,13,13,0.55)`
- تدرّج سفلي (falloff) يذوّب الصفوف في خلفية الصفحة
- كل صورة لها `objectPosition` مختلف عشان التكرار ما يبان
- الصف الثالث يبدأ بصورة مختلفة (`row * 3 + i`) عشان الصفوف ما تمشي بالتوازي

### تنفيذه في Flutter

الفكرة نفسها: `AnimationController` واحد بـ `repeat()`، و `Transform.translate` على track يحتوي الصور مكررة مرتين.

```dart
// lib/app/widgets/hero_mosaic.dart
class HeroMosaic extends StatefulWidget {
  final List<String> tiles;      // من landing_page_config
  final int rows;                // 3 افتراضياً
  final double rowHeight;        // 215 → نحوّلها .h
  final Duration speed;          // 90s
  final double dim;              // 0.55
  final bool showPanel;          // البلوك الصلب خلف العنوان
}
```

نقاط تنفيذية:
- `AnimationController(vsync: this, duration: 90s)..repeat()`
- لكل صف: `dir = row.isEven ? -1 : 1`
- `Transform.translate(offset: Offset(dir * controller.value * trackWidth / 2, 0))`
- الصف الثالث: `delay` = نطرح `1/3` من قيمة الكنترولر ونعمل `% 1.0`
- `ColorFiltered` + `ColorFilter.matrix` للـ grayscale (نفس المصفوفة الموجودة في home_page.dart سطر 165)
- `RepaintBoundary` حول كل صف — مهم جداً للأداء
- **الأداء:** 3 صفوف × 12 صورة = 36 صورة متحركة. لازم `cacheWidth` على `CachedNetworkImage` وإلا الذاكرة تنفجر على أجهزة ضعيفة
- **RTL:** الاتجاهات لازم تنقلب بالعربي، أو نتركها كما هي (الحركة تجريدية مش قرائية) — قرارك

**سؤال:** بدك الأنيميشن ده في الموبايل على صفحات Films/Studio/About/Support زي الويب بالضبط، ولا بس في مكان واحد؟

---

## رابعاً: الـ Onboarding من الداشبورد

### الوضع الحالي
3 شرائح، كل وحدة صورة hardcoded من Unsplash، والنصوص من ARB (`onboardingWitness`, `onboardingDesc1`, ...).

### المقترح

**خيار A — استخدام `landing_page_config` (بدون migration جديد)**

نضيف صف جديد `section_key = 'mobile_onboarding'`:
```json
{
  "slotIds": ["slide-1", "slide-2", "slide-3"],
  "slots": {
    "slide-1": {
      "imageSrc": "https://<project>.supabase.co/storage/v1/object/public/media/onboarding-1.jpg",
      "title":       { "en": "Witness.",  "pt": "Testemunhe.", "ar": "شاهد." },
      "description": { "en": "Go beyond the headlines.", "pt": "...", "ar": "..." }
    },
    ...
  }
}
```

✅ يستخدم نفس محرر اللاندنج في الداشبورد — مافي شغل UI جديد
✅ multilingual جاهز
⚠️ يحتاج إضافة القسم لقائمة الـ sections في الداشبورد

**خيار B — جدول `mobile_config` مستقل**

جدول جديد للإعدادات الخاصة بالموبايل (onboarding، إعدادات التطبيق، force-update version، إلخ).

✅ أنظف على المدى الطويل — الموبايل رح يحتاج إعدادات خاصة فيه لاحقاً
⚠️ يحتاج migration + شاشة جديدة في الداشبورد

**توصيتي:** خيار A للـ onboarding الآن (سريع، بدون migration)، وخيار B لاحقاً لما نحتاج إعدادات موبايل حقيقية (نسخة إجبارية، feature flags).

**مهم في الحالتين:** لازم fallback — لو الاستعلام فشل أو المستخدم offline في أول تشغيل، تظهر صور محلية من `assets/`. الـ onboarding أول شاشة يشوفها المستخدم؛ ما ينفع تكون فاضية.

---

## خامساً: البنية المقترحة للكود

```
lib/app/supabase/
├── supabase_client.dart          # Supabase.initialize() + المفاتيح من --dart-define
├── supabase_provider.dart        # Riverpod provider للـ client
├── data_source_service.dart      # قراءة site_settings.data_source (cache 10 ثواني)
└── lang_helper.dart              # pickLang() — نسخة Dart من str()

lib/app/localization/
├── locale_controller.dart        # اللغة المختارة + الحفظ في SharedPrefs
├── locales_provider.dart         # content_languages من Supabase
└── ui_strings_provider.dart      # ui_strings + دمجها فوق الـ ARB

lib/app/widgets/
└── hero_mosaic.dart              # الأنيميشن (مشترك بين عدة صفحات)

lib/layers/<feature>/
├── domain/
│   ├── entities/<x>.dart
│   └── repositories/<x>_repository.dart
├── data/
│   ├── models/<x>_model.dart              # fromJson + snake_case + pickLang
│   ├── datasources/<x>_remote_datasource.dart   # استعلامات Supabase
│   └── repositories/<x>_repository_impl.dart    # Either<Failure, T> + fallback
└── presentation/
    ├── controllers/<x>_controller.dart
    ├── widgets/                            # ← تقسيم الصفحات الكبيرة
    └── <x>_page.dart
```

---

## سادساً: خطة التنفيذ بالمراحل

### المرحلة صفر — تنظيف (نصف يوم)
| # | المهمة | السبب |
|---|---|---|
| 0.1 | تقسيم `home_page.dart` (1135 سطر) → `presentation/widgets/` | مستحيل نربطه بالداتا وهو بهالحجم |
| 0.2 | `print()` → `debugPrint()` في splash | مخالف لـ analysis_options |
| 0.3 | ربط `FilmsPage` بالراوتر أو حذفها | كود ميت حالياً |
| 0.4 | إرجاع فحص `hasSeenOnboarding` في splash | معطّل بتعليق |

### المرحلة 1 — أساس Supabase (يوم)
| # | المهمة |
|---|---|
| 1.1 | تثبيت `supabase_flutter: ^2.8.0` |
| 1.2 | تهيئة الـ client + المفاتيح عبر `--dart-define` (**ممنوع hardcode**) |
| 1.3 | `data_source_service.dart` — نفس منطق الويب |
| 1.4 | `lang_helper.dart` — `pickLang()` |
| 1.5 | `Failure` mapping من `PostgrestException` |

### المرحلة 2 — اللغات (يوم) 🔴 أولوية عالية
| # | المهمة |
|---|---|
| 2.1 | `LocaleController` + الحفظ في SharedPrefs |
| 2.2 | `localesProvider` من `content_languages` |
| 2.3 | `ui_strings_provider` + الدمج فوق الـ ARB |
| 2.4 | شاشة اختيار اللغة (في Profile) |
| 2.5 | مراجعة RTL — `EdgeInsetsDirectional` بدل `EdgeInsets` |
| 2.6 | خط عربي (Cairo/Tajawal) |
| 2.7 | ترجمة الصفحات السبعة الناقصة |

### المرحلة 3 — Auth حقيقي (يوم)
| # | المهمة |
|---|---|
| 3.1 | `User` entity + `AuthRepository` بـ `Either<Failure, User>` |
| 3.2 | Supabase Auth: login/register/OTP/reset/logout |
| 3.3 | `authStateProvider` (keepAlive) + استرجاع الجلسة |
| 3.4 | `redirect` + `refreshListenable` في الراوتر ← الحماية |

### المرحلة 4 — الداشبورد والـ Hero (يوم ونصف)
| # | المهمة |
|---|---|
| 4.1 | `landing_page_config` → entity + repository + controller |
| 4.2 | ربط الـ Home بالداتا الحقيقية (استبدال كل الـ hardcoded) |
| 4.3 | بناء `hero_mosaic.dart` + اختبار الأداء |
| 4.4 | Onboarding من الداشبورد + fallback محلي |

### المرحلة 5 — الصفحات الداخلية (3-4 أيام) ⏸️ *بانتظار التصميم منك*
| # | الصفحة | الجدول |
|---|---|---|
| 5.1 | Films listing + detail | `films` |
| 5.2 | Studio listing + detail + episode | `studio_items` |
| 5.3 | Read listing + article detail | `articles` |
| 5.4 | Academy listing + course + learn | `academy_programs` |
| 5.5 | Events + detail | `events` |
| 5.6 | Impact | `impact_stats` |
| 5.7 | Support / Donate | `donations` + Stripe |

---

## سابعاً: أسئلة محتاج جوابها قبل ما أبدأ

1. **مفاتيح Supabase** — نفس مشروع الويب ولا منفصل؟ (لو نفسه، بحتاج الـ URL والـ anon key)
2. **العربي `enabled: false`** — بدك تفعّله من الداشبورد ولا الموبايل يتجاهل الفلاغ ويعرض الـ3 دايماً؟
3. **الـ Hero Mosaic** — في كم صفحة بالموبايل؟ (الويب: films, studio, about, support, academy)
4. **الـ Onboarding** — خيار A (landing_page_config) ولا B (جدول mobile_config)؟
5. **الفيديو** — الويب فيه `file | hls | bunny | embed`. الموبايل رح يشغّل فيديو؟ (لو HLS، `video_player` لحاله ما يكفي)
6. **التبرعات** — رح تكون داخل التطبيق؟ (Apple بتاخد 30% على المدفوعات الرقمية داخل التطبيق — التبرعات الخيرية لها استثناء بس تحتاج توثيق)
7. **`discover`** — الصفحة موجودة بالموبايل ومالها مقابل في الويب. من وين تجيب داتاها؟

---

## ملاحظة أخيرة

الترتيب اللي فوق مقصود: **اللغات قبل الصفحات الداخلية**. لأنه لو بنينا 10 صفحات بنص واحد ثابت، رح نرجع نفتح كل صفحة مرة تانية عشان نضيف الترجمة والـ RTL. الفرق: يوم واحد الآن مقابل 3 أيام إعادة شغل بعدين.

ونفس الكلام على المرحلة صفر — `home_page.dart` بـ 1135 سطر مستحيل نربطه بـ Supabase وهو بهالشكل.

ابعتلي التصميم لما يجهز وبنبدأ بالمرحلة 5 بالتوازي مع الباقي.
