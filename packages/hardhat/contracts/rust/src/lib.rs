#![cfg_attr(target_arch = "wasm32", no_std)]
extern crate alloc;
extern crate fluentbase_sdk;

use alloc::vec::Vec;
use rand::{Rng, SeedableRng};
use rand::rngs::SmallRng;
use fluentbase_sdk::{
    basic_entrypoint,
    derive::{router, signature},
    SharedAPI,
    U256,
};

#[derive(Default)]
struct ROUTER;

pub trait RouterAPI {
    fn make_move<SDK: SharedAPI>(&self, board: U256) -> U256;
}

#[router(mode = "solidity")]
impl RouterAPI for ROUTER {
    #[signature("function makeMove(uint256 board) external returns (uint256)")]
    fn make_move<SDK: SharedAPI>(&self, board: U256) -> U256 {
        let mut available_moves = Vec::new();
        
        // Check each of the 9 positions (0-8)
        for i in 0..9 {
            // If the position is empty (0), add it to available moves
            if (board & U256::from(3u8) << (i * 2)) == U256::from(0) {
                available_moves.push(i);
            }
        }
        
        if available_moves.is_empty() {
            return U256::MAX;
        }
        
        let mut rng = SmallRng::seed_from_u64(42);
        let random_number: u64 = rng.gen();

        // Select a random move from available moves
        let random_index = random_number % available_moves.len() as u64;
        U256::from(available_moves[random_index as usize])
    }
}

impl ROUTER {
    fn deploy<SDK: SharedAPI>(&self) {
        // any custom deployment logic here
    }
}

basic_entrypoint!(ROUTER);

