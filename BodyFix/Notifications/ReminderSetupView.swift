import SwiftUI
import SwiftData

struct ReminderSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    @State private var selectedDays: Set<Int> = []
    @State private var selectedTime: Date?
    @State private var showsTimePicker = false
    @State private var hint: String?

    private let days: [(weekday: Int, label: String)] = [
        (2, "M"), (3, "T"), (4, "W"), (5, "T"), (6, "F"), (7, "S"), (1, "S"),
    ]

    private var canSave: Bool {
        !selectedDays.isEmpty && selectedTime != nil
    }

    private var primaryProblemArea: String? {
        profiles.first?.problemAreas.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bfPageBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 26) {
                        header
                        daySection
                        timeSection

                        if let hint {
                            Text(hint)
                                .font(Typography.caption)
                                .foregroundStyle(Color.bfSliderWarm)
                        }

                        saveButton
                    }
                    .padding(22)
                    .padding(.bottom, 34)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        HStack {
            Button {
                HapticManager.shared.softImpact()
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.bfTextPrimary)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.bfSurfaceElevated))
                    .overlay(Circle().stroke(Color.bfBorder.opacity(0.65), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Reminder Setup")
                .font(Typography.sectionTitle)
                .foregroundStyle(Color.bfTextPrimary)

            Spacer()
            Color.clear.frame(width: 38, height: 38)
        }
    }

    private var daySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WHEN DO YOU WANT TO STRETCH?")
                .font(Typography.metadataBadge)
                .foregroundStyle(Color.bfTextMuted)

            Text("Days")
                .font(Typography.sectionTitle)
                .foregroundStyle(Color.bfTextPrimary)

            HStack(spacing: 10) {
                ForEach(days, id: \.weekday) { item in
                    let isSelected = selectedDays.contains(item.weekday)
                    Button {
                        HapticManager.shared.selection()
                        if isSelected {
                            selectedDays.remove(item.weekday)
                        } else {
                            selectedDays.insert(item.weekday)
                        }
                        hint = selectedDays.isEmpty ? "Select at least one day" : nil
                    } label: {
                        VStack(spacing: 8) {
                            Text(item.label)
                                .font(Typography.metadataBadge)
                            Circle()
                                .fill(isSelected ? Color(hex: "#5EEAD4") : Color.clear)
                                .frame(width: 11, height: 11)
                                .overlay(Circle().stroke(isSelected ? Color.clear : Color.bfBorder, lineWidth: 1))
                        }
                        .foregroundStyle(isSelected ? Color.bfHeroSurface : Color.bfTextSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 72)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(isSelected ? Color(hex: "#5EEAD4").opacity(0.22) : Color.bfSurfaceElevated)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(isSelected ? Color(hex: "#5EEAD4").opacity(0.7) : Color.bfBorder.opacity(0.55), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("Tap to choose your reminder days")
                .font(Typography.caption)
                .foregroundStyle(Color.bfTextTertiary)
        }
    }

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time")
                .font(Typography.sectionTitle)
                .foregroundStyle(Color.bfTextPrimary)

            Button {
                if !showsTimePicker {
                    HapticManager.shared.lightImpact()
                }
                if selectedTime == nil {
                    selectedTime = Date()
                }
                showsTimePicker = true
                hint = nil
            } label: {
                HStack {
                    Text(timeLabel)
                        .font(Typography.controlLabel)
                        .foregroundStyle(selectedTime == nil ? Color.bfTextMuted : Color.bfTextPrimary)
                    Spacer()
                    Image(systemName: "clock.fill")
                        .foregroundStyle(Color.bfBlue)
                }
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.bfSurfaceElevated))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.bfBorder.opacity(0.55), lineWidth: 1))
            }
            .buttonStyle(.plain)

            if showsTimePicker {
                DatePicker(
                    "Reminder time",
                    selection: Binding(
                        get: { selectedTime ?? Date() },
                        set: { selectedTime = $0 }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.bfSurfaceElevated))
            }
        }
    }

    private var saveButton: some View {
        Button {
            guard let selectedTime, canSave else {
                hint = selectedDays.isEmpty ? "Select at least one day" : "Choose a reminder time"
                return
            }

            let components = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
            guard let hour = components.hour, let minute = components.minute else { return }

            NotificationManager.shared.requestPermission { granted in
                guard granted else {
                    HapticManager.shared.error()
                    hint = "Notifications are disabled. Enable them in Settings to save reminders."
                    return
                }
                NotificationManager.shared.scheduleReminders(
                    days: selectedDays,
                    hour: hour,
                    minute: minute,
                    problemArea: primaryProblemArea
                ) { didSchedule in
                    if didSchedule {
                        HapticManager.shared.success()
                        dismiss()
                    } else {
                        HapticManager.shared.error()
                        hint = "We couldn't save your reminders. Please try again."
                    }
                }
            }
        } label: {
            Text("Save")
                .font(Typography.primaryCta)
                .foregroundStyle(canSave ? Color.bfHeroSurface : Color.bfTextDisabled)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(canSave ? Color(hex: "#5EEAD4") : Color.bfBorder.opacity(0.42))
                )
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
        .padding(.top, 8)
    }

    private var timeLabel: String {
        guard let selectedTime else { return "Choose time" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: selectedTime)
    }
}
