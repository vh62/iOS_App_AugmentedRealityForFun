//
//  ContentView.swift
//  ARF
//
//  Created by Vikram Ho on 1/14/21.
//

import SwiftUI
import RealityKit
import ARKit

struct ContentView: View {
    
    @State private var isPlacementEnabled = false
    @State private var selectedModel: Model?
    @State private var modelConfirmedForPlacement: Model?
    
    private var models: [Model] = {
        //Dynamically get our filenames
        let filemanager = FileManager.default
            guard let path = Bundle.main.resourcePath, let files = try?
                    filemanager.contentsOfDirectory(atPath: path) else {
                return []
            }
        
        var availableModels: [Model] = []
        for filename  in files where filename.hasSuffix("usdz"){
            let modelName = filename.replacingOccurrences(of: ".usdz", with: "")
            let model = Model(modelName: modelName)
            availableModels.append(model)
        }
        return availableModels
    }()
    
    var body: some View {
        ZStack(alignment: .bottom){
            ARViewContainer(modelConfirmedForPlacement: $modelConfirmedForPlacement)
            
            if self.isPlacementEnabled{
                PlacementButtonView(isPlacementEnabled: $isPlacementEnabled, selectedModel: $selectedModel, modelConfirmedForPlacement: $modelConfirmedForPlacement)
            }else{
                ModelPickerView(isPlacementEnabled: $isPlacementEnabled, selectedModel: $selectedModel, models: self.models)
            }
            
            
            
        }
    }
}

struct ARViewContainer: UIViewRepresentable{
    
    @Binding var modelConfirmedForPlacement: Model?
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero)
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh){
            config.sceneReconstruction = .mesh
        }
        
        arView.session.run(config)
        
        return arView
    }
    func updateUIView(_ uiView: ARView, context: Context) {
        if let model = self.modelConfirmedForPlacement{
            
            if let modelEntity = model.modelEntity{
                print("Debug, adding model to scene - \(model.modelName)")
                let anchorEntity = AnchorEntity(plane: .any)
                anchorEntity.addChild(modelEntity.clone(recursive: true))
                
                uiView.scene.addAnchor(anchorEntity)
            } else{
                print("Debug: Unable to load modelEntity for \(model.modelName)")
            }
            DispatchQueue.main.async {
                self.modelConfirmedForPlacement = nil
            }
        }
    }
}


struct ModelPickerView: View{
    
    @Binding var isPlacementEnabled: Bool
    @Binding var selectedModel: Model?
    
    var models: [Model]
    var body: some View{
        ScrollView(.horizontal, showsIndicators: false){
            HStack(spacing: 30){
                ForEach(0 ..< self.models.count){ index in
                    Button(action: {
                        print("Debug models are: \(self.models[index].modelName)")
                        
                        selectedModel = models[index]
                        
                        isPlacementEnabled = true
                    }, label: {
                        Image(uiImage: self.models[index].image)
                            .resizable()
                            .frame(height: 80)
                            .aspectRatio(1/1, contentMode: .fit)
                            .background(Color.white)
                            .cornerRadius(12)
                    }).buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(20)
        .background(Color.black.opacity(0.5))
    }
}

struct PlacementButtonView: View{
    @Binding var isPlacementEnabled: Bool
    @Binding var selectedModel: Model?
    @Binding var modelConfirmedForPlacement: Model?
    var body: some View{
        HStack{
            //Cancel button
            Button(action: {
                print("Debug, cancel model placement")
                
                resetPlacementParameters()
            }, label: {
               Image(systemName: "xmark")
                .frame(width: 60, height: 60)
                .font(.title)
                .background(Color.white.opacity(0.75))
                .cornerRadius(30)
                .padding(20)
            })
            //Confirm button
            Button(action: {
                print("Debug, confirm model placement")
                
                modelConfirmedForPlacement = selectedModel
                resetPlacementParameters()
            }, label: {
               Image(systemName: "checkmark")
                .frame(width: 60, height: 60)
                .font(.title)
                .background(Color.white.opacity(0.75))
                .cornerRadius(30)
                .padding(20)
            })
        }
    }
    
    func resetPlacementParameters(){
        self.isPlacementEnabled = false
        self.selectedModel = nil
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
