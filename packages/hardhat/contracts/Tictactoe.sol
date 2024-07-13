// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBotContract {
    function makeMove(uint256 move) external returns (uint256);
}

contract Tictactoe {

    uint256 gameBoard = 0;

    uint256 internal constant HORIZONTAL_MASK = 0x3F;
    uint256 internal constant VERTICAL_MASK = 0x30C3;
    uint256 internal constant BR_TO_TL_DIAGONAL_MASK = 0x30303;
    uint256 internal constant BL_TO_TR_DIAGONAL_MASK = 0x3330;

    address public player;
    address public botContract;

    IBotContract internal bot;

    constructor(address _botContract) {
        require(_botContract != address(0), "Invalid AI contract address");
        botContract = _botContract;
        bot = IBotContract(_botContract);
        player = msg.sender;
    }

    modifier moveIsValid(uint256 _move) {
        uint p1 = _move << 1;
        uint p2 = p1 + 1;
        uint _gameBoard = gameBoard;

        require(!(((_gameBoard >> p1) & 1) == 1 || ((_gameBoard >> p2) & 1) == 1), "Invalid move");
        require(_move < 9, "Invalid move");
        _;
    }

    function newGame() external returns (uint256) {
        uint256 _gameBoard = gameBoard;

        if (_gameBoard > 0) {
            _gameBoard = _gameBoard << 21 | 1 << 20;
        } else {
            _gameBoard = _gameBoard | 1 << 20;
        }

        gameBoard = _gameBoard;
        return _gameBoard;
    }

    function getGame() external view returns (uint256) {
        return gameBoard;
    }

    function move(uint256 _move) moveIsValid(_move) external returns (uint256) {
        require(msg.sender == player, "Only player can make a move");
        uint256 _gameBoard = gameBoard;
        
        require(_gameBoard >> 19 & 1 == 0 && _gameBoard >> 20 & 1 == 1, "Game has ended");

        _gameBoard = _gameBoard ^ (1 << (_move << 1));
        gameBoard = _gameBoard ^ (1 << 18);

        uint256 gameState = checkState(0);

        if (gameState == 1) {
            gameBoard = gameBoard ^ (1 << 19); 
            return 1;
        } else if (gameState == 2) {
            return 2; // Draw
        }

        uint256 aiMove = bot.makeMove(gameBoard);
        require(aiMove < 9, "Invalid AI move");
        
        _gameBoard = gameBoard ^ (1 << ((aiMove << 1) + 1));
        gameBoard = _gameBoard ^ (1 << 18);

        gameState = checkState(1);

        if (gameState == 1) {
            gameBoard = gameBoard ^ (1 << 20);
            return 1;
        } else if (gameState == 2) {
            return 2;
        }

        return 0;
    }
    
    function checkState(uint _playerId) public view returns (uint256) {
        uint256 _gameBoard = gameBoard;

        if ((_gameBoard & HORIZONTAL_MASK) == ((HORIZONTAL_MASK / 3) << _playerId)) {
            return 1;
        } else if ((_gameBoard & (HORIZONTAL_MASK << 6)) == ((HORIZONTAL_MASK / 3) << _playerId) << 6) {
            return 1;
        } else if ((_gameBoard & (HORIZONTAL_MASK << 12)) == ((HORIZONTAL_MASK / 3) << _playerId) << 12) {
            return 1;
        }

        if ((_gameBoard & VERTICAL_MASK) == (VERTICAL_MASK / 3) << _playerId) {
            return 1;
        } else if ((_gameBoard & (VERTICAL_MASK << 2)) == (VERTICAL_MASK / 3) << _playerId << 2) {
            return 1;
        } else if ((_gameBoard & (VERTICAL_MASK << 4)) == (VERTICAL_MASK / 3) << _playerId << 4) {
            return 1;
        }

        if ((_gameBoard & BR_TO_TL_DIAGONAL_MASK) == (BR_TO_TL_DIAGONAL_MASK / 3) << _playerId) {
            return 1;
        }

        if ((_gameBoard & BL_TO_TR_DIAGONAL_MASK) == (BL_TO_TR_DIAGONAL_MASK / 3) << _playerId) {
            return 1;
        }

        unchecked {
            for (uint x = 0; x < 9; x++) {
                if (_gameBoard & 1 == 0 && _gameBoard & 2 == 0)  {
                    return 0;
                } 
                _gameBoard = _gameBoard >> 2;
            }

            return 2;
        }
    }
}