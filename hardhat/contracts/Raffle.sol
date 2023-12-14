// Raffle
// Enter the lottery (paying some amount)
// Pick a random winner (verifiably random)
// Winner to be selected every X minutes => completly automated
// Chainlink Oracle => Randomness, Automated Execution (Chainlink Keeper)

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

error Raffle_NotEnoughETHEntered();

contract Raffle is VRFConsumerBaseV2 {
    /* State Variables */
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;

    /* Events */
    event RaffleEnter(address indexed player);

    constructor(
        address vrfCoordinator,
        uint256 entranceFee
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
    }

    /* Functions */
    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) revert Raffle_NotEnoughETHEntered();
        s_players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);
    }

    function requestRandomWinner() external {
        // Request the random number from the oracle
        // Once we get it, do somethign with it
        // 2 transaction process
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {}

    /* View/ Pure Functions */
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 playerIdx) public view returns (address) {
        return s_players[playerIdx];
    }
}
