import "@stdlib/deploy";

message PlayTicket {
    packedCombination: Int as uint64;
}
 
struct Ticket {
    roundTickedPlayed: Int as uint64;
    packedTicketCombination: Int as uint64;
    redeemed: Bool;
}

struct UnpackedTicketCombination {
    num1: Int as uint8;
    num2: Int as uint8;
    num3: Int as uint8;
    num4: Int as uint8;
    num5: Int as uint8;
    num6: Int as uint8;
}

contract LuckySix with Deployable {

    const _BITMASK_0b111111: Int = pow(2, 6) - 1;

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
        if(previousTicket != null) {
            // TODO: Test throw
            nativeThrow(123444);
        }

        // TODO: Check if numbers are valid

        // TODO: Pay for storage

        self.playerTicket.set(sender(), Ticket { 
            roundTickedPlayed: self.currentRound,
            packedTicketCombination: msg.packedCombination,
            redeemed: false
        });
    }

    get fun lastPlayedTicket(address: Address): Ticket? {
        let previousTicket: Ticket? = self.playerTicket.get(address);

        if(previousTicket != null){
            return previousTicket;
        } else {
            return Ticket { 
                roundTickedPlayed: 0, 
                packedTicketCombination: 0,
                redeemed: false
            };
        }
    }

    get fun bla(packedNumber: Int): UnpackedTicketCombination {
        return self.unpackTicketNumbers(packedNumber);
    }

    fun unpackTicketNumbers(packedNumbers: Int): UnpackedTicketCombination {
        let num1: Int = packedNumbers & self._BITMASK_0b111111;
        packedNumbers = packedNumbers >> 6;

        let num2: Int = packedNumbers & self._BITMASK_0b111111;
        packedNumbers = packedNumbers >> 6;

        let num3: Int = packedNumbers & self._BITMASK_0b111111;
        packedNumbers = packedNumbers >> 6;

        let num4: Int = packedNumbers & self._BITMASK_0b111111;
        packedNumbers = packedNumbers >> 6;

        let num5: Int = packedNumbers & self._BITMASK_0b111111;
        packedNumbers = packedNumbers >> 6;

        let num6: Int = packedNumbers & self._BITMASK_0b111111;
        packedNumbers = packedNumbers >> 6;

        return UnpackedTicketCombination { num1, num2, num3, num4, num5, num6 };
    }
}
