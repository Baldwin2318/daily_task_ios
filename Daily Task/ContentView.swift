import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    var body: some View {
        Text("Hello World")
        ListView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }

}

#Preview {
    ContentView()
}
