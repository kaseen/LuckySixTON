import "@stdlib/deploy";

message PlayTicket {
    packedCombination: Int as uint64;
}
 
struct Ticket {
    roundTickedPlayed: Int as uint64;
    lastCombinationPlayed: Int as uint64;
    redeemed: Bool;
}

contract LuckySix with Deployable {

    owner: Address;
    playerTicket: map<Address, Ticket>;
    currentRound: Int as uint64;

    // Constructor
    init() {
        self.owner = sender();
        self.currentRound = 0;
    }

    // Play ticket for current round
    receive(msg: PlayTicket) {
        let previousTicket: Ticket? = self.playerTicket.get(sender());
        
        /**
         * @dev: A user cannot play a ticket if the status of the last ticket is unresolved, regardless of
         * whether the ticket is winning or losing. The map for sender address needs to be empty before
         * playing the next ticket.
         */
        if(previousTicket != null){
            // TODO: Test throw
            nativeThrow(123444);
        }

        // TODO: Check if numbers are valid

        // TODO: Pay for storage

        self.playerTicket.set(sender(), Ticket{ 
            roundTickedPlayed: self.currentRound,
            lastCombinationPlayed: msg.packedCombination,
            redeemed: false
        });
    }

    get fun lastPlayedTicket(address: Address): Ticket? {
        let previousTicket: Ticket? = self.playerTicket.get(address);

        if(previousTicket != null){
            return previousTicket;
        } else {
            return Ticket{ 
                roundTickedPlayed: 0, 
                lastCombinationPlayed: 0,
                redeemed: false
            };
        }
    }
}
