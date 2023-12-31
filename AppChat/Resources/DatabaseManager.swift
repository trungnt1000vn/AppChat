//
//  DatabaseManager.swift
//  AppChat
//
//  Created by Trung on 05/06/2023.
//
import Foundation
import Firebase
import MessageKit
import CoreLocation


final class DatabaseManager{
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    static func safeEmail(emailAddress: String) -> String{
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
}
extension DatabaseManager{
    public func getDataFor(path: String, completion :@escaping (Result<Any, Error>) -> Void){
        self.database.child("\(path)").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
}
extension DatabaseManager{
    public func userExists(with email:String,completion:@escaping((Bool)-> Void)){
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        database.child(safeEmail).observeSingleEvent(of: .value, with: {snapshot in
            guard  snapshot.value as? [String: Any] != nil else{
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    
    ///Inserts new user to database
    public func insertUser(with user: ChatAppUser, completion: @escaping(Bool) -> Void){
        database.child(user.safeEmail).setValue(["first name": user.firstName,
                                                 "last_name": user.lastName], withCompletionBlock:{[weak self] error , _ in
            guard let strongSelf = self else {
                return
            }
            guard error == nil else{
                print("failed to write to database")
                completion(false)
                return
            }
            /*
             users => [
             [
             "name":
             "safe_email":
             ]
             
             ]
             */
            strongSelf.database.child("users").observeSingleEvent(of: .value, with: {
                snapshot in
                if var usersCollection = snapshot.value as? [[String:String]]{
                    //append to user dictionary
                    let newElement: [[String:String]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                    ]
                    usersCollection.append(contentsOf: newElement)
                    strongSelf.database.child("users").setValue(usersCollection,withCompletionBlock: { error , _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                }
                else{
                    //create that array
                    let newCollection: [[String:String]] = [
                        ["name": user.firstName + " " + user.lastName,
                         "email": user.safeEmail
                        ]
                    ]
                    strongSelf.database.child("users").setValue(newCollection,withCompletionBlock: { error , _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                }
            })
            
            completion(true)
        })
    }
    public func getAllUsers(completion: @escaping (Result<[[String:String]], Error>) -> Void){
        database.child("users").observeSingleEvent(of: .value, with: {
            snapshot in
            guard let value = snapshot.value as? [[String:String]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        })
    }
    public enum DatabaseError: Error{
        case failedToFetch
    }
}

/// MARK : - Sending Messages / conversations
extension DatabaseManager {
    /*
     
     
     Conversation => [
     [
     "conversation_id":
     "other_user_email":
     "lastest_message"" => {
     "date": Date()
     "latest_message": "message"
     "is_read": true/false
     }
     ]
     
     ]
     */
    
    /// Create a new conversation with target user email and first message sent
    public func createNewConversation(with otherUserEmail: String,name: String, firstMessage : Message, completion: @escaping (Bool) -> Void){
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
              let currentName = UserDefaults.standard.value(forKey: "name") as? String
        else{
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value, with: {[weak self] snapshot in
            guard var userNode = snapshot.value as? [String: Any] else{
                completion(false)
                print("User not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            let timeString = ChatViewController.dateFormatter1.string(from: messageDate)
            let senderString = safeEmail
            var message = ""
            switch firstMessage.kind{
                
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            let conversationId = "conversation_\(firstMessage.messageId)"
            let newConversationData: [String: Any] = [
                "id": "conversation_\(firstMessage.messageId)",
                "other_user_email": otherUserEmail,
                "name": name,
                "latest_message": [
                    "date":dateString,
                    "time":timeString,
                    "sender":senderString,
                    "message": message,
                    "is_read": false,
                    "type": firstMessage.kind.messageKindString
                ]
            ]
            
            
            let recipient_newConversationData: [String: Any] = [
                "id": "conversation_\(firstMessage.messageId)",
                "other_user_email": safeEmail,
                "name":  currentName,
                "latest_message": [
                    "date":dateString,
                    "time":timeString,
                    "sender":senderString,
                    "message": message,
                    "is_read": false,
                    "type": firstMessage.kind.messageKindString
                ]
            ]
            //Update recipient conversation entry
            
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: {
                [weak self] snapshot in
                if var conversations = snapshot.value as? [[String: Any]] {
                    //append
                    conversations.append(recipient_newConversationData)
                    let conversationUpdates = ["\(otherUserEmail)/conversations": conversations]
                    self?.database.updateChildValues(conversationUpdates)
                }
                else{
                    //Creation
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                }
            })
            
            //Update current user conversation entry
            if var conversations = userNode["conversations"] as? [[String: Any]]{
                // conversation array exists for current user
                // you should append
                
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name,conversationID: conversationId, firstMessage: firstMessage, completion: completion)
                })
            }
            else {
                // Conversation array does NOT exist
                // Create it
                userNode["conversations"] = [
                    newConversationData
                ]
                
                ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name,conversationID: conversationId, firstMessage: firstMessage, completion: completion)
                })
            }
        })
    }
    
    private func finishCreatingConversation(name: String,conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void){
        //        {
        //            "id": String,
        //            "type": text, photo, video,
        //            "content": String,
        //            "date": Date(),
        //            "sender_email": String,
        //            "isRead": true/false,
        //        }
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        let timeString = ChatViewController.dateFormatter1.string(from: messageDate)
        
        var message = ""
        switch firstMessage.kind{
            
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else{
            completion(false)
            return
        }
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "time": timeString,
            "sender_email": currentUserEmail,
            "is_read": false,
            "name": name
        ]
        let value: [String: Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        print("Adding conversation: \(conversationID)")
        database.child("\(conversationID)").setValue(value, withCompletionBlock:{ error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    /// Fetch and returns all conversations for the user with passed in email
    public func getAllConverssations(for email: String, completion: @escaping (Result<[Conversation],Error>) -> Void){
        database.child("\(email)/conversations").observe(.value, with: {snapshot in
            guard let value = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            let conversations: [Conversation] = value.compactMap({ dictionary in
                guard let conversationId = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String: Any],
                      let date = latestMessage["date"] as? String,
                      let time = latestMessage["time"] as? String,
                      let sender = latestMessage["sender"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool,
                      let type = latestMessage["type"] as? String
                else {
                    return nil
                }
                
                
                let latestMessageObject = LatestMessage(date: date, time: time, sender: sender, text: message, isRead: isRead, type: type)
                
                return Conversation(id: conversationId, name: name, otherUserEmail: otherUserEmail, latestMessage: latestMessageObject)
            })
            completion(.success(conversations))
        })
    }
    
    /// Get all messages for a given conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message],Error>) -> Void){
        database.child("\(id)/messages").observe(.value, with: {snapshot in
            guard let value = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let messages: [Message] = value.compactMap({ dictionary in
                print(dictionary)
                guard let messageID = dictionary["id"] as? String
                else {
                    return nil
                }
                let name = dictionary["name"] as? String ?? "Unknown"
                let isRead = dictionary["is_read"] as? Bool
                let content = dictionary["content"] as? String ?? "Unknow"
                let senderEmail = dictionary["sender_email"] as? String ?? "unknown@gmail.com"
                let type = dictionary["type"] as? String ?? "Unknown"
                let dateString = dictionary["date"] as? String ?? "Unknown"
                let timeString = dictionary["time"] as? String ?? "Unknown"
                let date = ChatViewController.dateFormatter.date(from: dateString ?? "") ?? Date()
                let time = ChatViewController.dateFormatter1.date(from: timeString ?? "") ?? Date()
                var kind: MessageKind?
                if type == "photo"{
                    guard let imageUrl = URL(string: content),
                          let placeHolder = UIImage(systemName: "plus")
                    else {
                        return nil
                    }
                    let media = Media(url: imageUrl, image: nil, placeholderImage: placeHolder, size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                }
                else if type == "video"{
                    guard let videoUrl = URL(string: content),
                          let placeHolder = UIImage(systemName: "play")
                    else {
                        return nil
                    }
                    let media = Media(url: videoUrl, image: nil, placeholderImage: placeHolder, size: CGSize(width: 300, height: 300))
                    kind = .video(media)
                }
                else if type == "location"{
                    let locationComponent = content.components(separatedBy: ",")
                    guard let longitude = Double(locationComponent[0]) ,let latitude = Double(locationComponent[1])
                    else {
                        return nil
                    }
                    let location = Location(location: CLLocation(latitude: latitude, longitude: longitude), size: CGSize(width: 300, height: 300))
                    kind = .location(location)
                }
                else {
                    kind = .text(content)
                }
                
                guard let finalKind = kind else {
                    return nil
                }
                
                let sender = Sender(photoURL: "", senderId: senderEmail, displayName: name)
                return Message(sender: sender, messageId: messageID, sentDate: date, kind: finalKind)
            })
            completion(.success(messages))
        })
    }
    
    
    /// Send a message with target conversation and message
    public func sendMessage(to conversation: String,otherUserEmail :String, name :String, newMessage: Message,completion: @escaping(Bool) -> Void){
        // add new message to messages
        //update sender latest message
        //update recipient latest message
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String
        else{
            completion(false)
            return
        }
        let currentEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        database.child("\(conversation)/messages").observeSingleEvent(of: .value, with: {[weak self]snapshot in
            guard let strongSelf = self else{
                return
            }
            
            guard var currentMessages = snapshot.value as?[[String:Any]]
            else{
                completion(false)
                return
            }
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            let timeString = ChatViewController.dateFormatter1.string(from: messageDate)
            let type = newMessage.kind.messageKindString
            let sender = currentEmail
            var message = ""
            switch newMessage.kind{
                
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString{
                    message = targetUrlString
                }
                break
            case .video(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString{
                    message = targetUrlString
                }
                break
            case .location(let locationData):
                let location = locationData.location
                message = "\(location.coordinate.longitude),\(location.coordinate.latitude)"
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else{
                completion(false)
                return
            }
            let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
            
            let newMessageEntry: [String: Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKindString,
                "content": message,
                "date": dateString,
                "time": timeString,
                "sender_email": currentUserEmail,
                "is_read": false,
                "name": name
            ]
            currentMessages.append(newMessageEntry)
            
            strongSelf.database.child("\(conversation)/messages").setValue(currentMessages, withCompletionBlock: {error, _ in
                guard error == nil else{
                    completion(false)
                    return
                }
                
                strongSelf.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value, with: {snapshot in
                    var databaseEntryConversations = [[String: Any]]()
                    let updatedValue: [String: Any] = [
                        "date":dateString,
                        "time":timeString,
                        "sender":sender,
                        "is_read": false,
                        "message": message,
                        "type": type
                    ]
                    if var currentUserConversations = snapshot.value as? [[String: Any]]{
                        ///We need to create conversation entry
                        
                        var targetConversation: [String: Any]?
                        
                        var position = 0
                        
                        for conversationDictionary in currentUserConversations {
                            if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                                targetConversation = conversationDictionary
                                break
                            }
                            position += 1
                        }
                        if var targetConversation = targetConversation {
                            targetConversation["latest_message"] = updatedValue
                            currentUserConversations[position] = targetConversation
                            databaseEntryConversations = currentUserConversations
                        }
                        else {
                            let newConversationData: [String: Any] = [
                                "id":conversation,
                                "other_user_email": DatabaseManager.safeEmail(emailAddress: otherUserEmail),
                                "name": name,
                                "latest_message": updatedValue
                            ]
                            currentUserConversations.append(newConversationData)
                            databaseEntryConversations = currentUserConversations
                        }
                    }
                    else {
                        let newConversationData: [String: Any] = [
                            "id":conversation,
                            "other_user_email": DatabaseManager.safeEmail(emailAddress: otherUserEmail),
                            "name": name,
                            "latest_message": updatedValue
                        ]
                        databaseEntryConversations = [
                            newConversationData
                        ]
                    }
                    
                    strongSelf.database.child("\(currentEmail)/conversations").setValue(databaseEntryConversations, withCompletionBlock: {error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        //Update latest message for receipient user
                        
                        
                        strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: {snapshot in
                            let updatedValue: [String: Any] = [
                                "date":dateString,
                                "time":timeString,
                                "sender":sender,
                                "is_read": false,
                                "message": message,
                                "type": type
                            ]
                            var databaseEntryConversations = [[String: Any]]()
                            
                            guard let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
                                return
                            }
                            if var otherUserConversations = snapshot.value as? [[String: Any]] {
                                var targetConversation: [String: Any]?
                                
                                var position = 0
                                
                                for conversationDictionary in otherUserConversations {
                                    if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                                        targetConversation = conversationDictionary
                                        break
                                    }
                                    position += 1
                                }
                                if var targetConversation = targetConversation {
                                    targetConversation["latest_message"] = updatedValue
                                    otherUserConversations[position] = targetConversation
                                    databaseEntryConversations =  otherUserConversations
                                }
                                else {
                                    ///Failed to find current collection
                                    let newConversationData: [String: Any] = [
                                        "id":conversation,
                                        "other_user_email": DatabaseManager.safeEmail(emailAddress: currentEmail),
                                        "name": currentName,
                                        "latest_message": updatedValue
                                    ]
                                    otherUserConversations.append(newConversationData)
                                    databaseEntryConversations = otherUserConversations
                                }
                            }
                            else {
                                ///Current collection does not exist
                                let newConversationData: [String: Any] = [
                                    "id":conversation,
                                    "other_user_email": DatabaseManager.safeEmail(emailAddress: currentEmail),
                                    "name": currentName,
                                    "latest_message": updatedValue
                                ]
                                databaseEntryConversations = [
                                    newConversationData
                                ]
                            }
                            
                            
                            strongSelf.database.child("\(otherUserEmail)/conversations").setValue(databaseEntryConversations, withCompletionBlock: {error, _ in
                                guard error == nil else {
                                    completion(false)
                                    return
                                }
                                completion(true)
                            })
                        })
                    })
                })
            })
        })
    }
    
    
    public func deleteConversation(conversationId : String, completion: @escaping (Bool) -> Void){
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        print("Deleting conversation with id : \(conversationId)")
        
        
        ///Get all conversations for current user
        ///Delete conversation in collection with target id
        ///Reset those conversation for the user in database
        let ref = database.child("\(safeEmail)/conversations")
        ref.observeSingleEvent(of: .value) {
            snapshot in
            if var conversations = snapshot.value as? [[String:Any]]{
                var positionToRemove = 0
                for conversation in conversations {
                    if let id = conversation["id"] as? String,
                       id == conversationId {
                        print("Found conversation to delete")
                        break
                    }
                    positionToRemove += 1
                }
                conversations.remove(at: positionToRemove)
                ref.setValue(conversations, withCompletionBlock: {error, _ in
                    guard error == nil else {
                        completion(false)
                        print("Failed to write new conversation array")
                        return
                    }
                    print("Deleted Conversation")
                    completion(true)
                })
            }
        }
    }
    public func conversationExists(with targetRecipientEmail: String, completion: @escaping (Result<String, Error>) -> Void ){
        let safeRecipientEmail = DatabaseManager.safeEmail(emailAddress: targetRecipientEmail)
        guard let senderEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeSenderEmail = DatabaseManager.safeEmail(emailAddress: senderEmail)
        
        database.child("\(safeRecipientEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
            guard let collection = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            ///Iterate and find conversation with target sender
            if let conversation = collection.first(where: {
                guard let targetSenderEmail = $0["other_user_email"] as? String else {
                    return false
                }
                return safeSenderEmail == targetSenderEmail
            })
            {
                ///Get ID
                guard let id = conversation["id"] as? String else{
                    completion(.failure(DatabaseError.failedToFetch))
                    return
                }
                completion(.success(id))
                return
            }
            completion(.failure(DatabaseError.failedToFetch))
        })
        
    }
    func markConversationAsRead(with conversationId: String) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        database.child("\(safeEmail)/conversations").observeSingleEvent(of: .value, with: { [weak self] snapshot in
            if var conversations = snapshot.value as? [[String: Any]] {
                for (index, conversation) in conversations.enumerated() {
                    if let id = conversation["id"] as? String, id == conversationId {
                        if let latestMessage = conversations[index]["latest_message"] as? [String: Any] {
                            var updatedLatestMessage = latestMessage
                            updatedLatestMessage["is_read"] = true
                            conversations[index]["latest_message"] = updatedLatestMessage
                        }
                        self?.database.child("\(safeEmail)/conversations/\(index)/latest_message/is_read").setValue(true)
                        return
                    }
                }
            }
        })
    }

}

struct ChatAppUser{
    let firstName: String
    let lastName: String
    let emailAddress: String
    var safeEmail: String{
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    var profilePictureFileName: String{
        return "\(safeEmail)_profile_picture.png"
    }
    var coverPictureFileName: String {
        return "\(safeEmail)_cover_photo.png"
    }
}

