import Foundation
import SwiftData

enum MockDataSeeder {
    private static let seedVersion = 2
    private static let versionKey = "kinetichausMockSeedVersion"

    @MainActor
    static func seedIfNeeded(_ context: ModelContext) {
        #if targetEnvironment(simulator)
        let stored = UserDefaults.standard.integer(forKey: versionKey)
        let existing = (try? context.fetch(FetchDescriptor<UserProfile>())) ?? []
        if stored == seedVersion, !existing.isEmpty { return }
        wipe(context)
        seed(context)
        UserDefaults.standard.set(seedVersion, forKey: versionKey)
        UserDefaults.standard.set(true, forKey: "hausConfigured")
        #endif
    }

    @MainActor
    private static func wipe(_ context: ModelContext) {
        func del<T: PersistentModel>(_ t: T.Type) {
            (try? context.fetch(FetchDescriptor<T>()))?.forEach { context.delete($0) }
        }
        del(WorkoutSession.self); del(Workout.self)
        del(TrainingProgram.self); del(ProgramWeek.self); del(ProgramDay.self)
        del(FoodProduct.self); del(Meal.self); del(MealItem.self); del(HydrationLog.self)
        del(Book.self); del(ReadingSession.self); del(CalendarEvent.self)
        del(BodyMeasurement.self); del(UserGoal.self); del(UserProfile.self)
        try? context.save()
    }

    @MainActor
    private static func seed(_ context: ModelContext) {
        let cal = Calendar.current
        let now = Date()
        func day(_ n: Int) -> Date { cal.date(byAdding: .day, value: -n, to: now) ?? now }
        func at(_ hour: Int, _ date: Date) -> Date { cal.date(byAdding: .hour, value: hour, to: cal.startOfDay(for: date)) ?? date }

        let profile = UserProfile(
            name: "Jonas Krell", age: 31, heightCm: 188, currentWeightKg: 88.0, targetWeightKg: 85,
            activityLevel: "high", trainingLevel: .intermediate,
            mainGoals: ["Precision lifting", "Measurable gains", "Minimal fat"],
            dailyCaloriesGoal: 2600, proteinGoalGrams: 175, fatGoalGrams: 75, carbsGoalGrams: 280, waterGoalMl: 3200
        )
        context.insert(profile)

        let upper = Workout(title: "A — Squat/Bench", workoutDescription: "Primary compound day", type: .strength, difficulty: .intermediate, goal: "Strength", estimatedDurationMinutes: 75, tags: ["strength"], exercises: [
            WorkoutExercise(name: "Competition Squat", muscleGroup: .legs, equipment: "Barbell", sets: 5, reps: 3, weightKg: 120, restSeconds: 90, orderIndex: 0),
            WorkoutExercise(name: "Competition Bench", muscleGroup: .chest, equipment: "Barbell", sets: 5, reps: 3, weightKg: 100, restSeconds: 90, orderIndex: 1),
            WorkoutExercise(name: "RDL", muscleGroup: .legs, equipment: "Barbell", sets: 4, reps: 6, weightKg: 100, restSeconds: 90, orderIndex: 2)
        ])
        let legs = Workout(title: "B — Deadlift/OHP", workoutDescription: "Posterior & press", type: .strength, difficulty: .advanced, goal: "Strength", estimatedDurationMinutes: 70, tags: ["strength"], exercises: [
            WorkoutExercise(name: "Conventional Deadlift", muscleGroup: .legs, equipment: "Barbell", sets: 4, reps: 4, weightKg: 140, restSeconds: 90, orderIndex: 0),
            WorkoutExercise(name: "Strict Press", muscleGroup: .shoulders, equipment: "Barbell", sets: 4, reps: 6, weightKg: 60, restSeconds: 90, orderIndex: 1),
            WorkoutExercise(name: "Chin-Up", muscleGroup: .back, equipment: "Bodyweight", sets: 4, reps: 8, restSeconds: 90, orderIndex: 2)
        ])
        let hiit = Workout(title: "C — Accessories", workoutDescription: "Volume block", type: .strength, difficulty: .intermediate, goal: "Hypertrophy", estimatedDurationMinutes: 50, tags: ["strength"], exercises: [
            WorkoutExercise(name: "Leg Curl", muscleGroup: .legs, equipment: "Machine", sets: 4, reps: 12, weightKg: 45, restSeconds: 90, orderIndex: 0),
            WorkoutExercise(name: "Incline Press", muscleGroup: .chest, equipment: "Barbell", sets: 4, reps: 8, weightKg: 70, restSeconds: 90, orderIndex: 1),
            WorkoutExercise(name: "Face Pull", muscleGroup: .shoulders, equipment: "Cable", sets: 3, reps: 15, weightKg: 20, restSeconds: 90, orderIndex: 2)
        ])
        let mobility = Workout(title: "Deload Reset", workoutDescription: "Reduced intensity", type: .mobility, difficulty: .beginner, goal: "Recovery", estimatedDurationMinutes: 30, tags: ["mobility"], exercises: [
            WorkoutExercise(name: "Tempo Squat", muscleGroup: .legs, equipment: "Barbell", sets: 3, reps: 5, weightKg: 60, restSeconds: 90, orderIndex: 0),
            WorkoutExercise(name: "Band Work", muscleGroup: .mobility, equipment: "Band", sets: 2, reps: 15, restSeconds: 90, orderIndex: 1)
        ])
        [upper, legs, hiit, mobility].forEach { context.insert($0) }
        upper.lastPerformedAt = day(2)
        legs.lastPerformedAt = day(4)
        hiit.lastPerformedAt = day(6)

        func session(_ workout: Workout, daysAgo n: Int, durationMin: Int, volume: Double, rpe: Int) -> WorkoutSession {
            let s = WorkoutSession(workoutId: workout.id, workoutTitle: workout.title, startedAt: at(9, day(n)))
            s.status = .completed
            s.durationSeconds = durationMin * 60
            s.endedAt = cal.date(byAdding: .minute, value: durationMin, to: s.startedAt)
            s.perceivedDifficulty = rpe
            s.mood = ["Strong", "Focused", "Calm", "Energized"].randomElement()
            s.totalVolume = volume
            var sets: [PerformedSet] = []
            for ex in workout.sortedExercises {
                for setIdx in 0..<ex.sets {
                    sets.append(PerformedSet(exerciseName: ex.name, muscleGroup: ex.muscleGroup, setIndex: setIdx, reps: ex.reps, weightKg: ex.weightKg, durationSeconds: ex.durationSeconds, rpe: ex.rpe, isCompleted: true, completedAt: s.startedAt))
                }
            }
            s.performedSets = sets
            s.completedExercisesCount = workout.exercises.count
            s.completedSetsCount = sets.count
            return s
        }

        [session(upper, daysAgo: 14, durationMin: 55, volume: 4200, rpe: 7),
         session(legs, daysAgo: 11, durationMin: 62, volume: 7100, rpe: 8),
         session(hiit, daysAgo: 8, durationMin: 28, volume: 1800, rpe: 6),
         session(upper, daysAgo: 5, durationMin: 58, volume: 4500, rpe: 8),
         session(legs, daysAgo: 2, durationMin: 65, volume: 7400, rpe: 8)
        ].forEach { context.insert($0) }

        let plannedToday = WorkoutSession(workoutId: legs.id, workoutTitle: legs.title, startedAt: at(18, now))
        plannedToday.status = .planned
        context.insert(plannedToday)

        let program = TrainingProgram(
            title: "16-Week Linear Block",
            programDescription: "Structured periodization with deloads",
            goal: "Precision lifting", difficulty: .intermediate,
            startDate: day(14), endDate: cal.date(byAdding: .day, value: 56, to: now),
            weeksCount: 4, daysPerWeek: 3, status: .active,
            weeks: (1...4).map { w in
                ProgramWeek(weekIndex: w, title: "Week \(w)", notes: w == 1 ? "Foundation" : nil, days: [
                    ProgramDay(dayIndex: 1, weekday: 2, title: "A — Squat/Bench", plannedWorkoutId: upper.id, isCompleted: w == 1),
                    ProgramDay(dayIndex: 2, weekday: 4, title: "B — Deadlift/OHP", plannedWorkoutId: legs.id, isCompleted: w == 1),
                    ProgramDay(dayIndex: 3, weekday: 6, title: "C — Accessories", plannedWorkoutId: hiit.id, isCompleted: false)
                ])
            }
        )
        context.insert(program)

        func product(_ name: String, _ brand: String?, _ kcal: Double, _ p: Double, _ f: Double, _ c: Double, fav: Bool = false) -> FoodProduct {
            FoodProduct(source: .manual, name: name, brand: brand, caloriesPer100g: kcal, proteinPer100g: p, fatPer100g: f, carbsPer100g: c, nutriScore: nil, isFavorite: fav)
        }
        let chicken = product("Lean Beef", nil, 250, 26, 15, 0, fav: true)
        let oats = product("White Rice", nil, 130, 2.7, 0.3, 28, fav: true)
        let banana = product("Broccoli", nil, 34, 2.8, 0.4, 7, fav: true)
        let yogurt = product("Cottage Cheese 0%", nil, 72, 12, 0.5, 3, fav: false)
        let almonds = product("Peanut Butter", nil, 588, 25, 50, 20, fav: false)
        let rice = product("Casein Powder", "HausNutri", 360, 80, 2, 6, fav: false)
        let salmon = product("Asparagus", nil, 20, 2.2, 0.1, 3.9, fav: false)
        [chicken, oats, banana, yogurt, almonds, rice, salmon].forEach { context.insert($0) }

        func item(_ p: FoodProduct, _ grams: Double) -> MealItem {
            let r = grams / 100
            return MealItem(foodProductId: p.id, productName: p.name, amountGrams: grams, calories: p.caloriesPer100g * r, protein: p.proteinPer100g * r, fat: p.fatPer100g * r, carbs: p.carbsPer100g * r)
        }
        func meal(_ date: Date, _ type: MealType, _ title: String, _ items: [MealItem]) -> Meal {
            Meal(date: date, type: type, title: title, items: items)
        }
        [
            meal(now, .breakfast, "Protein Oats", [item(oats, 80), item(banana, 120), item(yogurt, 150)]),
            meal(now, .lunch, "Beef & Rice", [item(chicken, 180), item(rice, 200)]),
            meal(now, .dinner, "Casein Bowl", [item(salmon, 160), item(almonds, 30)])
        ].forEach { context.insert($0) }

        for n in 1...7 {
            let d = day(n)
            [meal(d, .breakfast, "Breakfast", [item(oats, 70), item(yogurt, 150)]),
             meal(d, .lunch, "Lunch", [item(chicken, 150), item(rice, 180)]),
             meal(d, .dinner, "Dinner", [item(salmon, 150)])].forEach { context.insert($0) }
        }

        for ml in [300, 500, 400, 500] { context.insert(HydrationLog(date: now, amountMl: ml)) }
        for n in 1...5 { context.insert(HydrationLog(date: day(n), amountMl: 3200 - 400 + n * 100)) }

        let b1 = Book(title: "Scientific Principles of Hypertrophy", authors: ["Mike Israetel"], firstPublishYear: 2018, subjects: ["Fitness"], readingStatus: .reading, rating: 5, progressPercent: 0.5, notes: "On my path.")
        let b2 = Book(title: "The Strength Training Anatomy", authors: ["Frederic Delavier"], firstPublishYear: 2017, subjects: ["Fitness"], readingStatus: .reading, rating: 5, progressPercent: 0.8, notes: "On my path.")
        let b3 = Book(title: "Thinking in Systems", authors: ["Donella Meadows"], firstPublishYear: 2016, subjects: ["Fitness"], readingStatus: .completed, rating: 5, progressPercent: 1.0)
        let b4 = Book(title: "Practical Programming", authors: ["Mark Rippetoe"], firstPublishYear: 2015, subjects: ["Fitness"], readingStatus: .wantToRead, rating: 4, progressPercent: 0.0)
        let b5 = Book(title: "More to Explore", authors: ["Various"], firstPublishYear: 2020, subjects: ["Health"], readingStatus: .wantToRead)
        let b6 = Book(title: "Paused Read", authors: ["Various"], firstPublishYear: 2019, subjects: ["Wellness"], readingStatus: .paused, progressPercent: 0.1)
        [b1, b2, b3, b4, b5, b6].forEach { context.insert($0) }
        for n in 0...4 {
            context.insert(ReadingSession(bookId: b1.id, bookTitle: b1.title, date: day(n), durationMinutes: 18 + n * 2, pagesRead: 12 + n))
        }

        func event(_ title: String, _ type: CalendarEventType, _ date: Date, _ status: CalendarEventStatus = .planned) -> CalendarEvent {
            CalendarEvent(title: title, eventType: type, startDate: date, status: status)
        }
        [
            event("A — Squat/Bench", .workout, at(9, now)),
            event("Weigh-in", .rest, at(14, now)),
            event("Program review", .note, at(19, now), .completed),
            event("A — Squat/Bench", .workout, day(3), .completed),
            event("B — Deadlift/OHP", .workout, day(5), .completed)
        ].forEach { context.insert($0) }

        let weights: [Double] = [90.5, 89.8, 89.2, 88.8, 88.5, 88.2, 88.0, 88.0]
        for i in 0..<weights.count {
            let d = cal.date(byAdding: .day, value: -(7 * (weights.count - 1 - i)), to: now) ?? now
            context.insert(BodyMeasurement(date: d, weightKg: weights[i], bodyFatPercent: 18.0 - Double(i) * 0.3, muscleMassKg: 34.0 + Double(i) * 0.2, waistCm: 88 - Double(i) * 0.5, note: i == weights.count - 1 ? "On track." : nil))
        }

        [
            UserGoal(title: "Squat 140 kg", type: .custom, targetValue: 140, currentValue: 120, unit: "kg"),
            UserGoal(title: "85 kg bodyweight", type: .bodyWeight, targetValue: 85, currentValue: 88.0, unit: "kg"),
            UserGoal(title: "4 lifts / week", type: .workoutsCount, targetValue: 4, currentValue: 4, unit: "units"),
            UserGoal(title: "175g protein", type: .protein, targetValue: 175, currentValue: 150, unit: "g")
        ].forEach { context.insert($0) }

        try? context.save()
    }
}
