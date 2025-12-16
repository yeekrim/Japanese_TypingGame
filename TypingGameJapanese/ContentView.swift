//
//  ContentView.swift
//  TypingGameJapanese
//
//  Created by 이경림 on 12/16/25.
//

import SwiftUI
import AppKit

struct FallingWord: Identifiable, Equatable {
    let id = UUID()
    let text: String
    var x: CGFloat
    var y: CGFloat
    var speed: CGFloat
}

struct ContentView: View {
    private let wordsPool: [String] = [
            "こんにちは", "ありがとう", "さようなら", "すみません", "お願いします",
            "猫", "犬", "水", "火", "風", "山", "海", "空",
            "学校", "先生", "友達", "日本語", "勉強", "ごはん", "電車",
    ]
    private let spawnInterval: TimeInterval = 1.5
    private let tickInterval: TimeInterval = 1.0 / 60
    private let bottomPadding: CGFloat = 80
    
    @State private var activeWords: [FallingWord] = []
    @State private var inputText: String = ""
    @State private var lives: Int = 3
    @State private var isGameOver: Bool = false
    
    @State private var viewSize: CGSize = .zero
    
    @State private var spawnTimer: Timer?
    @State private var tickTimer: Timer?
    
    
    var body: some View {
            ZStack {
                Image("background")
                .ignoresSafeArea()

                GeometryReader { geo in
                    ZStack(alignment: .topLeading) {
                        // 단어들
                        ForEach(activeWords) { w in
                            Text(w.text)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .shadow(radius: 6)
                                .position(x: w.x, y: w.y)
                                .animation(.linear(duration: 0.0), value: w.y)
                        }

                        // 상단 UI (목숨)
                        HStack(spacing: 8) {
                            Text("命:")
                                .foregroundStyle(.white.opacity(0.8))
                                .font(.system(size: 20, weight: .semibold))
                            ForEach(0..<3, id: \.self) { i in
                                Image(systemName: i < lives ? "heart.fill" : "heart")
                                    .foregroundStyle(i < lives ? .red : .white.opacity(0.35))
                            }
                            Spacer()
                        }
                        .padding(.top, 14)
                        .padding(.horizontal, 16)
                    }
                    .onAppear {
                        viewSize = geo.size
                        startGame()
                    }
                    .onChange(of: geo.size) { newValue in
                        viewSize = newValue
                    }
                }

                // 하단 입력창
                VStack {
                    Spacer()

                    HStack(spacing: 12) {
                        TextField("入力", text: $inputText)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 18))
                            .frame(width: 380)
                            .onSubmit {
                                checkInput()
                            }

                        Button("ENTER") {
                            checkInput()
                        }
                        .keyboardShortcut(.defaultAction)
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 16)

                // 게임오버 오버레이
                if isGameOver {
                    Color.black.opacity(0.65).ignoresSafeArea()
                    VStack(spacing: 14) {
                        Text("GAME OVER")
                            .font(.system(size: 44, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)

                        Text("목숨이 모두 사라졌어.")
                            .foregroundStyle(.white.opacity(0.85))

                        Button("RESTART") {
                            restartGame()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding(26)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 20)
                }
            }
        }
    
    private func startGame() {
            stopTimers()

            lives = 3
            isGameOver = false
            activeWords.removeAll()
            inputText = ""

            // 단어 생성 타이머
            spawnTimer = Timer.scheduledTimer(withTimeInterval: spawnInterval, repeats: true) { _ in
                spawnWord()
            }

            // 이동(틱) 타이머
            tickTimer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { _ in
                tick()
            }
            RunLoop.main.add(spawnTimer!, forMode: .common)
            RunLoop.main.add(tickTimer!, forMode: .common)
        }
    
    private func stopTimers() {
            spawnTimer?.invalidate()
            tickTimer?.invalidate()
            spawnTimer = nil
            tickTimer = nil
    }
    
    private func restartGame() {
            startGame()
    }
    
    private func spawnWord() {
            guard !isGameOver else { return }
            guard viewSize.width > 0, viewSize.height > 0 else { return }

            let text = wordsPool.randomElement() ?? "こんにちは"

            // x는 좌우 여유를 둬서 랜덤
            let margin: CGFloat = 40
            let x = CGFloat.random(in: margin...(max(margin, viewSize.width - margin)))

            // y는 화면 최상단 위쪽에서 시작(살짝 위)
            let y: CGFloat = -20

            // 속도 랜덤 (난이도 느낌)
            let speed = CGFloat.random(in: 80...160)

            activeWords.append(FallingWord(text: text, x: x, y: y, speed: speed))
    }
    
    private func tick() {
            guard !isGameOver else { return }

            // deltaTime (초)
            let dt = CGFloat(tickInterval)

            // 단어들을 아래로 이동
            for i in activeWords.indices {
                activeWords[i].y += activeWords[i].speed * dt
            }

            // 바닥 도달 체크
            let bottomY = viewSize.height - bottomPadding
            var removed: [UUID] = []

            for w in activeWords {
                if w.y >= bottomY {
                    removed.append(w.id)
                }
            }

            if !removed.isEmpty {
                activeWords.removeAll { removed.contains($0.id) }
                loseLives(count: removed.count)
            }
    }
    
    private func loseLives(count: Int) {
            lives -= count
            if lives <= 0 {
                lives = 0
                gameOver()
            }
    }
    
    private func gameOver() {
            isGameOver = true
            stopTimers()
    }
    
    private func checkInput() {
            guard !isGameOver else { return }
            let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }

            // 화면에 떠있는 단어 중 완벽히 일치하는 것 제거
            if let idx = activeWords.firstIndex(where: { $0.text == trimmed }) {
                activeWords.remove(at: idx)
            }

            inputText = ""
    }

}

#Preview {
    ContentView()
}
