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
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 300, height: 300, alignment: .center)
                        .clipped()
                    Text("Original Image")
                        .padding()
                }
                
                if let image = viewModel.convertedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 300, height: 300, alignment: .center)
                        .clipped()
                    Text("Converted Image")
                        .padding()
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
