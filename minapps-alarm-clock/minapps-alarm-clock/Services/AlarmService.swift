//
//  AlarmService.swift
//  minapps-alarm-clock
//
//  Created by Jibran Syed on 12/13/17.
//  Copyright © 2017 Jishenaz. All rights reserved.
//

import Foundation
import CoreData


class AlarmService
{
    static let instance = AlarmService()
    private init()
    {
    }
    
    
    var alarms: [AlarmEntity_CoreData] = []
    private(set) public var nextAlarm: AlarmEntity_CoreData? = nil
    private var nextAlarmTimer: Timer? = nil
    
    
    // Used to load in AppDelegate
    func start()
    {
        self.loadAllAlarms { (success) in
            if success
            {
                print("AlarmService loaded \(self.alarms.count) alarms successfully")
            }
            else
            {
                print("ERROR: AlarmService failed to load alarms")
            }
        }
        
        //self.determineNextAlarm()
    }
    
    
    func loadAllAlarms(onComplete: @escaping (_ success: Bool) -> Void)
    {
        CoreDataService.instance.loadEntities(ofType: AlarmEntity_CoreData.self) { (inAlarms) in
            guard let loadedAlarms = inAlarms else
            {
                print("ERROR: Alarms could not be loaded from Core Data")
                onComplete(false)
                return
            }
            
            self.alarms = loadedAlarms
            onComplete(true)
        }
    }
    
    
    func makeNewAlarmAndSave(onComplete: @escaping (_ newAlarm: AlarmEntity_CoreData?) -> Void)
    {
        let newAlarm = CoreDataService.instance.makeNewEntity(ofType: AlarmEntity_CoreData.self)
        
        CoreDataService.instance.saveAllEntities { (success) in
            if success
            {
                self.loadAllAlarms(onComplete: { (areAlarmsLoaded) in
                    if areAlarmsLoaded
                    {
                        onComplete(newAlarm)
                    }
                    else
                    {
                        print("Making a new alarm: failed to reload the list of alarms!")
                        onComplete(nil)
                    }
                })
            }
            else
            {
                CoreDataService.instance.deleteEntity(ofType: AlarmEntity_CoreData.self, entity: newAlarm)
                print("Making a new alarm: failed to save new alarm!")
                onComplete(nil)
            }
        }
    }
    
    
    func deleteAlarmAndSave(_ alarm: AlarmEntity_CoreData, onComplete: @escaping (_ success: Bool) -> Void)
    {
        CoreDataService.instance.deleteEntity(ofType: AlarmEntity_CoreData.self, entity: alarm)
        
        CoreDataService.instance.saveAllEntities { (success) in
            if success
            {
                self.loadAllAlarms(onComplete: { (areAlarmsLoaded) in
                    if areAlarmsLoaded
                    {
                        onComplete(true)
                    }
                    else
                    {
                        print("Delete an alarm: failed to reload the list of alarms!")
                        onComplete(false)
                    }
                })
            }
            else
            {
                print("Deleting an alarm: failed to delete alarm!")
                onComplete(false)
            }
        }
    }
    
    
    func determineNextAlarm()
    {
        self.cancelNextAlarm()
        
        // TODO: Implement the next alarm algorithm based on the alarm closest to the current time (factoring days of the week)
        self.nextAlarm = self.alarms.first
        
        
        if let activeAlarm = self.nextAlarm
        {
            // Schedule next alarm
            let timeTilAlarmFires = self.determineSecondsTilAlarm(activeAlarm)
            self.nextAlarmTimer = Timer.scheduledTimer(timeInterval: timeTilAlarmFires, target: self, selector: #selector(fireAlarm), userInfo: nil, repeats: false)
            
            print("Next alarm \"\(self.nextAlarm?.alarmName ?? "Unammed Alarm")\" scheduled O")
        }
    }
    
    
    func cancelNextAlarm()
    {
        if self.nextAlarm != nil && self.nextAlarmTimer != nil
        {
            print("Next alarm \"\(self.nextAlarm?.alarmName ?? "Unammed Alarm")\" cancelled X")
            self.nextAlarmTimer!.invalidate()
            self.nextAlarmTimer = nil
            self.nextAlarm = nil
        }
    }
    
    
    
    private func determineSecondsTilAlarm(_ alarm: AlarmEntity_CoreData) -> TimeInterval
    {
        // TODO: Calculate, in seconds, the time from now til the active alarm
        return 10.0
    }
    
    
    @objc
    private func fireAlarm()
    {
        print(">===========")
        print("    Alarm \"\(self.nextAlarm?.alarmName ?? "Unammed Alarm")\" was fired off!")
        print(">===========")
        
        
    }
    
}
