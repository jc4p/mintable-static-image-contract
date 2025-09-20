# Mintable Static Image Contract

Simple ERC‑721 NFT contract with a fixed mint price and a single static IPFS token URI returned for every token. Payments are held in the contract; the owner must call `withdraw()` to collect funds.

## Features

- ERC‑721 standard compliant (OpenZeppelin Contracts v5)
- Public mint with fixed price: 0.0005 ETH
- Funds accrue in the contract; owner withdraws via `withdraw()`
- Single static token URI for all tokens (constant IPFS CID)

## Prerequisites

- Git
- Foundry (forge, cast, anvil): https://getfoundry.sh/
- An Ethereum RPC URL (Base, another network, or local Anvil)
- A wallet private key for deployment/transactions

## Installation

```shell
git clone https://github.com/jc4p/mintable-static-image-contract.git
cd mintable-static-image-contract
forge install
forge build
```

## Configuration

Create a `.env` file at the repo root:

```
RPC_URL=https://mainnet.base.org
PRIVATE_KEY=your_private_key_without_0x_prefix
```

Source it when needed:

```shell
source .env
```

### Set Your Static IPFS URI

Every token’s `tokenURI(tokenId)` returns the same IPFS URI. Update the constant in the contract:

- Edit `src/MyToken.sol` and set the `TOKEN_DATA_URI` to your IPFS CID, e.g.

```solidity
string private constant TOKEN_DATA_URI = "ipfs://<YOUR_CID_HERE>";
```

Notes:
- This project does not concatenate a token ID; it returns exactly the provided string for all tokens.
- Ensure the content at that CID is what your dApp/wallet expects (image or JSON metadata).

### Optional: Change Mint Price

Edit `src/MyToken.sol` if you want a different price:

```solidity
uint256 public constant MINT_PRICE = 0.0005 ether;
```

## Testing

```shell
forge test -vv
```

## Deployment

Dry‑run (simulate):

```shell
forge script script/MyToken.sol:DeployMyToken \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY
```

Broadcast (deploy):

```shell
forge script script/MyToken.sol:DeployMyToken \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast
```

Find the deployed address in the script output or the `broadcast` folder:

```shell
cat broadcast/MyToken.sol/*/run-latest.json | grep -A1 '"contractAddress"'
```

## Contract Verification (Basescan example)

Get an API key at https://basescan.org/ and add to `.env`:

```
BASESCAN_API_KEY=your_api_key_here
```

Verify (Base mainnet chain id 8453, compiler v0.8.28 as used by this repo):

```shell
forge verify-contract \
  --chain-id 8453 \
  --watch \
  --compiler-version 0.8.28 \
  $CONTRACT_ADDRESS \
  src/MyToken.sol:MyToken \
  --etherscan-api-key $BASESCAN_API_KEY
```

## Interacting with the Contract (cast)

Set your variables:

```shell
export CONTRACT=<deployed_contract_address>
unset TO # not needed for mint()
```

- Read the mint price (wei):

```shell
cast call $CONTRACT "MINT_PRICE()(uint256)" --rpc-url $RPC_URL
```

- Mint an NFT (public): requires exact payment of 0.0005 ETH; token IDs auto‑increment from 1.

```shell
cast send $CONTRACT "mint()" \
  --value 0.0005ether \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY
```

- Check ownership of a token:

```shell
cast call $CONTRACT "ownerOf(uint256)(address)" 1 --rpc-url $RPC_URL
```

- Read the token URI (same for all tokens; reverts if token does not exist):

```shell
cast call $CONTRACT "tokenURI(uint256)(string)" 1 --rpc-url $RPC_URL
```

- Check the contract’s ETH balance:

```shell
cast balance $CONTRACT --rpc-url $RPC_URL
```

- Withdraw funds (owner only): sends the entire contract balance to the owner.

```shell
cast send $CONTRACT "withdraw()" \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY
```

## Notes & Tips

- Takes ETH directly, can be modified to take USDC or any coin.
- There is no supply cap; add one if you need it.
- `tokenURI` is identical for all tokens.
- To change price or URI after deployment, you would need to redeploy.

## License

MIT
