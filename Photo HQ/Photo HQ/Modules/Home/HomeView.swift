//
//  ContentView.swift
//  Photo HQ
//
//  Created by Oscar Castillo on 11/23/22.
//

import SwiftUI

struct HomeView: View {
    
    @StateObject var viewModel = OptimizerViewModel()
    @State var selectPhoto: Bool = false
    @State var showLoadingOverlay = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if let image = viewModel.originalImage {
                        ThumbnailView(image: image, text: "Original Photo")
                    }
                    
                    if let image = viewModel.convertedImage {
                        ThumbnailView(image: image, text: "Optimized Photo")
                    }
                    
                    Spacer()
                }
                .padding()
                .navigationBarItems(
                    leading: (
                        Button(
                            action: { selectPhoto = true},
                            label: { Text("Select Photo")
                                    .fontWeight(.medium)
                            }
                        )
                        .disabled(viewModel.isOptimizing)
                        .padding()
                    ),trailing: (
                        Button(
                            action: {
                                if let optimizedImage = viewModel.convertedImage {
                                    viewModel.saveImage(image: optimizedImage)
                                    return
                                }
                                
                                guard let image = viewModel.originalImage else { return }
                                viewModel.optimizeImage(image)

                            },
                            label: { Text(viewModel.convertedImage != nil ? "Save": "Optimize")
                                    .fontWeight(.medium)
                            }
                        )
                        .disabled(viewModel.isOptimizing)
                        .padding()
                    )
                )
                .sheet(isPresented: $selectPhoto) {
                    PhotoPicker(showLoadingOverlay: $showLoadingOverlay, completion: { images in
                        guard let image = images.first else { return }
                        viewModel.originalImage = image
                    })
                }
                .alert(viewModel.alertMessage, isPresented: $viewModel.hasAlert) {
                    Button("OK", role: .cancel) {
                        viewModel.alertMessage = ""
                    }
                }
            }
        }
    }
    
    struct ThumbnailView: View {
        let image: UIImage
        let text: String
        var body: some View {
            VStack(spacing: 8) {
                NavigationLink(destination: {
                    ZoomableScrollView {
                        Image(uiImage: image)
                            .padding()
                    }
                }, label: {
                    VStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 300, height: 300)
                            .border(Color.blue)
                            .clipped()
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 8.0,
                                    style: .continuous
                                )
                            )
                        
                        Text(text)
                            .foregroundColor(.white)
                            .font(.system(.title3))
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .background(.blue)
                            .cornerRadius(8)
                    }
                })
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
