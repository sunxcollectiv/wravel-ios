//
//  MemberInvitePopup.swift
//  wravel
//

import SwiftUI

/// A centered card for inviting people to a trip by email, shown over the trip form.
/// Each submitted address is added to `emails` straight away and listed beneath the
/// field, so several can be entered in a row before closing. Tapping someone in the
/// list opens their member card in the same popup, to name or remove them.
struct MemberInvitePopup: View {
    @Binding var emails: [String]
    /// What to call people who don't have an account, by email.
    @Binding var names: [String: String]
    /// The name on each account, by email, for people who have one: theirs is shown
    /// instead of one set here, so their card can't change it.
    var accountNames: [String: String] = [:]
    let onClose: () -> Void

    @State private var text = ""
    @State private var errorMessage: String?
    /// Natural height of the email list, so the card hugs it until it needs to scroll.
    @State private var listHeight: CGFloat = 0
    /// The member whose card is showing, by email; nil shows the invite list.
    @State private var selectedEmail: String?
    @FocusState private var isFocused: Bool

    var body: some View {
        Group {
            if let selectedEmail {
                MemberCard(
                    email: selectedEmail,
                    name: nameBinding(for: selectedEmail),
                    accountName: accountNames[selectedEmail],
                    onBack: showList,
                    onRemove: { remove(selectedEmail) }
                )
                .transition(PopupCard.contentTransition)
            } else {
                inviteList
                    .transition(PopupCard.contentTransition)
            }
        }
        .popupCard(onClose: onClose)
        .onAppear { isFocused = true }
    }

    private var inviteList: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                Label("Add Members", systemImage: "person.2.fill")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(1)
                    .foregroundStyle(Color.appForeground.opacity(0.6))
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                emailField
                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Color.appForeground.opacity(0.75))
                        .padding(.horizontal, 4)
                }
            }

            emailList
        }
    }

    /// `names[email]`, with a blank name stored as none.
    private func nameBinding(for email: String) -> Binding<String> {
        Binding(
            get: { names[email] ?? "" },
            set: { names[email] = $0.isEmpty ? nil : $0 }
        )
    }

    private func showCard(for email: String) {
        isFocused = false
        withAnimation(PopupCard.resizeAnimation) { selectedEmail = email }
    }

    /// Back from a member card to the list, tidying the name they were given.
    private func showList() {
        if let email = selectedEmail {
            let name = names[email]?.trimmingCharacters(in: .whitespacesAndNewlines)
            names[email] = name?.isEmpty == false ? name : nil
        }
        withAnimation(PopupCard.resizeAnimation) { selectedEmail = nil }
    }

    private func remove(_ email: String) {
        withAnimation(PopupCard.resizeAnimation) {
            emails.removeAll { $0 == email }
            names[email] = nil
            selectedEmail = nil
        }
    }

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var emailField: some View {
        HStack(spacing: 8) {
            Image(systemName: "envelope")
                .foregroundStyle(Color.black.opacity(0.45))
            TextField("Email address", text: $text, prompt: appFieldPrompt("Email address"))
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($isFocused)
                .onSubmit(add)
                .onChange(of: text) { _, _ in errorMessage = nil }
            Button("Add", action: add)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.appAccent)
                .buttonStyle(.plain)
                .disabled(trimmedText.isEmpty)
                .opacity(trimmedText.isEmpty ? 0.4 : 1)
        }
        .appField()
    }

    /// The invited emails, scrolling once there are more than fit in the card.
    @ViewBuilder
    private var emailList: some View {
        if emails.isEmpty {
            Text("Invited members will appear here.")
                .font(.footnote)
                .foregroundStyle(Color.appForeground.opacity(0.6))
                .padding(.horizontal, 4)
        } else {
            ScrollView {
                MemberEmailList(emails: $emails, names: displayNames, onSelect: showCard)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { listHeight = $0 }
            }
            .frame(height: min(listHeight, 240))
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    /// The name each listed person goes by: their account's, else one set here.
    private var displayNames: [String: String] {
        names.merging(accountNames) { _, account in account }
    }

    /// Adds the typed address to the list, keeping focus so the next one can be typed.
    private func add() {
        let email = trimmedText.lowercased()
        guard !email.isEmpty else { return }
        guard Self.isValidEmail(email) else {
            errorMessage = "That doesn't look like an email address."
            isFocused = true
            return
        }
        guard !emails.contains(email) else {
            errorMessage = "\(email) is already on the list."
            isFocused = true
            return
        }
        withAnimation(.snappy(duration: 0.2)) { emails.append(email) }
        text = ""
        isFocused = true
    }

    /// A loose shape check: something@something.tld, no spaces.
    static func isValidEmail(_ email: String) -> Bool {
        email.wholeMatch(of: /[^@\s]+@[^@\s]+\.[^@\s]+/) != nil
    }
}

/// Rows of invited people, each with an avatar initial, their name over their email
/// when they have one, and a remove button. Tapping a row calls `onSelect`.
struct MemberEmailList: View {
    @Binding var emails: [String]
    /// What each person goes by, by email; people missing here show just their email.
    var names: [String: String] = [:]
    var onSelect: ((String) -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(emails.enumerated()), id: \.element) { index, email in
                HStack(spacing: 12) {
                    Button {
                        onSelect?(email)
                    } label: {
                        HStack(spacing: 8) {
                            identity(email: email, name: names[email])
                                .frame(maxWidth: .infinity, alignment: .leading)
                            // Hints that the row opens their card.
                            if onSelect != nil {
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(Color.appForeground.opacity(0.35))
                                    .accessibilityHidden(true)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(onSelect == nil)
                    .accessibilityHint(onSelect == nil ? "" : "Opens their member card")

                    Button {
                        withAnimation(.snappy(duration: 0.2)) { emails.removeAll { $0 == email } }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.footnote.weight(.semibold))
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.appForeground.opacity(0.7))
                    .accessibilityLabel("Remove \(names[email] ?? email)")
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)

                if index < emails.count - 1 {
                    Divider().overlay(Color.appForeground.opacity(0.15))
                }
            }
        }
        .background(Color.appForeground.opacity(0.08), in: .rect(cornerRadius: appFieldCornerRadius))
    }

    private func identity(email: String, name: String?) -> some View {
        HStack(spacing: 12) {
            MemberInitial(name: name ?? email)
            VStack(alignment: .leading, spacing: 2) {
                Text(name ?? email)
                    .font(.subheadline)
                    .lineLimit(1)
                    .truncationMode(name == nil ? .middle : .tail)
                if name != nil {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(Color.appForeground.opacity(0.6))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
    }
}

/// A person's initial in a circle, as the member lists show them.
struct MemberInitial: View {
    let name: String
    var size: CGFloat = 32

    var body: some View {
        Text(String(name.first(where: \.isLetter) ?? "?").uppercased())
            .font(size > 40 ? .title3.weight(.semibold) : .subheadline.weight(.semibold))
            .frame(width: size, height: size)
            .background(Color.appForeground.opacity(0.18), in: .circle)
    }
}

/// One person's card inside the invite popup: their email, a field for what to call
/// them, and a button to take them off the trip. Someone with an account goes by
/// that account's name, shown here but not editable.
private struct MemberCard: View {
    let email: String
    @Binding var name: String
    let accountName: String?
    let onBack: () -> Void
    let onRemove: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button(action: onBack) {
                Label("Member", systemImage: "chevron.left")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(1)
                    .foregroundStyle(Color.appForeground.opacity(0.6))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back to members")

            VStack(spacing: 8) {
                MemberInitial(name: accountName ?? (name.isEmpty ? email : name), size: 56)
                Text(email)
                    .font(.footnote)
                    .foregroundStyle(Color.appForeground.opacity(0.6))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 8) {
                if let accountName {
                    HStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .foregroundStyle(Color.black.opacity(0.45))
                        Text(accountName)
                            .foregroundStyle(Color.black.opacity(0.6))
                        Spacer()
                        Image(systemName: "lock.fill")
                            .font(.footnote)
                            .foregroundStyle(Color.black.opacity(0.35))
                    }
                    .appField()
                    Text("They have an account, so they go by the name on it.")
                        .font(.footnote)
                        .foregroundStyle(Color.appForeground.opacity(0.6))
                        .padding(.horizontal, 4)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "person")
                            .foregroundStyle(Color.black.opacity(0.45))
                        TextField("Name", text: $name, prompt: appFieldPrompt("Name"))
                            .textContentType(.name)
                            .textInputAutocapitalization(.words)
                            .submitLabel(.done)
                            .focused($isFocused)
                            .onSubmit(onBack)
                            .onChange(of: name) { _, newValue in
                                // The server takes up to 120 characters.
                                if newValue.count > 120 { name = String(newValue.prefix(120)) }
                            }
                    }
                    .appField()
                    Text("Shown to everyone on the trip until they make an account.")
                        .font(.footnote)
                        .foregroundStyle(Color.appForeground.opacity(0.6))
                        .padding(.horizontal, 4)
                }
            }

            Button(role: .destructive, action: onRemove) {
                Text("Remove from Trip")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        // Straight to typing for someone with no name yet.
        .onAppear { isFocused = accountName == nil && name.isEmpty }
    }
}

#Preview {
    @Previewable @State var emails = ["sam@example.com", "jesse@example.com"]
    @Previewable @State var names = ["jesse@example.com": "Jesse"]
    ZStack {
        Color.black.ignoresSafeArea()
        MemberInvitePopup(emails: $emails, names: $names, accountNames: ["sam@example.com": "Sam"], onClose: {})
    }
}
