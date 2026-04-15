import SwiftUI

// MARK: - Room Detail View
struct RoomDetailView: View {
    @EnvironmentObject var appState: AppState
    let room: Room
    let projectID: UUID
    @State private var showAddMeasure = false
    @State private var showHeatMap = true
    @State private var selectedTab = 0
    
    var currentRoom: Room {
        appState.projects.first(where: { $0.id == projectID })?
            .rooms.first(where: { $0.id == room.id }) ?? room
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                // Segmented picker
                Picker("View", selection: $selectedTab) {
                    Text("Heat Map").tag(0)
                    Text("Measurements").tag(1)
                    Text("Zones").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                
                Group {
                    switch selectedTab {
                    case 0: HeatMapView(room: currentRoom, projectID: projectID)
                    case 1: MeasurementsListView(room: currentRoom, projectID: projectID)
                    default: ProblemZonesView(room: currentRoom)
                    }
                }
            }
        }
        .navigationTitle(currentRoom.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddMeasure = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(DS.accent)
                }
            }
        }
        .sheet(isPresented: $showAddMeasure) {
            AddMeasurementView(room: currentRoom, projectID: projectID)
        }
    }
}

// MARK: - Heat Map View
struct HeatMapView: View {
    @EnvironmentObject var appState: AppState
    let room: Room
    let projectID: UUID
    @State private var selectedPoint: MeasurementPoint? = nil
    @State private var appear = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Heat map canvas
                HZCard(padding: 12) {
                    VStack(spacing: 10) {
                        HStack {
                            Text("Room Plan")
                                .font(DS.Font.heading(14))
                            Spacer()
                            Text("\(String(format: "%.1f", room.width)) × \(String(format: "%.1f", room.height)) m")
                                .font(DS.Font.mono(12))
                                .foregroundColor(.secondary)
                        }
                        
                        GeometryReader { geo in
                            let w = geo.size.width
                            let h = max(geo.size.height, 240)
                            
                            ZStack {
                                // Room background
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(DS.border, lineWidth: 2)
                                    )
                                
                                // Heat blobs
                                Canvas { ctx, size in
                                    for point in room.measurements {
                                        let px = point.x * size.width
                                        let py = point.y * size.height
                                        let radius: CGFloat = min(size.width, size.height) * 0.22
                                        let color = DS.tempColor(celsius: point.temperature)
                                        let rect = CGRect(x: px - radius, y: py - radius, width: radius*2, height: radius*2)
                                        ctx.fill(Path(ellipseIn: rect), with: .color(color.opacity(0.35)))
                                        // Inner
                                        let inner = radius * 0.5
                                        let innerRect = CGRect(x: px - inner, y: py - inner, width: inner*2, height: inner*2)
                                        ctx.fill(Path(ellipseIn: innerRect), with: .color(color.opacity(0.55)))
                                    }
                                }
                                .opacity(appear ? 1 : 0)
                                .animation(.easeIn(duration: 0.8), value: appear)
                                
                                // Measurement dots
                                ForEach(room.measurements) { point in
                                    let px = point.x * w
                                    let py = point.y * h
                                    
                                    Button(action: { selectedPoint = point }) {
                                        ZStack {
                                            Circle()
                                                .fill(DS.tempColor(celsius: point.temperature))
                                                .frame(width: selectedPoint?.id == point.id ? 28 : 20,
                                                       height: selectedPoint?.id == point.id ? 28 : 20)
                                                .shadow(color: DS.tempColor(celsius: point.temperature).opacity(0.5), radius: 6)
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 8, height: 8)
                                        }
                                    }
                                    .position(x: px, y: py)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedPoint?.id)
                                }
                                
                                if room.measurements.isEmpty {
                                    VStack(spacing: 8) {
                                        Image(systemName: "plus.viewfinder")
                                            .font(.system(size: 32))
                                            .foregroundColor(.secondary.opacity(0.5))
                                        Text("Tap + to add measurement points")
                                            .font(DS.Font.caption(13))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .frame(height: 260)
                    }
                }
                .padding(.horizontal, 20)
                
                // Legend
                HZCard(padding: 14) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Temperature Legend")
                            .font(DS.Font.heading(13))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            ForEach([
                                ("< 12°", DS.cold),
                                ("12–17°", DS.cool),
                                ("17–24°", DS.neutral),
                                ("24–29°", DS.warm),
                                ("> 29°", DS.hot)
                            ], id: \.0) { label, color in
                                VStack(spacing: 4) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(color)
                                        .frame(height: 8)
                                    Text(label)
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Selected point detail
                if let pt = selectedPoint {
                    ZoneDetailCard(measurement: pt, projectID: projectID, roomID: room.id)
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer().frame(height: 20)
            }
            .padding(.top, 8)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.4).delay(0.2)) { appear = true }
        }
    }
}

struct HomeZoneWebView: View {
    @State private var targetURL: String? = ""
    @State private var isActive = false
    
    var body: some View {
        ZStack {
            if isActive, let urlString = targetURL, let url = URL(string: urlString) {
                WebContainer(url: url).ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { initialize() }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LoadTempURL"))) { _ in reload() }
    }
    
    private func initialize() {
        let temp = UserDefaults.standard.string(forKey: "temp_url")
        let stored = UserDefaults.standard.string(forKey: "hz_endpoint_target") ?? ""
        targetURL = temp ?? stored
        isActive = true
        if temp != nil { UserDefaults.standard.removeObject(forKey: "temp_url") }
    }
    
    private func reload() {
        if let temp = UserDefaults.standard.string(forKey: "temp_url"), !temp.isEmpty {
            isActive = false
            targetURL = temp
            UserDefaults.standard.removeObject(forKey: "temp_url")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isActive = true }
        }
    }
}

struct ZoneDetailCard: View {
    @EnvironmentObject var appState: AppState
    let measurement: MeasurementPoint
    let projectID: UUID
    let roomID: UUID
    
    var body: some View {
        HZCard(padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(measurement.label.isEmpty ? "Measurement Detail" : measurement.label)
                        .font(DS.Font.heading(16))
                    Spacer()
                    ClimateTag(type: measurement.problemType)
                }
                
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Image(systemName: "thermometer.medium")
                            .foregroundColor(DS.warm)
                        Text(String(format: "%.1f%@", appState.temperatureUnit.convert(measurement.temperature), appState.temperatureUnit.symbol))
                            .font(DS.Font.display(20))
                    }
                    Rectangle().fill(DS.border).frame(width: 1, height: 44)
                    VStack(spacing: 4) {
                        Image(systemName: "drop.fill")
                            .foregroundColor(DS.mold)
                        Text(String(format: "%.0f%%", measurement.humidity))
                            .font(DS.Font.display(20))
                    }
                    Rectangle().fill(DS.border).frame(width: 1, height: 44)
                    VStack(spacing: 4) {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        Text(measurement.timestamp.formatted(date: .omitted, time: .shortened))
                            .font(DS.Font.caption(12))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                if measurement.problemType != .normal {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("💡 Recommendation")
                            .font(DS.Font.heading(13))
                            .foregroundColor(DS.accent)
                        Text(measurement.problemType.recommendation)
                            .font(DS.Font.body(13))
                            .foregroundColor(.secondary)
                            .lineSpacing(3)
                    }
                    .padding(12)
                    .background(DS.accent.opacity(0.06))
                    .cornerRadius(10)
                }
            }
        }
    }
}

// MARK: - Measurements List
struct MeasurementsListView: View {
    @EnvironmentObject var appState: AppState
    let room: Room
    let projectID: UUID
    @State private var showAddMeasure = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if room.measurements.isEmpty {
                    EmptyStateView(icon: "thermometer", title: "No Measurements", subtitle: "Add your first measurement to this room.", buttonTitle: "Add Measurement", action: { showAddMeasure = true })
                } else {
                    ForEach(room.measurements) { m in
                        MeasurementRowCard(measurement: m)
                            .contextMenu {
                                Button(role: .destructive) {
                                    appState.deleteMeasurement(measureID: m.id, roomID: room.id, projectID: projectID)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                Spacer().frame(height: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .sheet(isPresented: $showAddMeasure) {
            AddMeasurementView(room: room, projectID: projectID)
        }
    }
}

struct MeasurementRowCard: View {
    @EnvironmentObject var appState: AppState
    let measurement: MeasurementPoint
    
    var body: some View {
        HZCard(padding: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(DS.tempColor(celsius: measurement.temperature).opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: measurement.problemType.icon)
                        .font(.system(size: 18))
                        .foregroundColor(DS.tempColor(celsius: measurement.temperature))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(measurement.label.isEmpty ? "Point (\(Int(measurement.x*100))%, \(Int(measurement.y*100))%)" : measurement.label)
                        .font(DS.Font.heading(14))
                    Text(measurement.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(DS.Font.caption(11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    TempBadge(value: measurement.temperature, unit: appState.temperatureUnit)
                    Text(String(format: "💧%.0f%%", measurement.humidity))
                        .font(DS.Font.caption(11))
                        .foregroundColor(measurement.humidity > 70 ? DS.mold : .secondary)
                }
            }
        }
    }
}

// MARK: - Problem Zones View
struct ProblemZonesView: View {
    @EnvironmentObject var appState: AppState
    let room: Room
    
    var problems: [MeasurementPoint] { room.measurements.filter { $0.problemType != .normal } }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if problems.isEmpty {
                    VStack(spacing: 12) {
                        HZCard {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(DS.success.opacity(0.15))
                                        .frame(width: 52, height: 52)
                                    Image(systemName: "checkmark.shield.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(DS.success)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("All Clear!")
                                        .font(DS.Font.heading(16))
                                    Text("No problem zones detected in this room.")
                                        .font(DS.Font.body(13))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                } else {
                    ForEach(problems) { m in
                        HZCard(padding: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    ClimateTag(type: m.problemType)
                                    Spacer()
                                    TempBadge(value: m.temperature, unit: appState.temperatureUnit)
                                }
                                Text(m.label.isEmpty ? "Unnamed point" : m.label)
                                    .font(DS.Font.heading(15))
                                Text(m.problemType.recommendation)
                                    .font(DS.Font.body(13))
                                    .foregroundColor(.secondary)
                                    .lineSpacing(3)
                            }
                        }
                    }
                }
                Spacer().frame(height: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }
}

// MARK: - Add Measurement
struct AddMeasurementView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    let room: Room
    let projectID: UUID
    
    @State private var label = ""
    @State private var temperature = "20.0"
    @State private var humidity = "50"
    @State private var xPos = 0.5
    @State private var yPos = 0.5
    @State private var showError = false
    @State private var isDragging = false
    
    var tempVal: Double { Double(temperature) ?? 20.0 }
    var humVal: Double { Double(humidity) ?? 50.0 }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Position picker
                    HZCard(padding: 14) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Point Position")
                                .font(DS.Font.heading(14))
                            Text("Drag to place the measurement point on the room plan")
                                .font(DS.Font.caption(12))
                                .foregroundColor(.secondary)
                            
                            GeometryReader { geo in
                                let w = geo.size.width
                                let h = geo.size.height
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(DS.border, lineWidth: 2)
                                        )
                                    
                                    // Grid lines
                                    Path { p in
                                        for i in 1..<4 {
                                            let x = w * CGFloat(i) / 4
                                            p.move(to: CGPoint(x: x, y: 0))
                                            p.addLine(to: CGPoint(x: x, y: h))
                                        }
                                        for i in 1..<4 {
                                            let y = h * CGFloat(i) / 4
                                            p.move(to: CGPoint(x: 0, y: y))
                                            p.addLine(to: CGPoint(x: w, y: y))
                                        }
                                    }
                                    .stroke(DS.border, lineWidth: 0.5)
                                    
                                    // Point
                                    ZStack {
                                        Circle()
                                            .fill(DS.tempColor(celsius: tempVal).opacity(0.3))
                                            .frame(width: 50, height: 50)
                                        Circle()
                                            .fill(DS.tempColor(celsius: tempVal))
                                            .frame(width: 22, height: 22)
                                        Circle()
                                            .fill(.white)
                                            .frame(width: 9, height: 9)
                                    }
                                    .scaleEffect(isDragging ? 1.2 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
                                    .position(x: xPos * w, y: yPos * h)
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { val in
                                                isDragging = true
                                                xPos = max(0.05, min(0.95, val.location.x / w))
                                                yPos = max(0.05, min(0.95, val.location.y / h))
                                            }
                                            .onEnded { _ in isDragging = false }
                                    )
                                }
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { val in
                                            xPos = max(0.05, min(0.95, val.location.x / w))
                                            yPos = max(0.05, min(0.95, val.location.y / h))
                                        }
                                )
                            }
                            .frame(height: 200)
                            
                            Text("Position: \(Int(xPos*100))%, \(Int(yPos*100))%")
                                .font(DS.Font.mono(12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Inputs
                    HZCard(padding: 16) {
                        VStack(spacing: 14) {
                            HZTextField(placeholder: "Label (e.g. Window corner)", text: $label, icon: "tag")
                            
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Temperature (°C)")
                                        .font(DS.Font.caption(12))
                                        .foregroundColor(.secondary)
                                    HZTextField(placeholder: "20.0", text: $temperature, icon: "thermometer", keyboardType: .decimalPad)
                                }
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Humidity (%)")
                                        .font(DS.Font.caption(12))
                                        .foregroundColor(.secondary)
                                    HZTextField(placeholder: "50", text: $humidity, icon: "drop", keyboardType: .decimalPad)
                                }
                            }
                            
                            // Preview
                            HStack(spacing: 12) {
                                TempBadge(value: tempVal, unit: .celsius)
                                ClimateTag(type: problemType)
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    if showError {
                        Text("Please enter valid temperature and humidity values.")
                            .font(DS.Font.caption(13))
                            .foregroundColor(DS.error)
                            .padding(.horizontal, 20)
                    }
                    
                    HZButton(title: "Add Measurement", style: .primary, action: save, icon: "plus.circle.fill")
                        .padding(.horizontal, 20)
                    
                    Spacer().frame(height: 20)
                }
                .padding(.top, 16)
            }
            .navigationTitle("Add Measurement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }
    
    var problemType: ProblemType {
        let t = tempVal
        let h = humVal
        if h > 70 { return .mold }
        if t < 12 { return .cold }
        if t > 28 { return .hot }
        if t < 17 { return .cool }
        return .normal
    }
    
    func save() {
        guard let t = Double(temperature), let h = Double(humidity),
              t >= -30 && t <= 60, h >= 0 && h <= 100 else {
            showError = true; return
        }
        showError = false
        let pt = MeasurementPoint(roomID: room.id, x: xPos, y: yPos,
                                   temperature: t, humidity: h, label: label)
        appState.addMeasurement(pt, roomID: room.id, projectID: projectID)
        dismiss()
    }
}
