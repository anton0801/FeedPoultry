import SwiftUI

struct TasksView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var notifications: NotificationManager
    @State private var showAdd = false
    @State private var editingTask: FeedingTask?

    var pending: [FeedingTask] {
        store.tasks.filter { !$0.isDone }.sorted { $0.scheduledAt < $1.scheduledAt }
    }

    var done: [FeedingTask] {
        store.tasks.filter { $0.isDone }.sorted { $0.scheduledAt > $1.scheduledAt }
    }

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    headerCard

                    SectionHeader(title: "Upcoming", subtitle: "\(pending.count) tasks")
                    if pending.isEmpty {
                        EmptyState(icon: "checkmark.seal.fill", title: "No pending tasks")
                            .cardStyle()
                    } else {
                        VStack(spacing: 10) {
                            ForEach(pending) { task in
                                TaskRow(task: task) {
                                    toggleDone(task)
                                } onEdit: {
                                    editingTask = task
                                } onDelete: {
                                    deleteTask(task)
                                }
                            }
                        }
                    }

                    if !done.isEmpty {
                        SectionHeader(title: "Completed", subtitle: "\(done.count) done")
                        VStack(spacing: 10) {
                            ForEach(done.prefix(8)) { task in
                                TaskRow(task: task) {
                                    toggleDone(task)
                                } onEdit: {
                                    editingTask = task
                                } onDelete: {
                                    deleteTask(task)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Tasks")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(AppTheme.grainActive)
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            TaskEditSheet(task: nil) { newTask in
                store.tasks.insert(newTask, at: 0)
                store.logActivity(title: "Task added", detail: newTask.title, icon: "calendar.badge.plus")
                if newTask.notify {
                    notifications.scheduleTask(newTask)
                }
            }
            .environmentObject(store)
            .environmentObject(notifications)
        }
        .sheet(item: $editingTask) { task in
            TaskEditSheet(task: task) { updated in
                if let idx = store.tasks.firstIndex(where: { $0.id == updated.id }) {
                    store.tasks[idx] = updated
                    notifications.cancel(id: updated.id.uuidString)
                    if updated.notify { notifications.scheduleTask(updated) }
                    store.logActivity(title: "Task updated", detail: updated.title, icon: "calendar")
                }
            }
            .environmentObject(store)
            .environmentObject(notifications)
        }
    }

    private var headerCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.healthGradient)
                    .frame(width: 56, height: 56)
                Image(systemName: "list.bullet.clipboard.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Feeding Schedule")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Text("Plan and get reminded for every feed.")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
        }
        .cardStyle()
    }

    private func toggleDone(_ task: FeedingTask) {
        guard let idx = store.tasks.firstIndex(where: { $0.id == task.id }) else { return }
        store.tasks[idx].isDone.toggle()
        if store.tasks[idx].isDone {
            notifications.cancel(id: task.id.uuidString)
            store.logActivity(title: "Task completed", detail: task.title, icon: "checkmark.circle.fill")
        }
    }

    private func deleteTask(_ task: FeedingTask) {
        store.tasks.removeAll { $0.id == task.id }
        notifications.cancel(id: task.id.uuidString)
        store.logActivity(title: "Task removed", detail: task.title, icon: "trash")
    }
}

struct TaskRow: View {
    let task: FeedingTask
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .stroke(task.isDone ? AppTheme.healthMain : AppTheme.divider, lineWidth: 2)
                        .frame(width: 28, height: 28)
                    if task.isDone {
                        Circle()
                            .fill(AppTheme.healthMain)
                            .frame(width: 18, height: 18)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .strikethrough(task.isDone, color: AppTheme.textInactive)
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.textInactive)
                    Text(scheduledLabel)
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                    if task.notify && !task.isDone {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.grainActive)
                    }
                    Text(task.recurrence.displayName)
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(AppTheme.grainHighlight))
                        .foregroundColor(AppTheme.earthDark)
                }
            }

            Spacer()

            Menu {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.cardBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.divider, lineWidth: 1)
        )
    }

    private var scheduledLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d • HH:mm"
        return formatter.string(from: task.scheduledAt)
    }
}

struct TaskEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var draft: FeedingTask
    let onSave: (FeedingTask) -> Void
    let isNew: Bool

    init(task: FeedingTask?, onSave: @escaping (FeedingTask) -> Void) {
        if let t = task {
            self._draft = State(initialValue: t)
            self.isNew = false
        } else {
            self._draft = State(initialValue: FeedingTask(
                id: UUID(),
                title: "Morning Feed",
                scheduledAt: Date().addingTimeInterval(3600),
                recurrence: .daily,
                notify: true,
                isDone: false,
                notes: ""
            ))
            self.isNew = true
        }
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            ZStack {
                ScreenBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        AppTextField(label: "Title", text: $draft.title, placeholder: "Morning feed")

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Scheduled at")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppTheme.textSecondary)
                            DatePicker(
                                "",
                                selection: $draft.scheduledAt,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(AppTheme.cardBg)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(AppTheme.divider, lineWidth: 1)
                            )
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Repeats")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppTheme.textSecondary)
                            HStack(spacing: 8) {
                                ForEach(TaskRecurrence.allCases) { rec in
                                    PillButton(
                                        title: rec.displayName,
                                        isSelected: draft.recurrence == rec
                                    ) {
                                        draft.recurrence = rec
                                    }
                                }
                            }
                        }

                        Toggle(isOn: $draft.notify) {
                            HStack(spacing: 10) {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(AppTheme.grainActive)
                                Text("Notify me")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(AppTheme.textPrimary)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: AppTheme.healthMain))
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(AppTheme.cardBg)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.divider, lineWidth: 1)
                        )

                        AppTextField(label: "Notes", text: $draft.notes, placeholder: "Optional details")

                        PrimaryButton(title: isNew ? "Add Task" : "Save Task", icon: "checkmark.circle.fill") {
                            onSave(draft)
                            dismiss()
                        }
                        .disabled(draft.title.trimmingCharacters(in: .whitespaces).isEmpty)
                        .opacity(draft.title.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 18)
                }
            }
            .navigationTitle(isNew ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.earthMain)
                }
            }
        }
    }
}
