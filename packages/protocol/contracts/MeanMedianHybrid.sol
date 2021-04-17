// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./Median.sol";

// Uses mean if median is within +-toleranceInPercentages% of mean,
// uses median otherwise
contract MeanMedianHybrid is Median {
  // Percentages are represented by multiplying by 1e6
  uint256 public constant HUNDRED_PERCENT = 100e6;
  uint256 public toleranceInPercentages;

  constructor (uint256 _toleranceInPercentages)
  {
    toleranceInPercentages = _toleranceInPercentages;
  }

  // I'm overiding compute() so that the aggregation method is modular.
  // So you can plug in whatever aggregation method you want to your ~dAPI~.
  // Note: The aggregators should be implemented for int256 responses
  // (not uint256) for generality.
  function compute
  (
    uint256[] memory arr
  )
    public
    override
    view
    returns (uint256)
  {
    // Compute the median
    uint256 mean;
    for (uint256 i = 0; i < arr.length; i++) {
      mean += arr[i];
    }
    mean /= arr.length;
    // Test the mean for validity.
    // Note that we are checking the mean against the median without actually
    // computing the median, in O(n) time. Wow!
    uint256 upperTolerance = mean * (HUNDRED_PERCENT + toleranceInPercentages) / HUNDRED_PERCENT;
    uint256 lowerTolerance = mean * (HUNDRED_PERCENT - toleranceInPercentages) / HUNDRED_PERCENT;
    uint256 upperToleranceValidityCount;
    uint256 lowerToleranceValidityCount;
    for (uint256 i = 0; i < arr.length; i++) {
      if (upperTolerance >= arr[i]) {
        upperToleranceValidityCount++;
      }
      if (lowerTolerance <= arr[i]) {
        lowerToleranceValidityCount++;
      }
    }
    // We expect this to be false if
    //   1. toleranceInPercentages is not chosen correctly
    //   2. Funny business is going on
    // Either way, we should investigate off-chain.
    if (upperToleranceValidityCount >= arr.length / 2) {
      if (lowerToleranceValidityCount >= arr.length / 2) {
        return mean;
      }
    }
    // Fall back to median if the mean is not valid.
    // Not a huge deal, this is how the aggregation was supposed to work anyway.
    return super.compute(arr);
  }
}
