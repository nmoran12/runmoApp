//
//  HeartRateChartView.swift
//  Runr
//
//  Created by Noah Moran on 4/4/2025.
//

import SwiftUI

struct HeartRateChartView: View {
    let dataPoints: [HeartRateDataPoint]
    /// Closure that determines the zone name for a given BPM
    let zoneForBPM: (Double) -> String
    
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                guard dataPoints.count >= 2 else { return }
                
                // Calculate the overall time and BPM ranges.
                let firstPoint = dataPoints.first!
                let lastPoint = dataPoints.last!
                let timeRange = lastPoint.time.timeIntervalSince(firstPoint.time)
                let minBPM = dataPoints.map { $0.bpm }.min() ?? 0
                let maxBPM = dataPoints.map { $0.bpm }.max() ?? 1
                
                // Helpers to map a time/BPM to canvas coordinates.
                func xPosition(for time: Date) -> CGFloat {
                    let elapsed = time.timeIntervalSince(firstPoint.time)
                    return CGFloat(elapsed / timeRange) * size.width
                }
                func yPosition(for bpm: Double) -> CGFloat {
                    let relative = (bpm - minBPM) / (maxBPM - minBPM)
                    return size.height * (1 - CGFloat(relative))
                }
                
                // Draw line segments between every consecutive pair of points.
                for i in 0..<(dataPoints.count - 1) {
                    let start = dataPoints[i]
                    let end = dataPoints[i+1]
                    
                    // Determine color based on the starting point's zone.
                    let zone = zoneForBPM(start.bpm)
                    let segmentColor: Color = {
                        switch zone {
                        case "Zone 1": return .blue
                        case "Zone 2": return .green
                        case "Zone 3": return .yellow
                        case "Zone 4": return .orange
                        case "Zone 5": return .red
                        default:       return .gray
                        }
                    }()
                    
                    var path = Path()
                    path.move(to: CGPoint(x: xPosition(for: start.time),
                                          y: yPosition(for: start.bpm)))
                    path.addLine(to: CGPoint(x: xPosition(for: end.time),
                                             y: yPosition(for: end.bpm)))
                    
                    context.stroke(path, with: .color(segmentColor), lineWidth: 2)
                }
                
                // Draw a small circle for each data point.
                for point in dataPoints {
                    let center = CGPoint(x: xPosition(for: point.time),
                                         y: yPosition(for: point.bpm))
                    let rect = CGRect(x: center.x - 2, y: center.y - 2, width: 4, height: 4)
                    
                    let zone = zoneForBPM(point.bpm)
                    let dotColor: Color = {
                        switch zone {
                        case "Zone 1": return .blue
                        case "Zone 2": return .green
                        case "Zone 3": return .yellow
                        case "Zone 4": return .orange
                        case "Zone 5": return .red
                        default:       return .gray
                        }
                    }()
                    
                    context.fill(Path(ellipseIn: rect), with: .color(dotColor))
                }
            }
        }
        .frame(height: 100)
    }
}

struct HeartRateChartView_Previews: PreviewProvider {
    static var previews: some View {
        // Sample data with one point per second.
        let sampleData = [
            HeartRateDataPoint(time: Date(), bpm: 100),
            HeartRateDataPoint(time: Date().addingTimeInterval(1), bpm: 100),
            HeartRateDataPoint(time: Date().addingTimeInterval(2), bpm: 105),
            HeartRateDataPoint(time: Date().addingTimeInterval(3), bpm: 105),
            HeartRateDataPoint(time: Date().addingTimeInterval(4), bpm: 115),
            HeartRateDataPoint(time: Date().addingTimeInterval(5), bpm: 115)
        ]
        
        HeartRateChartView(
            dataPoints: sampleData,
            zoneForBPM: { bpm in
                switch bpm {
                case ..<110:       return "Zone 1"
                case 110..<120:    return "Zone 2"
                case 120..<130:    return "Zone 3"
                case 130..<140:    return "Zone 4"
                default:           return "Zone 5"
                }
            }
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
