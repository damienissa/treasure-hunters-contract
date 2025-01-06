struct Winner {
    treasure: Int;
    player: Address;
}
message AddMemberInternal {
    member: Address;
}
message ExpeditionResultInternal {
    winners: map<Int, Winner>;
}
message BuyTicket {
    referrer: Address?;
}
message Claim {
}
struct ExpeditionResult {
    winners: map<Int, Winner>;
}
message Withdraw {
}