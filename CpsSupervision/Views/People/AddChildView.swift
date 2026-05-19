import SwiftUI
import PhotosUI

struct AddChildView: View {
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    var editingChild: Child?

    @State private var name = ""
    @State private var caseNumber = ""
    @State private var dateOfBirth = Date()
    @State private var hasDOB = false
    @State private var caseWorkerName = ""
    @State private var caseWorkerPhone = ""
    @State private var notes = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoImage: UIImage?
    @State private var showValidation = false

    private var isEditing: Bool { editingChild != nil }

    var body: some View {
        NavigationStack {
            Form {
                photoSection
                identitySection
                caseWorkerSection
                notesSection
            }
            .navigationTitle(isEditing ? "Edit Child" : "Add Child")
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
        .alert("Name required", isPresented: $showValidation) {
            Button("OK", role: .cancel) {}
        }
    }

    private var photoSection: some View {
        Section {
            HStack {
                Spacer()
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    ZStack {
                        if let img = photoImage {
                            Image(uiImage: img)
                                .resizable().scaledToFill()
                                .frame(width: 90, height: 90)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.blue.opacity(0.12))
                                .frame(width: 90, height: 90)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 36))
                                        .foregroundStyle(.blue)
                                )
                        }
                        Circle()
                            .strokeBorder(Color.blue.opacity(0.3), lineWidth: 2)
                            .frame(width: 90, height: 90)
                        Image(systemName: "camera.fill")
                            .font(.caption)
                            .padding(6)
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(Circle())
                            .offset(x: 28, y: 28)
                    }
                }
                .onChange(of: selectedPhoto) {
                    Task {
                        if let data = try? await selectedPhoto?.loadTransferable(type: Data.self),
                           let img = UIImage(data: data) {
                            photoImage = img
                        }
                    }
                }
                Spacer()
            }
            .listRowBackground(Color.clear)
        }
    }

    private var identitySection: some View {
        Section("Child Information") {
            TextField("Full name *", text: $name)
            TextField("Case number", text: $caseNumber)
            Toggle("Date of birth known", isOn: $hasDOB)
            if hasDOB {
                DatePicker("Date of birth", selection: $dateOfBirth,
                           in: ...Date(), displayedComponents: .date)
            }
        }
    }

    private var caseWorkerSection: some View {
        Section("Case Worker") {
            TextField("Case worker name", text: $caseWorkerName)
            TextField("Case worker phone", text: $caseWorkerPhone)
                .keyboardType(.phonePad)
        }
    }

    private var notesSection: some View {
        Section("Notes") {
            TextEditor(text: $notes)
                .frame(minHeight: 80)
        }
    }

    private func populate() {
        guard let child = editingChild else { return }
        name = child.wrappedName
        caseNumber = child.wrappedCaseNumber
        caseWorkerName = child.wrappedCaseWorkerName
        caseWorkerPhone = child.wrappedCaseWorkerPhone
        notes = child.wrappedNotes
        if let dob = child.dateOfBirth { dateOfBirth = dob; hasDOB = true }
        photoImage = child.photo
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { showValidation = true; return }

        let child = editingChild ?? Child(context: ctx)
        if editingChild == nil { child.id = UUID(); child.createdAt = Date() }

        child.name = trimmed
        child.caseNumber = caseNumber.trimmingCharacters(in: .whitespaces)
        child.dateOfBirth = hasDOB ? dateOfBirth : nil
        child.caseWorkerName = caseWorkerName.trimmingCharacters(in: .whitespaces)
        child.caseWorkerPhone = caseWorkerPhone.trimmingCharacters(in: .whitespaces)
        child.notes = notes
        child.updatedAt = Date()
        if let img = photoImage {
            child.photoData = img.jpegData(compressionQuality: 0.8)
        }

        PersistenceController.shared.save()
        dismiss()
    }
}

#Preview {
    AddChildView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
