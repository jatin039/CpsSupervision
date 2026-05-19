import SwiftUI

struct AddSupervisorView: View {
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    var editingSupervisor: Supervisor?

    @State private var name = ""
    @State private var relationship = Constants.SupervisorRelationship.fosterParent
    @State private var email = ""
    @State private var phone = ""
    @State private var organization = ""

    private var isEditing: Bool { editingSupervisor != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Supervisor Information") {
                    TextField("Full name *", text: $name)
                    Picker("Role / Relationship", selection: $relationship) {
                        ForEach(Constants.SupervisorRelationship.allCases, id: \.self) { r in
                            Text(r.rawValue).tag(r)
                        }
                    }
                    TextField("Organization (optional)", text: $organization)
                }
                Section("Contact") {
                    TextField("Phone number", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email address", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle(isEditing ? "Edit Supervisor" : "Add Supervisor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear { populate() }
    }

    private func populate() {
        guard let sup = editingSupervisor else { return }
        name = sup.wrappedName
        relationship = Constants.SupervisorRelationship(rawValue: sup.wrappedRelationship) ?? .other
        email = sup.wrappedEmail
        phone = sup.wrappedPhone
        organization = sup.wrappedOrganization
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let sup = editingSupervisor ?? Supervisor(context: ctx)
        if editingSupervisor == nil { sup.id = UUID(); sup.createdAt = Date() }
        sup.name = trimmed
        sup.relationship = relationship.rawValue
        sup.email = email.trimmingCharacters(in: .whitespaces)
        sup.phone = phone.trimmingCharacters(in: .whitespaces)
        sup.organization = organization.trimmingCharacters(in: .whitespaces)

        PersistenceController.shared.save()
        dismiss()
    }
}

#Preview {
    AddSupervisorView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
