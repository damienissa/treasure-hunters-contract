import "@stdlib/deploy";
import "@stdlib/ownable";
message BuyTicket {
}
message BuyTicketWithDiscount {
    referrer: Address;
}

message Withdraw {}

contract TreasureHunters with Deployable, Ownable {
    owner: Address;
    numberOfPlayers: Int as uint8;
    ticketPrice: Int as uint64;
    players: map<Int, Address>;
    playersLength: Int as uint8;
    playedAtLeastOnce: map<Address, Bool>;
    discountPercent: Int as uint8;
    gameInProgress: Bool;
    lastGameWinners: map<Address, Int>;
    
    init(){
        
        self.owner = context().sender;
        self.playedAtLeastOnce = emptyMap();
        self.numberOfPlayers = 20;
        self.ticketPrice = ton("10");
        self.players = emptyMap();
        self.playersLength = 0;
        self.discountPercent = 10;
        self.gameInProgress = true;
        self.lastGameWinners = emptyMap();
    }

    receive(msg: BuyTicket){
        let messageContext = context();
        if (messageContext.value < self.ticketPrice) {
            throw(37)
        }
         
        self.processTicket();
    }

    receive(msg: Withdraw) {
        self.requireOwner();
        send(SendParameters{to: self.owner, value: myBalance() - ton("1"), bounce: false});
    }
    
    get fun requestLastGameWinners(): map<Address, Int> {
        
        return self.lastGameWinners;
    }

    get fun contractBalance(): Int {
        
        return myBalance();
    }

    get fun numberOfCurrentPlayers(): Int {
        
        return self.playersLength;
    }

    get fun currentGame(): map<Int, Address> {
        
        return self.players;
    }

    fun processTicket() {
        let sender = context().sender;
        self.playedAtLeastOnce.set(sender, true);
        self.players.set(self.playersLength, sender);
        self.playersLength = self.playersLength + 1;

        if (self.playersLength >= self.numberOfPlayers) {
        
            self.lastGameWinners = self.getWinners();
            foreach (address, prize in self.lastGameWinners) {
                send(SendParameters{to: address, bounce: true, value: prize, mode: SendRemainingValue + SendIgnoreErrors});
            }
        
            self.players = emptyMap();
            self.playersLength = 0;
        }
    }
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