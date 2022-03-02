platform :ios, '11.0'

workspace 'Timeline'

target 'Timeline FM' do
    
    use_frameworks!
    
    project 'Timeline FM/Timeline FM.xcodeproj'
    
    pod 'ActionSheetPicker-3.0', '~> 2.2.0'
    pod 'Alamofire', '~> 4.5'
    pod 'AlamofireImage', '~> 3.3'
    pod 'PKHUD', :git => 'https://github.com/pkluz/PKHUD.git', :branch => 'release/swift4'
    pod 'KeychainAccess', '~> 3.0.0'
    pod 'SnapKit', '~> 3.1.1'
    pod 'Material', '~> 2.4.0'
    pod 'KCFloatingActionButton', '~> 2.2'
    pod 'CSV.swift', '~> 2.1'
    pod 'JTAppleCalendar', '~> 7.0'
    pod 'Socket.IO-Client-Swift', '~> 11.1.3'
    pod 'Pulsar', '~> 2.0'
    pod 'UICheckbox.Swift'
    pod 'Chatto', '= 3.2.0'
    pod 'ChattoAdditions', '= 3.2.0'
    pod 'NYTPhotoViewer'
    pod 'MapKitGoogleStyler'
    pod 'Fabric'
    pod 'Crashlytics', '~>  3.10'
    pod 'Fingertips'
    pod 'EasyAnimation'
    pod 'RevealingSplashView'
    pod 'IQKeyboardManagerSwift'
    pod 'Motion'
    pod 'Floaty'
    pod 'NYAlertViewController'
    pod 'SwiftLocation', '~> 3.2.3'
    pod 'BetterSegmentedControl', '~> 0.9'
    pod 'SwiftReorder', '~> 6.0'
    pod 'WaterDrops'
    pod 'MYTableViewIndex'
    pod 'TTGSnackbar'
    
end

target 'Timeline CMMS' do
    
    use_frameworks!
    
    project 'Timeline CMMS/Timeline CMMS.xcodeproj'
   
   pod 'ActionSheetPicker-3.0', '~> 2.2.0'
   pod 'Alamofire', '~> 4.5'
   pod 'AlamofireImage', '~> 3.3'
   pod 'PKHUD', :git => 'https://github.com/pkluz/PKHUD.git', :branch => 'release/swift4'
   pod 'KeychainAccess', '~> 3.0.0'
   pod 'SnapKit', '~> 3.1.1'
   pod 'Material', '~> 2.4.0'
   pod 'KCFloatingActionButton', '~> 2.2'
   pod 'CSV.swift', '~> 2.1'
   pod 'JTAppleCalendar', '~> 7.0'
   pod 'Socket.IO-Client-Swift', '~> 11.1.3'
   pod 'Pulsar', '~> 2.0'
   pod 'UICheckbox.Swift'
   pod 'Chatto', '= 3.2.0'
   pod 'ChattoAdditions', '= 3.2.0'
   pod 'NYTPhotoViewer'
   pod 'MapKitGoogleStyler'
   pod 'Fabric'
   pod 'Crashlytics', '~>  3.10'
   pod 'Fingertips'
   pod 'EasyAnimation'
   pod 'RevealingSplashView'
   pod 'IQKeyboardManagerSwift'
   pod 'Motion'
   pod 'Floaty'
   pod 'NYAlertViewController'
   pod 'SwiftLocation', '~> 3.2.3'
   pod 'BetterSegmentedControl', '~> 0.9'
   
end

target 'Timeline Core' do
    
    use_frameworks!
    
    project 'Timeline Core/Timeline Core.xcodeproj'
    
    pod 'ActionSheetPicker-3.0', '~> 2.2.0'
    pod 'Alamofire', '~> 4.5'
    pod 'AlamofireImage', '~> 3.3'
    pod 'PKHUD', :git => 'https://github.com/pkluz/PKHUD.git', :branch => 'release/swift4'
    pod 'KeychainAccess', '~> 3.0.0'
    pod 'SnapKit', '~> 3.1.1'
    pod 'Material', '~> 2.4.0'
    pod 'KCFloatingActionButton', '~> 2.2'
    pod 'CSV.swift', '~> 2.1'
    pod 'JTAppleCalendar', '~> 7.0'
    pod 'Socket.IO-Client-Swift', '~> 11.1.3'
    pod 'Pulsar', '~> 2.0'
    pod 'UICheckbox.Swift'
    pod 'Chatto', '= 3.2.0'
    pod 'ChattoAdditions', '= 3.2.0'
    pod 'NYTPhotoViewer'
    pod 'MapKitGoogleStyler'
    pod 'Fabric'
    pod 'Crashlytics', '~>  3.10'
    pod 'Fingertips'
    pod 'EasyAnimation'
    pod 'RevealingSplashView'
    pod 'IQKeyboardManagerSwift'
    pod 'Motion'
    pod 'Floaty'
    pod 'NYAlertViewController'
    pod 'SwiftLocation', '~> 3.2.3'
    pod 'BetterSegmentedControl', '~> 0.9'
    pod 'SwiftLint'
    
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end
end
