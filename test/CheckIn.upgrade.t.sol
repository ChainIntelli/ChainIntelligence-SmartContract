// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console} from "forge-std/Test.sol";
import {CheckIn} from "../src/CheckIn.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

/// @title CheckInV2
/// @notice Mock V2 contract for testing upgrades
contract CheckInV2 is CheckIn {
    /// @notice New storage variable in V2
    uint256 public totalGlobalCheckIns;

    /// @notice New function in V2
    function checkInV2() external nonReentrant whenNotPaused {
        require(
            lastCheckInTime[msg.sender] < block.timestamp,
            "CheckIn: already checked in this block"
        );

        checkInCounts[msg.sender] += 1;
        lastCheckInTime[msg.sender] = block.timestamp;
        totalGlobalCheckIns += 1;

        emit CheckedIn(
            msg.sender,
            block.timestamp,
            checkInCounts[msg.sender],
            block.number
        );
    }

    /// @notice Get the contract version
    function version() external pure returns (string memory) {
        return "2.0.0";
    }
}

contract CheckInUpgradeTest is Test {
    CheckIn public implementation;
    CheckIn public checkIn;
    ERC1967Proxy public proxy;

    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        // Deploy implementation
        implementation = new CheckIn();

        // Deploy proxy and initialize
        bytes memory initData = abi.encodeWithSelector(CheckIn.initialize.selector, owner);
        proxy = new ERC1967Proxy(address(implementation), initData);

        // Cast proxy to CheckIn interface
        checkIn = CheckIn(address(proxy));
    }

    // ==================== Upgrade Authorization Tests ====================

    function test_Upgrade_OnlyOwner() public {
        CheckInV2 newImpl = new CheckInV2();

        vm.prank(user1);
        vm.expectRevert();
        checkIn.upgradeToAndCall(address(newImpl), "");
    }

    function test_Upgrade_OwnerCanUpgrade() public {
        CheckInV2 newImpl = new CheckInV2();

        vm.prank(owner);
        checkIn.upgradeToAndCall(address(newImpl), "");

        // Verify upgrade was successful by calling new function
        CheckInV2 checkInV2 = CheckInV2(address(proxy));
        assertEq(checkInV2.version(), "2.0.0");
    }

    // ==================== State Preservation Tests ====================

    function test_Upgrade_PreservesState() public {
        // User checks in before upgrade
        vm.prank(user1);
        checkIn.checkIn();

        vm.warp(block.timestamp + 1);

        vm.prank(user1);
        checkIn.checkIn();

        assertEq(checkIn.getCheckInCount(user1), 2);
        uint256 lastTimeBeforeUpgrade = checkIn.getLastCheckInTime(user1);

        // Perform upgrade
        CheckInV2 newImpl = new CheckInV2();
        vm.prank(owner);
        checkIn.upgradeToAndCall(address(newImpl), "");

        // Verify state is preserved
        CheckInV2 checkInV2 = CheckInV2(address(proxy));
        assertEq(checkInV2.getCheckInCount(user1), 2);
        assertEq(checkInV2.getLastCheckInTime(user1), lastTimeBeforeUpgrade);
    }

    function test_Upgrade_PreservesOwner() public {
        CheckInV2 newImpl = new CheckInV2();
        vm.prank(owner);
        checkIn.upgradeToAndCall(address(newImpl), "");

        CheckInV2 checkInV2 = CheckInV2(address(proxy));
        assertEq(checkInV2.owner(), owner);
    }

    function test_Upgrade_PreservesPausedState() public {
        // Pause the contract
        vm.prank(owner);
        checkIn.pause();

        // Upgrade
        CheckInV2 newImpl = new CheckInV2();
        vm.prank(owner);
        checkIn.upgradeToAndCall(address(newImpl), "");

        // Verify still paused
        CheckInV2 checkInV2 = CheckInV2(address(proxy));
        assertTrue(checkInV2.paused());
    }

    // ==================== New Functionality Tests ====================

    function test_Upgrade_NewFunctionWorks() public {
        // Upgrade
        CheckInV2 newImpl = new CheckInV2();
        vm.prank(owner);
        checkIn.upgradeToAndCall(address(newImpl), "");

        CheckInV2 checkInV2 = CheckInV2(address(proxy));

        // Use new V2 function
        vm.prank(user1);
        checkInV2.checkInV2();

        assertEq(checkInV2.getCheckInCount(user1), 1);
        assertEq(checkInV2.totalGlobalCheckIns(), 1);

        // Another user
        vm.prank(user2);
        checkInV2.checkInV2();

        assertEq(checkInV2.totalGlobalCheckIns(), 2);
    }

    function test_Upgrade_OldFunctionStillWorks() public {
        // Upgrade
        CheckInV2 newImpl = new CheckInV2();
        vm.prank(owner);
        checkIn.upgradeToAndCall(address(newImpl), "");

        CheckInV2 checkInV2 = CheckInV2(address(proxy));

        // Old checkIn function should still work
        vm.prank(user1);
        checkInV2.checkIn();

        assertEq(checkInV2.getCheckInCount(user1), 1);
        // Note: Old function doesn't increment totalGlobalCheckIns
        assertEq(checkInV2.totalGlobalCheckIns(), 0);
    }

    // ==================== Multiple Upgrades Test ====================

    function test_Upgrade_MultipleUpgrades() public {
        // First upgrade
        CheckInV2 v2Impl = new CheckInV2();
        vm.prank(owner);
        checkIn.upgradeToAndCall(address(v2Impl), "");

        // User checks in with V2
        CheckInV2 checkInV2 = CheckInV2(address(proxy));
        vm.prank(user1);
        checkInV2.checkInV2();

        // Second upgrade (back to V1 for testing, in practice would be V3)
        CheckIn v3Impl = new CheckIn();
        vm.prank(owner);
        checkInV2.upgradeToAndCall(address(v3Impl), "");

        // State should still be preserved
        assertEq(checkIn.getCheckInCount(user1), 1);
    }
}
