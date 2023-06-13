//
//  ConversationsModel.swift
//  AppChat
//
//  Created by Trung on 05/06/2023.
//

struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    var latestMessage: LatestMessage
}

struct LatestMessage{
    var date: String
    var time: String
    var sender:String
    var text: String
    var isRead: Bool
    var type: String
}

