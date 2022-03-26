//SPDX-License-Identifier: APACHE 2.0

pragma solidity >=0.8.0 <0.9.0;
/**
 * @dev IOpenRanking is about ranking addresses of interest. 
 */
import "https://github.com/Block-Star-Logic/open-roles/blob/fc410fe170ac2d608ea53e3760c8691e3c5b550e/blockchain_ethereum/solidity/v2/contracts/interfaces/IOpenRolesManaged.sol";

import "../openblock/OpenRolesSecure.sol";
import "../openblock/IOpenRegister.sol";

import "./IOpenRanking.sol";
import "./LRankingUtilities.sol";


contract OpenRanking is IOpenRanking, OpenRolesSecure, IOpenRolesManaged {

    using LRankingUtilities for address;

     string name                         = "RESERVED_OPEN_RANKING_CORE"; 
    uint256 version                     = 1; 

    string registerCA                   = "RESERVED_OPEN_REGISTER";
    string roleManagerCA                = "RESERVED_OPEN_ROLES";

    address registryAddress; 
    IOpenRegister registry; 

    string [] roleNames; 

    mapping(string=>bool) hasDefaultFunctionsByRole;
    mapping(string=>string[]) defaultFunctionsByRole;

    mapping(string=>address[]) rankedAddressesByListName; 

     constructor(address _registryAddress) {         
       registryAddress = _registryAddress;   
        registry = IOpenRegister(_registryAddress); 
        setRoleManager(registry.getAddress(roleManagerCA));
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

    function addAddressToRank(address _address, string memory _rankingListName) override external returns (uint256 _listCount){
        address [] memory _list = rankedAddressesByListName[_rankingListName];
        rankedAddressesByListName[_rankingListName] = _address.rank(_list);
        return rankedAddressesByListName[_rankingListName].length; 
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

}