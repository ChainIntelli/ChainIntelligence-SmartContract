// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console} from "forge-std/Test.sol";
import {CheckIn} from "../src/CheckIn.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract CheckInGasTest is Test {
    CheckIn public implementation;
    CheckIn public checkIn;
    ERC1967Proxy public proxy;

    address public owner;
    address[] public users;

    function setUp() public {
        owner = makeAddr("owner");

        // Create multiple test users
        for (uint256 i = 0; i < 100; i++) {
            users.push(makeAddr(string(abi.encodePacked("user", i))));
        }

        // Deploy implementation
        implementation = new CheckIn();

        // Deploy proxy and initialize
        bytes memory initData = abi.encodeWithSelector(CheckIn.initialize.selector, owner);
        proxy = new ERC1967Proxy(address(implementation), initData);

        // Cast proxy to CheckIn interface
        checkIn = CheckIn(address(proxy));
    }

    // ==================== Gas Measurement Tests ====================

    function test_Gas_FirstCheckIn() public {
        address user = users[0];

        vm.prank(user);
        uint256 gasBefore = gasleft();
        checkIn.checkIn();
        uint256 gasAfter = gasleft();

        uint256 gasUsed = gasBefore - gasAfter;
        console.log("Gas used for first check-in:", gasUsed);

        // First check-in writes to two storage slots (from 0 to non-0), so it's more expensive
        // Gas varies based on Foundry settings (~80,000-110,000 with proxy overhead)
        assertTrue(gasUsed > 40_000, "Gas too low for first check-in");
        assertTrue(gasUsed < 150_000, "Gas too high for first check-in");
    }

    function test_Gas_SecondCheckIn() public {
        address user = users[0];

        // First check-in
        vm.prank(user);
        checkIn.checkIn();

        // Warp time
        vm.warp(block.timestamp + 1);

        // Second check-in (updates existing storage slots)
        vm.prank(user);
        uint256 gasBefore = gasleft();
        checkIn.checkIn();
        uint256 gasAfter = gasleft();

        uint256 gasUsed = gasBefore - gasAfter;
        console.log("Gas used for second check-in:", gasUsed);

        // Subsequent check-ins only update existing slots (non-0 to non-0)
        // With warm storage slots, gas is much lower (~4,000-10,000)
        assertTrue(gasUsed > 2_000, "Gas too low for second check-in");
        assertTrue(gasUsed < 60_000, "Gas too high for second check-in");
    }

    function test_Gas_GetCheckInCount() public {
        address user = users[0];

        // Do a check-in first
        vm.prank(user);
        checkIn.checkIn();

        // Measure gas for view function
        uint256 gasBefore = gasleft();
        checkIn.getCheckInCount(user);
        uint256 gasAfter = gasleft();

        uint256 gasUsed = gasBefore - gasAfter;
        console.log("Gas used for getCheckInCount:", gasUsed);

        // View functions through proxy have overhead (~2,000-10,000 gas)
        assertTrue(gasUsed < 15_000, "Gas too high for view function");
    }

    function test_Gas_GetUserInfo() public {
        address user = users[0];

        // Do a check-in first
        vm.prank(user);
        checkIn.checkIn();

        // Measure gas for view function
        uint256 gasBefore = gasleft();
        checkIn.getUserInfo(user);
        uint256 gasAfter = gasleft();

        uint256 gasUsed = gasBefore - gasAfter;
        console.log("Gas used for getUserInfo:", gasUsed);

        // View functions through proxy have overhead (~2,000-15,000 gas)
        assertTrue(gasUsed < 20_000, "Gas too high for view function");
    }

    // ==================== Multi-User Gas Tests ====================

    function test_Gas_MultipleUsersCheckIn() public {
        uint256 numUsers = 10;
        uint256 totalGas = 0;

        console.log("=== Multiple Users Check-in Gas Report ===");

        for (uint256 i = 0; i < numUsers; i++) {
            address user = users[i];

            vm.prank(user);
            uint256 gasBefore = gasleft();
            checkIn.checkIn();
            uint256 gasAfter = gasleft();

            uint256 gasUsed = gasBefore - gasAfter;
            totalGas += gasUsed;

            console.log("User", i, "gas used:", gasUsed);
        }

        console.log("Total gas for", numUsers, "users:", totalGas);
        console.log("Average gas per user:", totalGas / numUsers);
    }

    function test_Gas_SingleUserMultipleCheckIns() public {
        address user = users[0];
        uint256 numCheckIns = 10;
        uint256 totalGas = 0;

        console.log("=== Single User Multiple Check-ins Gas Report ===");

        for (uint256 i = 0; i < numCheckIns; i++) {
            vm.warp(block.timestamp + 1);

            vm.prank(user);
            uint256 gasBefore = gasleft();
            checkIn.checkIn();
            uint256 gasAfter = gasleft();

            uint256 gasUsed = gasBefore - gasAfter;
            totalGas += gasUsed;

            console.log("Check-in", i + 1, "gas used:", gasUsed);
        }

        console.log("Total gas for", numCheckIns, "check-ins:", totalGas);
        console.log("Average gas per check-in:", totalGas / numCheckIns);
    }

    // ==================== Gas Snapshot Tests (for comparison) ====================

    function test_Gas_Snapshot_FirstCheckIn() public {
        address user = users[0];
        vm.prank(user);
        checkIn.checkIn();

        // This test is mainly for `forge snapshot` to track gas changes over time
        assertEq(checkIn.getCheckInCount(user), 1);
    }

    function test_Gas_Snapshot_SecondCheckIn() public {
        address user = users[0];

        vm.prank(user);
        checkIn.checkIn();

        vm.warp(block.timestamp + 1);

        vm.prank(user);
        checkIn.checkIn();

        assertEq(checkIn.getCheckInCount(user), 2);
    }

    function test_Gas_Snapshot_TenthCheckIn() public {
        address user = users[0];

        for (uint256 i = 0; i < 10; i++) {
            vm.warp(block.timestamp + 1);
            vm.prank(user);
            checkIn.checkIn();
        }

        assertEq(checkIn.getCheckInCount(user), 10);
    }

    // ==================== Gas Comparison: First vs Subsequent ====================

    function test_Gas_CompareFirstVsSubsequent() public {
        address user = users[0];

        // First check-in
        vm.prank(user);
        uint256 gas1Before = gasleft();
        checkIn.checkIn();
        uint256 gas1After = gasleft();
        uint256 firstCheckInGas = gas1Before - gas1After;

        vm.warp(block.timestamp + 1);

        // Second check-in
        vm.prank(user);
        uint256 gas2Before = gasleft();
        checkIn.checkIn();
        uint256 gas2After = gasleft();
        uint256 secondCheckInGas = gas2Before - gas2After;

        console.log("=== First vs Subsequent Check-in Comparison ===");
        console.log("First check-in gas:", firstCheckInGas);
        console.log("Second check-in gas:", secondCheckInGas);
        console.log("Gas savings on subsequent:", firstCheckInGas - secondCheckInGas);
        console.log(
            "Percentage savings:",
            ((firstCheckInGas - secondCheckInGas) * 100) / firstCheckInGas,
            "%"
        );

        // Subsequent check-ins should be cheaper
        assertTrue(secondCheckInGas < firstCheckInGas, "Subsequent check-in should be cheaper");
    }
}
