import "@stdlib/deploy";
import "@stdlib/ownable";
import "./config.tact";
import "./models.tact";

contract Expedition with Deployable, Ownable {
    // Constants
    const minTonsForStorage: Int = ton("0.01");
    const gasConsumption: Int = ton("0.01");
    // Variables
    id: Int;
    owner: Address;
    config: Config;
    members: map<Int, Address>;
    membersLength: Int;
    // Lifecycle
    init(id: Int, config: Config){
        self.id = id;
        self.owner = context().sender;
        self.config = config;
        self.members = emptyMap();
        self.membersLength = 0;
    }

    receive(msg: AddMemberInternal){
        self.requireOwner();
        require(self.membersLength < self.config.numberOfPlayers, "Expedition is already started");
        self.members.set(self.membersLength, msg.member);
        self.membersLength += 1;
        if (self.membersLength == self.config.numberOfPlayers) {
            self.startExpedition();
        }
    }

    fun startExpedition() {
        let winners: map<Int, Winner> = self.getWinners(self.config, self.membersLength, self.members);
        send(SendParameters{
                to: self.owner,
                value: (myBalance() - self.minTonsForStorage) - self.gasConsumption,
                mode: SendRemainingBalance,
                bounce: false,
                body: ExpeditionResultInternal{winners: winners, address: myAddress()}.toCell()
            }
        );
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

    fun getWinners(config: Config, copyLength: Int, copyPlayers: map<Int, Address>): map<Int, Winner> {
        let winnerMap: map<Int, Winner> = emptyMap();
        let randomPlayers: map<Int, Address> = self.selectRandomPlayers(5, copyLength, copyPlayers);
        let prizes: map<Int, Int> = emptyMap();
        let currentIndex: Int = 0;
        let treasure: Int = config.treasure();
        prizes.set(0, (treasure * 50) / 100);
        prizes.set(1, (treasure * 20) / 100);
        prizes.set(2, (treasure * 10) / 100);
        prizes.set(3, (treasure * 10) / 100);
        prizes.set(4, (treasure * 10) / 100);
        foreach (key, value in randomPlayers) {
            let winner: Winner = Winner{treasure: prizes.get(currentIndex)!!, player: value};
            winnerMap.set(currentIndex, winner);
            currentIndex += 1;
        }
        return winnerMap;
    }
}