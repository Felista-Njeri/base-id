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
    
    // Modifiers
    modifier validUsername(string memory username) {
        require(bytes(username).length >= MIN_USERNAME_LENGTH, "Username too short");
        require(bytes(username).length <= MAX_USERNAME_LENGTH, "Username too long");
        require(usernameToAddress[username] == address(0), "Username already taken");
        require(isValidUsername(username), "Invalid username format");
        _;
    }
    
    modifier profileExists(address user) {
        require(profiles[user].exists, "Profile does not exist");
        _;
    }
    
    // Constructor
    constructor() Ownable(msg.sender)  {}
    
    // Create a new profile
    function createProfile(
        string memory ipfsCID,
        string memory username
    ) external validUsername(username) nonReentrant {
        require(!profiles[msg.sender].exists, "Profile already exists");
        require(bytes(ipfsCID).length > 0, "IPFS CID cannot be empty");
        
        // Create profile
        profiles[msg.sender] = Profile({
            ipfsCID: ipfsCID,
            username: username,
            createdAt: block.timestamp,
            updatedAt: block.timestamp,
            views: 0,
            exists: true
        });
        
        // Register username
        usernameToAddress[username] = msg.sender;
        addressToUsername[msg.sender] = username;
        
        // Add to users array
        allUsers.push(msg.sender);
        totalProfiles++;
        
        emit ProfileCreated(msg.sender, ipfsCID, block.timestamp);
        emit UsernameRegistered(msg.sender, username, block.timestamp);
    }
    
    // Update existing profile
    function updateProfile(string memory newIpfsCID) external profileExists(msg.sender) nonReentrant {
        require(bytes(newIpfsCID).length > 0, "IPFS CID cannot be empty");
        
        string memory oldCID = profiles[msg.sender].ipfsCID;
        profiles[msg.sender].ipfsCID = newIpfsCID;
        profiles[msg.sender].updatedAt = block.timestamp;
        
        emit ProfileUpdated(msg.sender, oldCID, newIpfsCID, block.timestamp);
    }
    
    // Get profile by address
    function getProfile(address user) external view returns (Profile memory) {
        require(profiles[user].exists, "Profile does not exist");
        return profiles[user];
    }
    
    // Get profile by username
    function getProfileByUsername(string memory username) external view returns (Profile memory) {
        address userAddress = usernameToAddress[username];
        require(userAddress != address(0), "Username not found");
        return profiles[userAddress];
    }
    
}