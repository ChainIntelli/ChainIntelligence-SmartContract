// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console} from "forge-std/Test.sol";
import {CheckIn} from "../src/CheckIn.sol";
import {ICheckIn} from "../src/interfaces/ICheckIn.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract CheckInTest is Test {
    CheckIn public implementation;
    CheckIn public checkIn;
    ERC1967Proxy public proxy;

    address public owner;
    address public user1;
    address public user2;
    address public user3;

    event CheckedIn(
        address indexed user,
        uint256 timestamp,
        uint256 totalCount,
        uint256 blockNumber
    );

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");

        // Deploy implementation
        implementation = new CheckIn();

        // Deploy proxy and initialize
        bytes memory initData = abi.encodeWithSelector(CheckIn.initialize.selector, owner);
        proxy = new ERC1967Proxy(address(implementation), initData);

        // Cast proxy to CheckIn interface
        checkIn = CheckIn(address(proxy));
    }

    // ==================== Initialization Tests ====================

    function test_Initialize_SetsOwner() public view {
        assertEq(checkIn.owner(), owner);
    }

    function test_Initialize_CannotReinitialize() public {
        vm.expectRevert();
        checkIn.initialize(user1);
    }

    function test_Initialize_ImplementationCannotBeInitialized() public {
        vm.expectRevert();
        implementation.initialize(user1);
    }

    // ==================== CheckIn Tests ====================

    function test_CheckIn_FirstCheckIn() public {
        vm.prank(user1);
        checkIn.checkIn();

        assertEq(checkIn.getCheckInCount(user1), 1);
        assertEq(checkIn.getLastCheckInTime(user1), block.timestamp);
    }

    function test_CheckIn_MultipleCheckIns() public {
        // First check-in
        vm.prank(user1);
        checkIn.checkIn();
        assertEq(checkIn.getCheckInCount(user1), 1);

        // Warp time to next block
        vm.warp(block.timestamp + 1);

        // Second check-in
        vm.prank(user1);
        checkIn.checkIn();
        assertEq(checkIn.getCheckInCount(user1), 2);

        // Warp time again
        vm.warp(block.timestamp + 1);

        // Third check-in
        vm.prank(user1);
        checkIn.checkIn();
        assertEq(checkIn.getCheckInCount(user1), 3);
    }

    function test_CheckIn_EmitsEvent() public {
        vm.prank(user1);

        vm.expectEmit(true, false, false, true);
        emit CheckedIn(user1, block.timestamp, 1, block.number);

        checkIn.checkIn();
    }

    function test_CheckIn_MultipleUsers() public {
        // User1 checks in
        vm.prank(user1);
        checkIn.checkIn();

        // User2 checks in
        vm.prank(user2);
        checkIn.checkIn();

        // User3 checks in
        vm.prank(user3);
        checkIn.checkIn();

        assertEq(checkIn.getCheckInCount(user1), 1);
        assertEq(checkIn.getCheckInCount(user2), 1);
        assertEq(checkIn.getCheckInCount(user3), 1);
    }

    function test_CheckIn_GetUserInfo() public {
        vm.prank(user1);
        checkIn.checkIn();

        (uint256 count, uint256 lastTime) = checkIn.getUserInfo(user1);
        assertEq(count, 1);
        assertEq(lastTime, block.timestamp);
    }

    // ==================== Security Tests ====================

    function test_CheckIn_RevertsSameBlock() public {
        vm.startPrank(user1);
        checkIn.checkIn();

        // Try to check in again in the same block (same timestamp)
        vm.expectRevert("CheckIn: already checked in this block");
        checkIn.checkIn();
        vm.stopPrank();
    }

    function test_CheckIn_RevertsWhenPaused() public {
        // Owner pauses the contract
        vm.prank(owner);
        checkIn.pause();

        // User tries to check in
        vm.prank(user1);
        vm.expectRevert();
        checkIn.checkIn();
    }

    function test_CheckIn_WorksAfterUnpause() public {
        // Owner pauses the contract
        vm.prank(owner);
        checkIn.pause();

        // Owner unpauses the contract
        vm.prank(owner);
        checkIn.unpause();

        // User can check in
        vm.prank(user1);
        checkIn.checkIn();
        assertEq(checkIn.getCheckInCount(user1), 1);
    }

    // ==================== Access Control Tests ====================

    function test_Pause_OnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        checkIn.pause();
    }

    function test_Unpause_OnlyOwner() public {
        vm.prank(owner);
        checkIn.pause();

        vm.prank(user1);
        vm.expectRevert();
        checkIn.unpause();
    }

    // ==================== View Function Tests ====================

    function test_GetCheckInCount_ReturnsZeroForNewUser() public view {
        assertEq(checkIn.getCheckInCount(user1), 0);
    }

    function test_GetLastCheckInTime_ReturnsZeroForNewUser() public view {
        assertEq(checkIn.getLastCheckInTime(user1), 0);
    }

    function test_GetUserInfo_ReturnsZerosForNewUser() public view {
        (uint256 count, uint256 lastTime) = checkIn.getUserInfo(user1);
        assertEq(count, 0);
        assertEq(lastTime, 0);
    }

    // ==================== Fuzz Tests ====================

    function testFuzz_CheckIn_MultipleCheckIns(uint8 numCheckIns) public {
        vm.assume(numCheckIns > 0 && numCheckIns <= 100);

        for (uint8 i = 0; i < numCheckIns; i++) {
            vm.warp(block.timestamp + 1);
            vm.prank(user1);
            checkIn.checkIn();
        }

        assertEq(checkIn.getCheckInCount(user1), numCheckIns);
    }

    function testFuzz_CheckIn_DifferentUsers(address[] memory users) public {
        vm.assume(users.length > 0 && users.length <= 50);

        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            // Skip zero address and precompiles
            if (user == address(0) || uint160(user) < 10) continue;
            // Skip if user already checked in (avoid same-block duplicate)
            if (checkIn.getCheckInCount(user) > 0) continue;

            vm.prank(user);
            checkIn.checkIn();
        }
    }
}
