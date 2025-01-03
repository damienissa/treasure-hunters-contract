import "@stdlib/deploy";
import "@stdlib/ownable";
import "./models.tact";
import "./expedition.tact";

contract TreasureHuntersV2 with Deployable, Ownable {
    owner: Address;
    maxNumberOfPlayers: Int as uint8;
    currentExpeditionId: Int;
    ticketPrice: Int as coins;
    treasurePercent: Int as uint8;
    playedAtLeastOnce: map<Address, Bool>;
    init(maxNumberOfPlayers: Int, ticketPrice: Int, treasurePercent: Int){
        self.owner = context().sender;
        self.maxNumberOfPlayers = maxNumberOfPlayers;
        self.currentExpeditionId = 0;
        self.ticketPrice = ticketPrice;
        self.treasurePercent = treasurePercent;
        self.playedAtLeastOnce = emptyMap();
    }

    receive(msg: Withdraw){
        self.requireOwner();
        send(SendParameters{to: self.owner, value: myBalance() - ton("1"), bounce: false});
    }

    receive(msg: BuyTicket){
        require(context().value >= self.ticketPrice, "Not enough funds");
        dump(self.currentExpeditionId);
        self.playedAtLeastOnce.set(context().sender, true);
        let expeditionInit = self.intiOfExpedition();
        self.forward(self.currentExpeditionAddress(),
            AddPlayerInternal{player: context().sender}.toCell(),
            false,
            expeditionInit
        );
    }

    receive(msg: WinnerList){
        dump("Winners is selected");
        require(context().sender == self.currentExpeditionAddress(),
            "This method can only be called by the current expedition"
        );
        self.currentExpeditionId += 1;
        dump("Send the prize to the winners");
        dump(self.currentExpeditionId);
        // Send the prize to the winners
        send(SendParameters{to: msg.firstPlace, value: (self.treasure() * 50) / 100});
        send(SendParameters{to: msg.secondPlace, value: (self.treasure() * 30) / 100});
        send(SendParameters{to: msg.thirdPlace, value: (self.treasure() * 10) / 100});
        send(SendParameters{to: msg.fourthPlace, value: (self.treasure() * 7) / 100});
        send(SendParameters{to: msg.fifthPlace, value: (self.treasure() * 3) / 100});
    }

    get fun currentExpeditionAddress(): Address {
        return self.expeditionAddress();
    }

    get fun currentExpeditionNumber(): Int {
        return self.currentExpeditionId;
    }

    fun intiOfExpedition(): StateInit {
        return initOf Expedition(self.currentExpeditionId, self.maxNumberOfPlayers);
    }

    fun expeditionAddress(): Address {
        return contractAddress(self.intiOfExpedition());
    }

    fun treasure(): Int {
        return ((self.maxNumberOfPlayers * self.ticketPrice) * self.treasurePercent) / 100; // 70 % of the total amount goes to the winners
    }
}