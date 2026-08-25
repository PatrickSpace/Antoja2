import Charts
import SwiftUI

struct ProgressDashboardView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ProgressViewModel

    private let albumColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    init(userID: String) {
        _viewModel = StateObject(wrappedValue: ProgressViewModel(userID: userID))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView("Preparando tu progreso…")
                        .tint(AppTheme.accent)
                        .foregroundStyle(AppTheme.ink)
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            weekSelector
                            weeklyHero
                            experienceCard
                            historyChart
                            weeklyAlbum
                            badgesSection
                            estimationNote
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationTitle("Progreso")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                        .foregroundStyle(AppTheme.accent)
                }
            }
        }
        .alert("No pudimos cargar tu progreso", isPresented: errorBinding) {
            Button("Entendido", role: .cancel) { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? "Inténtalo nuevamente.")
        }
        .preferredColorScheme(.light)
    }

    private var weekSelector: some View {
        HStack(spacing: 14) {
            weekButton(
                systemImage: "chevron.left",
                isEnabled: viewModel.canGoToPreviousWeek,
                action: viewModel.goToPreviousWeek
            )

            VStack(spacing: 3) {
                Text(weekTitle)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                Text(isCurrentWeek ? "Esta semana" : "Semana completada")
                    .font(.caption)
                    .foregroundStyle(AppTheme.mutedInk)
            }
            .frame(maxWidth: .infinity)

            weekButton(
                systemImage: "chevron.right",
                isEnabled: viewModel.canGoToNextWeek,
                action: viewModel.goToNextWeek
            )
        }
        .padding(.horizontal, 4)
    }

    private var weeklyHero: some View {
        VStack(spacing: 18) {
            VStack(spacing: 5) {
                Text(viewModel.selectedWeek.estimatedAvoidedCalories.formatted())
                    .font(.system(size: 50, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text("kcal evitadas estimadas")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.92))
                Text(viewModel.selectedWeek.avoidedCaloriesRangeText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.75))
            }

            HStack(spacing: 10) {
                ProgressMetric(
                    value: viewModel.selectedWeek.avoidedCravings.count,
                    label: "Evitados",
                    systemImage: "sparkles"
                )
                ProgressMetric(
                    value: viewModel.selectedWeek.resolvedCount,
                    label: "Resueltos",
                    systemImage: "checkmark.circle.fill"
                )
                ProgressMetric(
                    value: viewModel.selectedWeek.pendingCount,
                    label: "Pendientes",
                    systemImage: "clock.fill"
                )
            }
        }
        .padding(22)
        .background {
            LinearGradient(
                colors: [AppTheme.accent, Color(red: 0.96, green: 0.49, blue: 0.24)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: AppTheme.accent.opacity(0.22), radius: 22, y: 12)
        .animation(.easeInOut(duration: 0.25), value: viewModel.selectedWeek.weekStart)
    }

    private var experienceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accentSoft.opacity(0.75))
                    Image(systemName: "star.fill")
                        .foregroundStyle(AppTheme.accent)
                }
                .frame(width: 46, height: 46)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Nivel \(viewModel.level)")
                        .font(.headline.weight(.black))
                        .foregroundStyle(AppTheme.ink)
                    Text("\(viewModel.experiencePoints) XP por seguimientos honestos")
                        .font(.caption)
                        .foregroundStyle(AppTheme.mutedInk)
                }

                Spacer()

                VStack(spacing: 2) {
                    Label("\(viewModel.checkInStreak)", systemImage: "flame.fill")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.accent)
                    Text("racha")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppTheme.mutedInk)
                }
            }

            ProgressView(value: viewModel.levelProgress)
                .tint(AppTheme.green)
                .scaleEffect(x: 1, y: 1.8, anchor: .center)

            Text("\(viewModel.pointsUntilNextLevel) XP para el siguiente nivel · Cada resultado suma, lo hayas comido o no.")
                .font(.caption)
                .foregroundStyle(AppTheme.mutedInk)
        }
        .padding(18)
        .antojaCard()
    }

    private var historyChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Últimas 8 semanas")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                Text("Calorías evitadas estimadas")
                    .font(.caption)
                    .foregroundStyle(AppTheme.mutedInk)
            }

            Chart(viewModel.chartWeeks) { week in
                BarMark(
                    x: .value("Semana", week.weekStart),
                    y: .value("Calorías", week.estimatedAvoidedCalories),
                    width: .ratio(0.58)
                )
                .foregroundStyle(
                    week.weekStart == viewModel.selectedWeek.weekStart
                        ? AppTheme.accent
                        : AppTheme.accentSoft
                )
                .cornerRadius(6)
            }
            .chartYScale(domain: 0...viewModel.chartMaximum)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine().foregroundStyle(.clear)
                    AxisTick().foregroundStyle(AppTheme.border)
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        .foregroundStyle(AppTheme.mutedInk)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) {
                    AxisGridLine().foregroundStyle(AppTheme.border)
                    AxisValueLabel().foregroundStyle(AppTheme.mutedInk)
                }
            }
            .frame(height: 190)
        }
        .padding(18)
        .antojaCard()
    }

    private var weeklyAlbum: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Tu colección semanal")
                    .font(.title3.weight(.black))
                    .foregroundStyle(AppTheme.ink)
                Text("Cada tarjeta representa algo que confirmaste que no comiste.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.mutedInk)
            }

            if viewModel.selectedWeek.avoidedCravings.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(AppTheme.accent)
                    Text("Tu colección está lista para crecer")
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                    Text("Los antojos confirmados como no comidos aparecerán aquí.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.mutedInk)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .padding(.horizontal, 18)
                .antojaCard()
            } else {
                LazyVGrid(columns: albumColumns, spacing: 12) {
                    ForEach(viewModel.selectedWeek.avoidedCravings) { craving in
                        AvoidedCravingCollectible(craving: craving)
                    }
                }
            }
        }
    }

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Insignias")
                .font(.title3.weight(.black))
                .foregroundStyle(AppTheme.ink)

            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(viewModel.badges) { badge in
                        ProgressBadgeCard(badge: badge)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private var estimationNote: some View {
        Label(
            "Las calorías son estimaciones basadas en los supuestos confirmados y no equivalen directamente a pérdida de peso.",
            systemImage: "info.circle"
        )
        .font(.caption)
        .foregroundStyle(AppTheme.mutedInk)
        .padding(.horizontal, 6)
        .padding(.bottom, 12)
    }

    private func weekButton(systemImage: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(isEnabled ? AppTheme.ink : AppTheme.mutedInk.opacity(0.25))
                .frame(width: 42, height: 42)
                .background(.white.opacity(isEnabled ? 0.9 : 0.4))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private var weekTitle: String {
        let lastDay = viewModel.selectedWeek.weekEnd.addingTimeInterval(-24 * 60 * 60)
        return "\(viewModel.selectedWeek.weekStart.formatted(.dateTime.day().month(.abbreviated))) – \(lastDay.formatted(.dateTime.day().month(.abbreviated)))"
    }

    private var isCurrentWeek: Bool {
        !viewModel.canGoToNextWeek
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.clearError() } }
        )
    }
}

private struct ProgressMetric: View {
    let value: Int
    let label: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 5) {
            Label("\(value)", systemImage: systemImage)
                .font(.headline.weight(.black))
            Text(label)
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .background(.white.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct AvoidedCravingCollectible: View {
    let craving: ProgressCraving

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(AppTheme.accentSoft.opacity(0.7))
                    Image(systemName: craving.foodSymbol)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                }
                .frame(width: 48, height: 48)

                Spacer()

                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(AppTheme.green)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(craving.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)
                Text(craving.portionText)
                    .font(.caption)
                    .foregroundStyle(AppTheme.mutedInk)
                    .lineLimit(1)
            }

            Divider()

            Text(craving.calorieRangeText)
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.accent)
            Text(craving.createdAt.formatted(.dateTime.weekday(.wide).day()))
                .font(.caption2)
                .foregroundStyle(AppTheme.mutedInk)
        }
        .padding(15)
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
        .antojaCard()
    }
}

private struct ProgressBadgeCard: View {
    let badge: ProgressBadge

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(badge.isUnlocked ? AppTheme.accentSoft : AppTheme.border)
                Image(systemName: badge.isUnlocked ? badge.systemImage : "lock.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(badge.isUnlocked ? AppTheme.accent : AppTheme.mutedInk)
            }
            .frame(width: 48, height: 48)

            Text(badge.title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.ink)
            Text(badge.subtitle)
                .font(.caption)
                .foregroundStyle(AppTheme.mutedInk)
                .lineLimit(2)
        }
        .padding(16)
        .frame(width: 170, height: 160, alignment: .topLeading)
        .background(badge.isUnlocked ? Color.white : Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        }
    }
}
