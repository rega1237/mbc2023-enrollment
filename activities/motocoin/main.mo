import AccountImport "account";
import TrieMap "mo:base/TrieMap";
import Result "mo:base/Result";
import Principal "mo:base/Principal";

/** TODO
  1. Define a variable called ledger, which is a TrieMap. In this datastructure, the keys are of
  type Account and the values are of type Nat and represent the balance of each account. You can use
  the helper functions in account.mo to help you.

  2.Implement name which returns the name of the token as a Text. The name of the token is MotoCoin.

  3. Implement symbol which returns the symbol of the token as a Text. The symbol of the token is MOC.

  4. Implement totalSupply which returns the total number of MOC token in circulation.

  5. Implement balanceOf which takes an account and returns the balance of this account. If the
  account has never interacted with the ledger before, you will return 0.

  6. Implement transfer that accepts three parameters: an Account object for the sender (from), an
  Account object for the recipient (to), and a Nat value for the amount to be transferred. This function should
  transfer the specified amount of tokens from the sender's account to the recipient's account. This
  function should return an error message wrapped in an Err result if the caller has not enough token
  in it's main account.

  7. Implement airdrop which adds 100 MotoCoin to the main account of all students participating in
  the Bootcamp.
**/

actor MotoCoin {
  type Account = AccountImport.Account;
  type SubAccount = AccountImport.Subaccount;

  let map = TrieMap.TrieMap<Account, Nat>(AccountImport.accountsEqual, AccountImport.accountsHash);

  var totalSupplyCoins : Nat = 1000000;

  let portalCanister = actor("rww3b-zqaaa-aaaam-abioa-cai") : actor {
    getAllStudentsPrincipal : shared () -> async [Principal];
  };

  public query func name() : async Text {
    return "MotoCoin";
  };

  public query func symbol() : async Text {
    return "MOC";
  };

  public query func totalSupply() : async Nat {
    return totalSupplyCoins;
  };

  public query func balanceOf(account : Account) : async Nat {

    let balance : ?Nat = map.get(account);

    switch(balance) {
      case(null) { 0 };
      case(?balance) { balance };
    };
  };

  public func transfer(from : Account, to : Account, amount : Nat) : async Result.Result<(), Text> {

    let senderBalance : ?Nat = map.get(from);
    let recipierBalance : ?Nat = map.get(to);

    switch(senderBalance) {
      case(null) { return #err("Sender does not exist") };
      case(?senderBalance) {
        switch(recipierBalance) {
          case(null) { return #err("Recipier does not exist") };
          case(?recipierBalance) {
            if(senderBalance < amount) {
              return #err("Sender does not have enough balance");
            } else {
              map.put(from, senderBalance - amount);
              map.put(to, recipierBalance + amount);
              return #ok(());
            };
          };
        };
      };
    };
  };

  func createStudentsAccounts(students : [Principal]) : () {
    for(student in students.vals()) {
      let studentAccount : Account = {
          owner = student;
          subaccount = null;
      };

      let accountExist : ?Nat = map.get(studentAccount);

      switch(accountExist) {
        case(null) {
          map.put(studentAccount, 100);
          totalSupplyCoins := totalSupplyCoins - 100;
        };
        case(?balance) {
          map.put(studentAccount, balance + 100);
          totalSupplyCoins := totalSupplyCoins - 100;
        };
      };
    };

    return ();
  };

  public func airdrop() : async Result.Result<(), Text>{
    let students : [Principal] = await portalCanister.getAllStudentsPrincipal();

    if(totalSupplyCoins < students.size()) {
      return #err("Not enough tokens to send to all students");
    } else {
      createStudentsAccounts(students);
      return #ok(());
    };
  }
}
