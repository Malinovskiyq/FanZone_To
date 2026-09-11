import SwiftUI

// MARK: - Auth Root

struct AuthRootView: View {
    var body: some View {
        NavigationStack {
            LoginView()
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Login View

struct LoginView: View {
    @StateObject private var vm = AuthViewModel()
    @State private var emailOrPhone = ""
    @State private var password     = ""
    @State private var showRegister      = false
    @State private var showForgotPassword = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // MARK: Logo
                    VStack(spacing: 12) {
                        Image(systemName: "hockey.puck.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(AppTheme.heroGradient)
                        VStack(spacing: 4) {
                            Text("ХК СИБИРЬ")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .tracking(4)
                            Text("FanZone")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                                .tracking(2)
                        }
                    }
                    .padding(.top, 60)

                    // MARK: Form
                    VStack(spacing: 14) {
                        FZTextField(
                            placeholder: "Email или телефон",
                            text: $emailOrPhone,
                            icon: "person",
                            keyboardType: .emailAddress,
                            autocapitalization: .never
                        )

                        FZTextField(
                            placeholder: "Пароль",
                            text: $password,
                            icon: "lock",
                            isSecure: true
                        )

                        HStack {
                            Spacer()
                            Button("Забыли пароль?") { showForgotPassword = true }
                                .font(.footnote)
                                .foregroundColor(AppTheme.brandPrimary)
                        }
                    }

                    // MARK: Actions
                    VStack(spacing: 14) {
                        FZPrimaryButton("ВОЙТИ", isLoading: vm.isLoading) {
                            Task { await vm.login(emailOrPhone: emailOrPhone, password: password) }
                        }

                        HStack(spacing: 4) {
                            Text("Нет аккаунта?")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                            Button("Зарегистрироваться") { showRegister = true }
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(AppTheme.brandPrimary)
                        }
                    }
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .alert("Ошибка", isPresented: $vm.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage)
        }
        .navigationDestination(isPresented: $showRegister) { RegisterView() }
        .navigationDestination(isPresented: $showForgotPassword) { ForgotPasswordView() }
        .navigationBarHidden(true)
    }
}

// MARK: - Register View

struct RegisterView: View {
    @StateObject private var vm = AuthViewModel()
    @State private var firstName  = ""
    @State private var lastName   = ""
    @State private var username   = ""
    @State private var email      = ""
    @State private var phone      = ""
    @State private var password   = ""
    @State private var confirm    = ""
    @State private var useEmail   = true
    @Environment(\.dismiss) private var dismiss

    var isValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !username.isEmpty &&
        !password.isEmpty && password == confirm &&
        (useEmail ? !email.isEmpty : !phone.isEmpty)
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 6) {
                        Text("Регистрация")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.white)
                        Text("Создайте аккаунт болельщика")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.top, 16)

                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            FZTextField(placeholder: "Имя", text: $firstName)
                            FZTextField(placeholder: "Фамилия", text: $lastName)
                        }
                        FZTextField(
                            placeholder: "Никнейм", text: $username,
                            icon: "at", autocapitalization: .never
                        )

                        // Email / Phone toggle
                        Picker("", selection: $useEmail) {
                            Text("Email").tag(true)
                            Text("Телефон").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .padding(.vertical, 4)

                        if useEmail {
                            FZTextField(
                                placeholder: "Email", text: $email,
                                icon: "envelope", keyboardType: .emailAddress,
                                autocapitalization: .never
                            )
                        } else {
                            FZTextField(
                                placeholder: "+7 (999) 000-00-00", text: $phone,
                                icon: "phone", keyboardType: .phonePad
                            )
                        }

                        FZTextField(
                            placeholder: "Пароль", text: $password,
                            icon: "lock", isSecure: true
                        )
                        FZTextField(
                            placeholder: "Повторите пароль", text: $confirm,
                            icon: "lock.fill", isSecure: true
                        )

                        if !confirm.isEmpty && password != confirm {
                            Text("Пароли не совпадают")
                                .font(.caption)
                                .foregroundColor(AppTheme.error)
                        }
                    }

                    FZPrimaryButton("ЗАРЕГИСТРИРОВАТЬСЯ", isLoading: vm.isLoading) {
                        Task {
                            await vm.register(
                                email: useEmail ? email : nil,
                                phone: useEmail ? nil : phone,
                                username: username,
                                firstName: firstName,
                                lastName: lastName,
                                password: password
                            )
                        }
                    }
                    .disabled(!isValid)
                    .opacity(isValid ? 1 : 0.5)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationTitle("Регистрация")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert("Ошибка", isPresented: $vm.showError) {
            Button("OK") {}
        } message: { Text(vm.errorMessage) }
    }
}

// MARK: - Forgot Password View

struct ForgotPasswordView: View {
    @State private var emailOrPhone = ""
    @State private var isSent = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 48))
                        .foregroundColor(AppTheme.brandPrimary)
                    Text("Восстановление пароля")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)
                    Text("Введите email или телефон, который вы использовали при регистрации")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 16)

                if isSent {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 52))
                            .foregroundColor(AppTheme.success)
                        Text("Инструкции отправлены")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Проверьте почту или SMS")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                } else {
                    FZTextField(
                        placeholder: "Email или телефон",
                        text: $emailOrPhone,
                        icon: "envelope",
                        keyboardType: .emailAddress,
                        autocapitalization: .never
                    )

                    FZPrimaryButton("ОТПРАВИТЬ", isLoading: isLoading) {
                        Task {
                            isLoading = true
                            do {
                                try await APIClient.shared.requestEmpty(.forgotPassword(emailOrPhone: emailOrPhone))
                                isSent = true
                            } catch {
                                errorMessage = error.localizedDescription
                                showError = true
                            }
                            isLoading = false
                        }
                    }
                    .disabled(emailOrPhone.isEmpty)
                    .opacity(emailOrPhone.isEmpty ? 0.5 : 1)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .navigationTitle("Восстановление")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert("Ошибка", isPresented: $showError) {
            Button("OK") {}
        } message: { Text(errorMessage) }
    }
}

// MARK: - Auth ViewModel

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isLoading   = false
    @Published var showError   = false
    @Published var errorMessage = ""

    func login(emailOrPhone: String, password: String) async {
        guard !emailOrPhone.isEmpty, !password.isEmpty else {
            showError(message: "Заполните все поля")
            return
        }
        isLoading = true
        do {
            try await AuthManager.shared.login(emailOrPhone: emailOrPhone, password: password)
        } catch {
            showError(message: error.localizedDescription)
        }
        isLoading = false
    }

    func register(
        email: String?, phone: String?,
        username: String, firstName: String, lastName: String, password: String
    ) async {
        isLoading = true
        do {
            try await AuthManager.shared.register(
                email: email, phone: phone, username: username,
                firstName: firstName, lastName: lastName, password: password
            )
        } catch {
            showError(message: error.localizedDescription)
        }
        isLoading = false
    }

    private func showError(message: String) {
        errorMessage = message
        showError    = true
    }
}
