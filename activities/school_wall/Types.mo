import Principal "mo:base/Principal";

module {
  public type Content = {
    #Text: Text;
    #Image: Blob;
    #Video: Blob;
  };

  public type Message = {
    vote: Int;
    content: Content;
    creator: Principal;
  };
};
