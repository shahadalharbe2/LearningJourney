//
//  OnboardingView.swift
//  LearningJourney
//
//  Created by shahad on 02/06/1448 AH.
//

// شاشة البداية: تستقبل اسم الهدف ومدته، ثم تحفظه قبل الانتقال إلى النشاط.
import SwiftUI
import SwiftData

struct OnboardingView: View {
    // يصل إلى سياق SwiftData المستخدم لقراءة البيانات وحفظها داخل هذه الشاشة.
    @Environment(\.modelContext) private var modelContext
    // يغلق الشاشة المعروضة عند الرجوع أو بعد نجاح الحفظ.
    @Environment(\.dismiss) private var dismiss
    // يجمع استدعاءات منطق التطبيق في كائن ViewModel بدل تنفيذ الحفظ والحساب داخل الأزرار.
    private let viewModel = LearningGoalViewModel()
    // يربط الشاشة بقائمة الأهداف المحفوظة؛ لا يمثل قائمة اختبار مستقلة.
    @Query private var savedGoals: [LearningGoal]
    // نسخة محلية من اسم الهدف أثناء الكتابة؛ لا تحفظ كل ضغطة مباشرة في قاعدة البيانات.
    @State private var goalTitle = ""
    // يحفظ اختيار المدة أثناء التفاعل مع الشاشة.
    @State private var selectedDuration: LearningDuration = .week
    // يتابع تركيز حقل النص ليسمح بإغلاق لوحة المفاتيح.
    @FocusState private var isGoalFocused: Bool

    private let orange = Color(red: 1, green: 146.0 / 255, blue: 48.0 / 255)
    // يفعل زر البدء فقط إذا بقي حرف بعد إزالة الفراغات والأسطر الجديدة.
    private var hasGoal: Bool {
        !goalTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // يبني عناصر هذه الشاشة من حالة الواجهة والبيانات الحالية.
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // هوية شاشة البداية: رمز النار والعنوان والوصف.
                        Image(systemName: "flame.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(orange)
                            .frame(maxWidth: .infinity)
                            .padding(.top, geometry.size.height * 0.08)
                            .padding(.bottom, geometry.size.height * 0.105)

                        Text("Hello \(Text("Learner").bold())")
                            .font(.system(size: 34))
                        Text("This app will help you learn everyday!")
                            .font(.system(size: 17))
                            .foregroundStyle(Color(white: 0.6))
                            .padding(.top, 4)

                        VStack(alignment: .leading, spacing: 16) {
                            Text("I want to learn")
                            // حقل الهدف؛ إغلاق لوحة المفاتيح لا يعني أن الهدف حفظ بعد.
                            TextField("", text: $goalTitle, prompt: Text("Swift").foregroundStyle(Color(white: 0.3)))
                                .textFieldStyle(.plain)
                                .focused($isGoalFocused)
                                .tint(orange)
                                .submitLabel(.done)
                                .onSubmit { isGoalFocused = false }
                                .accessibilityLabel("Learning goal")
                            Rectangle()
                                .fill(Color(white: 0.22))
                                .frame(height: 0.5)
                        }
                        .padding(.top, 32)

                        VStack(alignment: .leading, spacing: 14) {
                            Text("I want to learn it in a")
                            HStack(spacing: 12) {
                                durationButton("Week", duration: .week)
                                durationButton("Month", duration: .month)
                                durationButton("Year", duration: .year)
                            }
                        }
                        .padding(.top, 32)
                    }
                    .font(.system(size: 17))
                    .padding(.horizontal, 18)
                    .padding(.bottom, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollDismissesKeyboard(.interactively)
                // يثبت زر البدء والنص المساعد قرب أسفل المساحة الآمنة للشاشة.
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    VStack(spacing: 12) {
                        Button {
                            isGoalFocused = false
                            if viewModel.saveGoal(
                                title: goalTitle,
                                duration: selectedDuration,
                                context: modelContext
                            ) {
                                dismiss()
                            }
                        } label: {
                            Text("Start Learning")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 22)
                                .frame(height: 46)
                                .background(orange.gradient, in: Capsule())
                                .overlay(Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .disabled(!hasGoal)

                        Text("You can edit your desire later")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(white: 0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                    .background(.black)
                }
            }
            .background(Color.black.ignoresSafeArea())
            .foregroundStyle(.white)
            .toolbar(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    // يبني زر مدة التعلم، ويغير مظهر الخيار المحدد وقيمته المحلية عند الضغط.
    private func durationButton(_ title: String, duration: LearningDuration) -> some View {
        let isSelected = selectedDuration == duration
        return Button {
            selectedDuration = duration
        } label: {
            Text(title)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(isSelected ? .white : Color(white: 0.4))
                .padding(.horizontal, 22)
                .frame(height: 46)
                .glassEffect(
                    .regular.tint(isSelected ? orange : Color(white: 0.08)).interactive(),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// معاينة في Xcode ببيانات منفصلة عن بيانات المستخدم؛ لا تستخدم لاختبار الحفظ الدائم.
#Preview("Onboarding - Test") {
    let container = try! ModelContainer(
        for: LearningGoal.self, LearningDay.self,
        configurations: ModelConfiguration(
            isStoredInMemoryOnly: true
        )
    )

    return ContentView()
        .modelContainer(container)
}
