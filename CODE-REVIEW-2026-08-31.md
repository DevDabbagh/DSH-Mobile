# DSH Mobile — مراجعة الكود الشاملة
**التاريخ:** 31 أغسطس 2026
**المراجع:** Claude
**الحالة العامة:** الواجهات ممتازة ✅ — البنية التحتية تحتاج شغل قبل Supabase ⚠️

---

## ملخص سريع (TL;DR)

| المجال | التقييم | ملاحظة |
|---|---|---|
| تصميم الـ UI | ⭐⭐⭐⭐⭐ | Home page احترافي جداً، الـ carousel والـ animations ممتازة |
| البنية المعمارية | ⭐⭐ | 10 من 12 feature بدون domain/data — presentation فقط |
| الـ Auth | ⭐⭐ | Mock بالكامل، مافي User entity، مافي session، مافي token |
| الـ Routing | ⭐⭐⭐⭐ | StatefulShellRoute ممتاز، لكن **مافي auth guard** |
| الترجمة (i18n) | ⭐⭐⭐ | البنية تمام (en/ar/pt) لكن 7 صفحات مش مترجمة |
| جاهزية Supabase | ⭐ | غير مثبت أصلاً |

**الخلاصة:** الشكل حلو جداً بس تحت الغطا لسه mock. قبل ما تربط Supabase لازم نصلح 4 حاجات أساسية.

---

## 1. البنية المعمارية — أهم مشكلة 🔴

### الوضع الحالي

```
Feature        domain    data    presentation
────────────────────────────────────────────────
auth             ✅       ✅         ✅
home             ✅       ✅         ✅
about            ❌       ❌         ✅
academy          ❌       ❌         ✅
discover         ❌       ❌         ✅
events           ❌       ❌         ✅
films            ❌       ❌         ✅
main             ❌       ❌         ✅   ← طبيعي (shell فقط)
onboarding       ❌       ❌         ✅   ← مقبول (مافي data)
profile          ❌       ❌         ✅
read             ❌       ❌         ✅
splash           ❌       ❌         ✅   ← طبيعي
```

**8 features تحتاج domain + data** (about, academy, discover, events, films, profile, read، وتكملة home).

### مشكلة أخطر: home فيها clean architecture "شكلية"

`home_page.dart` سطر 60:
```dart
data: (_) => _buildContent(context),   // ← الـ underscore يرمي الداتا!
```

يعني `HomeController` بيجيب `List<HomeSection>` من الـ repository، والـ UI **بيتجاهلها تماماً** ويرسم بيانات hardcoded جوّه الويدجت. الـ layers موجودة بس مش موصولة.

**نفس المشكلة ستتكرر مع Supabase** لو ما اتصلحت الأول.

---

## 2. الـ Auth — mock بالكامل 🔴

`lib/layers/auth/domain/auth_repository.dart`:
```dart
abstract class AuthRepository {
  Future<void> login(String email, String password);   // ← void!
  Future<void> register(...);
  Future<void> verifyOtp(String code);
  Future<void> resetPassword(String newPassword);
}
```

**المشاكل:**

1. **`Future<void>` بدل `Either<Failure, User>`** — مخالف للـ template اللي اتفقنا عليه (Dartz). مافي error handling منظّم.
2. **مافي `User` entity** — مافي `domain/entities/` في auth أصلاً.
3. **مافي حفظ للـ token** — `SharedPrefsHelper` عنده `saveToken()` و `getToken()` جاهزين بس **مش مستخدمين ولا مرة**.
4. **`AuthController` state هو `void`** — يعني مافي session state. التطبيق ما بيعرف مين المستخدم الحالي.
5. **مافي `logout()`** ولا `getCurrentUser()` ولا استرجاع session بعد إعادة فتح التطبيق.
6. **hardcoded mock:** `if (code != '123456') throw ...` و `if (email == 'error@email.com')`.

---

## 3. الـ Router — ناقصه حماية 🟠

`app_router.dart` — الإيجابيات:
- ✅ `StatefulShellRoute.indexedStack` (أفضل من IndexedStack اليدوي في MontCamp)
- ✅ `NoTransitionPage` للتابات
- ✅ navigator keys منفصلة لكل branch

**الناقص:**

1. **مافي `redirect` callback** — أي حد يقدر يفتح `/home` أو `/profile` مباشرة بدون تسجيل دخول.
2. **مافي `refreshListenable`** — لما تتغير حالة الـ auth، الراوتر ما بيعرف.
3. **`FilmsPage` موجودة بس مش مربوطة بأي route** — كود ميت.
4. **مافي detail routes** — لا `/film/:slug` ولا `/read/:slug` ولا `/course/:slug`. (لازمة للتوافق مع الويب.)

---

## 4. الترجمة (i18n) 🟠

البنية ممتازة: `en` / `ar` / `pt` مع 101 مفتاح لكل لغة، و `AppLocalizations` مربوطة صح في `app.dart`.

**بس الاستخدام غير مكتمل:**

| الصفحة | عدد استخدامات AppLocalizations |
|---|---|
| home_page | 28 ✅ |
| register_page | 12 ✅ |
| login_page | 11 ✅ |
| main_navigation | 5 ✅ |
| reset_password / otp | 2 ⚠️ |
| onboarding | 1 ⚠️ |
| **about, academy, discover, events, films, profile, read, splash, forgot_password, password_success** | **0** ❌ |

كمان: **مافي locale switcher provider** — اللغة بتتبع لغة الجهاز فقط، والمستخدم ما يقدر يغيّرها من داخل التطبيق. (`SharedPrefsHelper.setLocale()` موجود بس مش مستخدم.)

---

## 5. مشاكل جودة كود 🟡

1. **`home_page.dart` = 1135 سطر** — كبير جداً. لازم يتقسم لويدجتس منفصلة تحت `presentation/widgets/`.
   - `discover_page.dart` = 525 سطر — نفس المشكلة بدرجة أقل.

2. **`print()` في `splash_page.dart`** (3 مرات، أسطر 60-62) — مخالف لـ `analysis_options.yaml` اللي فيه `avoid_print: true`. لازم `debugPrint()`.

3. **الـ onboarding check معطّل** في splash:
   ```dart
   // Temporarily always show onboarding as requested
   // final hasSeenOnboarding = ref.read(sharedPrefsHelperProvider).hasSeenOnboarding();
   context.go('/onboarding');
   ```
   لازم يترجع قبل الإطلاق.

4. **صور hardcoded من مصادر خارجية** — 40+ رابط:
   - `i.pravatar.cc` (6 مرات) — صور أفاتار وهمية
   - `images.unsplash.com` (25+) — صور المحتوى
   - `picsum.photos` (8) — في `home_repository_impl.dart`

   كلها لازم تتبدل ببيانات Supabase.

5. **`FilmsPage` و `AcademyPage` صفحات فاضية** (14 سطر لكل وحدة — بس `Center(child: Text('Films'))`).

---

## 6. مقارنة الموبايل مع الويب 📊

الويب (`dsh-landing`) شغال على **Supabase فعلياً** مع 10 جداول:

```
films · studio_items · articles · academy_programs · events
donations · impact_stats · landing_page_config · site_settings
trailer_access_requests
```

### خريطة صفحات الويب ↔ الموبايل

| صفحة الويب | الموبايل | الحالة |
|---|---|---|
| `/` (landing) | `/home` | ✅ مبني (بيانات hardcoded) |
| `/films` | `FilmsPage` | ⚠️ صفحة فاضية + مش في الراوتر |
| `/film/[slug]` | — | ❌ غير موجود |
| `/studio` | — | ❌ غير موجود |
| `/studio/[slug]` | — | ❌ غير موجود |
| `/studio/[slug]/[episode]` | — | ❌ غير موجود |
| `/read` | `/read` | ⚠️ "coming soon" |
| `/read/[slug]` | — | ❌ غير موجود |
| `/academy` | `/academy` | ⚠️ صفحة فاضية |
| `/course/[slug]` | — | ❌ غير موجود |
| `/course/[slug]/learn` | — | ❌ غير موجود |
| `/academy/instructor/[slug]` | — | ❌ غير موجود |
| `/agenda` | `/events` | ✅ مبني (313 سطر) |
| `/agenda/[slug]` | — | ❌ غير موجود |
| `/about` | `/about` | ✅ مبني (300 سطر) |
| `/support` | — | ❌ غير موجود |
| `/profile` | `/profile` | ✅ مبني (311 سطر) |
| — | `/discover` | ➕ خاص بالموبايل (525 سطر) |

**النتيجة:** 6 صفحات مبنية، 3 فاضية/placeholder، **10 صفحات ناقصة**.

---

## 7. خطة ربط Supabase 🎯

### المبدأ الأساسي

الويب عنده pattern ذكي في `src/lib/api.ts` لازم الموبايل يقلّده:

```
site_settings.data_source (per module: mock | live)
        ↓
   live → Supabase query → mapper → domain entity
   mock → mock data
   (وfallback تلقائي للـ mock لو الاستعلام فشل)
```

يعني نفس الـ **Data Switcher** اللي في الـ dashboard بيتحكم في الموبايل كمان. هذا مهم — يخليك تشتغل على الداشبورد وتشوف النتيجة فوراً في الموبايل.

### البنية المقترحة

```
lib/app/supabase/
├── supabase_client.dart       # تهيئة Supabase.initialize()
├── supabase_provider.dart     # Riverpod provider للـ client
└── data_source_service.dart   # قراءة site_settings.data_source (cache 10s)

lib/layers/films/
├── domain/
│   ├── entities/film.dart              # نسخة Dart من Film type في الويب
│   └── repositories/films_repository.dart
├── data/
│   ├── models/film_model.dart          # fromJson + mapper (يطابق mapFilm في mappers.ts)
│   ├── datasources/films_remote_datasource.dart   # Supabase queries
│   └── repositories/films_repository_impl.dart
└── presentation/
    ├── controllers/films_controller.dart
    ├── films_page.dart
    └── film_detail_page.dart
```

**مهم:** أسماء الأعمدة في Supabase `snake_case` (مثل `synopsis_short`، `thumbnail_url`) — لازم `@JsonKey(name: '...')` في كل model، بالضبط زي ما `mappers.ts` بتعمل في الويب.

### Auth مع Supabase

Supabase Auth بيحل معظم مشاكل الـ auth الحالية:

```dart
// domain/entities/user.dart  ← لازم ينعمل
class User extends Equatable { id, email, fullName, avatarUrl, role }

// domain/repositories/auth_repository.dart  ← لازم يتعدّل
abstract class AuthRepository {
  Future<Either<Failure, User>> login(String email, String password);
  Future<Either<Failure, User>> register(...);
  Future<Either<Failure, Unit>> logout();
  Future<Either<Failure, User?>> getCurrentUser();
  Stream<User?> authStateChanges();          // ← لـ router refreshListenable
}
```

Supabase بيوفّر جاهز: session persistence، refresh tokens، OAuth (Google/Apple)، password reset بالإيميل، OTP. يعني الـ `pinput` والـ OTP page اللي مبنيين رح يشتغلوا مع Supabase OTP مباشرة.

### الحزم المطلوبة

```yaml
supabase_flutter: ^2.8.0     # يشمل gotrue + postgrest + storage + realtime
```

وبعدها ممكن نشيل `dio` / `retrofit` / `dio_http_formatter` (إلا لو في APIs خارجية زي Stripe).

---

## 8. خطة العمل المقترحة (بالترتيب)

### المرحلة صفر — تنظيف قبل Supabase (نصف يوم)
1. تقسيم `home_page.dart` (1135 سطر) لويدجتس تحت `home/presentation/widgets/`
2. إصلاح `print()` → `debugPrint()` في splash
3. ربط `FilmsPage` بالراوتر أو حذفها مؤقتاً
4. إرجاع فحص `hasSeenOnboarding` في splash

### المرحلة 1 — أساس Supabase (يوم)
5. تثبيت `supabase_flutter` + تهيئة الـ client + الـ providers
6. بناء `data_source_service.dart` (نفس منطق الويب)
7. إنشاء `.env` أو `--dart-define` لمفاتيح Supabase (**ممنوع hardcode المفاتيح**)

### المرحلة 2 — Auth حقيقي (يوم)
8. `User` entity + إعادة كتابة `AuthRepository` بـ `Either<Failure, User>`
9. ربط Supabase Auth (login/register/OTP/reset/logout)
10. `authStateProvider` (keepAlive) + حفظ session
11. **`redirect` + `refreshListenable` في الراوتر** ← الحماية

### المرحلة 3 — ربط المحتوى (2-3 أيام)
12. `films` — entity + model + datasource + repository + controller + ربط UI
13. `articles` (read) — نفس الشي
14. `academy_programs` — نفس الشي
15. `events` — ربط الصفحة المبنية بالبيانات الحقيقية
16. `impact_stats` + `landing_page_config` — ربط الـ home بالبيانات الفعلية

### المرحلة 4 — الصفحات الناقصة (3-4 أيام)
17. Film detail، Article detail، Course detail + learn، Studio + episodes، Support/Donate

### المرحلة 5 — تلميع
18. إكمال الترجمة للصفحات السبعة الناقصة
19. Locale switcher provider + حفظه في SharedPrefs
20. Shimmer/empty/error states موحّدة في كل صفحة

---

## 9. أسئلة محتاج جوابها منك

1. **مفاتيح Supabase** — نفس المشروع تبع الويب ولا مشروع منفصل؟
2. **الـ dashboard** — إيش الحاجات اللي رح تضيفها؟ عشان نحسب حسابها في الـ schema من الآن.
3. **الفيديو** — الويب فيه `videoProvider: file | hls | bunny | embed`. الموبايل رح يشغّل فيديو داخل التطبيق؟ (لو أيوه، `video_player` موجود بس ممكن نحتاج `better_player` للـ HLS.)
4. **Stripe/التبرعات** — رح يكون في الموبايل ولا web-only؟ (في اعتبارات App Store لو في مدفوعات جوّا التطبيق.)
5. **`discover` page** — مالها مقابل في الويب. هل هي feature خاصة بالموبايل بالكامل؟

---

## الخلاصة

الشغل اللي انعمل على الواجهات **ممتاز فعلاً** — التصميم احترافي والـ animations نظيفة والـ i18n مبني صح من الأساس. المشكلة إن كل شي واقف على mock data، والـ clean architecture مطبقة على feature واحدة ونص.

قبل ما نبدأ Supabase، أنصح بشدة نعمل المرحلة صفر + 1 + 2 (يومين تقريباً) — لأن لو ربطنا Supabase على البنية الحالية، رح نعيد نفس الشغل مرتين.

بعدها كل feature جديدة رح تاخد ساعتين بدل يوم، لأن الـ pattern رح يكون واضح ومكرر.
