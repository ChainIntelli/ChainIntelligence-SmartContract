// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ICheckIn} from "./interfaces/ICheckIn.sol";

/// @title CheckIn
/// @notice A contract for users to check in on-chain
/// @dev Implements UUPS upgradeable pattern with security features
contract CheckIn is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuard,
    ICheckIn
{
    /// @notice Mapping of user address to check-in count
    mapping(address => uint256) public checkInCounts;

    /// @notice Mapping of user address to last check-in timestamp
    mapping(address => uint256) public lastCheckInTime;

    /// @dev Reserved storage slots for future upgrades
    uint256[48] private __gap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize the contract
    /// @param owner_ The address of the contract owner
    function initialize(address owner_) external initializer {
        __Ownable_init(owner_);
        __Pausable_init();
    }

    /// @notice Perform a check-in
    /// @dev Protected against reentrancy, requires not paused, prevents same-block replay
    function checkIn() external nonReentrant whenNotPaused {
        // Prevent replay attack: cannot check in twice in the same block
        require(
            lastCheckInTime[msg.sender] < block.timestamp,
            "CheckIn: already checked in this block"
        );

        // Update state (Checks-Effects-Interactions pattern)
        checkInCounts[msg.sender] += 1;
        lastCheckInTime[msg.sender] = block.timestamp;

        // Emit event for off-chain tracking
        emit CheckedIn(
            msg.sender,
            block.timestamp,
            checkInCounts[msg.sender],
            block.number
        );
    }

    /// @notice Get the check-in count for a user
    /// @param user The address of the user
    /// @return The number of times the user has checked in
    function getCheckInCount(address user) external view returns (uint256) {
        return checkInCounts[user];
    }

    /// @notice Get the last check-in time for a user
    /// @param user The address of the user
    /// @return The timestamp of the user's last check-in
    function getLastCheckInTime(address user) external view returns (uint256) {
        return lastCheckInTime[user];
    }

    /// @notice Get complete user info
    /// @param user The address of the user
    /// @return count The number of check-ins
    /// @return lastTime The timestamp of the last check-in
    function getUserInfo(address user) external view returns (uint256 count, uint256 lastTime) {
        count = checkInCounts[user];
        lastTime = lastCheckInTime[user];
    }

    /// @notice Pause the contract
    /// @dev Only callable by owner
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause the contract
    /// @dev Only callable by owner
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Authorize upgrade to new implementation
    /// @dev Only callable by owner
    /// @param newImplementation Address of new implementation contract
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
