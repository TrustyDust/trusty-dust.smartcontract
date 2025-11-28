#!/bin/bash
set -e

source .env

echo "===================================="
echo " Deploying TrustyDust on Base Sepolia"
echo "===================================="

# 1. Clean & Build
forge clean
forge build

echo ""
echo "✅ BUILD SUCCESS"
echo ""

# 2. DEPLOY ALL CONTRACTS
echo "🚀 Starting deployment..."

forge script script/Deploy.s.sol:Deploy \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --chain-id 84532 \
  --broadcast \
  -vvvv

echo ""
echo "✅ DEPLOY DONE"
echo ""

sleep 90

echo "===================================="
echo " Starting manual verification step"
echo "===================================="

# 3. GET DEPLOYER ADDRESS
DEPLOYER=$(cast wallet address $PRIVATE_KEY)
echo "Deployer: $DEPLOYER"

# 4. REPLACE THESE WITH REAL ADDRESSES FROM LOG
DUST="0x330a7b9BCE82363879Ef5383E4754d66e65343C4"
IDENTITY="0xc459e56EE983De8d5e10c18C6cFD9FDcC51cBBf4"
CORE="0x11e7B912D56a3F3e96aD9bE2737debDE38bFc2a2"
CONTENT="0xF88b5e87bb25c68278c6FdA529536bE45936A017"
JOBS="0xf2654Ac6b25C9815003d0a8f3D14422b822B01a9"
VERIFIER="0x60cd018766a0C3e521324d77b79D08EA786dBdc0"

echo ""
echo "⚠️  Update contract address manually first!"
echo ""

# =============================
# VERIFY DUST TOKEN
# =============================

echo "✅ VERIFYING DustToken"

forge verify-contract \
  --chain-id 84532 \
  $DUST \
  src/DustToken.sol:DustToken \
  --constructor-args $(cast abi-encode "constructor(string,string,address)" "Dust" "DUST" $DEPLOYER) \
  --num-of-optimizations 200 \
  --compiler-version 0.8.30 \
  --watch

# =============================
# VERIFY IDENTITY
# =============================

echo "✅ VERIFYING Identity"

forge verify-contract \
  --chain-id 84532 \
  $IDENTITY \
  src/Identity.sol:Identity \
  --num-of-optimizations 200 \
  --compiler-version 0.8.30 \
  --watch

# =============================
# VERIFY CORE
# =============================

echo "✅ VERIFYING Core"

forge verify-contract \
  --chain-id 84532 \
  $CORE \
  src/Core.sol:Core \
  --constructor-args $(cast abi-encode "constructor(address,address)" $IDENTITY $DUST) \
  --num-of-optimizations 200 \
  --compiler-version 0.8.30 \
  --watch

# =============================
# VERIFY CONTENT
# =============================

echo "✅ VERIFYING Content"

forge verify-contract \
  --chain-id 84532 \
  $CONTENT \
  src/Content.sol:Content \
  --constructor-args $(cast abi-encode "constructor(address,address)" $IDENTITY $DUST) \
  --num-of-optimizations 200 \
  --compiler-version 0.8.30 \
  --watch

# =============================
# VERIFY JOBS
# =============================

echo "✅ VERIFYING Jobs"

forge verify-contract \
  --chain-id 84532 \
  $JOBS \
  src/Jobs.sol:Jobs \
  --constructor-args $(cast abi-encode "constructor(address,address,address)" $IDENTITY $DUST $CORE) \
  --num-of-optimizations 200 \
  --compiler-version 0.8.30 \
  --watch

# =============================
# VERIFY VERIFIER
# =============================

echo "✅ VERIFYING Verifier"

forge verify-contract \
  --chain-id 84532 \
  $VERIFIER \
  src/Verifier.sol:Verifier \
  --constructor-args $(cast abi-encode "constructor(address)" $IDENTITY) \
  --num-of-optimizations 200 \
  --compiler-version 0.8.30 \
  --watch

echo ""
echo "✅✅✅ ALL CONTRACTS VERIFIED SUCCESSFULLY ✅✅✅"
