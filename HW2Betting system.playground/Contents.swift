import Foundation


//MARK:- Enums
enum Role {
  case admin
  case regularUser
}

enum State {
  case authorised
  case unaunthorised
  case banned
  case undefined
}

//MARK:- Structs

struct SystemStorage {
  
  var users: [String: User] = [:]
  var bets: [Bet] = []
  
  func isUniqueUsername(_ username: String) -> Bool {
    users[username] != nil ? false : true
  }
  
  func checkUsernameAndPassword(_ username: String, _ password: String) -> Bool {
    guard let user = users[username] else { print("Could not check username and password. Unknown user"); return false }
    return user.password == password ? true : false
  }
  
  func checkUserStatus(_ user: User) -> State {
    guard let user = users[user.username] else { print("Could not check user status. Unknown user"); return .undefined }
    return user.state
  }
  
  func findUser(_ username: String) -> User? {
    guard let user = users[username] else {return nil}
    return user
  }

  func showUserBets(user: User) {
    for bet in bets {
      if bet.user.username == user.username {
        print(bet.betDescription, bet.user.username)
      }
    }
  }
  
  mutating func addUser(_ user: User) {
    self.users[user.username] = user
  }
  
  
  mutating func changeUserStatus(username: String, state: State) {
    guard let user = users[username] else { print("Unknown user"); return }
    user.state = state
  }

  mutating func addBet(_ bet: Bet) {
    bets.append(bet)
  }
  
}

//MARK:- Structs

struct Bet {
  let user: User
  let betDescription: String
}

//MARK:- Class

class User{

  let role: Role
  
  
  var username: String
  var password: String
  var state: State = .unaunthorised
  var bets: [Bet] = []
  
  init(username: String, password: String, role: Role) {
    self.username = username
    self.password = password
    self.role = role
    
  }
  
  func placeBet(desription: String) -> Bet? {
    if state == .authorised {
      let newBet = Bet(user: self, betDescription: desription)
      bets.append(newBet)
      return newBet
    }
    print("You need to authorize before place bet")
    return nil
  }
  
  func showMyBets() {
    if state == .authorised {
      for bet in bets {
        print("User: \(bet.user.username) placed bet: \(bet.betDescription)")
      }
    } else {
      print("Could not show bets. Please authorize.")
    }
    
  }
  
}

class BettingSystem {
  
  static let shared = BettingSystem()
  
  var storage = SystemStorage()
  
  var currentUser: User?
  var currentAdmin: User?
  
  
  func createUser(username: String, password: String, role: Role) -> User? {
    
    if storage.isUniqueUsername(username) {
      let newUser = User(username: username, password: password, role: role)
      storage.addUser(newUser)
      print("Successful created \(role) – \(username) ")
      return newUser
      
    } else {
      print("User \(username) has already exist.")
      return nil
      
    }
    
  }
  
  
  func login(username: String, password: String) {
    
    
    guard let user = storage.findUser(username) else {return}
    
    switch storage.checkUserStatus(user) {
    case .authorised:
      print("Sorry, but you couldn`t authorise twice.")
    case .unaunthorised:
      if storage.checkUsernameAndPassword(username, password) {
        storage.changeUserStatus(username: username, state: .authorised)
        if user.role == .admin {
          currentAdmin?.state = .unaunthorised
          currentAdmin = user
        } else {
          currentUser?.state = .unaunthorised
          currentUser = user
        }
        print("\(username) successful log in into a system")
      } else {
        print("Wrong password. Try again")
      }
    case .banned:
      print("You account has been banned.")
    case .undefined:
      print("This user does not exist.")
      
    }
    
  }
  
  
  func logout(username: String) {
    
    guard let user = storage.findUser(username) else {return}
    
    if storage.checkUserStatus(user) == .authorised {
      storage.changeUserStatus(username: username, state: .unaunthorised)
      user.role == .admin ? (currentAdmin = nil) : (currentUser = nil)
      print("\(username) successful log out from system")
    } else {
      print("You have already log out from system")
    }
  }
  
  
  func takeBetFromUser(_ bet: Bet) {
    
    guard let user = storage.findUser(bet.user.username) else {print("Undefined user"); return}
    if user.state == .authorised {
      storage.addBet(bet)
      print("Bet successful added.")
    } else {
      print("You could not place a bet")
    }
  }
  
  
  func ban(user: User, by admin: User) {
    if admin.state == .authorised && admin.role == .admin {
      guard let user = storage.users[user.username] else {return}
      user.state = .banned
      print("User \(user.username) banned by admin \(admin.username)")
      
    } else {
      print("Could not ban user. Authorization required")
    }
  }
  
  func showUsers(by admin: User) {
    if admin.state == .authorised && admin.role == .admin {
      
      print("Users: ")
      for user in storage.users {
        if user.value.role == .regularUser {
          print(user.key)
        }
      }
      
    } else {
      print("Could not show users! Authorization required")
    }
  }
  
}


//MARK:- ===========SYSTEM===============


let bettingSystem = BettingSystem.shared

let admin = bettingSystem.createUser(username: "Admin", password: "Admin", role: .admin)

let vasya = bettingSystem.createUser(username: "vasya", password: "123", role: .regularUser)
let dima = bettingSystem.createUser(username: "dima", password: "123", role: .regularUser)
let anotherDima = bettingSystem.createUser(username: "dima", password: "123", role: .regularUser)


bettingSystem.storage.checkUserStatus(admin!)
bettingSystem.login(username: "Admin", password: "Admin")
bettingSystem.storage.checkUserStatus(admin!)

bettingSystem.login(username: "vasya", password: "2")
bettingSystem.login(username: "vasya", password: "123")
bettingSystem.storage.checkUserStatus(vasya!)
bettingSystem.storage.checkUserStatus(admin!)

let betFromVasya = vasya?.placeBet(desription: "To NaVi 3:0")
bettingSystem.takeBetFromUser(betFromVasya!)
bettingSystem.currentUser?.showMyBets()

let betFromDima = dima?.placeBet(desription: "To Astralis 3:6")

bettingSystem.showUsers(by: admin!)
bettingSystem.logout(username: "Admin")
bettingSystem.storage.checkUserStatus(admin!)
bettingSystem.showUsers(by: admin!)
bettingSystem.ban(user: dima!, by: admin!)

bettingSystem.login(username: "Admin", password: "Admin")
bettingSystem.ban(user: dima!, by: admin!)

bettingSystem.storage.checkUserStatus(dima!)
bettingSystem.login(username: "dima", password: "123")



