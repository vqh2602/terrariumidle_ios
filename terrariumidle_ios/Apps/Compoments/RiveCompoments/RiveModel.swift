////
////  RiveModel.swift
////  terrariumidle_ios
////
////  Created by vương quang huy on 2/2/26.
////
//@_spi(RiveExperimental) import RiveRuntime
//
//class ToggleViewModel: RiveViewModel {
//  private let onAnimation: String = "On"
//  private let offAnimation: String = "Off"
//  private let startAnimation: String = "StartOff"
//
//  var action: ((Bool) -> Void)? = nil
//  var isOn = false {
//      didSet {
//          stop()
//          play(animationName: isOn ? onAnimation : offAnimation)
//          action?(isOn)
//      }
//  }
//
//  init() {
//      super.init(fileName: "toggle", animationName: startAnimation, fit: .cover)
//  }
//
////  func view(_ action: ((Bool) -> Void)? = nil) -> some View {
////      self.action = action
////      return super.view().frame(width: 100, height: 50, alignment: .center)
////  }
////
////  // When an animation is played
////  override func player(playedWithModel riveModel: RiveModel?) {
////    if let animationName = riveModel?.animation?.name() {...}
////  }
////  // When an animation is paused
////  override func player(pausedWithModel riveModel: RiveModel?) {
////    if let animationName = riveModel?.animation?.name() {...}
////  }
////  // When an animation is stopped
////  override func player(stoppedWithModel riveModel: RiveModel?) {
////    if let animationName = riveModel?.animation?.name() {...}
////  }
////  // When an animation is looped
////  override func player(loopedWithModel riveModel: RiveModel?, type: Int) {
////    if let animationName = riveModel?.animation?.name() {...}
////  }
////  // When an animation is advanced
////  override func player(didAdvanceby seconds: Double, riveModel: RiveModel?) {...}
//}
