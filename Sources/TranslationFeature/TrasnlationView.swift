//
//  TranslationViewModel.swift
//  LLML
//
//  Created by Watanabe Toshinori on 2025/02/15.
//

import AccessibilityClient
import AppSettingsClient
import AppleTranslateClient
@preconcurrency import Combine
import Language
import Observation
import OllamaClient
import OpenAIClient
import PasteboardClient
import SwiftUI
@preconcurrency import Translation

@MainActor
@Observable
public class TranslationViewModel {
    enum AppLayout: String {
        case horizontal
        case vertical
    }

    // Properties

    private(set) var translationProvider: TranslationProvider = .openAI {
        didSet {
            translatedText = ""
        }
    }

    private var sourceLanguage: Language = .none

    private var targetLanguage: Language = .none

    private(set) var appLayout: AppLayout?

    // SwiftUI’s standard controls do not have a direct equivalent to `hasMarkedText`.
    // Instead, a two-way binding is used to capture the confirmed text after conversion.
    var sourceText = "" {
        didSet {
            sourceTextSubject.send(sourceText)
        }
    }

    private(set) var translatedText = ""

    private(set) var isLoading = false

    private(set) var settingsAlertMessage: String?

    private(set) var alertMessage: String?

    private(set) var autoExecuteTranslation = true

    private(set) var translationConfiguration: AppleTranslateConfiguration = {
        if #available(macOS 15.0, *) {
            .init(rawValue: TranslationSession.Configuration())
        } else {
            .init(rawValue: "Undefined")
        }
    }()

    var currentSourceLanguage: Language {
        if translationProvider == .appleTranslate, sourceLanguage.identifier.isEmpty {
            .automatic
        } else {
            sourceLanguage
        }
    }

    var currentTargetLanguage: Language {
        if translationProvider == .appleTranslate, targetLanguage.identifier.isEmpty {
            .english_american
        } else {
            targetLanguage
        }
    }

    var languages1: [Language] {
        let languages =
            if translationProvider == .appleTranslate {
                Language.allCases.filter({ !$0.identifier.isEmpty })
            } else {
                Language.allCases.filter { $0 != .none }
            }
        return Array(languages[0..<languages.count / 3])
    }

    var languages2: [Language] {
        let languages =
            if translationProvider == .appleTranslate {
                Language.allCases.filter({ !$0.identifier.isEmpty })
            } else {
                Language.allCases.filter { $0 != .none }
            }
        return Array(languages[languages.count / 3..<(languages.count / 3 * 2)])
    }

    var languages3: [Language] {
        let languages =
            if translationProvider == .appleTranslate {
                Language.allCases.filter({ !$0.identifier.isEmpty })
            } else {
                Language.allCases.filter { $0 != .none }
            }
        return Array(languages[(languages.count / 3 * 2)..<languages.count])
    }

    @ObservationIgnored
    private var accessibilityEnabled = false {
        didSet {
            pasteboardObservationConditionDidChanged()
        }
    }

    @ObservationIgnored
    private var shortcutEnabled = false {
        didSet {
            pasteboardObservationConditionDidChanged()
        }
    }

    @ObservationIgnored
    private var translationProviderObservationTask: Task<Void, Never>?

    @ObservationIgnored
    private var accessibilityObservationTask: Task<Void, Never>?

    @ObservationIgnored
    private var shortcutEnabledObservationTask: Task<Void, Never>?

    @ObservationIgnored
    private var sourceLanguageObservationTask: Task<Void, Never>?

    @ObservationIgnored
    private var targetLanguageObservationTask: Task<Void, Never>?

    @ObservationIgnored
    private var appLayoutObservationTask: Task<Void, Never>?

    @ObservationIgnored
    private var autoExecuteTranslationObservationTask: Task<Void, Never>?

    @ObservationIgnored
    private var pasteboardObservationTask: Task<Void, Never>?

    @ObservationIgnored
    private var sourceTextSubject = CurrentValueSubject<String, Never>("")

    @ObservationIgnored
    private var translationConfigurationObservationTask: Task<Void, Never>?

    @ObservationIgnored
    private var cancellables = Set<AnyCancellable>()

    // Clients

    @ObservationIgnored
    private var accessibilityClient: AccessibilityClient

    @ObservationIgnored
    private var appSettingsClient: AppSettingsClient

    @ObservationIgnored
    private var pasteboardClient: PasteboardClient

    @ObservationIgnored
    private var openAIClient: OpenAIClient

    @ObservationIgnored
    private var ollamaClient: OllamaClient

    @ObservationIgnored
    private var appleTranslateClient: AppleTranslateClient

    // Initializing

    public init(
        accessibilityClient: AccessibilityClient = .liveValue,
        appSettingsClient: AppSettingsClient = .liveValue,
        pasteboardClient: PasteboardClient = .liveValue,
        openAIClient: OpenAIClient = .liveValue,
        ollamaClient: OllamaClient = .liveValue,
        appleTranslateClient: AppleTranslateClient = .liveValue
    ) {
        self.accessibilityClient = accessibilityClient
        self.appSettingsClient = appSettingsClient
        self.pasteboardClient = pasteboardClient
        self.openAIClient = openAIClient
        self.ollamaClient = ollamaClient
        self.appleTranslateClient = appleTranslateClient

        // Observes status updates from Client
        translationProviderObservationTask = Task {
            for await value in appSettingsClient.translationProvider() {
                translationProvider = TranslationProvider(rawValue: value.rawValue) ?? .openAI
            }
        }

        accessibilityObservationTask = Task {
            for await value in accessibilityClient.statuses() {
                accessibilityEnabled = value
            }
        }

        shortcutEnabledObservationTask = Task {
            for await value in appSettingsClient.shortcutEnabled() {
                shortcutEnabled = value
            }
        }

        autoExecuteTranslationObservationTask = Task {
            for await value in appSettingsClient.autoExecuteTranslation() {
                autoExecuteTranslation = value
            }
        }

        sourceTextSubject
            .debounce(for: .milliseconds(750), scheduler: RunLoop.main)
            .sink { [weak self] value in
                guard let self else { return }
                guard autoExecuteTranslation else { return }
                executeTranslation(value)
            }
            .store(in: &cancellables)

        sourceLanguageObservationTask = Task {
            for await value in appSettingsClient.sourceLanguage() {
                sourceLanguage = Language(rawValue: value) ?? .english_american
                if #available(macOS 15.0, *) {
                    appleTranslateClient.updateLanguages(sourceLanguage, targetLanguage)
                }
            }
        }

        targetLanguageObservationTask = Task {
            for await value in appSettingsClient.targetLanguage() {
                targetLanguage = Language(rawValue: value) ?? .english_american
                if #available(macOS 15.0, *) {
                    appleTranslateClient.updateLanguages(sourceLanguage, targetLanguage)
                }
            }
        }

        appLayoutObservationTask = Task {
            for await value in appSettingsClient.appLayout() {
                appLayout = AppLayout(rawValue: value.rawValue)
            }
        }

        translationConfigurationObservationTask = Task {
            for await value in appleTranslateClient.configuration() {
                translationConfiguration = value
            }
        }
    }

    // Actions

    func sourceLanguageDidSelected(_ newValue: Language) {
        guard sourceLanguage != newValue else { return }
        Task {
            await appSettingsClient.setSourceLanguage(newValue.rawValue)
        }
    }

    func targetLanguageDidSelected(_ newValue: Language) {
        guard targetLanguage != newValue else { return }
        Task {
            await appSettingsClient.setTargetLanguage(newValue.rawValue)
        }
    }

    func switchLanguageTapped() {
        guard sourceLanguage != targetLanguage, sourceLanguage != .automatic else { return }

        Task {
            await appSettingsClient.setSourceLanguage(targetLanguage.rawValue)
            await appSettingsClient.setTargetLanguage(sourceLanguage.rawValue)

            let sourceText = self.sourceText
            let translatedText = self.translatedText
            self.sourceText = translatedText
            self.translatedText = sourceText
        }
    }

    func clearButtonTapped() {
        sourceText = ""
        translatedText = ""
    }

    func translationSessionDidChanged(_ session: AppleTranslateSession) {
        Task {
            await appleTranslateClient.setSession(session)
        }
    }

    func translationModeTapped() {
        Task {
            await appSettingsClient.setAutoExecuteTranslation(!autoExecuteTranslation)
        }
    }

    func translateTapped() {
        guard !isLoading else { return }
        executeTranslation(sourceText)
    }

    // Inner Actions

    private func pasteboardObservationConditionDidChanged() {
        if accessibilityEnabled, shortcutEnabled {
            // Start observing pasteboard changes
            guard pasteboardObservationTask == nil else { return }
            pasteboardObservationTask = Task {
                for await value in pasteboardClient.values() {
                    pasteboardDidChanged(value)
                }
            }
        } else {
            // Cancel observation
            pasteboardObservationTask?.cancel()
            pasteboardObservationTask = nil
        }
    }

    private func pasteboardDidChanged(_ newValue: PasteboardItem) {
        Task {
            // Prohibit processing of items sent from excluded apps.
            let apps = await appSettingsClient.excludedApps()
            if apps.contains(where: { $0 == newValue.bundleIdentifier }) {
                return
            }

            sourceText = newValue.string
            translatedText = ""

            await appSettingsClient.appWindowMakeActive()
        }
    }

    private func executeTranslation(_ newValue: String) {
        Task {
            defer {
                isLoading = false
            }
            do {
                isLoading = true

                alertMessage = nil
                settingsAlertMessage = nil

                if sourceLanguage == targetLanguage {
                    translatedText = sourceText
                    return
                }

                let sourceText = self.sourceText
                let translatedText: String
                switch translationProvider {
                case .openAI:
                    translatedText = try await openAIClient.translate(sourceLanguage, targetLanguage, sourceText)
                case .ollama:
                    translatedText = try await ollamaClient.translate(sourceLanguage, targetLanguage, sourceText)
                case .appleTranslate:
                    translatedText = try await appleTranslateClient.translate(sourceLanguage, targetLanguage, sourceText)
                }

                if sourceText == self.sourceText {
                    self.translatedText = translatedText
                }
            } catch {
                // Display error if translation fails
                if let openAIError = error as? OpenAIClientError, case .invalidSettings = openAIError {
                    settingsAlertMessage = "\(openAIError.localizedDescription)"
                } else if let ollamaError = error as? OllamaClientError, case .invalidSettings = ollamaError {
                    settingsAlertMessage = "\(ollamaError.localizedDescription)"
                } else {
                    alertMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}

public struct TranslationView: View {
    @Bindable var viewModel: TranslationViewModel

    @FocusState private var isSourceTextEditorFocused: Bool

    @FocusState private var isTranslatedTextEditorFocused: Bool

    @State var needsAdjustSourceFontSize: Bool = false

    @State var needsAdjustTargetFontSize: Bool = false

    @State private var isSettingsLinkHovered = false

    @State private var hoveredSourceLanguage: Language? = nil

    @State private var hoveredTargetLanguage: Language? = nil

    @State private var showsSourceLanguageList: Bool = false

    @State private var showsTargetLanguageList: Bool = false

    public init(viewModel: TranslationViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        if #available(macOS 15.0, *) {
            core
                .translationTask(viewModel.translationConfiguration.translationSessionConfiguration) { session in
                    viewModel.translationSessionDidChanged(AppleTranslateSession(rawValue: session))
                }
        } else {
            core
        }
    }

    private var core: some View {
        VStack(spacing: 0) {
            headerToolBar
                .onTapGesture {
                    showsSourceLanguageList = false
                    showsTargetLanguageList = false
                }

            ZStack {
                translationEditorsArea
                    .padding(.horizontal, -1)
                sourceLanguageList
                targetLanguageList
                messageArea
            }

            bottomTootlBar
                .onTapGesture {
                    showsSourceLanguageList = false
                    showsTargetLanguageList = false
                }
        }
        .onChange(of: viewModel.sourceText) { _, _ in
            isSourceTextEditorFocused = true
        }
        .onChange(of: isSourceTextEditorFocused) { _, newValue in
            if newValue {
                showsTargetLanguageList = false
            }
        }
        .onChange(of: isTranslatedTextEditorFocused) { _, newValue in
            if newValue {
                showsSourceLanguageList = false
            }
        }
        .onAppear {
            isSourceTextEditorFocused = true
        }
    }

    private var headerToolBar: some View {
        HStack(spacing: 0) {
            // Left
            HStack(spacing: 0) {
                Spacer()

                HoveredButton(action: {
                    showsSourceLanguageList.toggle()
                    isSourceTextEditorFocused = false
                    isTranslatedTextEditorFocused = false
                }) {
                    Text(viewModel.currentSourceLanguage.name)
                        .fontWeight(.semibold)
                        .frame(height: 40)
                        .padding(.horizontal)
                }
            }
            .frame(maxWidth: .infinity)

            // Middle
            HoveredButton(action: {
                viewModel.switchLanguageTapped()
            }) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.body)
                    .padding(10)
                    .frame(width: 40, height: 40)
                    .layoutPriority(1)
            }

            // Right
            HStack(spacing: 0) {
                HoveredButton(action: {
                    showsTargetLanguageList.toggle()
                    isSourceTextEditorFocused = false
                    isTranslatedTextEditorFocused = false
                }) {
                    Text(viewModel.currentTargetLanguage.name)
                        .fontWeight(.semibold)
                        .frame(height: 40)
                        .padding(.horizontal)
                }

                Spacer()

                // Settings button
                SettingsLink {
                    Image(systemName: "gearshape")
                        .font(.title2)
                        .padding(10)
                }
                .buttonStyle(.link)
                .foregroundStyle(.primary)
                .background(isSettingsLinkHovered ? Color(NSColor.unemphasizedSelectedContentBackgroundColor) : Color.clear)
                .cornerRadius(8)
                .onHover { isHovered in
                    self.isSettingsLinkHovered = isHovered
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color(NSColor.windowBackgroundColor))
    }

    @ViewBuilder private var translationEditorsArea: some View {
        switch viewModel.appLayout {
        case .horizontal:
            HStack(spacing: 0) {
                translationEditors
            }
        case .vertical:
            VStack(spacing: 0) {
                translationEditors
            }
        default:
            EmptyView()
        }
    }

    private var translationEditors: some View {
        Group {
            // Source Text
            Group {
                TextEditor(text: $viewModel.sourceText)
                    .font(needsAdjustSourceFontSize ? .title3 : .title)
                    .lineSpacing(8)
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.never)
                    .focused($isSourceTextEditorFocused)
                    .overlay(alignment: .topLeading) {
                        Text("Type or paste text to translate")
                            .font(.title)
                            .foregroundStyle(.secondary)
                            .opacity(viewModel.sourceText.isEmpty ? 1 : 0)
                            .padding(.horizontal, 4)
                    }
                    .background(
                        // Adjusts font size dynamically based on the number of characters
                        ViewThatFits(in: .vertical) {
                            TextEditor(text: Binding(get: { viewModel.sourceText }, set: { _ in }))
                                .font(.title)
                                .lineSpacing(8)
                                .opacity(0)
                            Color.clear
                                .onAppear {
                                    needsAdjustSourceFontSize = true
                                }
                                .onDisappear {
                                    needsAdjustSourceFontSize = false
                                }
                        }
                    )
                    .padding(.vertical)
                    .padding(.leading)
                    .padding(.trailing, 24)
            }
            .overlay(alignment: .topTrailing) {
                // Clear button
                HoveredButton(action: viewModel.clearButtonTapped) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20))
                        .padding(6)
                }
                .padding(2)
                .opacity(viewModel.sourceText.isEmpty ? 0 : 1)
                .disabled(viewModel.sourceText.isEmpty)
            }
            .border(isSourceTextEditorFocused ? Color.blue.opacity(0.8) : Color.gray.opacity(0.3), width: 1)

            // Translated text
            Group {
                TextEditor(text: Binding(get: { viewModel.translatedText }, set: { _ in }))
                    .font(needsAdjustTargetFontSize ? .title3 : .title)
                    .lineSpacing(8)
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.never)
                    .focused($isTranslatedTextEditorFocused)
                    .overlay(alignment: .center) {
                        if viewModel.translatedText.isEmpty {
                            VStack(alignment: .center) {
                                Text("LLM-powered Language translator")
                                    .foregroundStyle(.secondary)

                                HStack {
                                    Spacer()

                                    Image("MenuIcon")
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.indigo, .teal],
                                                startPoint: .topLeading, endPoint: .bottomTrailing

                                            )
                                        )
                                    Text("LLML")
                                        .fontWeight(.bold)
                                        .font(.body)
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.teal, .indigo],
                                                startPoint: .topLeading, endPoint: .bottomTrailing

                                            )
                                        )

                                    Spacer()
                                }
                            }
                        }
                    }
                    .overlay(alignment: .bottom) {
                        if viewModel.isLoading {
                            Image(systemName: "ellipsis")
                                .symbolEffect(.variableColor.reversing.cumulative, options: .repeating)
                                .font(.largeTitle)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color(NSColor.windowBackgroundColor))
                                .cornerRadius(12)
                        }
                    }
                    .background(
                        // Adjusts font size dynamically based on the number of characters
                        ViewThatFits(in: .vertical) {
                            TextEditor(text: Binding(get: { viewModel.translatedText }, set: { _ in }))
                                .font(.title)
                                .lineSpacing(8)
                                .opacity(0)
                            Color.clear
                                .onAppear {
                                    needsAdjustTargetFontSize = true
                                }
                                .onDisappear {
                                    needsAdjustTargetFontSize = false
                                }
                        }
                    )
                    .padding(.vertical)
                    .padding(.leading)
                    .padding(.trailing, 24)
            }
            .border(isTranslatedTextEditorFocused ? Color.blue.opacity(0.8) : Color.gray.opacity(0.3), width: 1)
        }
    }

    private var sourceLanguageList: some View {
        HStack(spacing: 0) {
            Group {
                ScrollView {
                    HStack(spacing: 0) {
                        LanguageList(
                            selectedLanguage: viewModel.currentSourceLanguage,
                            hoverLanguage: $hoveredSourceLanguage,
                            languages: viewModel.languages1,
                            action: {
                                viewModel.sourceLanguageDidSelected($0)
                                showsSourceLanguageList = false
                            }
                        )
                        LanguageList(
                            selectedLanguage: viewModel.currentSourceLanguage,
                            hoverLanguage: $hoveredSourceLanguage,
                            languages: viewModel.languages2,
                            action: {
                                viewModel.sourceLanguageDidSelected($0)
                                showsSourceLanguageList = false
                            }
                        )
                        LanguageList(
                            selectedLanguage: viewModel.currentSourceLanguage,
                            hoverLanguage: $hoveredSourceLanguage,
                            languages: viewModel.languages3,
                            action: {
                                viewModel.sourceLanguageDidSelected($0)
                                showsSourceLanguageList = false
                            }
                        )
                    }
                }
                .background(.ultraThickMaterial)
                .cornerRadius(8)
            }
            .padding(.horizontal, 4)
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 2)
            .containerRelativeFrame(.horizontal, count: 2, span: 1, spacing: 0)

            Spacer()
        }
        .opacity(showsSourceLanguageList ? 1 : 0)
    }

    private var targetLanguageList: some View {
        HStack(spacing: 0) {
            Spacer()

            Group {
                ScrollView {
                    HStack(spacing: 0) {
                        LanguageList(
                            selectedLanguage: viewModel.currentTargetLanguage,
                            hoverLanguage: $hoveredTargetLanguage,
                            languages: Array(viewModel.languages1.dropFirst()),  // remove `autodetect`
                            action: {
                                viewModel.targetLanguageDidSelected($0)
                                showsTargetLanguageList = false
                            }
                        )
                        LanguageList(
                            selectedLanguage: viewModel.currentTargetLanguage,
                            hoverLanguage: $hoveredTargetLanguage,
                            languages: viewModel.languages2,
                            action: {
                                viewModel.targetLanguageDidSelected($0)
                                showsTargetLanguageList = false
                            }
                        )
                        LanguageList(
                            selectedLanguage: viewModel.currentTargetLanguage,
                            hoverLanguage: $hoveredTargetLanguage,
                            languages: viewModel.languages3,
                            action: {
                                viewModel.targetLanguageDidSelected($0)
                                showsTargetLanguageList = false
                            }
                        )
                    }
                }
                .background(.ultraThickMaterial)
                .cornerRadius(8)
            }
            .padding(.horizontal, 4)
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 2)
            .containerRelativeFrame(.horizontal, count: 2, span: 1, spacing: 0)
        }
        .opacity(showsTargetLanguageList ? 1 : 0)
    }

    private var messageArea: some View {
        VStack(alignment: .center) {
            Spacer()

            // Settings alert
            if let alertMessage = viewModel.settingsAlertMessage {
                AlertMessageView(type: .settings, message: alertMessage)
                    .padding(.horizontal)
            }

            // Error alert
            if let alertMessage = viewModel.alertMessage {
                AlertMessageView(type: .error, message: alertMessage)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }

    private var bottomTootlBar: some View {
        HStack(spacing: 0) {
            // Left
            HStack(spacing: 0) {
                HStack(spacing: 0) {
                    HoveredButton(action: {
                        viewModel.translationModeTapped()
                    }) {
                        Image(systemName: viewModel.autoExecuteTranslation ? "autostartstop" : "autostartstop.slash")
                            .font(.system(size: 20))
                            .frame(height: 40)
                            .padding(.horizontal)
                    }

                    Spacer()
                }

                if !viewModel.autoExecuteTranslation {
                    HoveredButton(action: {
                        viewModel.translateTapped()
                    }) {
                        Text("Translate")
                            .fontWeight(.semibold)
                            .frame(width: 80, height: 40)
                            .padding(.horizontal)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.secondary, lineWidth: 1)
                    )
                    .layoutPriority(1)
                }

                HStack(spacing: 0) {
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)

            // Right
            HStack(spacing: 0) {
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .padding(4)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
