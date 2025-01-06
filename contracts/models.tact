struct Winner {
    treasure: Int;
    player: Address;
    claimed: Bool;
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
mutates extends fun claim(self: Winner) {
    require(!self.claimed, "Already claimed");
    self.claimed = true;
}