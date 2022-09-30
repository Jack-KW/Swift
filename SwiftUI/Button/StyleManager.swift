
var body: some View {
    Button {
        ......
    } label: {
        Text("Some Text")
            .frame(width: buttonWidth, height: buttonHeight)
    }
    .buttonStyle(selectionMode ? .bookshelfDisable :
                 (openFileButtonHover ? .bookshelfHover : .bookshelfNormal))
    .frame(maxHeight: buttonHeight)
    .onHover { isHovered in
        self.buttonHover = isHovered
    }
    ......
}

extension ButtonStyle where Self == CustomButtonStyle {
    static var bookshelfDisable: Self {
        CustomButtonStyle(isSelect: true, isHover: false)
    }
    static var bookshelfHover: Self {
        CustomButtonStyle(isSelect: false, isHover: true)
    }
    static var bookshelfNormal: Self {
        CustomButtonStyle(isSelect: false, isHover: false)
    }
}

struct CustomButtonStyle: ButtonStyle {
    
    let isDisable: Bool
    let isHover: Bool
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        let isMac = Scaffold.deviceType == .mac
        let colors: (forground: Color, background: Color) = colors(isDark: colorScheme == .dark,
                                                                   isDisable: isDisable,
                                                                   isHover: isHover,
                                                                   isMac: isMac)
        if isMac {
            configuration.label
                .background(colors.background)
                .foregroundColor(colors.forground)
                .clipShape(RoundedRectangle(cornerSize: CGSize(width: 12, height: 12)))
        } else {
            configuration.label
                .foregroundColor(colors.forground)
        }
    }
    
    private func colors(isDark: Bool, isDisable: Bool,
                        isHover: Bool, isMac: Bool) -> (forground: Color, background: Color) {
        
        var foregroundColor: Color
        var backgroundColor: Color
        if isMac {
            if isDark {
                if isHover {
                    foregroundColor = .primary
                    backgroundColor = Color(red: 0.0, green: 0.0, blue: 0.5)
                } else if isDisable {
                    foregroundColor = .gray
                    backgroundColor = Color(red: 0.3, green: 0.3, blue: 0.3)
                } else {
                    foregroundColor = .primary
                    backgroundColor = Color(red: 0, green: 0.1, blue: 0.2)
                }
            } else {
                if isHover {
                    foregroundColor = .primary
                    backgroundColor = Color(red: 0.2, green: 0.2, blue: 0.2)
                } else if isDisable {
                    foregroundColor = .primary
                    backgroundColor = Color(red: 0, green: 0.1, blue: 0.2)
                } else {
                    foregroundColor = .primary
                    backgroundColor = Color(red: 0, green: 0.1, blue: 0.2)
                }
            }
        } else if isDark {
            if isHover {
                foregroundColor = .blue
                backgroundColor = .clear
            } else if isDisable {
                foregroundColor = .blue
                backgroundColor = .clear
            } else {
                foregroundColor = .blue
                backgroundColor = .clear
            }
        } else {
            if isHover {
                foregroundColor = .blue
                backgroundColor = .clear
            } else if isDisable {
                foregroundColor = .blue
                backgroundColor = .clear
            } else {
                foregroundColor = .blue
                backgroundColor = .clear
            }
        }
        return (foregroundColor, backgroundColor)
    }
}
