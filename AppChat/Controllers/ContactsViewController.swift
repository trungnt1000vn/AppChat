//
//  ContactsViewController.swift
//  AppChat
//
//  Created by Trung on 09/06/2023.
//

import UIKit

class ContactsViewController: UIViewController{
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var tableView: UITableView!
    
    private var contacts = [Conversation]()
    
    private var filteredContacts = [Conversation]()
    
    private var isSearching = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.placeholder = "Search Contacts By Name"
        tableView.register(ContactCell.self, forCellReuseIdentifier: ContactCell.identifier)
        setUpTable()
        startListenForContactsChange()
        searchBar.delegate = self
    }
    
    
    private func setUpTable(){
        tableView.delegate = self
        tableView.dataSource = self
    }
    private func startListenForContactsChange(){
        guard let email = UserDefaults.standard.value(forKey: "email") as? String
        else {return}
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        DatabaseManager.shared.getAllConverssations(for: safeEmail, completion: {
            [weak self] result in
            switch result{
            case .success(let contacts):
                print("Get contact success !")
                guard !contacts.isEmpty else {
                    return
                }
                self?.contacts = contacts.sorted{ $0.name < $1.name }
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                print("Failed to load contact from Firebase")
            }
        })
    }
}
extension ContactsViewController : UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching {
            return filteredContacts.count
        }
        else {
            return contacts.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model: Conversation
        if isSearching {
            model = filteredContacts[indexPath.row]
        }
        else {
            model = contacts[indexPath.row]
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: ContactCell.identifier, for: indexPath) as! ContactCell
        cell.configure(with: model)
        return cell
    }
    func openConversation(_ model :Conversation){
        let vc = ChatViewController(with: model.otherUserEmail, id: model.id)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var model = contacts[indexPath.row]
        openConversation(model)
    }
    
}
extension ContactsViewController : UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredContacts = contacts.filter({ $0.name.lowercased().contains(searchText.lowercased())})
        isSearching = !searchText.isEmpty
        tableView.reloadData()
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            searchBar.text = ""
            filteredContacts.removeAll()
            isSearching = false
            tableView.reloadData()
          
        }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
