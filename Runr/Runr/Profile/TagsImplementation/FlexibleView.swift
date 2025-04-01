import SwiftUI

struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let maxRows: Int?
    let content: (Data.Element) -> Content

    init(data: Data,
         spacing: CGFloat = 8,
         alignment: HorizontalAlignment = .leading,
         maxRows: Int? = nil,
         @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.spacing = spacing
        self.alignment = alignment
        self.maxRows = maxRows
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var rows: [[Data.Element]] = [[]]
        
        // Arrange items into rows based on available width.
        for item in data {
            let itemSize = UIHostingController(rootView: content(item)).view.intrinsicContentSize.width + spacing
            if width + itemSize > geometry.size.width {
                rows.append([item])
                width = itemSize
            } else {
                rows[rows.count - 1].append(item)
                width += itemSize
            }
        }
        
        // Limit the number of rows if maxRows is provided.
        let limitedRows = maxRows != nil ? Array(rows.prefix(maxRows!)) : rows
        
        return VStack(alignment: alignment, spacing: spacing) {
            ForEach(limitedRows, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(row, id: \.self) { item in
                        content(item)
                    }
                }
            }
        }
    }
}
