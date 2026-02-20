//
//  DocumentViewModel+QuizSession.swift
//  AutoQuiz
//

import Foundation

extension DocumentViewModel {
    func startQuiz(with settings: QuizSettings = .default) {
        currentQuizSettings = settings
        selectedQuestionType = settings.questionType

        let desiredLanguageMode: Generator.QuizGenerationLanguageMode
        if let fallbackIdentifier = item.preferredFallbackLanguageIdentifier {
            desiredLanguageMode = .specificLanguage(Locale.Language(identifier: fallbackIdentifier))
        } else {
            desiredLanguageMode = settings.useOriginalLanguage ? .detectedDocumentLanguage : .appLocale(.current)
        }

        if activeGenerationLanguageMode != desiredLanguageMode {
            item.questions.removeAll()
            item.trueFalseQuestions?.removeAll()
            persistItemChanges()
            stopBackgroundGeneration()
            startBackgroundGeneration(languageMode: desiredLanguageMode)
        } else if backgroundGenerationTask == nil {
            startBackgroundGeneration(languageMode: desiredLanguageMode)
        }

        hasStartedQuiz = false
        currentQuestionIndex = 0
        currentSessionAnswers.removeAll()
        currentSessionAnsweredQuestions.removeAll()
        currentSessionQuestions.removeAll()
        currentQuestionStartedAt = nil
        lastAnswerCorrect = nil
        isWaitingForNextQuestion = false
        showingResults = false

        currentQuizSession = QuizSession(
            documentID: item.id,
            questionType: settings.questionType,
            maxQuestions: settings.maxQuestions,
            isUnlimitedQuestions: settings.isUnlimitedQuestions,
            shuffleQuestions: settings.shuffleQuestions,
            includeFailedQuestions: settings.includeFailedQuestions,
            sourceContentRevision: item.contentRevision
        )

        persistQuizSession()

        prepareQuizSession()

        hasStartedQuiz = true
        currentQuestionStartedAt = Date()
        lastKnownQuestionCount = currentQuestionCounts
    }

    private func prepareQuizSession() {
        currentSessionQuestions.removeAll()

        var availableQuestions: [QuizQuestion] = []

        switch currentQuizSettings.questionType {
        case .multipleChoice:
            availableQuestions = item.questions.enumerated().map { index, question in
                QuizQuestion.multipleChoice(question, originalIndex: index)
            }
        case .trueFalse:
            availableQuestions = (item.trueFalseQuestions ?? []).enumerated().map { index, question in
                QuizQuestion.trueFalse(question, originalIndex: index)
            }
        case .spacedRepetition:
            availableQuestions = []
        }

        if currentQuizSettings.includeFailedQuestions {
            let failedQuestions = getFailedQuestionsFromHistory()
            availableQuestions.append(contentsOf: failedQuestions)
        }

        if currentQuizSettings.shuffleQuestions {
            availableQuestions.shuffle()
        }

        if !currentQuizSettings.isUnlimitedQuestions {
            availableQuestions = Array(availableQuestions.prefix(currentQuizSettings.maxQuestions))
        }

        currentSessionQuestions = availableQuestions
    }

    private func getFailedQuestionsFromHistory() -> [QuizQuestion] {
        let failedAnswers = item.answeredQuestions.filter {
            !$0.isCorrect && $0.sourceContentRevision == item.contentRevision
        }
        var failedQuestions: [QuizQuestion] = []

        for failedAnswer in failedAnswers {
            switch failedAnswer.questionType {
            case .multipleChoice:
                if let question = item.questions.first(where: { $0.question == failedAnswer.questionText }) {
                    let originalIndex = item.questions.firstIndex(where: { $0.question == failedAnswer.questionText }) ?? 0
                    failedQuestions.append(.multipleChoice(question, originalIndex: originalIndex))
                }
            case .trueFalse:
                if let question = item.trueFalseQuestions?.first(where: { $0.question == failedAnswer.questionText }) {
                    let originalIndex = item.trueFalseQuestions?.firstIndex(where: { $0.question == failedAnswer.questionText }) ?? 0
                    failedQuestions.append(.trueFalse(question, originalIndex: originalIndex))
                }
            case .spacedRepetition:
                break
            }
        }

        return failedQuestions
    }

    func endQuiz() {
        if let session = currentQuizSession {
            session.completeSession()
            persistQuizSession()
        }

        for answeredQuestion in currentSessionAnsweredQuestions {
            item.answeredQuestions.append(answeredQuestion)
            persistAnsweredQuestion(answeredQuestion)
        }

        persistItemChanges()
        showingResults = true
    }

    func resetQuiz() {
        if let session = currentQuizSession, !session.isCompleted {
            session.abandonSession()
            persistQuizSession()
        }

        currentQuizSession = nil
        hasStartedQuiz = false
        showingResults = false
        currentQuestionIndex = 0
        currentSessionAnswers.removeAll()
        currentSessionAnsweredQuestions.removeAll()
        currentSessionQuestions.removeAll()
        currentQuestionStartedAt = nil
        lastAnswerCorrect = nil
        isWaitingForNextQuestion = false
    }

    var quizResults: (totalQuestions: Int, correctAnswers: Int, totalPoints: Int) {
        let correctCount = currentSessionAnsweredQuestions.filter { $0.isCorrect }.count
        let totalPoints = currentSessionAnsweredQuestions.reduce(0) { $0 + $1.pointsEarned }
        return (currentSessionAnsweredQuestions.count, correctCount, totalPoints)
    }
}
