sudo source .env

sudo forge script script/Deploy.s.sol:Deploy \
  --rpc-url $RPC_URL \
  --chain-id 84532 \
  --broadcast --verify --legacy --resume \
  --private-key $PRIVATE_KEY \
  --retries 10 --delay 5

sudo forge clean
sudo source .env
sudo forge script script/Deploy.s.sol:Deploy \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  -vvvv

# BASE SEPOLIA
  → new DustToken@0xb54e25Db229942E8E9360613A46A72cf0f92E83c
  → new Identity@0xa171051a408E9720D587A80247977d596dB37614
  → new Core@0x9dF9F9952cF743542Cf97337EfA37Ae936E669B7
  → new Content@0x7F9194dD652a4A4796c01a5a625a2aC71017fB2c
  → new Jobs@0x245b947434a2C28134f6d6C26eB57962e11bc1b0
  → new Verifier@0xbca221bCcf6c4cF32d1e578b75eC53fA697c0979

# LISK SEPOLIA
  → new DustToken@0x1132930Ad19B0799542EC7d54199b9E41C17dD97
  → new Identity@0x34B8fC5C8d90c45FA74f286080007Dd71b2e3F11
  → new Core@0x563854442B2C517db5714e6975E517612A06BD82
  → new Content@0xED66cEF23B7F88a7A8CaF3B9D84F2bC1505C6FA7
  → new Jobs@0x69C65978B7Bd891801163557067Eb401767979cC
  → new Verifier@0xf3b3E0f3C878124388F7aac493bd8f9D8c2B011f