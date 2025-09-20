// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MyToken} from "../src/MyToken.sol";

contract DeployMyToken is Script {
    function run() external returns (address) {
        // Retrieve the private key from the environment variable.
        // This is a secure way to handle secrets.
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // It's good practice to check if the key was actually loaded.
        if (deployerPrivateKey == 0) {
            revert("PRIVATE_KEY environment variable not set. Please create a .env file.");
        }

        // The constructor for MyToken requires an `initialOwner`.
        // We will use the address of the wallet deploying the contract as the owner.
        address initialOwner = vm.addr(deployerPrivateKey);

        console.log("Deploying MyToken contract...");
        console.log("Initial Owner will be:", initialOwner);

        // Start broadcasting transactions. All subsequent contract calls will be
        // sent to the network, signed by our private key.
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the MyToken contract, passing the owner's address to the constructor.
        MyToken myToken = new MyToken(initialOwner);

        // Stop broadcasting.
        vm.stopBroadcast();

        console.log("MyToken contract deployed successfully!");
        console.log("   - Address:", address(myToken));
        console.log("   - Owner:", myToken.owner());
        
        // Return the address of the deployed contract.
        return address(myToken);
    }
}