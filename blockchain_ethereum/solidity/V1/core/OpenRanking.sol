//SPDX-License-Identifier: APACHE 2.0

pragma solidity ^0.8.14;
/**
 * @dev IOpenRanking is about ranking addresses of interest. 
 */
import "https://github.com/Block-Star-Logic/open-roles/blob/732f4f476d87bece7e53bd0873076771e90da7d5/blockchain_ethereum/solidity/v2/contracts/interfaces/IOpenRolesManaged.sol";
import "https://github.com/Block-Star-Logic/open-roles/blob/732f4f476d87bece7e53bd0873076771e90da7d5/blockchain_ethereum/solidity/v2/contracts/core/OpenRolesSecureCore.sol";
import "https://github.com/Block-Star-Logic/open-register/blob/03fb07e69bfdfaa6a396a063988034de65bdab3d/blockchain_ethereum/solidity/V1/interfaces/IOpenRegister.sol";
import "https://github.com/Block-Star-Logic/open-ranking/blob/0e468d4680147bbb71c01bdeae1e799d96ff62db/blockchain_ethereum/solidity/V1/interfaces/IOpenRanking.sol";
import "https://github.com/Block-Star-Logic/open-ranking/blob/7c619870350c6c77db6603e88da7749bf9ea455f/blockchain_ethereum/solidity/V1/libraries/LRankingUtilities.sol";

contract OpenRanking is IOpenRanking, OpenRolesSecureCore, IOpenVersion,  IOpenRolesManaged {

    using LRankingUtilities for address;
    using LOpenUtilities for address; 

    string name                         = "RESERVED_OPEN_RANKING_CORE"; 
    uint256 version                     = 12; 

    string registerCA                   = "RESERVED_OPEN_REGISTER_CORE";
    string roleManagerCA                = "RESERVED_OPEN_ROLES_CORE";

    string openAdminRole                = "RESERVED_OPEN_ADMIN_ROLE";
    string dappCoreRole                 = "DAPP_CORE_ROLE"; 


    address registryAddress; 
    IOpenRegister registry; 

    string [] roleNames = [openAdminRole, dappCoreRole]; 

    mapping(string=>bool) hasDefaultFunctionsByRole;
    mapping(string=>string[]) defaultFunctionsByRole;

    mapping(string=>address[]) rankedAddressesByListName; 

    mapping(address=>string[]) listsByAddress; 
    mapping(address=>mapping(string=>bool)) onListByAddress; 
    mapping(string=>bool) knownList; 

     constructor(address _registryAddress, string memory _dappName) OpenRolesSecureCore(_dappName) {         
       registryAddress = _registryAddress;   
        registry = IOpenRegister(_registryAddress); 
        setRoleManager(registry.getAddress(roleManagerCA));
        addConfigurationItem(address(registry));
        addConfigurationItem(address(roleManager));
        initJobCryptFunctionsForRoles();
    }

    function getVersion() override view external returns (uint256 _version){
        return version; 
    }

    function getName() override view external returns (string memory _contractName){
        return name;
    }

    function getDefaultRoles() override view external returns (string [] memory _roleNames){
        return roleNames; 
    }

    function hasDefaultFunctions(string memory _role) override view external returns(bool _hasFunctions){
        return hasDefaultFunctionsByRole[_role];
    } 

    function getDefaultFunctions(string memory _role) override view external returns (string [] memory _functions){
        return defaultFunctionsByRole[_role];
    }

    function getRanking(string memory _rankingListName, uint256 _limit) override view external returns (address[] memory _rankedAddresses){
        uint256 size_ = rankedAddressesByListName[_rankingListName].length;
        if(size_ < _limit) {
            return rankedAddressesByListName[_rankingListName];
        }
        _rankedAddresses = new address[](_limit);
          address [] memory list_ = rankedAddressesByListName[_rankingListName];
        for(uint256 x = 0; x < _limit; x++){
            _rankedAddresses[x] = list_[x];
        }
        return _rankedAddresses; 
    }

    function addAddressToRank(address _address, string memory _rankingListName) override external returns (uint256 _listCount){
        require(isSecure(dappCoreRole, "addAddressToRank")," dapp core only ");  
        if(!knownList[_rankingListName]){
           rankedAddressesByListName[_rankingListName] = new address[](0);
           knownList[_rankingListName] = true; 
        }
        if(onListByAddress[_address][_rankingListName]) {
            rankedAddressesByListName[_rankingListName] = _address.remove(rankedAddressesByListName[_rankingListName]);
            delete onListByAddress[_address][_rankingListName]; 
        }
        address [] memory _list = rankedAddressesByListName[_rankingListName];   
        
        if(_list.length > 0){
            rankedAddressesByListName[_rankingListName] = _address.rank(_list);            
        }
        else {
            rankedAddressesByListName[_rankingListName].push(_address);            
        }
        listsByAddress[_address].push(_rankingListName);
        onListByAddress[_address][_rankingListName] = true; 
        return rankedAddressesByListName[_rankingListName].length; 
    }

    function removeRankedAddress(address _address) override external returns (bool _removed) {
        require(isSecure(dappCoreRole, "removeRankedAddress")," dapp core only ");
        string [] memory lists_ = listsByAddress[_address];
        for(uint256 x = 0; x < lists_.length; x++){
            string memory list_ = lists_[x];
            rankedAddressesByListName[list_] = _address.remove(rankedAddressesByListName[list_]);
            delete onListByAddress[_address][list_];
        }
        delete listsByAddress[_address];
        return true; 
    }

    function notifyChangeOfAddress() external returns (bool _recieved){
        require(isSecure(openAdminRole, "notifyChangeOfAddress")," admin only ");    
        registry                = IOpenRegister(registry.getAddress(registerCA)); // make sure this is NOT a zero address               
        roleManager             = IOpenRoles(registry.getAddress(roleManagerCA));    
        addConfigurationItem(address(registry));   
        addConfigurationItem(address(roleManager));         
        
        return true; 
    }

    // ==================================== INTERNAL =====================================================

    function initJobCryptFunctionsForRoles() internal returns (bool _initiated) {
        hasDefaultFunctionsByRole[openAdminRole] = true; 
        defaultFunctionsByRole[openAdminRole].push("notifyChangeOfAddress");
       

        hasDefaultFunctionsByRole[dappCoreRole] = true; 
        defaultFunctionsByRole[dappCoreRole].push("addAddressToRank");
        defaultFunctionsByRole[dappCoreRole].push("removeRankedAddress");  
        return true; 
    }

}