//
//  ProfileViewModel.swift
//  AppChat
//
//  Created by Trung on 05/06/2023.
//

enum ProfileViewModelType{
    case info, email, logout
}
struct ProfileViewModel {
    let viewModelType:ProfileViewModelType
    let title:String
    let handler: (() -> Void)?
}

