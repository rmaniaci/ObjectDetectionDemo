//
//  ContentView.swift
//  ObjectDetectionDemo
//
//  Created by Ross Maniaci on 6/18/24.
//

import SwiftUI
import PhotosUI
import GoogleGenerativeAI

struct ContentView: View {
    let model = GenerativeModel(name: "gemini-pro-vision", apiKey: APIKey.default)

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: Image?
    
    @State private var analyzedResult: String?
    @State private var isAnalyzing: Bool = false
    
    var body: some View {
        VStack {
            if let selectedImage {
                selectedImage
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 20.0))
                    .overlay {
                        if isAnalyzing {
                            RoundedRectangle(cornerRadius: 20.0)
                                .fill(.black)
                                .opacity(0.5)
                            
                            ProgressView()
                                .tint(.white)
                        }
                    }
            } else {
                Image(systemName: "photo")
                    .imageScale(.large)
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20.0))
            }
            ScrollView {
                Text(analyzedResult ?? (isAnalyzing ? "Analyzing..." : "Select a photo to get started"))
                    .font(.system(.title2, design: .rounded))
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 20.0))
            Spacer()
            
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label("Select Photo", systemImage: "photo")
                    .frame(maxWidth: .infinity)
                    .bold()
                    .padding()
                    .foregroundStyle(.white)
                    .background(.indigo)
                    .clipShape(RoundedRectangle(cornerRadius: 20.0))
            }
        }
        .padding(.horizontal)
        .onChange(of: selectedItem) { oldItem, newItem in
            Task {
                if let image = try? await newItem?.loadTransferable(type: Image.self) {
                    selectedImage = image
                    
                    analyze()
                }
            }
        }
    }

    @MainActor func analyze() {
        self.analyzedResult = nil
        self.isAnalyzing.toggle()

        // Convert Image to UIImage
        let imageRenderer = ImageRenderer(content: selectedImage)
        imageRenderer.scale = 1.0
        
        guard let uiImage = imageRenderer.uiImage else {
            return
        }
        
        let prompt = "Describe the image and explain what the objects are found in the image"
        
        Task {
            do {
                let response = try await model.generateContent(prompt, uiImage)
                
                if let text = response.text {
                    print("Response: \(text)")
                    self.analyzedResult = text
                    self.isAnalyzing.toggle()
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

#Preview {
    ContentView()
}
