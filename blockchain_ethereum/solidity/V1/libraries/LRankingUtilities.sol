// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

import "../interfaces/IOpenRankSortable.sol";

library LRankingUtilities { 

    function rank(address a, address [] memory rankingList ) view internal returns (address [] memory _rankedList){
        
        uint256 size_ = rankingList.length + 1;
        uint256 end_ = rankingList.length - 1; 
        _rankedList = new address[](size_); 

        IOpenRankSortable sortable = IOpenRankSortable(a); 
        
        // find index
        bool shiftDown = false;       
        uint256 y = 0;
        for(uint256 x = 0; x < rankingList.length; x++ ) {
            address b = rankingList[x];
            
            if(!shiftDown) {
                int result = sortable.compare(b);            
                if(result == 1 ){ // if greater take the position                
                    _rankedList[y] = a;
                    y++;
                    shiftDown = true;               
                }
                
                if(result == 0){ // if equal 
                    _rankedList[y] = a;
                    y++;
                    shiftDown = true; 
                }
                if(result == -1){
                    // do nothing                        
                }
            }
            _rankedList[y] = b;
            y++;
            if( x == end_ && !shiftDown ){
                _rankedList[y++] = a;
            }         
        }
         return (_rankedList);       
    }

    function assignIndex(uint256 _oldIndex, uint256 _newIndex) pure internal returns (uint256 _assignedIndex){
        if(_oldIndex < _newIndex) {
            return _oldIndex; 
        }
        return _newIndex; 
    }

}