import SwiftUI
import SwiftData

struct UsersListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\User.displayName)]) private var users: [User]
    
    init() {}

    @State private var name: String = ""
    @State private var region: String = ""
    @State private var gender: Gender = .unspecified
    @State private var ageGroup: AgeGroup? = nil

    var body: some View {
        Form {
            Section("Add User") {
                TextField("Display Name", text: $name)
                TextField("Region", text: $region)
                Picker("Gender", selection: $gender) {
                    ForEach(Gender.allCases) { g in Text(g.rawValue.capitalized).tag(g) }
                }
                Picker("Age Group", selection: $ageGroup) {
                    Text("Unspecified").tag(Optional<AgeGroup>.none)
                    ForEach(AgeGroup.allCases) { ag in Text(ag.rawValue).tag(Optional(ag)) }
                }
                Button("Add") { addUser() }
                    .disabled(name.isEmpty)
            }

            Section("Users") {
                ForEach(users) { user in
                    NavigationLink(user.displayName) {
                        UserDetailView(user: user)
                    }
                }
                .onDelete(perform: deleteUsers)
            }
        }
        .navigationTitle("Users")
    }

    private func addUser() {
        let user = User(displayName: name, region: region, gender: gender.rawValue, ageGroup: ageGroup?.rawValue ?? "")
        context.insert(user)
        do { try context.save() } catch { print("Save user error: \(error)") }
        name = ""; region = ""; gender = .unspecified; ageGroup = nil
    }

    private func deleteUsers(at offsets: IndexSet) {
        for index in offsets { context.delete(users[index]) }
        do { try context.save() } catch { print("Delete error: \(error)") }
    }
}

struct UserDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var user: User

    var body: some View {
        Form {
            Section("Profile") {
                TextField("Display Name", text: $user.displayName)
                TextField("Region", text: $user.region)
                Picker("Gender", selection: Binding(get: { user.genderEnum }, set: { user.genderEnum = $0 })) {
                    ForEach(Gender.allCases) { g in Text(g.rawValue.capitalized).tag(g) }
                }
                Picker("Age Group", selection: Binding(get: { user.ageGroupEnum }, set: { user.ageGroupEnum = $0 })) {
                    Text("Unspecified").tag(Optional<AgeGroup>.none)
                    ForEach(AgeGroup.allCases) { ag in Text(ag.rawValue).tag(Optional(ag)) }
                }
            }
        }
        .navigationTitle(user.displayName)
        .onDisappear { do { try? context.save() } }
    }
}

private enum UsersListPreviewData {
    @MainActor
    static var container: ModelContainer {
        let container = try! ModelContainer(for: User.self)
        let context = container.mainContext
        context.insert(User(displayName: "Alice", region: "US", gender: "female", ageGroup: "25-34"))
        return container
    }
}

#Preview {
    NavigationStack { UsersListView() }
        .modelContainer(UsersListPreviewData.container)
}
