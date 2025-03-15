// SPDX-License-Identifier: MIT License
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Gamble} from "../src/Gamble.sol";

contract GambleTest is Test {
    Gamble public gamble;

    event PlayerJoined(address indexed player, uint256 amount, uint256 gameNumber);
    event WinnerSelected(address winner, uint256 amount, uint256 gameNumber);

    function setUp() public {
        gamble = new Gamble();
    }

    function test_Deposit() public {
        address player = address(0x1234);
        uint256 entryFee = 1 ether;

        vm.deal(player, 10 ether);
        vm.startPrank(player);

        console.log("Before deposit - Player count:", gamble.getPlayerCount());
        console.log("Before deposit - Balance:", gamble.getBalance());
        gamble.deposit{value: entryFee}();

        console.log("After deposit - Player count:", gamble.getPlayerCount());
        console.log("After deposit - Balance:", gamble.getBalance());
        assertEq(gamble.getPlayerCount(), 1, "Player count should be 1 after deposit");
        assertEq(gamble.getBalance(), entryFee, "Balance should equal ENTRY_FEE");

        vm.stopPrank();
    }

    function test_DepositAfterReset() public {
        address[5] memory players = [
            address(0x1),
            address(0x2),
            address(0x3),
            address(0x4),
            address(0x5)
        ];
        address newPlayer = address(0x6);
        uint256 entryFee = 1 ether;

        for (uint256 i = 0; i < 5; i++) {
            vm.deal(players[i], 10 ether);
            vm.prank(players[i]);
            gamble.deposit{value: entryFee}();
        }

        assertEq(gamble.getPlayerCount(), 0, "Player count should be 0 after reset");
        assertEq(gamble.getBalance(), 0, "Balance should be 0 after payout");

        vm.deal(newPlayer, 10 ether);
        vm.startPrank(newPlayer);
        gamble.deposit{value: entryFee}();
        assertEq(gamble.getPlayerCount(), 1, "Player count should be 1 in new game");
        vm.stopPrank();
    }

    function test_ManyDeposits() public {
        address[5] memory players = [
            address(0x1),
            address(0x2),
            address(0x3),
            address(0x4),
            address(0x5)
        ];
        uint256 entryFee = 1 ether;

        for (uint256 i = 0; i < 5; i++) {
            vm.deal(players[i], 10 ether);
            vm.prank(players[i]);
            gamble.deposit{value: entryFee}();
        }

        assertEq(gamble.getPlayerCount(), 0, "Player count should reset after 5 deposits");
        assertEq(gamble.getBalance(), 0, "Balance should be 0 after payout");
    }

    function test_MaxPlayersAndGameEnd() public {
        address[5] memory players = [
            address(0x1),
            address(0x2),
            address(0x3),
            address(0x4),
            address(0x5)
        ];
        uint256 entryFee = 1 ether;

        for (uint256 i = 0; i < 4; i++) {
            vm.deal(players[i], 10 ether);
            vm.prank(players[i]);
            gamble.deposit{value: entryFee}();
        }

        vm.deal(players[4], 10 ether);
        vm.startPrank(players[4]);

        console.log("Before last deposit - Player count:", gamble.getPlayerCount());
        console.log("Before last deposit - Balance:", gamble.getBalance());
        gamble.deposit{value: entryFee}();

        console.log("After game end - Player count:", gamble.getPlayerCount());
        console.log("After game end - Balance:", gamble.getBalance());
        assertEq(gamble.getPlayerCount(), 0, "Player count should reset after game ends");
        assertEq(gamble.getBalance(), 0, "Balance should be 0 after payout");
        assertGt(gamble.getTimeRemaining(), 0, "New game should have time remaining");

        vm.stopPrank();

        address extraPlayer = address(0x6);
        vm.deal(extraPlayer, 10 ether);
        vm.prank(extraPlayer);
        gamble.deposit{value: entryFee}();
    }
}
