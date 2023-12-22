// Raffle
// Enter the lottery (paying some amount)
// Pick a random winner (verifiably random)
// Winner to be selected every X minutes => completly automated
// Chainlink Oracle => Randomness, Automated Execution (Chainlink Keeper)

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

error Raffle_NotEnoughETHEntered();
error Raffle_TransferFailed();
error Raffle_NotOpen();

contract Raffle is VRFConsumerBaseV2, AutomationCompatible {
    /* Type Declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /* State Variables */
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    /* Lottery variables */
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /* Constants */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    /* Events */
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    constructor(
        address vrfCoordinator,
        uint256 entranceFee,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_raffleState = RaffleState.OPEN;
    }

    /* Functions */
    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) revert Raffle_NotEnoughETHEntered();
        if (s_raffleState != RaffleState.OPEN) revert Raffle_NotOpen();

        s_players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);
    }

    /**
     * @dev checkUpkeep is called by the Chainlink Automation nodes to determine if the upkeep should be performed.
     * The following must be true for it to return true:
     * - Time interval should have passed
     * - Lottery should have at least one player, and have some ETH
     * - Subscription should be funded with LINK
     * - Lottery should be in an 'open' state
     */
    function checkUpkeep(
        bytes calldata checkData
    ) external override returns (bool upkeepNeeded, bytes memory performData) {}

    function performUpkeep(bytes calldata performData) external override {}

    function requestRandomWinner() external {
        s_raffleState = RaffleState.CALCULATING;

        // Request the random number from the oracle
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        // Once we get it, do somethign with it
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory randomWords
    ) internal override {
        // Pick a random winner
        uint256 winnerIdx = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[winnerIdx];
        s_recentWinner = recentWinner;

        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);

        // Transfer the balance to the winner
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) revert Raffle_TransferFailed();

        emit WinnerPicked(recentWinner);
    }

    /* View/ Pure Functions */
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 playerIdx) public view returns (address) {
        return s_players[playerIdx];
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }
}
