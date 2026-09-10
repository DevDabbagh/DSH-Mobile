# مواصفات: Mobile Settings + Onboarding من الداتابيز
**التاريخ:** 31 أغسطس 2026
**النطاق:** dsh-admin (صفحة جديدة) · Supabase (جدول + migration) · DSH Mobile (قراءة الداتا)
**تمت مراجعتها ضد:** `.agent/skills/` في الموبايل + `src/actions/` في الداشبورد

---

## القرارات المعتمدة

| البند | القرار |
|---|---|
| مكان التحكم | صفحة **Mobile Settings** في الـ Sidebar، تحت Landing Settings |
| تابات جوّاها | `[ Onboarding ]` `[ Mobile Landing ]` |
| التخزين | جدول `mobile_onboarding_slides` + migration `024` |
| النص الملون | **آخر جزء من الجملة فقط** — حقلان (`title` + `title_highlight`) |
| الترجمة | JSONB لكل حقل: `{ "en": …, "pt": …, "ar": … }` |
| الصور | مصفوفة صور لكل شريحة |
| فيديو الـ Splash | يشتغل **كل** فتحة للتطبيق |
| فشل جلب الـ Onboarding | ⇒ Home مباشرة، بدون شاشة خطأ |

---

## ✅ أولاً: الـ skills اتزبطت (تمّ)

كانت في 3 تعارضات بين `.agent/skills/` والكود الفعلي. اتحسمت كلها لصالح **الكود الفعلي**، والـ skills اتحدّثت:

| # | كان في الـ skill | صار |
|---|---|---|
| 1 | `lib/layers/domain/{feature}/` (layer-first) | `lib/layers/{feature}/domain/` (**feature-first**) |
| 2 | `Result<T>` tuple | `Either<Failure, T>` من **dartz** |
| 3 | "ALWAYS use Dio + Retrofit" + `BaseResponseModel` | **Supabase SDK** لكل جداول DSH؛ Retrofit للـ APIs الخارجية فقط |

**الملفات اللي اتعدّلت:**
```
.agent/skills/
├── DSHMobileArchitecture/
│   ├── SKILL.md                              ← أعيدت كتابته
│   └── examples/
│       ├── example_repository.dart           ← Either بدل Result
│       ├── example_remote_datasource.dart    ← Supabase بدل Retrofit
│       ├── example_model.dart                ← snake_case + pickLang
│       └── example_repository_impl.dart      ← جديد: نمط الـ Either الكامل
├── DSHMobileRiverpodState/
│   ├── SKILL.md                              ← قسم fold() + copyWithPrevious
│   └── examples/example_async_notifier.dart  ← نمط Either في build ومutation
└── DSHMobileUIWidgets/
    └── SKILL.md                              ← pt + RTL + حد 400 سطر للصفحة
```

**زيادات مهمة دخلت الـ skills:**
- قاعدة صريحة ضد `data: (_) =>` — اللي هي المشكلة الموجودة في `home_page.dart` حالياً
- الفرق بين نصوص الواجهة (ARB) والمحتوى التحريري (JSONB + `pickLang`)
- `app_pt.arb` مضاف (كان مذكور en/ar بس)
- `EdgeInsetsDirectional` + قائمة فحص RTL لكل شاشة
- حد ~400 سطر للصفحة الواحدة
- منع روابط الصور المؤقتة (unsplash / picsum / pravatar) في شاشة نهائية
- `memCacheWidth` + `RepaintBoundary` للصور المتحركة

---

## ثانياً: النص الملون — حقلان منفصلان

**القرار:** الملون هو آخر جزء من الجملة فقط.

```json
"title":           { "en": "Films, series, journalism, and education that name power and refuse",
                     "pt": "Filmes, séries, jornalismo e educação que nomeiam o poder e recusam o",
                     "ar": "أفلام وسلاسل وصحافة وتعليم تُسمّي السلطة وترفض" },

"title_highlight": { "en": "erasure.", "pt": "apagamento.", "ar": "المحو." }
```

**على الشاشة:**
```
Films, series, journalism, and education that name power and refuse
erasure.        ← بالتدرّج اللوني
```

مافي markup ولا parser. المترجم يكتب حقلين نص عادي — لا يحتاج يفهم رموز، ولا يقدر يكسر النص بقوس ناقص. وبالعربي RTL يشتغل تلقائياً لأن الملون آخر جزء طبيعياً.

**العرض في Flutter** — يعيد استخدام `GradientText` الموجود:
```dart
RichText(
  text: TextSpan(
    style: textTheme.displayLarge,
    children: [
      TextSpan(text: '${slide.title} '),
      WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: GradientText(
          slide.titleHighlight,
          gradient: AppColors.primaryGradient,
          style: textTheme.displayLarge,
        ),
      ),
    ],
  ),
)
```

---

## ثالثاً: الجدول ✅ (تمّ)

**الملف:** `dsh-admin/supabase/027_mobile_onboarding.sql` — جاهز للتشغيل في Supabase SQL Editor.

مكتوب بنفس نمط الـ migrations الموجودة (`007`, `023`): تعليق يشرح "ليش" مش "إيش"، `IF NOT EXISTS` في كل مكان، `DROP POLICY` قبل `CREATE POLICY`، و trigger لـ `updated_at`.

**الأعمدة:**

| العمود | النوع | ملاحظة |
|---|---|---|
| `id` | uuid | PK |
| `sort_order` | integer | الترتيب — سحب وإفلات |
| `enabled` | boolean | إخفاء بدون حذف |
| `images` | jsonb | مصفوفة روابط من bucket `media` |
| `image_mode` | text | `single` / `carousel` / `mosaic` |
| `title` | jsonb | متعدد اللغات |
| `title_highlight` | jsonb | متعدد اللغات — الجزء الملون |
| `description` | jsonb | متعدد اللغات |
| `show_logo` | boolean | لوجو DSH فوق |

**الـ RLS:** الـ anon يقرأ `enabled = true` فقط، والأدمن يدير الكل عبر `is_admin()` (نفس الـ helper المستخدم في باقي الجداول).

**الـ seed:** الشرائح الثلاث بنصوصها الحالية، **بدون صور**. تركت `images` فاضية عن قصد — الروابط الحالية من Unsplash، وحطها في الـ seed بيخلي روابط مؤقتة تبان كأنها محتوى حقيقي. المحرر يرفع الصور الفعلية.

⚠️ **`image_mode` لسه فيه الـ3 قيم** لأني ما عرفت الغرض من الصور المتعددة. لو carousel بس (أو mosaic بس)، بشيل التانية من الـ `CHECK` — سطر واحد.

---

## رابعاً: الداشبورد — يمشي على نفس نمط `src/actions/`

### 1. الـ Server Actions

ملف جديد `src/actions/mobile.ts` — بنفس أسلوب `landing.ts` بالضبط:

```ts
"use server";

import { createServerSupabase } from "@/lib/supabase-server";
import { requirePermission } from "./guard";
import { validateUUID, pickAllowedFields, MOBILE_ONBOARDING_FIELDS } from "@/lib/validate";

// ── Onboarding Slides ──

export async function getOnboardingSlides() {
  const supabase = await createServerSupabase();
  const { data, error } = await supabase
    .from("mobile_onboarding_slides")
    .select("*")
    .order("sort_order", { ascending: true });
  if (error) throw new Error("Failed to load onboarding slides");
  return data;
}

export async function createOnboardingSlide() {
  await requirePermission("settings", "add");
  const supabase = await createServerSupabase();
  const { data, error } = await supabase
    .from("mobile_onboarding_slides")
    .insert({})
    .select()
    .single();
  if (error) throw new Error("Failed to create slide");
  return data;
}

export async function updateOnboardingSlide(id: string, updates: Record<string, unknown>) {
  validateUUID(id);
  await requirePermission("settings", "edit");
  const supabase = await createServerSupabase();
  const sanitized = pickAllowedFields(updates, [...MOBILE_ONBOARDING_FIELDS]);
  const { error } = await supabase
    .from("mobile_onboarding_slides")
    .update({ ...sanitized, updated_at: new Date().toISOString() })
    .eq("id", id);
  if (error) throw new Error("Failed to update slide");
}

export async function deleteOnboardingSlide(id: string) {
  validateUUID(id);
  await requirePermission("settings", "delete");
  const supabase = await createServerSupabase();
  const { error } = await supabase.from("mobile_onboarding_slides").delete().eq("id", id);
  if (error) throw new Error("Failed to delete slide");
}

export async function reorderOnboardingSlides(slides: { id: string; sort_order: number }[]) {
  await requirePermission("settings", "edit");

  if (!Array.isArray(slides) || slides.length > 20) {
    throw new Error("Invalid slides list");
  }

  const supabase = await createServerSupabase();
  for (const s of slides) {
    validateUUID(s.id);
    if (typeof s.sort_order !== "number" || s.sort_order < 0 || s.sort_order > 100) {
      throw new Error("Invalid sort order");
    }
    await supabase.from("mobile_onboarding_slides").update({ sort_order: s.sort_order }).eq("id", s.id);
  }
}
```

**تعديلان مصاحبان:**

في `src/lib/validate.ts` — جنب `LANDING_CONFIG_FIELDS`:
```ts
export const MOBILE_ONBOARDING_FIELDS = [
  "sort_order", "enabled", "images", "image_mode",
  "title", "title_highlight", "description", "show_logo",
] as const;
```

في `src/actions/index.ts`:
```ts
export * from "./mobile";
```

**الصلاحية:** استخدمت `"settings"` لأنها الأقرب. لو بدك موديول مستقل `"mobile"`، لازم يتضاف لـ `PermissionModule` في `types.ts` وللـ permissions matrix — **قل لي لو تفضّل كده.**

### 2. الـ Sidebar

في `src/components/layout/Sidebar.tsx`، تحت Landing Settings مباشرة:
```tsx
{ label: "Landing Settings", href: "/landing-settings", icon: Monitor, module: "settings" },
{ label: "Mobile Settings",  href: "/mobile-settings",  icon: Smartphone, module: "settings" },
{ label: "Settings",         href: "/settings",         icon: Settings, module: "settings" },
```

### 3. الصفحة

```
src/app/(dashboard)/mobile-settings/
├── page.tsx                      # التابات: Onboarding | Mobile Landing
└── components/
    ├── OnboardingEditor.tsx      # قائمة الشرائح + ترتيب بالسحب
    ├── SlideCard.tsx             # تحرير شريحة واحدة
    └── MultiImageUploader.tsx    # رفع/حذف/ترتيب عدة صور
```

**تاب Mobile Landing:** هي معاينة اللاندنج بعرض الموبايل — اللي كانت تاب `mobile` جوّه Landing Settings.

⚠️ الـ `isMobile` مستخدم في **13 موضع** جوّه `landing-settings/page.tsx` (1600+ سطر). عشان ما ننسخ الكود:
- نستخرج المحرر لـ `src/components/landing/LandingEditor.tsx` ياخد `viewport: "desktop" | "mobile"`
- `landing-settings` → `<LandingEditor viewport="desktop" />`
- `mobile-settings` تاب Mobile Landing → `<LandingEditor viewport="mobile" />`

نفس الكود ونفس الحفظ ونفس البيانات — العرض بس اللي يختلف.

### 4. واجهة محرر الـ Onboarding

```
┌─────────────────────────────────────────────────────────┐
│  Mobile Settings                                         │
│  [ Onboarding ]  [ Mobile Landing ]                      │
├─────────────────────────────────────────────────────────┤
│  Language:  [EN] [PT] [AR]         ← useLanguages()      │
│                                        [+ Add Slide]     │
│                                                          │
│  ⠿  Slide 1                        [enabled ●]  [🗑]     │
│  ┌───────────────────────────────────────────────────┐  │
│  │ Images                                            │  │
│  │  [img1] [img2] [+ Upload]     ← سحب لإعادة الترتيب│  │
│  │  Display:  ( ) Single  ( ) Carousel  (•) Mosaic    │  │
│  │                                                   │  │
│  │ Title                                             │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │ Films, series, journalism, and education    │  │  │
│  │  │ that name power and refuse                  │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  │                                                   │  │
│  │ Highlighted ending   ← يُعرض بالتدرّج اللوني       │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │ erasure.                                    │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  │                                                   │  │
│  │ Description                                       │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  │                                                   │  │
│  │ [ ] Show DSH logo                                 │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

- شريط اللغة يعيد استخدام `useLanguages()` من `LanguageContext` — زي Landing Settings
- الرفع عبر `uploadFile(file, "onboarding")` من `src/lib/storage.ts`
- لو اللغة الحالية مالها نص: تنبيه خفيف + نص اللغة الافتراضية كـ placeholder رمادي

### 5. تنظيف Landing Settings

- حذف `activeTab` state (سطر 1203) وشريط التابات (سطر ~1547)
- `isMobile` ما ينحذف — بينتقل ليكون `viewport` prop على `LandingEditor`

---

## خامساً: جانب الموبايل

> البنية تحت **تفترض feature-first**. لو اخترت layer-first (تعارض #1)، المسارات تتغير لـ `lib/layers/domain/onboarding/` وهكذا.

```
lib/layers/onboarding/
├── domain/
│   ├── entities/onboarding_slide.dart
│   └── repositories/onboarding_repository.dart
├── data/
│   ├── models/onboarding_slide_model.dart          # freezed + json_annotation
│   ├── datasources/onboarding_remote_datasource.dart
│   └── repositories/onboarding_repository_impl.dart
└── presentation/
    ├── controllers/onboarding_controller.dart      # موجود — يتوسّع
    ├── widgets/
    │   ├── onboarding_slide.dart                   # موجود — يتعدّل
    │   ├── onboarding_shimmer.dart                 # جديد
    │   └── slide_images.dart                       # جديد
    └── onboarding_page.dart                        # يتحوّل لـ dynamic
```

### الـ Entity

```dart
class OnboardingSlide extends Equatable {
  final String id;
  final int sortOrder;
  final List<String> images;
  final ImageMode imageMode;
  final String title;             // محلول حسب اللغة
  final String titleHighlight;
  final String description;
  final bool showLogo;
}
```

### الـ Repository — بصيغة الـ skill

```dart
abstract class OnboardingRepository {
  Future<Result<List<OnboardingSlide>>> getSlides();
}
```
*(لو استقر الرأي على `Either`، تتغير لـ `Future<Either<Failure, List<OnboardingSlide>>>`.)*

### الـ Datasource — Supabase بدل Retrofit

```dart
@riverpod
OnboardingRemoteDataSource onboardingRemoteDataSource(Ref ref) =>
    OnboardingRemoteDataSource(ref.read(supabaseClientProvider));

class OnboardingRemoteDataSource {
  final SupabaseClient _client;
  OnboardingRemoteDataSource(this._client);

  Future<List<Map<String, dynamic>>> getSlides() async {
    final res = await _client
        .from('mobile_onboarding_slides')
        .select()
        .eq('enabled', true)
        .order('sort_order', ascending: true);
    return List<Map<String, dynamic>>.from(res);
  }
}
```

الـ `Ref` العام مش `OnboardingRemoteDataSourceRef` — زي ما الـ skill يطلب.

### الالتزام بالـ skills في الـ UI

- ✅ `AppColors` فقط — مافي HEX
- ✅ `AppDimensions` + `.w/.h/.r/.sp` — مافي أرقام خام
- ✅ `EdgeInsetsDirectional` مش `EdgeInsets`
- ✅ `.withValues(alpha:)` مش `.withOpacity()`
- ✅ Shimmer للتحميل الأولي، مش `CircularProgressIndicator`
- ✅ `AppLocalizations.of(context)!.key` لنصوص الواجهة (Skip / Continue / Retry) — نصوص الشرائح نفسها من الداتابيز
- ✅ `flutter gen-l10n` بعد أي تعديل على `.arb`
- ⚠️ الـ skill يذكر `app_en.arb` و `app_ar.arb` بس — **لازم يتحدّث ليشمل `app_pt.arb`** (موجود فعلاً)

---

## سادساً: مسار الإقلاع

**الفيديو دائماً. الـ Onboarding بشرط.**

```
                  فتح التطبيق
                       │
                       ▼
        ┌──────────────────────────────┐
        │  Splash — الفيديو يشتغل      │  ← كل مرة
        │  (~4 ثواني)                   │
        │                              │
        │  بالتوازي، لو ما شافها قبل:  │
        │  · جلب الشرائح               │
        │  · precacheImage للصور        │
        └──────────────┬───────────────┘
                       │  الفيديو خلص
                       ▼
              ┌────────────────┐
              │ شاف onboarding │──── أيوه ──────┐
              │ قبل كده؟       │                │
              └────────┬───────┘                │
                       │ لأ                     │
                       ▼                        │
              ┌────────────────┐                │
              │ الداتا وصلت    │──── لأ / فشل ──┤
              │ وفيها شرائح؟   │     / timeout  │
              └────────┬───────┘                │
                       │ أيوه                   │
                       ▼                        ▼
                ┌────────────┐            ┌──────────┐
                │ Onboarding │───يكمّل──▶ │   Home   │
                └────────────┘            └──────────┘
```

**القواعد:**

1. **الفيديو يكمل دايماً** — لو الداتا وصلت بدري ما نقطعه. ولو خلص والداتا لسه، ننتظر **ثانيتين بحد أقصى** وبعدها Home.

2. **فشل الجلب = تخطّي صامت** — لا شاشة خطأ ولا onboarding فاضية. Home مباشرة.

3. **`hasSeenOnboarding` ما تتعلّم إلا لو شافها فعلاً** ⚠️
   لو راح Home بسبب فشل، الفلاغ يفضل `false`. غير كده، أي مستخدم كان أول تشغيل عنده نت مقطوع يخسر الـ onboarding للأبد.

4. **Shimmer** أثناء تحميل الصور — ويدجت مستقلة `onboarding_shimmer.dart` زي ما الـ skill يطلب.

5. **زر Retry** لو صورة فشلت — `ref.invalidate(onboardingControllerProvider)`. النص من مفتاح `retry` الموجود.

6. **زر Skip شغّال دائماً.** الـ onboarding مش بوابة.

7. **الكاش خفيف** — آخر جلب ناجح في SharedPrefs، عشان لو قفل التطبيق في النص ورجع. يُمسح بعد الإكمال.

**ما عاد له لزوم:**
- ❌ صور fallback محلية في `assets/` — البديل عن الفشل هو Home. يوفر ~2MB
- ❌ مفاتيح `onboardingWitness`, `onboardingDesc1`… في الـ ARB — النصوص كلها من الداتابيز الآن

**ملاحظة على الفيديو:** بيتكرر مع الإقلاع البارد فقط (لو المستخدم رجع بسرعة، النظام محتفظ بالتطبيق في الذاكرة و`main()` ما تتنفذ). خليه ≤ 2MB — بيتحمّل في كل إقلاع وهو أكتر شي بيأثر على الإحساس بسرعة التطبيق.

---

## سابعاً: خطوات التنفيذ

### مرحلة 0 — الأساسات ✅ تمّت
| # | الخطوة | الحالة |
|---|---|---|
| 0.1 | حسم feature-first vs layer-first | ✅ feature-first |
| 0.2 | حسم `Result<T>` vs `Either` | ✅ Either + dartz |
| 0.3 | حسم Supabase vs Retrofit | ✅ Supabase SDK |
| 0.4 | تحديث الـ skills الثلاثة + الأمثلة | ✅ |
| 0.5 | migration `027_mobile_onboarding.sql` | ✅ جاهز للتشغيل |

### مرحلة 1 — Supabase في الموبايل (من خطة الربط)
| # | الخطوة | تقدير |
|---|---|---|
| 1.1 | `supabase_flutter` + الـ client + المفاتيح بـ `--dart-define` | 45 د |
| 1.2 | `pickLang()` helper | 20 د |
| 1.3 | `SupabaseExceptions` → `Failure` | 30 د |

### مرحلة 2 — الداشبورد
| # | الخطوة | تقدير |
|---|---|---|
| 2.1 | ~~migration `024`~~ ✅ — يتبقّى تشغيلها في SQL Editor | 5 د |
| 2.2 | `src/actions/mobile.ts` + `MOBILE_ONBOARDING_FIELDS` + `index.ts` | 1 س |
| 2.3 | Sidebar + هيكل صفحة `mobile-settings` والتابات | 45 د |
| 2.4 | `MultiImageUploader` | 1.5 س |
| 2.5 | `OnboardingEditor` + `SlideCard` + السحب والحفظ | 2 س |
| 2.6 | استخراج `LandingEditor` + تمرير viewport | 2 س |
| 2.7 | تنظيف Landing Settings | 20 د |

### مرحلة 3 — الموبايل
| # | الخطوة | تقدير |
|---|---|---|
| 3.1 | entity + model (freezed) + datasource + repository | 1.5 س |
| 3.2 | `slide_images.dart` | 1.5 س |
| 3.3 | `onboarding_page` dynamic + shimmer + retry | 1.5 س |
| 3.4 | منطق الإقلاع في splash: prefetch + timeout + توجيه | 1 س |
| 3.5 | اختبار الـ3 لغات + RTL + وضع الطيران | 1 س |

**الإجمالي: ~16 ساعة** (يومان)

---

## اللي لسه محتاج قرارك

| # | السؤال | رأيي |
|---|---|---|
| 1 | **`image_mode`** — الصور المتعددة carousel ولا mosaic؟ | محتاج جوابك — بشيل الزايدة من الـ CHECK |
| 2 | صلاحية `"settings"` تكفي ولا موديول `"mobile"` مستقل؟ | `"settings"` أبسط دلوقتي |
| 3 | `LandingEditor` — استخراج صح (ساعتين) ولا حل سريع؟ | استخراج صح؛ التكرار بيتعب بسرعة |
| 4 | العربي `enabled: false` في `content_languages` — أفعّله؟ | لازم يتفعّل عشان يظهر في التطبيق |

**السؤال #1 هو الوحيد اللي بيوقف التنفيذ.** الباقي ليها افتراضات معقولة وبقدر أمشي عليها.

---

## ملاحظات على الكود الحالي طلعت أثناء تزبيط الـ skills

دي مخالفات موجودة دلوقتي وصارت الـ skills تمنعها صراحةً. مش جزء من شغل الـ Onboarding، بس لازم تتصلح:

| الملف | المشكلة |
|---|---|
| `home_page.dart` | `data: (_) =>` — بيرمي الداتا اللي جابها الكنترولر، وكل الـ UI hardcoded |
| `home_page.dart` | 1135 سطر — أكتر من ضعف الحد (400) |
| `home_page.dart` | `error:` بيعرض `Text(err.toString())` بدل `ErrorRetryWidget` |
| `splash_page.dart` | `print()` ×3 — مخالف لـ `avoid_print` في `analysis_options.yaml` |
| `splash_page.dart` | فحص `hasSeenOnboarding` معطّل بتعليق |
| كل الصفحات | `EdgeInsets` بدل `EdgeInsetsDirectional` — بيكسر العربي |
| 6 ملفات | روابط unsplash / picsum / pravatar |
| 7 صفحات | صفر استخدام لـ `AppLocalizations` |

---

## سجل القرارات

| التاريخ | القرار |
|---|---|
| 31 أغسطس | صفحة **Mobile Settings** تحت Landing Settings — مش تاب جوّه Landing Settings |
| 31 أغسطس | تاباتها: Onboarding + Mobile Landing |
| 31 أغسطس | جدول `mobile_onboarding_slides` مستقل |
| 31 أغسطس | النص الملون = آخر جزء فقط، حقلان منفصلان، بدون markup |
| 31 أغسطس | فيديو الـ splash كل فتحة للتطبيق |
| 31 أغسطس | فشل جلب الـ Onboarding ⇒ Home، و`hasSeenOnboarding` تفضل `false` |
| 31 أغسطس | الداشبورد يمشي على نمط `src/actions/` (server actions + guard + validate) |
| 31 أغسطس | **feature-first** — `lib/layers/{feature}/domain\|data\|presentation/`. الـ skill اتصلح |
| 31 أغسطس | **`Either<Failure, T>` + dartz** — مش `Result<T>` tuple. الـ skill اتصلح |
| 31 أغسطس | **Supabase SDK** لكل جداول DSH؛ Dio+Retrofit للـ APIs الخارجية فقط. الـ skill اتصلح |
