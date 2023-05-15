import Type "Types";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import IC "Ic";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Error "mo:base/Error";
import Array "mo:base/Array";

actor verifier {
  type HashMap<K, V> = HashMap.HashMap<K, V>;
  type StudentProfile = Type.StudentProfile;

  let studentProfileStore : HashMap<Principal, StudentProfile> = HashMap.HashMap<Principal, StudentProfile>(1, Principal.equal, Principal.hash);

  public shared ({caller}) func addMyProfile(profile : StudentProfile) : async () {
    studentProfileStore.put(caller, profile);
  };

  public query ({caller}) func seeAProfile(p : Principal) : async Result.Result<StudentProfile, Text> {
    let profile : ?StudentProfile = studentProfileStore.get(p);

    switch(profile) {
      case(null) { #err "No profile found for this principal" };
      case(?profile) { #ok profile };
    };
  };

  public shared ({caller}) func updateMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
    let oldProfile : ?StudentProfile = studentProfileStore.get(caller);

    switch(oldProfile) {
      case(null) { #err "No profile found for this principal" };
      case(?oldProfile) {
        studentProfileStore.put(caller, profile);
        #ok ();
      };
    };
  };

  public shared ({caller}) func deleteMyProfile() : async Result.Result<(), Text> {
    let oldProfile : ?StudentProfile = studentProfileStore.get(caller);

    switch(oldProfile) {
      case(null) { #err "No profile found for this principal" };
      case(?oldProfile) {
        studentProfileStore.delete(caller);
        #ok ();
      };
    };
  };

  public type TestResult = Type.TestResult;
  public type TestError = Type.TestError;

  public func test(canisterId : Principal) : async TestResult {

    let calculatorInterface = actor (Principal.toText(canisterId)) : actor {
      reset : shared () -> async Int;
      add : shared (x : Nat) -> async Int;
      sub : shared (x : Nat) -> async Int;
    };

    try {
      let reset = await calculatorInterface.reset();

      if (reset != 0) {
        return #err(#UnexpectedValue("Reset failed"));
      };

      let add = await calculatorInterface.add(1);

      if (add != 1) {
        return #err(#UnexpectedValue("Add failed"));
      };

      let sub = await calculatorInterface.sub(1);

      if (sub != 0) {
        return #err(#UnexpectedValue("Sub failed"));
      };

      return #ok ();
    } catch (err) {
      #err(#UnexpectedError("Unexpected error"));
    };
  };

  type CanisterId = IC.CanisterId;
  type CanisterSettings = IC.CanisterSettings;
  type ManagementCanister = IC.ManagementCanister;

  private func parseControllersFromCanisterStatusErrorIfCallerNotController(errorMessage : Text) : [Principal] {
    let lines = Iter.toArray(Text.split(errorMessage, #text("\n")));
    let words = Iter.toArray(Text.split(lines[1], #text(" ")));
    var i = 2;
    let controllers = Buffer.Buffer<Principal>(0);
    while (i < words.size()) {
      controllers.add(Principal.fromText(words[i]));
      i += 1;
    };
    Buffer.toArray<Principal>(controllers);
  };

  public func verifyOwnership(canisterId: Principal, principalId: Principal): async Bool{

    let managerCanister: ManagementCanister = actor("aaaaa-aa");

    try{
      let status = await managerCanister.canister_status({canister_id = canisterId});
      let settings: CanisterSettings = status.settings;
      let controllers: [Principal] = settings.controllers;
      return true;
    }
    catch(e){
      let messageError = Error.message(e);
      let controllers2 = parseControllersFromCanisterStatusErrorIfCallerNotController(messageError);

      switch(Array.find<Principal>(controllers2, func x = x == principalId)) {
        case(null) {false  };
        case(control) {true};
      };
    };
  };

  public func verifyWork(canisterId: Principal, principalId: Principal) : async Result.Result<(), Text> {
    let isOwnerOfCanister: Bool = await verifyOwnership(canisterId, principalId);
    switch(isOwnerOfCanister) {
      case(false) {#err("you are not the owner of this canister")  };
      case(true ) {
        let isAproved=  await test(canisterId);
        switch(isAproved) {
          case(#err(Error)) {#err("feature not verified")  };
          case(#ok()) {
            let profileToModify: ?StudentProfile = studentProfileStore.get(principalId);
            switch(profileToModify) {
              case(null) {#err("submitted principal id not registered in the school")  };
              case(?profile) {
                let newProfile: StudentProfile = {
                  name = profile.name;
                  team = profile.team;
                  graduate = true;
                };
                studentProfileStore.put(principalId, newProfile);
                #ok();
              };
            };
          };
        };
      };
    }
  }
};
