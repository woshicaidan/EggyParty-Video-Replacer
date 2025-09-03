import SwiftUI
import UniformTypeIdentifiers
import MobileCoreServices
import PhotosUI

struct ContentView: View {
    @State private var bundleId: String = "com.netease.party" //蛋仔派对的Bundle ID
    @State private var fileName: String = "login.mp4"  //蛋仔开屏动画
    @State private var selectedFileURL: URL?
    @State private var logMessages: [String] = []
    @State private var isReplacing: Bool = false
    @State private var showFilePicker: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var hasRootAccess: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    Form {
                        Section(header: Text("应用信息")) {
                            TextField("Bundle ID", text: $bundleId)
                            //蛋仔Bundle ID的输入框
                            
                            //没招了只能整个退出键盘按钮
                            Button(action: {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }) {
                                HStack {
                                    Image(systemName: "keyboard.chevron.compact.down")
                                    Text("退出键盘")
                                }
                                .font(.system(size: 14))
                            }
                        }

                        //选择文件板块
                        Section(header: Text("文件操作")) {
                            Button(action: {
                                showFilePicker = true
                            }) {
                                HStack {
                                    Image(systemName: "folder")
                                    Text("选择替换文件")
                                }
                            }
                            //添加从相册中选择按钮
                            Button(action: {
                                showImagePicker = true
                            }) {
                                HStack {
                                    Image(systemName: "photo")
                                    Text("从相册中选择")
                                }
                            }
                            
                            if let fileURL = selectedFileURL {
                                Text("已选择: \(fileURL.lastPathComponent)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Button(action: {
                                replaceFiles()
                            }) {
                                HStack {
                                    if isReplacing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    }
                                    Text(isReplacing ? "替换中..." : "开始替换")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .disabled(selectedFileURL == nil || isReplacing || !hasRootAccess)
                            .listRowBackground(
                                (selectedFileURL != nil && !isReplacing && hasRootAccess) ? Color.blue : Color.gray
                            )
                            .foregroundColor(.white)
                        }
                        //更多板块
                        Section(header: Text("更多")) {
                            Button("检查权限") {
                                checkPermissions()
                            }
                            Button("关于开发者") {
                                if let url = URL(string: "https://www.douyin.com/user/MS4wLjABAAAAvdmi-e79jKWHFTUvn_HlzsZ8-_kPed1KZPauhXILUnajAw4DB0bYbIlwrYIRAp-d?from_tab_name=main") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            Button("查看应用源代码") {
                                if let url = URL(string: "https://github.com/woshicaidan") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                        
                        Section(header: Text("操作日志")) {
                            ScrollViewReader { proxy in
                                ScrollView {
                                    LazyVStack(alignment: .leading, spacing: 4) {
                                        ForEach(logMessages, id: \.self) { message in
                                            Text(message)
                                                .font(.system(size: 12, design: .monospaced))
                                                .id(message)
                                        }
                                    }
                                    .padding(4)
                                }
                                .frame(height: 200)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .onChange(of: logMessages) { _ in
                                    if let lastMessage = logMessages.last {
                                        withAnimation {
                                            proxy.scrollTo(lastMessage, anchor: .bottom)
                                        }
                                    }
                                }
                            }
                        }

                        //记得给我的蛋仔主页留言嘻嘻嘻
                        Text("不要为了越狱放弃升级的乐趣")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                            .padding(.horizontal, 8)
                    }
                }

                //权限提示弹窗
                if !hasRootAccess {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {}
                    
                    VStack(spacing: 20) {
                        //红色叉号
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        
                        //权限提示
                        Text("需要文件读写权限")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("请使用TrollStore签名此应用")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        //确定按钮
                        Button(action: {
                            //点击后关闭弹窗
                            withAnimation {
                                hasRootAccess = true
                            }
                        }) {
                            Text("确定")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    .padding(30)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(radius: 10)
                    )
                    .padding(40)
                }
            }
            
            //应用大标题
            .navigationTitle("蛋仔开屏动画替换工具")
            .sheet(isPresented: $showFilePicker) {
                DocumentPicker(selectedFileURL: $selectedFileURL)
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedFileURL: $selectedFileURL)
            }
            .onAppear {
                checkPermissions()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())  //使用栈导航样式(适配iPad)
    }
    
    func checkPermissions() {
        let fileManager = FileManager.default
        
        //测试是否可以访问data
        let testPaths = [
            "/var/mobile/Containers/Data/Application",
        ]
        
        //测试的日志输出
        var accessible = true
        for path in testPaths {
            if !fileManager.isReadableFile(atPath: path) {
                accessible = false
                log("无法访问: \(path)")
            } else {
                log("可以访问: \(path)")
            }
        }
        
        hasRootAccess = accessible
        
        if accessible {
            log("权限正常")
        } else {
            log("无访问权限")
        }
    }
    
    func replaceFiles() {
        guard let replacementURL = selectedFileURL else {
            log("错误: 未选择文件")
            return
        }
        
        guard !bundleId.isEmpty else {
            log("错误: Bundle ID 不能为空")
            return
        }
        
        
        isReplacing = true
        log("开始替换文件...")
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.replaceFilesWithRootAccess(
                bundleId: self.bundleId,
                fileName: self.fileName,
                replacementURL: replacementURL
            )
            
            DispatchQueue.main.async {
                self.isReplacing = false
                if result {
                    self.log("文件替换操作完成")
                } else {
                    self.log("文件替换操作失败，请查看日志")
                }
            }
        }
    }
    
    func replaceFilesWithRootAccess(bundleId: String, fileName: String, replacementURL: URL) -> Bool {
        let fileManager = FileManager.default
        
        //查找.app路径
        let containerPaths = findApplicationPaths(for: bundleId)
        
        if containerPaths.bundlePath.isEmpty || containerPaths.dataPath.isEmpty {
            log("错误: 找不到应用路径，请检查Bundle ID是否正确")
            return false
        }
        
        log("找到路径: \(containerPaths.dataPath)")
        
        //构建目标文件路径
        let dataTargetPath = containerPaths.dataPath + "/Documents/res/video/\(fileName)"
        
        var success = true
        
        //替换Data下的文件
        if fileManager.fileExists(atPath: dataTargetPath) {
            do {
                try fileManager.removeItem(atPath: dataTargetPath)
                try fileManager.copyItem(atPath: replacementURL.path, toPath: dataTargetPath)
                log("成功替换文件")
            } catch {
                log("替换文件失败: \(error.localizedDescription)")
                success = false
            }
        } else {
            log("Data路径下未找到目标文件，尝试创建...")
            //尝试创建目录并复制文件
            let dataTargetDir = containerPaths.dataPath + "/Documents/res/video/"
            if !fileManager.fileExists(atPath: dataTargetDir) {
                do {
                    try fileManager.createDirectory(
                        atPath: dataTargetDir,
                        withIntermediateDirectories: true
                    )
                    log("创建目录成功: \(dataTargetDir)")
                } catch {
                    log("创建目录失败: \(error.localizedDescription)")
                    success = false
                    return success
                }
            }
            
            do {
                try fileManager.copyItem(atPath: replacementURL.path, toPath: dataTargetPath)
                log("成功创建并复制文件到Data路径")
            } catch {
                log("复制文件到Data路径失败: \(error.localizedDescription)")
                success = false
            }
        }
        
        return success
    }
    
    func findApplicationPaths(for bundleId: String) -> (bundlePath: String, dataPath: String) {
        let fileManager = FileManager.default
        var bundlePath = ""
        var dataPath = ""
        
        //查找.app路径
        let bundleContainerPath = "/var/containers/Bundle/Application"
        do {
            let appUUIDs = try fileManager.contentsOfDirectory(atPath: bundleContainerPath)
            for appUUID in appUUIDs {
                let appPath = bundleContainerPath + "/" + appUUID
                let appContents = try? fileManager.contentsOfDirectory(atPath: appPath)
                
                //根据Bundle ID查找.app路径
                for content in appContents ?? [] {
                    if content.hasSuffix(".app") {
                        let infoPlistPath = appPath + "/" + content + "/Info.plist"
                        if let infoDict = NSDictionary(contentsOfFile: infoPlistPath),
                           let appBundleId = infoDict["CFBundleIdentifier"] as? String,
                           appBundleId == bundleId {
                            bundlePath = appPath + "/" + content
                            break
                        }
                    }
                }
                if !bundlePath.isEmpty { break }
            }
        } catch {
            log("查找Bundle路径时出错: \(error.localizedDescription)")
        }
        
        //根据Bundle ID查找APP Data路径
        let dataContainerPath = "/var/mobile/Containers/Data/Application"
        do {
            let appUUIDs = try fileManager.contentsOfDirectory(atPath: dataContainerPath)
            for appUUID in appUUIDs {
                let metadataPath = dataContainerPath + "/" + appUUID + "/.com.apple.mobile_container_manager.metadata.plist"
                if let metadataDict = NSDictionary(contentsOfFile: metadataPath),
                   let appBundleId = metadataDict["MCMMetadataIdentifier"] as? String,
                   appBundleId == bundleId {
                    dataPath = dataContainerPath + "/" + appUUID
                    break
                }
            }
        } catch {
            log("查找Data路径时出错: \(error.localizedDescription)")
        }
        
        return (bundlePath, dataPath)
    }
    
    func log(_ message: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let timestamp = dateFormatter.string(from: Date())
        let logMessage = "[\(timestamp)] \(message)"
        
        DispatchQueue.main.async {
            logMessages.append(logMessage)
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedFileURL: URL?
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let documentPicker = UIDocumentPickerViewController(
            forOpeningContentTypes: [.movie, .video, .data],
            asCopy: true
        )
        documentPicker.delegate = context.coordinator
        documentPicker.allowsMultipleSelection = false
        return documentPicker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.selectedFileURL = url
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            //处理取消操作
        }
    }
}

//添加ImagePicker结构体
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedFileURL: URL?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.movie", "public.video"]
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let videoURL = info[.mediaURL] as? URL {
                //复制视频文件到临时目录
                let tempDirectory = FileManager.default.temporaryDirectory
                let destinationURL = tempDirectory.appendingPathComponent(videoURL.lastPathComponent)
                
                do {
                    try FileManager.default.copyItem(at: videoURL, to: destinationURL)
                    parent.selectedFileURL = destinationURL
                } catch {
                    print("复制视频文件失败: \(error)")
                }
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

//使用Canvas预览
#Preview {
    ContentView()
}
