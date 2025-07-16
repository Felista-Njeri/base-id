// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

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
    
    // Record a profile view (can be called by anyone)
    function recordView(address profileOwner) external profileExists(profileOwner) {
        profiles[profileOwner].views++;
        emit ProfileViewed(msg.sender, profileOwner, block.timestamp);
    }
    
    // Check if username is available
    function isUsernameAvailable(string memory username) external view returns (bool) {
        return usernameToAddress[username] == address(0) && 
               bytes(username).length >= MIN_USERNAME_LENGTH && 
               bytes(username).length <= MAX_USERNAME_LENGTH &&
               isValidUsername(username);
    }
    
    // Get all users (paginated)
    function getUsers(uint256 offset, uint256 limit) external view returns (address[] memory) {
        require(offset < allUsers.length, "Offset out of bounds");
        
        uint256 end = offset + limit;
        if (end > allUsers.length) {
            end = allUsers.length;
        }
        
        address[] memory result = new address[](end - offset);
        for (uint256 i = offset; i < end; i++) {
            result[i - offset] = allUsers[i];
        }
        
        return result;
    }
    
    // Get leaderboard by views
    function getTopProfiles(uint256 limit) external view returns (address[] memory, uint256[] memory) {
        require(limit <= allUsers.length, "Limit too high");
        
        // Create arrays for sorting
        address[] memory addresses = new address[](allUsers.length);
        uint256[] memory views = new uint256[](allUsers.length);
        
        // Copy data
        for (uint256 i = 0; i < allUsers.length; i++) {
            addresses[i] = allUsers[i];
            views[i] = profiles[allUsers[i]].views;
        }
        
        // Simple bubble sort (not gas efficient for large arrays, but works for MVP)
        for (uint256 i = 0; i < allUsers.length - 1; i++) {
            for (uint256 j = 0; j < allUsers.length - i - 1; j++) {
                if (views[j] < views[j + 1]) {
                    // Swap views
                    uint256 tempViews = views[j];
                    views[j] = views[j + 1];
                    views[j + 1] = tempViews;
                    
                    // Swap addresses
                    address tempAddr = addresses[j];
                    addresses[j] = addresses[j + 1];
                    addresses[j + 1] = tempAddr;
                }
            }
        }
        
        // Return top profiles
        address[] memory topAddresses = new address[](limit);
        uint256[] memory topViews = new uint256[](limit);
        
        for (uint256 i = 0; i < limit; i++) {
            topAddresses[i] = addresses[i];
            topViews[i] = views[i];
        }
        
        return (topAddresses, topViews);
    }
    
    // Internal function to validate username format
    function isValidUsername(string memory username) internal pure returns (bool) {
        bytes memory usernameBytes = bytes(username);
        
        for (uint256 i = 0; i < usernameBytes.length; i++) {
            bytes1 char = usernameBytes[i];
            
            // Allow a-z, A-Z, 0-9, underscore, and hyphen
            if (!(char >= 0x30 && char <= 0x39) && // 0-9
                !(char >= 0x41 && char <= 0x5A) && // A-Z
                !(char >= 0x61 && char <= 0x7A) && // a-z
                !(char == 0x5F) && // underscore
                !(char == 0x2D)) { // hyphen
                return false;
            }
        }
        
        return true;
    }
    
    // Get contract stats
    function getStats() external view returns (uint256 totalUsers, uint256 totalViews) {
        totalUsers = totalProfiles;
        totalViews = 0;
        
        for (uint256 i = 0; i < allUsers.length; i++) {
            totalViews += profiles[allUsers[i]].views;
        }
    }
    
    // Emergency functions (only owner)
    function emergencyUpdateProfile(address user, string memory newCID) external onlyOwner {
        require(profiles[user].exists, "Profile does not exist");
        profiles[user].ipfsCID = newCID;
        profiles[user].updatedAt = block.timestamp;
    }
}