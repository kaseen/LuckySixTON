import "@stdlib/deploy";

// --------------------------------------------------------------------------------------
// ------------------------------- TICKET ARRAY STRUCTURE -------------------------------
// --------------------------------------------------------------------------------------
const _MAX_ARRAY_SIZE: Int = 48;

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

// --------------------------------------------------------------------------------------
// --------------------------------------- OTHER ----------------------------------------
// --------------------------------------------------------------------------------------
message PlayTicket {
    packedCombination:  Int as uint64;
}

// TODO: Max ticket value is uint128
struct Ticket {
    roundTickedPlayed:  Int as uint64;
    packedCombination:  Int as uint64;
    ticketBet:          Int as uint128;
}

struct Round {
    roundNumber:        Int as uint128;
    timeStarted:        Int as uint64;
    isStarted:          Bool;
}

/**
 *  @dev The maximum round number is 2^128-1
 *  @dev Error numbers:
 *       UnauthorizedAccess:        1
 *       LotteryNotClosed:          2
 *       LotteryNotOpen:            3
 *       LotteryNotStarted:         4
 *       PreviousTicketUnresolved:  5
 *       InvalidCombination:        6
 *       TicketDoesNotExists:       7
 *       InvalidRoundNumber:        8
 *       NotEnoughFunds:            9
 *       LotteryNotEnoughFunds:     10
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
    bonusMultiplier: UnpackedTicketCombinationArray;

    // Constructor
    init() {
        self.owner = context().sender;
        self.roundInfo = Round{
            roundNumber: 0,
            timeStarted: 0,
            isStarted: false
        };
        self.lotteryState = self.LOTTERY_CLOSED;

        // TODO: Better
        self.bonusMultiplier = emptyArray();
        repeat(5) {
            self.bonusMultiplier.append(0);
        }
        self.bonusMultiplier.append(10000);
        self.bonusMultiplier.append(7500);
        self.bonusMultiplier.append(5000);
        self.bonusMultiplier.append(2500);
        self.bonusMultiplier.append(1000);
        self.bonusMultiplier.append(500);
        self.bonusMultiplier.append(300);
        self.bonusMultiplier.append(200);
        self.bonusMultiplier.append(150);
        self.bonusMultiplier.append(100);
        self.bonusMultiplier.append(90);
        self.bonusMultiplier.append(80);
        self.bonusMultiplier.append(70);
        self.bonusMultiplier.append(60);
        self.bonusMultiplier.append(50);
        self.bonusMultiplier.append(40);
        self.bonusMultiplier.append(30);
        self.bonusMultiplier.append(25);
        self.bonusMultiplier.append(20);
        self.bonusMultiplier.append(15);
        self.bonusMultiplier.append(10);
        self.bonusMultiplier.append(9);
        self.bonusMultiplier.append(8);
        self.bonusMultiplier.append(7);
        self.bonusMultiplier.append(6);
        self.bonusMultiplier.append(5);
        self.bonusMultiplier.append(4);
        self.bonusMultiplier.append(3);
        self.bonusMultiplier.append(2);
        self.bonusMultiplier.append(1);
    }

    // --------------------------------------------------------------------------------------
    // --------------------------------- RECEIVE FUNCTIONS ----------------------------------
    // --------------------------------------------------------------------------------------

    receive("openRound") {
        // UnauthorizedAccess
        if(context().sender != self.owner) { nativeThrow(1); }
        // LotteryNotClosed
        if(self.lotteryState != self.LOTTERY_CLOSED) { nativeThrow(2); }
        self.lotteryState = self.LOTTERY_READY;
        self.roundInfo.isStarted = false;
    }

    /**
     * @dev: A user cannot play a ticket if the status of the last ticket is unresolved, regardless of
     *       whether the ticket is winning or losing. The map for sender address needs to be empty before
     *       playing the next ticket.
     */
    receive(msg: PlayTicket) {
        // LotteryNotOpen
        if(self.lotteryState != self.LOTTERY_READY && self.lotteryState != self.LOTTERY_STARTED) { nativeThrow(3); }

        // TODO: Better estimation
        let estimatedGasOfThisFunction: Int = ton("0.05");

        // NotEnoughFunds
        if(context().value < estimatedGasOfThisFunction) { nativeThrow(9); }

        let previousTicket: Ticket? = self.playerTicket.get(context().sender);
        
        // Check if the user has empty storage
        // PreviousTicketUnresolved
        if(previousTicket != null) { nativeThrow(5); }

        // InvalidCombination        
        if(self.checkIfPlayedNumbersAreValid(msg.packedCombination) == false) { nativeThrow(6); }

        // When the first ticket is played, start the countdown 
        if(!self.roundInfo.isStarted) {
            self.lotteryState = self.LOTTERY_STARTED;
            self.roundInfo.timeStarted = now();
            self.roundInfo.isStarted = true;
        }

        // TODO: Pay for storage
        self.playerTicket.set(context().sender, Ticket{ 
            roundTickedPlayed: self.roundInfo.roundNumber,
            packedCombination: msg.packedCombination,
            ticketBet: context().value - estimatedGasOfThisFunction
        });
    }    

    // TODO: Check how much this costs
    receive("drawNumbers") {
        // UnauthorizedAccess
        if(context().sender != self.owner) { nativeThrow(1); }

        // LotteryNotStarted
        if(self.lotteryState != self.LOTTERY_STARTED) { nativeThrow(4); }

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
     * @dev If the ticket is not winning, remove it from the playerTicket mapping. If it is a winning
     *      one, send the payout to the winner and remove it from the same mapping.
     */
    // TODO: Reentracy
    receive("resolveTicketStatus") {
        let playerTicket: Ticket? = self.playerTicket.get(context().sender);

        // TicketDoesNotExists
        if(playerTicket == null) { nativeThrow(7); }

        // TODO: Check if numbers are drawn
        let multiplier: Int = self.getMultiplier(playerTicket!!);

        if(multiplier != 0) {
            let cashEarned: Int = multiplier * playerTicket!!.ticketBet;

            // LotteryNotEnoughFunds
            if(cashEarned > self.lotteryBalance()) { nativeThrow(10); }

            send(SendParameters{
                to: context().sender,
                value: cashEarned,
                body: "Congratulations!".asComment()
            });
        }
        // Implicitly deletes entry if multiplier is 0
        self.playerTicket.del(context().sender);
    }

    // --------------------------------------------------------------------------------------
    // --------------------------------- PRIVATE FUNCTIONS ----------------------------------
    // --------------------------------------------------------------------------------------

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

    /**
     *  @dev It is implicitly ensured that the ticket is valid, and that the numbers have been drawn for 
     *       that round.
     */
    fun getMultiplier(ticket: Ticket): Int {
        let drawnNumbers: UnpackedTicketCombinationArray = self.unpackedDrawnNumbersForRound(ticket.roundTickedPlayed);
        let ticketNumbers: UnpackedTicketCombinationArray = self.unpackTicketNumbers(ticket.packedCombination);
        
        let numbersMatchedCounter: Int = 0;
        let index: Int = -1;

        let n: Int = ticketNumbers.getLength();
        let m: Int = drawnNumbers.getLength();

        let i: Int = 0;
        let j: Int = 0;

        while(i < n) {
            j = 0;
            while(j < m) {
                if(ticketNumbers.getIndex(i) == drawnNumbers.getIndex(j)) {
                    numbersMatchedCounter = numbersMatchedCounter + 1;
                    index = j > index ? j : index;
                }
                j = j + 1;
            }
            i = i + 1;
        }

        if(numbersMatchedCounter == 0) {
            return 100;
        } else if(numbersMatchedCounter == 6) {
            return self.bonusMultiplier.getIndex(index);
        } else {
            return 0;
        }
    }

    fun unpackTicketNumbers(packedNumbers: Int): UnpackedTicketCombinationArray {
        let result: UnpackedTicketCombinationArray = emptyArray();

        repeat(6) {
            result.append(packedNumbers & self.BITMASK_0b111111);
            packedNumbers = packedNumbers >> 6;
        }

        return result;
    }

    fun packedDrawnNumbersForRound(n: Int): Int {
        // InvalidRoundNumber
        if(n > self.roundInfo.roundNumber) { nativeThrow(8); }
        return self.drawnNumbersPerRound.get(n)!!;
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

    // --------------------------------------------------------------------------------------
    // -------------------------------------- GETTERS ---------------------------------------
    // --------------------------------------------------------------------------------------

    get fun roundInfo(): Round {
        return self.roundInfo;
    }

    get fun lotteryState(): Int {
        return self.lotteryState;
    }

    get fun lotteryBalance(): Int {
        return myBalance();
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

    get fun lastPlayedTicket(address: Address): Ticket {
        let previousTicket: Ticket? = self.playerTicket.get(address);

        if(previousTicket != null){
            return previousTicket!!;
        } else {
            return Ticket{ 
                roundTickedPlayed: 0, 
                packedCombination: 0,
                ticketBet: 0
            };
        }
    }
}
