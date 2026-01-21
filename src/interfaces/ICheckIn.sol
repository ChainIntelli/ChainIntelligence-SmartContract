// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @title ICheckIn
/// @notice Interface for the CheckIn contract
interface ICheckIn {
    /// @notice Emitted when a user checks in
    /// @param user The address of the user who checked in
    /// @param timestamp The timestamp of the check-in
    /// @param totalCount The total number of check-ins for this user
    /// @param blockNumber The block number when the check-in occurred
    event CheckedIn(
        address indexed user,
        uint256 timestamp,
        uint256 totalCount,
        uint256 blockNumber
    );

    /// @notice Perform a check-in
    function checkIn() external;

    /// @notice Get the check-in count for a user
    /// @param user The address of the user
    /// @return The number of times the user has checked in
    function getCheckInCount(address user) external view returns (uint256);

    /// @notice Get the last check-in time for a user
    /// @param user The address of the user
    /// @return The timestamp of the user's last check-in
    function getLastCheckInTime(address user) external view returns (uint256);

    /// @notice Get complete user info
    /// @param user The address of the user
    /// @return count The number of check-ins
    /// @return lastTime The timestamp of the last check-in
    function getUserInfo(address user) external view returns (uint256 count, uint256 lastTime);
}
