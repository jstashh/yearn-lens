// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;

import "../../../interfaces/Cream/Unitroller.sol";
import "../../../interfaces/Cream/CyToken.sol";
import "../../../interfaces/Common/IERC20.sol";

contract CalculationsIronBank {
    address public unitrollerAddress;

    constructor(address _unitrollerAddress) {
        unitrollerAddress = _unitrollerAddress;
    }

    function getIronBankMarkets() public view returns (address[] memory) {
        return Unitroller(unitrollerAddress).getAllMarkets();
    }

    function isIronBankMarket(address tokenAddress) public view returns (bool) {
        address[] memory ironBankMarkets = getIronBankMarkets();
        uint256 numIronBankMarkets = ironBankMarkets.length;
        for (
            uint256 marketIdx = 0;
            marketIdx < numIronBankMarkets;
            marketIdx++
        ) {
            address marketAddress = ironBankMarkets[marketIdx];
            if (tokenAddress == marketAddress) {
                return true;
            }
        }
        return false;
    }

    function getIronBankMarketPriceUsdc(address tokenAddress)
        public
        view
        returns (uint256)
    {
        CyToken cyToken = CyToken(tokenAddress);
        uint256 exchangeRateStored = cyToken.exchangeRateStored();
        address underlyingTokenAddress = cyToken.underlying();
        uint256 decimals = cyToken.decimals();
        IERC20 underlyingToken = IERC20(underlyingTokenAddress);
        uint8 underlyingTokenDecimals = underlyingToken.decimals();
        (, bytes memory data) =
            address(msg.sender).staticcall(
                abi.encodeWithSignature(
                    "getPriceFromRouterUsdc(address)",
                    underlyingTokenAddress
                )
            );
        uint256 underlyingTokenPrice = abi.decode(data, (uint256));

        uint256 price =
            (underlyingTokenPrice * exchangeRateStored) /
                10**(underlyingTokenDecimals + decimals);
        return price;
    }

    function getPriceUsdc(address tokenAddress) public view returns (uint256) {
        if (isIronBankMarket(tokenAddress)) {
            return getIronBankMarketPriceUsdc(tokenAddress);
        }
        revert();
    }
}
