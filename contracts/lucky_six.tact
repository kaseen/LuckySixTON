import "@stdlib/deploy";

message PlayTicket {
    num1: Int as uint32;
}

contract LuckySix with Deployable {

    owner: Address;
    playerTickets: map<Address, Int>;

    init() {
        self.owner = sender();
    }

    receive(msg: PlayTicket) {
        self.playerTickets.set(sender(), msg.num1);
    }

    get fun ticket(address: Address): Int? {
        let returnValue: Int? = self.playerTickets.get(address);

        // Return if map is not empty
        if(returnValue != null) {
            return returnValue;
        } else {
            return 0;
        }
    }
}
