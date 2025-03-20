import UIKit

// Run this in viewDidLoad or similar
func generateBookIcon() {
    let config = UIImage.SymbolConfiguration(pointSize: 80, weight: .regular)
    if let image = UIImage(systemName: "character.book.closed", withConfiguration: config)?
        .withTintColor(.systemBlue, renderingMode: .alwaysOriginal) {
        if let data = image.pngData() {
            // Save to Documents directory
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let url = documentsDirectory.appendingPathComponent("BookIcon.png")
            try? data.write(to: url)
            print("Icon saved to: \(url.path)")
        }
    }
}