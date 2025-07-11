// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";

contract NFTReceiver is IERC721Receiver {
    event NFTReceived(
        address operator,
        address from,
        uint256 tokenId,
        bytes data
    );
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        emit NFTReceived(operator, from, tokenId, data);
        return IERC721Receiver.onERC721Received.selector;
    }
}

// Todo: Implement safeTransferFrom with NFTReceiver
contract ERC721 {
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == 0x80ac58cd || interfaceId == 0x01ffc9a7;
    }

    mapping(uint => address) private _owners;
    mapping(address => uint) private _balances;
    mapping(uint => address) private _tokenApprovals;

    error ZeroAddress();
    error NotTokenOwner();
    error NoTokens();
    error NoAllowance();
    error AlreadyMinted();

    modifier notZeroAddress(address addr) {
        if (addr == address(0)) revert ZeroAddress();
        _;
    }

    event Transfer(
        address indexed from,
        address indexed to,
        uint indexed tokenId
    );
    event Approval(
        address indexed from,
        address indexed to,
        uint indexed tokenId
    );

    function balanceOf(
        address owner
    ) public view notZeroAddress(owner) returns (uint) {
        return _balances[owner];
    }

    function ownerOf(uint tokenId) public view returns (address) {
        address tokenOwner = _owners[tokenId];
        if (tokenOwner == address(0)) revert NotTokenOwner();
        return tokenOwner;
    }

    function _transfer(address from, address to, uint tokenId) private {
        if (_owners[tokenId] != from) revert NotTokenOwner();
        if (_balances[from] < 1) revert NoTokens();
        _balances[from] -= 1;
        _owners[tokenId] = to;
        _balances[to] += 1;

        emit Transfer(from, to, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint tokenId
    ) public notZeroAddress(from) notZeroAddress(to) {
        if (msg.sender != from) {
            if (_tokenApprovals[tokenId] != msg.sender) revert NoAllowance();
            delete _tokenApprovals[tokenId];
        }

        _transfer(from, to, tokenId);
    }

    function approve(address to, uint tokenId) public notZeroAddress(to) {
        if (_owners[tokenId] != msg.sender) revert NotTokenOwner();

        _tokenApprovals[tokenId] = to;
        emit Approval(msg.sender, to, tokenId);
    }

    function getApproved(uint tokenId) public view returns (address) {
        if (_owners[tokenId] == address(0)) revert NoTokens();
        return _tokenApprovals[tokenId];
    }

    function _mint(address to, uint tokenId) internal notZeroAddress(to) {
        if (_owners[tokenId] != address(0)) revert AlreadyMinted();
        _owners[tokenId] = to;
        _balances[to] += 1;

        emit Transfer(address(0), to, tokenId);
    }
}
