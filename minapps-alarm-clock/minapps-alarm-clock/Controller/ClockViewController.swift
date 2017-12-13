//
//  ClockViewController.swift
//  minapps-alarm-clock
//
//  Created by Jibran Syed on 12/8/17.
//  Copyright © 2017 Jishenaz. All rights reserved.
//

import UIKit

class ClockViewController: UIViewController 
{
    static let MAX_COVER_OPACITY: CGFloat = 0.8
    
    @IBOutlet weak var lblHoursAndMinutes: UILabel!
    @IBOutlet weak var lblSeconds: UILabel!
    @IBOutlet weak var lblAmOrPm: UILabel!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var lblBatteryGadge: UILabel!
    @IBOutlet weak var imgBell: UIImageView!
    @IBOutlet weak var imgBattery: UIImageView!
    @IBOutlet weak var btnGear: UIButton!
    @IBOutlet weak var lblAlarmInfo: UILabel!
    @IBOutlet weak var viewBrightnessCover: UIView!
    
    
    private var clockTimer: Timer?
    private var clockData = ClockTimeData()
    private var dateData = ClockDateData()
    private var currTouchPos = CGPoint()
    private var prevTouchPos = CGPoint()
    private var touchMoveDelta: CGFloat = 0.0
    
    
    
    // Properties
    
    private var batteryPercentage: Int
    {
        get
        {
            return Int(UIDevice.current.batteryLevel * 100.0)
        }
    }
    
    
    private var brightnessCoverOpacity: CGFloat
    {
        get
        {
            // Converting brightness (0 to 1) to alpha (0.8 to 0)
            let brightnessRatio = SettingsService.instance.getBrightnessRatio()
            return ClockViewController.MAX_COVER_OPACITY * abs(brightnessRatio - 1.0)
        }
    }
    
    
    
    
    // View Controller Stuff
    
    override func viewDidLoad() 
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Setup all views based off app settings
        self.onSettingsChanged()
        
        
        // Setup setting service notification
        NotificationCenter.default.addObserver(self, selector: #selector(onSettingsChanged), name: UserDefaults.didChangeNotification, object: nil)
        
        // Setup battery monitoring
        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(onBatteryLevelChanged(_:)), name: .UIDeviceBatteryLevelDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onBatteryStateChanged(_:)), name: .UIDeviceBatteryStateDidChange, object: nil)
        
        
        // Setup brightness swipe gestures
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(onSwipeScreen(gesture:)))
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(onSwipeScreen(gesture:)))
        swipeUp.direction = .up
        swipeDown.direction = .down
        self.view.addGestureRecognizer(swipeUp)
        self.view.addGestureRecognizer(swipeDown)
        
        
        // Initialize clock update "loop" (accurately a repeating timer event)
        self.initializeClockTimer()
    }
    
    override func viewWillAppear(_ animated: Bool) 
    {
        super.viewWillAppear(animated)
        
        self.updateClockFace()
        
        if self.clockTimer?.isValid == false
        {
            self.stopClockTimer()
            self.initializeClockTimer()
        }
        
        self.updateClockFace()
        self.updateBatteryGadge()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) 
    {
        self.stopClockTimer()
        
        super.viewWillDisappear(animated)
    }
    
    
    override func didReceiveMemoryWarning() 
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
        self.stopClockTimer()
    }
    
    
    
    
    
    
    // Methods
    
    
    func setupColor(_ newColor: UIColor)
    {
        self.btnGear.imageView?.tintColor = newColor
        self.imgBell.tintColor = newColor
        self.imgBattery.tintColor = newColor
        self.lblBatteryGadge.textColor = newColor
        self.lblDate.textColor = newColor
        self.lblAmOrPm.textColor = newColor
        self.lblSeconds.textColor = newColor
        self.lblAlarmInfo.textColor = newColor
        self.lblHoursAndMinutes.textColor = newColor
    }
    
    
    private func initializeClockTimer()
    {
        self.stopClockTimer()
        
        self.clockTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (timer) in
            self.updateClockFace()
        })
    }
    
    
    private func stopClockTimer()
    {
        self.clockTimer?.invalidate()
        self.clockTimer = nil
    }
    
    
    private func updateClockFace()
    {
        let currentDateTime = Date()
        
        // Get current time
        self.clockData.updateTime(withDate: currentDateTime)
        
        // Output Time (hour and minute)
        if SettingsService.instance.isUsing24HourConvention()
        {
            self.lblHoursAndMinutes.text = "\(clockData.hoursText24):\(clockData.minutesText)"
            self.lblAmOrPm.isHidden = true
        }
        else
        {
            self.lblHoursAndMinutes.text = "\(clockData.hoursText12):\(clockData.minutesText)"
            self.lblAmOrPm.text = " \(clockData.amOrPmText.uppercased())"
            self.lblAmOrPm.isHidden = false
        }
        
        // Output seconds
        if SettingsService.instance.doesShowSeconds()
        {
            self.lblSeconds.text = ":\(clockData.secondsText)"
            self.lblSeconds.isHidden = false
        }
        else
        {
            self.lblSeconds.isHidden = true
        }
        
        
        // Get current date
        if SettingsService.instance.doesShowDate()
        {
            self.dateData.updateDate(withDate: currentDateTime)
            self.lblDate.text = "\(dateData.weekdayShort.uppercased()), \(dateData.monthShort.uppercased()) \(dateData.day) \(dateData.year)"
            self.lblDate.isHidden = false
        }
        else
        {
            self.lblDate.isHidden = true
        }
    }
    
    
    private func updateBatteryGadge()
    {
        if SettingsService.instance.doesShowBattery() 
        {
            self.imgBattery.isHidden = false
            let batteryValue = self.batteryPercentage
            if batteryValue < 0 // Negative battery meter means we are on the Simulator
            {
                self.lblBatteryGadge.text = "SIMU"
            }
            else
            {
                self.lblBatteryGadge.text = "\(self.batteryPercentage)%"
            }
            self.lblBatteryGadge.isHidden = false
        }
        else
        {
            self.imgBattery.isHidden = true
            self.lblBatteryGadge.isHidden = true
        }
    }
    
    
    func updateDisplayBrightness()
    {
        self.viewBrightnessCover.backgroundColor = UIColor(white: 0.0, alpha: self.brightnessCoverOpacity)
    }
    
    
    func updateFont(named fontName: String)
    {
        self.lblDate.font = UIFont(name: fontName, size: lblDate.font.pointSize)
        self.lblBatteryGadge.font = UIFont(name: fontName, size: lblBatteryGadge.font.pointSize)
        self.lblHoursAndMinutes.font = UIFont(name: fontName, size: lblHoursAndMinutes.font.pointSize)
        self.lblSeconds.font = UIFont(name: fontName, size: lblSeconds.font.pointSize)
        self.lblAmOrPm.font = UIFont(name: fontName, size: lblAmOrPm.font.pointSize)
        self.lblAlarmInfo.font = UIFont(name: fontName, size: lblAlarmInfo.font.pointSize)
    }
    
    func determineAutolockState()
    {
        let isDevicePluggedIn = UIDevice.current.batteryState == .full || UIDevice.current.batteryState == .charging
        
        if isDevicePluggedIn
        {
            let autolockShouldBeEnabled = SettingsService.instance.willAutoLockWhenPluggedIn()
            
            if autolockShouldBeEnabled
            {
                UIApplication.shared.isIdleTimerDisabled = false
            }
            else // Disale autolock
            {
                UIApplication.shared.isIdleTimerDisabled = true
            }
        }
        else
        {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    
    
    // Events
    
    
    @objc
    func onBatteryLevelChanged(_ notification: Notification)
    {
        self.updateBatteryGadge()
    }
    
    @objc 
    func onBatteryStateChanged(_ notification: Notification)
    {
        self.determineAutolockState()
    }
    
    
    @objc
    func onSettingsChanged()
    {
        self.setupColor(SettingsService.instance.getColor())
        self.updateFont(named: SettingsService.instance.getFont())
        self.updateClockFace()
        self.updateBatteryGadge()
        self.updateDisplayBrightness()
        self.determineAutolockState()
    }
    
    
    @objc
    func onSwipeScreen(gesture: UISwipeGestureRecognizer)
    {
        if SettingsService.instance.canSwipeToControlBrightness()
        {
            let oldValue = SettingsService.instance.getBrightnessRatio()
            let delta = (self.touchMoveDelta / 100.0)
            
            if gesture.direction == .up
            {
                SettingsService.instance.setBrightnessRatio(oldValue + delta)
            }
            else if gesture.direction == .down
            {
                SettingsService.instance.setBrightnessRatio(oldValue - delta)
            }
        }
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) 
    {
        if let touch = touches.first
        {
            self.currTouchPos = touch.location(in: self.view)
            self.prevTouchPos = self.currTouchPos
        }
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) 
    {
        if let touch = touches.first
        {
            self.currTouchPos = touch.location(in: self.view)
            
            // Calculate a movement delta with distance formula
            let xDelta = self.currTouchPos.x - self.prevTouchPos.x
            let yDelta = self.currTouchPos.y - self.prevTouchPos.y
            self.touchMoveDelta = sqrt(xDelta * xDelta + yDelta * yDelta)
            
            self.prevTouchPos = self.currTouchPos
        }
    }
    
    
    
    @IBAction func onSettingsBtnPressed(_ sender: Any) 
    {
        if let appSettings = URL(string: UIApplicationOpenSettingsURLString)
        {
            UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
        }
    }
    
    @IBAction func onAlarmBtnPressed(_ sender: Any) 
    {
        
    }
    
    
    
    
    
    
}

