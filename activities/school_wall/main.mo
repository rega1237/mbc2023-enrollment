import Nat "mo:base/Nat";
import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Result "mo:base/Result";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";
import Order "mo:base/Order";

import Type "Types";

actor studentWalll {
  type HashMap<K, V> = HashMap.HashMap<K, V>;
  type Message = Type.Message;
  type Content = Type.Content;

  var messageId : Nat = 0;

  let wall : HashMap<Nat, Message> = HashMap.HashMap(1, Nat.equal, Hash.hash);

  public shared ({ caller = creator }) func writeMessage (c : Content) : async Nat {
    let id : Nat = messageId;
    messageId += 1;

    let message : Message = {
      vote = 0;
      content = c;
      creator = creator;
    };

    wall.put(id, message);

    return id;
  };

  public query func getMessage(id : Nat) : async Result.Result<Message, Text> {
    let message : ?Message = wall.get(id);

    switch(message) {
      case(null) { #err "Message not found"; };
      case(?message) { #ok message; };
    };
  };

  public shared ({ caller = user }) func updateMessage(messageId: Nat, c: Content) : async Result.Result<(), Text> {
    let message : ?Message = wall.get(messageId);

    switch(message) {
      case(null) { #err "Message not found"; };
      case(?message) {
        if (message.creator == user) {
          let newMessage : Message = {
            vote = message.vote;
            content = c;
            creator = message.creator;
          };

          wall.put(messageId, newMessage);

          #ok ();
        } else {
          #err "User is not the creator of the message";
        }
      }
    }
  };

  public func deleteMessage(messageId : Nat) : async Result.Result<(), Text> {
    let message : ?Message = wall.get(messageId);

    switch(message) {
      case(null) { #err "Message not found"; };
      case(?message) {
          ignore wall.remove(messageId);
          #ok ();
       };
    };
  };

  public func upVote(messageId : Nat) : async Result.Result<(), Text> {
    let message : ?Message = wall.get(messageId);

    switch(message) {
      case(null) { #err "Message not found"; };
      case(?message) {
        let newMessage : Message = {
          vote = message.vote + 1;
          content = message.content;
          creator = message.creator;
        };

        wall.put(messageId, newMessage);

        #ok ();
      };
    };
  };

  public func downVote(messageId : Nat) : async Result.Result<(), Text> {
    let message : ?Message = wall.get(messageId);

    switch(message) {
      case(null) { #err "Message not found"; };
      case(?message) {
        let newMessage : Message = {
          vote = message.vote - 1;
          content = message.content;
          creator = message.creator;
        };

        wall.put(messageId, newMessage);

        #ok ();
      };
    };
  };

  public query func getAllMessages() : async [Message] {
    let bufferMessages = Buffer.Buffer<Message>(1);

    for (message in wall.vals()) {
      bufferMessages.add(message);
    };

    return bufferMessages.toArray();
  };

  public query func getAllMessagesRanked() : async [Message] {
    let bufferMessages = Buffer.Buffer<Message>(1);

    for (message in wall.vals()) {
      bufferMessages.add(message);
    };

    let messageArray = bufferMessages.toArray();

    return Array.sort<Message>(messageArray, sortMessages)
  };

  private func sortMessages(message1 : Message , message2 : Message) :  Order.Order {
    if (message1.vote > message2.vote) {
      return #less;
    } else if (message1.vote < message2.vote) {
      return #greater;
    } else {
      return #equal;
    };
  };
}
