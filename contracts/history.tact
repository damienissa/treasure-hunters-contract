struct ExpeditionHistory {
    winners: map<Int, Address>;
    losers: map<Int, Address>;
}
struct HistoricalData {
    playedAtLeastOnce: map<Address, Bool>;
    expeditionLogLength: Int;
    expeditionLog: map<Int, ExpeditionHistory>;
}

mutates extends fun savePlayerPlayedAtLeastOnce(self: HistoricalData, sender: Address) {
    self.playedAtLeastOnce.set(sender, true);
}

mutates extends fun saveToHistory(self: HistoricalData, winners: map<Int, Address>, losers: map<Int, Address>,) {
    self.expeditionLog.set(self.expeditionLogLength, ExpeditionHistory{winners: winners, losers: losers});
    self.expeditionLogLength += 1; 
}

