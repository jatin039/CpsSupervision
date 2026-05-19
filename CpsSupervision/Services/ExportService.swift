import UIKit
import PDFKit
import SwiftUI
import UniformTypeIdentifiers

struct PDFExport: Transferable {
    let data: Data
    let filename: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: UTType.pdf) { $0.data }
            .suggestedFileName { $0.filename }
    }
}

class ExportService {
    private static let pageWidth: CGFloat = 612
    private static let pageHeight: CGFloat = 792
    private static let margin: CGFloat = 50

    static func generatePDF(for log: SupervisionLog) -> PDFExport? {
        guard let data = renderPDF(logs: [log]) else { return nil }
        let date = log.startTime?.formatted(date: .abbreviated, time: .omitted) ?? "unknown"
        let childName = log.child?.wrappedName.replacingOccurrences(of: " ", with: "_") ?? "child"
        return PDFExport(data: data, filename: "supervision_log_\(childName)_\(date).pdf")
    }

    static func generatePDF(for logs: [SupervisionLog], child: Child? = nil) -> PDFExport? {
        guard let data = renderPDF(logs: logs) else { return nil }
        let childName = child?.wrappedName.replacingOccurrences(of: " ", with: "_") ?? "all"
        let dateStr = Date().formatted(date: .abbreviated, time: .omitted)
        return PDFExport(data: data, filename: "supervision_report_\(childName)_\(dateStr).pdf")
    }

    private static func renderPDF(logs: [SupervisionLog]) -> Data? {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        return renderer.pdfData { ctx in
            for (index, log) in logs.enumerated() {
                ctx.beginPage()
                drawPage(log: log, pageNumber: index + 1, totalPages: logs.count, in: ctx.cgContext)
            }
        }
    }

    private static func drawPage(log: SupervisionLog, pageNumber: Int, totalPages: Int, in context: CGContext) {
        var y: CGFloat = margin

        // Header bar
        context.setFillColor(UIColor.systemBlue.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: pageWidth, height: 80))

        // App title
        draw("CPS SUPERVISION LOG", at: CGPoint(x: margin, y: 18),
             font: .systemFont(ofSize: 20, weight: .bold), color: .white)
        draw("CONFIDENTIAL DOCUMENT", at: CGPoint(x: margin, y: 45),
             font: .systemFont(ofSize: 11, weight: .medium), color: UIColor.white.withAlphaComponent(0.85))

        // Page number
        let pageStr = "Page \(pageNumber) of \(totalPages)"
        draw(pageStr, at: CGPoint(x: pageWidth - margin - 80, y: 30),
             font: .systemFont(ofSize: 11), color: .white)

        y = 100

        // Child info section
        if let child = log.child {
            y = drawSection(title: "CHILD INFORMATION", startY: y, in: context)
            y = drawField("Name", value: child.wrappedName, at: y)
            y = drawField("Case Number", value: child.wrappedCaseNumber, at: y)
            if !child.wrappedCaseWorkerName.isEmpty {
                y = drawField("Case Worker", value: child.wrappedCaseWorkerName, at: y)
            }
        }

        // Session details
        y = drawSection(title: "SESSION DETAILS", startY: y + 8, in: context)
        if let start = log.startTime {
            y = drawField("Date", value: start.shortDateString, at: y)
            y = drawField("Time", value: log.dateRangeString, at: y)
        }
        y = drawField("Duration", value: log.formattedDuration, at: y)
        y = drawField("Location", value: log.wrappedLocation, at: y)
        if !log.wrappedLocationType.isEmpty {
            y = drawField("Location Type", value: log.wrappedLocationType, at: y)
        }
        y = drawField("Status", value: log.wrappedStatus.capitalized, at: y)

        // Supervisors
        if !log.supervisorsArray.isEmpty {
            y = drawSection(title: "SUPERVISORS PRESENT", startY: y + 8, in: context)
            for sup in log.supervisorsArray {
                let detail = [sup.wrappedRelationship, sup.wrappedPhone]
                    .filter { !$0.isEmpty }.joined(separator: " | ")
                y = drawField(sup.wrappedName, value: detail, at: y)
            }
        }

        // Activities
        if !log.wrappedActivities.isEmpty {
            y = drawSection(title: "ACTIVITIES", startY: y + 8, in: context)
            y = drawMultilineText(log.wrappedActivities, startY: y)
        }

        // Notes
        if !log.wrappedNotes.isEmpty {
            y = drawSection(title: "NOTES", startY: y + 8, in: context)
            y = drawMultilineText(log.wrappedNotes, startY: y)
        }

        // Flag
        if log.isFlagged == true {
            y = drawSection(title: "⚠ CONCERN FLAGGED", startY: y + 8, in: context, color: .systemOrange)
            y = drawMultilineText(log.wrappedFlagReason, startY: y)
        }

        // Incidents
        if !log.incidentsArray.isEmpty {
            y = drawSection(title: "INCIDENTS (\(log.incidentsArray.count))", startY: y + 8, in: context, color: .systemRed)
            for incident in log.incidentsArray {
                y = drawField("Type", value: incident.wrappedType, at: y)
                y = drawField("Severity", value: incident.wrappedSeverity, at: y)
                y = drawMultilineText(incident.wrappedDescription, startY: y)
                if !incident.wrappedActionTaken.isEmpty {
                    y = drawField("Action Taken", value: incident.wrappedActionTaken, at: y)
                }
                y += 6
            }
        }

        // Footer
        let footerY = pageHeight - 40
        context.setStrokeColor(UIColor.separator.cgColor)
        context.move(to: CGPoint(x: margin, y: footerY - 8))
        context.addLine(to: CGPoint(x: pageWidth - margin, y: footerY - 8))
        context.strokePath()
        let generated = "Generated: \(Date().fullDateTimeString)"
        draw(generated, at: CGPoint(x: margin, y: footerY), font: .systemFont(ofSize: 9), color: .secondaryLabel)
        if let submittedBy = log.submittedAt {
            let sub = "Submitted: \(submittedBy.fullDateTimeString) by \(log.wrappedSubmittedBy)"
            draw(sub, at: CGPoint(x: margin, y: footerY + 12), font: .systemFont(ofSize: 9), color: .secondaryLabel)
        }
    }

    @discardableResult
    private static func drawSection(title: String, startY: CGFloat, in context: CGContext, color: UIColor = .systemBlue) -> CGFloat {
        context.setFillColor(color.withAlphaComponent(0.12).cgColor)
        context.fill(CGRect(x: margin, y: startY, width: pageWidth - margin * 2, height: 20))
        draw(title, at: CGPoint(x: margin + 6, y: startY + 4),
             font: .systemFont(ofSize: 10, weight: .semibold), color: color)
        return startY + 24
    }

    @discardableResult
    private static func drawField(_ label: String, value: String, at y: CGFloat) -> CGFloat {
        let labelWidth: CGFloat = 140
        draw(label + ":", at: CGPoint(x: margin + 6, y: y + 2),
             font: .systemFont(ofSize: 10, weight: .medium), color: .secondaryLabel)
        draw(value, at: CGPoint(x: margin + labelWidth, y: y + 2),
             font: .systemFont(ofSize: 10), color: .label)
        return y + 18
    }

    @discardableResult
    private static func drawMultilineText(_ text: String, startY: CGFloat) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.label
        ]
        let rect = CGRect(x: margin + 6, y: startY + 2, width: pageWidth - margin * 2 - 12, height: 200)
        let str = NSAttributedString(string: text, attributes: attrs)
        str.draw(in: rect)
        let estimatedLines = max(1, text.count / 80 + 1)
        return startY + CGFloat(estimatedLines) * 14 + 8
    }

    private static func draw(_ text: String, at point: CGPoint, font: UIFont, color: UIColor) {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        text.draw(at: point, withAttributes: attrs)
    }
}
