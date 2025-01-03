struct CurrentExpedition {
    players: map<Int, Address>;
    playersLength: Int;
}

mutates extends fun addPlayer(self: CurrentExpedition, player: Address) {
    self.players.set(self.playersLength, player);
    self.playersLength += 1;
}
