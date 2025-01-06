import "@stdlib/deploy";
import "@stdlib/ownable";
import "./config.tact";
import "./models.tact";
import "./expedition.tact";

contract TreasureHuntersV2 with Deployable, Ownable {
    // Constants
    const minTonsForStorage: Int = ton("0.01");
    const gasConsumption: Int = ton("0.01");
    // Variables
    owner: Address;
    config: Config;
    currentExpedition: Address?;
    currentExpeditionLength: Int;
    expeditionResultsLength: Int;
    expeditionResults: map<Int, ExpeditionResult>;
    // Lifecycle
    init(config: Config){
        self.owner = context().sender;
        self.config = config;
        self.currentExpeditionLength = 0;
        self.expeditionResultsLength = 0;
        self.expeditionResults = emptyMap();
    }

    // Listeners
    receive(msg: Withdraw){
        self.requireOwner();
        let contractBalance: Int = myBalance();
        let reservedFundsForClaim: Int = self.reservedFundsForClaim();
        let toBeWithdrawn: Int = contractBalance - self.minTonsForStorage - self.gasConsumption - reservedFundsForClaim;
        dump(contractBalance);
        dump(reservedFundsForClaim);
        dump(toBeWithdrawn);
        send(SendParameters{
                to: self.owner, 
                value: toBeWithdrawn, 
                bounce: false, 
                mode: SendRemainingValue
        });
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
        if (self.currentExpedition == null) {
            
            let address = self.startExpedition(sender);
            self.currentExpedition = address;
        } else {
             send(SendParameters{
                to: self.currentExpedition!!, 
                value: ton("1"),
                bounce: false,
                body: AddMemberInternal{
                    member: sender
                }.toCell(),
            });
        }

        self.currentExpeditionLength += 1;
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
        send(SendParameters{
                to: sender, 
                bounce: true, 
                value: toBeClaimed, 
                mode: SendIgnoreErrors, 
                body: "Claimed".asComment()
                },
            );
    }

    fun reservedFundsForClaim(): Int {
        let sum: Int = 0;
        foreach (index, expedition in self.expeditionResults) {
            foreach (i, winner in expedition.winners) {
                if (winner.claimed == false) {
                    sum += winner.treasure;
                }
            }
        }

        return sum;
    }


    fun startExpedition(member: Address): Address {
        let init: StateInit = initOf Expedition(self.expeditionResultsLength, self.config);
        let expeditionAddress: Address = contractAddress(init);
        
        send(SendParameters{
                to: expeditionAddress, 
                value: ton("1"),
                bounce: false,
                body: AddMemberInternal{
                    member: member,
                }.toCell(),
                code: init.code,
                data: init.data
            });

            return expeditionAddress;
    }

    // Getters

    get fun expeditionHistory(): map<Int, ExpeditionResult> {
        return self.expeditionResults;
    }

    get fun contractBalance(): Int {
        return myBalance();
    }
}