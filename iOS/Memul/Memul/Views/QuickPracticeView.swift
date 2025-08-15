//
//  QuickPracticeView.swift
//  Memul
//

import SwiftUI

struct QuickPracticeView: View {
    enum Mode { case multiplication, division }

    let mode: Mode
    let minValue: Int
    let maxValue: Int

    @State private var a: Int = 2
    @State private var b: Int = 2
    @State private var dividend: Int = 0
    @State private var divisor: Int = 0
    @State private var correctAnswer: Int = 0
    @State private var options: [Int] = []
    @State private var selected: Int? = nil
    @State private var isCorrect: Bool? = nil
    @State private var score: Int = 0
    @State private var questionCount: Int = 0

    private let totalQuestions = 10

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(String(format: NSLocalizedString("qp_score", comment: ""), score, questionCount, totalQuestions))
                    .font(.subheadline)
                Spacer()
            }

            Text(promptText)
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            VStack(spacing: 12) {
                ForEach(options, id: \.self) { value in
                    Button {
                        choose(value)
                    } label: {
                        HStack {
                            Text("\(value)")
                                .font(.title3.bold())
                            Spacer()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(backgroundFor(value))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3)))
                        .cornerRadius(10)
                    }
                    .disabled(isCorrect != nil) // lock after choosing
                }
            }
            .padding(.vertical, 8)

            if let isCorrect = isCorrect {
                Text(isCorrect
                     ? NSLocalizedString("qp_correct", comment: "")
                     : String(format: NSLocalizedString("qp_wrong", comment: ""), correctAnswer))
                .foregroundColor(isCorrect ? .green : .red)
                .font(.headline)
                .padding(.top, 4)
            }

            Spacer()

            HStack {
                Button(NSLocalizedString("qp_next", comment: "")) {
                    nextQuestion()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isCorrect == nil && questionCount > 0)
                Spacer()
            }
        }
        .padding()
        .onAppear { nextQuestion(first: true) }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var promptText: String {
        switch mode {
        case .multiplication:
            return String(format: NSLocalizedString("qp_m_prompt", comment: ""), a, b)
        case .division:
            return String(format: NSLocalizedString("qp_d_prompt", comment: ""), dividend, divisor)
        }
    }

    private func choose(_ value: Int) {
        guard isCorrect == nil else { return }
        selected = value
        let correct = (value == correctAnswer)
        isCorrect = correct
        if correct { score += 1 }
    }

    private func backgroundFor(_ value: Int) -> some View {
        Group {
            if let selected, let isCorrect = isCorrect {
                if value == selected {
                    (isCorrect ? Color.green.opacity(0.25) : Color.red.opacity(0.25))
                } else if !isCorrect && value == correctAnswer {
                    Color.green.opacity(0.15)
                } else {
                    Color(UIColor.secondarySystemBackground)
                }
            } else {
                Color(UIColor.secondarySystemBackground)
            }
        }
    }

    private func nextQuestion(first: Bool = false) {
        if !first {
            questionCount = min(questionCount + 1, totalQuestions)
        } else {
            questionCount = 0
            score = 0
        }

        selected = nil
        isCorrect = nil

        switch mode {
        case .multiplication:
            a = Int.random(in: minValue...maxValue)
            b = Int.random(in: minValue...maxValue)
            correctAnswer = a * b
            options = makeOptions(correct: correctAnswer, base: correctAnswer, span: 10)

        case .division:
            let q = Int.random(in: max(1, minValue)...maxValue)   // quotient
            let d = Int.random(in: max(1, minValue)...maxValue)   // divisor
            dividend = q * d
            divisor = d
            correctAnswer = q
            options = makeOptions(correct: correctAnswer, base: correctAnswer, span: 5)
        }
    }

    private func makeOptions(correct: Int, base: Int, span: Int) -> [Int] {
        var set = Set<Int>([correct])
        let candidates = (base - span ... base + span).filter { $0 > 0 }
        while set.count < 4, let cand = candidates.randomElement() {
            set.insert(cand)
        }
        return Array(set).shuffled()
    }
}
