// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {CheckIn} from "../src/CheckIn.sol";

/// @title UpgradeScript
/// @notice Upgrades CheckIn contract to a new implementation
/// @dev Use with --keystore and --password-file flags for secure key management
/// @dev Requires PROXY_ADDRESS environment variable to be set
contract UpgradeScript is Script {
    function run() external returns (address newImplementation) {
        // Get configuration from environment
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        address deployer = msg.sender;

        console.log("Upgrading CheckIn contract...");
        console.log("Deployer:", deployer);
        console.log("Proxy:", proxyAddress);

        vm.startBroadcast();

        // Deploy new implementation
        newImplementation = address(new CheckIn());
        console.log("New implementation deployed at:", newImplementation);

        // Upgrade proxy to new implementation
        CheckIn proxy = CheckIn(proxyAddress);
        proxy.upgradeToAndCall(newImplementation, "");

        vm.stopBroadcast();

        console.log("");
        console.log("=== Upgrade Summary ===");
        console.log("Proxy:", proxyAddress);
        console.log("New Implementation:", newImplementation);
    }
}
