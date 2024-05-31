import "@stdlib/deploy";

// ------------------------------------------------------------------------------------------------------
// --------------------------------------- TICKET ARRAY STRUCTURE ---------------------------------------
// ------------------------------------------------------------------------------------------------------
const _MAX_ARRAY_SIZE: Int = 6;

struct UnpackedTicketCombinationArray {
    array: map<Int as uint8, Int as uint8>;
    length: Int = 0;
}

extends mutates fun append(self: UnpackedTicketCombinationArray, item: Int) {
    require(self.length + 1 <= _MAX_ARRAY_SIZE, "");
    self.array.set(self.length, item);
    self.length += 1;
}

extends fun getIndex(self: UnpackedTicketCombinationArray, index: Int): Int {
    require(self.length > 0, "");
    require(index >= 0, "");
    require(index < self.length, "");

    return self.array.get(index)!!;
}

fun emptyArray(): UnpackedTicketCombinationArray {
    return UnpackedTicketCombinationArray{ array: emptyMap(), length: 0 };
}


message PlayTicket {
    packedCombination: Int as uint64;
}
 
struct Ticket {
    roundTickedPlayed: Int as uint64;
    packedTicketCombination: Int as uint64;
    redeemed: Bool;
}

contract LuckySix with Deployable {

    const _BITMASK_0b111111: Int = pow(2, 6) - 1;
    const _MAXIMUM_NUMBER_DRAWN: Int = 48;

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

    get fun bla(packedNumbers: Int): UnpackedTicketCombinationArray {
        return self.unpackTicketNumbers(packedNumbers);
    }

    get fun ifValid(packedNumbers: Int): Bool {
        return self.checkIfPlayedNumbersAreValid(packedNumbers);
    }

    // TODO: Can it be private?
    fun checkIfPlayedNumbersAreValid(packedNumbers: Int): Bool {

        let combinationLength: Int = 6;
        let i: Int = 0;
        let j: Int = 0;

        let combination: UnpackedTicketCombinationArray = self.unpackTicketNumbers(packedNumbers);
        
        while(i < combinationLength) {
            // Check if number is between 1 and `_MAXIMUM_NUMBER_DRAWN`
            if(combination.getIndex(i) < 1 || combination.getIndex(i) > self._MAXIMUM_NUMBER_DRAWN) {
                return false;
            }

            // Check if number is unique
            j = i + 1;
            while(j < combinationLength) {
                if(combination.getIndex(i) == combination.getIndex(j)) {
                    return false;
                }

                j = j + 1;
            }
            i = i + 1;
        }

        return true;
    }

    fun unpackTicketNumbers(packedNumbers: Int): UnpackedTicketCombinationArray {
        let result: UnpackedTicketCombinationArray = emptyArray();

        repeat(6) {
            result.append(packedNumbers & self._BITMASK_0b111111);
            packedNumbers = packedNumbers >> 6;
        }

        return result;
    }
}
