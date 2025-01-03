struct ExpeditionState {
    code: Int; // 0 - not started, 1 - in progress, 2 - finished
}
message AddPlayerInternal {
    player: Address;
}
message WinnerList {
    firstPlace: Address; // 50%
    secondPlace: Address; // 30%
    thirdPlace: Address; // 10%
    fourthPlace: Address; // 7%
    fifthPlace: Address; // 3%
}
message BuyTicket {
}
message Withdraw {
}