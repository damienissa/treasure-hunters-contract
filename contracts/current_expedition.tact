import "./config.tact";

struct CurrentExpedition {
    players: map<Int, Address>;
    playersLength: Int;
    expeditionStarted: Bool;
}

mutates extends fun addPlayer(self: CurrentExpedition, player: Address) {
    if (self.expeditionStarted) {
        require(!self.expeditionStarted, "Expedition is already started");
    }
    self.players.set(self.playersLength, player);
    self.playersLength += 1;
}


mutates extends fun startExpedition(self: CurrentExpedition, expeditionManager: ExpeditionManager, config: Config) {
    self.expeditionStarted = true;
    dump("Expedition started");
    let getWinners: ExpeditionResult = getWinners(config.treasurePercent, self.playersLength, self.players);
    dump("Winners selected");
    expeditionManager.addResult(getWinners);
    dump("Winners added to expedition manager");
    self.players = emptyMap();
    self.playersLength = 0;
    dump("Players reset");
}



struct Winner {
    treasure: Int;
    player: Address;
    claimed: Bool;
}

mutates extends fun claim(self: Winner) {
    require(!self.claimed, "Already claimed");
    self.claimed = true;
}

struct ExpeditionResult {
    winners: map<Int, Winner>;
}

struct ExpeditionManager {
    expeditions: map<Int, ExpeditionResult>;
    expeditionsLength: Int;
}

mutates extends fun addResult(self: ExpeditionManager, result: ExpeditionResult) {
    
    self.expeditions.set(self.expeditionsLength, result);
    self.expeditionsLength += 1;
}

fun selectRandomPlayers(count: Int, copyLength: Int, copyPlayers: map<Int, Address>): map<Int, Address> {
        
        let selectedPlayers: map<Int, Address> = emptyMap();
        let selectedCount: Int = 0;
        while (selectedCount < count) {
            let randomKey: Int = random(0, copyLength);
            if (copyPlayers.exists(randomKey)) {
                let address: Address = copyPlayers.get(randomKey)!!;
                selectedPlayers.set(selectedCount, address);
                selectedCount += 1;
                copyPlayers.del(randomKey);
                copyLength -= 1;
            }
        }
        return selectedPlayers;
}

fun getWinners(treasure: Int, copyLength: Int, copyPlayers: map<Int, Address>): ExpeditionResult {
        dump(myBalance());
        let winnerMap: map<Int, Winner> = emptyMap();
        dump(myBalance());
        let randomPlayers: map<Int, Address> = selectRandomPlayers(5, copyLength, copyPlayers);
        dump(myBalance());
        let prizes: map<Int, Int> = emptyMap();
        dump(myBalance());
        let currentIndex: Int = 0;
        dump(myBalance());
        prizes.set(0, (treasure * 50) / 100);
        prizes.set(1, (treasure * 30) / 100);
        prizes.set(2, (treasure * 10) / 100);
        prizes.set(3, (treasure * 7) / 100);
        prizes.set(4, (treasure * 3) / 100);
        dump(myBalance());

        foreach (key, value in randomPlayers) {
            let winner: Winner = Winner{treasure: prizes.get(currentIndex)!!, player: value, claimed: false};
            winnerMap.set(currentIndex, winner);
            currentIndex += 1;
        }
        dump(myBalance());
        return ExpeditionResult{winners: winnerMap};    
    }