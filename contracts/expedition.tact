import "@stdlib/deploy";
import "@stdlib/ownable";
import "./models.tact";

contract Expedition with Deployable, Ownable {
    id: Int;
    state: ExpeditionState;
    owner: Address;
    numberOfPlayers: Int as uint8;
    players: map<Int, Address>;
    maxNumberOfPlayers: Int as uint8;
    init(id: Int, maxNumberOfPlayers: Int){
        dump("New Expedition is created");
        self.id = id;
        self.owner = context().sender;
        self.state = ExpeditionState{code: 0};
        self.numberOfPlayers = 0;
        self.players = emptyMap();
        self.maxNumberOfPlayers = maxNumberOfPlayers;
    }

    receive(msg: AddPlayerInternal){
        if (self.state.code == 0) {
            self.state = ExpeditionState{code: 1};
        }
        // Check if the sender is the owner
        self.requireOwner();
        let player = msg.player;
        self.players.set(self.numberOfPlayers, player);
        self.numberOfPlayers += 1;
        if (self.numberOfPlayers == self.maxNumberOfPlayers) {
            self.state = ExpeditionState{code: 2};
            let winners = self.selectRandomPlayers(5);
            let body = WinnerList{
                firstPlace: winners.get(0)!!,
                secondPlace: winners.get(1)!!,
                thirdPlace: winners.get(2)!!,
                fourthPlace: winners.get(3)!!,
                fifthPlace: winners.get(4)!!
            };
            dump(myBalance());
            send(SendParameters{
                    to: self.owner,
                    value: 0,
                    bounce: false,
                    mode: SendRemainingBalance | SendIgnoreErrors,
                    body: body.toCell()
                }
            );
        }
    }

    get fun currentState(): ExpeditionState {
        return self.state;
    }

    get fun currentNumberOfPlayers(): Int {
        return self.numberOfPlayers;
    }
}

extends fun selectRandomPlayers(self: Expedition, count: Int): map<Int, Address> {
    let selectedPlayers: map<Int, Address> = emptyMap();
    let selectedCount: Int = 0;
    while (selectedCount < count) {
        let randomKey: Int = random(0, self.numberOfPlayers);
        if (self.players.exists(randomKey)) {
            let address: Address = self.players.get(randomKey)!!;
            selectedPlayers.set(selectedCount, address);
            selectedCount += 1;
            self.players.del(randomKey);
            self.numberOfPlayers -= 1;
        }
    }
    return selectedPlayers;
}