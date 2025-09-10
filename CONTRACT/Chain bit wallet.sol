// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title chain bit vault
 * @dev A decentralized digital asset storage and management system
 * @author chain bit vault Team
 */
contract Project {
    
    // Struct to represent a digital asset vault
    struct BitVault {
        uint256 vaultId;
        address owner;
        uint256 balance;
        string vaultType;
        uint256 creationTime;
        bool isActive;
        uint256 lastAccessTime;
    }
    
    // Struct for vault access logs
    struct AccessLog {
        address accessor;
        uint256 timestamp;
        string action;
        uint256 amount;
    }
    
    // State variables
    address public platformOwner;
    uint256 public totalVaults;
    uint256 public totalAssetsStored;
    uint256 public constant MINIMUM_VAULT_DEPOSIT = 0.01 ether;
    mapping(uint256 => BitVault) public vaults;
    mapping(address => uint256[]) public userVaults;
    mapping(uint256 => AccessLog[]) public vaultAccessLogs;
    mapping(address => uint256) public userTotalAssets;
    
    // Events
    event VaultCreated(uint256 indexed vaultId, address indexed owner, string vaultType);
    event AssetsStored(uint256 indexed vaultId, address indexed owner, uint256 amount);
    event AssetsRetrieved(uint256 indexed vaultId, address indexed owner, uint256 amount);
    event VaultAccessed(uint256 indexed vaultId, address indexed accessor, string action);
    
    // Modifiers
    modifier onlyPlatformOwner() {
        require(msg.sender == platformOwner, "Only platform owner can execute this");
        _;
    }
    
    modifier onlyVaultOwner(uint256 _vaultId) {
        require(vaults[_vaultId].owner == msg.sender, "Only vault owner can access");
        require(vaults[_vaultId].isActive, "Vault is not active");
        _;
    }
    
    modifier validVaultId(uint256 _vaultId) {
        require(_vaultId > 0 && _vaultId <= totalVaults, "Invalid vault ID");
        _;
    }
    
    /**
     * @dev Constructor initializes the chain bit vault system
     */
    constructor() {
        platformOwner = msg.sender;
        totalVaults = 0;
        totalAssetsStored = 0;
    }
    
    /**
     * @dev Core Function 1: Create a new digital vault for storing assets
     * @param _vaultType Type of vault (e.g., "personal", "business", "savings")
     */
    function createVault(string memory _vaultType) public payable {
        require(msg.value >= MINIMUM_VAULT_DEPOSIT, "Insufficient deposit for vault creation");
        require(bytes(_vaultType).length > 0, "Vault type cannot be empty");
        
        totalVaults++;
        
        vaults[totalVaults] = BitVault({
            vaultId: totalVaults,
            owner: msg.sender,
            balance: msg.value,
            vaultType: _vaultType,
            creationTime: block.timestamp,
            isActive: true,
            lastAccessTime: block.timestamp
        });
        
        userVaults[msg.sender].push(totalVaults);
        userTotalAssets[msg.sender] += msg.value;
        totalAssetsStored += msg.value;
        
        // Log the vault creation
        vaultAccessLogs[totalVaults].push(AccessLog({
            accessor: msg.sender,
            timestamp: block.timestamp,
            action: "VAULT_CREATED",
            amount: msg.value
        }));
        
        emit VaultCreated(totalVaults, msg.sender, _vaultType);
        emit VaultAccessed(totalVaults, msg.sender, "VAULT_CREATED");
    }
    
    /**
     * @dev Core Function 2: Store additional digital assets in existing vault
     * @param _vaultId ID of the vault to store assets
     */
    function storeAssets(uint256 _vaultId) public payable onlyVaultOwner(_vaultId) validVaultId(_vaultId) {
        require(msg.value > 0, "Asset amount must be greater than zero");
        
        BitVault storage vault = vaults[_vaultId];
        vault.balance += msg.value;
        vault.lastAccessTime = block.timestamp;
        
        userTotalAssets[msg.sender] += msg.value;
        totalAssetsStored += msg.value;
        
        // Log the asset storage
        vaultAccessLogs[_vaultId].push(AccessLog({
            accessor: msg.sender,
            timestamp: block.timestamp,
            action: "ASSETS_STORED",
            amount: msg.value
        }));
        
        emit AssetsStored(_vaultId, msg.sender, msg.value);
        emit VaultAccessed(_vaultId, msg.sender, "ASSETS_STORED");
    }
    
    /**
     * @dev Core Function 3: Retrieve digital assets from vault
     * @param _vaultId ID of the vault to retrieve assets from
     * @param _amount Amount of assets to retrieve
     */
    function retrieveAssets(uint256 _vaultId, uint256 _amount) public onlyVaultOwner(_vaultId) validVaultId(_vaultId) {
        require(_amount > 0, "Retrieval amount must be greater than zero");
        
        BitVault storage vault = vaults[_vaultId];
        require(vault.balance >= _amount, "Insufficient vault balance");
        
        vault.balance -= _amount;
        vault.lastAccessTime = block.timestamp;
        
        userTotalAssets[msg.sender] -= _amount;
        totalAssetsStored -= _amount;
        
        // Log the asset retrieval
        vaultAccessLogs[_vaultId].push(AccessLog({
            accessor: msg.sender,
            timestamp: block.timestamp,
            action: "ASSETS_RETRIEVED",
            amount: _amount
        }));
        
        // Transfer assets to user
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Asset retrieval failed");
        
        emit AssetsRetrieved(_vaultId, msg.sender, _amount);
        emit VaultAccessed(_vaultId, msg.sender, "ASSETS_RETRIEVED");
    }
    
    /**
     * @dev Get detailed vault information
     * @param _vaultId ID of the vault
     * @return Vault details including balance, type, and timestamps
     */
    function getVaultDetails(uint256 _vaultId) public view validVaultId(_vaultId) returns (
        uint256 vaultId,
        address owner,
        uint256 balance,
        string memory vaultType,
        uint256 creationTime,
        bool isActive,
        uint256 lastAccessTime
    ) {
        BitVault memory vault = vaults[_vaultId];
        return (
            vault.vaultId,
            vault.owner,
            vault.balance,
            vault.vaultType,
            vault.creationTime,
            vault.isActive,
            vault.lastAccessTime
        );
    }
    
    /**
     * @dev Get all vault IDs owned by a user
     * @param _user Address of the user
     * @return Array of vault IDs
     */
    function getUserVaultIds(address _user) public view returns (uint256[] memory) {
        return userVaults[_user];
    }
    
    /**
     * @dev Get access logs for a specific vault
     * @param _vaultId ID of the vault
     * @return Array of access logs
     */
    function getVaultAccessLogs(uint256 _vaultId) public view validVaultId(_vaultId) returns (AccessLog[] memory) {
        return vaultAccessLogs[_vaultId];
    }
    
    /**
     * @dev Get platform statistics
     * @return totalVaults, totalAssetsStored, activeVaults
     */
    function getPlatformStats() public view returns (uint256, uint256, uint256) {
        uint256 activeVaults = 0;
        for (uint256 i = 1; i <= totalVaults; i++) {
            if (vaults[i].isActive) {
                activeVaults++;
            }
        }
        return (totalVaults, totalAssetsStored, activeVaults);
    }
    
    /**
     * @dev Deactivate a vault (emergency function)
     * @param _vaultId ID of the vault to deactivate
     */
    function deactivateVault(uint256 _vaultId) public onlyVaultOwner(_vaultId) validVaultId(_vaultId) {
        BitVault storage vault = vaults[_vaultId];
        require(vault.balance == 0, "Cannot deactivate vault with remaining balance");
        
        vault.isActive = false;
        vault.lastAccessTime = block.timestamp;
        
        // Log the deactivation
        vaultAccessLogs[_vaultId].push(AccessLog({
            accessor: msg.sender,
            timestamp: block.timestamp,
            action: "VAULT_DEACTIVATED",
            amount: 0
        }));
        
        emit VaultAccessed(_vaultId, msg.sender, "VAULT_DEACTIVATED");
    }
    
    /**
     * @dev Get user's total assets across all vaults
     * @param _user Address of the user
     * @return Total assets owned by the user
     */
    function getUserTotalAssets(address _user) public view returns (uint256) {
        return userTotalAssets[_user];
    }
    
    /**
     * @dev Emergency withdrawal function (platform owner only)
     * @param _vaultId ID of the vault
     */
    function emergencyWithdraw(uint256 _vaultId) public onlyPlatformOwner validVaultId(_vaultId) {
        BitVault storage vault = vaults[_vaultId];
        uint256 amount = vault.balance;
        
        require(amount > 0, "Vault has no balance");
        
        vault.balance = 0;
        vault.isActive = false;
        userTotalAssets[vault.owner] -= amount;
        totalAssetsStored -= amount;
        
        // Log the emergency withdrawal
        vaultAccessLogs[_vaultId].push(AccessLog({
            accessor: msg.sender,
            timestamp: block.timestamp,
            action: "EMERGENCY_WITHDRAWAL",
            amount: amount
        }));
        
        // Transfer to vault owner
        (bool success, ) = payable(vault.owner).call{value: amount}("");
        require(success, "Emergency withdrawal failed");
        
        emit VaultAccessed(_vaultId, msg.sender, "EMERGENCY_WITHDRAWAL");
    }
    
    /**
     * @dev Receive function to handle direct ETH transfers
     */
    receive() external payable {
        // Auto-create a vault for direct deposits
        if (msg.value >= MINIMUM_VAULT_DEPOSIT) {
            createVault("auto-created");
        }
    }
    
    /**
     * @dev Fallback function
     */
    fallback() external payable {
        revert("Function not supported");
    }
}
