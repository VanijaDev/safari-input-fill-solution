//
//  FormItemRowView.swift
//  FFill
//
//  Display row for a single FormItem — key, value preview, and optional folder badge.
//

import SwiftUI

struct FormItemRowView: View {
    let item: FormItem

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(item.key)
                .font(.body)
                .fontWeight(.medium)

            HStack(spacing: 6) {
                Text(item.value.isEmpty ? "—" : item.value)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let folder = item.folder {
                    Text(folder.name)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.tint.opacity(0.12))
                        .foregroundStyle(.tint)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 2)
    }
}
