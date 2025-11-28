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
DUST="0x1132930Ad19B0799542EC7d54199b9E41C17dD97"
IDENTITY="0x34B8fC5C8d90c45FA74f286080007Dd71b2e3F11"
CORE="0x563854442B2C517db5714e6975E517612A06BD82"
CONTENT="0xED66cEF23B7F88a7A8CaF3B9D84F2bC1505C6FA7"
JOBS="0x69C65978B7Bd891801163557067Eb401767979cC"
VERIFIER="0xf3b3E0f3C878124388F7aac493bd8f9D8c2B011f"

echo ""
echo "⚠️  Update contract address manually first!"
echo ""

# =============================
# VERIFY DUST TOKEN
# =============================

echo "✅ VERIFYING DustToken"

forge verify-contract \
  --chain-id $CHAINID \
  $DUST \
  src/DustToken.sol:DustToken \
  --constructor-args $(cast abi-encode "constructor(string,string,address)" "Dust" "DUST" $DEPLOYER) \
  --num-of-optimizations 200 \
  --compiler-version 0.8.30 \
  --watch

# =============================
# VERIFY IDENTITY
# =============================
`
echo "✅ VERIFYING Identity"

forge verify-contract \
  --chain-id $CHAINID \
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
  --chain-id $CHAINID \
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
  --chain-id $CHAINID \
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
  --chain-id $CHAINID \
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
  --chain-id $CHAINID \
  $VERIFIER \
  src/Verifier.sol:Verifier \
  --constructor-args $(cast abi-encode "constructor(address)" $IDENTITY) \
  --num-of-optimizations 200 \
  --compiler-version 0.8.30 \
  --watch

echo ""
echo "✅✅✅ ALL CONTRACTS VERIFIED SUCCESSFULLY ✅✅✅"
