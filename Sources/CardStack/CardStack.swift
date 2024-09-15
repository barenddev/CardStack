import SwiftUI

/**
 A SwiftUI view that arranges its children in an interactive deck of cards.
 */

public struct CardStack<Data, Content>: View where Data: RandomAccessCollection, Data.Element: Identifiable, Content: View {
    @State private var currentIndex: Double = 0.0
    @State private var previousIndex: Double = 0.0
    @State private var isScrolling: Bool = false
    private var wrapEnabled: Bool?
    private var highlightEnabled: Bool? // New variable to determine if highlighting should be enabled
    private var highlightCornerRadius: CGFloat = 10
    private var highlightColor: Color = .gray
    private var highlightStrokeWidth: CGFloat = 4
    private var highlightBlurRadius: CGFloat = 3
    private let data: Data
    @ViewBuilder private let content: (Data.Element) -> Content
    @Binding var finalCurrentIndex: Int
    
    /// Creates a stack with the given content
    /// - Parameters:
    ///   - data: The identifiable data for computing the list.
    ///   - currentIndex: The index of the topmost card in the stack
    ///   - wrapEnabled: Turns  infinite scrolling behavior on or off (default behavior is off).
    ///   - highlightEnabled: Applies a highlight around the currently selected card
    ///   - highlightCornerRadius: Adjusts the corner radius of the highlight
    ///   - highlightColor: Adjusts the color of the highlight
    ///   - highlightStrokeWidth: Adjusts the width of the highlight
    ///   - highlightBlurRadius: Adjusts the blur of the highlight
    ///   - content: A view builder that creates the view for a single card
    
    public init(_ data: Data, currentIndex: Binding<Int> = .constant(0), wrapEnabled: Bool? = nil, highlightEnabled: Bool? = nil, highlighCornerRadius: CGFloat = 10, highlightColor: Color = .gray, highlightStrokeWidth: CGFloat = 4, highlightBlurRadius: CGFloat = 3, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.content = content
        _finalCurrentIndex = currentIndex
        self.wrapEnabled = wrapEnabled
        self.highlightEnabled = highlightEnabled // Initialize with the passed value
        self.highlightCornerRadius = highlighCornerRadius
        self.highlightColor = highlightColor
        self.highlightStrokeWidth = highlightStrokeWidth
        self.highlightBlurRadius = highlightBlurRadius
    }
    
    public var body: some View {
        ZStack {
            ForEach(Array(data.enumerated()), id: \.element.id) { (index, element) in
                content(element)
                    .zIndex(zIndex(for: index))
                    .offset(x: xOffset(for: index), y: 0)
                    .scaleEffect(scale(for: index), anchor: .center)
                    .rotationEffect(.degrees(rotationDegrees(for: index)))
                    .background(
                        Group {
                            if highlightEnabled == true && !isScrolling && index == Int(round(currentIndex)) {
                                RoundedRectangle(cornerRadius: highlightCornerRadius) // Adjust the cornerRadius as needed
                                    .stroke(isScrolling ? Color.clear : highlightColor, lineWidth: highlightStrokeWidth).blur(radius: highlightBlurRadius)
                                    .opacity(index == Int(round(currentIndex)) ? 1 : 0) // Applies the highlight to the topmost card and only if 'isScrolling' is false
                            }
                        }
                    )
            }
        }
        .onAppear {
            self.currentIndex = Double(finalCurrentIndex)
            self.previousIndex = currentIndex
        }
        .highPriorityGesture(dragGesture)
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let generator = UISelectionFeedbackGenerator()
                generator.selectionChanged()
                withAnimation(.interactiveSpring()) {
                    isScrolling = true // User started scrolling
                    let x = (value.translation.width / 300) - previousIndex
                    self.currentIndex = -x
                }
            }
            .onEnded { value in
                withAnimation(.interpolatingSpring(stiffness: 300, damping: 40)) {
                    isScrolling = false // Scrolling has stopped
                    self.snapToNearestAbsoluteIndex(value.predictedEndTranslation)
                    self.previousIndex = self.currentIndex
                    
                    // Snap the index and then wait to allow the animation to finish before resetting the scrolling state
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isScrolling = false
                    }
                }
            }
    }
    
    private func snapToNearestAbsoluteIndex(_ predictedEndTranslation: CGSize) {
        withAnimation(.interpolatingSpring(stiffness: 300, damping: 40)) {
            let translation = predictedEndTranslation.width
            if abs(translation) > 200 {
                if translation > 0 {
                    self.goTo(round(self.previousIndex) - 1)
                } else {
                    self.goTo(round(self.previousIndex) + 1)
                }
            } else {
                self.currentIndex = round(currentIndex)
            }
        }
    }
    
    private func goTo(_ index: Double) {
        if wrapEnabled == true {
            let itemCount = Double(data.count)
            let wrappedIndex = (index.truncatingRemainder(dividingBy: itemCount) + itemCount).truncatingRemainder(dividingBy: itemCount)
            self.currentIndex = wrappedIndex
            self.finalCurrentIndex = Int(wrappedIndex)
        }
        else {
            let maxIndex = Double(data.count - 1)
            if index < 0 {
                self.currentIndex = 0
            } else if index > maxIndex {
                self.currentIndex = maxIndex
            } else {
                self.currentIndex = index
            }
            self.finalCurrentIndex = Int(self.currentIndex)
        }
    }
    
    private func zIndex(for index: Int) -> Double {
        if (Double(index) + 0.5) < currentIndex {
            return -Double(data.count - index)
        } else {
            return Double(data.count - index)
        }
    }
    
    private func xOffset(for index: Int) -> CGFloat {
        let topCardProgress = currentPosition(for: index)
        let padding = 35.0
        let x = ((CGFloat(index) - currentIndex) * padding)
        if topCardProgress > 0 && topCardProgress < 0.99 && index < (data.count - 1) {
            return x * swingOutMultiplier(topCardProgress)
        }
        return x
    }
    
    private func scale(for index: Int) -> CGFloat {
        return 1.0 - (0.1 * abs(currentPosition(for: index)))
    }
    
    private func rotationDegrees(for index: Int) -> Double {
        return -currentPosition(for: index) * 2
    }
    
    private func currentPosition(for index: Int) -> Double {
        currentIndex - Double(index)
    }
    
    private func swingOutMultiplier(_ progress: Double) -> Double {
        return sin(Double.pi * progress) * 15
    }
}

struct CardStackView_Previews: PreviewProvider {
    
    struct DemoItem: Identifiable {
        let name: String
        let color: Color
        
        var id: String {
            name
        }
    }
    
    struct DemoView: View {
        @State private var currentIndex = 0
        @State private var tappedIndex: Int? = nil
        
        var body: some View {
            let colors = [
                DemoItem(name: "Red", color: .red),
                DemoItem(name: "Orange", color: .orange),
                DemoItem(name: "Yellow", color: .yellow),
                DemoItem(name: "Green", color: .green),
                DemoItem(name: "Blue", color: .blue),
                DemoItem(name: "Purple", color: .purple),
            ]
            
            VStack {
                CardStack(colors, currentIndex: $currentIndex, wrapEnabled: true) { namedColor in
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(namedColor.color)
                        .overlay(
                            Text(namedColor.name)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                        .frame(height: 400)
                        .onTapGesture {
                            tappedIndex = currentIndex
                        }
                        .padding(50)

                }
                
                Text("Current card is \(currentIndex)")
                if let tappedIndex = tappedIndex {
                    Text("Card \(tappedIndex) was tapped")
                } else {
                    Text("No card has been tapped")
                }
            }
        }
    }
    
    static var previews: some View {
        DemoView()
    }

}
