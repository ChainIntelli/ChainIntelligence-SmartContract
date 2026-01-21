// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {CheckIn} from "../src/CheckIn.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// @title DeployScript
/// @notice Deploys CheckIn contract with UUPS proxy pattern
/// @dev Use with --keystore and --password-file flags for secure key management
contract DeployScript is Script {
    function run() external returns (address proxy, address implementation) {
        // Get deployer address from the sender (set by keystore)
        address deployer = msg.sender;

        console.log("Deploying CheckIn contract...");
        console.log("Deployer:", deployer);

        vm.startBroadcast();

        // Deploy implementation
        implementation = address(new CheckIn());
        console.log("Implementation deployed at:", implementation);

        // Deploy proxy with initialization
        bytes memory initData = abi.encodeWithSelector(CheckIn.initialize.selector, deployer);
        proxy = address(new ERC1967Proxy(implementation, initData));
        console.log("Proxy deployed at:", proxy);

        vm.stopBroadcast();

        // Verify deployment
        CheckIn checkIn = CheckIn(proxy);
        console.log("Owner:", checkIn.owner());

        console.log("");
        console.log("=== Deployment Summary ===");
        console.log("Implementation:", implementation);
        console.log("Proxy:", proxy);
        console.log("Owner:", deployer);
    }
}
