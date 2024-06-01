import "@stdlib/deploy";

// ------------------------------------------------------------------------------------------------------
// --------------------------------------- TICKET ARRAY STRUCTURE ---------------------------------------
// ------------------------------------------------------------------------------------------------------
const _MAX_ARRAY_SIZE: Int = 488;

struct UnpackedTicketCombinationArray {
    array: map<Int as uint8, Int>;
    length: Int = 0;
}

extends mutates fun append(self: UnpackedTicketCombinationArray, item: Int) {
    require(self.length + 1 <= _MAX_ARRAY_SIZE, "");
    self.array.set(self.length, item);
    self.length += 1;
}

extends mutates fun swapIndexes(self: UnpackedTicketCombinationArray, i: Int, j: Int) {
    require(i >= 0, "");
    require(j >= 0, "");
    require(i < self.length, "");
    require(j < self.length, "");

    let tmp: Int = self.array.get(i)!!;
    self.array.set(i, self.array.get(j)!!);
    self.array.set(j, tmp);
}

extends fun getIndex(self: UnpackedTicketCombinationArray, index: Int): Int {
    require(self.length > 0, "");
    require(index >= 0, "");
    require(index < self.length, "");

    return self.array.get(index)!!;
}

extends mutates fun setIndex(self: UnpackedTicketCombinationArray, index: Int, value: Int) {
    require(self.length > 0, "");
    require(index >= 0, "");
    require(index < self.length, "");

    self.array.set(index, value);
}

extends fun getLength(self: UnpackedTicketCombinationArray): Int {
    return self.length;
}

fun emptyArray(): UnpackedTicketCombinationArray {
    return UnpackedTicketCombinationArray { array: emptyMap(), length: 0 };
}

fun allocateArray(n: Int): UnpackedTicketCombinationArray {
    return UnpackedTicketCombinationArray { array: emptyMap(), length: n }; 
}

// ------------------------------------------------------------------------------------------------------
// ---------------------------------------------- MESSAGES ----------------------------------------------
// ------------------------------------------------------------------------------------------------------
message PlayTicket {
    packedCombination:  Int as uint64;
}

struct Ticket {
    roundTickedPlayed:  Int as uint64;
    packedCombination:  Int as uint64;
    redeemed:           Bool;
}

struct Round {
    roundNumber:        Int as uint128;
    timeStarted:        Int as uint64;
    isStarted:          Bool;
}

/**
 *  @dev The maximum round number is 2^128-1
 */
contract LuckySix with Deployable {

    const BITMASK_0b111111:     Int = pow(2, 6) - 1;
    const MAXIMUM_NUMBER_DRAWN: Int = 48;
    const NUMBER_OF_DRAWS:      Int = 35;

    const LOTTERY_READY:        Int = 0;
    const LOTTERY_STARTED:      Int = 1;
    const LOTTERY_CLOSED:       Int = 2;

    lotteryState: Int as uint8; 
    roundInfo: Round;

    owner: Address;
    playerTicket: map<Address, Ticket>;
    drawnNumbersPerRound: map<Int as uint128, Int>;     // TODO: Remember number of tickets played, to release storage

    // Constructor
    init() {
        self.owner = sender();
        self.roundInfo = Round{
            roundNumber: 0,
            timeStarted: 0,
            isStarted: false
        };
        // TODO: self.lotteryState = self.LOTTERY_CLOSED;
        self.lotteryState = self.LOTTERY_READY;     // TODO: remove
    }

    receive("openRound") {
        if(sender() != self.owner) {
            // TODO: UnauthorizedAccess
            nativeThrow(1251251251);
        }
        if(self.lotteryState != self.LOTTERY_CLOSED) {
            // TODO: LotteryNotClosed
            nativeThrow(2141241);
        }
        self.lotteryState = self.LOTTERY_READY;
        self.roundInfo.isStarted = false;
    }

    // TODO: Check how much this costs
    receive("drawNumbers") {
        if(sender() != self.owner) {
            // TODO: UnauthorizedAccess
            nativeThrow(1251251251);
        }

        // TODO: Check timestamp of lottery

        let numbers1to48: UnpackedTicketCombinationArray = self.generateNumbers1to48();
        let random48numbers: UnpackedTicketCombinationArray = self.generateRandom48Numbers();

        let packedResult: Int = 0;

        let j: Int = numbers1to48.getLength() - 1;
        let i: Int = 0;
        while(i < self.NUMBER_OF_DRAWS){
            let indexOfChosenNumber: Int = random48numbers.getIndex(i) % j;

            numbers1to48.swapIndexes(j, indexOfChosenNumber);

            packedResult = packedResult | numbers1to48.getIndex(j);
            packedResult = packedResult << 6;

            i = i + 1;
            j = j - 1;
        }

        packedResult = packedResult >> 6;

        self.drawnNumbersPerRound.set(self.roundInfo.roundNumber, packedResult);
        self.roundInfo.roundNumber = self.roundInfo.roundNumber + 1;
        self.lotteryState = self.LOTTERY_CLOSED;
    }

    /**
     * @dev: A user cannot play a ticket if the status of the last ticket is unresolved, regardless of
     *       whether the ticket is winning or losing. The map for sender address needs to be empty before
     *       playing the next ticket.
     */
    receive(msg: PlayTicket) {
        if(self.lotteryState != self.LOTTERY_READY && self.lotteryState != self.LOTTERY_STARTED) {
            // TODO: LotteryNotOpen
            nativeThrow(12412);
        }

        let previousTicket: Ticket? = self.playerTicket.get(sender());
        
        // Check if the combination entered is valid
        /* TODO
        if(previousTicket != null) {
            dump(123);
            // TODO: UserCannotPlay
            nativeThrow(123444);
        }*/

        // Check if the user has empty storage
        if(self.checkIfPlayedNumbersAreValid(msg.packedCombination) == false) {
            dump(234);
            // TODO: InvalidCombination
            nativeThrow(12512512);
        }

        // When the first ticket is played, start the countdown 
        if(!self.roundInfo.isStarted) {
            self.lotteryState = self.LOTTERY_STARTED;
            self.roundInfo.timeStarted = now();
            self.roundInfo.isStarted = true;
        }

        // TODO: Pay for storage

        self.playerTicket.set(sender(), Ticket{ 
            roundTickedPlayed: self.roundInfo.roundNumber,
            packedCombination: msg.packedCombination,
            redeemed: false
        });
    }

    receive("getPayoutForTicket") {
        let playerTicket: Ticket? = self.playerTicket.get(sender());

        if(playerTicket == null) {
            // TODO: TicketDoesNotExists
            nativeThrow(125125125);
        }

        // TODO: Check if numbers are drawn

        //let multiplier: Int = self.get
    }

    /**
     *  @dev It is implicitly ensured that the roundNumber is valid, which in turn indicates
     *       that the numbers have been drawn for that round.
     */
    fun getMultiplier(ticket: Ticket): Int {
        //let drawnNumbers: UnpackedTicketCombinationArray = self.drawnNumbersForRound(ticket.roundTickedPlayed);

        return 0;
    }

    get fun lastPlayedTicket(address: Address): Ticket? {
        let previousTicket: Ticket? = self.playerTicket.get(address);

        if(previousTicket != null){
            return previousTicket;
        } else {
            return Ticket{ 
                roundTickedPlayed: 0, 
                packedCombination: 0,
                redeemed: false
            };
        }
    }

    fun checkIfPlayedNumbersAreValid(packedNumbers: Int): Bool {

        let combinationLength: Int = 6;
        let i: Int = 0;
        let j: Int = 0;

        let combination: UnpackedTicketCombinationArray = self.unpackTicketNumbers(packedNumbers);
        
        while(i < combinationLength) {
            // Check if number is between 1 and `MAXIMUM_NUMBER_DRAWN`
            if(combination.getIndex(i) < 1 || combination.getIndex(i) > self.MAXIMUM_NUMBER_DRAWN) {
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
            result.append(packedNumbers & self.BITMASK_0b111111);
            packedNumbers = packedNumbers >> 6;
        }

        return result;
    }

    fun generateNumbers1to48(): UnpackedTicketCombinationArray {
        let result: UnpackedTicketCombinationArray = emptyArray();
        let i: Int = 1;
        while(i < 49) {
            result.append(i);
            i = i + 1;
        }
        return result;
    }

    fun generateRandom48Numbers(): UnpackedTicketCombinationArray {
        let result: UnpackedTicketCombinationArray = emptyArray();

        nativeRandomizeLt();
        repeat(48) {
            result.append(randomInt());
        }

        return result;
    }

     fun packedDrawnNumbersForRound(n: Int): Int {
        if(n > self.roundInfo.roundNumber) {
            // TODO: InvalidRoundNumber
            nativeThrow(134125);
        }
        return self.drawnNumbersPerRound.get(n)!!;
    }

    /**
     *  @dev The validity of round number `n` is checked inside the `packedDrawnNumbersForRound` function.
     */
    get fun unpackedDrawnNumbersForRound(n: Int): UnpackedTicketCombinationArray {
        let packedDrawnNumber: Int = self.packedDrawnNumbersForRound(n);
        let result: UnpackedTicketCombinationArray = allocateArray(self.NUMBER_OF_DRAWS);
        let tmp: Int = self.NUMBER_OF_DRAWS - 1;
        let i: Int = 0;

        while(i < self.NUMBER_OF_DRAWS) {
            result.setIndex(tmp - i, (packedDrawnNumber >> i * 6) & self.BITMASK_0b111111);
            i = i + 1;
        }

        return result;
    }

    // TODO: Delete
    get fun ifValid(packedNumbers: Int): Bool {
        return self.checkIfPlayedNumbersAreValid(packedNumbers);
    }
}
