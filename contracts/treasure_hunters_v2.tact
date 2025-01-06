import "@stdlib/deploy";
import "@stdlib/ownable";
import "./config.tact";
import "./models.tact";
import "./expedition.tact";

contract TreasureHuntersV2 with Deployable, Ownable {
    owner: Address;
    config: Config;
    currentExpedition: Address?;
    currentExpeditionLength: Int;
    expeditionResultsLength: Int;
    expeditionResults: map<Int, ExpeditionResult>;
    init(config: Config){
        self.owner = context().sender;
        self.config = config;
        self.currentExpeditionLength = 0;
        self.expeditionResultsLength = 0;
        self.expeditionResults = emptyMap();
    }

    // Add initial balance of contract
    receive(){
        self.requireOwner();
    }

    receive(msg: ExpeditionResultInternal) {
        let expeditionResult: ExpeditionResult = ExpeditionResult{
            winners: msg.winners
        };
        self.expeditionResults.set(self.expeditionResultsLength, expeditionResult);
        self.expeditionResultsLength += 1;
        self.currentExpedition = null;
        self.currentExpeditionLength = 0;
    }

    receive(msg: BuyTicket){
        require(context().value >= self.config.ticketPrice, "Not enough funds");
        let sender = context().sender;
        let referrer = msg.referrer;
        if (referrer != null) {
            let referrerBonus = (self.config.ticketPrice * self.config.referrerBonusPercent) / 100;
            send(SendParameters{to: referrer!!, value: referrerBonus, bounce: true, body: "Referral bonus".asComment()});
        }

        if (self.currentExpedition == null) {
            
            let address = self.startExpedition(sender);
            self.currentExpedition = address;
        } else {
             send(SendParameters{
                to: self.currentExpedition!!, 
                value: 0,
                mode: SendRemainingValue, 
                bounce: false,
                body: AddMemberInternal{
                    member: sender
                }.toCell(),
            });
        }

        self.currentExpeditionLength += 1;
    }

    fun startExpedition(member: Address): Address {
        let init: StateInit = initOf Expedition(self.expeditionResultsLength, self.config);
        let expeditionAddress: Address = contractAddress(init);
        
        send(SendParameters{
                to: expeditionAddress, 
                value: 0,
                mode: SendRemainingValue, 
                bounce: false,
                body: AddMemberInternal{
                    member: member,
                }.toCell(),
                code: init.code,
                data: init.data
            });

            return expeditionAddress;
    }

    receive(msg: Claim) {
        let sender = context().sender;
        let toBeClaimed: Int = 0;
        foreach (index, expedition in self.expeditionResults) {
            foreach (i, winner in expedition.winners) {
                if (winner.claimed == false && sender == winner.player) {
                    toBeClaimed += winner.treasure;
                    winner.claim();
                }
            }
        }

        send(SendParameters{to: sender, bounce: true, value: toBeClaimed, mode: SendRemainingValue + SendIgnoreErrors});
    }

    get fun canBeClaimed(): Int {
        let toBeClaimed: Int = 0;
        foreach (index, expedition in self.expeditionResults) {
            foreach (i, winner in expedition.winners) {
                if (winner.claimed == false && context().sender == winner.player) {
                    toBeClaimed += winner.treasure;
                }
            }
        }

        return toBeClaimed;
    }

    get fun expeditionHistory(): map<Int, ExpeditionResult> {
        return self.expeditionResults;
    }
}