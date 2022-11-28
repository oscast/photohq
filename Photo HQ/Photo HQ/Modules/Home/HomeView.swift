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
    
    var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                if let image = viewModel.originalImage {
                    NavigationLink(destination: {
                        ZoomableScrollView {
                            Image(uiImage: image)
                        }
                    }, label: {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 200, height: 200)
                            .border(Color.pink)
                            .clipped()
                    })
                    .padding()
                    Text("Original Image")
                }
                
                if let image = viewModel.convertedImage {
                    NavigationLink(destination: {
                        ZoomableScrollView {
                            Image(uiImage: image)
                        }
                    }, label: {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 200, height: 200)
                            .border(Color.pink)
                            .clipped()
                    })
                    Text("Converted Image")
                }
                
                Spacer()
            }
            .padding()
            .navigationBarItems(
                leading: Button(action: {
                    selectPhoto = true
                }, label: { Text("Select") })
                .padding()
            )
            .navigationBarItems(
                trailing: Button(action: {
                    guard let image = viewModel.originalImage else { return }
                    viewModel.transformImage(image: image)
                }, label: { Text("Optimize") })
                .disabled(viewModel.isOptimizing)
                .padding()
            )
            .sheet(isPresented: $selectPhoto) {
                PhotoPicker(showLoadingOverlay: $showLoadingOverlay, completion: { images in
                    guard let image = images.first else { return }
                    viewModel.originalImage = image
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
