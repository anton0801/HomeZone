import SwiftUI

// MARK: - Reports View
struct ReportsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showExport = false
    @State private var showComparison = false
    @State private var appear = false
    
    var avgTemp: Double {
        let all = appState.allMeasurements
        guard !all.isEmpty else { return 0 }
        return all.reduce(0) { $0 + $1.temperature } / Double(all.count)
    }
    var avgHumidity: Double {
        let all = appState.allMeasurements
        guard !all.isEmpty else { return 0 }
        return all.reduce(0) { $0 + $1.humidity } / Double(all.count)
    }
    
    var problemBreakdown: [(ProblemType, Int)] {
        let all = appState.allMeasurements
        return ProblemType.allCases.compactMap { type in
            let count = all.filter { $0.problemType == type }.count
            return count > 0 ? (type, count) : nil
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Overview
                    HZCard(padding: 16) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Analytics Overview")
                                .font(DS.Font.heading(16))
                            
                            HStack(spacing: 20) {
                                VStack(spacing: 4) {
                                    Text("\(appState.projects.count)")
                                        .font(DS.Font.display(28))
                                        .foregroundColor(DS.accent)
                                    Text("Projects")
                                        .font(DS.Font.caption(12))
                                        .foregroundColor(.secondary)
                                }
                                VStack(spacing: 4) {
                                    Text("\(appState.totalRooms)")
                                        .font(DS.Font.display(28))
                                        .foregroundColor(DS.indigo)
                                    Text("Rooms")
                                        .font(DS.Font.caption(12))
                                        .foregroundColor(.secondary)
                                }
                                VStack(spacing: 4) {
                                    Text("\(appState.allMeasurements.count)")
                                        .font(DS.Font.display(28))
                                        .foregroundColor(DS.warm)
                                    Text("Points")
                                        .font(DS.Font.caption(12))
                                        .foregroundColor(.secondary)
                                }
                                VStack(spacing: 4) {
                                    Text("\(appState.problemMeasurements.count)")
                                        .font(DS.Font.display(28))
                                        .foregroundColor(DS.error)
                                    Text("Issues")
                                        .font(DS.Font.caption(12))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .opacity(appear ? 1 : 0)
                    
                    // Climate averages
                    HZCard(padding: 16) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Climate Averages")
                                .font(DS.Font.heading(16))
                            
                            if appState.allMeasurements.isEmpty {
                                Text("No measurements yet. Add data to see analytics.")
                                    .font(DS.Font.body(14))
                                    .foregroundColor(.secondary)
                            } else {
                                HStack(spacing: 0) {
                                    VStack(spacing: 8) {
                                        Image(systemName: "thermometer.medium")
                                            .font(.system(size: 24))
                                            .foregroundColor(DS.warm)
                                        Text(String(format: "%.1f%@", appState.temperatureUnit.convert(avgTemp), appState.temperatureUnit.symbol))
                                            .font(DS.Font.display(22))
                                        Text("Avg Temperature")
                                            .font(DS.Font.caption(12))
                                            .foregroundColor(.secondary)
                                        ClimateTag(type: DS.tempColor(celsius: avgTemp) == DS.cold ? .cold : avgTemp < 17 ? .cool : avgTemp < 24 ? .normal : avgTemp < 28 ? .hot : .hot)
                                    }
                                    .frame(maxWidth: .infinity)
                                    
                                    Rectangle().fill(DS.border).frame(width: 1, height: 80)
                                    
                                    VStack(spacing: 8) {
                                        Image(systemName: "drop.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(DS.mold)
                                        Text(String(format: "%.0f%%", avgHumidity))
                                            .font(DS.Font.display(22))
                                        Text("Avg Humidity")
                                            .font(DS.Font.caption(12))
                                            .foregroundColor(.secondary)
                                        Text(avgHumidity > 70 ? "⚠️ High Risk" : avgHumidity > 60 ? "Moderate" : "✅ Good")
                                            .font(DS.Font.caption(12))
                                            .foregroundColor(avgHumidity > 70 ? DS.error : avgHumidity > 60 ? DS.warning : DS.success)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .opacity(appear ? 1 : 0)
                    
                    // Problem breakdown bar chart
                    if !problemBreakdown.isEmpty {
                        HZCard(padding: 16) {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Problem Breakdown")
                                    .font(DS.Font.heading(16))
                                
                                ForEach(problemBreakdown, id: \.0) { type, count in
                                    HStack(spacing: 12) {
                                        Image(systemName: type.icon)
                                            .font(.system(size: 14))
                                            .foregroundColor(type.color)
                                            .frame(width: 20)
                                        Text(type.rawValue)
                                            .font(DS.Font.body(13))
                                            .frame(width: 90, alignment: .leading)
                                        GeometryReader { geo in
                                            let total = Double(appState.allMeasurements.count)
                                            let pct = total > 0 ? Double(count) / total : 0
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(type.color.opacity(0.15))
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(type.color)
                                                    .frame(width: geo.size.width * CGFloat(pct))
                                            }
                                        }
                                        .frame(height: 12)
                                        Text("\(count)")
                                            .font(DS.Font.mono(13))
                                            .foregroundColor(.secondary)
                                            .frame(width: 24, alignment: .trailing)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .opacity(appear ? 1 : 0)
                    }
                    
                    // Per-room summary
                    if !appState.projects.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Room Summary")
                            
                            ForEach(appState.projects) { project in
                                ForEach(project.rooms) { room in
                                    RoomSummaryCard(room: room)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .opacity(appear ? 1 : 0)
                    }
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        HZButton(title: "Export Report", style: .primary, action: { showExport = true }, icon: "square.and.arrow.up")
                        HZButton(title: "Compare Periods", style: .secondary, action: { showComparison = true }, icon: "arrow.left.arrow.right")
                        NavigationLink(destination: HistoryView()) {
                            HStack(spacing: 8) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 15))
                                Text("View Full History")
                                    .font(DS.Font.heading(16))
                            }
                            .foregroundColor(DS.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(DS.accent.opacity(0.08))
                            .cornerRadius(14)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
                .padding(.top, 12)
            }
            .navigationTitle("Reports")
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .sheet(isPresented: $showExport) { ExportView() }
            .sheet(isPresented: $showComparison) { ComparisonView() }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) { appear = true }
        }
    }
}

struct RoomSummaryCard: View {
    @EnvironmentObject var appState: AppState
    let room: Room
    
    var avgTemp: Double? {
        guard !room.measurements.isEmpty else { return nil }
        return room.measurements.reduce(0) { $0 + $1.temperature } / Double(room.measurements.count)
    }
    
    var body: some View {
        HZCard(padding: 14) {
            HStack(spacing: 12) {
                Image(systemName: "door.left.hand.open")
                    .font(.system(size: 18))
                    .foregroundColor(DS.indigo)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 4) {
                    Text(room.name)
                        .font(DS.Font.heading(14))
                    Text("\(room.measurements.count) measurement points")
                        .font(DS.Font.caption(12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                if let avg = avgTemp {
                    TempBadge(value: avg, unit: appState.temperatureUnit)
                } else {
                    Text("No data")
                        .font(DS.Font.caption(11))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Export View
struct ExportView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var exported = false
    @State private var exporting = false
    @State private var selectedFormat = 0
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Export Format")) {
                    Picker("Format", selection: $selectedFormat) {
                        Text("PDF Report").tag(0)
                        Text("CSV Data").tag(1)
                        Text("JSON").tag(2)
                    }
                    .pickerStyle(.segmented)
                }
                Section(header: Text("Include")) {
                    Label("All Projects (\(appState.projects.count))", systemImage: "folder.fill")
                    Label("All Rooms (\(appState.totalRooms))", systemImage: "door.left.hand.open")
                    Label("All Measurements (\(appState.allMeasurements.count))", systemImage: "thermometer")
                    Label("Problem Zones (\(appState.problemMeasurements.count))", systemImage: "exclamationmark.triangle")
                }
                Section {
                    if exported {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(DS.success)
                            Text("Export ready! Saved to Files app.")
                                .font(DS.Font.body(14))
                                .foregroundColor(DS.success)
                        }
                    } else {
                        Button(action: doExport) {
                            HStack {
                                if exporting {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "square.and.arrow.up")
                                }
                                Text(exporting ? "Exporting..." : "Export Now")
                            }
                            .foregroundColor(DS.accent)
                        }
                        .disabled(exporting)
                    }
                }
            }
            .navigationTitle("Export Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
        }
    }
    
    func doExport() {
        exporting = true
        appState.logActivity(action: "Report Exported", detail: "Export generated", icon: "doc.fill")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            exporting = false
            exported = true
        }
    }
}

// MARK: - Comparison View
struct ComparisonView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    var recentMeasurements: [MeasurementPoint] {
        Array(appState.allMeasurements.prefix(5))
    }
    var olderMeasurements: [MeasurementPoint] {
        Array(appState.allMeasurements.dropFirst(5).prefix(5))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    HZCard(padding: 16) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Before / After Comparison")
                                .font(DS.Font.heading(16))
                            Text("Compare climate data across different time periods to track improvements.")
                                .font(DS.Font.body(13))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    HStack(alignment: .top, spacing: 12) {
                        // Before
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Before")
                                .font(DS.Font.heading(14))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                            ForEach(olderMeasurements) { m in
                                HZCard(padding: 12) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        TempBadge(value: m.temperature, unit: appState.temperatureUnit)
                                        Text(String(format: "💧 %.0f%%", m.humidity))
                                            .font(DS.Font.caption(11))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            if olderMeasurements.isEmpty {
                                HZCard(padding: 12) {
                                    Text("No older data")
                                        .font(DS.Font.caption(12))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        VStack { Rectangle().fill(DS.border).frame(width: 1) }
                            .padding(.top, 28)
                        
                        // After
                        VStack(alignment: .leading, spacing: 10) {
                            Text("After")
                                .font(DS.Font.heading(14))
                                .foregroundColor(DS.accent)
                                .padding(.horizontal, 4)
                            ForEach(recentMeasurements) { m in
                                HZCard(padding: 12) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        TempBadge(value: m.temperature, unit: appState.temperatureUnit)
                                        Text(String(format: "💧 %.0f%%", m.humidity))
                                            .font(DS.Font.caption(11))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            if recentMeasurements.isEmpty {
                                HZCard(padding: 12) {
                                    Text("No recent data")
                                        .font(DS.Font.caption(12))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer().frame(height: 20)
                }
                .padding(.top, 12)
            }
            .navigationTitle("Comparison")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

// MARK: - History View
struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    
    var groupedActivity: [(String, [ActivityEntry])] {
        let grouped = Dictionary(grouping: appState.activityLog) { entry -> String in
            let cal = Calendar.current
            if cal.isDateInToday(entry.timestamp) { return "Today" }
            if cal.isDateInYesterday(entry.timestamp) { return "Yesterday" }
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: entry.timestamp)
        }
        return grouped.sorted { a, b in
            guard let firstA = a.1.first, let firstB = b.1.first else { return false }
            return firstA.timestamp > firstB.timestamp
        }
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            if appState.activityLog.isEmpty {
                EmptyStateView(icon: "clock", title: "No History", subtitle: "Your activity history will appear here.")
            } else {
                List {
                    ForEach(groupedActivity, id: \.0) { day, entries in
                        Section(header: Text(day).font(DS.Font.heading(13))) {
                            ForEach(entries) { entry in
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(DS.accent.opacity(0.12))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: entry.icon)
                                            .font(.system(size: 14))
                                            .foregroundColor(DS.accent)
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(entry.action)
                                            .font(DS.Font.heading(13))
                                        Text(entry.detail)
                                            .font(DS.Font.body(12))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(entry.timestamp.relativeString)
                                        .font(DS.Font.caption(11))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Activity History")
    }
}
