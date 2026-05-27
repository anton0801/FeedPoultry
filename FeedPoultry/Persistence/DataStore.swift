import Foundation
import SwiftUI
import Combine

final class DataStore: ObservableObject {
    @Published var ingredients: [Ingredient] = []
    @Published var recipes: [Recipe] = []
    @Published var stockEntries: [StockEntry] = []
    @Published var costs: [CostRecord] = []
    @Published var tasks: [FeedingTask] = []
    @Published var activity: [ActivityEvent] = []

    private let ingredientsKey = "fp.ingredients.v1"
    private let recipesKey     = "fp.recipes.v1"
    private let stockKey       = "fp.stock.v1"
    private let costsKey       = "fp.costs.v1"
    private let tasksKey       = "fp.tasks.v1"
    private let activityKey    = "fp.activity.v1"
    private let seededKey      = "fp.seeded.v1"

    private var bag: Set<AnyCancellable> = []

    init() {
        load()
        if !UserDefaults.standard.bool(forKey: seededKey) {
            seedDefaults()
            UserDefaults.standard.set(true, forKey: seededKey)
        }
        bind()
    }

    // MARK: Persistence

    private func bind() {
        $ingredients.dropFirst().sink { [weak self] in self?.save($0, key: self?.ingredientsKey ?? "") }.store(in: &bag)
        $recipes.dropFirst().sink     { [weak self] in self?.save($0, key: self?.recipesKey ?? "") }.store(in: &bag)
        $stockEntries.dropFirst().sink{ [weak self] in self?.save($0, key: self?.stockKey ?? "") }.store(in: &bag)
        $costs.dropFirst().sink       { [weak self] in self?.save($0, key: self?.costsKey ?? "") }.store(in: &bag)
        $tasks.dropFirst().sink       { [weak self] in self?.save($0, key: self?.tasksKey ?? "") }.store(in: &bag)
        $activity.dropFirst().sink    { [weak self] in self?.save($0, key: self?.activityKey ?? "") }.store(in: &bag)
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        guard !key.isEmpty else { return }
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        ingredients   = decode(ingredientsKey) ?? []
        recipes       = decode(recipesKey) ?? []
        stockEntries  = decode(stockKey) ?? []
        costs         = decode(costsKey) ?? []
        tasks         = decode(tasksKey) ?? []
        activity      = decode(activityKey) ?? []
    }

    private func decode<T: Decodable>(_ key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func seedDefaults() {
        ingredients = Ingredient.defaults()
        let now = Date()
        let cal = Calendar.current
        tasks = [
            FeedingTask(title: "Morning feed", scheduledAt: cal.date(bySettingHour: 7, minute: 30, second: 0, of: now) ?? now, recurrence: .daily, notify: true, isDone: false, notes: "Top up feeders for the chickens"),
            FeedingTask(title: "Evening feed", scheduledAt: cal.date(bySettingHour: 18, minute: 0, second: 0, of: now) ?? now, recurrence: .daily, notify: true, isDone: false, notes: "Final feed and water check"),
        ]
        costs = [
            CostRecord(title: "Corn purchase", amount: 32.50, category: "Feed"),
            CostRecord(title: "Vitamin mix",   amount: 14.00, category: "Supplements"),
        ]
        activity = [
            ActivityEvent(title: "Welcome to Feed Poultry", detail: "Your farm is ready to optimize", icon: "sparkles")
        ]
    }

    // MARK: Helpers

    func ingredient(by id: UUID) -> Ingredient? {
        ingredients.first(where: { $0.id == id })
    }

    func updateIngredient(_ ing: Ingredient) {
        if let idx = ingredients.firstIndex(where: { $0.id == ing.id }) {
            ingredients[idx] = ing
        }
    }

    func addIngredient(_ ing: Ingredient) {
        ingredients.append(ing)
        log(ActivityEvent(title: "Ingredient added", detail: ing.name, icon: "plus.circle.fill"))
    }

    func deleteIngredient(at offsets: IndexSet) {
        let names = offsets.map { ingredients[$0].name }.joined(separator: ", ")
        ingredients.remove(atOffsets: offsets)
        if !names.isEmpty {
            log(ActivityEvent(title: "Ingredient removed", detail: names, icon: "trash.fill"))
        }
    }

    func adjustStock(ingredientId: UUID, deltaGrams: Double, kind: StockChangeKind) {
        guard let idx = ingredients.firstIndex(where: { $0.id == ingredientId }) else { return }
        ingredients[idx].grams = max(0, ingredients[idx].grams + deltaGrams)
        let entry = StockEntry(ingredientId: ingredientId,
                               ingredientName: ingredients[idx].name,
                               grams: deltaGrams,
                               kind: kind)
        stockEntries.insert(entry, at: 0)
        log(ActivityEvent(title: "Stock \(kind.title.lowercased())",
                          detail: "\(ingredients[idx].name): \(Int(abs(deltaGrams))) g",
                          icon: "shippingbox.fill"))
    }

    func saveRecipe(_ recipe: Recipe) {
        if let idx = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes[idx] = recipe
        } else {
            recipes.insert(recipe, at: 0)
        }
        log(ActivityEvent(title: "Recipe saved", detail: recipe.name, icon: "bookmark.fill"))
    }

    func deleteRecipe(at offsets: IndexSet) {
        let names = offsets.map { recipes[$0].name }.joined(separator: ", ")
        recipes.remove(atOffsets: offsets)
        if !names.isEmpty {
            log(ActivityEvent(title: "Recipe deleted", detail: names, icon: "trash.fill"))
        }
    }

    func addCost(_ cost: CostRecord) {
        costs.insert(cost, at: 0)
        log(ActivityEvent(title: "Cost added", detail: cost.title, icon: "dollarsign.circle.fill"))
    }

    func deleteCost(at offsets: IndexSet) {
        costs.remove(atOffsets: offsets)
    }

    func addTask(_ task: FeedingTask) {
        tasks.append(task)
        log(ActivityEvent(title: "Task added", detail: task.title, icon: "checklist"))
    }

    func toggleTask(_ task: FeedingTask) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx].isDone.toggle()
        }
    }

    func deleteTask(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
    }

    func updateTask(_ task: FeedingTask) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx] = task
        }
    }

    func log(_ event: ActivityEvent) {
        activity.insert(event, at: 0)
        if activity.count > 100 { activity = Array(activity.prefix(100)) }
    }

    func logActivity(title: String, detail: String = "", icon: String = "circle.fill") {
        log(ActivityEvent(title: title, detail: detail, icon: icon))
    }

    func clearActivity() {
        activity.removeAll()
    }

    func resetAllData() {
        ingredients = Ingredient.defaults()
        recipes.removeAll()
        stockEntries.removeAll()
        costs.removeAll()
        tasks.removeAll()
        activity = [ActivityEvent(title: "Data reset", detail: "Farm reset to defaults", icon: "arrow.counterclockwise.circle.fill")]
    }

    func resetAll() { resetAllData() }

    // MARK: Computed dashboard helpers

    var totalStockGrams: Double {
        ingredients.reduce(0) { $0 + $1.grams }
    }

    var totalStockValue: Double {
        ingredients.reduce(0) { $0 + ($1.grams / 1000.0) * $1.pricePerKg }
    }

    var totalSpent: Double {
        costs.reduce(0) { $0 + $1.amount }
    }

    var pendingTasksCount: Int {
        tasks.filter { !$0.isDone }.count
    }
}
