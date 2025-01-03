import "@stdlib/deploy";
import "@stdlib/ownable";
import "./history.tact";
import "./config.tact";
import "./messages.tact";
import "./current_expedition.tact";

contract TreasureHunters with Deployable, Ownable {
    owner: Address;
    config: Config;
    currentExpedition: CurrentExpedition;
    historicalData: HistoricalData;
    init(config: Config){
        self.owner = context().sender;
        self.historicalData = HistoricalData{
            playedAtLeastOnce: emptyMap(),
            expeditionLog: emptyMap(),
            expeditionLogLength: 0
        };
        self.config = config;
        self.currentExpedition = CurrentExpedition{players: emptyMap(), playersLength: 0};
    }

    receive(msg: BuyFirstTicketAfterReferral){
        let messageContext = context();
        require(self.currentExpedition.playersLength < self.config.numberOfPlayers, "Expedition is full");
        require(messageContext.value >= self.config.discountTicketPrice, "Not enough funds");
        let referrer = msg.referrer;
        let referrerBonus = (self.config.ticketPrice * self.config.referrerBonusPercent) / 100;
        send(SendParameters{to: referrer, value: referrerBonus, bounce: true, body: "Referral bonus".asComment()});
        self.processTicket();
    }

    receive(msg: BuyTicket){
        let messageContext = context();
        require(self.currentExpedition.playersLength < self.config.numberOfPlayers, "Expedition is full");
        require(messageContext.value >= self.config.ticketPrice, "Not enough funds");
        self.processTicket();
    }

    receive(msg: Withdraw){
        self.requireOwner();
        send(SendParameters{to: self.owner, value: myBalance() - ton("1"), bounce: false});
    }

    get fun expeditionLog(): map<Int, ExpeditionHistory> {
        return self.historicalData.expeditionLog;
    }

    get fun contractBalance(): Int {
        return myBalance();
    }

    get fun numberOfCurrentPlayers(): Int {
        return self.currentExpedition.playersLength;
    }

    fun processTicket() {
        let sender = context().sender;
        self.historicalData.savePlayerPlayedAtLeastOnce(sender);
        self.currentExpedition.addPlayer(sender);
        if (self.currentExpedition.playersLength == self.config.numberOfPlayers) {
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
            self.currentExpedition = CurrentExpedition{players: emptyMap(), playersLength: 0};
        }
    }

    fun selectRandomPlayers(count: Int): map<Int, Address> {
        let copyLength: Int = self.currentExpedition.playersLength;
        let copyPlayers: map<Int, Address> = self.currentExpedition.players;
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
        self.historicalData.saveToHistory(selectedPlayers, copyPlayers);
        return selectedPlayers;
    }

    fun getWinners(): map<Address, Int> {
        let winnerMap: map<Address, Int> = emptyMap();
        let randomPlayers: map<Int, Address> = self.selectRandomPlayers(5);
        let prizes: map<Int, Int> = emptyMap();
        let currentIndex: Int = 0;
        let treasure = self.config.treasure();
        prizes.set(0, (treasure * 50) / 100);
        prizes.set(1, (treasure * 30) / 100);
        prizes.set(2, (treasure * 10) / 100);
        prizes.set(3, (treasure * 7) / 100);
        prizes.set(4, (treasure * 3) / 100);
        foreach (key, value in randomPlayers) {
            winnerMap.set(value, prizes.get(currentIndex)!!);
            currentIndex += 1;
        }
        return winnerMap;
    }
}