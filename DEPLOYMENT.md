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
  → new DustToken@0x5B99B1363F634CbF43FC13bd6D425285022aC469
  → new Identity@0x8219dF54d4de0012Fde4BaBf0D39437f4652B85d
  → new Core@0xA6b64d740De8FFD7EFD67Ff6296cD3CC9A0aac04
  → new Content@0x9C41c06011d228f08B907B073D3a12800d35C0e9
  → new Jobs@0x0691D75F7689142c304CE49ae89eaDC13Ab2cF27
  → new Verifier@0xca6bE56320bA3faF5401b6eEe72b19B06EbE9992