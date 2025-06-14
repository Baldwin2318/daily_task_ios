//
//  DailyTaskWidget.swift
//  DailyTaskWidget
//
//  Created by Baldwin Kiel Malabanan on 2025-06-14.
//

import WidgetKit
import SwiftUI
import CoreData

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), tasks: [])
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let viewContext = WidgetPersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isCompleted == NO")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)]
        let tasks = (try? viewContext.fetch(fetchRequest)) ?? []
        return SimpleEntry(date: Date(), configuration: configuration, tasks: tasks)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let viewContext = WidgetPersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isCompleted == NO")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)]
        let tasks = (try? viewContext.fetch(fetchRequest)) ?? []
        let entry = SimpleEntry(date: Date(), configuration: configuration, tasks: tasks)
        return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 15)))
    }

//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let tasks: [Item]
}

struct DailyTaskWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Tasks")
                .font(.headline)
                .foregroundColor(.primary)

            if entry.tasks.isEmpty {
                HStack {
                    Image(systemName: "checkmark.seal")
                        .foregroundColor(.green)
                    Text("You're all caught up! 🎉")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                ForEach(entry.tasks.prefix(3), id: \.objectID) { task in
                    HStack(spacing: 6) {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(task.isCompleted ? .green : .accentColor)
                        Text(task.text ?? "Untitled")
                            .lineLimit(1)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding()
        .widgetURL(URL(string: "daily-task://open")) // Optional: Deep link to open app
    }
} // End of DailyTaskWidgetEntryView

struct DailyTaskWidget: Widget {
    let kind: String = "DailyTaskWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            DailyTaskWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}

#Preview(as: .systemSmall) {
    DailyTaskWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley, tasks: [])
    SimpleEntry(date: .now, configuration: .starEyes, tasks: [])
}
