import { useEffect, useState } from "react";
import { useScaffoldContract } from "../hooks/scaffold-eth/useScaffoldContract";
import { useScaffoldReadContract } from "../hooks/scaffold-eth/useScaffoldReadContract";
import { useWalletClient } from "wagmi";
import { Address } from "~~/components/scaffold-eth";

const BIT_MASK = BigInt('0x1FFFFF'); // Mask to keep only the last 21 bits

const parseGameState = (bitState) => {
  const binaryLength = bitState.toString(2).length;
  const numGames = Math.floor((binaryLength + 20) / 21);
  const shiftAmount = BigInt((numGames) * 21);
  const maskedBitState = (bitState >> shiftAmount) & BIT_MASK; // Get the relevant 21 bits for the game
  const state = Number((maskedBitState >> 19n) & 0b11n);
  const turn = Number((maskedBitState >> 18n) & 0b1n);
  const board = [];
  for (let i = 0; i < 9; i++) {
    board.push(Number((maskedBitState >> (2n * BigInt(8 - i))) & 0b11n));
  }
  const winner = state === 1 ? 'X' : state === 2 ? 'O' : state === 3 ? 'Draw' : null;
  return { numGames, state, turn, board, winner };
};

const TicTacToe = () => {
  const { data: walletClient } = useWalletClient();
  const { data: ttt } = useScaffoldContract({
    contractName: "Tictactoe",
    walletClient,
  });
  const { data: playerOne } = useScaffoldReadContract({
    contractName: "Tictactoe",
    functionName: "player",
    args: [],
  });
  const { data: playerTwo } = useScaffoldReadContract({
    contractName: "Tictactoe",
    functionName: "botContract",
    args: [],
  });
  const { data: bitState, refetch } = useScaffoldReadContract({
    contractName: "Tictactoe",
    functionName: "getGame",
    args: [],
  });
  const [{ numGames, state, turn, board, winner }, setGame] = useState({
    numGames: 0,
    state: 0,
    turn: 0,
    board: Array(9).fill(0),
    winner: null,
  });

  useEffect(() => {
    if (bitState !== undefined) {
      setGame(parseGameState(bitState));
    }
  }, [bitState, setGame]);

  console.log(bitState)
  console.log({numGames,state, turn, board, winner })

  const handleClick = async index => {
    try {
      console.log(index)
      await ttt?.write.move([index]);
      await refetch();
    } catch (e) {
      console.error(e);
    }
  };

  const handleNewGame = async () => {
    try {
      await ttt?.write.newGame();
      await refetch();
    } catch (e) {
      console.error(e);
    }
  };

  const renderSquare = index => {
    const value = board[index] === 1 ? "X" : board[index] === 2 ? "O" : "";
    return (
      <button
        className="btn btn-outline w-24 h-24 text-3xl"
        onClick={() => handleClick(index)}
        disabled={!(turn === 0 && walletClient?.account?.address === playerOne || turn === 1 && walletClient?.account?.address === playerTwo) || value || state !== 0}
      >
        {value}
      </button>
    );
  };

  const status =
    state === 0
      ? `Next player: ${turn === 0 ? "X" : "O"}`
      : state === 1
        ? "Winner: X"
        : state === 2
          ? "Winner: O"
          : "Draw";

  return (
    <div className="flex flex-col items-center">
      <div className="my-2 flex flex-col items-center">
        <div>
          <Address address={playerOne} />
          <span>(X)</span>
        </div>
        <div>vs.</div>
        <div>
          <Address address={playerTwo} />
          <span>(O)</span>
        </div>
      </div>
      <div className="mb-2 text-2xl">Game #{numGames}</div>
      <div className="mb-4 text-2xl">{status}</div>
      <div className="grid grid-cols-3 gap-2">
        {Array.from({ length: 9 }, (_, index) => (
          <span key={index}>{renderSquare(index)}</span>
        ))}
      </div>
      <div className="mt-4">
        <button className="btn btn-primary mr-2" onClick={handleNewGame}>
          New Game
        </button>
      </div>
    </div>
  );
};

export default TicTacToe;
