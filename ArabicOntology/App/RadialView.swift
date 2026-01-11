import SwiftUI
import SwiftData
import Combine

// MARK: - Radial View Model

@MainActor
class RadialViewModel: ObservableObject {
    @Published var nodes: [RadialNode] = []
    @Published var edges: [RadialEdge] = []
    
    private let centerRadius: CGFloat = 0
    private let dialectRadius: CGFloat = 120
    private let formRadius: CGFloat = 220
    
    func loadGraph(for centerLemma: Lemma) {
        var newNodes: [RadialNode] = []
        var newEdges: [RadialEdge] = []
        
        // 1. Center Node
        let centerNode = RadialNode(
            id: centerLemma.lemmaId,
            text: centerLemma.lemma,
            type: .center,
            angle: 0,
            radius: centerRadius,
            color: .blue
        )
        newNodes.append(centerNode)
        
        // 2. Identify Dialect Groups (Correspondences + Center's own dialect)
        // We treat the center lemma as one "group" and correspondences as others.
        // To make it symmetrical, we'll collect ALL related lemmas (center + correspondences)
        // and group them by dialect.
        
        var allLemmas: [Lemma] = [centerLemma]
        allLemmas.append(contentsOf: centerLemma.correspondences)
        
        // Group by Dialect Name (or Code)
        let groupedLemmas = Dictionary(grouping: allLemmas) { $0.dialect?.name ?? "Unknown" }
        let sortedDialects = groupedLemmas.keys.sorted()
        
        let dialectCount = sortedDialects.count
        guard dialectCount > 0 else {
            self.nodes = newNodes
            self.edges = []
            return
        }
        
        let anglePerDialect = 2.0 * .pi / Double(dialectCount)
        
        for (i, dialectName) in sortedDialects.enumerated() {
            let baseAngle = Double(i) * anglePerDialect
            let lemmasInDialect = groupedLemmas[dialectName] ?? []
            
            // Sub-distribute lemmas within the dialect sector if > 1
            // Small spread around the baseAngle
            let spread = 0.5 * anglePerDialect // use half the sector
            
            for (j, lemma) in lemmasInDialect.enumerated() {
                // Calculate angle for this lemma
                let offset: Double
                if lemmasInDialect.count == 1 {
                    offset = 0
                } else {
                    let step = spread / Double(lemmasInDialect.count)
                    offset = (Double(j) * step) - (spread / 2.0) + (step / 2.0)
                }
                
                let lemmaAngle = baseAngle + offset
                let isCenter = lemma.lemmaId == centerLemma.lemmaId
                
                // If it's the center lemma, we ALREADY added it at (0,0).
                // But wait, the design says "Dialect clusters" on Ring 1.
                // If the center lemma is "MSA", does it sit in the center OR on the MSA ring?
                // The prompt says "Center: Selected Lemma".
                // So if the center is MSA, the MSA node is in the center.
                // Correspondences are on the ring.
                
                if isCenter {
                    // Center node already added.
                    // We just need to add its FORMS.
                    // Forms radiate from the CENTER in this specific sector.
                    addForms(for: lemma, parentNode: centerNode, baseAngle: lemmaAngle, spreadAngle: anglePerDialect, into: &newNodes, &newEdges)
                } else {
                    // Create Ring 1 Node (Dialect Lemma)
                    let lemmaNode = RadialNode(
                        id: lemma.lemmaId,
                        text: lemma.lemma, // + "\n" + (lemma.dialect?.name ?? ""),
                        type: .dialectLemma,
                        angle: lemmaAngle,
                        radius: dialectRadius,
                        color: .orange // Distinct color for ring 1
                    )
                    newNodes.append(lemmaNode)
                    
                    // Edge from Center to this Lemma
                    newEdges.append(RadialEdge(from: centerNode.id, to: lemmaNode.id, color: .gray.opacity(0.5)))
                    
                    // Add Forms (Ring 2)
                    addForms(for: lemma, parentNode: lemmaNode, baseAngle: lemmaAngle, spreadAngle: anglePerDialect / Double(max(1, lemmasInDialect.count)), into: &newNodes, &newEdges)
                }
            }
        }
        
        self.nodes = newNodes
        self.edges = newEdges
    }
    
    private func addForms(
        for lemma: Lemma,
        parentNode: RadialNode,
        baseAngle: Double,
        spreadAngle: Double,
        into nodes: inout [RadialNode],
        _ edges: inout [RadialEdge]
    ) {
        let allForms = lemma.forms
        let forms = Array(allForms.prefix(10))
        guard !forms.isEmpty else { return }
        
        // Distribute forms fan-like around the parent's angle
        // Use 85% of the available sector to allow breathing room between dialect groups
        let formSpread = spreadAngle * 0.85
        
        for (k, form) in forms.enumerated() {
            let offset: Double
            if forms.count == 1 {
                offset = 0
            } else {
                let step = formSpread / Double(forms.count)
                offset = (Double(k) * step) - (formSpread / 2.0) + (step / 2.0)
            }
            
            let formAngle = baseAngle + offset
            // Visual consistency: Forms always on Ring 2 distance relative to center?
            // If parent is center, maybe forms go to Ring 1? Or Ring 2 directly?
            // Let's put them on Ring 2 distance to distinguish from Lemmas.
            
            let actualRadius = (parentNode.type == .center) ? dialectRadius * 1.5 : formRadius
            
            let formNode = RadialNode(
                id: form.formKey,
                text: form.token,
                type: .form,
                angle: formAngle,
                radius: actualRadius,
                color: .green // Form color
            )
            nodes.append(formNode)
            edges.append(RadialEdge(from: parentNode.id, to: formNode.id, color: .gray.opacity(0.3)))
        }
    }
}

// MARK: - Data Structures

enum NodeType {
    case center
    case dialectLemma
    case form
}

struct RadialNode: Identifiable {
    let id: String
    let text: String
    let type: NodeType
    let angle: Double
    let radius: CGFloat
    let color: Color
    
    var position: CGPoint {
        CGPoint(
            x: cos(CGFloat(angle)) * radius,
            y: sin(CGFloat(angle)) * radius
        )
    }
}

struct RadialEdge: Identifiable {
    let id = UUID()
    let from: String
    let to: String
    let color: Color
}

// MARK: - Radial View

struct RadialView: View {
    let rootLemma: Lemma
    @StateObject private var viewModel = RadialViewModel()
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            
            ZStack {
                // Background
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                
                // Graph
                Canvas { context, size in
                    // Apply transformations
                    context.translateBy(x: center.x + offset.width, y: center.y + offset.height)
                    context.scaleBy(x: scale, y: scale)
                    
                    // Draw Edges
                    for edge in viewModel.edges {
                        if let startNode = viewModel.nodes.first(where: { $0.id == edge.from }),
                           let endNode = viewModel.nodes.first(where: { $0.id == edge.to }) {
                            
                            var path = Path()
                            path.move(to: startNode.position)
                            path.addLine(to: endNode.position)
                            
                            context.stroke(path, with: .color(edge.color), lineWidth: 1)
                        }
                    }
                    
                    // Draw Nodes
                    for node in viewModel.nodes {
                        let nodeSize: CGFloat = node.type == .center ? 40 : (node.type == .dialectLemma ? 25 : 15)
                        let rect = CGRect(
                            x: node.position.x - nodeSize / 2,
                            y: node.position.y - nodeSize / 2,
                            width: nodeSize,
                            height: nodeSize
                        )
                        
                        context.fill(Path(ellipseIn: rect), with: .color(node.color))
                        
                        // Text Label
                        if node.type != .form || scale > 0.8 { // Hide small labels if zoomed out
                            let text = Text(node.text)
                                .font(.system(size: node.type == .center ? 14 : 10))
                                .foregroundColor(.primary)
                            
                            // Offset text slightly
                            let textOffset = CGPoint(x: node.position.x, y: node.position.y + nodeSize/1.5)
                            context.draw(text, at: textOffset, anchor: .top)
                        }
                    }
                }
            }
            .gesture(
                MagnificationGesture()
                    .onChanged {
                        scale = $0.magnitude
                    }
            )
        }
        .onAppear {
            viewModel.loadGraph(for: rootLemma)
        }
        .onChange(of: rootLemma) {
            viewModel.loadGraph(for: rootLemma)
            // Reset view on new lemma?
            // offset = .zero
            // scale = 1.0
        }
    }
}
