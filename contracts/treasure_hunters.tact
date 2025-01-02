import "@stdlib/deploy";
import "@stdlib/ownable";
message BuyTicket {
}

contract TreasureHunters with Deployable, Ownable {
    owner: Address;
    numberOfPlayers: Int as uint8;
    ticketPrice: Int as uint8;
    players: map<Int, Address>;
    playersLength: Int as uint8;
    playedAtLeastOnce: map<Address, Bool>;
    init(owner: Address){
        self.owner = owner;
        self.playedAtLeastOnce = emptyMap();
        self.numberOfPlayers = 20;
        self.ticketPrice = ton("10");
        self.players = emptyMap();
        self.playersLength = 0;
    }

    receive(msg: BuyTicket){
        let sender = context().sender;
        self.playedAtLeastOnce.set(sender, true);
        dump("Player bought a ticket");
        // Ensure playersLength is updated correctly
        self.players.set(self.playersLength, sender);
        self.playersLength = self.playersLength + 1;
        dump("Players length after adding a ticket:");
        dump(self.playersLength);
        if (self.isExpeditionFull()) {
            dump("Expedition is full");
            let winners = self.getWinners();
            foreach (address, prize in winners) {
                send(SendParameters{
                        to: address,
                        bounce: true,
                        value: prize,
                        mode: SendRemainingValue + SendIgnoreErrors
                    }
                );
            }
            self.createNewGame();
        }
    }
}

extends fun createNewGame(self: TreasureHunters) {
    self.players = emptyMap();
    self.playersLength = 0;
}

extends fun isExpeditionFull(self: TreasureHunters): Bool {
    return self.playersLength >= self.numberOfPlayers;
}

extends fun getWinners(self: TreasureHunters): map<Address, Int> {
    let winnerMap: map<Address, Int> = emptyMap();
    let randomPlayers: map<Int, Address> = self.selectRandomPlayers(5);
    let prizes: map<Int, Int> = emptyMap();
    let currentIndex: Int = 0;
    prizes.set(0, (self.treasure() * 50) / 100);
    prizes.set(1, (self.treasure() * 30) / 100);
    prizes.set(2, (self.treasure() * 10) / 100);
    prizes.set(3, (self.treasure() * 7) / 100);
    prizes.set(4, (self.treasure() * 3) / 100);
    foreach (key, value in randomPlayers) {
        winnerMap.set(value, prizes.get(currentIndex)!!);
        currentIndex += 1;
    }
    return winnerMap;
}

extends fun treasure(self: TreasureHunters): Int {
    return ((self.numberOfPlayers * self.ticketPrice) * 70) / 100; // 70 % of the total amount goes to the winners
}

extends fun selectRandomPlayers(self: TreasureHunters, count: Int): map<Int, Address> {
    let selectedPlayers: map<Int, Address> = emptyMap();
    let selectedCount: Int = 0;
    while (selectedCount < count) {
        let randomKey: Int = random(0, self.playersLength);
        if (self.players.exists(randomKey)) {
            let address: Address = self.players.get(randomKey)!!;
            selectedPlayers.set(selectedCount, address);
            selectedCount += 1;
            self.players.del(randomKey);
            self.playersLength -= 1;
        }
    }
    return selectedPlayers;
}