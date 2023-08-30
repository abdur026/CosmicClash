//
//  ContentView.swift
//  CosmicClash
//
//  Created by Abdur Rehman on 5/16/23.
//

import SwiftUI
import CoreMotion
import AVFoundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift


struct ContentView: View {
    
    @State private var translationX: CGFloat = 0.0
    @State private var playPressed = false
    @State private var LeaderBoardPressed = false
    @State private var pausePressed = false
    @State private var resumePressed = false
    @State private var homePressed = false
    @State private var score: Int = 0
    @State private var timer: Timer?
    @State private var shootingTimer: Timer?
    @State private var circles: [CircleModel] = []
    @State private var rocketPositionX: CGFloat = 225.0
    @State private var enemies: [EnemyModel] = []
    @State private var gameOverImage: String? = nil
    @State private var enemyRockets: [CircleModel] = []
    @State private var enemyShootingTimer: Timer?
    @State private var gameOver: Bool = false
    @State private var gameOverPressed = false
    
    @State private var introPlayer: AVAudioPlayer?
    @State private var introSoundPlayed = false
    @State private var bulletPlayer: AVAudioPlayer?
    @State private var bulletSoundPlayed = false
    @State private var gameOverPlayer: AVAudioPlayer?
    @State private var gameOverSoundPlayed = false
    @State private var isSoundOn = true
    
    @State private var user: User?
    
    var body: some View {
        
        ZStack {
            
            if playPressed {
                
                ZStack{
                    
                        
                        GameView()
                            .onAppear {
                                startScoreTimer()
                                stopIntroSound()
                            }
                            .onDisappear {
                                stopScoreTimer()
                            }
                            .gesture(TapGesture().onEnded {
                                shootCircle()
                            })
                        
                        
                        ForEach(circles) { circle in
                            Image("bullet")  // Use the "bullet" image
                                .resizable()  // Make the image resizable
                                .frame(width: circle.size, height: circle.size)
                                .position(circle.position)
                            
                        }
                        
                        
                        ForEach(enemies) { enemy in
                            Image(enemy.image) // Use the image from the enemy model
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: enemy.size, height: enemy.size)
                                .position(enemy.position)
                        }
                        
                        
                    TiltImageView(pausePressed: $pausePressed, externalTranslationX: $translationX)
                        .position(x: rocketPositionX, y: 730)
                        
                        PauseButtonView(pausePressed: $pausePressed)
                            .position(x: 350, y: 30)
                        
                        Text("Score: \(score)")
                            .bold()
                            .position(x: 80, y: 30)
                            .font(.system(size: 27))
                            .foregroundColor(.white)
                        
                        if pausePressed {
                            ZStack {
                                Image("space2")
                                    .resizable()  // Make sure the image resizes
                                    .edgesIgnoringSafeArea(.all)  // Ensure it covers the whole screen
                                
                                VStack(spacing: 20) {
                                    resumeButtonView(resumePressed: $resumePressed, pausePressed: $pausePressed)
                                    
                                    HomeButtonView(homePressed: $homePressed)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .edgesIgnoringSafeArea(.all)  // Make sure the ZStack covers the entire screen
                        }
                        
                    if gameOver {
                            
                            Image(gameOverImage ?? "")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 450, height: 350)
                                .position(x:220, y: 350)
                                .onAppear{
                                    if isSoundOn{
                                        playGameOverSound()
                                    }
                                }
                            Button(action: {
                                restartGame() // Return to the main menu
                            }) {
                                Image(systemName: "play.rectangle.fill")
                                    .font(.system(size: 75))
                                    .foregroundColor(.indigo)
                                    .cornerRadius(1)
                                    .padding(.top, 20)
                            }
                            .position(x: 120, y: 580)
                            
                            Button(action: {
                                playPressed = false // Return to the main menu
                            }) {
                                Image(systemName: "house.fill")
                                    .font(.system(size: 55))
                                    .foregroundColor(.white)
                                    .background(Color.indigo)
                                    .cornerRadius(10)
                                    .padding(.top, 20)
                            }
                            .position(x: 320, y: 580)
                            
                        }
                        
                    }
                    
                    
                    
                }
                
                else {
                    BackgroundView {
                        
                        VStack(spacing: 20) {
                            LogoView()
                            PlayButtonView(playPressed: $playPressed)
                                .onAppear{
                                    playIntroSound()
                                }
                            LeaderBoardButtonView(LeaderBoardPressed: $LeaderBoardPressed)
                            
                            Button(action: {
                                isSoundOn.toggle()
                                if !isSoundOn {
                                    stopAllAudio()
                                } else {
                                    playIntroSound()
                                }
                            }) {
                                Image(systemName: isSoundOn ? "speaker.wave.2": "speaker.slash.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                            }
                            
                            RootViewPreview()
                        }
                    }
                }
            if LeaderBoardPressed {
                ZStack {
                    Color.black.opacity(0.7)
                        .edgesIgnoringSafeArea(.all) // Background overlay
                    
                    LeaderboardView(LeaderBoardPressed: $LeaderBoardPressed, userTopScore: user?.topScore ?? 0)
                        .onAppear {
                            fetchUserData() // Fetch user data from Firestore
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity) // Full screen
                        .background(Color.black)
                        .cornerRadius(15)
                        .shadow(radius: 1)
                        .ignoresSafeArea()
                    VStack {
                        Image(systemName: "person.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.white)
                            .padding()
                        
                        Text("Leaderboard")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.bottom, 10)
                        
                        Spacer()
                    }
                }
            }


                
                if homePressed  {
                    ContentView()
                }
                
            }
            
            
        }
        private func stopAllAudio() {
            stopIntroSound()
            stopBulletSound()
            stopGameOverSound()
        }
        private func fetchUserData() {
            guard let authUser = try? AuthenticationManager.shared.getAuthenticatedUser() else {
                return
            }
            
            let db = Firestore.firestore()
            let userDocRef = db.collection("users").document(authUser.uid)
            
            userDocRef.getDocument { document, error in
                if let document = document, document.exists {
                    if let userData = document.data(), let topScore = userData["topScore"] as? Int {
                        user = User(id: authUser.uid, topScore: topScore)
                    }
                } else {
                    // Document doesn't exist, create a new one
                    let newUser = User(id: authUser.uid, topScore: 0)
                    userDocRef.setData(["topScore": 0])
                    user = newUser
                }
            }
        }
        
        private func updateTopScoreIfNeeded(newScore: Int) {
            if var currentUser = user, newScore > currentUser.topScore {
                currentUser.topScore = newScore
                user = currentUser
                
                let db = Firestore.firestore()
                let userDocRef = db.collection("users").document(currentUser.id)
                userDocRef.updateData(["topScore": newScore])
            }
        }
        private func restartGame() {
            gameOverImage = nil
            gameOver = false
            score = 0
            circles.removeAll()
            enemies.removeAll()
            playPressed = true
            gameOverPressed = false
            
            // Stop existing game-related timers
            stopScoreTimer()
            stopShootingTimer()
            enemyShootingTimer?.invalidate()
            
            // Start game-related timers and logic
            startScoreTimer()
            
            for enemy in enemies {
                startEnemyMovement(for: enemy)
            }
            updateTopScoreIfNeeded(newScore: score)
        }
        
        func playIntroSound() {
            if !introSoundPlayed,
               let soundURL = Bundle.main.url(forResource: "intro", withExtension: "mp3") {
                do {
                    introPlayer = try AVAudioPlayer(contentsOf: soundURL)
                    introPlayer?.numberOfLoops = -1  // Loop indefinitely
                    introPlayer?.play()
                    introSoundPlayed = true
                } catch {
                    print("Error playing intro sound: \(error.localizedDescription)")
                }
            }
        }
        
        func stopIntroSound() {
            introPlayer?.stop()
            introSoundPlayed = false
        }
        func stopBulletSound() {
            bulletPlayer?.stop()
            bulletSoundPlayed = false
        }
        func stopGameOverSound() {
            gameOverPlayer?.stop()
            gameOverSoundPlayed = false
        }
        
        func playBulletSound() {
            if let soundURL = Bundle.main.url(forResource: "bullets", withExtension: "mp3") {
                do {
                    bulletPlayer = try AVAudioPlayer(contentsOf: soundURL)
                    bulletPlayer?.play()
                } catch {
                    print("Error playing bullet sound: \(error.localizedDescription)")
                }
            }
        }
        func playGameOverSound() {
            if let soundURL = Bundle.main.url(forResource: "gameover", withExtension: "mp3") {
                do {
                    bulletPlayer = try AVAudioPlayer(contentsOf: soundURL)
                    bulletPlayer?.play()
                } catch {
                    print("Error playing gameover sound: \(error.localizedDescription)")
                }
            }
        }
        
        
        
        struct BackgroundView<Content: View>: View {
            let content: Content
            
            init(@ViewBuilder content: () -> Content) {
                self.content = content()
            }
            
            var body: some View {
                Image("Space")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .overlay(content)
            }
        }
        
        struct LogoView: View {
            var body: some View {
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 350, height: 350)
            }
        }
        
        struct User {
            let id: String
            var topScore: Int
        }
        
        
        struct RootViewPreview: View {
            @State private var showRootView = false
            @State private var isUserSignedIn = false
            
            var body: some View {
                VStack {
                    Button(isUserSignedIn ? "Settings" : "Sign In") {
                        showRootView.toggle()
                    }
                    .padding()
                    .frame(maxWidth: 200)
                    .frame(height: 40)
                    .background(Color.blue)
                    .foregroundColor(Color.white)
                    .cornerRadius(25)
                }
                .onTapGesture {
                    showRootView.toggle()
                }
                .sheet(isPresented: $showRootView, onDismiss: {
                    checkUserSignedInStatus()
                }, content: {
                    RootView()
                })
                .onAppear {
                    checkUserSignedInStatus()
                }
            }
            
            func checkUserSignedInStatus() {
                let authUser = try? AuthenticationManager.shared.getAuthenticatedUser()
                self.isUserSignedIn = authUser != nil
            }
        }
        
        
        
        
        
        struct LeaderBoardButtonView: View {
            @Binding var LeaderBoardPressed: Bool
            
            var body: some View {
                Button(action: {
                    LeaderBoardPressed = true
                }) {
                    Image(systemName: "trophy.circle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.yellow)
                }
            }
        }
        
        struct PlayButtonView: View {
            @Binding var playPressed: Bool
            var body: some View {
                Button(action: {
                    playPressed = true
                    
                }) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.indigo)
                }
            }
        }
        
        
        struct PauseButtonView: View {
            @Binding var pausePressed: Bool
            
            var body: some View {
                Button(action: {
                    pausePressed = true
                }) {
                    Image(systemName: "pause.rectangle.fill")
                        .font(.system(size: 45))
                        .foregroundColor(.white)
                }
            }
        }
        
        struct GameView: View {
            var body: some View{
                Image("stars")
                    .resizable()
                    .ignoresSafeArea()
                
                
            }
        }
    struct LeaderboardView: View {
        @Binding var LeaderBoardPressed: Bool
        var userTopScore: Int // Pass the user's top score instead of dummy scores
        
        var body: some View {
            ZStack {
                Color.black
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 30) {
                    Text("Your Top Score:")
                        .font(.title)
                        .foregroundColor(.white)
                    
                    Text("\(userTopScore)") // Display the user's top score
                        .font(.title)
                        .foregroundColor(.yellow)
                    
                    Button(action: {
                        LeaderBoardPressed = false
                    }) {
                        Text("Back to Game")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .shadow(color: .blue, radius: 5, x: 0, y: 0)
                    }
                }
                .padding()
            }
        }
    }


    
        
        
    struct resumeButtonView: View {
        @Binding var resumePressed: Bool
        @Binding var pausePressed: Bool
        
        var body: some View {
            VStack {
                Spacer()
                Button(action: {
                    resumePressed = true
                    pausePressed = false
                }) {
                    HStack {
                        Image(systemName: "play.fill") // SF Symbol for play
                            .font(.title)
                        Text("Resume")
                            .font(.title)
                            .fontWeight(.semibold)
                    }
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .shadow(color: .blue, radius: 5, x: 0, y: 0)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    struct HomeButtonView: View {
        @Binding var homePressed: Bool
        
        var body: some View {
            VStack {
                Spacer()
                Button(action: {
                    homePressed = true
                }) {
                    HStack {
                        Image(systemName: "house.fill") // SF Symbol for home
                            .font(.title)
                        Text("Main Menu")
                            .font(.title)
                            .fontWeight(.semibold)
                    }
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .shadow(color: .blue, radius: 5, x: 0, y: 0)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
        
        struct TiltImageView: View {
            @Binding var pausePressed: Bool
            @Binding var externalTranslationX: CGFloat
            
            let motionManager = CMMotionManager()
            @State private var translationX: CGFloat = 0.0
            
            var body: some View {
                Image("Rocket")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 500, height: 200)
                    .offset(x: translationX)
                    .onAppear {
                        startMotionUpdates()
                        externalTranslationX = translationX
                    }
                    .onDisappear {
                        stopMotionUpdates()
                    }
            }
            
            
            private func startMotionUpdates() {
                if !pausePressed &&  motionManager.isDeviceMotionAvailable {
                    motionManager.deviceMotionUpdateInterval = 0.1
                    motionManager.startDeviceMotionUpdates(to: .main) { (motionData, error) in
                        if let motionData = motionData {
                            let tilt = motionData.attitude.roll
                            translationX = CGFloat(tilt) * 100 // Adjust the sensitivity as needed
                            externalTranslationX = translationX // Update the external translation as well
                        }
                    }
                }
            }
            
            
            private func stopMotionUpdates() {
                motionManager.stopDeviceMotionUpdates()
            }
            
        }
        
        private func startScoreTimer() {
            
            guard !pausePressed else {
                   return
               }
            timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
                score += 1
                
                var spawnProbability = 20
                
                if score > 20*33 && score <= 40*33 {
                    spawnProbability = 15
                } else if score > 40*33 && score <= 60*33 {
                    spawnProbability = 10
                } else if score > 60*33 {
                    spawnProbability = 5
                }
                
                if Int.random(in: 0..<spawnProbability) == 0 {
                    spawnEnemy()
                }
                
                
                
                if rocketCollidesWithAnyEnemy() {
                    gameOver = true
                    stopScoreTimer()
                    gameOverImage = "gameover" // Set the image name to "gameover"
                }
                updateTopScoreIfNeeded(newScore: score)
            }
        }
    
        
        
        private func rocketCollidesWithAnyEnemy() -> Bool {
            
            let rocketWidth: CGFloat = 35 // Adjust if the size of the rocket changes
            let rocketHeight: CGFloat = 50 // Adjust if the height of the rocket changes
            
            let rocketFrame = CGRect(x: rocketPositionX + translationX - rocketWidth / 2,
                                     y: 760 - rocketHeight,
                                     width: rocketWidth,
                                     height: rocketHeight)
            
            for enemy in enemies {
                let enemyFrame = CGRect(x: enemy.position.x - enemy.size / 2,
                                        y: enemy.position.y - enemy.size / 2,
                                        width: enemy.size,
                                        height: enemy.size)
                
                if rocketFrame.intersects(enemyFrame) {
                    return true
                }
            }
            return false
        }
        
        
        
        
        
        private func stopScoreTimer() {
            timer?.invalidate()
            timer = nil
        }
        
        struct CircleModel: Identifiable {
            let id = UUID()
            var position: CGPoint
            let size: CGFloat
            
        }
        
        struct EnemyModel: Identifiable {
            let id = UUID()
            var position: CGPoint
            let size: CGFloat
            let image: String // Add this property to store the image name
        }
        
        
        
        private func spawnEnemy() {
            guard !pausePressed else {
                   return
               }
            let enemySize: CGFloat = 30  // set a constant size
            let startPositionX: CGFloat = CGFloat.random(in: 0...550)
            
            // Randomly pick an image name
            let enemyImageName = Bool.random() ? "enemy" : "enemy2"
            
            let newEnemy = EnemyModel(position: CGPoint(x: startPositionX, y: -enemySize), size: enemySize, image: enemyImageName)
            enemies.append(newEnemy)
            startEnemyMovement(for: newEnemy)
        }
        
        
        private func startEnemyMovement(for enemy: EnemyModel) {
            guard !pausePressed else {
                return
            }
            // Randomize the amplitude, frequency, and ySpeed for each enemy
            let amplitude: CGFloat = CGFloat.random(in: 100.0...200.0)  // Determines the amplitude of the sinusoidal pattern
            let frequency: CGFloat = CGFloat.random(in: 0.03...0.07)  // Determines the frequency of the sinusoidal pattern
            let ySpeed: CGFloat = CGFloat.random(in: 4.0...6.0)      // Determines the speed of the enemy's descent
            var time: CGFloat = 0.0  // This will be incremented to change the phase of the sine wave
            
            let startingXPosition = enemy.position.x  // Capture the starting X position when function is called
            var initialYPosition: CGFloat = -200  // Initial y-coordinate where the enemy spawns
            
            _ = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
                guard let index = enemies.firstIndex(where: { $0.id == enemy.id }) else {
                    timer.invalidate()
                    return
                }
                
                var updatedEnemy = enemy
                time += frequency
                
                let xOffset = sin(time) * amplitude  // Sine wave for left and right motion
                
                // Update x-coordinate based on the sine wave and y-coordinate moves downward linearly
                let updatedPosition = CGPoint(x: startingXPosition + xOffset, y: initialYPosition + ySpeed)
                initialYPosition += ySpeed  // Move the initial position downward
                
                updatedEnemy.position = updatedPosition
                enemies[index] = updatedEnemy
                
                if updatedPosition.y >= 900 {
                    timer.invalidate()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        enemies.removeAll(where: { $0.id == enemy.id })
                    }
                }
            }
        }
        
        
        
        
        
        
        private func shootCircle() {
            guard !pausePressed else {
                return
            }
            let circleSize: CGFloat = 20.0
            let relativeStartPositionX: CGFloat = 0.0
            let newCircle = CircleModel(position: CGPoint(x: rocketPositionX + relativeStartPositionX + translationX, y: 760 - 70), size: circleSize)
            circles.append(newCircle)
            if isSoundOn { // Check if sound is not muted
                playBulletSound()
            }
            startShootingTimer(for: newCircle)
        }
        
        
        
        private func collides(circle: CircleModel, enemy: EnemyModel) -> Bool {
            let distance = sqrt(pow(circle.position.x - enemy.position.x, 2) + pow(circle.position.y - enemy.position.y, 2))
            return distance < (circle.size / 2 + enemy.size / 2)
        }
        
        
        
        private func startShootingTimer(for circle: CircleModel) {
            guard !pausePressed else {
                return
            }
            let initialYPosition: CGFloat = circle.position.y  // Store the starting y-coordinate
            
            _ = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
                withAnimation {
                    guard let index = circles.firstIndex(where: { $0.id == circle.id }) else {
                        timer.invalidate()
                        return
                    }
                    
                    var currentCircle = circles[index]  // Use the updated circle from the array for each iteration
                    let updatedPosition = CGPoint(x: currentCircle.position.x, y: currentCircle.position.y - 5) // Subtract only 5 from y-coordinate to move bullet up progressively
                    currentCircle.position = updatedPosition
                    circles[index] = currentCircle
                    
                    if updatedPosition.y <= 0 || (initialYPosition - updatedPosition.y) >= 700 {  // Check if bullet has reached the top of the screen or moved up 700 units
                        timer.invalidate()
                        DispatchQueue.main.async {
                            circles.removeAll(where: { $0.id == circle.id }) // Remove the bullet from the array
                        }
                    } else {
                        // Check for collisions with enemies
                        for (enemyIndex, enemy) in enemies.enumerated() {
                            if collides(circle: currentCircle, enemy: enemy) {
                                enemies.remove(at: enemyIndex)
                                circles.remove(at: index)
                                timer.invalidate()
                                return // Return to exit the loop and prevent invalid array access
                            }
                        }
                    }
                    
                }
            }
        }
        
        
        
    
        
        
        private func stopShootingTimer() {
            shootingTimer?.invalidate()
            shootingTimer = nil
        }
        
        private func handleTap() {
            shootCircle()
        }
        
        
        
        struct ContentView_Previews: PreviewProvider {
            static var previews: some View {
                ContentView()
                
                
            }
        }
        
        
    }
    



