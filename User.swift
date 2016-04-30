//
//  User.swift
//  MappedOut
//
//  Created by Thomas Clifford on 3/10/16.
//  Copyright © 2016 Codepath. All rights reserved.
//

import UIKit
import Parse
import ParseUI

class User: PFUser {
    
    //Not yet finished
    
    //User inherits the properties username, password, and objectId from PFUser
    
    var name: String?
    var propicFile: PFFile?
    var eventsAttending: [String]?
    var eventsInvitedTo: [String]?
    var eventsOwned: [String]?
    var location: CLLocation?
    var friendIDs: [String]?
    var followerIDs: [String]?
    var userObjectID: String?
    
    
    override init() {
        super.init()
//        self.name = PFUser.currentUser()?.username
        self.eventsOwned = PFUser.currentUser()?.objectForKey("eventOwned") as? [String]
        self.eventsAttending = PFUser.currentUser()?.objectForKey("eventsAttending") as? [String]
        self.eventsInvitedTo = PFUser.currentUser()?.objectForKey("eventsInvitedTo") as? [String]
        self.friendIDs = PFUser.currentUser()?.objectForKey("friendIDs") as? [String]
        self.name = PFUser.currentUser()?.objectForKey("username") as? String
        self.propicFile = PFUser.currentUser()?.objectForKey("picture") as? PFFile
//        self.username = PFUser.currentUser()?.username
        self.objectId = PFUser.currentUser()?.objectId
        self.followerIDs = PFUser.currentUser()?.objectForKey("followerIDs") as? [String]
        self.userObjectID = PFUser.currentUser()?.objectForKey("userObjectID") as? String
    }
    
    //    init(name: String?, propic: UIImage?, eventsAttending: [String]?, eventsOwned: [String]?) {
    //        super.init()
    //        self.name = name
    //        self.propic = propic
    //        self.eventsAttending = eventsAttending
    //        self.eventsOwned = eventsOwned
    //    }
    
    init(user: PFUser) {
        super.init()
        self.name = user.objectForKey("name") as? String
        self.propicFile = user.objectForKey("picture") as? PFFile
        self.eventsAttending = user.objectForKey("eventsAttending") as? [String]
        self.eventsOwned = user.objectForKey("eventOwned") as? [String]
        self.eventsInvitedTo = user.objectForKey("eventsInvitedTo") as? [String]
        self.friendIDs = user.objectForKey("friendIDs") as? [String]
        self.username = user.username
        self.objectId = user.objectId
        self.followerIDs = user.objectForKey("followerIDs") as? [String]
        self.userObjectID = user.objectForKey("userObjectID") as? String
        
        let loc = user.objectForKey("location") as? PFGeoPoint
        if let loc = loc {
            self.location = CLLocation(latitude: (loc.latitude), longitude: (loc.longitude))
        }
    }
    
    func updateProfile(name: String?, picture: UIImage?) {
        if let name = name {
            PFUser.currentUser()?.setObject("\(name)", forKey: "name")
        }
        if let picture = picture {
            let file = Event.getPFFileFromImage(picture)
            if let file = file {
                PFUser.currentUser()?.setObject(file, forKey: "picture")
            }
            
        }
        
        PFUser.currentUser()?.saveInBackground()
    }
    
    func addFriend(user: User) {
        print(friendIDs)
        let id = user.objectId!
        if (friendIDs) != nil {
            self.friendIDs!.append(id)
        }else{
            friendIDs = [id]
        }
        print(friendIDs)
        PFUser.currentUser()?.setObject(friendIDs!, forKey: "friendIDs")
        
        PFUser.currentUser()?.saveInBackgroundWithBlock({ (done:Bool, error:NSError?) in
            if(done){
                print("upload success")
                
                let query = PFQuery(className: "UserObject")
                query.getObjectInBackgroundWithId(user.userObjectID!, block: { (object: PFObject?, error: NSError?) in
                    if let object = object {
                        print("Object: ")
                        print(object)
                        var userObj = UserObject(object: object)
                        var followerIDs = userObj.followerIDs
                        if followerIDs != nil {
                            followerIDs!.append(self.objectId!)
                        }
                        else {
                            followerIDs = [self.objectId!]
                        }
                        print("Follower IDs: ")
                        print(followerIDs)
                        object.setObject(followerIDs!, forKey: "followerIDs")
                        object.saveInBackground()
                    }
                })
                
//                let query = PFQuery(className: "_User")
//                query.whereKey("_id", equalTo: id)
//                query.getFirstObjectInBackgroundWithBlock({ (object: PFObject? ,error: NSError?) in
//                    var user = User(user: object as! PFUser)
//                    if let followerIDs = user.followerIDs {
//                        user.followerIDs!.append(self.objectId!)
//                        print("567")
//                    }
//                    else {
//                        user.followerIDs = [self.objectId!]
//                        print("8910")
//                        print(self.objectId!)
//                        print(user.followerIDs)
//                    }
//                    user.setObject(user.followerIDs!, forKey: "followerIDs")
//                    user.saveInBackgroundWithBlock({ (success: Bool, error: NSError?) in
//                        if (success) {
//                            
//                        }
//                        else {
//                            print(error?.localizedDescription)
//                        }
//                    })
//                })
            }else{
                print(error)
            }
        })
    }
    
    func removeFriend(user: User) {
        print(friendIDs)
        let id = user.objectId!
        if (friendIDs) != nil {
            self.friendIDs! = self.friendIDs!.filter() { $0 != id }
        }
        
        PFUser.currentUser()?.setObject(friendIDs!, forKey: "friendIDs")
        
        PFUser.currentUser()?.saveInBackgroundWithBlock({ (done:Bool, error:NSError?) in
            if(done){
                print("upload success")
                let query = PFQuery(className: "UserObject")
                query.getObjectInBackgroundWithId(user.userObjectID!, block: { (object: PFObject?, error: NSError?) in
                    if let object = object {
                        var userObj = UserObject(object: object)
                        var followerIDs = userObj.followerIDs
                        if followerIDs != nil {
                            followerIDs = followerIDs!.filter() { $0 != id }
                        }
                        object.setObject(followerIDs!, forKey: "followerIDs")
                        object.saveInBackground()
                    }
                })
                
            }else{
                print(error)
            }
        })
    }
    
    func addOwnedEvent(id:String){
        if(eventsAttending != nil){
            self.eventsAttending?.append(id)
        }else{
            eventsAttending = [id]
        }
        PFUser.currentUser()?.setObject(eventsAttending!, forKey: "eventsAttending")
        
        if(eventsOwned != nil){
            self.eventsOwned?.append(id)
        }else{
            eventsOwned = [id]
        }
        PFUser.currentUser()?.setObject(eventsOwned!, forKey: "eventOwned")
        
        PFUser.currentUser()?.saveInBackgroundWithBlock({ (done:Bool, error:NSError?) in
            if(done){
                print("upload success")
            }else{
                print(error)
            }
        })
    }
    
    //getFriends() returns an array of Users on success in it's closure.
    func getFriends(success: (friends: [User])->()) {
        var friends: [User] = []
        if let friendIDs = friendIDs {
            let query = PFQuery(className: "_User")
            query.whereKey("_id", containedIn: friendIDs)
            
            query.findObjectsInBackgroundWithBlock({ (objects: [PFObject]?, error: NSError?) -> Void in
                if(error != true) {
                    if let objects = objects {
                        for object in objects {
                            friends.append(User(user: object as! PFUser))
                        }
                    }
                }
                else {
                    print(error?.localizedDescription)
                }
                success(friends: friends)
            })
        }
    }
    
    func getFollowers(success: (followers: [User])->()) {
        var followers: [User] = []
        
        self.getUserObject { (userObj: UserObject) in
            let ids = userObj.followerIDs
            if let ids = ids {
                let query = PFQuery(className: "_User")
                query.whereKey("_id", containedIn: ids)
                
                query.findObjectsInBackgroundWithBlock({ (objects: [PFObject]?, error: NSError?) -> Void in
                    if(error != true) {
                        if let objects = objects {
                            for object in objects {
                                followers.append(User(user: object as! PFUser))
                            }
                        }
                    }
                    else {
                        print(error?.localizedDescription)
                    }
                    success(followers: followers)
                })
            }
        }
        
//        if let followerIDs = followerIDs {
//            let query = PFQuery(className: "_User")
//            query.whereKey("_id", containedIn: followerIDs)
//            
//            query.findObjectsInBackgroundWithBlock({ (objects: [PFObject]?, error: NSError?) -> Void in
//                if(error != true) {
//                    if let objects = objects {
//                        for object in objects {
//                            followers.append(User(user: object as! PFUser))
//                        }
//                    }
//                }
//                else {
//                    print(error?.localizedDescription)
//                }
//                success(followers: followers)
//            })
//        }
    }
    
    
    func getNearbyUsers(currentLocation: CLLocation, success: ([User])->()) {
        
        let query = PFQuery(className: "_User")
        let loc = PFGeoPoint(location: currentLocation)
        
        query.whereKey("location", nearGeoPoint: loc, withinMiles: 2)
        
        query.findObjectsInBackgroundWithBlock { (users: [PFObject]?, error: NSError?) -> Void in
            if let users = users {
                var usersArray: [User] = []
                for user in users {
                    usersArray.append(User(user: user as! PFUser))
                }
                
                success(usersArray)
            } else {
                print(error)
            }
        }
    }
    
    class func getUserByUsername(username: String, success: (User?)->()) {
        let query = PFQuery(className: "_User")
        query.whereKey("username", equalTo: username)
        
        query.getFirstObjectInBackgroundWithBlock { (object: PFObject?, error: NSError?) -> Void in
            var user: User?
            if let object = object {
                user = User(user: object as! PFUser)
                success(user)
            }
            else {
                user = nil
                success(user)
            }
            
        }
    }
    
    func getPublicAttendingEvents(success: ([Event])->()) {
        let query = PFQuery(className: "Event")
        var events: [Event] = []
        if let eventsAttending = eventsAttending {
            query.whereKey("_id", containedIn: eventsAttending)
            query.whereKey("date", greaterThan: NSDate())
            query.whereKey("isPublic", equalTo: true)
            query.orderByAscending("date")
            query.findObjectsInBackgroundWithBlock({ (objects: [PFObject]?, error: NSError?) in
                if let objects = objects {
                    for object in objects {
                        events.append(Event(event: object))
                    }
                    success(events)
                }
                else {
                    print(error?.localizedDescription)
                    success(events)
                }
            })
        }
        else {
           success(events)
        }
    }
    
    func getOwnedEvents(success: ([Event])->()) {
        let query = PFQuery(className: "Event")
        var events: [Event] = []
        if let eventsOwned = eventsOwned {
            query.whereKey("_id", containedIn: eventsOwned)
            query.whereKey("date", greaterThan: NSDate())
            query.orderByAscending("date")
            query.findObjectsInBackgroundWithBlock({ (objects: [PFObject]?, error: NSError?) in
                if let objects = objects {
                    for object in objects {
                        events.append(Event(event: object))
                    }
                    success(events)
                }
                else {
                    print(error?.localizedDescription)
                    success(events)
                }
            })
        }
        else {
            success(events)
        }
    }
    
    func getUserObject(success: (UserObject)->()) {
        let query = PFQuery(className: "UserObject")
        query.getObjectInBackgroundWithId(self.userObjectID!) { (object: PFObject?, error: NSError?) in
            if let object = object {
                let userObject = UserObject(object: object)
                success(userObject)
            }
        }
    }
    
    class func getAllUsers(success: ([User])->()) {
        var users: [User] = []
        let query = PFQuery(className: "_User")
        query.findObjectsInBackgroundWithBlock { (objects: [PFObject]?, error: NSError?) in
            if let objects = objects {
                for object in objects {
                    users.append(User(user: object as! PFUser))
                }
            }
            success(users)
        }
    }
    
}
