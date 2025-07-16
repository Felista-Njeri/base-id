// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BaseLinktree is Ownable, ReentrancyGuard {
    // Events
    event ProfileCreated(address indexed user, string ipfsCID, uint256 timestamp);
    event ProfileUpdated(address indexed user, string oldCID, string newCID, uint256 timestamp);
    event UsernameRegistered(address indexed user, string username, uint256 timestamp);
    event ProfileViewed(address indexed viewer, address indexed profileOwner, uint256 timestamp);
    
    // Structs
    struct Profile {
        string ipfsCID;
        string username;
        uint256 createdAt;
        uint256 updatedAt;
        uint256 views;
        bool exists;
    }
    
    // State variables
    mapping(address => Profile) public profiles;
    mapping(string => address) public usernameToAddress;
    mapping(address => string) public addressToUsername;
    
    address[] public allUsers;
    uint256 public totalProfiles;
    uint256 public constant MAX_USERNAME_LENGTH = 20;
    uint256 public constant MIN_USERNAME_LENGTH = 3;

}