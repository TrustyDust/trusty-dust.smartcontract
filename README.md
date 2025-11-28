# TrustyDust Smart Contracts (Simplified)

Dokumentasi konsumsi kontrak untuk frontend & backend berdasarkan stack sederhana di `src/`.

## Peta Proyek & Kontrak (src/)
- `DustToken.sol` — ERC20 non-transferable; Role {OWNER, OPERATOR, SYSTEM}; hanya OPERATOR yang boleh mint/burn; transfer biasa direvert.
- `Identity.sol` — Registry `users[address] -> User{trustScore,tier,reputation,posts,jobsCompleted,hasBadge}`; mutator tanpa ACL.
- `Core.sol` — Reward sosial (LIKE/COMMENT/REPOST) dan job (rating 1-5) membayar DUST + update trust/jobsCompleted.
- `Content.sol` — `mintPost` membakar 10 DUST per post, lalu tambah posts di Identity.
- `Jobs.sol` — Board sederhana: create job burn 10 DUST, status {OPEN, COMPLETED, CANCELLED}, assign worker, approve → Core.rewardJob; cancel oleh poster.
- `Verifier.sol` — Wrapper ke verifier eksternal; `verifyTrustScore`, `verifyTier` (set tier & hasBadge pada sukses). Alamat verifier bisa di-set bebas.
- `SharedTypes.sol` — Enum SocialAction, JobStatus; struct User, Job.
- `Errors.sol` — Error library (Unauthorized, ZeroAddress, ZeroAmount, InvalidInput, InvalidState, InsufficientBalance).

## Dependensi & Keterkaitan
- DustToken diperlukan oleh Core (mint), Content (burn), Jobs (burn). Beri role OPERATOR ke Core/Content/Jobs.
- Identity di-update oleh Core (trust & jobsCompleted), Content (posts), Verifier (tier/hasBadge). Jobs tidak menulis langsung ke Identity.
- Jobs memanggil Core pada approve; nilai `minScore` hanya disimpan, tidak divalidasi on-chain.
- Verifier memerlukan alamat verifier eksternal; tidak ada guard owner untuk setter saat ini.

## Alur Utama
- Social reward: `Core.rewardSocial(user, action)` → delta (1/3/1 DUST) → Identity.addTrust → DustToken.mint.
- Job flow: `createJob` (burn 10 DUST) → `assignWorker` → `approveJob(rating)` (poster only) → status COMPLETED + Core.rewardJob(worker, rating) → trust/jobsCompleted bertambah.
- Content: `mintPost` burn 10 DUST → Identity.addPost.
- Verifikasi: `verifyTier`/`verifyTrustScore` → panggil verifier eksternal → jika tier sukses, Identity.setTier + hasBadge.

## Peran & Risiko
- Satu-satunya kontrol akses adalah Role di DustToken; kontrak lain tidak punya ACL. Set OPERATOR untuk Core/Content/Jobs sebelum produksi.
- Identity & Verifier setter terbuka; data dapat diubah oleh siapa saja sesuai kode saat ini.
- Jobs tidak memeriksa minScore; lakukan validasi off-chain bila diperlukan.

## Build & Test
```bash
forge build
forge test
```

## Deploy
Script: `script/Deploy.s.sol`
```bash
export RPC_URL=...
export PRIVATE_KEY=0x...
forge script script/Deploy.s.sol:Deploy \
  --rpc-url $RPC_URL \
  --broadcast --legacy
```
Script akan deploy DustToken, Identity, Core, Content, Jobs, Verifier dan memberi role OPERATOR ke Core/Content/Jobs.
