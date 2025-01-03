struct Config {
    numberOfPlayers: Int;
    ticketPrice: Int as coins;
    treasurePercent: Int as coins;
}

extends fun treasure(self: Config): Int {
    return ((self.numberOfPlayers * self.ticketPrice) * self.treasurePercent) / 100; // 70 % of the total amount goes to the winners
}