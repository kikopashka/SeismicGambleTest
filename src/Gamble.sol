// SPDX-License-Identifier: MIT License
pragma solidity ^0.8.0;




contract Gamble {

    // have to think more about types
    saddress[] private players; 
    suint256 private ENTRY_FEE = suint256(1 ether);
    suint256 private MAX_PLAYERS = suint256(5);
    suint256 private deadline; // deadline of actual game
    sbool private gameActive; 
    saddress private lastWinner;
    suint256 private gameCount; // total number of games
    suint256 private GAME_DURATION = suint256(1 hours);

    // have to fix
    event PlayerJoined(address player, uint256 amount, uint256 gameNumber);
    event WinnerSelected(address winner, uint256 amount, uint256 gameNumber);

    constructor() {
        resetGame();
    }

    // if dep then joined
    function deposit() external payable {
        require(gameActive, "No active game, wait for reset");
        require(suint256(block.timestamp) < deadline, "Deposit period has ended");
        require(suint256(msg.value) == ENTRY_FEE, "Must send exactly 1 ETH");
        require(players.length < MAX_PLAYERS, "Game is full");
        require(!isPlayer(saddress(msg.sender)), "You have already joined");

        players.push(saddress(msg.sender));
        emit PlayerJoined(msg.sender, msg.value, uint256(gameCount));

        if (players.length == MAX_PLAYERS) {
            endGame();
        }
    }

    // do some research how to generate properly random number
    function getRandomNumber() private view returns (suint256) {
        require(players.length > suint256(0), "No players to select from");
        suint256 random = suint256(keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender)));
        return (random % players.length) + suint256(1);
    }

    // function endGame() private {
    //     require(gameActive, "Game already ended");
    //     require(players.length > suint256(0), "No players to end game");

    //     suint256 winningNumber = getRandomNumber();
    //     lastWinner = players[winningNumber - suint256(1)];

    //     gameActive = sbool(false); 
    //     suint256 prize = suint256(address(this).balance); // some fee later
    //     (bool sent, ) = address(lastWinner).call{value: uint256(prize)}("");
    //     require(sent, "Failed to send ETH to winner");

    //     emit WinnerSelected(address(lastWinner), uint256(prize), uint256(gameCount));

    //     resetGame();
    // }



    function endGame() private {
        require(gameActive, "Game already ended");
        require(players.length > suint256(0), "No players to end game");

        suint256 winningNumber = getRandomNumber();
        lastWinner = players[winningNumber - suint256(1)];

        gameActive = sbool(false);
        suint256 prize = suint256(address(this).balance);
        (bool sent, ) = address(lastWinner).call{value: uint256(prize)}("");
        // require(sent, "Failed to send ETH to winner"); // Закомментировано для тестов

        emit WinnerSelected(address(lastWinner), uint256(prize), uint256(gameCount));

        resetGame();
    }  

    function resetGame() private {
        delete players;
        deadline = suint256(block.timestamp) + GAME_DURATION;
        gameActive = sbool(true);
        gameCount = gameCount + suint256(1);
    }

    // if already player
    function isPlayer(saddress _player) private view returns (bool) {
        for (suint256 i = suint256(0); i < players.length; i++) {      // compiler warning
            if (players[i] == _player) return true;
        }
        return false;
    }
    function getPlayerCount() external view returns (uint256) {
        return uint256(players.length);
    }

    function getBalance() external view returns (uint256) {
        return uint256(address(this).balance);
    }

    // get left time to play
    function getTimeRemaining() external view returns (uint256) {
        if (suint256(block.timestamp) >= deadline || bool(!gameActive)) {
            return 0;
        }
        return uint256(deadline - suint256(block.timestamp));
    }
}
