//
//  ContentView.swift
//  Photo HQ
//
//  Created by Oscar Castillo on 11/23/22.
//

import SwiftUI

struct HomeView: View {
    
    @StateObject var viewModel = OptimizerViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Image("singer")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 180, height: 250, alignment: .center)
                Text("Original Image")
                
                if let image = viewModel.convertedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 180, height: 250)
                    Text("Converted Image")
                }
                
                Spacer()
            }
            .padding()
            .navigationBarItems(
                leading: Button(action: {
                    // Actions
                }, label: { Text("Select") })
                .padding()
            )
            .navigationBarItems(
                trailing: Button(action: {
                    guard let image = UIImage(named: "singer") else { return }
                    viewModel.transformImage(image: image)
                }, label: { Text("Optimize") })
                .disabled(viewModel.isOptimizing)
                .padding()
            )
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
