//
//  ContentView.swift
//  LazyTableImages LazyTableImages.xcodeproj LazyTableImagesTests LazyTableImages
//
//  Created by Gene Backlin on 6/21/21.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var reader = RSSReader()

    var body: some View {
        NavigationView {
            VStack {
                if let entries = reader.entries {
                    List(entries) { entry in
                        let imageURL: URL = URL(string: entry.imageURLString!)!
                        HStack {
                            AsyncImage(url: imageURL) { phase in
                                switch phase {
                                case .empty:
                                    Color.gray.opacity(0.1)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .transition(.slide)
                                case .failure(_):
                                    Color.gray.opacity(0.1)
                                @unknown default:
                                    ProgressView()
                                                        .progressViewStyle(CircularProgressViewStyle(tint: .gray))                            }
                            }
                                .frame(width: 50, height: 50)
                                .refreshable {
                                    await reader.load()
                                }

                            Text(entry.appName!)
                                .font(.system(size: 15))
                                .foregroundColor(Color.black)
                        }
                    }
                    .refreshable {
                        await reader.load()
                    }
                    .listStyle(.plain)
                }
            }
                .navigationBarTitle("Top Paid Apps")
                .navigationBarItems(trailing:
                        Button(action: {
                    reader.reload()
                        }) {
                            Image(systemName: "arrow.clockwise.circle").imageScale(.large)
                        }
                )

        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
