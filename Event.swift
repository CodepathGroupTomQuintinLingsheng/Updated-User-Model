//
//  Event.swift
//  MappedOut
//
//  Created by Thomas Clifford on 3/10/16.
//  Copyright © 2016 Codepath. All rights reserved.
//

import UIKit
import Parse
import ParseUI

class Event: NSObject {
    
    //Not yet finished
    
    var name: String?
    var ownerName: String?
    var ownerID: String?
    var descript: String?
    var location: CLLocation?
    var attendanceCount: Int? = 0
    var usersAttending: [String] = []
    var address: String?
    
    //Should be UIImage.  Store in Parse as PFFile
    var pictureFile: PFFile?
    var startDate: NSDate?
    var endDate: NSDate?
    var id: String?
    var isPublic: Bool? = true
    var owner : User?
    
    init(event: PFObject) {
        super.init()
        self.id = event.objectId
        
        self.name = event["name"] as? String
        self.ownerName = event["ownerName"] as? String
        self.ownerID = event["ownerID"] as? String
        self.descript = event["description"] as? String
        let loc = event["location"] as? PFGeoPoint
        self.location = CLLocation(latitude: (loc?.latitude)!, longitude: (loc?.longitude)!)
        self.attendanceCount =  event["attendanceCount"] as? Int
        self.address = event["address"] as? String
        
        let attendingUsers = event["usersAttending"] as? [String]
        if(attendingUsers != nil) {
            self.usersAttending = attendingUsers!
        }
        
        self.pictureFile = event["picture"] as? PFFile
        
        self.startDate = event["date"] as? NSDate
        self.endDate = event["endDate"] as? NSDate
        self.isPublic = event["isPublic"] as? Bool
    }
    init(name: String?, owner: User, description: String?, location: CLLocation?, picture: UIImage?, startDate: NSDate?, endDate: NSDate?, isPublic: Bool, address: String?) {
        super.init()
        self.name = name
        self.ownerName = owner.name
        self.ownerID = owner.objectId
        self.usersAttending.append(owner.objectId!)
        self.descript = description
        self.address = address
        self.location = location
        self.pictureFile = Event.getPFFileFromImage(picture)
        self.startDate = startDate
        self.endDate = endDate
        self.isPublic = isPublic
        self.attendanceCount! += 1
        Event.postEvent(self) { (eventObj: PFObject) -> () in
            self.id = eventObj.objectId
            let owner = User()
            owner.addOwnedEvent(self.id!)
            print(self.id)
        }
    }
    
    class func postEvent(inputEvent: Event, success: (PFObject)->()) {
        // Create Parse object PFObject
        let event = PFObject(className: "Event")
        
        // Add relevant fields to the object
        
        event["name"] = inputEvent.name
        event["ownerName"] = inputEvent.ownerName
        event["ownerID"] = inputEvent.ownerID
        event["description"] = inputEvent.descript
        event["attendanceCount"] = inputEvent.attendanceCount
        event["usersAttending"] = inputEvent.usersAttending
        
        event["picture"] = inputEvent.pictureFile
        
        event["address"] = inputEvent.address
        event["date"] = inputEvent.startDate
        event["endDate"] = inputEvent.endDate
        event["isPublic"] = inputEvent.isPublic
        
        let point = PFGeoPoint(location: inputEvent.location)
        event["location"] = point
        
        
        // Save object (following function will save the object in Parse asynchronously)
        event.saveInBackgroundWithBlock { (done: Bool, error: NSError?) -> Void in
            if(done) {
                success(event)
                print("create success")
                
                let eventId = event.objectId
                var eventsOwned = PFUser.currentUser()?.objectForKey("eventOwned") as? [String]
                if eventsOwned != nil {
                    eventsOwned!.append(eventId!)
                }
                else {
                    eventsOwned = [eventId!]
                }
                
                PFUser.currentUser()?.setObject(eventsOwned!, forKey: "eventOwned")
                
                PFUser.currentUser()?.fetchInBackground()
                //                NSNotificationCenter.defaultCenter().postNotificationName(userDidCreatenewNotification, object: nil)
            }
        }
    }
    
    class func getNearbyEvents(currentLocation: CLLocation, orderBy: String, success: ([Event])->()) {
        
        let query = PFQuery(className: "Event")
        let loc = PFGeoPoint(location: currentLocation)
        
        query.whereKey("location", nearGeoPoint: loc, withinMiles: 2)
        query.orderByDescending(orderBy)
        
        query.findObjectsInBackgroundWithBlock { (events: [PFObject]?, error: NSError?) -> Void in
            if let events = events {
                var eventsArray: [Event] = []
                for event in events {
                    eventsArray.append(Event(event: event))
                }
                
                success(eventsArray)
            } else {
                print(error)
            }
        }
    }
    
    class func getEventsbyIDs(ids:[String],orderBy:String,success:([Event])->()){
        let query = PFQuery(className: "Event")
        query.whereKey("_id", containedIn: ids)
        query.orderByDescending(orderBy)
        
        query.findObjectsInBackgroundWithBlock { (events:[PFObject]?, error: NSError?) in
            if let events = events {
                var eventsArray: [Event] = []
                for event in events {
                    eventsArray.append(Event(event: event))
                }
                
                success(eventsArray)
                
            } else {
                print(error)
            }
        }
    }
    
    class func deleteEvent(event: Event, success: ()->()) {
        let query = PFQuery(className: "Event")
        //Also must delete event from any Events arrays
        query.getObjectInBackgroundWithId(event.id!) {
            (parseEvent: PFObject?, error: NSError?) -> Void in
            if error == nil && parseEvent != nil {
                parseEvent?.deleteEventually()
                success()
            } else {
                print(error)
            }
        }
    }
    
    class func addAttendee(user: User, event: Event) {
        //Does not account for the user side
        event.attendanceCount! += 1
        event.usersAttending.append(user.objectId!)
    }
    
    
    /**
     Method to convert UIImage to PFFile
     
     - parameter image: Image that the user wants to upload to parse
     
     - returns: PFFile for the the data in the image
     */
    class func getPFFileFromImage(image: UIImage?) -> PFFile? {
        // check if image is not nil
        if let image = image {
            // get image data and check if that is not nil
            if let imageData = UIImagePNGRepresentation(image) {
                return PFFile(name: "image.png", data: imageData)
            }
        }
        return nil
    }
    
    func inviteUsersWithIDs(users: [User]) {
        var userIds: [String] = []
        for user in users {
            if let objectID = user.objectId {
                userIds.append(objectID)
            }
        }
        let id = self.id
        let query = PFQuery(className: "_User")
        query.whereKey("_id", containedIn: userIds)
        query.findObjectsInBackgroundWithBlock { ( objects: [PFObject]?, error: NSError?) in
            if let objects = objects {
                for object in objects {
                    let user = object as! PFUser
                    var events = user.objectForKey("eventsInvitedTo") as! [String]
                    events.append(id!)
                    user.setObject(id!, forKey: "eventsInvitedTo")
                    user.saveInBackground()
                }
            }
        }
    }
    
    func getUsersAttending(success: ([User])->()) {
        var users: [User] = []
        let query = PFQuery(className: "_User")
        query.whereKey("_id", containedIn: usersAttending)
        query.findObjectsInBackgroundWithBlock { (objects: [PFObject]?, error: NSError?) in
            if let objects = objects {
                for object in objects {
                    let user = User(user: object as! PFUser)
                    users.append(user)
                }
            }
            success(users)
        }
    }
    
    func inviteToEvent(users: [User], success: ()->()) {
        var userIds: [String] = []
        for user in users {
            userIds.append(user.userObjectID!)
        }
        let query = PFQuery(className: "UserObject")
        query.whereKey("_id", containedIn: userIds)
        query.findObjectsInBackgroundWithBlock { (objects: [PFObject]?, error: NSError?) in
            if let objects = objects {
                for object in objects {
                    let userObject = UserObject(object: object)
                    
                    if userObject.eventsInvitedTo != nil {
                        userObject.eventsInvitedTo?.append(self.id!)
                    }
                    else {
                        userObject.eventsInvitedTo  = [self.id!]
                    }

                    object.setObject(userObject.eventsInvitedTo!, forKey: "eventsInvitedTo")
                    object.saveInBackground()
                }
                success()
            }
        }
    }
    
}
