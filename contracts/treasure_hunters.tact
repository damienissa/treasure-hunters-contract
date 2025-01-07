import "@stdlib/deploy";
import "@stdlib/ownable";
import "./config.tact";
import "./models.tact";
import "./expedition.tact";

contract TreasureHunters with Deployable, Ownable {
    // Constants
    const minTonsForStorage: Int = ton("0.5");
    const gasConsumption: Int = ton("0.01");
    // Variables
    owner: Address;
    config: Config;
    currentExpedition: Address?;
    currentExpeditionLength: Int;
    expeditionResultsLength: Int;
    expeditionResults: map<Int, ExpeditionResult>;
    toBeClaimed: map<Address, Int>; // Address -> to treasury
    referralBonus: map<Address, Int>; // Address -> to treasury
    oncePlayed: map<Address, Bool>;
    // Lifecycle
    init(config: Config){
        self.owner = context().sender;
        self.config = config;
        self.currentExpeditionLength = 0;
        self.expeditionResultsLength = 0;
        self.expeditionResults = emptyMap();
        self.referralBonus = emptyMap();
        self.oncePlayed = emptyMap();
    }

    /// Add initial balance of contract
    receive(){
        self.requireOwner();

    }

    // Listeners
    receive(msg: Withdraw){
        self.requireOwner();
        let toBeWithdrawn: Int = self.canBeWithdrawn();
        send(SendParameters{to: self.owner, value: toBeWithdrawn, bounce: false, mode: SendRemainingValue});
    }

     receive(msg: Claim){
        let sender = context().sender;
        require(self.toBeClaimed.exists(sender), "Only winner can claim");
        let value: Int = self.toBeClaimed.get(sender)!!;
        send(SendParameters{to: sender, bounce: true, value: value, mode: SendIgnoreErrors, body: "Claimed".asComment()}
        );
        self.toBeClaimed.del(sender);
    }

    receive(msg: BuyTicket){
        require(context().value >= self.config.ticketPrice, "Not enough funds");
        if (!self.oncePlayed.exists(context().sender)) {
            if (msg.referrer != null) {
                let referrerBonus: Int = (self.config.ticketPrice * self.config.referrerBonusPercent) / 100;
                if (self.referralBonus.exists(msg.referrer!!)) {
                    self.referralBonus.set(msg.referrer!!, self.referralBonus.get(msg.referrer!!)!! + referrerBonus);
                } else {
                    self.referralBonus.set(msg.referrer!!, referrerBonus);
                }
                self.oncePlayed.set(context().sender, true);
            }
        }
       
        let sender = context().sender;
        if (self.currentExpedition == null) {
            let address = self.startExpedition(sender);
            self.currentExpedition = address;
        } else {

            send(SendParameters{
                    to: self.currentExpedition!!,
                    value: self.minTonsForStorage,
                    bounce: false,
                    body: AddMemberInternal{member: sender}.toCell()
                }
            );
        }
        self.currentExpeditionLength += 1;
    }

    receive(msg: ExpeditionResultInternal){
        let expeditionResult: ExpeditionResult = ExpeditionResult{winners: msg.winners, address: msg.address};
        foreach (index, winner in expeditionResult.winners) {
            self.toBeClaimed.set(winner.player, winner.treasure);
        }
        self.expeditionResults.set(self.expeditionResultsLength, expeditionResult);
        self.expeditionResultsLength += 1;
        self.currentExpedition = null;
        self.currentExpeditionLength = 0;
    }

    receive(msg: RequestReferralBonus){
        require(self.referralBonus.exists(context().sender), "You have no referral bonus");
        let value: Int = self.referralBonus.get(context().sender)!!;
        send(SendParameters{to: context().sender, bounce: true, value: value, mode: SendIgnoreErrors, body: "Referral bonus".asComment()}
        );
        self.referralBonus.del(context().sender);
    }

    fun reservedFundsForClaim(): Int {
        let sum: Int = 0;
        foreach (address, treasury in self.toBeClaimed) {
            sum += treasury;
        }
        return sum;
    }

    fun reservedFundsForReferralBonus(): Int {
        let sum: Int = 0;
        foreach (address, treasury in self.referralBonus) {
            sum += treasury;
        }
        return sum;
    }

    fun startExpedition(member: Address): Address {
        let init: StateInit = initOf Expedition(self.expeditionResultsLength, self.config);
        let expeditionAddress: Address = contractAddress(init);
        send(SendParameters{
                to: expeditionAddress,
                value: self.minTonsForStorage,
                bounce: false,
                body: AddMemberInternal{member: member}.toCell(),
                code: init.code,
                data: init.data
            }
        );
        return expeditionAddress;
    }

    fun canBeWithdrawn(): Int {
        let contractBalance: Int = myBalance();
        let reservedFundsForClaim: Int = self.reservedFundsForClaim();
        let reservedFundsForReferralBonus: Int = self.reservedFundsForReferralBonus();
        let currentGameExpenses = self.currentExpeditionLength * self.config.ticketPrice;
        return contractBalance - self.minTonsForStorage - self.gasConsumption - reservedFundsForClaim - currentGameExpenses - reservedFundsForReferralBonus;
    }

    // Getters

    get fun expeditionHistory(): map<Int, ExpeditionResult> {
        return self.expeditionResults;
    }

    get fun contractBalance(): Int {
        return myBalance();
    }

    get fun availableForWithdraw(): Int {
        return self.canBeWithdrawn();
    }

    get fun canBeClaimed(address: Address): Int? {
        return self.toBeClaimed.get(address);
    }

    get fun referralBonusBalance(address: Address): Int? {
        return self.referralBonus.get(address);
    }
}