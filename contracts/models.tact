struct Winner {
    treasure: Int;
    player: Address;
}
message AddMemberInternal {
    member: Address;
}
message ExpeditionResultInternal {
    address: Address;
    winners: map<Int, Winner>;
}
message BuyTicket {
    referrer: Address?;
}
message Claim {
}
struct ExpeditionResult {
    address: Address;
    winners: map<Int, Winner>;
}
message Withdraw {
}