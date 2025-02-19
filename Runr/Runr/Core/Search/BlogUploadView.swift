//
//  BlogUploadView.swift
//  Runr
//
//  Created by Noah Moran on 19/2/2025.
//

import SwiftUI

struct BlogUploadView: View {
    @State private var title = ""
    @State private var content = ""
    @State private var linkedBlogs = [""]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Create a Blog")
                .font(.headline)
                .padding(.bottom, 5)
            
            TextField("Enter blog title...", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom)

            TextEditor(text: $content)
                .frame(height: 200)
                .border(Color.gray.opacity(0.5), width: 1)
                .cornerRadius(8)
                .padding(.bottom)

            Text("Link Other Blogs:")
                .font(.subheadline)
                .padding(.bottom, 5)
            
            ForEach($linkedBlogs.indices, id: \.self) { index in
                HStack {
                    TextField("Paste blog URL...", text: $linkedBlogs[index])
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if linkedBlogs.count > 1 {
                        Button(action: { linkedBlogs.remove(at: index) }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            
            Button(action: { linkedBlogs.append("") }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Link")
                }
            }
            .padding(.top, 5)
            
            Spacer()
            
            Button(action: uploadBlog) {
                Text("Upload Blog")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
    
    func uploadBlog() {
        print("Uploading blog titled: \(title)")
        // Here you can integrate with Firestore to save the blog
    }
}


#Preview {
    BlogUploadView()
}
