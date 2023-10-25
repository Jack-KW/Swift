import SwiftUI

struct CompareColorsView: View {
    
    let colorRectSize = 90.0
    let commentFontSize = 9.0
    
    let baseColors: [Int:ColorInfo] = [
        1: ColorInfo(color: CPColor.label, label: "label"),
        2: ColorInfo(color: CPColor.secondaryLabel, label: "secondary label"),
        3: ColorInfo(color: CPColor.tertiaryLabel, label: "tertiary label"),
        4: ColorInfo(color: CPColor.quaternaryLabel, label: "quaternary label"),
        5: ColorInfo(color: CPColor.red, label: "red"),
        6: ColorInfo(color: CPColor.green, label: "green"),
        7: ColorInfo(color: CPColor.blue, label: "blue"),
        8: ColorInfo(color: CPColor.yellow, label: "yellow"),
        9: ColorInfo(color: CPColor.orange, label: "orange"),
        11: ColorInfo(color: CPColor.purple, label: "purple"),
        10: ColorInfo(color: CPColor.white, label: "white"),
        12: ColorInfo(color: CPColor.black, label: "black")
    ]
    
    let layout = [ GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()) ]
    
    @State var matchedColorId = 0
    @State var currentColor = UIColor.black
    @State var randomColors = [UIColor]()
    
    struct ColorInfo {
        let color: CPColor
        let label: String
    }
    
    private func generateRandomColos() -> [UIColor] {
        [randomColor, randomColor, randomColor, randomColor]
    }
    
    var body: some View {
        VStack {
            LazyVGrid (columns: layout, spacing: 10) {
                ForEach(baseColors.keys.sorted(), id: \.self) { key in
                    VStack {
                        Color(baseColors[key]!.color)
                            .frame(width: colorRectSize, height: colorRectSize)
                        Text(baseColors[key]!.label)
                            .font(.system(size: commentFontSize))
                        Spacer()
                    }
                }
            }
            VStack {
                Text("Select a color")
                    .font(.system(size: 20))
                    .bold()
                HStack {
                    ForEach(0..<randomColors.count, id: \.self) { index in
                        let randomColor = randomColors[index]
                        Button(action: {
                            currentColor = randomColor
                            matchedColorId = matchColor(randomColor)
                        }) {
                            Color(randomColor)
                                .frame(width: colorRectSize, height: colorRectSize)
                            Text("current color: \(randomColor)")
                                .font(.system(size: commentFontSize))
                        }
                        .frame(width: colorRectSize, height: colorRectSize)
                    }
                }
            }
            HStack {
                let foundMatch = (1...baseColors.count).contains(matchedColorId)
                VStack {
                    Color(foundMatch ? currentColor : .systemBackground)
                        .frame(width: colorRectSize * 2, height: colorRectSize)
                    Text(foundMatch ? "\(currentColor)" : "")
                        .font(.system(size: commentFontSize))
                    Spacer()
                }
                VStack {
                    Color(foundMatch ? baseColors[matchedColorId]!.color : .systemBackground)
                        .frame(width: colorRectSize * 2, height: colorRectSize)
                    Text(foundMatch ? baseColors[matchedColorId]!.label : "")
                        .font(.system(size: commentFontSize))
                    Spacer()
                }
            }
            Button(action: {
                randomColors = generateRandomColos()
            }) {
                Text("change colors")
            }
            .buttonStyle(.borderedProminent)
        }.onAppear() {
            randomColors = generateRandomColos()
        }
    }
    
    private func matchColor(_ color: CPColor) -> Int {
        var minDistance = Double.infinity
        var targetId = -1
        for key in baseColors.keys.sorted() {
            let distance = color.CIEDE2000(compare: baseColors[key]!.color)
            if distance < minDistance {
                minDistance = distance
                targetId = key
            }
        }
        return targetId
    }
    
    var randomColor: CPColor {
        return CPColor(cgColor: CGColor(red: randomColorComponentValue, green: randomColorComponentValue,
                                        blue: randomColorComponentValue, alpha: 1.0))
    }
    
    var randomColorComponentValue: CGFloat {
        CGFloat.random(in: 0.0...1.0)
    }
}
