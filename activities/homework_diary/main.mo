import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import Text "mo:base/Text";

import Type "Types";

actor {

  type Homework = Type.Homework;

  var homeworkDiary = Buffer.Buffer<Homework>(3);

  public func addHomework(homework : Homework) : async Nat  {
    homeworkDiary.add(homework);
    return homeworkDiary.size() - 1;
  };

  public query func getHomework(id : Nat) : async Result.Result<Homework, Text> {
    if (id >= homeworkDiary.size()) {
      #err "Homework not found";
    } else {
      let homework = homeworkDiary.get(id);
      #ok homework;
    }
  };

  public func updateHomework(id : Nat, homework : Homework) : async Result.Result<(), Text> {
    if (id >= homeworkDiary.size()) {
      #err "Homework not found";
    } else {
      var arrayBuffer = Buffer.toVarArray(homeworkDiary);
      arrayBuffer[id] := homework;
      homeworkDiary := Buffer.fromVarArray(arrayBuffer);
      #ok ();
    }
  };

  public func markAsCompleted(id : Nat) : async Result.Result<(), Text> {
    if (id >= homeworkDiary.size()) {
      #err "Homework not found";
    } else {
      var arrayBuffer = Buffer.toVarArray(homeworkDiary);
      arrayBuffer[id] := {
        title = arrayBuffer[id].title;
        description = arrayBuffer[id].description;
        completed = true;
        dueDate = arrayBuffer[id].dueDate;
      };
      homeworkDiary := Buffer.fromVarArray(arrayBuffer);
      #ok ();
    }
  };

  public func deleteHomework(id : Nat) : async Result.Result<(), Text> {

    if (id >= homeworkDiary.size()) {
      #err "Homework not found";
    } else {
      let removedHomework = homeworkDiary.remove(id);
      #ok ();
    }
  };

  public query func getAllHomework() : async [Homework] {
    return Buffer.toArray(homeworkDiary);
  };

  private func incompleted(homework : Homework) : Bool {
    if (homework.completed) {
      return false;
    } else {
      return true;
    }
  };

  public query func getPendingHomework() : async [Homework] {
    let array = Buffer.toArray(homeworkDiary);
    return Array.filter(array, incompleted);
  };

 /** private func searchFilter(homework : Homework) : async Bool {
    let description = homework.description;
    if (Text.contains(description, #text searchTerm)) {
      return true;
    } else {
      return false;
    }
  };
**/

  public query func searchHomework(searchTerm : Text) : async [Homework] {
    let array = Buffer.toArray(homeworkDiary);
    return Array.filter<Homework>(array, func(x : Homework)  {Text.contains(x.description, #text searchTerm)});
  };
}
